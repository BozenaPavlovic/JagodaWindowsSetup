# JagodaWindowsSetup

PowerShell projekat za automatsku instalaciju programa i postavljanje Windows okruženja (Strawberry / Jagoda Windows Setup). Podržana okruženja: Windows 10 i Windows 11, sa dijeljenom (shared) logikom u `Core/`.

## Ulazne tačke

| Fajl | Namjena |
|------|---------|
| `START\START.bat` / `START\START.ps1` | Glavni korisnički pokretač (klik): provjere okruženja (Windows, PowerShell 5.1+), učitavanje `START\Config.ps1`, pokretanje GUI-ja `GUI\MainMenu.ps1`. |
| `START\install.ps1` | Pokreće se iz START foldera; traži admin privilegije i pokreće `main.ps1`. |
| `START\PinkSetup.ps1` | CLI meni iz START foldera (wallpaper, tema, programi, specifikacije, kompletna instalacija) uz dijeljene Core module/engine. |
| `main.ps1` | Application router: detektuje OS (`Get-WindowsVersion` iz `Core\Model.ps1`), loguje u `Logs\main.log`, pokreće `Windows11\install.ps1` (Windows 11) ili `Windows10\install.ps1` (Windows 10). |
| `Windows11\install.ps1` | Admin elevacija, učitavanje `Core\Model.ps1`, `Core\Controller.ps1`, `Windows11\Config.ps1`, `Core\SystemTools\Get-SystemSpecs.ps1`, poziv `Run-Installation`. |
| `Windows10\install.ps1` | Isti ulazni obrazac za Windows 10: elevacija, učitavanje Core modula i `Windows10\Config.ps1`, pokretanje `Run-Installation`. |
| `GUI\MainMenu.ps1` | WinForms GUI ulazna tačka (MVC: Model/View/Controller). |

## Struktura foldera

```text
JagodaWindowsSetup/
├── main.ps1
├── README.md
│
├── START/
│   ├── START.bat
│   ├── START.ps1
│   ├── PinkSetup.ps1
│   ├── install.ps1
│   ├── Config.ps1
│   └── Logs/
│
├── Core/
│   ├── Installers/
│   │   ├── 01_Configuration.ps1   # učitava OS Config, postavlja DownloadFolder/LogFolder
│   │   ├── 02_UiHelpers.ps1       # Invoke-UiRefresh, Wait-ProcessWithUiRefresh
│   │   ├── 03_AppDetection.ps1    # Find-InstalledApp
│   │   ├── 04_Download.ps1        # Get-ProgramInstaller
│   │   ├── 05_Winget.ps1          # Test-Winget, Install-WithWinget
│   │   ├── 06_InstallApplication.ps1  # Install-OneApp, Install-Programs
│   │   └── Programs.ps1           # agreguje 01–06 (dijeljeni instalacioni engine)
│   ├── SystemTools/
│   │   └── Get-SystemSpecs.ps1    # Get-SystemSpecs, Test-IsWindows
│   ├── Wallpapers/
│   │   └── Wallpaper.ps1          # WALLPAPERS (SystemParametersInfo)
│   ├── Controller.ps1             # Get-SelectedApps, Show-MainMenu, Show-OSSpecs, Run-Installation
│   ├── Installer.ps1              # Install-OneApp wrapper (stvarna implementacija u 06_InstallApplication.ps1)
│   ├── InstallerConfig.ps1        # $Global:InstallerSettings (InstallCooldownSeconds = 5s)
│   ├── InstallerHelpers.ps1       # Initialize-InstallerBackend, Invoke-UiRefresh, Wait-ProcessWithUiRefresh, Find-InstalledApp, Test-Winget, Install-WithWinget, Get-ProgramInstaller, Write-InstallerLog, Get-InstallCooldownSeconds, Invoke-InstallCooldown, Install-YouTubeShortcut
│   ├── Logging.ps1                # Write-AppLog (Activity.log, Installation.log, Errors.log)
│   ├── Model.ps1                  # Get-WindowsVersion, Get-OSConfig
│   ├── Paths.ps1                  # Get-ProjectRoot, $Global:ProjectRoot/DataFolder/PhotosFolder/LogsFolder
│   ├── ProgramDatabase.ps1        # wrapper -> DATABASE\ProgramDatabase.ps1
│   ├── ThemeEngine.ps1            # Set-ThemeDword, ConvertTo-WindowsColor, New-AccentPalette, Invoke-ThemeRefresh, Set-WindowsAccentTheme
│   └── ThemeManager.ps1           # Get-ThemeCatalog, Get-TargetThemeOS, Initialize-ThemeBackend, Get-ThemeDefinition, Invoke-Theme, Install-*-Theme aliasi
│
├── DATABASE/
│   ├── ProgramDatabase.ps1        # učitava definicije iz DATABASE\Installers
│   └── Installers/
│       ├── Compression.ps1
│       ├── Development.ps1
│       ├── Media.ps1
│       ├── Messaging.ps1
│       ├── Office.ps1
│       ├── Utilities.ps1
│       └── WebBrowsers.ps1
│
├── GUI/
│   ├── MainMenu.ps1
│   ├── Controllers/
│   │   ├── MainMenuController.ps1
│   │   └── ProfileController.ps1
│   ├── Helpers/
│   │   └── SystemInformationFormatter.ps1
│   ├── Models/
│   │   ├── MainMenuModel.ps1
│   │   └── ProfileModel.ps1
│   ├── Views/
│   │   ├── MainMenuView.ps1
│   │   ├── MainMenuPanel.ps1
│   │   └── SystemInformationPanel.ps1
│   └── OtherWindows/
│       ├── About.ps1
│       ├── AppsInstaller.ps1
│       ├── LoadInstallerBackend.ps1
│       ├── LogViewer.ps1
│       ├── ProfileInstaller.ps1
│       ├── ThemeManager.ps1
│       └── WallpaperManager.ps1
│
├── Windows11/
│   ├── Config.ps1                 # $Global:PinkRoot/Work/Config/WindowsConfig/Environment
│   ├── install.ps1                # entry (elevacija, Core moduli, Run-Installation)
│   └── Themes/ (Blue/Green/Pink/Yellow)
│
├── Windows10/
│   ├── Config.ps1                 # konfiguracija za Windows 10
│   ├── install.ps1                # entry za Windows 10
│   └── Themes/ (Blue/Green/Pink/Yellow)
│
├── DATA/
│   ├── Photos/                    # wallpaper slike (.jpg)
│   └── Profiles/
│       └── CustomProfiles.json    # custom user profiles (JSON, automatski se kreira)
│
├── Logs/
├── START\Logs/
├── Koncepti/                      # konceptne datoteke (Prvi/Drugi/Treći/Četvrti Koncept.txt)
├── Linux/install.ps1
└── MacOS/install.ps1
```

