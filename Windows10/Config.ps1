# Windows10/Config.ps1 - minimal Windows 10 configuration (delegates shared logic to Core)

$ErrorActionPreference = "Stop"

$Global:PinkRoot = $PSScriptRoot
$Global:PinkWork = Join-Path $env:TEMP "PinkWindowsSetup"

$Global:PinkConfig = @{
    Version = "3.1"
    Name = "STRAWBERRY WINDOWS Strawberry Edition"
    Root = $Global:PinkRoot
    WallpaperFolder = Join-Path ([Environment]::GetFolderPath("MyPictures")) "Pink Wallpapers"
    DownloadFolder = Join-Path $Global:PinkWork "Downloads"
    CacheFolder = Join-Path $Global:PinkWork "Cache"
    LogFolder = Join-Path $Global:PinkRoot "Logs"
}

$Global:WindowsConfig = @{
    OS = "Windows10"
    Theme = "Pink"
    EnableDarkMode = $true
    InstallWinget = $true
    EnableWidgets = $false
}

$Folders = @(
    $Global:PinkConfig.WallpaperFolder
    $Global:PinkConfig.DownloadFolder
    $Global:PinkConfig.CacheFolder
    $Global:PinkConfig.LogFolder
)
foreach ($Folder in $Folders) {
    New-Item -ItemType Directory -Path $Folder -Force -ErrorAction Stop | Out-Null
}

$Global:PinkEnvironment = @{
    ComputerName = $env:COMPUTERNAME
    UserName = $env:USERNAME
    WindowsVersion = [Environment]::OSVersion.Version
    PowerShellVersion = $PSVersionTable.PSVersion
    Is64Bit = [Environment]::Is64BitOperatingSystem
}

Write-Host "STRAWBERRY WINDOWS Windows 10 configuration loaded." -ForegroundColor Magenta
