
<#
.SYNOPSIS
    Loads the Strawberry Windows installer backend.

.DESCRIPTION
    Loads the shared installer backend, application database,
    logging, helpers and shared theme manager for GUI use.
#>

# ==========================================
# PROJECT PATHS
# ==========================================

$ProjectRoot = Split-Path $PSScriptRoot -Parent
$ProjectRoot = Split-Path $ProjectRoot -Parent

$LoggingPath = Join-Path $ProjectRoot "Core\Logging.ps1"
$DatabasePath = Join-Path $ProjectRoot "Core\ProgramDatabase.ps1"
$InstallerHelpersPath = Join-Path $ProjectRoot "Core\InstallerHelpers.ps1"
$Windows10InstallerPath = Join-Path $ProjectRoot "Windows10\Installers\Programs.ps1"
$ThemeManagerPath = Join-Path $ProjectRoot "Core\ThemeManager.ps1"

# ==========================================
# VALIDATE REQUIRED FILES
# ==========================================

$RequiredFiles = @(
    $LoggingPath
    $DatabasePath
    $InstallerHelpersPath
    $Windows10InstallerPath
    $ThemeManagerPath
)

foreach ($file in $RequiredFiles) {

    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        throw "Required backend file not found: $file"
    }
}

# ==========================================
# LOAD LOGGING
# ==========================================

if (-not (Get-Command Write-AppLog -ErrorAction SilentlyContinue)) {
    . $LoggingPath
}

if (-not (Get-Command Write-AppLog -ErrorAction SilentlyContinue)) {
    throw "Write-AppLog function could not be loaded."
}

Write-AppLog -Message "========================================"
Write-AppLog -Message "GUI installer backend loading started."

# ==========================================
# LOAD DATABASE
# ==========================================

try {
    . $DatabasePath
    Write-AppLog -Message "Application database loaded."
}
catch {
    Write-AppLog -Message "Failed to load application database: $($_.Exception.Message)"
    throw
}

# ==========================================
# LOAD HELPERS
# ==========================================

try {
    . $InstallerHelpersPath
    Write-AppLog -Message "Installer helpers loaded."
}
catch {
    Write-AppLog -Message "Failed to load installer helpers: $($_.Exception.Message)"
    throw
}

# ==========================================
# LOAD INSTALLER ENGINE
# ==========================================

try {
    . $Windows10InstallerPath
    Write-AppLog -Message "Windows 10 installer engine loaded."
}
catch {
    Write-AppLog -Message "Failed to load installer engine: $($_.Exception.Message)"
    throw
}

# ==========================================
# LOAD THEME MANAGER
# ==========================================

try {

    . $ThemeManagerPath
    Initialize-ThemeBackend | Out-Null

    if (-not (Get-Command Invoke-Theme -ErrorAction SilentlyContinue)) {
        throw "Invoke-Theme function was not loaded successfully."
    }

    Write-AppLog -Message "Shared theme manager loaded successfully."
}
catch {
    Write-AppLog -Message "Failed to load theme manager: $($_.Exception.Message)"
    throw
}

# ==========================================
# INITIALIZE GUI MODE
# ==========================================

$Global:AutoMode = $true

Write-AppLog -Message "GUI installer backend loaded successfully."
Write-AppLog -Message "========================================"

Write-Host "Installer backend successfully loaded." -ForegroundColor Green
