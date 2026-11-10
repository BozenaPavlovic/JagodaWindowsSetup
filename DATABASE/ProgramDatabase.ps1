# ==========================================
# STRAWBERRY WINDOWS - PROGRAM DATABASE
# Loads categorized installer definitions from DATABASE\Installers
# ==========================================

$InstallersPath = Join-Path $PSScriptRoot "Installers"

if (-not (Test-Path -LiteralPath $InstallersPath -PathType Container)) {
    throw "Installer database folder not found: $InstallersPath"
}

$allApps = @()

Get-ChildItem -LiteralPath $InstallersPath -Filter "*.ps1" -File | Sort-Object Name | ForEach-Object {
    $items = . $_.FullName
    if ($null -ne $items) {
        foreach ($item in @($items)) {
            if ($item -is [hashtable] -or $item -is [System.Collections.IDictionary] -or $item.PSObject.Properties['Name']) {
                $allApps += $item
            }
        }
    }
}

$Global:Apps = $allApps
