# ==========================================
# STRAWBERRY WINDOWS - OBZ INSTALLER BACKEND
# Separate OBZ download + execution engine.
# Accepts only validated OBZ database references.
# Never uses Winget. Does not touch the standard engine.
# ==========================================

$ErrorActionPreference = "Stop"

$OBZInstallerConfigPath = Join-Path $PSScriptRoot "OBZConfiguration.ps1"
$OBZInstallerDatabasePath = Join-Path $PSScriptRoot "OBZApplicationDatabase.ps1"

if (-not (Test-Path -LiteralPath $OBZInstallerConfigPath -PathType Leaf)) {
    throw "OBZ configuration not found: $OBZInstallerConfigPath"
}

if (-not (Test-Path -LiteralPath $OBZInstallerDatabasePath -PathType Leaf)) {
    throw "OBZ application database not found: $OBZInstallerDatabasePath"
}

. $OBZInstallerConfigPath
. $OBZInstallerDatabasePath

# ==========================================
# SEPARATE OBZ LOGGING
# ==========================================

$OBZInstallerRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$OBZInstallerLogDirectory = Join-Path $OBZInstallerRoot "Logs"

if (-not (Test-Path -LiteralPath $OBZInstallerLogDirectory -PathType Container)) {
    New-Item -ItemType Directory -Path $OBZInstallerLogDirectory -Force | Out-Null
}

$Global:OBZInstallationLog = Join-Path $OBZInstallerLogDirectory "OBZInstallation.log"

function Write-OBZLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $user = [Environment]::UserName
    $computer = $env:COMPUTERNAME

    $entry = "[$timestamp] [$Level] [$computer] [$user] $Message"

    try {
        Add-Content -LiteralPath $Global:OBZInstallationLog -Value $entry -Encoding UTF8 -ErrorAction Stop
    }
    catch {
        Write-Warning "OBZ logging failed: $($_.Exception.Message)"
    }

    # Also output to console (like standard installer)
    $color = switch ($Level) {
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR"   { "Red" }
        default   { "Cyan" }
    }
    if (Get-Command Write-Host -ErrorAction SilentlyContinue) {
        Write-Host "[OBZ] $Message" -ForegroundColor $color
    }
}

# ==========================================
# VALIDATION HELPERS
# ==========================================

function Resolve-OBZApplicationReference {
    <#
        Resolves a caller-supplied reference to the canonical object
        stored in the current OBZ database. Only the database copy
        is ever used, so URLs/paths cannot be injected from outside.
    #>
    param(
        [string]$Id,

        [psobject]$Application
    )

    if (-not $Id -and $null -ne $Application -and $Application.PSObject.Properties['Id']) {
        $Id = [string]$Application.Id
    }

    if ([string]::IsNullOrWhiteSpace($Id)) {
        throw "No OBZ application reference supplied."
    }

    if (-not (Test-OBZApplication -Id $Id)) {
        throw "Application '$Id' does not exist in the current OBZ database."
    }

    return Get-OBZApplicationById -Id $Id
}

function Test-OBZDownloadUrl {
    <#
        Ensures the download URL is absolute HTTP(S) and belongs to
        the configured OBZ server. Prevents arbitrary external URLs.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$DownloadUrl
    )

    $uri = $null
    if (-not [System.Uri]::TryCreate($DownloadUrl, [System.UriKind]::Absolute, [ref]$uri)) {
        return $false
    }

    if ($uri.Scheme -ne "http" -and $uri.Scheme -ne "https") {
        return $false
    }

    $base = $Global:OBZSettings.ApplicationDirectoryUrl
    if ([string]::IsNullOrWhiteSpace($base)) {
        return $false
    }

    return $DownloadUrl.StartsWith($base, [System.StringComparison]::OrdinalIgnoreCase)
}

function Test-OBZInstallerFile {
    <#
        Validates a downloaded EXE: exists, non-empty, and has a
        valid DOS/PE "MZ" header.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $false
    }

    $item = Get-Item -LiteralPath $Path
    if ($item.Length -le 0) {
        return $false
    }

    try {
        $stream = [System.IO.File]::OpenRead($Path)
        try {
            $buffer = New-Object byte[] 2
            $read = $stream.Read($buffer, 0, 2)
            if ($read -lt 2) { return $false }
            if ($buffer[0] -ne 0x4D -or $buffer[1] -ne 0x5A) { return $false }
        }
        finally {
            $stream.Dispose()
        }
    }
    catch {
        return $false
    }

    return $true
}

# ==========================================
# PRE-INSTALL CHECK
# ==========================================

