$ErrorActionPreference = "Stop"

# LOAD CONFIG
if (-not $Global:PinkConfig) {
    $detectedOS = "Windows10"
    try {
        $build = [int](Get-CimInstance Win32_OperatingSystem).BuildNumber
        if ($build -ge 22000) {
            $detectedOS = "Windows11"
        }
    }
    catch {
        $detectedOS = "Windows10"
    }

    $ConfigPath = Join-Path $PSScriptRoot "..\..\$detectedOS\Config.ps1"
    if (!(Test-Path $ConfigPath)) {
        $ConfigPath = Join-Path $PSScriptRoot "..\..\Windows11\Config.ps1"
    }
    if (!(Test-Path $ConfigPath)) {
        throw "Config.ps1 not found"
    }

    . $ConfigPath
}

if (-not $Global:OSVersion) {
    $Global:OSVersion = "Windows10"
    try {
        $build = [int](Get-CimInstance Win32_OperatingSystem).BuildNumber
        if ($build -ge 22000) {
            $Global:OSVersion = "Windows11"
        }
    }
    catch {
        $Global:OSVersion = "Windows10"
    }
}

$DownloadFolder = $Global:PinkConfig.DownloadFolder
$LogFolder = $Global:PinkConfig.LogFolder

New-Item -ItemType Directory -Force -Path $DownloadFolder | Out-Null
New-Item -ItemType Directory -Force -Path $LogFolder | Out-Null

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12