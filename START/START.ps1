
# ==========================================
# STRAWBERRY WINDOWS - PORTABLE STARTER
# ==========================================

$ErrorActionPreference = "Stop"

try {

    $Root = $PSScriptRoot

    # ==========================================
    # ELEVATION (required for MSI/EXE install & uninstall)
    # ==========================================

    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Host ""
        Write-Host "Administrator privileges required. Relaunching elevated..." -ForegroundColor Yellow
        Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        exit
    }

    Write-Host ""
    Write-Host "STRAWBERRY WINDOWS PORTABLE STARTER" -ForegroundColor Magenta
    Write-Host "Project: $Root" -ForegroundColor Cyan

    # Windows check
    if ([Environment]::OSVersion.Platform -ne "Win32NT") {
        throw "This program requires Windows."
    }

    # PowerShell check
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        throw "PowerShell 5.1 or newer is required."
    }

    # Required files
    $RequiredFiles = @(
        "Config.ps1",
        "..\GUI\MainMenu.ps1"
    )

    foreach ($File in $RequiredFiles) {

        $Path = Join-Path $Root $File

        if (!(Test-Path $Path -PathType Leaf)) {
            throw "Missing required file: $File"
        }

        Write-Host "[OK] $File" -ForegroundColor Green
    }

    # Check USB/project write access
    $TestFile = Join-Path $Root "Logs\write-test.tmp"

    try {
        New-Item -Path $TestFile -ItemType File -Force |
            Out-Null

        Remove-Item $TestFile -Force
    }
    catch {
        Write-Host "WARNING: Project folder is read-only." -ForegroundColor Yellow
        Write-Host "Logs may need to be stored locally." -ForegroundColor Yellow
    }

    # Load configuration
    . "$Root\Config.ps1"

    Write-Host ""
    Write-Host "COMPUTER: $env:COMPUTERNAME" -ForegroundColor Cyan
    Write-Host "POWERSHELL: $($PSVersionTable.PSVersion)" -ForegroundColor Cyan
    Write-Host "SYSTEM: $([Environment]::OSVersion.Version)" -ForegroundColor Cyan

    Write-Host ""
    Write-Host "ALL CHECKS PASSED!" -ForegroundColor Green

    # Start application
    & "$Root\..\GUI\MainMenu.ps1"

}
catch {

    Write-Host ""
    Write-Host "STARTUP ERROR!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    Write-Host ""
    Read-Host "Press ENTER to close"
}
