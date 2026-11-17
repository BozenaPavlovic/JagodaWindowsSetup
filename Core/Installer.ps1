# ==========================================
# STRAWBERRY WINDOWS - INSTALLER ENTRY POINT
# Compatibility shim: loads the shared engine
# from Core\Installers\Programs.ps1.
# ==========================================

$InstallerEnginePath = Join-Path $PSScriptRoot "Installers\Programs.ps1"

if (-not (Test-Path -LiteralPath $InstallerEnginePath -PathType Leaf)) {
    throw "Installer engine not found: $InstallerEnginePath"
}

. $InstallerEnginePath