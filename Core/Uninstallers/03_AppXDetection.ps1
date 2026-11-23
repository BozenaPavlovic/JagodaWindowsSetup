# ==========================================
# STRAWBERRY WINDOWS - APPX DETECTION
# Detect installed AppX/MSIX applications.
# ==========================================

function Find-InstalledAppByAppx {
    param(
        [Parameter(Mandatory)]
        [string]$Pattern
    )

    $appx = Get-AppxPackage -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -like "*$Pattern*" -or $_.PackageFullName -like "*$Pattern*"
        } |
        Select-Object -First 1

    if ($appx) {
        return [PSCustomObject]@{
            Name             = $appx.Name
            DisplayName      = $appx.Name
            DisplayVersion   = $appx.Version
            Publisher        = $appx.Publisher
            UninstallString  = $null
            QuietUninstallString = $null
            InstallDate      = $null
            InstallLocation  = $null
            Source           = "AppX"
            PackageFullName  = $appx.PackageFullName
        }
    }

    return $null
}

function Get-AllInstalledProgramsFromAppx {
    $appxItems = Get-AppxPackage -ErrorAction SilentlyContinue

    $programs = @()

    foreach ($appx in $appxItems) {
        $programs += [PSCustomObject]@{
            Name             = $appx.Name
            DisplayName      = $appx.Name
            DisplayVersion   = $appx.Version
            Publisher        = $appx.Publisher
            UninstallString  = $null
            QuietUninstallString = $null
            InstallDate      = $null
            InstallLocation  = $null
            Source           = "AppX"
            PackageFullName  = $appx.PackageFullName
        }
    }

    return $programs
}

function Get-InstalledProgramsFromAppx {
    param(
        [string]$Pattern
    )

    $programs = Get-AllInstalledProgramsFromAppx

    if (-not [string]::IsNullOrWhiteSpace($Pattern)) {
        $programs = $programs | Where-Object {
            $_.DisplayName -like "*$Pattern*" -or
            $_.Name -like "*$Pattern*" -or
            $_.PackageFullName -like "*$Pattern*"
        }
    }

    return $programs
}