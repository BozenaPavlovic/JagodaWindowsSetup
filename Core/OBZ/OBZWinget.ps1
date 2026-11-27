# ==========================================
# STRAWBERRY WINDOWS - OBZ WINGET SUPPORT
# Optional WinGet integration for OBZ installer.
# Does not make WinGet mandatory.
# ==========================================

if ($Global:OBZWingetLoaded) { return }

$ErrorActionPreference = "Stop"

$OBZWingetConfigPath = Join-Path $PSScriptRoot "OBZConfiguration.ps1"
$OBZWingetDatabasePath = Join-Path $PSScriptRoot "OBZApplicationDatabase.ps1"
$OBZWingetSilentPath = Join-Path $PSScriptRoot "OBZSilentInstaller.ps1"

if (-not (Test-Path -LiteralPath $OBZWingetConfigPath -PathType Leaf)) { throw "OBZ configuration not found: $OBZWingetConfigPath" }
if (-not (Test-Path -LiteralPath $OBZWingetDatabasePath -PathType Leaf)) { throw "OBZ application database not found: $OBZWingetDatabasePath" }
if (-not (Test-Path -LiteralPath $OBZWingetSilentPath -PathType Leaf)) { throw "OBZ silent installer not found: $OBZWingetSilentPath" }

. $OBZWingetConfigPath
. $OBZWingetDatabasePath
. $OBZWingetSilentPath

if (-not (Get-Command Write-OBZLog -ErrorAction SilentlyContinue)) {
    $OBZInstallerPath = Join-Path $PSScriptRoot "OBZInstaller.ps1"
    if (Test-Path -LiteralPath $OBZInstallerPath) { . $OBZInstallerPath }
}

function global:Test-OBZWingetAvailable {
    try {
        $cmd = Get-Command winget.exe -ErrorAction SilentlyContinue
        if (-not $cmd) { return $false }
        & $cmd.Source --version | Out-Null
        return ($LASTEXITCODE -eq 0)
    }
    catch { return $false }
}

function global:Install-OBZPublicAppWithWinget {
    param(
        [Parameter(Mandatory = $true)][string]$WingetId,
        [string]$Name = $WingetId
    )
    if (-not (Test-OBZWingetAvailable)) {
        if (Get-Command Write-OBZLog -ErrorAction SilentlyContinue) { Write-OBZLog -Level WARNING -Message "WinGet not available; skipping $Name" }
        return [pscustomobject]@{ Status = "Skipped"; ExitCode = $null; Message = "WinGet not available." }
    }
    $winget = (Get-Command winget.exe).Source
    $args = @("install","--id",$WingetId,"--exact","--silent","--accept-package-agreements","--accept-source-agreements","--disable-interactivity")
    $p = Start-Process -FilePath $winget -ArgumentList $args -Wait -PassThru
    $code = $p.ExitCode
    if ($code -in @(0,3010,1641)) {
        if (Get-Command Write-OBZLog -ErrorAction SilentlyContinue) { Write-OBZLog -Level SUCCESS -Message "WinGet install succeeded: $Name (exit $code)" }
        return [pscustomobject]@{ Status = "Success"; ExitCode = $code; Message = "Installed $Name." }
    }
    if (Get-Command Write-OBZLog -ErrorAction SilentlyContinue) { Write-OBZLog -Level ERROR -Message "WinGet install failed: $Name (exit $code)" }
    return [pscustomobject]@{ Status = "Error"; ExitCode = $code; Message = "WinGet exited with code $code." }
}

function global:Get-OBZFileSha256 {
    param([Parameter(Mandatory=$true)][string]$Path)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $stream = [System.IO.File]::OpenRead($Path)
        try { $hash = $sha.ComputeHash($stream) } finally { $stream.Dispose() }
    } finally { $sha.Dispose() }
    return ([BitConverter]::ToString($hash) -replace "-","").ToLowerInvariant()
}

