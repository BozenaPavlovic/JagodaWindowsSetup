# ==========================================
# STRAWBERRY WINDOWS - APPLICATION INSTALLATION
# MSI / EXE / Winget installation flow.
# Proper exit code handling, verbose logging, elevation handling.
# ==========================================

function Get-MsiExitCodeDescription {
    param([int]$ExitCode)

    switch ($ExitCode) {
        0        { return "Success" }
        1641     { return "Success, restart initiated" }
        3010     { return "Success, restart required" }
        1603     { return "Fatal installation error" }
        1618     { return "Another installation is already running" }
        1620     { return "Invalid MSI package" }
        1638     { return "Another version is already installed" }
        1605     { return "Product is not installed (uninstall)" }
        1614     { return "Product is not installed (uninstall)" }
        1925     { return "Action only valid for installed products" }
        default  { return "Unknown exit code: $ExitCode" }
    }
}

function Is-MsiSuccessExitCode {
    param([int]$ExitCode)
    return $ExitCode -in @(0, 1641, 3010)
}

function Is-MsiRetryableExitCode {
    param([int]$ExitCode)
    return $ExitCode -in @(1618, 1638)
}

function Install-OneApp {

    param(
        $App,
        [int]$Index = 0,
        [int]$Total = 0
    )

    if (-not $App) {
        throw "Install-OneApp requires an application."
    }

    Write-Host "`n========================================" -ForegroundColor Magenta

    if ($Index -gt 0 -and $Total -gt 0) {
        Write-Host " INSTALL PROGRESS: $Index/$Total" -ForegroundColor Cyan
    }

    Write-Host " $($App.Name)" -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta

    $logFolder = $LogFolder

    if (-not $logFolder -and $Global:PinkConfig) {
        $logFolder = $Global:PinkConfig.LogFolder
    }

    if (-not $logFolder) {
        $projectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
        $logFolder = Join-Path $projectRoot "Logs"
    }

    $historyFile = Join-Path $logFolder "InstallationHistory.log"
    $safeName = $App.Name -replace "[^a-zA-Z0-9]", "_"
    $msiLogFile = Join-Path $logFolder ($safeName + "_MSI.log")

    $didAttemptInstall = $false
    $installationMethod = ""

    try {

        $existing = Find-InstalledApp $App.Match

        if ($existing -and $Global:AutoMode) {
            Write-Host "$($App.Name) already installed - verified, skipping." -ForegroundColor Green
            if (Get-Command Write-AppLog -ErrorAction SilentlyContinue) {
                Write-AppLog -Message "$($App.Name) already installed (v$($existing.DisplayVersion)), skipping" -LogType INSTALLATION -Level INFO
            }
            return
        }

        if ($existing -and -not $Global:AutoMode) {

            Write-Host "ALREADY INSTALLED!" -ForegroundColor Yellow
            Write-Host "Version: $($existing.DisplayVersion)"

            $action = Read-Host "[S] Skip / [R] Reinstall"

            if ($action -notmatch "^[Rr]") {
                return
            }
        }

        $didAttemptInstall = $true

        if (Test-Winget) {

            try {
                $installationMethod = "Winget"
                Install-WithWinget $App

                Write-Host "Verifying Winget installation..." -ForegroundColor Cyan

                $verified = $null

                for ($i = 1; $i -le 10; $i++) {

                    $verified = Find-InstalledApp $App.Match

                    if ($verified) {
                        break
                    }

                    Start-Sleep -Seconds 3
                    Invoke-UiRefresh
                }

                if (-not $verified) {
                    throw "Winget finished, but application verification failed: $($App.Name)"
                }

                Write-Host "INSTALLATION VERIFIED!" -ForegroundColor Green
                Write-Host "Application: $($verified.DisplayName)"
                Write-Host "Version: $($verified.DisplayVersion)"

                if (Get-Command Write-AppLog -ErrorAction SilentlyContinue) {
                    Write-AppLog -Message "$($App.Name) installed successfully via Winget (v$($verified.DisplayVersion))" -LogType INSTALLATION -Level SUCCESS
                }

                Add-Content -Path $historyFile `
                    -Value "$(Get-Date) SUCCESS: $($App.Name) - Winget verified (v$($verified.DisplayVersion))"

                return
            }
            catch {
                Write-Host "Winget failed, falling back to classic installer." -ForegroundColor Yellow
                if (Get-Command Write-AppLog -ErrorAction SilentlyContinue) {
                    Write-AppLog -Message "Winget failed for $($App.Name), falling back to classic installer: $($_.Exception.Message)" -LogType INSTALLATION -Level WARNING
                }
            }
        }
        else {
            Write-Host "Winget not available - using classic installer." -ForegroundColor Yellow
            if (Get-Command Write-AppLog -ErrorAction SilentlyContinue) {
                Write-AppLog -Message "Winget not available for $($App.Name), using classic installer" -LogType INSTALLATION -Level INFO
            }
        }

        if (-not $App.URL) {
            throw "$($App.Name) is distributed via Microsoft Store / Winget only; no direct installer URL is available."
        }

        if ($Global:AutoMode) {
            $mode = "2"
        }
        else {
            Write-Host ""
            Write-Host "[1] Interactive installation"
            Write-Host "[2] Automatic installation"

            $mode = Read-Host "Choose installation mode"

            if ($mode -notin @("1", "2")) {
                throw "Invalid installation mode."
            }
        }

        $installer = Get-ProgramInstaller $App

        $installationMethod = "Classic ($($App.Type))"

        Write-Host "`nSTARTING INSTALLATION..." -ForegroundColor Cyan
        Write-Host "Installer: $installer" -ForegroundColor Gray
        Write-Host "MSI Log: $msiLogFile" -ForegroundColor Gray

        if (Get-Command Write-AppLog -ErrorAction SilentlyContinue) {
            Write-AppLog -Message "Starting $($App.Type) installation for $($App.Name) from $installer (MSI Log: $msiLogFile)" -LogType INSTALLATION -Level INFO
        }

        if ($App.Type -eq "MSI") {

            $msiArgs = @(
                "/i"
                "`"$installer`""
            )

            if ($mode -eq "2") {
                $msiArgs += $App.SilentArguments -split '\s+'
            }

            $msiArgs += @(
                "/L*v"
                "`"$msiLogFile`""
            )

            Write-Host "MSI Command: msiexec.exe $($msiArgs -join ' ')" -ForegroundColor Gray

            $process = Start-Process `
                -FilePath "msiexec.exe" `
                -ArgumentList $msiArgs `
                -PassThru

            if (-not (Wait-ProcessWithUiRefresh -Process $process -TimeoutMs 300000)) {
                throw "MSI installer timed out after 5 minutes."
            }

            $exitCode = $process.ExitCode
            $description = Get-MsiExitCodeDescription $exitCode

            $successColor = if (Is-MsiSuccessExitCode $exitCode) { "Green" } else { "Red" }
            Write-Host "MSI Exit Code: $exitCode - $description" -ForegroundColor $successColor

            if (Is-MsiRetryableExitCode $exitCode) {
                Write-Host "Retryable condition detected, waiting and retrying..." -ForegroundColor Yellow
                Start-Sleep -Seconds 10

                $process = Start-Process `
                    -FilePath "msiexec.exe" `
                    -ArgumentList $msiArgs `
                    -PassThru

                if (-not (Wait-ProcessWithUiRefresh -Process $process -TimeoutMs 300000)) {
                    throw "MSI installer timed out after 5 minutes (retry)."
                }

                $exitCode = $process.ExitCode
                $description = Get-MsiExitCodeDescription $exitCode
                $retryColor = if (Is-MsiSuccessExitCode $exitCode) { "Green" } else { "Red" }
                Write-Host "MSI Retry Exit Code: $exitCode - $description" -ForegroundColor $retryColor
            }
            elseif ($exitCode -eq 1925) {
                Write-Host "MSI requires elevation; retrying with RunAs..." -ForegroundColor Yellow
                $process = Start-Process `
                    -FilePath "msiexec.exe" `
                    -ArgumentList $msiArgs `
                    -Verb RunAs `
                    -PassThru

                if (-not (Wait-ProcessWithUiRefresh -Process $process -TimeoutMs 300000)) {
                    throw "MSI installer timed out after 5 minutes (elevated)."
                }

                $exitCode = $process.ExitCode
                $description = Get-MsiExitCodeDescription $exitCode
                $elevatedColor = if (Is-MsiSuccessExitCode $exitCode) { "Green" } else { "Red" }
                Write-Host "MSI Elevated Exit Code: $exitCode - $description" -ForegroundColor $elevatedColor
            }

            if (-not (Is-MsiSuccessExitCode $exitCode)) {
                $errorMsg = "MSI installation failed. Exit code: $exitCode ($description). Log: $msiLogFile"
                if (Get-Command Write-AppLog -ErrorAction SilentlyContinue) {
                    Write-AppLog -Message $errorMsg -LogType INSTALLATION -Level ERROR
                }
                throw $errorMsg
            }
        }
        else {

            if ($mode -eq "2") {
                $exeArgs = $App.SilentArguments -split '\s+'
            }
            else {
                $exeArgs = $App.InteractiveArguments -split '\s+'
            }

            Write-Host "EXE Command: $installer $($exeArgs -join ' ')" -ForegroundColor Gray

            $process = Start-Process `
                -FilePath $installer `
                -ArgumentList $exeArgs `
                -PassThru

            if (-not (Wait-ProcessWithUiRefresh -Process $process -TimeoutMs 300000)) {
                throw "EXE installer timed out after 5 minutes."
            }

            $exitCode = $process.ExitCode

            $exeColor = if ($exitCode -eq 0) { "Green" } else { "Red" }
            Write-Host "EXE Exit Code: $exitCode" -ForegroundColor $exeColor

            if ($exitCode -ne 0) {
                $errorMsg = "EXE installation failed. Exit code: $exitCode"
                if (Get-Command Write-AppLog -ErrorAction SilentlyContinue) {
                    Write-AppLog -Message $errorMsg -LogType INSTALLATION -Level ERROR
                }
                throw $errorMsg
            }
        }

        Write-Host "`nVERIFYING INSTALLATION..." -ForegroundColor Cyan

        $verified = $null

        for ($i = 1; $i -le 10; $i++) {

            Start-Sleep -Seconds 3

            $verified = Find-InstalledApp $App.Match

            Invoke-UiRefresh

            if ($verified) {
                break
            }
        }

        if (-not $verified) {
            $errorMsg = "Application not found in Windows registry after installation. MSI Log: $msiLogFile"
            if (Get-Command Write-AppLog -ErrorAction SilentlyContinue) {
                Write-AppLog -Message $errorMsg -LogType INSTALLATION -Level ERROR
            }
            throw $errorMsg
        }

        Write-Host "`nINSTALLATION SUCCESSFUL!" -ForegroundColor Green
        Write-Host "Application: $($verified.DisplayName)"
        Write-Host "Version: $($verified.DisplayVersion)"
        Write-Host "Method: $installationMethod"
        Write-Host "MSI Log: $msiLogFile"

        if (Get-Command Write-AppLog -ErrorAction SilentlyContinue) {
            Write-AppLog -Message "$($App.Name) installed successfully via $installationMethod (v$($verified.DisplayVersion), MSI Log: $msiLogFile)" -LogType INSTALLATION -Level SUCCESS
        }

        Add-Content -Path $historyFile `
            -Value "$(Get-Date) SUCCESS: $($App.Name) - $installationMethod (v$($verified.DisplayVersion))"

    }
    catch {

        Write-Host "`nINSTALLATION FAILED!" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red

        $errorMsg = $_.Exception.Message
        if ($installationMethod) {
            $errorMsg = "${installationMethod}: $errorMsg"
        }

        if (Get-Command Write-AppLog -ErrorAction SilentlyContinue) {
            Write-AppLog -Message "Installation failed for $($App.Name): $errorMsg" -LogType INSTALLATION -Level ERROR
        }

        Add-Content -Path $historyFile `
            -Value "$(Get-Date) FAILED: $($App.Name) - $errorMsg"
    }
    finally {

        if ($didAttemptInstall -and (Get-Command Invoke-InstallCooldown -ErrorAction SilentlyContinue)) {
            Invoke-InstallCooldown -AppName $App.Name
        }

        Invoke-UiRefresh
    }

    if (-not $Global:AutoMode) {
        Read-Host "`nPress ENTER to continue"
    }
}

function Install-Programs {

    while ($true) {

        Clear-Host

        Write-Host "========================================" -ForegroundColor Magenta
        Write-Host " STRAWBERRY WINDOWS PROGRAM INSTALLER" -ForegroundColor Magenta
        Write-Host "========================================" -ForegroundColor Magenta

        Write-Host ""
        Write-Host "[1] INSTALL ALL PROGRAMS" -ForegroundColor Magenta
        Write-Host "[2] Google Chrome"
        Write-Host "[4] VLC Media Player"
        Write-Host "[5] LibreOffice"
        Write-Host "[6] 7-Zip"
        Write-Host "[7] Python 3.14"
        Write-Host "[0] Back"
        Write-Host ""

        $choice = Read-Host "Choose program"

        if ($choice -eq "0") {
            return
        }

        if ($choice -eq "1") {
            $Global:AutoMode = $true
            $selected = $Global:Apps
        }
        else {
            $Global:AutoMode = $false
            $selected = @($Global:Apps | Where-Object {
                $_.Number -eq $choice
            })
        }

        if (@($selected).Count -eq 0) {
            Write-Host "Invalid option!" -ForegroundColor Red
            Start-Sleep 2
            continue
        }

        $totalApps = @($selected).Count
        $currentApp = 0

        foreach ($app in $selected) {
            $currentApp++
            Write-Host "`nProgress: $currentApp of $totalApps applications" -ForegroundColor Cyan
            Install-OneApp -App $app -Index $currentApp -Total $totalApps
        }

        Write-Host "`nINSTALLATION SESSION FINISHED!" -ForegroundColor Magenta
        Read-Host "Press ENTER to return"
    }
}