## Instalacioni engine i cooldown (shared)

- **`Core\Installers\Programs.ps1`** – djeljeni instalacioni engine. Agregira šest modula u redoslijedu: `01_Configuration.ps1` (config + foldovi), `02_UiHelpers.ps1` (`Invoke-UiRefresh`, `Wait-ProcessWithUiRefresh`), `03_AppDetection.ps1` (`Find-InstalledApp`), `04_Download.ps1` (`Get-ProgramInstaller`), `05_Winget.ps1` (`Test-Winget`, `Install-WithWinget`), `06_InstallApplication.ps1` (`Install-OneApp`, `Install-Programs`). Kasnije učitani moduli prevazilaze ranije definicije istih funkcija.
- **Sekvencijalna instalacija:** svaka instalacija se čeka do završetka (`winget` ili `Start-Process -Wait -PassThru` za MSI/EXE) uz provjeru prisutnosti aplikacije u registru prije prelaska na sljedeću.
- **Cooldown između aplikacija:** podrazumijevano **5 sekundi** (`Core\InstallerConfig.ps1`, `$Global:InstallerSettings.InstallCooldownSeconds`). `Core\InstallerHelpers.ps1`: `Get-InstallCooldownSeconds` i `Invoke-InstallCooldown` (log, odbrojavanje, `Start-Sleep`; 0 preskače čekanje). Poziva se u `finally` bloku `Install-OneApp` (`Core\Installers\06_InstallApplication.ps1`).
- **Napredak:** CLI/GUI batch prikazuje progres (`X of Y`, `INSTALL PROGRESS: Index/Total`).

## Core moduli i funkcije

