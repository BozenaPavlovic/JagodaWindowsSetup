# Core/Installer.ps1
function Install-OneApp {
    param($app)
    $os = (Get-CimInstance Win32_OperatingSystem).Caption
    if ($os -like "*Windows 10*") {
        & "$PSScriptRoot\..\Windows10\Installers\Programs.ps1" $app
    } elseif ($os -like "*Windows 11*") {
        & "$PSScriptRoot\..\Windows11\Installers\Programs.ps1" $app
    }
}
