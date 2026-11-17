function Test-Winget {

    if ($null -ne $script:WingetAvailable) {
        return $script:WingetAvailable
    }

    try {
        winget --version | Out-Null
        $script:WingetAvailable = $true
    } catch {
        $script:WingetAvailable = $false
    }

    return $script:WingetAvailable
}

function Install-WithWinget {
    param($App)

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host " WINGET INSTALLATION: $($App.Name)" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    $wingetCommand = Get-Command winget.exe -ErrorAction SilentlyContinue

    if (-not $wingetCommand -or -not $wingetCommand.Source) {
        throw "winget.exe not found."
    }

    $wingetExe = $wingetCommand.Source

    $wingetArguments = @(
        "install"
        "--id"
        $App.WingetID
        "--exact"
        "--silent"
        "--accept-package-agreements"
        "--accept-source-agreements"
        "--disable-interactivity"
    )

    $argumentString = $wingetArguments -join ' '

    $logFile = Join-Path $LogFolder (
        ($App.Name -replace '[^a-zA-Z0-9]', '_') + "_Winget.log"
    )

    Write-Host "Package ID: $($App.WingetID)" -ForegroundColor Gray
    Write-Host "Starting Winget directly..." -ForegroundColor Cyan
    Write-Host "Timeout: 15 minutes" -ForegroundColor Gray

    $startInfo = New-Object System.Diagnostics.ProcessStartInfo

    $startInfo.FileName = $wingetExe
    $startInfo.Arguments = $argumentString
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $false
    $startInfo.WorkingDirectory = $DownloadFolder

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo

    try {
        if (-not $process.Start()) {
            throw "Unable to start Winget."
        }

        Write-Host "Winget process started. PID: $($process.Id)" -ForegroundColor Green

        $timeout = 900000
        $elapsed = 0

        while (-not $process.HasExited) {

            if ($elapsed -ge $timeout) {
                Write-Host "WINGET TIMEOUT!" -ForegroundColor Red

                try {
                    $process.Kill()
                    $process.WaitForExit(5000)
                }
                catch {}

                throw "Winget installation timed out after 15 minutes."
            }

            [void]$process.WaitForExit(1000)

            Invoke-UiRefresh

            $elapsed += 1000
        }

        $process.WaitForExit()

        $exitCode = $process.ExitCode

        $exitHex = "0x{0:X8}" -f $exitCode

        Add-Content -Path $logFile -Value @"
Application: $($App.Name)
Package ID: $($App.WingetID)
Date: $(Get-Date)
Exit code: $exitCode
Exit code HEX: $exitHex
"@

        if ($exitCode -notin @(0, 3010, 1641)) {
            throw "Winget failed. Exit code: $exitCode ($exitHex)"
        }

        Write-Host "`nWINGET COMPLETED!" -ForegroundColor Green
        Write-Host "Exit code: $exitCode" -ForegroundColor Green

        return $true
    }
    finally {
        if ($process) {
            $process.Dispose()
        }
    }
}