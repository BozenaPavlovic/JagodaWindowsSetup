<#
.SYNOPSIS
    Profile controller: load/create/update/delete/validate custom profiles and resolve for install.

    Supports both Standard and OBZ application references. Each reference is
    normalized to { AppId, Source, Name } where Source is "Standard" or "OBZ".
    OBZ references are resolved against the current OBZ database at load/install
    time; unavailable OBZ applications are reported clearly.
#>

function global:Get-ProfileControllerStorePath {
    return (Get-ProfileStorePath)
}

function global:Get-AllCustomProfiles {
    $store = Read-ProfileStore
    # Normalize and filter invalid entries defensively
    $valid = @()
    $seenIds = @{}
    $seenNames = @{}
    foreach ($p in @($store.Profiles)) {
        if ($null -eq $p) { continue }
        $id = [string]$p.Id
        $name = [string]$p.Name
        if ([string]::IsNullOrWhiteSpace($id) -or [string]::IsNullOrWhiteSpace($name)) { continue }
        $keyId = $id.ToLowerInvariant()
        $keyName = $name.Trim().ToLowerInvariant()
        if ($seenIds.ContainsKey($keyId) -or $seenNames.ContainsKey($keyName)) { continue }
        $seenIds[$keyId] = $true
        $seenNames[$keyName] = $true

        $refs = Get-ProfileAppReferences -Profile $p

        # De-duplicate references by Source + AppId (stable identity, never index).
        $seenRefs = @{}
        $uniqueRefs = @()
        foreach ($r in $refs) {
            $refKey = ("{0}|{1}" -f [string]$r.Source, [string]$r.AppId).ToLowerInvariant()
            if ($seenRefs.ContainsKey($refKey)) { continue }
            $seenRefs[$refKey] = $true
            $uniqueRefs += [PSCustomObject]@{
                AppId  = [string]$r.AppId
                Source = [string]$r.Source
                Name   = [string]$r.Name
            }
        }

        $appIds = @($uniqueRefs | ForEach-Object { [string]$_.AppId })

        $valid += [PSCustomObject]@{
            Id           = $id
            Name         = $name.Trim()
            Applications = @($uniqueRefs)
            AppIds       = @($appIds)
        }
    }
    return @($valid)
}

function global:Save-CustomProfiles {
    param([Parameter(Mandatory)][AllowEmptyCollection()][array]$Profiles)
    $store = [PSCustomObject]@{ Profiles = @($Profiles) }
    Write-ProfileStore -Store $store
}

function global:Test-ProfileData {
    param(
        [string]$Name,
        [string[]]$AppIds,
        [array]$Applications,
        [string]$ExcludeId,
        [array]$ExistingProfiles
    )

    $errors = @()
    $trimName = ""
    if ($null -ne $Name) { $trimName = $Name.Trim() }

    if ([string]::IsNullOrWhiteSpace($trimName)) {
        $errors += "Profile name cannot be empty."
    }

    # Build references from Applications (preferred) or legacy AppIds.
    $refs = @()
    if ($Applications -and @($Applications).Count -gt 0) {
        foreach ($a in $Applications) {
            $r = ConvertTo-ProfileAppReference $a
            if ($null -ne $r) { $refs += $r }
        }
    }
    else {
        foreach ($id in @($AppIds)) {
            if (-not [string]::IsNullOrWhiteSpace([string]$id)) {
                $refs += [PSCustomObject]@{
                    AppId  = [string]$id
                    Source = "Standard"
                    Name   = ""
                }
            }
        }
    }

    # De-duplicate by stable Source + AppId identity.
    $seen = @{}
    $unique = @()
    foreach ($r in $refs) {
        $key = ("{0}|{1}" -f [string]$r.Source, [string]$r.AppId).ToLowerInvariant()
        if ($seen.ContainsKey($key)) { continue }
        $seen[$key] = $true
        $unique += $r
    }

    if ($refs.Count -ne $unique.Count) {
        $errors += "Duplicate application references are not allowed."
    }
    if ($unique.Count -eq 0) {
        $errors += "Profile must include at least one application."
    }

    if (-not $ExistingProfiles) { $ExistingProfiles = @(Get-AllCustomProfiles) }
    foreach ($p in @($ExistingProfiles)) {
        if ($ExcludeId -and ([string]$p.Id -eq [string]$ExcludeId)) { continue }
        if (-not [string]::IsNullOrWhiteSpace($trimName) -and ($p.Name.Trim().ToLowerInvariant() -eq $trimName.ToLowerInvariant())) {
            $errors += "A profile with this name already exists."
            break
        }
    }

    $appIds = @($unique | ForEach-Object { [string]$_.AppId })

    return [PSCustomObject]@{
        IsValid      = ($errors.Count -eq 0)
        Errors       = @($errors)
        Name         = $trimName
        Applications = @($unique)
        AppIds       = @($appIds)
    }
}

