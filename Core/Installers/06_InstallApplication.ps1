function Install-OneApp {

    param(
        $App,
        [int]$Index = 0,
        [int]$Total = 0
    )

    Write-Host "`n========================================" -ForegroundColor Magenta
    if ($Index -gt 0 -and $Total -gt 0) {
        Write-Host " INSTALL PROGRESS: $Index/$Total" -ForegroundColor Cyan
    }
    Write-Host " $($App.Name)" -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta

    $didAttemptInstall = $false

    try {

        $Existing = Find-InstalledApp $App.Match

        if ($Existing -and $Global:AutoMode) {
            Write-Host "$($App.Name) already installed - verified, skipping." -ForegroundColor Green
            return
        }

        if ($Existing -and -not $Global:AutoMode) {

            Write-Host "ALREADY INSTALLED!" -ForegroundColor Yellow
            Write-Host "Version: $($Existing.DisplayVersion)"

            $Action = Read-Host "[S] Skip / [R] Reinstall"

            if ($Action -notmatch "^[Rr]") {
                return
            }
        }

        $didAttemptInstall = $true

        if ($Global:OSVersion -ne "Windows11") {
            if (Test-Winget) {
                try {
                    Install-WithWinget $App

                    Write-Host "Verifying Winget installation..." -ForegroundColor Cyan

                    $Verified = $null

                    for ($i = 1; $i -le 10; $i++) {

                        $Verified = Find-InstalledApp $App.Match

                        if ($Verified) {
                            break
                        }

                        Start-Sleep -Seconds 3
                        Invoke-UiRefresh
                    }

                    if (-not $Verified) {
                        throw "Winget finished, but application verification failed: $($App.Name)"
                    }

                    Write-Host "INSTALLATION VERIFIED!" -ForegroundColor Green
                    Write-Host "Application: $($Verified.DisplayName)"
                    Write-Host "Version: $($Verified.DisplayVersion)"

                    Add-Content "$LogFolder\InstallationHistory.log" `
                        "$(Get-Date) SUCCESS: $($App.Name) - Winget verified"

                    return
                } catch {
                    Write-Host "Winget failed, falling back to classic installer." -ForegroundColor Yellow
                }
            } else {
                Write-Host "Winget not available - using classic installer." -ForegroundColor Yellow
            }
        } else {
            Write-Host "Detected Windows 11 - winget mode disabled." -ForegroundColor Yellow
        }

        if (-not $App.URL) {
            throw "$($App.Name) is distributed via Microsoft Store / Winget only; no direct installer URL is available."
        }

        if ($Global:AutoMode) {
            $Mode = "2"
        } else {
            Write-Host ""
            Write-Host "[1] Interactive installation"
            Write-Host "[2] Automatic installation"

            $Mode = Read-Host "Choose installation mode"

            if ($Mode -notin @("1","2")) {
                throw "Invalid installation mode."
            }
        }

        $Installer = Get-ProgramInstaller $App

        $SafeName = $App.Name -replace '[^a-zA-Z0-9]', '_'
        $Log = Join-Path $LogFolder "$SafeName.log"

        Write-Host "`nSTARTING INSTALLATION..." -ForegroundColor Cyan

        if ($App.Type -eq "MSI") {

            $Arguments = "/i `"$Installer`""

            if ($Mode -eq "2") {
                $Arguments += " $($App.SilentArguments)"
            }

            $Arguments += " /L*v `"$Log`""

            $Process = Start-Process `
                -FilePath "msiexec.exe" `
                -ArgumentList $Arguments `
                -PassThru

            if (-not (Wait-ProcessWithUiRefresh -Process $Process -TimeoutMs 300000)) {
                throw "MSI installer timed out after 5 minutes."
            }

        }
        else {

            if ($Mode -eq "2") {
                $Arguments = $App.SilentArguments
            }
            else {
                $Arguments = $App.InteractiveArguments
            }

            $Process = Start-Process `
                -FilePath $Installer `
                -ArgumentList $Arguments `
                -PassThru

            if (-not (Wait-ProcessWithUiRefresh -Process $Process -TimeoutMs 300000)) {
                throw "EXE installer timed out after 5 minutes."
            }

        }

        $Process.WaitForExit()
        $ExitCode = $Process.ExitCode

        if ($ExitCode -notin @(0, 1641, 3010, 1, 2, 3)) {
            throw "Installer exit code: $ExitCode"
        }

        Write-Host "`nVERIFYING INSTALLATION..." -ForegroundColor Cyan

        $Verified = $null

        for ($i = 1; $i -le 6; $i++) {

            Start-Sleep -Seconds 3

            $Verified = Find-InstalledApp $App.Match

            Invoke-UiRefresh

            if ($Verified) {
                break
            }
        }

        if (!$Verified) {
            throw "Application not found in Windows registry."
        }

        Write-Host "`nINSTALLATION SUCCESSFUL!" -ForegroundColor Green
        Write-Host "Application: $($Verified.DisplayName)"
        Write-Host "Version: $($Verified.DisplayVersion)"

        Add-Content "$LogFolder\InstallationHistory.log" `
            "$(Get-Date) SUCCESS: $($App.Name)"

    }
    catch {

        Write-Host "`nINSTALLATION FAILED!" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red

        Add-Content "$LogFolder\InstallationHistory.log" `
            "$(Get-Date) FAILED: $($App.Name) - $($_.Exception.Message)"
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

        $Choice = Read-Host "Choose program"

        if ($Choice -eq "0") {
            return
        }

        if ($Choice -eq "1") {
            $Global:AutoMode = $true
            $Selected = $Global:Apps
        } else {
            $Global:AutoMode = $false
            $Selected = @($Global:Apps | Where-Object {
                $_.Number -eq $Choice
            })
        }

        if ($Selected.Count -eq 0) {
            Write-Host "Invalid option!" -ForegroundColor Red
            Start-Sleep 2
            continue
        }

        $totalApps = @($Selected).Count
        $currentApp = 0
        foreach ($App in $Selected) {
            $currentApp++
            Write-Host "`nProgress: $currentApp of $totalApps applications" -ForegroundColor Cyan
            Install-OneApp -App $App -Index $currentApp -Total $totalApps
        }

        Write-Host "`nINSTALLATION SESSION FINISHED!" -ForegroundColor Magenta
        Read-Host "Press ENTER to return"
    }
}