| Fajl | Funkcije / varijable | Opis |
|------|-----------------------|------|
| `main.ps1` | `Write-Log` | OS router; detekcija OS-a, log u `Logs\main.log`, pokretanje `Windows10\install.ps1` ili `Windows11\install.ps1`. |
| `Core\Model.ps1` | `Get-WindowsVersion`, `Get-OSConfig` | Detekcija OS-a (build >= 22000 → Windows11) i učitavanje odgovarajućeg `Windows10/Windows11\Config.ps1`. |
| `Core\Controller.ps1` | `Get-SelectedApps`, `Show-MainMenu`, `Show-OSSpecs`, `Run-Installation` | CLI kontroler/meni (programi, tema, wallpaper, specifikacije). |
| `Core\Installer.ps1` | `Install-OneApp` | Ulaz za instalaciju jedne aplikacije; stvarna implementacija je u `Core\Installers\06_InstallApplication.ps1`. |
| `Core\InstallerConfig.ps1` | `$Global:InstallerSettings` | Dijeljena konfiguracija instalera (`InstallCooldownSeconds = 5`). |
| `Core\InstallerHelpers.ps1` | `Initialize-InstallerBackend`, `Invoke-UiRefresh`, `Wait-ProcessWithUiRefresh`, `Find-InstalledApp`, `Test-Winget`, `Install-WithWinget`, `Get-ProgramInstaller`, `Write-InstallerLog`, `Get-InstallCooldownSeconds`, `Invoke-InstallCooldown`, `Install-YouTubeShortcut` | Pomoćne funkcije za backend, detekciju, winget/download/log i cooldown. (Funkcije detekcije/download/winget se prevazilaze kada se učita `Core\Installers\Programs.ps1`.) |
| `Core\Installers\Programs.ps1` | `Find-InstalledApp`, `Get-ProgramInstaller`, `Test-Winget`, `Install-WithWinget`, `Install-OneApp`, `Install-Programs` | Dijeljeni instalacioni engine (agregira 01–06). |
| `Core\Logging.ps1` | `Write-AppLog` | Centralizovano logovanje (`Activity.log`, `Installation.log`, `Errors.log`). |
| `Core\Paths.ps1` | `Get-ProjectRoot`, `$Global:ProjectRoot`, `$Global:DataFolder`, `$Global:PhotosFolder`, `$Global:LogsFolder` | Pronalaženje root-a projekta i standardnih putanja. |
| `Core\ProgramDatabase.ps1` | (wrapper) | Učitava `DATABASE\ProgramDatabase.ps1`. |
| `Core\ThemeEngine.ps1` | `Set-ThemeDword`, `ConvertTo-WindowsColor`, `New-AccentPalette`, `Invoke-ThemeRefresh`, `Set-WindowsAccentTheme` | Primjena Windows accent/theme podešavanja. |
| `Core\ThemeManager.ps1` | `Get-ThemeCatalog`, `Get-TargetThemeOS`, `Initialize-ThemeBackend`, `Get-ThemeDefinition`, `Invoke-Theme`, `Install-PinkTheme`, `Install-BlueTheme`, `Install-YellowTheme`, `Install-GreenTheme` | Katalog tema i dispatch primjene teme. |
| `Core\Wallpapers\Wallpaper.ps1` | `WALLPAPERS` | Postavljanje wallpaper-a (`SystemParametersInfo`). |
| `Core\SystemTools\Get-SystemSpecs.ps1` | `Get-SystemSpecs`, `Test-IsWindows` | Prikupljanje sistemskih specifikacija. |

## Baza programa (`DATABASE`)

