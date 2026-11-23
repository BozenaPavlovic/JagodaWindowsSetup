# ==========================================
# STRAWBERRY WINDOWS - REGISTRY DETECTION
# Detect installed desktop applications through Windows registry uninstall entries.
# ==========================================

function Get-RegistryUninstallPaths {
    return @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
}

function Find-InstalledAppByRegistry {
    param(
        [Parameter(Mandatory)]
        [string]$Pattern
    )

    $paths = Get-RegistryUninstallPaths

    $found = Get-ItemProperty $paths -ErrorAction SilentlyContinue |
        Where-Object {
            $_.DisplayName -and ($_.DisplayName -like "*$Pattern*" -or $_.PSChildName -like "*$Pattern*")
        } |
        Select-Object -First 1

    if ($found) {
        return [PSCustomObject]@{
            Name             = $found.PSChildName
            DisplayName      = $found.DisplayName
            DisplayVersion   = $found.DisplayVersion
            Publisher        = $found.Publisher
            UninstallString  = $found.UninstallString
            QuietUninstallString = $found.QuietUninstallString
            InstallDate      = $found.InstallDate
            InstallLocation  = $found.InstallLocation
            Source           = "Registry"
            PSChildName      = $found.PSChildName
        }
    }

    return $null
}

function Get-AllInstalledProgramsFromRegistry {
    $paths = Get-RegistryUninstallPaths

    $registryItems = Get-ItemProperty $paths -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName }

    $programs = @()

    foreach ($item in $registryItems) {
        $programs += [PSCustomObject]@{
            Name             = $item.PSChildName
            DisplayName      = $item.DisplayName
            DisplayVersion   = $item.DisplayVersion
            Publisher        = $item.Publisher
            UninstallString  = $item.UninstallString
            QuietUninstallString = $item.QuietUninstallString
            InstallDate      = $item.InstallDate
            InstallLocation  = $item.InstallLocation
            Source           = "Registry"
            PSChildName      = $item.PSChildName
        }
    }

    return $programs
}

function Get-InstalledProgramsFromRegistry {
    param(
        [string]$Pattern
    )

    $programs = Get-AllInstalledProgramsFromRegistry

    if (-not [string]::IsNullOrWhiteSpace($Pattern)) {
        $programs = $programs | Where-Object {
            $_.DisplayName -like "*$Pattern*" -or
            $_.Name -like "*$Pattern*" -or
            $_.PSChildName -like "*$Pattern*"
        }
    }

    return $programs
}