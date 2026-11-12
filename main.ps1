# main.ps1 - Application router with robust error handling
$root = $PSScriptRoot
$logDir = Join-Path $root "Logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logFile = Join-Path $logDir "main.log"

function Write-Log {
    param([string]$Message)
    Add-Content -Path $logFile -Value "$(Get-Date) $Message"
}

try {
    . "$root\Core\Model.ps1"
    . "$root\Core\Controller.ps1"

    $os = Get-WindowsVersion
    Write-Host "Detected OS: $os" -ForegroundColor Green
    Write-Log "Detected OS: $os"

    $target = Join-Path $root "Windows11\install.ps1"

    if (!(Test-Path $target)) { throw "Missing $target" }
    & $target
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Log "FATAL: $($_.Exception.Message)"
    exit 1
}