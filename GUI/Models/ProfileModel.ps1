<#
.SYNOPSIS
    Profile data model and JSON persistence for custom installation profiles.

    Application references are stored canonically as objects with:
        AppId  - stable identifier (Standard: Number, OBZ: filename-derived Id)
        Source - "Standard" or "OBZ"
        Name   - display name (informational only)

    Backward compatibility:
        - Legacy "AppIds"/"ApplicationIds" string arrays are read as Standard refs.
        - "AppIds" is still written as a mirror of Applications' AppIds.
        - Checkbox positions / list indexes are never stored.
#>

function global:Get-ProfileStorePath {
    $root = Split-Path $PSScriptRoot -Parent
    $root = Split-Path $root -Parent
    return (Join-Path $root "DATA\Profiles\CustomProfiles.json")
}

function global:New-EmptyProfileStore {
    return [PSCustomObject]@{ Profiles = @() }
}

function global:ConvertTo-ProfileAppReference {
    param($raw)

    if ($null -eq $raw) { return $null }

    $appId = ""
    $source = "Standard"
    $name = ""

    if ($raw -is [string]) {
        $appId = $raw
    }
    else {
        if ($raw.PSObject.Properties['AppId'] -and $null -ne $raw.AppId) {
            $appId = [string]$raw.AppId
        }
        elseif ($raw.PSObject.Properties['Id'] -and $null -ne $raw.Id) {
            $appId = [string]$raw.Id
        }

        if ($raw.PSObject.Properties['Source'] -and -not [string]::IsNullOrWhiteSpace([string]$raw.Source)) {
            $source = [string]$raw.Source
        }

        if ($raw.PSObject.Properties['Name'] -and $null -ne $raw.Name) {
            $name = [string]$raw.Name
        }
    }

    if ([string]::IsNullOrWhiteSpace($appId)) { return $null }

    return [PSCustomObject]@{
        AppId  = $appId
        Source = $source
        Name   = $name
    }
}

function global:Get-ProfileAppReferences {
    param($Profile)

    if ($null -eq $Profile) { return @() }

    $refs = @()

    if ($Profile.PSObject.Properties['Applications'] -and $null -ne $Profile.Applications) {
        foreach ($a in @($Profile.Applications)) {
            $r = ConvertTo-ProfileAppReference $a
            if ($null -ne $r) { $refs += $r }
        }
    }
    elseif ($Profile.PSObject.Properties['AppIds'] -and $null -ne $Profile.AppIds) {
        foreach ($id in @($Profile.AppIds)) {
            if (-not [string]::IsNullOrWhiteSpace([string]$id)) {
                $refs += [PSCustomObject]@{
                    AppId  = [string]$id
                    Source = "Standard"
                    Name   = ""
                }
            }
        }
    }
    elseif ($Profile.PSObject.Properties['ApplicationIds'] -and $null -ne $Profile.ApplicationIds) {
        foreach ($id in @($Profile.ApplicationIds)) {
            if (-not [string]::IsNullOrWhiteSpace([string]$id)) {
                $refs += [PSCustomObject]@{
                    AppId  = [string]$id
                    Source = "Standard"
                    Name   = ""
                }
            }
        }
    }

    return @($refs)
}

function global:ConvertTo-ProfileObject {
    param($raw)
    if ($null -eq $raw) { return $null }

    $id = ""
    $name = ""
    if ($raw.PSObject.Properties['Id'] -and $null -ne $raw.Id) { $id = [string]$raw.Id }
    if ($raw.PSObject.Properties['Name'] -and $null -ne $raw.Name) { $name = [string]$raw.Name }

    $apps = Get-ProfileAppReferences -Profile $raw
    $appIds = @($apps | ForEach-Object { [string]$_.AppId })

    return [PSCustomObject]@{
        Id           = $id
        Name         = $name
        Applications = @($apps)
        AppIds       = @($appIds)
    }
}

function global:Read-ProfileStore {
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

function global:Write-ProfileStore {
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
        $refs = Get-ProfileAppReferences -Profile $p

        $appsOut = @()
        foreach ($r in $refs) {
            $appsOut += [ordered]@{
                AppId  = [string]$r.AppId
                Source = [string]$r.Source
                Name   = [string]$r.Name
            }
        }

        $appIdsOut = @($appsOut | ForEach-Object { [string]$_.AppId })

        $profilesOut += [ordered]@{
            Id           = [string]$p.Id
            Name         = [string]$p.Name
            Applications = @($appsOut)
            AppIds       = @($appIdsOut)
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