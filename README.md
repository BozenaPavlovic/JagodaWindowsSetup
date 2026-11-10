# JagodaWindowsSetup

Skripta za automatsku instalaciju i postavljanje Windows okruženja (Strawberry Windows Setup).

## Arhitektura

```
JagodaWindowsSetup/
│
├── main.ps1                    - OS router + Write-Log
│
├── Core/
│   ├── Model.ps1               - Get-WindowsVersion, Get-OSConfig
│   ├── Controller.ps1          - Show-MainMenu, Show-OSSpecs, Run-Installation, Get-SelectedApps
│   ├── Installer.ps1           - Install-OneApp (router to OS-specific installer)
│   ├── ProgramDatabase.ps1     - $Global:Apps (Chrome, VLC, LibreOffice, 7-Zip, Python 3.14)
│   ├── InstallerHelpers.ps1    - Initialize-InstallerBackend, Find-InstalledApp, Test-Winget,
│                                 Install-WithWinget, Get-ProgramInstaller, Write-InstallerLog,
│                                 Install-YouTubeShortcut
│   ├── Logging.ps1             - Write-AppLog (centralized logging: Activity/Installation/Error logs)
│   ├── ThemeEngine.ps1         - Set-ThemeDword, ConvertTo-WindowsColor, New-AccentPalette,
│                                 Invoke-ThemeRefresh, Set-WindowsAccentTheme
│   └── ThemeManager.ps1        - Get-ThemeCatalog, Get-TargetThemeOS, Initialize-ThemeBackend,
│                                 Get-ThemeDefinition, Invoke-Theme, Install-Pink/Blue/Yellow/GreenTheme
│
├── Windows10/
│   ├── Config.ps1              - $Global:PinkConfig, $Global:WindowsConfig (OS=Windows10, Theme=Pink, EnableWidgets=$false)
│   ├── install.ps1             - Elevation check + Core/Controller orchestration
│   ├── PinkSetup.ps1           - Get-OSSpecs + CLI menu (5 options: wallpaper, theme, programs, specs, complete)
│   ├── START.ps1 / START.bat   - Portable starter (launches GUI\MainMenu.ps1)
│   ├── Config/
│   │   └── settings.json
│   ├── Installers/
│   │   └── Programs.ps1        - Install-Programs, Find-InstalledApp, Get-ProgramInstaller,
│   │                             Test-Winget, Install-WithWinget, Install-OneApp,
│   │                             Install-YouTubeShortcut
│   ├── Modules/
│   │   └── Logging.psm1        - Write-Log (Windows10 specific)
│   ├── SystemTools/
│   │   ├── Get-SystemSpecs.ps1 - Get-SystemSpecs, Test-IsWindows
│   │   └── PCInfo.ps1
│   ├── Themes/
│   │   ├── PinkTheme.ps1       - Invoke-PinkTheme, Install-PinkTheme (delegates to Core engine)
│   │   ├── BlueTheme.ps1
│   │   ├── GreenTheme.ps1
│   │   └── YellowTheme.ps1
│   └── Wallpapers/
│       └── Wallpaper.ps1       - WALLPAPERS (sets desktop wallpaper via SystemParametersInfo)
│
├── Windows11/
│   ├── Config.ps1              - $Global:PinkConfig, $Global:WindowsConfig (OS=Windows11, Theme=Pink, EnableWidgets=$true, EnableDarkMode=$true)
│   ├── install.ps1             - Elevation check + Core/Controller orchestration
│   └── Themes/
│       ├── PinkTheme.ps1       - Invoke-PinkTheme, Install-PinkTheme (delegates to Core engine)
│       ├── BlueTheme.ps1
│       ├── GreenTheme.ps1
│       └── YellowTheme.ps1
│
├── Linux/
│   └── install.ps1
│
├── MacOS/
│   └── install.ps1
│
├── GUI/
│   ├── MainMenu.ps1                    - Entry point (WinForms app, loads Model/View/Controller)
│   ├── Models/
│   │   └── MainMenuModel.ps1           - Get-SystemInformation (OS, CPU, GPU, RAM, Disk, Uptime, Admin status)
│   ├── Helpers/
│   │   └── SystemInformationFormatter.ps1 - Format-SystemInformation (formats PSCustomObject to string)
│   ├── Views/
│   │   ├── MainMenuView.ps1            - Creates Form + adds MainMenuPanel + SystemInformationPanel
│   │   ├── MainMenuPanel.ps1           - Menu buttons (Profile Installer, Apps Installer, Theme Manager, Wallpaper Manager, Log Viewer, About, Exit)
│   │   └── SystemInformationPanel.ps1  - System info display panel (docked bottom, 350px height)
│   ├── Controllers/
│   │   └── MainMenuController.ps1      - Initialize-MainMenuController (button click handlers, window routing)
│   └── OtherWindows/
│       ├── About.ps1                   - Simple About dialog
│       ├── AppsInstaller.ps1           - GUI app selector with checkboxes, profile filtering, Install-OneApp integration
│       ├── ProfileInstaller.ps1        - Profile selection (Profil A/B/C) -> launches AppsInstaller with profile
│       ├── ThemeManager.ps1            - Theme picker GUI (dynamic from Get-ThemeCatalog, Apply button uses Invoke-Theme)
│       ├── WallpaperManager.ps1        - Lists JPG files from Photos folder
│       ├── LogViewer.ps1               - Displays InstallationHistory.log in TextBox
│       └── LoadInstallerBackend.ps1    - Loads Logging, ProgramDatabase, InstallerHelpers, Windows10 installer, ThemeManager; sets $Global:AutoMode=$true
│
├── DATA/
│   └── Photos/
│       ├── Pink-Strawberry.jpg
│       └── Yellow-Flowers-Blue-Sky.jpg
│
├── Logs/
│   ├── Activity.log
│   ├── Errors.log
│   ├── Google_Chrome.log
│   ├── Installation.log
│   └── InstallationHistory.log
│
└── Koncepti/
    ├── PrviKoncept.txt
    ├── DrugiKoncept.txt
    ├── TrećiKoncept.txt
    └── ČetvrtiKoncept.txt
```

