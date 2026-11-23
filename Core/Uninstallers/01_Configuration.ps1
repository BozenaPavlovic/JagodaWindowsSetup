# ==========================================
# STRAWBERRY WINDOWS - UNINSTALLER CONFIGURATION
# Paths, settings, timeouts and initialization.
# ==========================================

$ErrorActionPreference = "Stop"

$UninstallerProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

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

    $configPath = Join-Path $UninstallerProjectRoot "$($Global:OSVersion)\Config.ps1"
    $fallbackPath = Join-Path $UninstallerProjectRoot "Windows11\Config.ps1"

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

$UninstallLogFolder = $Global:PinkConfig.LogFolder

if (-not $UninstallLogFolder) {
    $UninstallLogFolder = Join-Path $UninstallerProjectRoot "Logs"
}

New-Item -ItemType Directory -Force -Path $UninstallLogFolder | Out-Null

$Global:UninstallLogFolder = $UninstallLogFolder

# ==========================================
# UNINSTALLER SETTINGS
# ==========================================

if (-not $Global:UninstallerSettings) {
    $Global:UninstallerSettings = @{}
}

if (-not $Global:UninstallerSettings.ContainsKey("UninstallTimeoutMs")) {
    $Global:UninstallerSettings.UninstallTimeoutMs = 600000
}

if (-not $Global:UninstallerSettings.ContainsKey("VerificationRetries")) {
    $Global:UninstallerSettings.VerificationRetries = 6
}

if (-not $Global:UninstallerSettings.ContainsKey("VerificationDelaySeconds")) {
    $Global:UninstallerSettings.VerificationDelaySeconds = 3
}

if (-not $Global:UninstallerSettings.ContainsKey("EnableAppxUninstall")) {
    $Global:UninstallerSettings.EnableAppxUninstall = $true
}

if (-not $Global:UninstallerSettings.ContainsKey("EnableMsiUninstall")) {
    $Global:UninstallerSettings.EnableMsiUninstall = $true
}

if (-not $Global:UninstallerSettings.ContainsKey("EnableExeUninstall")) {
    $Global:UninstallerSettings.EnableExeUninstall = $true
}

if (-not $Global:UninstallerSettings.ContainsKey("EnableWingetUninstall")) {
    $Global:UninstallerSettings.EnableWingetUninstall = $true
}

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

Write-Host "[OK] STRAWBERRY WINDOWS uninstaller configuration loaded." -ForegroundColor Green