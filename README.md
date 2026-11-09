# JagodaWindowsSetup

Skripta za automatsku instalaciju i postavljanje Windows okruženja (Strawberry Windows Setup).

## Arhitektura

```
main.ps1
    │
    ├── Core/Model.ps1        - Get-WindowsVersion, Get-OSConfig
    ├── Core/Controller.ps1   - Show-MainMenu, Show-OSSpecs, Run-Installation, Get-SelectedApps
    │
    ├── Windows10/
    │   ├── Config.ps1        - $WindowsConfig (OS=Windows10, Theme=Pink, EnableWidgets=$false)
    │   ├── install.ps1       - Elevation + PinkSetup.ps1
    │   ├── PinkSetup.ps1     - Get-OSSpecs + menu
    │   ├── Themes/PinkTheme.ps1 - Set-Dword, ConvertTo-WindowsColor, New-AccentPalette,
    │   │                       Set-WindowsAccentTheme, Install-PinkTheme, Install-BlueTheme,
    │   │                       Install-YellowTheme, Install-GreenTheme
    │   ├── Installers/Programs.ps1 - Find-InstalledApp, Get-ProgramInstaller, Test-Winget,
    │   │                       Install-WithWinget, Install-OneApp, Install-YouTubeShortcut,
    │   │                       Install-Programs
    │   ├── SystemTools/Get-SystemSpecs.ps1 - Get-SystemSpecs, Test-IsWindows
    │   ├── Wallpapers/Wallpaper.ps1 - WALLPAPERS
    │   └── Modules/Logging.psm1 - Write-Log
    │
    └── Windows11/
        ├── Config.ps1        - $WindowsConfig (OS=Windows11, Theme=Pink, EnableWidgets=$true)
        └── install.ps1       - Elevation + Core/Controller orchestration
```

## Funkcije po fajlovima

| Fajl | Funkcije |
|------|----------|
| `main.ps1` | `Write-Log` |
| `Core/Model.ps1` | `Get-WindowsVersion`, `Get-OSConfig` |
| `Core/Controller.ps1` | `Get-SelectedApps`, `Show-MainMenu`, `Show-OSSpecs`, `Run-Installation` |
| `Windows10/Config.ps1` | (config varijable) |
| `Windows10/PinkSetup.ps1` | `Get-OSSpecs` |
| `Windows10/Themes/PinkTheme.ps1` | `Set-Dword`, `ConvertTo-WindowsColor`, `New-AccentPalette`, `Set-WindowsAccentTheme`, `Install-PinkTheme`, `Install-BlueTheme`, `Install-YellowTheme`, `Install-GreenTheme` |
| `Windows10/Installers/Programs.ps1` | `Find-InstalledApp`, `Get-ProgramInstaller`, `Test-Winget`, `Install-WithWinget`, `Install-OneApp`, `Install-YouTubeShortcut`, `Install-Programs` |
| `Windows10/SystemTools/Get-SystemSpecs.ps1` | `Get-SystemSpecs`, `Test-IsWindows` |
| `Windows10/Wallpapers/Wallpaper.ps1` | `WALLPAPERS` |
| `Windows10/Modules/Logging.psm1` | `Write-Log` |
| `Windows11/Config.ps1` | (config varijable) |
| `Windows11/install.ps1` | (orchestrator) |

## Menu opcije

**PinkSetup.ps1 (Windows 10):**
- `[1]` Choose Wallpaper
- `[2]` Choose Theme
- `[3]` Install Programs
- `[4]` OS Specifications
- `[5]` Complete Installation
- `[0]` Exit

**Core/Controller.ps1 (Windows 11):**
- `[1]` Install Programs
- `[2]` Apply Theme
- `[3]` Set Wallpaper
- `[4]` OS Specifications
- `[0]` Exit

## Zajedničko vs specifično

- **Zajedničke funkcije** (Core): instalacija Chrome/Firefox/7-Zip, logiranje, wallpaper, system info
- **Specifično po OS-u**: Config.ps1 postavke (npr. `EnableWidgets`), theme prilagodbe, menu struktura
- **Detekcija OS-a**: `Get-WindowsVersion` koristi `BuildNumber >= 22000` za Windows 11