## Funkcije po fajlovima

| Fajl | Funkcije |
|------|----------|
| `main.ps1` | `Write-Log` |
| `Core/Model.ps1` | `Get-WindowsVersion` (detects Win10/Win11 via BuildNumber >= 22000), `Get-OSConfig` (loads OS-specific Config.ps1, returns `$Global:WindowsConfig`) |
| `Core/Controller.ps1` | `Get-SelectedApps` (filters `$Global:Apps` by IDs), `Show-MainMenu` (CLI menu: Install Programs, Apply Theme, Set Wallpaper, OS Specs, Exit), `Show-OSSpecs` (displays system specs via `Get-SystemSpecs`), `Run-Installation` (entry point: `Show-MainMenu`) |
| `Core/Installer.ps1` | `Install-OneApp` (router: calls Windows10 or Windows11 installer based on OS) |
| `Core/ProgramDatabase.ps1` | `$Global:Apps` (array of hashtables: Number, Name, Match, File, URL, Type, InteractiveArguments, SilentArguments, MinBytes, Publisher, WingetID) |
| `Core/InstallerHelpers.ps1` | `Initialize-InstallerBackend` (detects OS, loads Config, sets $Global:InstallerConfig with DownloadFolder/LogFolder), `Find-InstalledApp` (searches registry Uninstall keys), `Test-Winget` (checks winget.exe), `Install-WithWinget` (installs via winget --id), `Get-ProgramInstaller` (downloads installer to DownloadFolder, verifies MinBytes), `Write-InstallerLog` (appends to InstallationHistory.log), `Install-YouTubeShortcut` (creates YouTube.url on Desktop) |
| `Core/Logging.ps1` | `Write-AppLog` (centralized logging: Message, Level [INFO/SUCCESS/WARNING/ERROR], LogType [ACTIVITY/INSTALLATION/ERROR]; writes to Activity.log/Installation.log/Errors.log) |
| `Core/ThemeEngine.ps1` | `Set-ThemeDword` (registry helper), `ConvertTo-WindowsColor` (#RRGGBB -> ABGR int), `New-AccentPalette` (generates 8-color palette from base color), `Invoke-ThemeRefresh` (SendMessageTimeout WM_SETTINGCHANGE + explorer restart), `Set-WindowsAccentTheme` (applies theme to Personalize/DWM/Accent registry keys, calls Invoke-ThemeRefresh) |
| `Core/ThemeManager.ps1` | `Get-ThemeCatalog` (returns Pink/Blue/Yellow/Green theme definitions), `Get-TargetThemeOS` (detects OS via Get-WindowsVersion or CIM), `Initialize-ThemeBackend` (loads ThemeEngine.ps1, sets OS), `Get-ThemeDefinition` (looks up theme by ID), `Invoke-Theme` (dispatches to OS-specific Invoke-<Theme>Theme or falls back to Set-WindowsAccentTheme), `Install-Pink/Blue/Yellow/GreenTheme` (backward-compatible aliases) |
| `Windows10/Config.ps1` | `$Global:PinkConfig` (Root, WallpaperFolder, DownloadFolder, CacheFolder, LogFolder, WallpaperURL), `$Global:WindowsConfig` (OS=Windows10, Theme=Pink, EnableDarkMode=$true, InstallWinget=$true, EnableWidgets=$false), `$Global:PinkEnvironment` (ComputerName, UserName, WindowsVersion, PowerShellVersion, Is64Bit) |
| `Windows10/install.ps1` | Elevation check (restarts as Admin), loads Core/Model.ps1, Core/Controller.ps1, Config.ps1, Windows10/SystemTools/Get-SystemSpecs.ps1, calls `Run-Installation` |
| `Windows10/PinkSetup.ps1` | `Get-OSSpecs` (reads HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion), CLI menu loop (1=Wallpaper, 2=Theme, 3=Programs, 4=Specs, 5=Complete Installation via GUI\ProgramInstaller.ps1, 0=Exit) |
| `Windows10/START.ps1` / `START.bat` | Portable launcher for GUI\MainMenu.ps1 |
| `Windows10/Installers/Programs.ps1` | `Find-InstalledApp` (registry search), `Get-ProgramInstaller` (download with progress), `Test-Winget`, `Install-WithWinget`, `Install-OneApp` (handles MSI/EXE, interactive/auto mode, verification loop), `Install-YouTubeShortcut`, `Install-Programs` (menu: 1=All, 2=Chrome, 3=YouTube, 4=VLC, 5=LibreOffice, 6=7-Zip, 7=Python) |
| `Windows10/SystemTools/Get-SystemSpecs.ps1` | `Get-SystemSpecs` (returns hashtable: OS, Platform, IsWindows, ComputerName, UserName, Is64Bit, PowerShell; optional JSON output), `Test-IsWindows` |
| `Windows10/SystemTools/PCInfo.ps1` | (empty/helper) |
| `Windows10/Themes/PinkTheme.ps1` | `Invoke-PinkTheme` (loads Core ThemeManager if needed, calls Set-WindowsAccentTheme with Pink/#FF69B4), `Install-PinkTheme` (alias) |
| `Windows10/Themes/BlueTheme.ps1` | `Invoke-BlueTheme`, `Install-BlueTheme` |
| `Windows10/Themes/GreenTheme.ps1` | `Invoke-GreenTheme`, `Install-GreenTheme` |
| `Windows10/Themes/YellowTheme.ps1` | `Invoke-YellowTheme`, `Install-YellowTheme` |
| `Windows10/Wallpapers/Wallpaper.ps1` | `WALLPAPERS` (param $Number=1/2, sets wallpaper via SystemParametersInfo SPI_SETDESKWALLPAPER) |
| `Windows10/Modules/Logging.psm1` | `Write-Log` (simple file logging) |
| `Windows11/Config.ps1` | `$Global:PinkConfig`, `$Global:WindowsConfig` (OS=Windows11, Theme=Pink, EnableDarkMode=$true, InstallWinget=$true, EnableWidgets=$true), `$Global:PinkEnvironment` |
| `Windows11/install.ps1` | Elevation check, loads Core/Model.ps1, Core/Controller.ps1, Config.ps1, Windows10/SystemTools/Get-SystemSpecs.ps1, calls `Run-Installation` |
| `Windows11/Themes/PinkTheme.ps1` | `Invoke-PinkTheme`, `Install-PinkTheme` (delegates to Core ThemeEngine) |
| `Windows11/Themes/BlueTheme.ps1` | `Invoke-BlueTheme`, `Install-BlueTheme` |
| `Windows11/Themes/GreenTheme.ps1` | `Invoke-GreenTheme`, `Install-GreenTheme` |
| `Windows11/Themes/YellowTheme.ps1` | `Invoke-YellowTheme`, `Install-YellowTheme` |
| `GUI/MainMenu.ps1` | Entry point: loads Model/View/Controller, `Get-SystemInformation`, `Format-SystemInformation`, `Initialize-MainMenuController`, `Form.ShowDialog()` |
| `GUI/Models/MainMenuModel.ps1` | `Get-SystemInformation` (returns PSCustomObject: OS, Version, Build, ComputerName, Model, Username, CPU, GPU, RAM, DiskFree, DiskSize, Architecture, PowerShellVersion, Uptime, Administrator) |
| `GUI/Helpers/SystemInformationFormatter.ps1` | `Format-SystemInformation` (formats PSCustomObject to multi-line string for display) |
| `GUI/Views/MainMenuView.ps1` | Creates `$script:Form`, loads MainMenuPanel.ps1 + SystemInformationPanel.ps1, adds to Form.Controls |
| `GUI/Views/MainMenuPanel.ps1` | Creates `$script:MainMenuPanel` (Dock=Fill), title label, 6 menu buttons (Profile Installer, Apps Installer, Theme Manager, Wallpaper Manager, Log Viewer, About), Exit button, responsive resize handler |
| `GUI/Views/SystemInformationPanel.ps1` | Creates `$script:SystemInformationPanel` (Dock=Bottom, Height=350), title label, info label (Consolas 8pt), responsive resize handler |
| `GUI/Controllers/MainMenuController.ps1` | `Initialize-MainMenuController` (maps button Tags to OtherWindows scripts, click handler opens window via `& $windowPath`, Exit button closes Form) |
| `GUI/OtherWindows/About.ps1` | Simple WinForms dialog with info text |
| `GUI/OtherWindows/AppsInstaller.ps1` | Param `$ProfileName`, loads LoadInstallerBackend.ps1, defines profiles (A=2,4,6,7 / B=2,4 / C=6,7), creates Form with CheckBoxes for apps, Select All/Deselect All, Install Selected (calls `Install-OneApp` per app with `$Global:AutoMode=$true`), Back/Close button |
| `GUI/OtherWindows/ProfileInstaller.ps1` | `Show-ProfileForm` (profile selection dialog), loop: shows profile form -> launches AppsInstaller.ps1 with -ProfileName -> breaks on non-"Back" result |
| `GUI/OtherWindows/ThemeManager.ps1` | Loads LoadInstallerBackend.ps1 + Core ThemeManager fallback, gets themes via `Get-ThemeCatalog`, creates Form with colored buttons per theme, Apply button calls `Invoke-Theme -ThemeId`, Close button |
| `GUI/OtherWindows/WallpaperManager.ps1` | Lists JPG files from Photos folder in ListBox |
| `GUI/OtherWindows/LogViewer.ps1` | Reads Logs\InstallationHistory.log, displays in read-only multiline TextBox |
| `GUI/OtherWindows/LoadInstallerBackend.ps1` | Validates required files, loads Core/Logging.ps1, Core/ProgramDatabase.ps1, Core/InstallerHelpers.ps1, Windows10/Installers/Programs.ps1, Core/ThemeManager.ps1, calls `Initialize-ThemeBackend`, sets `$Global:AutoMode=$true` |

## Menu opcije

**PinkSetup.ps1 (Windows 10 CLI):**
- `[1]` Choose Wallpaper
- `[2]` Choose Theme
- `[3]` Install Programs
- `[4]` OS Specifications
- `[5]` Complete Installation (launches GUI\ProgramInstaller.ps1)
- `[0]` Exit

**Core/Controller.ps1 (Windows 11 CLI via main.ps1):**
- `[1]` Install Programs
- `[2]` Apply Theme
- `[3]` Set Wallpaper
- `[4]` OS Specifications
- `[0]` Exit

**GUI MainMenu (WinForms):**
- Profile Installer
- Apps Installer
- Theme Manager
- Wallpaper Manager
- Log Viewer
- About
- Exit

**AppsInstaller (GUI):**
- Profile-filtered or all apps with checkboxes
- Select All / Deselect All
- Install Selected (runs in AutoMode)

**ProfileInstaller (GUI):**
- Profil A (Chrome, VLC, 7-Zip, Python)
- Profil B (Chrome, VLC)
- Profil C (7-Zip, Python)

## Zajedničko vs specifično

- **Zajedničke funkcije** (Core): instalacija Chrome/Firefox/7-Zip, logiranje, wallpaper, system info, theme engine
- **Specifično po OS-u**: Config.ps1 postavke (npr. `EnableWidgets`=$true za Win11, $false za Win10), theme prilagodbe, menu struktura
- **Detekcija OS-a**: `Get-WindowsVersion` koristi `BuildNumber >= 22000` za Windows 11
- **Shared theme engine**: Core/ThemeEngine.ps1 + Core/ThemeManager.ps1 used by both Win10 and Win11 theme scripts
- **GUI backend**: LoadInstallerBackend.ps1 loads shared Core modules + Windows10 installer engine for GUI use