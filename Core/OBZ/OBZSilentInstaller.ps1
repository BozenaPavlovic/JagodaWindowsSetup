# ==========================================
# STRAWBERRY WINDOWS - OBZ SILENT INSTALLER
# Detects common EXE installer frameworks and
# returns appropriate silent arguments.
# ==========================================

function global:Get-OBZSilentArguments {
    param(
        [Parameter(Mandatory = $true)]
        [string]$InstallerPath
    )

    if (-not (Test-Path -LiteralPath $InstallerPath -PathType Leaf)) {
        return @()
    }

    $bytes = [System.IO.File]::ReadAllBytes($InstallerPath)
    $text = [System.Text.Encoding]::ASCII.GetString($bytes)

    # MSI-based EXE wrappers
    if ($text -match "MsiExec|MsiInstallProduct|\.msi") {
        # Only treat as MSI wrapper if MSI header is embedded
        if ($text -contains "D0CF11E0" -or ($bytes -join ",") -match "208,207,17,224") {
            return @("/s", "/v", "/qn")
        }
    }

    # Inno Setup
    if ($text -match "Inno Setup") {
        return @("/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART", "/SP-")
    }

    # NSIS
    if ($text -match "Nullsoft") {
        return @("/S")
    }

    # InstallShield
    if ($text -match "InstallShield") {
        return @("/s", "/v`"/qn`"")
    }

    return @()
}
