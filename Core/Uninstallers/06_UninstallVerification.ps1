# ==========================================
# STRAWBERRY WINDOWS - UNINSTALL VERIFICATION
# Verify that applications have actually been removed.
# ==========================================

function Verify-Uninstall {
    param(
        [Parameter(Mandatory)]
        [string]$ProgramName,
        [int]$Retries,
        [int]$DelaySeconds
    )

    if (-not $Retries -or $Retries -le 0) {
        $Retries = $Global:UninstallerSettings.VerificationRetries
    }

    if (-not $DelaySeconds -or $DelaySeconds -le 0) {
        $DelaySeconds = $Global:UninstallerSettings.VerificationDelaySeconds
    }

    Write-Host "Verifying uninstallation of $ProgramName..." -ForegroundColor Cyan

    for ($i = 1; $i -le $Retries; $i++) {

        $stillInstalled = Find-InstalledProgram -Pattern $ProgramName

        if (-not $stillInstalled -or $stillInstalled.Count -eq 0) {
            Write-Host "VERIFICATION PASSED: $ProgramName is no longer installed." -ForegroundColor Green
            return $true
        }

        $exactMatch = $stillInstalled | Where-Object {
            $_.Name -eq $ProgramName -or
            $_.DisplayName -eq $ProgramName -or
            $_.PSChildName -eq $ProgramName -or
            $_.PackageFullName -eq $ProgramName
        }

        if (-not $exactMatch -or $exactMatch.Count -eq 0) {
            Write-Host "VERIFICATION PASSED: $ProgramName is no longer installed." -ForegroundColor Green
            return $true
        }

        Write-Host "Still detected (attempt $i/$Retries), waiting ${DelaySeconds}s..." -ForegroundColor Yellow
        Start-Sleep -Seconds $DelaySeconds
        Invoke-UiRefresh
    }

    Write-Host "VERIFICATION FAILED: $ProgramName still appears to be installed." -ForegroundColor Red
    return $false
}

function Verify-AppxUninstall {
    param(
        [Parameter(Mandatory)]
        [string]$PackageFullName,
        [int]$Retries,
        [int]$DelaySeconds
    )

    if (-not $Retries -or $Retries -le 0) {
        $Retries = $Global:UninstallerSettings.VerificationRetries
    }

    if (-not $DelaySeconds -or $DelaySeconds -le 0) {
        $DelaySeconds = $Global:UninstallerSettings.VerificationDelaySeconds
    }

    Write-Host "Verifying AppX uninstallation of $PackageFullName..." -ForegroundColor Cyan

    for ($i = 1; $i -le $Retries; $i++) {

        $appx = Get-AppxPackage -ErrorAction SilentlyContinue |
            Where-Object { $_.PackageFullName -eq $PackageFullName } |
            Select-Object -First 1

        if (-not $appx) {
            Write-Host "VERIFICATION PASSED: AppX package $PackageFullName is no longer installed." -ForegroundColor Green
            return $true
        }

        Write-Host "Still detected (attempt $i/$Retries), waiting ${DelaySeconds}s..." -ForegroundColor Yellow
        Start-Sleep -Seconds $DelaySeconds
        Invoke-UiRefresh
    }

    Write-Host "VERIFICATION FAILED: AppX package $PackageFullName still appears to be installed." -ForegroundColor Red
    return $false
}

function Verify-MsiUninstall {
    param(
        [Parameter(Mandatory)]
        [string]$ProductCode,
        [int]$Retries,
        [int]$DelaySeconds
    )

    if (-not $Retries -or $Retries -le 0) {
        $Retries = $Global:UninstallerSettings.VerificationRetries
    }

    if (-not $DelaySeconds -or $DelaySeconds -le 0) {
        $DelaySeconds = $Global:UninstallerSettings.VerificationDelaySeconds
    }

    Write-Host "Verifying MSI uninstallation of $ProductCode..." -ForegroundColor Cyan

    for ($i = 1; $i -le $Retries; $i++) {

        $keyPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )

        $found = Get-ItemProperty $keyPaths -ErrorAction SilentlyContinue |
            Where-Object { $_.PSChildName -eq $ProductCode } |
            Select-Object -First 1

        if (-not $found) {
            Write-Host "VERIFICATION PASSED: MSI product $ProductCode is no longer installed." -ForegroundColor Green
            return $true
        }

        Write-Host "Still detected (attempt $i/$Retries), waiting ${DelaySeconds}s..." -ForegroundColor Yellow
        Start-Sleep -Seconds $DelaySeconds
        Invoke-UiRefresh
    }

    Write-Host "VERIFICATION FAILED: MSI product $ProductCode still appears to be installed." -ForegroundColor Red
    return $false
}