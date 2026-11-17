# ==========================================
# STRAWBERRY WINDOWS - UNINSTALLER
# Uninstall functions for JagodaSetup managed programs.
# ==========================================

function Get-UninstallStorePath {
    if ($Global:StrawberryLogDirectory) {
        return Join-Path $Global:StrawberryLogDirectory "ManagedPrograms.json"
    }

    $projectRoot = Split-Path $PSScriptRoot -Parent
    return Join-Path $projectRoot "Logs\ManagedPrograms.json"
}

function Read-ManagedStore {
    $path = Get-UninstallStorePath

    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        return @()
    }

    try {
        $content = Get-Content -LiteralPath $path -Raw -Encoding UTF8 -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($content)) {
            return @()
        }

        $data = $content | ConvertFrom-Json -ErrorAction Stop
        if ($null -eq $data) {
            return @()
        }

        return @($data)
    }
    catch {
        Write-Warning "Unable to read managed program store: $($_.Exception.Message)"
        return @()
    }
}

function Write-ManagedStore {
    param(
        [Parameter(Mandatory)]
        [hashtable[]]$Programs
    )

    $path = Get-UninstallStorePath
    $logDir = Split-Path $path -Parent

    if (-not (Test-Path -LiteralPath $logDir -PathType Container)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    $json = $Programs | ConvertTo-Json -Depth 10

    try {
        Set-Content -LiteralPath $path -Value $json -Encoding UTF8 -ErrorAction Stop
    }
    catch {
        Write-Warning "Unable to write managed program store: $($_.Exception.Message)"
    }
}

function Register-ManagedProgram {
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [string]$DisplayName,
        [string]$Version,
        [string]$Publisher,
        [string]$UninstallString,
        [string]$InstallDate,
        [string]$Source = "JagodaSetup"
    )

    $store = Read-ManagedStore

    $existing = $store | Where-Object { $_.Name -eq $Name } | Select-Object -First 1

    if ($existing) {
        $index = [array]::IndexOf($store, $existing)
        $store[$index] = [PSCustomObject]@{
            Name            = $Name
            DisplayName     = $DisplayName
            Version         = $Version
            Publisher       = $Publisher
            UninstallString = $UninstallString
            InstallDate     = $InstallDate
            Source          = $Source
        }
    }
    else {
        $store += [PSCustomObject]@{
            Name            = $Name
            DisplayName     = $DisplayName
            Version         = $Version
            Publisher       = $Publisher
            UninstallString = $UninstallString
            InstallDate     = $InstallDate
            Source          = $Source
        }
    }

    Write-ManagedStore -Programs $store
}

function Unregister-ManagedProgram {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $store = Read-ManagedStore
    $filtered = $store | Where-Object { $_.Name -ne $Name }

    Write-ManagedStore -Programs @($filtered)
}

function Get-InstalledPrograms {
    param(
        [string]$Pattern
    )

    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    $programs = @()

    $registryItems = Get-ItemProperty $registryPaths -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName }

    if (-not [string]::IsNullOrWhiteSpace($Pattern)) {
        $registryItems = $registryItems | Where-Object {
            $_.DisplayName -like "*$Pattern*" -or $_.PSChildName -like "*$Pattern*"
        }
    }

    foreach ($item in $registryItems) {
        $programs += [PSCustomObject]@{
            Name            = $item.PSChildName
            DisplayName     = $item.DisplayName
            Version         = $item.DisplayVersion
            Publisher       = $item.Publisher
            UninstallString = $item.UninstallString
            QuietUninstallString = $item.QuietUninstallString
            InstallDate     = $item.InstallDate
            InstallLocation = $item.InstallLocation
            Source          = "Registry"
            PSChildName     = $item.PSChildName
        }
    }

    $appxItems = Get-AppxPackage -ErrorAction SilentlyContinue

    if (-not [string]::IsNullOrWhiteSpace($Pattern)) {
        $appxItems = $appxItems | Where-Object {
            $_.Name -like "*$Pattern*" -or $_.PackageFullName -like "*$Pattern*"
        }
    }

    foreach ($appx in $appxItems) {
        $programs += [PSCustomObject]@{
            Name            = $appx.Name
            DisplayName     = $appx.Name
            Version         = $appx.Version
            Publisher       = $appx.Publisher
            UninstallString = $null
            QuietUninstallString = $null
            InstallDate     = $null
            InstallLocation = $null
            Source          = "AppX"
            PackageFullName = $appx.PackageFullName
        }
    }

    return $programs
}

