# ==========================================
# STRAWBERRY WINDOWS - UNINSTALL COMMAND RESOLVER
# Determine the correct uninstall method and command (MSI, EXE, AppX, Winget).
# ==========================================

function Resolve-UninstallCommand {
    param(
        [Parameter(Mandatory)]
        [string]$ProgramName,
        [object]$InputProgram
    )

    $resolvedProgram = $null
    $dbApp = $null

    # Use InputProgram to avoid PowerShell case-insensitive variable name collision with $program
    if ($null -ne $InputProgram -and $InputProgram.Count -gt 0) {
        $resolvedProgram = [PSCustomObject]$InputProgram
        
        # Check if this is a database app (has WingetID, Match properties)
        if ($resolvedProgram.WingetID -or $resolvedProgram.Match) {
            $dbApp = $resolvedProgram
        }
    }

    # If we have a database app, use its properties to find the installed app
    if ($dbApp) {
        $installed = Find-InstalledProgramFromDbApp -DbApp $dbApp
        if ($installed) {
            $resolvedProgram = $installed
        }
    }
    elseif (-not $resolvedProgram) {
        # Fallback: try to find by ProgramName
        $resolvedProgram = Find-InstalledProgram -Pattern $ProgramName | Select-Object -First 1
    }

    if (-not $resolvedProgram) {
        Write-Host "DEBUG: Program not found for '$ProgramName'. Tried database app matching and registry/AppX search." -ForegroundColor Yellow
        return $null
    }

    $name = $resolvedProgram.Name
    $uninstallString = $resolvedProgram.UninstallString
    $quietUninstallString = $resolvedProgram.QuietUninstallString
    $packageFullName = $resolvedProgram.PackageFullName
    $source = $resolvedProgram.Source

    # Handle AppX/MSIX packages
    if ($source -eq "AppX" -and $packageFullName -and $Global:UninstallerSettings.EnableAppxUninstall) {
        return [PSCustomObject]@{
            ProgramName      = $name
            DisplayName      = $resolvedProgram.DisplayName
            Command          = "Remove-AppxPackage"
            Arguments        = "-Package `"$packageFullName`""
            IsAppx           = $true
            IsMsi            = $false
            IsExe            = $false
            IsWinget         = $false
            PackageFullName  = $packageFullName
            Source           = "AppX"
            ProductCode      = $null
        }
    }

    # Handle MSI uninstall
    if ($uninstallString -and ($uninstallString -imatch "msiexec" -or $uninstallString -imatch "MsiExec") -and $Global:UninstallerSettings.EnableMsiUninstall) {
        $productCode = $null
        $guidMatch = [regex]::Match($uninstallString, "\{[0-9A-Fa-f\-]+\}")
        if ($guidMatch.Success) {
            $productCode = $guidMatch.Value
        }

        return [PSCustomObject]@{
            ProgramName      = $name
            DisplayName      = $resolvedProgram.DisplayName
            Command          = "msiexec.exe"
            Arguments        = "/x `"$productCode`" /qn"
            IsAppx           = $false
            IsMsi            = $true
            IsExe            = $false
            IsWinget         = $false
            PackageFullName  = $null
            Source           = "Registry"
            ProductCode      = $productCode
        }
    }

    # Handle EXE uninstall
    if ($uninstallString -and $Global:UninstallerSettings.EnableExeUninstall) {
        $command = $null
        $arguments = $null

        # Prefer QuietUninstallString if available
        $useQuiet = $false
        if ($quietUninstallString -and -not [string]::IsNullOrWhiteSpace($quietUninstallString)) {
            $useQuiet = $true
            $uninstallString = $quietUninstallString
        }

        $tokens = $uninstallString -split '\s(?=(?:[^"]*"[^"]*")*[^"]*$)', 2
        $command = $tokens[0] -replace '^"|"$', ''
        $arguments = if ($tokens.Count -gt 1) { $tokens[1] } else { $null }

        return [PSCustomObject]@{
            ProgramName      = $name
            DisplayName      = $resolvedProgram.DisplayName
            Command          = $command
            Arguments        = $arguments
            IsAppx           = $false
            IsMsi            = $false
            IsExe            = $true
            IsWinget         = $false
            PackageFullName  = $null
            Source           = "Registry"
            ProductCode      = $null
        }
    }

    # Try Winget uninstall if we have a database app with WingetID
    if ($dbApp -and $dbApp.WingetID -and $Global:UninstallerSettings.EnableWingetUninstall) {
        $wingetCmd = Resolve-WingetUninstallCommand -WingetId $dbApp.WingetID
        if ($wingetCmd) {
            $wingetCmd.ProgramName = $name
            $wingetCmd.DisplayName = $resolvedProgram.DisplayName
            return $wingetCmd
        }
    }

    # Fallback: no uninstall command available
    Write-Host "DEBUG: No uninstall command resolved for '$ProgramName' (Source: $source, Name: $name)" -ForegroundColor Yellow
    return [PSCustomObject]@{
        ProgramName      = $name
        DisplayName      = $resolvedProgram.DisplayName
        Command          = $null
        Arguments        = $null
        IsAppx           = $false
        IsMsi            = $false
        IsExe            = $false
        IsWinget         = $false
        PackageFullName  = $null
        Source           = $source
        ProductCode      = $null
    }
}

