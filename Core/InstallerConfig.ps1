# ==========================================
# STRAWBERRY WINDOWS - INSTALLER CONFIG
# ==========================================

if (-not $Global:InstallerSettings) {
    $Global:InstallerSettings = @{}
}

if (-not $Global:InstallerSettings.ContainsKey("InstallCooldownSeconds")) {
    $Global:InstallerSettings.InstallCooldownSeconds = 5
}
