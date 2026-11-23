# ==========================================
# STRAWBERRY WINDOWS - UNINSTALL LOGGING
# Uninstallation-specific logging and managed-program tracking.
# ==========================================

function Get-UninstallStorePath {
    if ($Global:StrawberryLogDirectory) {
        return Join-Path $Global:StrawberryLogDirectory "ManagedPrograms.json"
    }

    $projectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    return Join-Path $projectRoot "Logs\ManagedPrograms.json"
}

function Get-UninstallLogPath {
    if ($Global:UninstallLogFolder) {
        return Join-Path $Global:UninstallLogFolder "Uninstall.log"
    }

    $storePath = Get-UninstallStorePath
    return Join-Path (Split-Path $storePath -Parent) "Uninstall.log"
}

function Read-ManagedStore {
    $path = Get-UninstallStorePath

    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        return @()
    }

    try {
        $content = Get-Content -LiteralPath $path -Raw -Encoding UTF8 -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($content)) {
            return @()
        }

        $data = $content | ConvertFrom-Json -ErrorAction Stop
        if ($null -eq $data) {
            return @()
        }

        return @($data)
    }
    catch {
        Write-Warning "Unable to read managed program store: $($_.Exception.Message)"
        return @()
    }
}

function Write-ManagedStore {
    param(
        [object[]]$Programs = @()
    )

    $path = Get-UninstallStorePath
    $logDir = Split-Path $path -Parent

    if (-not (Test-Path -LiteralPath $logDir -PathType Container)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    $json = $Programs | ConvertTo-Json -Depth 10

    try {
        Set-Content -LiteralPath $path -Value $json -Encoding UTF8 -ErrorAction Stop
    }
    catch {
        Write-Warning "Unable to write managed program store: $($_.Exception.Message)"
    }
}

function Register-ManagedProgram {
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [string]$DisplayName,
        [string]$Version,
        [string]$Publisher,
        [string]$UninstallString,
        [string]$InstallDate,
        [string]$Source = "JagodaSetup"
    )

    $store = Read-ManagedStore

    $existing = $store | Where-Object { $_.Name -eq $Name } | Select-Object -First 1

    if ($existing) {
        $index = [array]::IndexOf($store, $existing)
        $store[$index] = [PSCustomObject]@{
            Name            = $Name
            DisplayName     = $DisplayName
            Version         = $Version
            Publisher       = $Publisher
            UninstallString = $UninstallString
            InstallDate     = $InstallDate
            Source          = $Source
        }
    }
    else {
        $store += [PSCustomObject]@{
            Name            = $Name
            DisplayName     = $DisplayName
            Version         = $Version
            Publisher       = $Publisher
            UninstallString = $UninstallString
            InstallDate     = $InstallDate
            Source          = $Source
        }
    }

    Write-ManagedStore -Programs $store
}

function Unregister-ManagedProgram {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $store = Read-ManagedStore
    $filtered = $store | Where-Object { $_.Name -ne $Name }

    # Ensure we pass an array, even if empty
    $programsArray = @($filtered)
    if ($programsArray.Count -eq 0) {
        $programsArray = @()
    }

    Write-ManagedStore -Programs $programsArray
}

function Write-UninstallLog {
    param(
        [Parameter(Mandatory)]
        [string]$ProgramName,
        [Parameter(Mandatory)]
        [ValidateSet("SUCCESS", "FAILED", "SKIPPED", "WARNING")]
        [string]$Status,
        [string]$Message,
        [int]$ExitCode,
        [string]$UninstallCommand
    )

    $logPath = Get-UninstallLogPath
    $logDir = Split-Path $logPath -Parent

    if (-not (Test-Path -LiteralPath $logDir -PathType Container)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $user = [Environment]::UserName
    $computer = $env:COMPUTERNAME

    $exitPart = if ($ExitCode -ne $null) { " [ExitCode: $ExitCode]" } else { "" }
    $cmdPart = if (-not [string]::IsNullOrWhiteSpace($UninstallCommand)) { " | Command: $UninstallCommand" } else { "" }
    $msgPart = if (-not [string]::IsNullOrWhiteSpace($Message)) { " | $Message" } else { "" }

    $entry = "[$timestamp] [UNINSTALL] [$Status] [$computer] [$user] $ProgramName$exitPart$cmdPart$msgPart"

    try {
        Add-Content -LiteralPath $logPath -Value $entry -Encoding UTF8 -ErrorAction Stop
    }
    catch {
        Write-Warning "Unable to write uninstall log: $($_.Exception.Message)"
    }

    if (Get-Command Write-AppLog -ErrorAction SilentlyContinue) {

        $logLevel = switch ($Status) {
            "FAILED"   { "ERROR" }
            "SKIPPED"  { "WARNING" }
            default    { $Status }
        }

        Write-AppLog -Message "Uninstall ${ProgramName}: $Status$msgPart" -Level $logLevel -LogType INSTALLATION
    }
}

function Get-ManagedPrograms {
    $store = Read-ManagedStore

    if ($store.Count -eq 0) {
        return @()
    }

    $installed = Get-AllInstalledPrograms

    $results = @()

    foreach ($entry in $store) {
        $match = $installed | Where-Object { $_.Name -eq $entry.Name -or $_.DisplayName -eq $entry.Name } | Select-Object -First 1

        $results += [PSCustomObject]@{
            Name            = $entry.Name
            DisplayName     = $entry.DisplayName
            Version         = $entry.Version
            Publisher       = $entry.Publisher
            UninstallString = $entry.UninstallString
            InstallDate     = $entry.InstallDate
            Source          = $entry.Source
            Installed       = ($null -ne $match)
            CurrentVersion  = if ($match) { $match.Version } else { $null }
        }
    }

    return $results
}

function Get-AllInstalledPrograms {
    $registryPrograms = Get-AllInstalledProgramsFromRegistry
    $appxPrograms = Get-AllInstalledProgramsFromAppx

    return $registryPrograms + $appxPrograms
}

function Get-InstalledPrograms {
    param(
        [string]$Pattern
    )

    $programs = Get-AllInstalledPrograms

    if (-not [string]::IsNullOrWhiteSpace($Pattern)) {
        $programs = $programs | Where-Object {
            $_.DisplayName -like "*$Pattern*" -or
            $_.Name -like "*$Pattern*" -or
            $_.PSChildName -like "*$Pattern*" -or
            $_.PackageFullName -like "*$Pattern*"
        }
    }

    return $programs
}