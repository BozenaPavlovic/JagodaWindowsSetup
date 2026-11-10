
# ==========================================
# STRAWBERRY WINDOWS - SHARED PATHS
# ==========================================
# Resolves the repository root reliably regardless of which script calls it,
# by walking up the directory tree until it finds main.ps1.

function Get-ProjectRoot {
    param([string]$StartPath = $PSScriptRoot)

    $current = [System.IO.Path]::GetFullPath($StartPath)
    while ($current) {
        if (Test-Path -LiteralPath (Join-Path $current "main.ps1") -PathType Leaf) {
            return $current
        }
        $parent = [System.IO.Path]::GetDirectoryName($current)
        if ($parent -eq $current) {
            break
        }
        $current = $parent
    }

    throw "Could not locate repository root (main.ps1 not found above $StartPath)"
}

$Global:ProjectRoot = Get-ProjectRoot $PSScriptRoot
$Global:DataFolder = Join-Path $Global:ProjectRoot "DATA"
$Global:PhotosFolder = Join-Path $Global:DataFolder "Photos"
$Global:LogsFolder = Join-Path $Global:ProjectRoot "Logs"
