# SYSTEM SPECS MODULE

function Get-SystemSpecs {
    param([string]$OutputFolder)

    $Specs = @{
        OS = [Environment]::OSVersion.VersionString
        Platform = [Environment]::OSVersion.Platform
        IsWindows = [Environment]::OSVersion.Platform -eq "Win32NT"
        ComputerName = $env:COMPUTERNAME
        UserName = $env:USERNAME
        Is64Bit = [Environment]::Is64BitOperatingSystem
        PowerShell = $PSVersionTable.PSVersion.ToString()
    }

    if ($OutputFolder) {
        New-Item -ItemType Directory -Force -Path $OutputFolder | Out-Null
        $Specs | ConvertTo-Json | Set-Content -Path (Join-Path $OutputFolder "systemspecs.json")
    }

    return $Specs
}

function Test-IsWindows {
    return [Environment]::OSVersion.Platform -eq "Win32NT"
}
