# JagodaWindowsSetup

Skripta za automatsku instalaciju i postavljanje Windows okruženja (Strawberry Windows Setup).

## Arhitektura

```
main.ps1                - OS router + Write-Log
│
├── Core/
│   ├── Model.ps1               - Get-WindowsVersion, Get-OSConfig
│   ├── Controller.ps1          - Show-MainMenu, Show-OSSpecs, Run-Installation, Get-SelectedApps
│   ├── Installer.ps1           - Install-OneApp
│   ├── ProgramDatabase.ps1     - $Global:Apps (Chrome, VLC, LibreOffice, 7-Zip, Python 3.14)
│   └── InstallerHelpers.ps1    - Initialize-InstallerBackend, Find-InstalledApp, Test-Winget,
│                                 Install-WithWinget, Get-ProgramInstaller, Write-InstallerLog,
│                                 Install-YouTubeShortcut
│
├── Windows10/
│   ├── Config.ps1              - $WindowsConfig (OS=Windows10, Theme=Pink)
│   ├── install.ps1             - Elevation + Core/Controller orchestration
│   ├── PinkSetup.ps1           - Get-OSSpecs + CLI menu
│   ├── START.ps1 / START.bat   - Portable starter (launches GUI\MainMenu.ps1)
│   ├── Config/settings.json
│   ├── Themes/PinkTheme.ps1    - Set-Dword, ConvertTo-WindowsColor, New-AccentPalette,
│   │                             Set-WindowsAccentTheme, Install-PinkTheme,
│   │                             Install-BlueTheme, Install-YellowTheme, Install-GreenTheme
│   ├── Installers/Programs.ps1 - Find-InstalledApp, Get-ProgramInstaller, Test-Winget,
│   │                             Install-WithWinget, Install-OneApp, Install-YouTubeShortcut,
│   │                             Install-Programs
│   ├── SystemTools/Get-SystemSpecs.ps1 - Get-SystemSpecs, Test-IsWindows
│   ├── SystemTools/PCInfo.ps1
│   ├── Wallpapers/Wallpaper.ps1 - WALLPAPERS
│   └── Modules/Logging.psm1    - Write-Log
│
├── Windows11/
│   ├── Config.ps1   - $WindowsConfig (OS=Windows11, Theme=Pink, EnableWidgets=$true)
│   └── install.ps1  - Elevation + Core/Controller orchestration
│
├── Linux/install.ps1
├── MacOS/install.ps1
│
├── GUI/
│   ├── MainMenu.ps1             - Entry point (WinForms app)
│   ├── Models/MainMenuModel.ps1 - Get-SystemInformation
│   ├── Helpers/SystemInformationFormatter.ps1 - Format-SystemInformation
│   ├── Views/MainMenuView.ps1               - Form + panel layout
│   ├── Views/MainMenuPanel.ps1              - Menu buttons panel
│   ├── Views/SystemInformationPanel.ps1     - System info panel
│   ├── Controllers/MainMenuController.ps1   - Initialize-MainMenuController
│   └── OtherWindows/
│       ├── About.ps1
│       ├── AppsInstaller.ps1
│       ├── ProfileInstaller.ps1
│       ├── ThemeManager.ps1
│       ├── WallpaperManager.ps1
│       ├── LogViewer.ps1
│       └── LoadInstallerBackend.ps1
│
├── DATA/Photos/*.jpg
├── Logs/*.log
└── Koncepti/*.txt
```

## Funkcije po fajlovima

| Fajl | Funkcije |
|------|----------|
| `main.ps1` | `Write-Log` |
| `Core/Model.ps1` | `Get-WindowsVersion`, `Get-OSConfig` |
| `Core/Controller.ps1` | `Get-SelectedApps`, `Show-MainMenu`, `Show-OSSpecs`, `Run-Installation` |
| `Core/Installer.ps1` | `Install-OneApp` |
| `Core/ProgramDatabase.ps1` | `$Global:Apps` |
| `Core/InstallerHelpers.ps1` | `Initialize-InstallerBackend`, `Find-InstalledApp`, `Test-Winget`, `Install-WithWinget`, `Get-ProgramInstaller`, `Write-InstallerLog`, `Install-YouTubeShortcut` |
| `Windows10/Config.ps1` | (config varijable) |
| `Windows10/PinkSetup.ps1` | `Get-OSSpecs` |
| `Windows10/Themes/PinkTheme.ps1` | `Set-Dword`, `ConvertTo-WindowsColor`, `New-AccentPalette`, `Set-WindowsAccentTheme`, `Install-PinkTheme`, `Install-BlueTheme`, `Install-YellowTheme`, `Install-GreenTheme` |
| `Windows10/Installers/Programs.ps1` | `Find-InstalledApp`, `Get-ProgramInstaller`, `Test-Winget`, `Install-WithWinget`, `Install-OneApp`, `Install-YouTubeShortcut`, `Install-Programs` |
| `Windows10/SystemTools/Get-SystemSpecs.ps1` | `Get-SystemSpecs`, `Test-IsWindows` |
| `Windows10/SystemTools/PCInfo.ps1` | - |
| `Windows10/Wallpapers/Wallpaper.ps1` | `WALLPAPERS` |
| `Windows10/Modules/Logging.psm1` | `Write-Log` |
| `Windows11/Config.ps1` | (config varijable) |
| `Windows11/install.ps1` | (orchestrator) |
| `GUI/MainMenu.ps1` | (entry point) |
| `GUI/Models/MainMenuModel.ps1` | `Get-SystemInformation` |
| `GUI/Helpers/SystemInformationFormatter.ps1` | `Format-SystemInformation` |
| `GUI/Views/MainMenuView.ps1` | (UI layout) |
| `GUI/Views/MainMenuPanel.ps1` | (UI layout) |
| `GUI/Views/SystemInformationPanel.ps1` | (UI layout) |
| `GUI/Controllers/MainMenuController.ps1` | `Initialize-MainMenuController` |
| `GUI/OtherWindows/About.ps1` | (About dialog) |
| `GUI/OtherWindows/AppsInstaller.ps1` | (app selection + Install-OneApp) |
| `GUI/OtherWindows/ProfileInstaller.ps1` | (profile-based app install) |
| `GUI/OtherWindows/ThemeManager.ps1` | (theme picker dialog) |
| `GUI/OtherWindows/WallpaperManager.ps1` | (wallpaper list dialog) |
| `GUI/OtherWindows/LogViewer.ps1` | (log display dialog) |
| `GUI/OtherWindows/LoadInstallerBackend.ps1` | (empty placeholder) |

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