function Test-OBZAppInstalled {
    <#
        Checks if an OBZ application is already installed on the system.
        Uses the standard registry + AppX detection (same as uninstaller).
        Matches by application Name or DisplayName from OBZ database.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Application
    )

    # Load uninstaller detection functions if not already loaded
    $UninstallerRoot = Join-Path $OBZInstallerRoot "Core\Uninstallers"
    $RegistryDetection = Join-Path $UninstallerRoot "02_RegistryDetection.ps1"
    $AppXDetection = Join-Path $UninstallerRoot "03_AppXDetection.ps1"

    if (-not (Get-Command Get-InstalledProgramsFromRegistry -ErrorAction SilentlyContinue)) {
        if (Test-Path -LiteralPath $RegistryDetection) {
            . $RegistryDetection
        }
    }

    if (-not (Get-Command Get-InstalledProgramsFromAppx -ErrorAction SilentlyContinue)) {
        if (Test-Path -LiteralPath $AppXDetection) {
            . $AppXDetection
        }
    }

    $searchNames = @()
    if ($Application.Name) { $searchNames += $Application.Name }
    if ($Application.DisplayName) { $searchNames += $Application.DisplayName }
    if ($Application.FileName) { $searchNames += [System.IO.Path]::GetFileNameWithoutExtension($Application.FileName) }

    # Add display name overrides from config
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($Application.FileName)
    if ($Global:OBZSettings.DisplayNameOverrides -and $Global:OBZSettings.DisplayNameOverrides.ContainsKey($baseName)) {
        $override = $Global:OBZSettings.DisplayNameOverrides[$baseName]
        if ($override) { $searchNames += $override }
    }

    Write-OBZLog -Level INFO -Message "Checking if already installed: $($Application.Name) (search names: $($searchNames -join ', '))"

    foreach ($name in $searchNames) {
        if ([string]::IsNullOrWhiteSpace($name)) { continue }

        # Check registry programs
        try {
            $regMatches = Get-InstalledProgramsFromRegistry -Pattern $name
            if ($regMatches -and $regMatches.Count -gt 0) {
                Write-OBZLog -Level INFO -Message "OBZ app '$($Application.Name)' already installed (registry match: $name) - found: $($regMatches.DisplayName -join ', ')"
                return $true
            }
        }
        catch { 
            Write-OBZLog -Level WARNING -Message "Registry check failed for '$name': $($_.Exception.Message)"
        }

        # Check AppX programs
        try {
            $appxMatches = Get-InstalledProgramsFromAppx -Pattern $name
            if ($appxMatches -and $appxMatches.Count -gt 0) {
                Write-OBZLog -Level INFO -Message "OBZ app '$($Application.Name)' already installed (AppX match: $name) - found: $($appxMatches.Name -join ', ')"
                return $true
            }
        }
        catch { 
            Write-OBZLog -Level WARNING -Message "AppX check failed for '$name': $($_.Exception.Message)"
        }
    }

    Write-OBZLog -Level INFO -Message "Not installed: $($Application.Name)"
    return $false
}

# ==========================================
# DOWNLOAD
# ==========================================

function Get-OBZInstallerFile {
    <#
        Downloads the installer to the dedicated OBZ download folder.
        Uses the configured timeout and retry settings.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$Application
    )

    $downloadFolder = $Global:OBZSettings.DownloadFolder
    if ([string]::IsNullOrWhiteSpace($downloadFolder)) {
        $downloadFolder = Join-Path $OBZInstallerRoot "DATABASE\OBZ\Downloads"
    }

    $downloadFolder = [IO.Path]::GetFullPath($downloadFolder)

    if (-not (Test-Path -LiteralPath $downloadFolder -PathType Container)) {
        New-Item -ItemType Directory -Path $downloadFolder -Force -ErrorAction Stop | Out-Null
    }

    $installer = Join-Path $downloadFolder $Application.FileName
    $temporary = "$installer.partial"

    $timeoutSec = [int]$Global:OBZSettings.DownloadTimeoutSeconds
    $retries = [int]$Global:OBZSettings.DownloadRetries
    if ($retries -lt 1) { $retries = 1 }
    $retryDelay = [int]$Global:OBZSettings.RetryDelaySeconds

    Write-OBZLog -Level INFO -Message "Downloading: $($Application.FileName) from $($Application.DownloadUrl) (timeout: ${timeoutSec}s, retries: $retries)"

    $oldProgressPreference = $ProgressPreference
    $ProgressPreference = "SilentlyContinue"

    try {
        for ($attempt = 1; $attempt -le $retries; $attempt++) {

            if (Test-Path -LiteralPath $temporary) {
                Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue
            }

            try {
                Write-OBZLog -Level INFO -Message "Download attempt $attempt of $retries for $($Application.FileName)"

                $headers = @{
                    "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
                }

                Invoke-WebRequest -Uri $Application.DownloadUrl -OutFile $temporary -Headers $headers -TimeoutSec $timeoutSec -UseBasicParsing -ErrorAction Stop
                
                Write-OBZLog -Level INFO -Message "Download completed for $($Application.FileName) on attempt $attempt"
                break
            }
            catch {
                Write-OBZLog -Level WARNING -Message "Download attempt $attempt failed for $($Application.FileName): $($_.Exception.Message)"
                if ($attempt -ge $retries) {
                    throw
                }
                Start-Sleep -Seconds $retryDelay
            }
        }
    }
    finally {
        $ProgressPreference = $oldProgressPreference
    }

    if (-not (Test-Path -LiteralPath $temporary -PathType Leaf)) {
        throw "Downloaded file does not exist."
    }

    if (-not (Test-OBZInstallerFile -Path $temporary)) {
        throw "Downloaded file failed validation."
    }

    Move-Item -LiteralPath $temporary -Destination $installer -Force

    Write-OBZLog -Level INFO -Message "Installer saved to: $installer"

    return $installer
}

