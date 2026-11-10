# Windows10/Themes/YellowTheme.ps1 - Yellow theme definition (delegates to shared Core engine)

function global:Invoke-YellowTheme {
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
    Set-WindowsAccentTheme -Name 'Yellow' -Color '#FFD700' -DisplayColor Yellow -OS $OS
}

function global:Install-YellowTheme { Invoke-YellowTheme }
