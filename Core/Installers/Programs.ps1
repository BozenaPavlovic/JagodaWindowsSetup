# ==========================================
# STRAWBERRY WINDOWS - SHARED INSTALLER ENGINE
# Single entry point that loads modules 01-06.
# ==========================================

$InstallerModuleFiles = @(
    "01_Configuration.ps1"
    "02_UiHelpers.ps1"
    "03_AppDetection.ps1"
    "04_Download.ps1"
    "05_Winget.ps1"
    "06_InstallApplication.ps1"
)

$InstallerHelpersPath = Join-Path (Split-Path $PSScriptRoot -Parent) "InstallerHelpers.ps1"

# ==========================================
# VALIDATE MODULE FILES
# ==========================================

foreach ($moduleFile in $InstallerModuleFiles) {

    $modulePath = Join-Path $PSScriptRoot $moduleFile

    if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
        throw "Required installer module not found: $modulePath"
    }
}

if (-not (Test-Path -LiteralPath $InstallerHelpersPath -PathType Leaf)) {
    throw "Required installer helper not found: $InstallerHelpersPath"
}

# ==========================================
# LOAD SHARED CORE HELPERS
# ==========================================

if (-not (Get-Command Invoke-InstallCooldown -ErrorAction SilentlyContinue)) {
    . $InstallerHelpersPath
}

# ==========================================
# LOAD INSTALLER MODULES
# ==========================================

foreach ($moduleFile in $InstallerModuleFiles) {
    . (Join-Path $PSScriptRoot $moduleFile)
}

Write-Host "[OK] STRAWBERRY WINDOWS installer module loaded." -ForegroundColor Green