# ==========================================
# INSTALL
# ==========================================

function Install-OBZApplication {
    <#
        Installs a single OBZ application.

        Accepts an Id (preferred) or an Application object; the
        reference is validated against the current OBZ database and
        only the stored database values are used.

        Returns an object:
            Status = "Success" | "Error" | "Skipped"
            ExitCode = process exit code (when available)
            InstallerPath = local installer path
            Message = human readable message
    #>
    param(
        [string]$Id,

        [psobject]$Application,

        [string[]]$Arguments = @()
    )

    try {
        $app = Resolve-OBZApplicationReference -Id $Id -Application $Application

        if ($app.InstallerType -and $app.InstallerType -ne "exe") {
            throw "Unsupported OBZ installer type '$($app.InstallerType)'."
        }

        if ($app.FileName -notmatch '\.exe$') {
            throw "Only EXE installers are supported. File: $($app.FileName)"
        }

        if (-not (Test-OBZDownloadUrl -DownloadUrl $app.DownloadUrl)) {
            throw "Download URL is not a valid OBZ server URL."
        }

        # --- Pre-install check ---
        if (Test-OBZAppInstalled -Application $app) {
            Write-OBZLog -Level INFO -Message "OBZ app already installed, skipping: $($app.Name) [$($app.Id)]"
            Write-Host "`n========================================" -ForegroundColor Magenta
            Write-Host " OBZ PROGRESS: $($app.Name) - ALREADY INSTALLED" -ForegroundColor Green
            Write-Host "========================================" -ForegroundColor Magenta
            return [pscustomobject]@{
                Status        = "Skipped"
                ExitCode      = $null
                InstallerPath = $null
                Message       = "$($app.Name) is already installed."
            }
        }

        Write-OBZLog -Level INFO -Message "Starting OBZ install: $($app.Name) [$($app.Id)]"
        Write-Host "`n========================================" -ForegroundColor Magenta
        Write-Host " OBZ PROGRESS: $($app.Name)" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Magenta

        $installerPath = Get-OBZInstallerFile -Application $app

        if (-not (Test-OBZInstallerFile -Path $installerPath)) {
            throw "Installer failed validation before execution."
        }

        Write-OBZLog -Level INFO -Message "Executing: $installerPath"
        Write-Host "Starting installation..." -ForegroundColor Cyan

        if ($Arguments -and $Arguments.Count -gt 0) {
            $process = Start-Process -FilePath $installerPath -ArgumentList $Arguments -Wait -PassThru
        }
        else {
            $process = Start-Process -FilePath $installerPath -Wait -PassThru
        }

        $exitCode = $process.ExitCode

        # Success codes: 0, 1641 (reboot initiated), 3010 (reboot required).
        if ($exitCode -eq 0 -or $exitCode -eq 1641 -or $exitCode -eq 3010) {
            Write-OBZLog -Level SUCCESS -Message "OBZ install succeeded: $($app.Name) (exit $exitCode)"
            Write-Host "`nINSTALLATION SUCCESSFUL!" -ForegroundColor Green
            Write-Host "Application: $($app.Name)" -ForegroundColor Green
            Write-Host "Exit code: $exitCode" -ForegroundColor Green
            return [pscustomobject]@{
                Status        = "Success"
                ExitCode      = $exitCode
                InstallerPath = $installerPath
                Message       = "Installed $($app.Name)."
            }
        }

        Write-OBZLog -Level ERROR -Message "OBZ install failed: $($app.Name) (exit $exitCode)"
        Write-Host "`nINSTALLATION FAILED!" -ForegroundColor Red
        Write-Host "Application: $($app.Name)" -ForegroundColor Red
        Write-Host "Exit code: $exitCode" -ForegroundColor Red
        return [pscustomobject]@{
            Status        = "Error"
            ExitCode      = $exitCode
            InstallerPath = $installerPath
            Message       = "Installer exited with code $exitCode."
        }
    }
    catch {
        $message = $_.Exception.Message
        Write-OBZLog -Level ERROR -Message "OBZ install error: $message"
        Write-Host "`nINSTALLATION ERROR!" -ForegroundColor Red
        Write-Host $message -ForegroundColor Red
        return [pscustomobject]@{
            Status        = "Error"
            ExitCode      = $null
            InstallerPath = $null
            Message       = $message
        }
    }
}

Write-Host "[OK] STRAWBERRY WINDOWS OBZ installer backend loaded." -ForegroundColor Green