function Resolve-WingetUninstallCommand {
    param(
        [Parameter(Mandatory)]
        [string]$WingetId
    )

    if (-not $Global:UninstallerSettings.EnableWingetUninstall) {
        return $null
    }

    $wingetCommand = Get-Command winget.exe -ErrorAction SilentlyContinue

    if (-not $wingetCommand -or -not $wingetCommand.Source) {
        return $null
    }

    $wingetExe = $wingetCommand.Source

    return [PSCustomObject]@{
        ProgramName      = $WingetId
        DisplayName      = $WingetId
        Command          = $wingetExe
        Arguments        = "uninstall --id `"$WingetId`" --exact --silent --accept-source-agreements --disable-interactivity"
        IsAppx           = $false
        IsMsi            = $false
        IsExe            = $false
        IsWinget         = $true
        PackageFullName  = $null
        Source           = "Winget"
        ProductCode      = $null
    }
}

function Find-InstalledProgram {
    param(
        [string]$Pattern
    )

    $programs = @()

    # Check registry first
    $registryPrograms = Get-InstalledProgramsFromRegistry -Pattern $Pattern
    $programs += $registryPrograms

    # Check AppX
    $appxPrograms = Get-InstalledProgramsFromAppx -Pattern $Pattern
    $programs += $appxPrograms

    return $programs
}

function Find-InstalledProgramFromDbApp {
    param(
        [Parameter(Mandatory)]
        [object]$DbApp
    )

    $allInstalled = Get-AllInstalledPrograms
    
    # Try multiple matching strategies in order of reliability
    
    # 1. Match by WingetID (most reliable for winget-installed apps)
    if ($DbApp.WingetID) {
        # Check registry for winget package ID in UninstallString or PSChildName
        $wingetMatch = $allInstalled | Where-Object {
            ($_.UninstallString -and $_.UninstallString -like "*$($DbApp.WingetID)*") -or
            ($_.PSChildName -and $_.PSChildName -like "*$($DbApp.WingetID)*") -or
            ($_.Name -and $_.Name -like "*$($DbApp.WingetID)*")
        } | Select-Object -First 1
        
        if ($wingetMatch) {
            return $wingetMatch
        }
        
        # Check AppX for package family name matching
        $appxMatch = $allInstalled | Where-Object {
            $_.Source -eq "AppX" -and $_.PackageFullName -and $_.PackageFullName -like "*$($DbApp.WingetID)*"
        } | Select-Object -First 1
        
        if ($appxMatch) {
            return $appxMatch
        }
    }
    
    # 2. Match by Match property (exact DisplayName match)
    if ($DbApp.Match) {
        $match = $allInstalled | Where-Object {
            $_.DisplayName -and ($_.DisplayName -ieq $DbApp.Match -or $_.DisplayName -like "*$($DbApp.Match)*")
        } | Select-Object -First 1
        
        if ($match) {
            return $match
        }
    }
    
    # 3. Match by Name property (exact or fuzzy)
    if ($DbApp.Name) {
        $match = $allInstalled | Where-Object {
            $_.DisplayName -and ($_.DisplayName -ieq $DbApp.Name -or $_.DisplayName -like "*$($DbApp.Name)*") -or
            $_.Name -and ($_.Name -ieq $DbApp.Name -or $_.Name -like "*$($DbApp.Name)*") -or
            $_.PSChildName -and ($_.PSChildName -ieq $DbApp.Name -or $_.PSChildName -like "*$($DbApp.Name)*")
        } | Select-Object -First 1
        
        if ($match) {
            return $match
        }
    }
    
    # 4. Match by Publisher + Name combination
    if ($DbApp.Publisher -and $DbApp.Name) {
        $match = $allInstalled | Where-Object {
            $_.Publisher -and $_.Publisher -like "*$($DbApp.Publisher)*" -and
            ($_.DisplayName -like "*$($DbApp.Name)*" -or $_.Name -like "*$($DbApp.Name)*")
        } | Select-Object -First 1
        
        if ($match) {
            return $match
        }
    }

    Write-Host "WARNING: No match found for DB app: Name='$($DbApp.Name)', Match='$($DbApp.Match)', WingetID='$($DbApp.WingetID)', Publisher='$($DbApp.Publisher)'" -ForegroundColor Yellow
    return $null
}