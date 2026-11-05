
# ==========================================
# PINK WINDOWS - PORTABLE CONFIGURATION
# VERSION 3.1
# ==========================================

$ErrorActionPreference = "Stop"

# PROJECT ROOT - USB OR LOCAL FOLDER
$Global:PinkRoot = $PSScriptRoot

# TEMPORARY WORKSPACE
$Global:PinkWork = Join-Path $env:TEMP "PinkWindowsSetup"

# CONFIGURATION
$Global:PinkConfig = @{
    Version = "3.1"
    Name = "Pink Windows Strawberry Edition"

    Root = $Global:PinkRoot

    WallpaperFolder = Join-Path `
        ([Environment]::GetFolderPath("MyPictures")) `
        "Pink Wallpapers"

    DownloadFolder = Join-Path $Global:PinkWork "Downloads"

    CacheFolder = Join-Path $Global:PinkWork "Cache"

    LogFolder = Join-Path $Global:PinkRoot "Logs"

    WallpaperURL = "https://www.fabmood.com/wp-content/uploads/2026/03/Cute-Pink-Strawberry-Desktop-Wallpaper-Kawaii-Aesthetic-Laptop-Background.jpg"
}

# CREATE DIRECTORIES
$Folders = @(
    $Global:PinkConfig.WallpaperFolder
    $Global:PinkConfig.DownloadFolder
    $Global:PinkConfig.CacheFolder
    $Global:PinkConfig.LogFolder
)

foreach ($Folder in $Folders) {
    New-Item -ItemType Directory `
        -Path $Folder `
        -Force `
        -ErrorAction Stop | Out-Null
}

# ENVIRONMENT INFORMATION
$Global:PinkEnvironment = @{
    ComputerName = $env:COMPUTERNAME
    UserName = $env:USERNAME
    WindowsVersion = [Environment]::OSVersion.Version
    PowerShellVersion = $PSVersionTable.PSVersion
    Is64Bit = [Environment]::Is64BitOperatingSystem
}

Write-Host ""
Write-Host "PINK WINDOWS CONFIGURATION LOADED!" -ForegroundColor Magenta
Write-Host "Project: $($Global:PinkConfig.Root)" -ForegroundColor Green
Write-Host "Downloads: $($Global:PinkConfig.DownloadFolder)" -ForegroundColor Cyan
Write-Host "Logs: $($Global:PinkConfig.LogFolder)" -ForegroundColor Cyan