function global:New-CustomProfile {
    param(
        [Parameter(Mandatory)][string]$Name,
        [string[]]$AppIds,
        [array]$Applications
    )

    $profiles = @(Get-AllCustomProfiles)
    $check = Test-ProfileData -Name $Name -AppIds $AppIds -Applications $Applications -ExistingProfiles $profiles
    if (-not $check.IsValid) {
        throw ($check.Errors -join "`n")
    }

    $newId = [Guid]::NewGuid().ToString()
    $tries = 0
    while (@($profiles | Where-Object { $_.Id -eq $newId }).Count -gt 0 -and $tries -lt 5) {
        $newId = [Guid]::NewGuid().ToString()
        $tries++
    }
    if (@($profiles | Where-Object { $_.Id -eq $newId }).Count -gt 0) {
        throw "Failed to generate a unique profile ID."
    }

    $profiles += [PSCustomObject]@{
        Id           = $newId
        Name         = $check.Name
        Applications = @($check.Applications)
        AppIds       = @($check.AppIds)
    }

    Save-CustomProfiles -Profiles $profiles
    return ($profiles | Where-Object { $_.Id -eq $newId } | Select-Object -First 1)
}

function global:Update-CustomProfile {
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Name,
        [string[]]$AppIds,
        [array]$Applications
    )

    $profiles = @(Get-AllCustomProfiles)
    $existing = $profiles | Where-Object { $_.Id -eq $Id } | Select-Object -First 1
    if (-not $existing) { throw "Profile not found." }

    $check = Test-ProfileData -Name $Name -AppIds $AppIds -Applications $Applications -ExcludeId $Id -ExistingProfiles $profiles
    if (-not $check.IsValid) {
        throw ($check.Errors -join "`n")
    }

    $updated = @()
    foreach ($p in $profiles) {
        if ($p.Id -eq $Id) {
            $updated += [PSCustomObject]@{
                Id           = $p.Id
                Name         = $check.Name
                Applications = @($check.Applications)
                AppIds       = @($check.AppIds)
            }
        } else {
            $updated += $p
        }
    }

    Save-CustomProfiles -Profiles $updated
    return ($updated | Where-Object { $_.Id -eq $Id } | Select-Object -First 1)
}

function global:Remove-CustomProfile {
    param([Parameter(Mandatory)][string]$Id)

    $profiles = @(Get-AllCustomProfiles)
    $remaining = @($profiles | Where-Object { $_.Id -ne $Id })
    if ($remaining.Count -eq $profiles.Count) {
        throw "Profile not found."
    }
    Save-CustomProfiles -Profiles $remaining
    return $true
}

function global:Get-CustomProfileById {
    param([Parameter(Mandatory)][string]$Id)
    $profiles = @(Get-AllCustomProfiles)
    return ($profiles | Where-Object { [string]$_.Id -eq [string]$Id } | Select-Object -First 1)
}

function global:Get-ApplicationById {
    param([Parameter(Mandatory)][string]$AppId)
    foreach ($app in @($Global:Apps)) {
        if ($null -ne $app -and [string]$app.Number -eq [string]$AppId) { return $app }
    }
    return $null
}

function global:Get-ResolvedOBZApplication {
    param([Parameter(Mandatory)][string]$AppId)

    if (Get-Command Get-OBZApplicationById -ErrorAction SilentlyContinue) {
        return (Get-OBZApplicationById -Id $AppId)
    }
    return $null
}

function global:Resolve-ProfileApplications {
    param([Parameter(Mandatory)]$Profile)

    $resolved = @()
    $missing = @()
    $unavailableObz = @()

    $refs = Get-ProfileAppReferences -Profile $Profile

    foreach ($ref in $refs) {
        $source = if ($ref.Source) { [string]$ref.Source } else { "Standard" }
        $appId = [string]$ref.AppId

        if ($source -eq "OBZ") {
            $obz = Get-ResolvedOBZApplication -AppId $appId
            if ($null -ne $obz) {
                $resolved += $obz
            }
            else {
                $missing += "OBZ:$appId"
                $unavailableObz += [PSCustomObject]@{
                    AppId = $appId
                    Name  = [string]$ref.Name
                }
            }
        }
        else {
            $app = Get-ApplicationById -AppId $appId
            if ($null -ne $app) {
                $resolved += $app
            }
            else {
                $missing += "Standard:$appId"
            }
        }
    }

    return [PSCustomObject]@{
        Resolved       = @($resolved)
        Missing        = @($missing)
        UnavailableOBZ = @($unavailableObz)
        IsValid        = (@($resolved).Count -gt 0)
    }
}