# ==========================================
# STRAWBERRY WINDOWS - OBZ CONFIGURATION
# Independent settings for the OBZ module.
# Does not load or alter the standard installer configuration.
# ==========================================

$ErrorActionPreference = "Stop"

$OBZProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

# ==========================================
# OBZ APPLICATION DIRECTORY
# ==========================================

if (-not $Global:OBZSettings) {
    $Global:OBZSettings = @{}
}

if (-not $Global:OBZSettings.ContainsKey("ApplicationDirectoryUrl")) {
    $Global:OBZSettings.ApplicationDirectoryUrl = "http://192.168.254.22/instalacije/"
}

# ==========================================
# OBZ DISPLAY NAME OVERRIDES
# Maps filename (without .exe) to actual installed DisplayName for detection
# ==========================================

if (-not $Global:OBZSettings.ContainsKey("DisplayNameOverrides")) {
    $Global:OBZSettings.DisplayNameOverrides = @{
        "OBZ32OcsPackage" = "OCS Inventory NG Agent"
        "OBZ64OcsPackage" = "OCS Inventory NG Agent"
    }
}

# ==========================================
# OBZ WINGET ID OVERRIDES
# Maps filename (without .exe) to winget package ID
# Apps not listed here fall back to direct download
# ==========================================

if (-not $Global:OBZSettings.ContainsKey("WingetIdOverrides")) {
    $Global:OBZSettings.WingetIdOverrides = @{
        # "OBZ32OcsPackage" = "OCS-Inventory.OCSAgent"
        # "Certilia_Middleware_v3.9.14" = "AKD.CertiliaMiddleware"
    }
}

# ==========================================
# OBZ MESSAGES
# ==========================================

if (-not $Global:OBZSettings.ContainsKey("Messages")) {
    $Global:OBZSettings.Messages = @{}
}

if (-not $Global:OBZSettings.Messages.ContainsKey("LoadingApplications")) {
    $Global:OBZSettings.Messages.LoadingApplications = "Loading applications..."
}

if (-not $Global:OBZSettings.Messages.ContainsKey("NoApplicationsAvailable")) {
    $Global:OBZSettings.Messages.NoApplicationsAvailable = "No applications are available."
}

if (-not $Global:OBZSettings.Messages.ContainsKey("ServerUnavailable")) {
    $Global:OBZSettings.Messages.ServerUnavailable = "The OBZ server is unavailable. Please try again later."
}

if (-not $Global:OBZSettings.Messages.ContainsKey("FailedToRetrieveApplicationList")) {
    $Global:OBZSettings.Messages.FailedToRetrieveApplicationList = "Failed to retrieve the application list."
}

if (-not $Global:OBZSettings.Messages.ContainsKey("InstallationError")) {
    $Global:OBZSettings.Messages.InstallationError = "An error occurred during installation."
}

# ==========================================
# OBZ DOWNLOAD SETTINGS
# ==========================================

if (-not $Global:OBZSettings.ContainsKey("DownloadFolder")) {
    $Global:OBZSettings.DownloadFolder = Join-Path $OBZProjectRoot "DATABASE\OBZ\Downloads"
}

$Global:OBZSettings.DownloadTimeoutSeconds = 60
$Global:OBZSettings.DownloadRetries = 2
$Global:OBZSettings.RetryDelaySeconds = 3

# ==========================================
# OBZ TIMEOUT SETTINGS
# ==========================================

if (-not $Global:OBZSettings.ContainsKey("ServerTimeoutSeconds")) {
    $Global:OBZSettings.ServerTimeoutSeconds = 30
}

if (-not $Global:OBZSettings.ContainsKey("RequestTimeoutSeconds")) {
    $Global:OBZSettings.RequestTimeoutSeconds = 60
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

Write-Host "[OK] STRAWBERRY WINDOWS OBZ configuration loaded." -ForegroundColor Green