
<#
.SYNOPSIS
    Loads the Strawberry Windows installer backend.
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

# ==========================================
# VALIDATE FILES
# ==========================================

$RequiredFiles = @(
    $LoggingPath,
    $DatabasePath,
    $InstallerHelpersPath,
    $Windows10InstallerPath
)

foreach ($file in $RequiredFiles) {
    if (-not (Test-Path -LiteralPath $file)) {
        throw "Required backend file not found: $file"
    }
}

# ==========================================
# LOAD LOGGING
# ==========================================

if (-not (Get-Command Write-AppLog -ErrorAction SilentlyContinue)) {
    . $LoggingPath
}

Write-AppLog -Message "========================================"
Write-AppLog -Message "GUI installer backend loading started."

# ==========================================
# LOAD DATABASE
# ==========================================

. $DatabasePath

Write-AppLog -Message "Application database loaded."

# ==========================================
# LOAD HELPERS
# ==========================================

. $InstallerHelpersPath

Write-AppLog -Message "Installer helpers loaded."

# ==========================================
# LOAD INSTALLER ENGINE
# ==========================================

. $Windows10InstallerPath

Write-AppLog -Message "Windows 10 installer engine loaded."

# ==========================================
# INITIALIZE GUI MODE
# ==========================================

$Global:AutoMode = $true

Write-AppLog -Message "GUI installer backend loaded successfully."
Write-AppLog -Message "========================================"

Write-Host "Installer backend successfully loaded." -ForegroundColor Green
