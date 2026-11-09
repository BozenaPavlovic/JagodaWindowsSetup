
<#
.SYNOPSIS
    Loads the existing Strawberry Windows installer backend.
#>

$ProjectRoot = Split-Path $PSScriptRoot -Parent
$ProjectRoot = Split-Path $ProjectRoot -Parent

$CoreInstaller = Join-Path $ProjectRoot "Core\Installer.ps1"
$Windows10Installer = Join-Path $ProjectRoot "Windows10\Installers\Programs.ps1"

if (-not (Test-Path $CoreInstaller)) {
    throw "Core Installer not found: $CoreInstaller"
}

if (-not (Test-Path $Windows10Installer)) {
    throw "Windows 10 Programs backend not found: $Windows10Installer"
}

# Load shared installer functions.
. $CoreInstaller

# Load Windows 10-specific program functions.
. $Windows10Installer

Write-Host "Installer backend successfully loaded." -ForegroundColor Green
