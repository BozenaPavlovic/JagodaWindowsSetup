# ==========================================
# STRAWBERRY WINDOWS - UNINSTALL EXECUTION
# Execute uninstall commands, wait for processes and handle exit codes and timeouts.
# ==========================================

function Invoke-UiRefresh {
    try {
        if ("System.Windows.Forms.Application" -as [type]) {
            [System.Windows.Forms.Application]::DoEvents()
        }
    }
    catch {
    }
}

function Wait-ProcessWithUiRefresh {
    param(
        [System.Diagnostics.Process]$Process,
        [int]$TimeoutMs = 300000
    )

    if (-not $Process) {
        return $false
    }

    $waited = 0

    while (-not $Process.WaitForExit(1000)) {

        Invoke-UiRefresh

        $waited += 1000

        if ($waited -ge $TimeoutMs) {
            try { $Process.Kill() } catch {}
            return $false
        }
    }

    return $true
}

function Execute-UninstallCommand {
    param(
        [Parameter(Mandatory)]
        [string]$Command,
        [string]$Arguments,
        [bool]$IsAppx = $false,
        [bool]$IsMsi = $false,
        [bool]$IsExe = $false,
        [bool]$IsWinget = $false,
        [string]$PackageFullName,
        [int]$TimeoutMs
    )

    if (-not $TimeoutMs -or $TimeoutMs -le 0) {
        $TimeoutMs = $Global:UninstallerSettings.UninstallTimeoutMs
    }

    if ($IsAppx) {
        try {
            Write-Host "Removing AppX package: $PackageFullName" -ForegroundColor Cyan
            Remove-AppxPackage -Package $PackageFullName -ErrorAction Stop
            return @{ ExitCode = 0; Success = $true }
        }
        catch {
            return @{ ExitCode = -1; Success = $false; Error = $_.Exception.Message }
        }
    }

    if ($IsWinget) {
        return Execute-WingetUninstall -Command $Command -Arguments $Arguments -TimeoutMs $TimeoutMs
    }

    if (-not (Test-Path -LiteralPath $Command -PathType Leaf)) {
        $found = Get-Command $Command -ErrorAction SilentlyContinue
        if ($found) {
            $Command = $found.Source
        }
        else {
            return @{ ExitCode = -1; Success = $false; Error = "Command not found: $Command" }
        }
    }

    try {
        Write-Host "Starting uninstaller: $Command" -ForegroundColor Cyan
        Write-Host "Arguments: $Arguments" -ForegroundColor Gray

        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.FileName = $Command
        $startInfo.Arguments = $Arguments
        $startInfo.UseShellExecute = $false
        $startInfo.CreateNoWindow = $false

        if ($Global:UninstallLogFolder) {
            $startInfo.WorkingDirectory = $Global:UninstallLogFolder
        }

        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $startInfo

        if (-not $process.Start()) {
            return @{ ExitCode = -1; Success = $false; Error = "Unable to start uninstaller." }
        }

        Write-Host "Uninstall process started. PID: $($process.Id)" -ForegroundColor Green

        $waited = 0
        while (-not $process.HasExited) {

            if ($waited -ge $TimeoutMs) {
                Write-Host "UNINSTALL TIMEOUT!" -ForegroundColor Red
                try {
                    $process.Kill()
                    $process.WaitForExit(5000)
                }
                catch {}

                return @{ ExitCode = -1; Success = $false; Error = "Uninstaller timed out after $([math]::Round($TimeoutMs / 60000)) minutes." }
            }

            [void]$process.WaitForExit(1000)
            Invoke-UiRefresh
            $waited += 1000
        }

        $process.WaitForExit()
        $exitCode = $process.ExitCode

        $successCodes = @(0, 1641, 3010, 1, 2, 3)
        $success = $successCodes -contains $exitCode

        return @{ ExitCode = $exitCode; Success = $success }
    }
    catch {
        return @{ ExitCode = -1; Success = $false; Error = $_.Exception.Message }
    }
    finally {
        if ($process) {
            $process.Dispose()
        }
    }
}

function Execute-WingetUninstall {
    param(
        [Parameter(Mandatory)]
        [string]$Command,
        [string]$Arguments,
        [int]$TimeoutMs
    )

    try {
        Write-Host "Starting Winget uninstall..." -ForegroundColor Cyan
        Write-Host "Timeout: $([math]::Round($TimeoutMs / 60000)) minutes" -ForegroundColor Gray

        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.FileName = $Command
        $startInfo.Arguments = $Arguments
        $startInfo.UseShellExecute = $false
        $startInfo.CreateNoWindow = $false

        if ($Global:UninstallLogFolder) {
            $startInfo.WorkingDirectory = $Global:UninstallLogFolder
        }

        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $startInfo

        if (-not $process.Start()) {
            return @{ ExitCode = -1; Success = $false; Error = "Unable to start Winget." }
        }

        Write-Host "Winget process started. PID: $($process.Id)" -ForegroundColor Green

        $waited = 0
        while (-not $process.HasExited) {

            if ($waited -ge $TimeoutMs) {
                Write-Host "WINGET TIMEOUT!" -ForegroundColor Red
                try {
                    $process.Kill()
                    $process.WaitForExit(5000)
                }
                catch {}

                return @{ ExitCode = -1; Success = $false; Error = "Winget uninstall timed out after $([math]::Round($TimeoutMs / 60000)) minutes." }
            }

            [void]$process.WaitForExit(1000)
            Invoke-UiRefresh
            $waited += 1000
        }

        $process.WaitForExit()
        $exitCode = $process.ExitCode

        $successCodes = @(0, 3010, 1641)
        $success = $successCodes -contains $exitCode

        return @{ ExitCode = $exitCode; Success = $success }
    }
    catch {
        return @{ ExitCode = -1; Success = $false; Error = $_.Exception.Message }
    }
    finally {
        if ($process) {
            $process.Dispose()
        }
    }
}