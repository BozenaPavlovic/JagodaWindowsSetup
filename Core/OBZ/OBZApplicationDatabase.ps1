# ==========================================
# STRAWBERRY WINDOWS - OBZ APPLICATION DATABASE
# Independent in-memory OBZ application store.
# Does not use or modify DATABASE\ProgramDatabase.ps1.
# No HTML parsing, downloading or installation here.
# ==========================================

$ErrorActionPreference = "Stop"

# ==========================================
# STATE
# ==========================================
# $null  = database has not been loaded yet.
# @{}    = database loaded but empty.
# The Loaded flag distinguishes "initialized empty" from "not loaded".

if (-not (Get-Variable -Name Global:OBZApplicationDatabase -Scope Global -ErrorAction SilentlyContinue)) {
    $Global:OBZApplicationDatabase = $null
}

if (-not (Get-Variable -Name Global:OBZApplicationDatabaseLoaded -Scope Global -ErrorAction SilentlyContinue)) {
    $Global:OBZApplicationDatabaseLoaded = $false
}

# ==========================================
# HELPERS
# ==========================================

function global:Get-OBZStableId {
    <#
        Generates a stable ID from an exact installer filename.
        The ID depends only on the filename bytes, never on list
        position or directory ordering. The original filename and
        extension are preserved by the caller.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FileName
    )

    $md5 = [System.Security.Cryptography.MD5]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($FileName)
        $hash = $md5.ComputeHash($bytes)
    }
    finally {
        $md5.Dispose()
    }

    $builder = New-Object System.Text.StringBuilder
    foreach ($b in $hash) {
        [void]$builder.Append($b.ToString("x2"))
    }

    return $builder.ToString()
}

function global:New-OBZApplicationObject {
    <#
        Builds a normalized OBZ application object.
        Source is always "OBZ". Id is derived from FileName.
        FileName (with extension) is preserved exactly as supplied.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FileName,

        [string]$Name,

        [string]$DownloadUrl,

        [string]$InstallerType
    )

    if ([string]::IsNullOrWhiteSpace($Name)) {
        $Name = [System.IO.Path]::GetFileNameWithoutExtension($FileName)
    }

    # Look up winget ID override
    $wingetId = $null
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($FileName)
    if ($Global:OBZSettings.WingetIdOverrides -and $Global:OBZSettings.WingetIdOverrides.ContainsKey($baseName)) {
        $wingetId = $Global:OBZSettings.WingetIdOverrides[$baseName]
    }

    return [pscustomobject]@{
        Id            = Get-OBZStableId -FileName $FileName
        Name          = $Name
        Source        = "OBZ"
        FileName      = $FileName
        DownloadUrl   = $DownloadUrl
        InstallerType = $InstallerType
        WingetID      = $wingetId
    }
}

# ==========================================
# PUBLIC FUNCTIONS
# ==========================================

function global:Initialize-OBZApplicationDatabase {
    <#
        Initializes an empty, loaded OBZ database.
        After this call the database is "loaded but empty",
        which is distinct from "not loaded".
    #>
    $Global:OBZApplicationDatabase = @{}
    $Global:OBZApplicationDatabaseLoaded = $true
}

function global:Set-OBZApplicationDatabase {
    <#
        Replaces the entire contents of the OBZ database with a
        newly discovered application list. Marks the database as loaded.
        Accepts objects providing FileName (plus optional Name,
        DownloadUrl, InstallerType). Source is forced to "OBZ" and
        Id is recomputed from FileName.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$Applications
    )

    $newStore = @{}
    $index = 0

    foreach ($app in $Applications) {
        $index++

        if ($null -eq $app) {
            continue
        }

        $fileName = $null

        if ($app -is [string]) {
            $fileName = $app
        }
        elseif ($app.PSObject.Properties['FileName']) {
            $fileName = [string]$app.FileName
        }

        if ([string]::IsNullOrWhiteSpace($fileName)) {
            throw "OBZ application at index $index has no FileName."
        }

        $name = $null
        if ($app -isnot [string] -and $app.PSObject.Properties['Name']) {
            $name = [string]$app.Name
        }

        $downloadUrl = $null
        if ($app -isnot [string] -and $app.PSObject.Properties['DownloadUrl']) {
            $downloadUrl = [string]$app.DownloadUrl
        }

        $installerType = $null
        if ($app -isnot [string] -and $app.PSObject.Properties['InstallerType']) {
            $installerType = [string]$app.InstallerType
        }

        $obj = New-OBZApplicationObject `
            -FileName $fileName `
            -Name $name `
            -DownloadUrl $downloadUrl `
            -InstallerType $installerType

        $newStore[$obj.Id] = $obj
    }

    $Global:OBZApplicationDatabase = $newStore
    $Global:OBZApplicationDatabaseLoaded = $true
}

function global:Get-OBZApplication {
    <#
        Returns all OBZ applications.
        If the database has not been loaded, returns nothing.
    #>
    if (-not $Global:OBZApplicationDatabaseLoaded) {
        return @()
    }

    return @($Global:OBZApplicationDatabase.Values)
}

function global:Get-OBZApplicationById {
    <#
        Finds a single OBZ application by its stable Id.
        Returns $null when not found or not loaded.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Id
    )

    if (-not $Global:OBZApplicationDatabaseLoaded) {
        return $null
    }

    if ($Global:OBZApplicationDatabase.ContainsKey($Id)) {
        return $Global:OBZApplicationDatabase[$Id]
    }

    return $null
}

function global:Test-OBZApplication {
    <#
        Checks whether an OBZ application with the given Id exists.
        Returns $false when the database has not been loaded.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Id
    )

    if (-not $Global:OBZApplicationDatabaseLoaded) {
        return $false
    }

    return $Global:OBZApplicationDatabase.ContainsKey($Id)
}

Write-Host "[OK] STRAWBERRY WINDOWS OBZ application database loaded." -ForegroundColor Green