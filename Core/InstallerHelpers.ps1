# ==========================================
# STRAWBERRY WINDOWS - INSTALLER HELPERS
# Shared cooldown helper used by the installer.
# ==========================================

function Get-InstallCooldownSeconds {

    if (-not $Global:InstallerSettings) {
        # Try to load from OS config if available (set by Core/Installers/01_Configuration.ps1)
        if ($Global:WindowsConfig -and $Global:WindowsConfig.ContainsKey("InstallCooldownSeconds")) {
            $Global:InstallerSettings = @{ InstallCooldownSeconds = $Global:WindowsConfig.InstallCooldownSeconds }
        }
        elseif ($Global:PinkConfig -and $Global:PinkConfig.ContainsKey("InstallCooldownSeconds")) {
            $Global:InstallerSettings = @{ InstallCooldownSeconds = $Global:PinkConfig.InstallCooldownSeconds }
        }
    }

    $value = $null

    if ($Global:InstallerSettings -and $Global:InstallerSettings.ContainsKey("InstallCooldownSeconds")) {
        $value = $Global:InstallerSettings.InstallCooldownSeconds
    }
    elseif ($Global:WindowsConfig -and $Global:WindowsConfig.ContainsKey("InstallCooldownSeconds")) {
        $value = $Global:WindowsConfig.InstallCooldownSeconds
    }
    elseif ($Global:PinkConfig -and $Global:PinkConfig.ContainsKey("InstallCooldownSeconds")) {
        $value = $Global:PinkConfig.InstallCooldownSeconds
    }

    if ($null -eq $value -or "$value" -eq "") {
        return 5
    }

    try {
        $seconds = [int]$value
    }
    catch {
        return 5
    }

    if ($seconds -lt 0) {
        return 5
    }

    return $seconds
}

function Invoke-InstallCooldown {

    param(
        [string]$AppName
    )

    $seconds = Get-InstallCooldownSeconds

    $name = $AppName

    if ([string]::IsNullOrWhiteSpace($name)) {
        $name = "Unknown application"
    }

    $message = "Installation cooldown for ${name}: ${seconds}s"

    if (Get-Command Write-AppLog -ErrorAction SilentlyContinue) {
        if ($seconds -gt 0) {
            Write-AppLog -Message $message -LogType INSTALLATION
        }
        else {
            Write-AppLog -Message "$message (skipped)" -LogType INSTALLATION
        }
    }

    if ($seconds -gt 0) {
        Write-Host ""
        Write-Host "Cooldown after ${name}: ${seconds}s" -ForegroundColor DarkGray

        for ($remaining = $seconds; $remaining -ge 0; $remaining--) {
            Write-Host ("`rCooldown: {0}s remaining... " -f $remaining) -NoNewline -ForegroundColor DarkGray

            if ($remaining -gt 0) {
                Start-Sleep -Seconds 1

                if (Get-Command Invoke-UiRefresh -ErrorAction SilentlyContinue) {
                    Invoke-UiRefresh
                }
            }
        }

        Write-Host "`rCooldown complete.            " -ForegroundColor DarkGray
    }
    else {
        Write-Host "Cooldown for ${name}: skipped (0s)" -ForegroundColor DarkGray
    }
}