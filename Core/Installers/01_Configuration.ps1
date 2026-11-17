# ==========================================
# STRAWBERRY WINDOWS - INSTALLER CONFIGURATION
# Loads OS configuration, folders and TLS.
# ==========================================

$ErrorActionPreference = "Stop"

$InstallerProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

# ==========================================
# WINDOWS VERSION
# ==========================================

if (-not $Global:OSVersion) {

    $osBuild = 0

    try {
        $osBuild = [int](Get-CimInstance Win32_OperatingSystem -ErrorAction Stop).BuildNumber
    }
    catch {
        $osBuild = 0
    }

    if ($osBuild -ge 22000) {
        $Global:OSVersion = "Windows11"
    }
    else {
        $Global:OSVersion = "Windows10"
    }
}

# ==========================================
# OS CONFIGURATION
# ==========================================

if (-not $Global:PinkConfig) {

    $configPath = Join-Path $InstallerProjectRoot "$($Global:OSVersion)\Config.ps1"
    $fallbackPath = Join-Path $InstallerProjectRoot "Windows11\Config.ps1"

    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        $configPath = $fallbackPath
    }

    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        throw "Windows configuration not found. Checked '$configPath'."
    }

    . $configPath
}

# ==========================================
# FOLDERS
# ==========================================

$DownloadFolder = $Global:PinkConfig.DownloadFolder

if (-not $DownloadFolder) {
    $DownloadFolder = Join-Path $InstallerProjectRoot "Downloads"
}

$LogFolder = $Global:PinkConfig.LogFolder

if (-not $LogFolder) {
    $LogFolder = Join-Path $InstallerProjectRoot "Logs"
}

New-Item -ItemType Directory -Force -Path $DownloadFolder | Out-Null
New-Item -ItemType Directory -Force -Path $LogFolder | Out-Null

$Global:DownloadFolder = $DownloadFolder
$Global:LogFolder = $LogFolder

# ==========================================
# TLS
# ==========================================

try {
    [Net.ServicePointManager]::SecurityProtocol = `
        [Net.ServicePointManager]::SecurityProtocol -bor `
        [Net.SecurityProtocolType]::Tls12
}
catch {
}