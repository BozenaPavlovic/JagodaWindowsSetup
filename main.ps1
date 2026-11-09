# main.ps1 - OS router with robust error handling
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

    switch ($os) {
        "Windows10" {
            Write-Host "Launching Windows10 installer..." -ForegroundColor Green
            $target = Join-Path $root "Windows10\install.ps1"
        }
        "Windows11" {
            Write-Host "Launching Windows11 installer..." -ForegroundColor Green
            $target = Join-Path $root "Windows11\install.ps1"
        }
        default {
            throw "Unsupported OS: $os"
        }
    }

    if (!(Test-Path $target)) { throw "Missing $target" }
    & $target
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Log "FATAL: $($_.Exception.Message)"
    exit 1
}