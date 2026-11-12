# Core/ThemeManager.ps1 - Shared theme selection and routing for Windows 10/11

$script:ThemeManagerBase = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($script:ThemeManagerBase) -and $MyInvocation.MyCommand.Path) {
    $script:ThemeManagerBase = Split-Path -Parent $MyInvocation.MyCommand.Path
}
$script:StrawberryProjectRoot = if ($script:ThemeManagerBase) { Split-Path $script:ThemeManagerBase -Parent } else { $null }
if (-not $script:ThemeBackendInitializedOS) { $script:ThemeBackendInitializedOS = $null }

function global:Get-ThemeCatalog {
    return @(
        @{ Id = "Pink";   Name = "Pink";   Color = "#FF69B4"; DisplayColor = [ConsoleColor]::Magenta }
        @{ Id = "Blue";   Name = "Blue";   Color = "#1E90FF"; DisplayColor = [ConsoleColor]::Cyan }
        @{ Id = "Yellow"; Name = "Yellow"; Color = "#FFD700"; DisplayColor = [ConsoleColor]::Yellow }
        @{ Id = "Green";  Name = "Green";  Color = "#32CD32"; DisplayColor = [ConsoleColor]::Green }
    )
}

function global:Get-TargetThemeOS {
    $base = $script:ThemeManagerBase
    if (-not $base) { $base = $PSScriptRoot }
    $modelPath = if ($base) { Join-Path $base "Model.ps1" } else { $null }
    if (-not (Get-Command Get-WindowsVersion -ErrorAction SilentlyContinue)) {
        if ($modelPath -and (Test-Path -LiteralPath $modelPath)) { . $modelPath }
    }
    if (Get-Command Get-WindowsVersion -ErrorAction SilentlyContinue) {
        return Get-WindowsVersion
    }
    return "Windows11"
}

function global:Initialize-ThemeBackend {
    param([string]$OS)

    $base = $script:ThemeManagerBase
    if (-not $base) { $base = $PSScriptRoot }
    if (-not $base) { throw "Theme manager base path could not be resolved." }

    $enginePath = Join-Path $base "ThemeEngine.ps1"
    if (!(Test-Path -LiteralPath $enginePath)) { throw "Theme engine not found: $enginePath" }
    . $enginePath

    if (-not $script:StrawberryProjectRoot) { $script:StrawberryProjectRoot = Split-Path $base -Parent }

    if ([string]::IsNullOrWhiteSpace($OS)) { $OS = Get-TargetThemeOS }
    $script:ThemeBackendInitializedOS = $OS
    return $OS
}

function global:Get-ThemeDefinition {
    param([Parameter(Mandatory)][string]$ThemeId)
    $theme = Get-ThemeCatalog | Where-Object { $_.Id -ieq $ThemeId } | Select-Object -First 1
    if (-not $theme) {
        $known = (Get-ThemeCatalog | ForEach-Object { $_.Id }) -join ', '
        throw "Unknown theme '$ThemeId'. Available themes: $known"
    }
    return $theme
}

function global:Invoke-Theme {
    param(
        [Parameter(Mandatory)][string]$ThemeId,
        [string]$OS
    )

    $theme = Get-ThemeDefinition -ThemeId $ThemeId
    $OS = Initialize-ThemeBackend -OS $OS

    $invokeName = "Invoke-$($theme.Id)Theme"
    if (Get-Command $invokeName -ErrorAction SilentlyContinue) {
        & $invokeName -OS $OS
        return
    }

    $projectRoot = $script:StrawberryProjectRoot
    if ([string]::IsNullOrWhiteSpace($projectRoot)) {
        $base = $script:ThemeManagerBase
        if ([string]::IsNullOrWhiteSpace($base)) { $base = $PSScriptRoot }
        if (-not [string]::IsNullOrWhiteSpace($base)) { $projectRoot = Split-Path $base -Parent }
    }
    if (-not [string]::IsNullOrWhiteSpace($projectRoot)) {
        $script:StrawberryProjectRoot = $projectRoot
        $themeScript = Join-Path $projectRoot "$OS\Themes\$($theme.Id)Theme.ps1"
        if (Test-Path -LiteralPath $themeScript) {
            . $themeScript
            if (Get-Command $invokeName -ErrorAction SilentlyContinue) {
                & $invokeName -OS $OS
                return
            }
        }
    }

    # Fallback: apply via shared engine directly (theme scripts are thin wrappers)
    if (-not (Get-Command Set-WindowsAccentTheme -ErrorAction SilentlyContinue)) {
        throw "Theme engine function Set-WindowsAccentTheme not available."
    }
    Set-WindowsAccentTheme -Name $theme.Name -Color $theme.Color -DisplayColor $theme.DisplayColor -OS $OS
}

# Backward-compatible aliases for existing call sites
function global:Install-PinkTheme { Invoke-Theme -ThemeId "Pink" }
function global:Install-BlueTheme { Invoke-Theme -ThemeId "Blue" }
function global:Install-YellowTheme { Invoke-Theme -ThemeId "Yellow" }
function global:Install-GreenTheme { Invoke-Theme -ThemeId "Green" }
