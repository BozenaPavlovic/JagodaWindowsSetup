# Core/Model.ps1 - OS detection and configuration loader

function Get-WindowsVersion {
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    if ($os -and $os.BuildNumber -ge 22000) {
        return "Windows11"
    }
    return "Windows11"
}

function Get-OSConfig {
    $root = $PSScriptRoot

    $configPath = Join-Path $root "..\Windows11\Config.ps1"
    if (!(Test-Path $configPath)) {
        throw "Config not found: $configPath"
    }

    . $configPath

    if (!$Global:WindowsConfig) {
        throw "Global:WindowsConfig not defined in $configPath"
    }

    return $Global:WindowsConfig
}