function Get-ManagedPrograms {
    $store = Read-ManagedStore

    if ($store.Count -eq 0) {
        return @()
    }

    $installed = Get-InstalledPrograms

    $results = @()

    foreach ($entry in $store) {
        $match = $installed | Where-Object { $_.Name -eq $entry.Name -or $_.DisplayName -eq $entry.Name } | Select-Object -First 1

        $results += [PSCustomObject]@{
            Name            = $entry.Name
            DisplayName     = $entry.DisplayName
            Version         = $entry.Version
            Publisher       = $entry.Publisher
            UninstallString = $entry.UninstallString
            InstallDate     = $entry.InstallDate
            Source          = $entry.Source
            Installed       = ($null -ne $match)
            CurrentVersion  = if ($match) { $match.Version } else { $null }
        }
    }

    return $results
}

function Find-UninstallCommand {
    param(
        [Parameter(Mandatory)]
        [string]$ProgramName,
        [object]$Program
    )

    $program = $null

    if ($Program) {
        $program = [PSCustomObject]$Program
    }
    else {
        $program = Get-InstalledPrograms -Pattern $ProgramName | Select-Object -First 1
    }

    if (-not $program) {
        return $null
    }

    $name = $program.Name
    $uninstallString = $program.UninstallString
    $quietUninstallString = $program.QuietUninstallString
    $packageFullName = $program.PackageFullName

    if ($program.Source -eq "AppX" -and $packageFullName) {
        return [PSCustomObject]@{
            ProgramName   = $name
            DisplayName   = $program.DisplayName
            Command       = "Remove-AppxPackage"
            Arguments     = "-Package `"$packageFullName`""
            IsAppx        = $true
            IsMsi         = $false
            PackageFullName = $packageFullName
            Source        = "AppX"
        }
    }

    if ([string]::IsNullOrWhiteSpace($uninstallString)) {
        return [PSCustomObject]@{
            ProgramName   = $name
            DisplayName   = $program.DisplayName
            Command       = $null
            Arguments     = $null
            IsAppx        = $false
            IsMsi         = $false
            PackageFullName = $null
            Source        = $program.Source
        }
    }

    $isMsi = $uninstallString -imatch "msiexec" -or $uninstallString -imatch "MsiExec"

    $productCode = $null
    if ($isMsi) {
        $guidMatch = [regex]::Match($uninstallString, "\{[0-9A-Fa-f\-]+\}")
        if ($guidMatch.Success) {
            $productCode = $guidMatch.Value
        }
    }

    $command = $null
    $arguments = $null

    if ($isMsi -and $productCode) {
        $command = "msiexec.exe"
        $arguments = "/x `"$productCode`" /qn"
    }
    else {
        $tokens = $uninstallString -split '\s(?=(?:[^"]*"[^"]*")*[^"]*$)', 2
        $command = $tokens[0] -replace '^"|"$', ''
        $arguments = if ($tokens.Count -gt 1) { $tokens[1] } else { $null }

        if ($quietUninstallString -and -not [string]::IsNullOrWhiteSpace($quietUninstallString)) {
            $qTokens = $quietUninstallString -split '\s(?=(?:[^"]*"[^"]*")*[^"]*$)', 2
            $command = $qTokens[0] -replace '^"|"$', ''
            $arguments = if ($qTokens.Count -gt 1) { $qTokens[1] } else { $null }
        }
    }

    return [PSCustomObject]@{
        ProgramName   = $name
        DisplayName   = $program.DisplayName
        Command       = $command
        Arguments     = $arguments
        IsAppx        = $false
        IsMsi         = $isMsi
        PackageFullName = $null
        Source        = $program.Source
    }
}

function Write-UninstallLog {
    param(
        [Parameter(Mandatory)]
        [string]$ProgramName,
        [Parameter(Mandatory)]
        [ValidateSet("SUCCESS", "FAILED", "SKIPPED", "WARNING")]
        [string]$Status,
        [string]$Message,
        [int]$ExitCode,
        [string]$UninstallCommand
    )

    $logDirectory = Get-UninstallStorePath
    $logPath = Join-Path (Split-Path $logDirectory -Parent) "Uninstall.log"

    $logDir = Split-Path $logPath -Parent
    if (-not (Test-Path -LiteralPath $logDir -PathType Container)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $user = [Environment]::UserName
    $computer = $env:COMPUTERNAME

    $exitPart = if ($ExitCode -ne $null) { " [ExitCode: $ExitCode]" } else { "" }
    $cmdPart = if (-not [string]::IsNullOrWhiteSpace($UninstallCommand)) { " | Command: $UninstallCommand" } else { "" }
    $msgPart = if (-not [string]::IsNullOrWhiteSpace($Message)) { " | $Message" } else { "" }

    $entry = "[$timestamp] [UNINSTALL] [$Status] [$computer] [$user] $ProgramName$exitPart$cmdPart$msgPart"

    try {
        Add-Content -LiteralPath $logPath -Value $entry -Encoding UTF8 -ErrorAction Stop
    }
    catch {
        Write-Warning "Unable to write uninstall log: $($_.Exception.Message)"
    }

    if (Get-Command Write-AppLog -ErrorAction SilentlyContinue) {

        $logLevel = switch ($Status) {
            "FAILED"   { "ERROR" }
            "SKIPPED"  { "WARNING" }
            default    { $Status }
        }

        Write-AppLog -Message "Uninstall ${ProgramName}: $Status$msgPart" -Level $logLevel -LogType INSTALLATION
    }
}

function Uninstall-OneApp {
    param(
        [Parameter(Mandatory)]
        [string]$ProgramName,
        [object]$Program,
        [switch]$Silent
    )

    $result = [PSCustomObject]@{
        ProgramName   = $ProgramName
        Status        = "FAILED"
        Message       = $null
        ExitCode      = $null
        UninstallCommand = $null
        Timestamp     = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }

    try {
        $commandInfo = Find-UninstallCommand -ProgramName $ProgramName -Program $Program

        if (-not $commandInfo) {
            $result.Message = "Program not found: $ProgramName"
            Write-UninstallLog -ProgramName $ProgramName -Status FAILED -Message $result.Message
            return $result
        }

        if (-not $commandInfo.Command) {
            $result.Message = "No uninstall command available for: $ProgramName"
            $result.Status = "SKIPPED"
            Write-UninstallLog -ProgramName $ProgramName -Status SKIPPED -Message $result.Message
            return $result
        }

        $result.UninstallCommand = "$($commandInfo.Command) $($commandInfo.Arguments)"

        Write-Host "Uninstalling: $ProgramName" -ForegroundColor Cyan

        if ($commandInfo.IsAppx) {
            Remove-AppxPackage -Package $commandInfo.PackageFullName -ErrorAction Stop
            $result.Status = "SUCCESS"
            $result.Message = "AppX package removed."
            Write-UninstallLog -ProgramName $ProgramName -Status SUCCESS -Message $result.Message -UninstallCommand $result.UninstallCommand
            Unregister-ManagedProgram -Name $ProgramName
            return $result
        }

        $silentArgs = $commandInfo.Arguments

        if ($Silent) {
            $silentLower = ($silentArgs -join " ") -replace '^"|"$', ''
            if (-not ($silentLower -like "* /qn *" -or $silentLower -like "* /quiet *" -or $silentLower -like "* /S *" -or $silentLower -like "* /s *")) {
                if ($commandInfo.IsMsi) {
                    $silentArgs += " /qn"
                }
                else {
                    $silentArgs += " /S"
                }
            }
        }

        $process = Start-Process -FilePath $commandInfo.Command -ArgumentList $silentArgs -PassThru -ErrorAction Stop

        $waited = 0
        while (-not $process.WaitForExit(1000)) {
            if (Get-Command Invoke-UiRefresh -ErrorAction SilentlyContinue) {
                Invoke-UiRefresh
            }

            $waited += 1000

            if ($waited -ge 600000) {
                try { $process.Kill() } catch {}
                throw "Uninstaller timed out after 10 minutes."
            }
        }

        $exitCode = $process.ExitCode
        $result.ExitCode = $exitCode

        $successCodes = @(0, 1641, 3010, 1, 2, 3)

        if ($successCodes -contains $exitCode) {
            Start-Sleep -Seconds 3

            $stillInstalled = Get-InstalledPrograms -Pattern $ProgramName |
                Where-Object { $_.Name -eq $ProgramName -or $_.DisplayName -eq $ProgramName -or $_.PSChildName -eq $ProgramName }

            if ($stillInstalled) {
                $result.Status = "FAILED"
                $result.Message = "Uninstaller finished but program is still present."
            }
            else {
                $result.Status = "SUCCESS"
                $result.Message = "Program uninstalled successfully."
            }
        }
        else {
            $result.Status = "FAILED"
            $result.Message = "Uninstaller exit code: $exitCode"
        }

        Write-UninstallLog -ProgramName $ProgramName -Status $result.Status -Message $result.Message -ExitCode $exitCode -UninstallCommand $result.UninstallCommand

        if ($result.Status -eq "SUCCESS") {
            Unregister-ManagedProgram -Name $ProgramName
        }

        return $result
    }
    catch {
        $result.Message = $_.Exception.Message
        $result.ExitCode = $null

        Write-UninstallLog -ProgramName $ProgramName -Status FAILED -Message $result.Message -UninstallCommand $result.UninstallCommand

        Write-Host "Uninstall failed for ${ProgramName}: $($_.Exception.Message)" -ForegroundColor Red

        return $result
    }
    finally {
        if (Get-Command Invoke-UiRefresh -ErrorAction SilentlyContinue) {
            Invoke-UiRefresh
        }
    }
}

function Uninstall-MultipleApps {
    param(
        [Parameter(Mandatory)]
        [array]$Programs,
        [switch]$Silent
    )

    $programs = @($Programs)
    $results = @()

    $total = $programs.Count
    $current = 0

    foreach ($app in $programs) {
        $current++

        $appName = $null

        if ($app -is [string]) {
            $appName = $app
        }
        elseif ($app -is [hashtable] -or $app -is [PSCustomObject]) {
            $appName = $app.DisplayName -or $app.Name -or $app.PSChildName
        }

        if (-not $appName) {
            continue
        }

        if ($current -gt 1) {
            Write-Host "`nProgress: $current of $total applications" -ForegroundColor Cyan
        }

        $result = Uninstall-OneApp -ProgramName $appName -Program $app -Silent:$Silent

        $results += $result
    }

    Write-Host "`nUNINSTALL SESSION FINISHED!" -ForegroundColor Magenta

    $successCount = ($results | Where-Object { $_.Status -eq "SUCCESS" }).Count
    $failedCount = ($results | Where-Object { $_.Status -eq "FAILED" }).Count
    $skippedCount = ($results | Where-Object { $_.Status -eq "SKIPPED" }).Count

    Write-Host "SUCCESS: $successCount | FAILED: $failedCount | SKIPPED: $skippedCount" -ForegroundColor Cyan

    return $results
}

Write-Host "[OK] STRAWBERRY WINDOWS uninstaller module loaded." -ForegroundColor Green
