# ==========================================
# STRAWBERRY WINDOWS - WINGET
# Synchronous winget install with timeout.
# Captures full stdout/stderr for diagnostics.
# ==========================================

function Test-Winget {

    if ($null -ne $script:WingetAvailable) {
        return $script:WingetAvailable
    }

    try {
        winget --version | Out-Null
        $script:WingetAvailable = $true
    }
    catch {
        $script:WingetAvailable = $false
    }

    return $script:WingetAvailable
}

function Install-WithWinget {

    param($App)

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host " WINGET INSTALLATION: $($App.Name)" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    if (-not $App.WingetID) {
        throw "Winget ID missing for $($App.Name)."
    }

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

    $argumentString = $wingetArguments -join " "

    $logFolder = $LogFolder

    if (-not $logFolder -and $Global:PinkConfig) {
        $logFolder = $Global:PinkConfig.LogFolder
    }

    if (-not $logFolder) {
        $projectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
        $logFolder = Join-Path $projectRoot "Logs"
    }

    $safeName = $App.Name -replace "[^a-zA-Z0-9]", "_"
    $logFile = Join-Path $logFolder ($safeName + "_Winget.log")
    $outputLogFile = Join-Path $logFolder ($safeName + "_Winget_Output.log")

    Write-Host "Package ID: $($App.WingetID)" -ForegroundColor Gray
    Write-Host "Starting Winget directly..." -ForegroundColor Cyan
    Write-Host "Timeout: 15 minutes" -ForegroundColor Gray
    Write-Host "Output log: $outputLogFile" -ForegroundColor Gray

    if (Get-Command Write-AppLog -ErrorAction SilentlyContinue) {
        Write-AppLog -Message "Starting Winget install for $($App.Name) (ID: $($App.WingetID))" -LogType INSTALLATION -Level INFO
    }

    $startInfo = New-Object System.Diagnostics.ProcessStartInfo

    $startInfo.FileName = $wingetExe
    $startInfo.Arguments = $argumentString
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $startInfo.StandardErrorEncoding = [System.Text.Encoding]::UTF8

    if ($DownloadFolder) {
        $startInfo.WorkingDirectory = $DownloadFolder
    }

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo

    $stdoutBuffer = New-Object System.Text.StringBuilder
    $stderrBuffer = New-Object System.Text.StringBuilder

    $outputWriter = [System.IO.StreamWriter]::new($outputLogFile, $true, [System.Text.Encoding]::UTF8)
    $outputWriter.AutoFlush = $true

    $stdoutAction = {
        param($sender, $e)
        if ($e.Data) {
            [void]$stdoutBuffer.AppendLine($e.Data)
            try { $outputWriter.WriteLine("[STDOUT] " + $e.Data) } catch {}
        }
    }

    $stderrAction = {
        param($sender, $e)
        if ($e.Data) {
            [void]$stderrBuffer.AppendLine($e.Data)
            try { $outputWriter.WriteLine("[STDERR] " + $e.Data) } catch {}
        }
    }

    $process.add_OutputDataReceived($stdoutAction)
    $process.add_ErrorDataReceived($stderrAction)

    try {

        if (-not $process.Start()) {
            throw "Unable to start Winget."
        }

        Write-Host "Winget process started. PID: $($process.Id)" -ForegroundColor Green

        $process.BeginOutputReadLine()
        $process.BeginErrorReadLine()

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

                $outputWriter.WriteLine("[TIMEOUT] Process killed after 15 minutes")
                throw "Winget installation timed out after 15 minutes."
            }

            [void]$process.WaitForExit(1000)

            Invoke-UiRefresh

            $elapsed += 1000
        }

        $process.WaitForExit()

        $process.CancelOutputRead()
        $process.CancelErrorRead()

        $fullOutput = $stdoutBuffer.ToString() + "`n" + $stderrBuffer.ToString()

        $outputWriter.WriteLine("[EXIT] Process exited with code: $($process.ExitCode)")

        $exitCode = $process.ExitCode
        $exitHex = "0x{0:X8}" -f $exitCode

        $logEntry = @"
Application: $($App.Name)
Package ID: $($App.WingetID)
Date: $(Get-Date)
Exit code: $exitCode
Exit code HEX: $exitHex
Output log: $outputLogFile
Full Output:
$fullOutput
"@

        Add-Content -Path $logFile -Value $logEntry -Encoding UTF8

        if (Get-Command Write-AppLog -ErrorAction SilentlyContinue) {
            Write-AppLog -Message "Winget install for $($App.Name) completed with exit code $exitCode ($exitHex)" -LogType INSTALLATION -Level (if ($exitCode -in @(0, 3010, 1641)) { "SUCCESS" } else { "ERROR" })
        }

        if ($exitCode -notin @(0, 3010, 1641)) {
            Write-Host "`nWINGET FAILED!" -ForegroundColor Red
            Write-Host "Exit code: $exitCode ($exitHex)" -ForegroundColor Red
            Write-Host "Full output saved to: $outputLogFile" -ForegroundColor Yellow
            throw "Winget failed. Exit code: $exitCode ($exitHex). See $outputLogFile for details."
        }

        Write-Host "`nWINGET COMPLETED!" -ForegroundColor Green
        Write-Host "Exit code: $exitCode" -ForegroundColor Green

        return $true
    }
    catch {
        if (Get-Command Write-AppLog -ErrorAction SilentlyContinue) {
            Write-AppLog -Message "Winget install for $($App.Name) failed: $($_.Exception.Message)" -LogType INSTALLATION -Level ERROR
        }
        throw
    }
    finally {
        if ($outputWriter) {
            try { $outputWriter.Close() } catch {}
        }
        if ($process) {
            $process.Dispose()
        }
    }
}