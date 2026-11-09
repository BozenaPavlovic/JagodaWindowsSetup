# install for Windows11
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Restarting script with administrator privileges..."
    Start-Process powershell.exe "-File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$root = Join-Path $PSScriptRoot ".."
$win10Path = Join-Path $root "Windows10"

. "$root\Core\Model.ps1"
. "$root\Core\Controller.ps1"
. "$PSScriptRoot\Config.ps1"
. "$win10Path\SystemTools\Get-SystemSpecs.ps1"

Run-Installation