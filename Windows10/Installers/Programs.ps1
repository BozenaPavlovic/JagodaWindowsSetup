# ==========================================
# STRAWBERRY WINDOWS - PROGRAM INSTALLER (compatibility wrapper)
# Delegates to Core\Installers\Programs.ps1
# ==========================================

$CoreEngine = Join-Path $PSScriptRoot "..\..\Core\Installers\Programs.ps1"

if (!(Test-Path -LiteralPath $CoreEngine)) {
    throw "Core installer engine not found: $CoreEngine"
}

. $CoreEngine
