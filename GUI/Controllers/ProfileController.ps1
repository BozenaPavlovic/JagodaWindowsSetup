<#
.SYNOPSIS
    Profile controller: load/create/update/delete/validate custom profiles and resolve for install.
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
        $appIds = @($p.AppIds | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | ForEach-Object { [string]$_ } | Select-Object -Unique)
        $valid += [PSCustomObject]@{ Id = $id; Name = $name.Trim(); AppIds = $appIds }
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
        [string]$ExcludeId,
        [array]$ExistingProfiles
    )

    $errors = @()
    $trimName = ""
    if ($null -ne $Name) { $trimName = $Name.Trim() }

    if ([string]::IsNullOrWhiteSpace($trimName)) {
        $errors += "Profile name cannot be empty."
    }

    $cleanIds = @($AppIds | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | ForEach-Object { [string]$_ })
    $uniqueIds = @($cleanIds | Select-Object -Unique)
    if ($cleanIds.Count -ne $uniqueIds.Count) {
        $errors += "Duplicate application references are not allowed."
    }
    if ($uniqueIds.Count -eq 0) {
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

    return [PSCustomObject]@{
        IsValid     = ($errors.Count -eq 0)
        Errors      = @($errors)
        Name        = $trimName
        AppIds      = @($uniqueIds)
    }
}

function global:New-CustomProfile {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string[]]$AppIds
    )

    $profiles = @(Get-AllCustomProfiles)
    $check = Test-ProfileData -Name $Name -AppIds $AppIds -ExistingProfiles $profiles
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
        Id     = $newId
        Name   = $check.Name
        AppIds = @($check.AppIds)
    }

    Save-CustomProfiles -Profiles $profiles
    return ($profiles | Where-Object { $_.Id -eq $newId } | Select-Object -First 1)
}

function global:Update-CustomProfile {
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string[]]$AppIds
    )

    $profiles = @(Get-AllCustomProfiles)
    $existing = $profiles | Where-Object { $_.Id -eq $Id } | Select-Object -First 1
    if (-not $existing) { throw "Profile not found." }

    $check = Test-ProfileData -Name $Name -AppIds $AppIds -ExcludeId $Id -ExistingProfiles $profiles
    if (-not $check.IsValid) {
        throw ($check.Errors -join "`n")
    }

    $updated = @()
    foreach ($p in $profiles) {
        if ($p.Id -eq $Id) {
            $updated += [PSCustomObject]@{ Id = $p.Id; Name = $check.Name; AppIds = @($check.AppIds) }
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

function global:Resolve-ProfileApplications {
    param([Parameter(Mandatory)]$Profile)

    $resolved = @()
    $missing = @()
    foreach ($id in @($Profile.AppIds)) {
        $app = Get-ApplicationById -AppId ([string]$id)
        if ($null -ne $app) {
            $resolved += $app
        } else {
            $missing += [string]$id
        }
    }

    return [PSCustomObject]@{
        Resolved = @($resolved)
        Missing  = @($missing)
        IsValid  = (@($resolved).Count -gt 0)
    }
}


