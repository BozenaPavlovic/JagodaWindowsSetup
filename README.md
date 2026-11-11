# JagodaWindowsSetup

PowerShell skripta/projekt za automatsku instalaciju programa i postavljanje Windows okruženja (Strawberry / Jagoda Windows Setup).

Najbitnije:
- **Struktura foldera** je ispod prikazana prema stvarnom stanju repozitorija.
- **Funkcije i ključne komponente** su navedene po fajlovima/modulima.

## Ulazne tačke

| Fajl | Namjena |
|------|---------|
| `main.ps1` | Glavni router: detektuje OS (`Get-WindowsVersion`), loguje u `Logs\main.log`, pokreće `Windows10\install.ps1` ili `Windows11\install.ps1`. |
| `Windows10\install.ps1` | Provjera administratorskih prava, učitavanje Core/Config/SystemTools modula, pokretanje `Run-Installation`. |
| `Windows11\install.ps1` | Isto kao Win10 varijanta (koristi Win11 config). |
| `Windows10\START.ps1` / `Windows10\START.bat` | Portable pokretač za GUI (`GUI\MainMenu.ps1`). |
| `Windows10\PinkSetup.ps1` | CLI meni za Windows 10 (wallpaper, tema, programi, specifikacije, kompletna instalacija). |
| `GUI\MainMenu.ps1` | WinForms GUI ulazna tačka (MVC: Model/View/Controller). |

## Struktura foldera

