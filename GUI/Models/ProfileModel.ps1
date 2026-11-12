<#
.SYNOPSIS
    Profile data model and JSON persistence for custom installation profiles.
#>

function Get-ProfileStorePath {
    $root = Split-Path $PSScriptRoot -Parent
    $root = Split-Path $root -Parent
    return (Join-Path $root "DATA\Profiles\CustomProfiles.json")
}

function New-EmptyProfileStore {
    return [PSCustomObject]@{ Profiles = @() }
}

function ConvertTo-ProfileObject {
    param($raw)
    if ($null -eq $raw) { return $null }
    $id = ""
    $name = ""
    $appIds = @()
    if ($raw.PSObject.Properties['Id'] -and $null -ne $raw.Id) { $id = [string]$raw.Id }
    if ($raw.PSObject.Properties['Name'] -and $null -ne $raw.Name) { $name = [string]$raw.Name }
    if ($raw.PSObject.Properties['AppIds'] -and $null -ne $raw.AppIds) {
        $appIds = @($raw.AppIds | ForEach-Object { [string]$_ })
    }
    elseif ($raw.PSObject.Properties['ApplicationIds'] -and $null -ne $raw.ApplicationIds) {
        $appIds = @($raw.ApplicationIds | ForEach-Object { [string]$_ })
    }
    return [PSCustomObject]@{
        Id     = $id
        Name   = $name
        AppIds = @($appIds)
    }
}

function Read-ProfileStore {
    param([string]$Path)

    if (-not $Path) { $Path = Get-ProfileStorePath }
    $dir = Split-Path $Path -Parent
    if (-not (Test-Path -LiteralPath $dir -PathType Container)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return (New-EmptyProfileStore)
    }

    try {
        $rawText = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($rawText)) {
            return (New-EmptyProfileStore)
        }
        $data = $rawText | ConvertFrom-Json -ErrorAction Stop
        $profiles = @()
        $items = $null
        if ($null -ne $data -and $data.PSObject.Properties['Profiles']) {
            $items = $data.Profiles
        }
        elseif ($data -is [System.Array]) {
            $items = $data
        }
        if ($null -ne $items) {
            foreach ($item in @($items)) {
                $p = ConvertTo-ProfileObject -raw $item
                if ($null -ne $p) { $profiles += $p }
            }
        }
        return [PSCustomObject]@{ Profiles = @($profiles) }
    }
    catch {
        # Corrupted or invalid JSON: preserve file as .bak and return empty store gracefully.
        try {
            $backup = "$Path.bak_$(Get-Date -Format 'yyyyMMddHHmmss')"
            Copy-Item -LiteralPath $Path -Destination $backup -Force -ErrorAction SilentlyContinue
        } catch { }
        return (New-EmptyProfileStore)
    }
}

function Write-ProfileStore {
    param(
        [Parameter(Mandatory)]$Store,
        [string]$Path
    )

    if (-not $Path) { $Path = Get-ProfileStorePath }
    $dir = Split-Path $Path -Parent
    if (-not (Test-Path -LiteralPath $dir -PathType Container)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    $profilesOut = @()
    foreach ($p in @($Store.Profiles)) {
        $profilesOut += [ordered]@{
            Id     = [string]$p.Id
            Name   = [string]$p.Name
            AppIds = @($p.AppIds | ForEach-Object { [string]$_ })
        }
    }
    $payload = [ordered]@{ Profiles = $profilesOut }
    $json = $payload | ConvertTo-Json -Depth 6

    $temp = "$Path.tmp"
    try {
        Set-Content -LiteralPath $temp -Value $json -Encoding UTF8 -ErrorAction Stop
        Move-Item -LiteralPath $temp -Destination $Path -Force -ErrorAction Stop
        return $true
    }
    catch {
        if (Test-Path -LiteralPath $temp) {
            Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
        }
        throw
    }
}
