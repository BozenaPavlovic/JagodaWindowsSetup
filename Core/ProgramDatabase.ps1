
# ==========================================
# STRAWBERRY WINDOWS - PROGRAM DATABASE (compatibility wrapper)
# Delegates to DATABASE\ProgramDatabase.ps1
# ==========================================

$DatabasePath = Join-Path (Split-Path $PSScriptRoot -Parent) "DATABASE\ProgramDatabase.ps1"

if (-not (Test-Path -LiteralPath $DatabasePath -PathType Leaf)) {
    throw "Program database not found: $DatabasePath"
}

. $DatabasePath