```text
JagodaWindowsSetup/
├── main.ps1
├── README.md
│
├── Core/
│   ├── Controller.ps1
│   ├── Installer.ps1
│   ├── InstallerHelpers.ps1
│   ├── Logging.ps1
│   ├── Model.ps1
│   ├── Paths.ps1
│   ├── ProgramDatabase.ps1          # compatibility wrapper -> DATABASE\ProgramDatabase.ps1
│   ├── ThemeEngine.ps1
│   └── ThemeManager.ps1
│
├── DATABASE/
│   ├── ProgramDatabase.ps1          # učitava sve definicije iz DATABASE\Installers
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
│   │   └── MainMenuController.ps1
│   ├── Helpers/
│   │   └── SystemInformationFormatter.ps1
│   ├── Models/
│   │   └── MainMenuModel.ps1
│   ├── Views/
│   │   ├── MainMenuPanel.ps1
│   │   ├── MainMenuView.ps1
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
├── Windows10/
│   ├── Config.ps1
│   ├── install.ps1
│   ├── PinkSetup.ps1
│   ├── START.bat
│   ├── START.ps1
│   ├── Config/
│   │   └── settings.json
│   ├── Installers/
│   │   └── Programs.ps1
│   ├── Modules/
│   │   └── Logging.psm1
│   ├── SystemTools/
│   │   ├── Get-SystemSpecs.ps1
│   │   └── PCInfo.ps1
│   ├── Themes/
│   │   ├── BlueTheme.ps1
│   │   ├── GreenTheme.ps1
│   │   ├── PinkTheme.ps1
│   │   └── YellowTheme.ps1
│   └── Wallpapers/
│       └── Wallpaper.ps1
│
├── Windows11/
│   ├── Config.ps1
│   ├── install.ps1
│   └── Themes/
│       ├── BlueTheme.ps1
│       ├── GreenTheme.ps1
│       ├── PinkTheme.ps1
│       └── YellowTheme.ps1
│
├── Linux/
│   └── install.ps1
│
├── MacOS/
│   └── install.ps1
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

## Core moduli i funkcije

| Fajl | Funkcije / varijable | Opis |
|------|-----------------------|------|
| `main.ps1` | `Write-Log` | OS router, pokretanje odgovarajućeg OS installera, logovanje u `Logs\main.log`. |
| `Core\Model.ps1` | `Get-WindowsVersion`, `Get-OSConfig` | Detekcija Windows 10/11 (`BuildNumber >= 22000`) i učitavanje OS `Config.ps1`. |
| `Core\Controller.ps1` | `Get-SelectedApps`, `Show-MainMenu`, `Show-OSSpecs`, `Run-Installation` | CLI kontroler/meni (instalacija programa, tema, wallpaper, specifikacije). |
| `Core\Installer.ps1` | `Install-OneApp` | Router instalacije ka OS-specifičnom installeru. |
| `Core\InstallerHelpers.ps1` | `Initialize-InstallerBackend`, `Find-InstalledApp`, `Test-Winget`, `Install-WithWinget`, `Get-ProgramInstaller`, `Write-InstallerLog`, `Install-YouTubeShortcut` | Pomoćne funkcije za instalaciju, provjeru postojećih app-a, winget, download i logovanje instalacija. |
| `Core\Logging.ps1` | `Write-AppLog` | Centralizovano logovanje (`Activity.log`, `Installation.log`, `Errors.log`). |
| `Core\Paths.ps1` | `Get-ProjectRoot`, `$Global:ProjectRoot`, `$Global:DataFolder`, `$Global:PhotosFolder`, `$Global:LogsFolder` | Pouzdano pronalaženje root-a projekta i standardnih putanja. |
| `Core\ProgramDatabase.ps1` | (wrapper) | Učitava `DATABASE\ProgramDatabase.ps1`. |
| `Core\ThemeEngine.ps1` | `Set-ThemeDword`, `ConvertTo-WindowsColor`, `New-AccentPalette`, `Invoke-ThemeRefresh`, `Set-WindowsAccentTheme` | Niskonivonska primjena Windows accent/theme podešavanja (registry + refresh). |
| `Core\ThemeManager.ps1` | `Get-ThemeCatalog`, `Get-TargetThemeOS`, `Initialize-ThemeBackend`, `Get-ThemeDefinition`, `Invoke-Theme`, `Install-PinkTheme`, `Install-BlueTheme`, `Install-YellowTheme`, `Install-GreenTheme` | Katalog tema i dispatch primjene teme (OS-specifično ili fallback na Core engine). |

## Baza programa (`DATABASE`)

- `DATABASE\ProgramDatabase.ps1`: učitava sve `.ps1` definicije iz `DATABASE\Installers\` i puni `$Global:Apps`.
- `Core\ProgramDatabase.ps1`: kompatibilnost/wrapper koji poziva `DATABASE\ProgramDatabase.ps1`.
- Kategorije instalera u `DATABASE\Installers\`:
  - `Compression.ps1`
  - `Development.ps1`
  - `Media.ps1`
  - `Messaging.ps1`
  - `Office.ps1`
  - `Utilities.ps1`
  - `WebBrowsers.ps1`

## GUI (WinForms, MVC stil)

| Fajl | Funkcije / uloga |
|------|------------------|
| `GUI\MainMenu.ps1` | Ulazna tačka GUI-ja: učitava model/view/controller, priprema i prikazuje formu. |
| `GUI\Models\MainMenuModel.ps1` | `Get-SystemInformation` (OS, verzija, build, CPU, GPU, RAM, disk, uptime, admin status itd.). |
| `GUI\Helpers\SystemInformationFormatter.ps1` | `Format-SystemInformation` (formatira podatke za prikaz). |
| `GUI\Views\MainMenuView.ps1` | Kreira glavnu formu i dodaje panele. |
| `GUI\Views\MainMenuPanel.ps1` | Glavni meni dugmad: Profile Installer, Apps Installer, Theme Manager, Wallpaper Manager, Log Viewer, About, Exit. |
| `GUI\Views\SystemInformationPanel.ps1` | Panel za prikaz sistemskih informacija. |
| `GUI\Controllers\MainMenuController.ps1` | `Initialize-MainMenuController` (mapiranje klikova na skripte u `GUI\OtherWindows`, zatvaranje aplikacije). |
| `GUI\OtherWindows\LoadInstallerBackend.ps1` | Učitava Core logging/database/helpers, Win10 installer i ThemeManager; inicijalizuje backend (`$Global:AutoMode = $true`). |
| `GUI\OtherWindows\AppsInstaller.ps1` | GUI izbor i instalacija aplikacija (checkbox lista, Select/Deselect All, profili, poziv `Install-OneApp`). |
| `GUI\OtherWindows\ProfileInstaller.ps1` | `Show-ProfileForm`; izbor profila (A/B/C) i pokretanje `AppsInstaller.ps1` sa profilom. |
| `GUI\OtherWindows\ThemeManager.ps1` | Dinamički prikaz tema iz `Get-ThemeCatalog` i primjena preko `Invoke-Theme`. |
| `GUI\OtherWindows\WallpaperManager.ps1` | Prikaz/listanje JPG wallpaper-a iz `DATA\Photos`. |
| `GUI\OtherWindows\LogViewer.ps1` | `Load-Log`; prikaz `Logs\InstallationHistory.log`. |
| `GUI\OtherWindows\About.ps1` | About dijalog. |

## Windows 10 / Windows 11 moduli

| Fajl | Funkcije / varijable | Opis |
|------|-----------------------|------|
| `Windows10\Config.ps1` | `$Global:PinkRoot`, `$Global:PinkWork`, `$Global:PinkConfig`, `$Global:WindowsConfig`, `$Global:PinkEnvironment` | Konfiguracija za Win10 (tema, putanje, okruženje; `EnableWidgets=$false`). |
| `Windows10\PinkSetup.ps1` | `Get-OSSpecs` + CLI meni | Interaktivni CLI tok za wallpaper/temu/programe/specifikacije/kompletnu instalaciju. |
| `Windows10\Installers\Programs.ps1` | `Find-InstalledApp`, `Get-ProgramInstaller`, `Test-Winget`, `Install-WithWinget`, `Install-OneApp`, `Install-YouTubeShortcut`, `Install-Programs` (+ `$Global:OSVersion`, `$Global:AutoMode`) | Win10 instalaciona logika (MSI/EXE, winget, verifikacija, meni/profili). |
| `Windows10\SystemTools\Get-SystemSpecs.ps1` | `Get-SystemSpecs`, `Test-IsWindows` | Prikupljanje i prikaz sistemskih specifikacija. |
| `Windows10\SystemTools\PCInfo.ps1` | (pomoćni/rezervni fajl) | Dodatne sistemske informacije (trenutno minimalno/placeholder). |
| `Windows10\Themes\*.ps1` | `Invoke-BlueTheme`, `Install-BlueTheme`, `Invoke-GreenTheme`, `Install-GreenTheme`, `Invoke-PinkTheme`, `Install-PinkTheme`, `Invoke-YellowTheme`, `Install-YellowTheme` | OS-specifični theme wrapperi (delegacija ka Core theme backend-u). |
| `Windows10\Wallpapers\Wallpaper.ps1` | `WALLPAPERS` | Postavljanje wallpaper-a preko `SystemParametersInfo`. |
| `Windows10\Modules\Logging.psm1` | `Write-Log` | Jednostavniji logging modul za Win10 skripte. |
| `Windows11\Config.ps1` | `$Global:PinkRoot`, `$Global:PinkWork`, `$Global:PinkConfig`, `$Global:WindowsConfig`, `$Global:PinkEnvironment` | Konfiguracija za Win11 (`EnableWidgets=$true`, `EnableDarkMode=$true` itd.). |
| `Windows11\Themes\*.ps1` | `Invoke-*Theme`, `Install-*Theme` (Blue/Green/Pink/Yellow) | Win11 theme wrapperi (delegacija ka Core theme backend-u). |

## Meniji i tokovi

### CLI (Windows 10 - `Windows10\PinkSetup.ps1`)
- `[1]` Choose Wallpaper
- `[2]` Choose Theme
- `[3]` Install Programs
- `[4]` OS Specifications
- `[5]` Complete Installation
- `[0]` Exit

### CLI (Core controller - `Core\Controller.ps1`)
- `[1]` Install Programs
- `[2]` Apply Theme
- `[3]` Set Wallpaper
- `[4]` OS Specifications
- `[0]` Exit

### GUI glavni meni
- Profile Installer
- Apps Installer
- Theme Manager
- Wallpaper Manager
- Log Viewer
- About
- Exit

### GUI profili (`GUI\OtherWindows\ProfileInstaller.ps1` / `AppsInstaller.ps1`)
- **Profil A**: 2, 4, 6, 7 (Chrome, VLC, 7-Zip, Python)
- **Profil B**: 2, 4 (Chrome, VLC)
- **Profil C**: 6, 7 (7-Zip, Python)

## Podaci i logovi

- `DATA\Photos\`: wallpaper slike (`.jpg`) koje koristi GUI/skripte.
- `Logs\`: runtime log fajlovi (`main.log` iz `main.ps1`, te `Activity.log`, `Errors.log`, `Installation.log`, `InstallationHistory.log`, pojedinačni app logovi).
- `Koncepti\`: tekstualni koncepti/dizajn ideje (nije runtime kod).

## Napomene

- Projekat sadrži i zajedničke (Core/DATABASE/GUI) i OS-specifične (`Windows10`, `Windows11`) komponente.
- `Linux/install.ps1` i `MacOS/install.ps1` su prisutni kao zasebni ulazi/folderi u strukturi repozitorija.
- README je fokusiran na tačnu strukturu foldera i pregled funkcionalnosti/funkcija u kodu.
