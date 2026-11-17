function Find-InstalledApp {

    param([string]$Pattern)

    $Paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    $Found = Get-ItemProperty $Paths -ErrorAction SilentlyContinue |
        Where-Object {
            $_.DisplayName -like "*$Pattern*"
        } |
        Select-Object -First 1

    if ($Found) {
        return $Found
    }

    $appx = Get-AppxPackage -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -like "*$Pattern*" -or $_.PackageFullName -like "*$Pattern*"
        } |
        Select-Object -First 1

    if ($appx) {
        return [PSCustomObject]@{
            DisplayName = $appx.Name
            DisplayVersion = $appx.Version
            PackageFullName = $appx.PackageFullName
        }
    }

    return $null
}