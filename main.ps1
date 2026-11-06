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
    if ($IsWindows) {
        try {
            $reg = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
            $ver = $reg.DisplayVersion
            if (-not $ver) { $ver = $reg.ReleaseId }
        } catch {
            Write-Log "Registry read failed: $($_.Exception.Message)"
            throw
        }

        $WindowsVersion = "Unknown"
        if ($ver -like "10*") { $WindowsVersion = "10" }
        elseif ($ver -like "11*") { $WindowsVersion = "11" }

        switch ($WindowsVersion) {
            "10" {
                Write-Host "Detected Windows 10 - launching Windows10 installer..." -ForegroundColor Green
                Read-Host "Press ENTER to continue"
                $target = Join-Path $root "Windows10\install.ps1"
                if (!(Test-Path $target)) { throw "Missing $target" }
                try { & $target } catch { Write-Log "Win10 install failed: $($_.Exception.Message)"; throw }
            }
            "11" {
                Write-Host "Detected Windows 11 - launching Windows11 installer..." -ForegroundColor Green
                Read-Host "Press ENTER to continue"
                $target = Join-Path $root "Windows11\install.ps1"
                if (!(Test-Path $target)) { throw "Missing $target" }
                try { & $target } catch { Write-Log "Win11 install failed: $($_.Exception.Message)"; throw }
            }
            default {
                Write-Host "Unsupported Windows version: $ver"
                Write-Log "Unsupported Windows version: $ver"
                exit 1
            }
        }
    } elseif ($IsLinux) {
        Write-Host "Detected Linux - launching Linux installer..." -ForegroundColor Green
        Read-Host "Press ENTER to continue"
        $target = Join-Path $root "Linux\install.ps1"
        if (!(Test-Path $target)) { throw "Missing $target" }
        try { & $target } catch { Write-Log "Linux install failed: $($_.Exception.Message)"; throw }
    } elseif ($IsMacOS) {
        Write-Host "Detected macOS - launching MacOS installer..." -ForegroundColor Green
        Read-Host "Press ENTER to continue"
        $target = Join-Path $root "MacOS\install.ps1"
        if (!(Test-Path $target)) { throw "Missing $target" }
        try { & $target } catch { Write-Log "MacOS install failed: $($_.Exception.Message)"; throw }
    } else {
        Write-Host "Unrecognized OS."
        Write-Log "Unrecognized OS."
        exit 1
    }
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Log "FATAL: $($_.Exception.Message)"
    exit 1
}
