# ==========================================
# STRAWBERRY WINDOWS - APPLICATION INSTALLATION
# MSI / EXE / Winget installation flow.
# ==========================================

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

    $didAttemptInstall = $false

    try {

        $existing = Find-InstalledApp $App.Match

        if ($existing -and $Global:AutoMode) {
            Write-Host "$($App.Name) already installed - verified, skipping." -ForegroundColor Green
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

                    Add-Content -Path $historyFile `
                        -Value "$(Get-Date) SUCCESS: $($App.Name) - Winget verified"

                    return
                }
                catch {
                    Write-Host "Winget failed, falling back to classic installer." -ForegroundColor Yellow
                }
            }
            else {
                Write-Host "Winget not available - using classic installer." -ForegroundColor Yellow
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

        $safeName = $App.Name -replace "[^a-zA-Z0-9]", "_"
        $logFile = Join-Path $logFolder "$safeName.log"

        Write-Host "`nSTARTING INSTALLATION..." -ForegroundColor Cyan

        if ($App.Type -eq "MSI") {

            $arguments = "/i `"$installer`""

            if ($mode -eq "2") {
                $arguments += " $($App.SilentArguments)"
            }

            $arguments += " /L*v `"$logFile`""

            $process = Start-Process `
                -FilePath "msiexec.exe" `
                -ArgumentList $arguments `
                -PassThru

            if (-not (Wait-ProcessWithUiRefresh -Process $process -TimeoutMs 300000)) {
                throw "MSI installer timed out after 5 minutes."
            }

            if ($process.ExitCode -eq 1925 -or $process.ExitCode -eq -1978335230) {
                Write-Host "MSI requires elevation; retrying with RunAs..." -ForegroundColor Yellow
                $process = Start-Process `
                    -FilePath "msiexec.exe" `
                    -ArgumentList $arguments `
                    -Verb RunAs `
                    -PassThru

                if (-not (Wait-ProcessWithUiRefresh -Process $process -TimeoutMs 300000)) {
                    throw "MSI installer timed out after 5 minutes."
                }
            }
        }
        else {

            if ($mode -eq "2") {
                $arguments = $App.SilentArguments
            }
            else {
                $arguments = $App.InteractiveArguments
            }

            $process = Start-Process `
                -FilePath $installer `
                -ArgumentList $arguments `
                -PassThru

            if (-not (Wait-ProcessWithUiRefresh -Process $process -TimeoutMs 300000)) {
                throw "EXE installer timed out after 5 minutes."
            }
        }

        $exitCode = $process.ExitCode

        if ($exitCode -notin @(0, 1641, 3010, 1, 2, 3)) {
            throw "Installer exit code: $exitCode"
        }

        Write-Host "`nVERIFYING INSTALLATION..." -ForegroundColor Cyan

        $verified = $null

        for ($i = 1; $i -le 6; $i++) {

            Start-Sleep -Seconds 3

            $verified = Find-InstalledApp $App.Match

            Invoke-UiRefresh

            if ($verified) {
                break
            }
        }

        if (-not $verified) {
            throw "Application not found in Windows registry."
        }

        Write-Host "`nINSTALLATION SUCCESSFUL!" -ForegroundColor Green
        Write-Host "Application: $($verified.DisplayName)"
        Write-Host "Version: $($verified.DisplayVersion)"

        Add-Content -Path $historyFile `
            -Value "$(Get-Date) SUCCESS: $($App.Name)"

    }
    catch {

        Write-Host "`nINSTALLATION FAILED!" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red

        Add-Content -Path $historyFile `
            -Value "$(Get-Date) FAILED: $($App.Name) - $($_.Exception.Message)"
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