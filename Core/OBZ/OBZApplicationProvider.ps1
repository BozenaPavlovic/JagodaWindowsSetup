# ==========================================
# STRAWBERRY WINDOWS - OBZ APPLICATION PROVIDER
# Discovers OBZ installers from the configured directory listing.
# Loads OBZConfiguration.ps1 and OBZApplicationDatabase.ps1.
# Does not download or execute installers.
# ==========================================

if ($Global:OBZBackendLoaded) { return }

$ErrorActionPreference = "Stop"

$OBZProviderConfigPath = Join-Path $PSScriptRoot "OBZConfiguration.ps1"
$OBZProviderDatabasePath = Join-Path $PSScriptRoot "OBZApplicationDatabase.ps1"

if (-not (Test-Path -LiteralPath $OBZProviderConfigPath -PathType Leaf)) {
    throw "OBZ configuration not found: $OBZProviderConfigPath"
}

if (-not (Test-Path -LiteralPath $OBZProviderDatabasePath -PathType Leaf)) {
    throw "OBZ application database not found: $OBZProviderDatabasePath"
}

# Load configuration (populates $Global:OBZSettings) and the database.
. $OBZProviderConfigPath
. $OBZProviderDatabasePath

# ==========================================
# PARSING HELPERS
# ==========================================

function Get-OBZInstallerLinks {
    <#
        Parses an HTML directory listing and returns valid EXE
        installer links as objects { FileName, DownloadUrl }.
        Ignores parent links, subdirectories, navigation and
        unrelated files. Handles URL-encoded filenames.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Html,

        [Parameter(Mandatory = $true)]
        [string]$BaseUrl
    )

    $results = @()
    $seen = @{}

    # Match href values in double or single quotes.
    $anchorPattern = '(?is)<a\b[^>]*?href\s*=\s*(["''])(.*?)\1'
    $anchorMatches = [regex]::Matches($Html, $anchorPattern)

    foreach ($m in $anchorMatches) {
        $href = $m.Groups[2].Value.Trim()

        if ([string]::IsNullOrWhiteSpace($href)) {
            continue
        }

        # Ignore navigation / sort links (e.g. ?C=N;O=D), anchors,
        # mail and absolute external links.
        if ($href.StartsWith("#")) { continue }
        if ($href.StartsWith("?")) { continue }
        if ($href.Contains("?")) { continue }
        if ($href.StartsWith("/")) { continue }
        if ($href -match '^[a-z]+://') { continue }

        # Ignore parent directory links and any subdirectory (trailing slash).
        if ($href.EndsWith("/")) { continue }
        if ($href -eq "..") { continue }
        if ($href -eq "../") { continue }

        # Decode the URL-encoded filename for a clean leaf name.
        $decoded = [System.Uri]::UnescapeDataString($href)
        $leaf = Split-Path -Path $decoded -Leaf

        if ([string]::IsNullOrWhiteSpace($leaf)) { continue }

        # Supported installers: EXE and MSI.
        $installerType = $null
        if ($leaf -match '\.exe$') {
            $installerType = "exe"
        }
        elseif ($leaf -match '\.msi$') {
            $installerType = "msi"
        }
        else {
            continue
        }

        # Build the absolute download URL from the raw (encoded) href.
        $baseUri = New-Object System.Uri($BaseUrl)
        $absUri = New-Object System.Uri($baseUri, $href)
        $downloadUrl = $absUri.AbsoluteUri

        # De-duplicate by filename (case-insensitive).
        $key = $leaf.ToLowerInvariant()
        if ($seen.ContainsKey($key)) { continue }
        $seen[$key] = $true

        $results += [pscustomobject]@{
            FileName      = $leaf
            DownloadUrl   = $downloadUrl
            InstallerType = $installerType
        }
    }

    return @($results)
}

# ==========================================
# DISCOVERY
# ==========================================

function Update-OBZApplicationDatabase {
    <#
        Retrieves the OBZ directory listing, parses valid EXE
        installers and refreshes the in-memory database.

        Returns a result object:
            Status = "Success" | "ServerUnavailable" | "ParseFailure"
            Count  = number of applications (when Success)
            Message= human readable message
            Applications = discovered list (when Success)

        The previous valid list is preserved on network or
        parsing failures; it is replaced only after a successful
        refresh (including a successful zero-result refresh).
    #>
    $baseUrl = $Global:OBZSettings.ApplicationDirectoryUrl
    $timeout = [int]$Global:OBZSettings.ServerTimeoutSeconds

    # --- Retrieve HTML ---
    $html = $null
    try {
        $response = Invoke-WebRequest -Uri $baseUrl -UseBasicParsing -TimeoutSec $timeout -ErrorAction Stop
        $html = $response.Content
    }
    catch {
        return [pscustomobject]@{
            Status       = "ServerUnavailable"
            Count        = 0
            Message      = $Global:OBZSettings.Messages.ServerUnavailable
            Applications = @()
        }
    }

    if ([string]::IsNullOrWhiteSpace($html)) {
        return [pscustomobject]@{
            Status       = "ServerUnavailable"
            Count        = 0
            Message      = $Global:OBZSettings.Messages.ServerUnavailable
            Applications = @()
        }
    }

    # --- Validate HTML (must contain anchor elements) ---
    if ($html -notmatch '(?is)<a\b') {
        return [pscustomobject]@{
            Status       = "ParseFailure"
            Count        = 0
            Message      = $Global:OBZSettings.Messages.FailedToRetrieveApplicationList
            Applications = @()
        }
    }

    # --- Parse installers ---
    $apps = @()
    try {
        $apps = Get-OBZInstallerLinks -Html $html -BaseUrl $baseUrl
    }
    catch {
        return [pscustomobject]@{
            Status       = "ParseFailure"
            Count        = 0
            Message      = $Global:OBZSettings.Messages.FailedToRetrieveApplicationList
            Applications = @()
        }
    }

    # --- Success: replace the in-memory list (even when empty) ---
    Set-OBZApplicationDatabase -Applications $apps | Out-Null

    if ($apps.Count -eq 0) {
        $message = $Global:OBZSettings.Messages.NoApplicationsAvailable
    }
    else {
        $message = $Global:OBZSettings.Messages.LoadingApplications
    }

    return [pscustomobject]@{
        Status       = "Success"
        Count        = $apps.Count
        Message      = $message
        Applications = @($apps)
    }
}

$Global:OBZBackendLoaded = $true
Write-Host "[OK] STRAWBERRY WINDOWS OBZ application provider loaded." -ForegroundColor Green