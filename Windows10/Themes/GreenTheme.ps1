# Windows10/Themes/GreenTheme.ps1 - Green theme definition (delegates to shared Core engine)

function global:Invoke-GreenTheme {
    param([string]$OS)
    if (-not (Get-Command Set-WindowsAccentTheme -ErrorAction SilentlyContinue)) {
        $base = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
        if ($base) {
            $core = Join-Path (Split-Path (Split-Path $base -Parent) -Parent) 'Core\ThemeManager.ps1'
            if (Test-Path -LiteralPath $core) { . $core; Initialize-ThemeBackend -OS $OS | Out-Null }
        }
    }
    if (-not (Get-Command Set-WindowsAccentTheme -ErrorAction SilentlyContinue)) {
        throw 'Theme engine not available (Set-WindowsAccentTheme missing).'
    }
    Set-WindowsAccentTheme -Name 'Green' -Color '#32CD32' -DisplayColor Green -OS $OS
}

function global:Install-GreenTheme { Invoke-GreenTheme }