function global:New-OBZLocalManifest {
    param(
        [Parameter(Mandatory=$true)][psobject]$Application,
        [Parameter(Mandatory=$true)][string]$InstallerPath,
        [string]$Version = "1.0.0",
        [string]$ManifestFolder
    )
    if ([string]::IsNullOrWhiteSpace($ManifestFolder)) {
        $ManifestFolder = Join-Path $env:TEMP "OBZManifests"
    }
    New-Item -ItemType Directory -Path $ManifestFolder -Force | Out-Null
    $id = "OBZ.$($Application.Name -replace '[^A-Za-z0-9]','')"
    if ([string]::IsNullOrWhiteSpace($id)) { $id = "OBZ.$($Application.Id)" }
    $hash = Get-OBZFileSha256 -Path $InstallerPath
    $fileName = [System.IO.Path]::GetFileName($InstallerPath)
    $installerType = if ($fileName -match '\.msi$') { "msi" } else { "exe" }
    $silent = @()
    if ($installerType -eq "exe") { $silent = Get-OBZSilentArguments -InstallerPath $InstallerPath }
    $manifest = @"
PackageIdentifier: $id
PackageVersion: $Version
PackageName: $($Application.Name)
Publisher: OBZ
InstallerType: $installerType
Installers:
  - Architecture: x64
    InstallerUrl: $($Application.DownloadUrl)
    InstallerSha256: $hash
    InstallerSwitches:
      Silent: $($silent -join ' ')
ManifestType: singleton
ManifestVersion: 1.4.0
"@
    $manifestPath = Join-Path $ManifestFolder "$id.yaml"
    Set-Content -LiteralPath $manifestPath -Value $manifest -Encoding UTF8
    if (Get-Command Write-OBZLog -ErrorAction SilentlyContinue) { Write-OBZLog -Level INFO -Message "Generated local manifest: $manifestPath" }
    return [pscustomobject]@{ Id = $id; Version = $Version; Path = $manifestPath; Hash = $hash }
}

function global:Install-OBZPrivateAppWithWinget {
    param(
        [Parameter(Mandatory=$true)][psobject]$Application,
        [Parameter(Mandatory=$true)][string]$InstallerPath,
        [string]$Version = "1.0.0"
    )
    if (-not (Test-OBZWingetAvailable)) {
        if (Get-Command Write-OBZLog -ErrorAction SilentlyContinue) { Write-OBZLog -Level WARNING -Message "WinGet not available; cannot install private app via manifest." }
        return [pscustomobject]@{ Status = "Skipped"; ExitCode = $null; Message = "WinGet not available." }
    }
    $manifestInfo = New-OBZLocalManifest -Application $Application -InstallerPath $InstallerPath -Version $Version
    $winget = (Get-Command winget.exe).Source
    $args = @("install","--manifest",$manifestInfo.Path,"--silent","--accept-package-agreements","--accept-source-agreements","--disable-interactivity")
    $p = Start-Process -FilePath $winget -ArgumentList $args -Wait -PassThru
    $code = $p.ExitCode
    if ($code -in @(0,3010,1641)) {
        if (Get-Command Write-OBZLog -ErrorAction SilentlyContinue) { Write-OBZLog -Level SUCCESS -Message "WinGet private install succeeded: $($Application.Name) (exit $code)" }
        return [pscustomobject]@{ Status = "Success"; ExitCode = $code; Message = "Installed $($Application.Name)."; Manifest = $manifestInfo.Path }
    }
    if (Get-Command Write-OBZLog -ErrorAction SilentlyContinue) { Write-OBZLog -Level ERROR -Message "WinGet private install failed: $($Application.Name) (exit $code)" }
    return [pscustomobject]@{ Status = "Error"; ExitCode = $code; Message = "WinGet exited with code $code." }
}

$Global:OBZWingetLoaded = $true
Write-Host "[OK] STRAWBERRY WINDOWS OBZ winget support loaded." -ForegroundColor Green
