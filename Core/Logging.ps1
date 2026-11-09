
# ==========================================
# STRAWBERRY WINDOWS - CENTRAL LOGGING
# ==========================================

# Project root = parent of Core
$Global:StrawberryRoot = Split-Path $PSScriptRoot -Parent

$Global:StrawberryLogDirectory = Join-Path `
    $Global:StrawberryRoot "Logs"

if (-not (Test-Path -LiteralPath $Global:StrawberryLogDirectory)) {
    New-Item -ItemType Directory `
        -Path $Global:StrawberryLogDirectory `
        -Force | Out-Null
}

$Global:ActivityLog = Join-Path $Global:StrawberryLogDirectory "Activity.log"
$Global:InstallationLog = Join-Path $Global:StrawberryLogDirectory "Installation.log"
$Global:ErrorLog = Join-Path $Global:StrawberryLogDirectory "Errors.log"

function Write-AppLog {

    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR")]
        [string]$Level = "INFO",

        [ValidateSet("ACTIVITY", "INSTALLATION", "ERROR")]
        [string]$LogType = "ACTIVITY"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $user = [Environment]::UserName
    $computer = $env:COMPUTERNAME

    $entry = "[$timestamp] [$Level] [$computer] [$user] $Message"

    $logPath = switch ($LogType) {
        "ACTIVITY"     { $Global:ActivityLog }
        "INSTALLATION" { $Global:InstallationLog }
        "ERROR"        { $Global:ErrorLog }
    }

    try {
        Add-Content -LiteralPath $logPath `
            -Value $entry `
            -Encoding UTF8 `
            -ErrorAction Stop
    }
    catch {
        Write-Warning "Logging failed: $($_.Exception.Message)"
        return
    }

    if ($Level -eq "ERROR" -and $LogType -ne "ERROR") {
        Add-Content -LiteralPath $Global:ErrorLog `
            -Value $entry `
            -Encoding UTF8
    }
}

Write-AppLog -Message "Central logging system initialized."
Write-AppLog -Message "Log directory: $Global:StrawberryLogDirectory"

