# JagodaWindowsSetup

PowerShell projekat za automatsku instalaciju programa i postavljanje Windows okruženja (Strawberry / Jagoda Windows Setup). Radi na Windows 10 i Windows 11, sa dijeljenom (shared) instalacionom logikom u `Core/`.

## Ulazne tačke

| Fajl | Namjena |
|------|---------|
| `START\START.bat` / `START\START.ps1` | Glavni korisnički pokretač (klik): provjere okruženja, učitavanje `START\Config.ps1`, pokretanje GUI-ja `GUI\MainMenu.ps1`. |
| `START\install.ps1` | Pokreće se iz START foldera; traži admin privilegije i pokreće `main.ps1`. |
| `START\PinkSetup.ps1` | CLI meni iz START foldera (wallpaper, tema, programi, specifikacije, kompletna instalacija) uz dijeljene Core module/engine. |
| `main.ps1` | OS router: detektuje OS (`Get-WindowsVersion` iz `Core\Model.ps1`), loguje u `Logs\main.log`, pokreće `Windows10\install.ps1` ili `Windows11\install.ps1`. |
| `Windows10\install.ps1` | Admin elevacija, učitavanje `Core\Model.ps1`, `Core\Controller.ps1`, `Windows10\Config.ps1`, `Windows10\SystemTools\Get-SystemSpecs.ps1`, poziv `Run-Installation`. |
| `Windows11\install.ps1` | Isto za Windows 11 (koristi `Windows11\Config.ps1`, dijeli Win10 system tools gdje je potrebno). |
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
│   │   └── Programs.ps1          # dijeljeni instalacioni engine (Win10/Win11)
│   ├── Controller.ps1
│   ├── Installer.ps1
│   ├── InstallerConfig.ps1       # dijeljena podešavanja instalera (cooldown)
│   ├── InstallerHelpers.ps1
│   ├── Logging.ps1
│   ├── Model.ps1
│   ├── Paths.ps1
│   ├── ProgramDatabase.ps1       # wrapper -> DATABASE\ProgramDatabase.ps1
│   ├── ThemeEngine.ps1
│   └── ThemeManager.ps1
│
├── DATABASE/
│   ├── ProgramDatabase.ps1       # učitava definicije iz DATABASE\Installers
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
│   ├── Helpers/
│   ├── Models/
│   ├── Views/
│   └── OtherWindows/
│       ├── About.ps1
│       ├── AppsInstaller.ps1
│       ├── LoadInstallerBackend.ps1
│       ├── LogViewer.ps1
│       ├── ProfileInstaller.ps1
│       ├── ThemeManager.ps1
│       └── WallpaperManager.ps1
│
├── Windows10/
│   ├── Config.ps1
│   ├── install.ps1
│   ├── Config/
│   │   └── settings.json
│   ├── Installers/
│   │   └── Programs.ps1          # wrapper -> Core\Installers\Programs.ps1
│   ├── Modules/
│   │   └── Logging.psm1
│   ├── SystemTools/
│   │   ├── Get-SystemSpecs.ps1
│   │   └── PCInfo.ps1
│   ├── Themes/ (Blue/Green/Pink/Yellow)
│   └── Wallpapers/
│       └── Wallpaper.ps1
│
├── Windows11/
│   ├── Config.ps1
│   ├── install.ps1
│   └── Themes/ (Blue/Green/Pink/Yellow)
│
├── DATA/Photos/
├── Logs/
├── Koncepti/
├── Linux/install.ps1
└── MacOS/install.ps1
```

## Instalacioni engine i cooldown (shared)

- **`Core/Installers/Programs.ps1`** – dijeljeni engine koji koriste Windows 10 i Windows 11 (GUI i CLI tokovi). Sadrži: `Find-InstalledApp`, `Get-ProgramInstaller` (download preko `Invoke-WebRequest`, `-UseBasicParsing`, timeout, redirect/user-agent), `Test-Winget`, `Install-WithWinget`, `Install-OneApp`, `Install-YouTubeShortcut`, `Install-Programs`.
- **`Windows10\Installers\Programs.ps1`** – kompatibilnost/wrapper koji delegira na `Core\Installers\Programs.ps1`.
- **Sekvencijalna instalacija:** svaka instalacija se čeka do završetka (`winget` inline / `Start-Process -Wait -PassThru` za MSI/EXE) uz provjeru prisutnosti aplikacije u registru prije prelaska na sljedeću.
- **Cooldown između aplikacija (sporiji/brži računari):**
  - Podrazumijevano **5 sekundi** (`Core/InstallerConfig.ps1`, `$Global:InstallerSettings.InstallCooldownSeconds`).
  - `Core/InstallerHelpers.ps1`: `Get-InstallCooldownSeconds` (čita shared/konfig vrijednost, fallback 5, validacija) i `Invoke-InstallCooldown` (loguje trajanje i ime aplikacije, ispisuje odbrojavanje 5→0 u konzoli, `Start-Sleep` po sekundi; 0 preskače čekanje).
  - Poziva se centralizovano jednom po završenoj aplikaciji u `finally` bloku `Install-OneApp` (`Core/Installers/Programs.ps1`), nakon uspjeha/neuspjeha provjere – prije sljedeće aplikacije. Ne duplira se u GUI/CLI petljama niti u definicijama aplikacija.
- **Napredak:** CLI/GUI batch prikazuje progres (`X of Y`, `INSTALL PROGRESS: Index/Total`) preko `Install-OneApp -Index/-Total`.

## Core moduli i funkcije

| Fajl | Funkcije / varijable | Opis |
|------|-----------------------|------|
| `main.ps1` | `Write-Log` | OS router, pokretanje odgovarajućeg OS installera, log u `Logs\main.log`. |
| `Core\Model.ps1` | `Get-WindowsVersion`, `Get-OSConfig` | Detekcija Windows 10/11 (`BuildNumber >= 22000`) i učitavanje OS `Config.ps1`. |
| `Core\Controller.ps1` | `Get-SelectedApps`, `Show-MainMenu`, `Show-OSSpecs`, `Run-Installation` | CLI kontroler/meni (programi, tema, wallpaper, specifikacije). |
| `Core\Installer.ps1` | `Install-OneApp` | Router instalacije ka OS-specifičnom installeru (legacy/kompatibilnost). |
| `Core\InstallerConfig.ps1` | `$Global:InstallerSettings` | Dijeljena konfiguracija instalera (npr. `InstallCooldownSeconds`, default 5). |
| `Core\InstallerHelpers.ps1` | `Initialize-InstallerBackend`, `Find-InstalledApp`, `Test-Winget`, `Install-WithWinget`, `Get-ProgramInstaller`, `Write-InstallerLog`, `Get-InstallCooldownSeconds`, `Invoke-InstallCooldown`, `Install-YouTubeShortcut` | Pomoćne funkcije za backend, detekciju, winget/download/log i centralizovani cooldown. |
| `Core\Installers\Programs.ps1` | `Find-InstalledApp`, `Get-ProgramInstaller`, `Test-Winget`, `Install-WithWinget`, `Install-OneApp`, `Install-YouTubeShortcut`, `Install-Programs` | Dijeljeni instalacioni engine (MSI/EXE, winget, verifikacija, CLI meni, cooldown hook). |
| `Core\Logging.ps1` | `Write-AppLog` | Centralizovano logovanje (`Activity.log`, `Installation.log`, `Errors.log`). |
| `Core\Paths.ps1` | `Get-ProjectRoot`, `$Global:ProjectRoot`, `$Global:DataFolder`, `$Global:PhotosFolder`, `$Global:LogsFolder` | Pronalaženje root-a projekta i standardnih putanja. |
| `Core\ProgramDatabase.ps1` | (wrapper) | Učitava `DATABASE\ProgramDatabase.ps1`. |
| `Core\ThemeEngine.ps1` | `Set-ThemeDword`, `ConvertTo-WindowsColor`, `New-AccentPalette`, `Invoke-ThemeRefresh`, `Set-WindowsAccentTheme` | Primjena Windows accent/theme podešavanja (registry + refresh). |
| `Core\ThemeManager.ps1` | `Get-ThemeCatalog`, `Get-TargetThemeOS`, `Initialize-ThemeBackend`, `Get-ThemeDefinition`, `Invoke-Theme`, `Install-*Theme` | Katalog tema i dispatch primjene teme (OS-specifično ili Core fallback). |

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
| `GUI\OtherWindows\LoadInstallerBackend.ps1` | Učitava Core logging/database/helpers, dijeljeni `Core\Installers\Programs.ps1` i ThemeManager; postavlja `$Global:AutoMode = $true`. |
| `GUI\OtherWindows\AppsInstaller.ps1` | GUI izbor i instalacija aplikacija (checkbox lista, Select/Deselect All, profili, `Install-OneApp` sa progresom). |
| `GUI\OtherWindows\ProfileInstaller.ps1` | `Show-ProfileForm`; izbor profila (A/B/C) i pokretanje `AppsInstaller.ps1`. |
| `GUI\OtherWindows\ThemeManager.ps1` | Prikaz tema iz `Get-ThemeCatalog` i primjena preko `Invoke-Theme`. |
| `GUI\OtherWindows\WallpaperManager.ps1` | Prikaz/listanje JPG wallpaper-a iz `DATA\Photos`. |
| `GUI\OtherWindows\LogViewer.ps1` | `Load-Log`; prikaz `Logs\InstallationHistory.log`. |
| `GUI\OtherWindows\About.ps1` | About dijalog. |

## Windows 10 / Windows 11 moduli

| Fajl | Funkcije / varijable | Opis |
|------|-----------------------|------|
| `Windows10\Config.ps1` | `$Global:PinkRoot`, `$Global:PinkWork`, `$Global:PinkConfig`, `$Global:WindowsConfig`, `$Global:PinkEnvironment` | Konfiguracija za Win10 (putanje, okruženje; `EnableWidgets=$false`). |
| `Windows10\Config\settings.json` | podešavanja | OS-specifična podešavanja (npr. verzija). |
| `Windows10\install.ps1` | (entry) | Elevacija i pokretanje Core kontrolera za Win10. |
| `Windows10\Installers\Programs.ps1` | (wrapper) | Delegira na `Core\Installers\Programs.ps1`. |
| `Windows10\SystemTools\Get-SystemSpecs.ps1` | `Get-SystemSpecs`, `Test-IsWindows` | Prikupljanje i prikaz sistemskih specifikacija. |
| `Windows10\SystemTools\PCInfo.ps1` | (pomoćni/rezervni) | Dodatne sistemske informacije. |
| `Windows10\Themes\*.ps1` | `Invoke-*Theme`, `Install-*Theme` | OS-specifični theme wrapperi (delegacija ka Core theme backend-u). |
| `Windows10\Wallpapers\Wallpaper.ps1` | `WALLPAPERS` | Postavljanje wallpaper-a (`SystemParametersInfo`). |
| `Windows10\Modules\Logging.psm1` | `Write-Log` | Jednostavniji logging modul za Win10 skripte. |
| `Windows11\Config.ps1` | `$Global:PinkRoot`, `$Global:PinkWork`, `$Global:PinkConfig`, `$Global:WindowsConfig`, `$Global:PinkEnvironment` | Konfiguracija za Win11 (npr. `EnableWidgets=$true`). |
| `Windows11\install.ps1` | (entry) | Elevacija i pokretanje Core kontrolera za Win11. |
| `Windows11\Themes\*.ps1` | `Invoke-*Theme`, `Install-*Theme` | Win11 theme wrapperi (delegacija ka Core theme backend-u). |

## Meniji i tokovi

### START CLI (`START\PinkSetup.ps1`)
- `[1]` Choose Wallpaper
- `[2]` Choose Theme
- `[3]` Install Programs
- `[4]` OS Specifications
- `[5]` Complete Installation
- `[0]` Exit

### Core CLI (`Core\Controller.ps1` / `Run-Installation`)
- `[1]` Install Programs
- `[2]` Apply Theme
- `[3]` Set Wallpaper
- `[4]` OS Specifications
- `[0]` Exit

### GUI glavni meni
- Profile Installer, Apps Installer, Theme Manager, Wallpaper Manager, Log Viewer, About, Exit

### GUI profili
- **Profil A**: 2, 4, 6, 7 (Chrome, VLC, 7-Zip, Python)
- **Profil B**: 2, 4 (Chrome, VLC)
- **Profil C**: 6, 7 (7-Zip, Python)

## Podaci i logovi

- `DATA\Photos\`: wallpaper slike (`.jpg`).
- `Logs\`: runtime logovi (`main.log`, `Activity.log`, `Errors.log`, `Installation.log`, `InstallationHistory.log`, pojedinačni app logovi).
- `START\Logs\`: log folder za START tok.
- `Koncepti\`: tekstualni koncepti/dizajn (nije runtime kod).

## Napomene

- Zajedničke komponente: `Core/`, `DATABASE/`, `GUI/`, `START/`; OS-specifične: `Windows10/`, `Windows11/`. Instalacioni engine i cooldown su dijeljeni (Core) za Windows 10 i 11.
- `Linux/install.ps1` i `MacOS/install.ps1` su prisutni kao zasebni ulazi u strukturi repozitorija.