- `DATABASE\ProgramDatabase.ps1`: učitava sve `.ps1` definicije iz `DATABASE\Installers\` i puni `$Global:Apps`.
- `Core\ProgramDatabase.ps1`: wrapper koji poziva `DATABASE\ProgramDatabase.ps1`.
- Kategorije u `DATABASE\Installers\`: `Compression.ps1`, `Development.ps1`, `Media.ps1`, `Messaging.ps1`, `Office.ps1`, `Utilities.ps1`, `WebBrowsers.ps1`.

## GUI (WinForms, MVC stil)

| Fajl | Funkcije / uloga |
|------|------------------|
| `GUI\MainMenu.ps1` | Ulazna tačka GUI-ja: učitava model/view/controller, prikazuje formu. |
| `GUI\Models\MainMenuModel.ps1` | `Get-SystemInformation` (OS, verzija, build, CPU, GPU, RAM, disk, uptime, admin itd.). |
| `GUI\Helpers\SystemInformationFormatter.ps1` | `Format-SystemInformation`. |
| `GUI\Views\MainMenuView.ps1` | Kreira glavnu formu i dodaje panele. |
| `GUI\Views\MainMenuPanel.ps1` | Dugmad: Profile Installer, Apps Installer, Theme Manager, Wallpaper Manager, Log Viewer, About, Exit. |
| `GUI\Views\SystemInformationPanel.ps1` | Panel sistemskih informacija. |
| `GUI\Controllers\MainMenuController.ps1` | `Initialize-MainMenuController` (mapiranje klikova na `GUI\OtherWindows`). |
| `GUI\OtherWindows\LoadInstallerBackend.ps1` | Učitava Core logging/database/helpers, `Core\Installers\Programs.ps1` i ThemeManager; postavlja `$Global:AutoMode = $true`. |
| `GUI\OtherWindows\AppsInstaller.ps1` | GUI izbor i instalacija aplikacija (checkbox lista, Select/Deselect All, profili, `Install-OneApp` sa progresom). |
| `GUI\OtherWindows\ProfileInstaller.ps1` | Installation Manager – custom profili (Create/Edit/Delete/Install) uz `ProfileModel`/`ProfileController`. |
| `GUI\Models\ProfileModel.ps1` | JSON persistencija custom profila (`DATA\Profiles\CustomProfiles.json`). |
| `GUI\Controllers\ProfileController.ps1` | CRUD operacije i validacija profila. |
| `GUI\OtherWindows\ThemeManager.ps1` | Prikaz tema iz `Get-ThemeCatalog` i primjena preko `Invoke-Theme`. |
| `GUI\OtherWindows\WallpaperManager.ps1` | Prikaz/listanje JPG wallpaper-a iz `DATA\Photos`. |
| `GUI\OtherWindows\LogViewer.ps1` | `Load-Log`; prikaz `Logs\InstallationHistory.log`. |
| `GUI\OtherWindows\About.ps1` | About dijalog. |

## Windows 10 i Windows 11 moduli

| Fajl | Funkcije / varijable | Opis |
|------|-----------------------|------|
| `Windows10\Config.ps1` | `$Global:PinkRoot`, `$Global:PinkWork`, `$Global:PinkConfig`, `$Global:WindowsConfig`, `$Global:PinkEnvironment` | Konfiguracija za Windows 10 (putanje, okruženje; `EnableWidgets=$false`). |
| `Windows10\install.ps1` | (entry) | Elevacija, učitavanje Core modula i pokretanje `Run-Installation`. |
| `Windows10\Themes\*.ps1` | `Invoke-*Theme`, `Install-*Theme` | Windows 10 theme wrapperi (delegacija ka Core theme backend-u). |
| `Windows11\Config.ps1` | `$Global:PinkRoot`, `$Global:PinkWork`, `$Global:PinkConfig`, `$Global:WindowsConfig`, `$Global:PinkEnvironment` | Konfiguracija za Windows 11 (npr. `EnableWidgets=$true`). |
| `Windows11\install.ps1` | (entry) | Elevacija, učitavanje Core modula i pokretanje `Run-Installation`. |
| `Windows11\Themes\*.ps1` | `Invoke-*Theme`, `Install-*Theme` | Windows 11 theme wrapperi (delegacija ka Core theme backend-u). |

Novi **Installation Manager** (`GUI\OtherWindows\ProfileInstaller.ps1`) omogućava korisnicima da kreiraju, uređuju, brišu i instaliraju vlastite custom profile:

| Mogućnost | Opis |
|-----------|------|
| **Create Profile** | Unos naziva profila + odabir aplikacija iz checkbox liste (sve aplikacije iz baze, grupirano po kategoriji, sa pretragom i Select/Deselect All). |
| **Edit Profile** | Uređivanje postojećeg profila – promjena imena i/ili odabranih aplikacija. |
| **Delete Profile** | Brisanje profila sa potvrdom (neobnovljivo). |
| **Install Profile** | Pokreće instalaciju odabranih aplikacija profila preko shared `Install-OneApp` engine-a (sa 5s cooldown-om, progress `X of Y`, logiranje). Koristi `Resolve-ProfileApplications` za validaciju referenci na aplikacije. |
| **Validacija** | Jedinstveni nazivi profila, minimalno 1 aplikacija, nema duplikata AppIds, provjera da aplikacije postoje u bazi. |
| **Persistencija** | JSON fajl: `DATA\Profiles\CustomProfiles.json` (automatski se kreira ako ne postoji). |

## Podaci i logovi

- `DATA\Photos\`: wallpaper slike (`.jpg`).
- `DATA\Profiles\CustomProfiles.json`: custom user profiles (JSON) – kreira se automatski.
- `Logs\`: runtime logovi (`main.log`, `Activity.log`, `Errors.log`, `Installation.log`, `InstallationHistory.log`).
- `START\Logs\`: log folder za START tok.

## Napomene

- Zajedničke komponente: `Core/`, `DATABASE/`, `GUI/`, `START/`; Windows-specific: `Windows10/` i `Windows11/` (config, entry, theme wrapperi). Instalacioni engine, cooldown, wallpaper i system-spec helper su dijeljeni u `Core/`.
- `Linux/install.ps1` i `MacOS/install.ps1` su prisutni kao zasebni ulazi u strukturi repozitorija.
