<#
.SYNOPSIS
    Formats system information for display.
#>

function Format-SystemInformation {

    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$SystemInfo
    )

    $text = @"
OS: $($SystemInfo.OS)

Version: $($SystemInfo.Version)
Build: $($SystemInfo.Build)

PC: $($SystemInfo.ComputerName)
Model: $($SystemInfo.Model)

CPU: $($SystemInfo.CPU)

GPU: $($SystemInfo.GPU)

RAM: $($SystemInfo.RAM) GB

Disk C: $($SystemInfo.DiskFree) GB free / $($SystemInfo.DiskSize) GB

Architecture: $($SystemInfo.Architecture)

PowerShell: $($SystemInfo.PowerShellVersion)

Uptime: $($SystemInfo.Uptime)

Administrator: $($SystemInfo.Administrator)

User: $($SystemInfo.Username)
"@

    return $text
}