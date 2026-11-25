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
│   │   ├── 01_Configuration.ps1   # učitava OS Config, postavlja DownloadFolder/LogFolder, TLS, InstallerSettings (InstallCooldownSeconds)
│   │   ├── 02_UiHelpers.ps1       # Invoke-UiRefresh, Wait-ProcessWithUiRefresh
│   │   ├── 03_AppDetection.ps1    # Find-InstalledApp (registry + AppX)
│   │   ├── 04_Download.ps1        # Get-ProgramInstaller (WebClient, .partial, MinBytes)
│   │   ├── 05_Winget.ps1          # Test-Winget, Install-WithWinget (sync, 15 min timeout)
│   │   ├── 06_InstallApplication.ps1  # Install-OneApp, Install-Programs
│   │   └── Programs.ps1           # agregira 01–06 (dijeljeni instalacioni engine)
│   ├── SystemTools/
│   │   └── Get-SystemSpecs.ps1    # Get-SystemSpecs, Test-IsWindows
│   ├── Wallpapers/
│   │   └── Wallpaper.ps1          # WALLPAPERS (SystemParametersInfo)
│   ├── Uninstallers/
│   │   ├── 01_Configuration.ps1   # Uninstaller config (timeout settings)
│   │   ├── 02_RegistryDetection.ps1  # Get-InstalledPrograms (registar Uninstall HKLM/HKCU 64/32-bit)
│   │   ├── 03_AppXDetection.ps1   # Get-AppxPackages (AppX package detection)
│   │   ├── 04_UninstallCommandResolver.ps1  # Find-UninstallCommand (MSI/AppX/EXE/winget)
│   │   ├── 05_UninstallExecution.ps1  # Execute-UninstallCommand (silent, timeout)
│   │   ├── 06_UninstallVerification.ps1  # Verify-MsiUninstall, Verify-AppxUninstall, Verify-Uninstall
│   │   ├── 07_UninstallLogging.ps1    # Write-UninstallLog
│   │   └── Uninstaller.ps1        # agregira 01–07 (dijeljeni uninstaller engine)
│   ├── Controller.ps1             # Get-SelectedApps, Show-MainMenu, Show-OSSpecs, Run-Installation
│   ├── Installer.ps1              # kompatibilni shim -> Core\Installers\Programs.ps1
│   ├── InstallerHelpers.ps1       # Get-InstallCooldownSeconds, Invoke-InstallCooldown
│   ├── Logging.ps1                # Write-AppLog (Activity.log, Installation.log, Errors.log)
│   ├── Model.ps1                  # Get-WindowsVersion, Get-OSConfig
│   ├── Paths.ps1                  # Get-ProjectRoot, $Global:ProjectRoot/DataFolder/PhotosFolder/LogsFolder
│   ├── ProgramDatabase.ps1        # wrapper -> DATABASE\ProgramDatabase.ps1
│   ├── ThemeEngine.ps1            # Set-ThemeDword, ConvertTo-WindowsColor, New-AccentPalette, Invoke-ThemeRefresh, Set-WindowsAccentTheme
│   ├── ThemeManager.ps1           # Get-ThemeCatalog, Get-TargetThemeOS, Initialize-ThemeBackend, Get-ThemeDefinition, Invoke-Theme, Install-*-Theme aliasi
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
│       ├── AppsInstaller.ps1       # dual-mode: Install / Uninstall
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
├── Logs/                          # main.log, Activity.log, Errors.log, Installation.log,
│                                  # InstallationHistory.log, Uninstall.log (+ ManagedPrograms.json)
├── START\Logs/
├── Koncepti/                      # konceptne datoteke (Prvi/Drugi/Treći/Četvrti Koncept.txt)
├── Linux/install.ps1              # prazan placeholder
└── MacOS/install.ps1              # prazan placeholder
```

## Instalacioni engine i cooldown (shared)

- **`Core\Installers\Programs.ps1`** – jedini ulaz za učitavanje dijeljenog instalacionog engine-a. Validira da postoje svi moduli, učitava `Core\InstallerHelpers.ps1` (cooldown) i zatim dot-source-ira šest modula u redoslijedu: `01_Configuration.ps1` (OS config, `DownloadFolder`/`LogFolder`, TLS), `02_UiHelpers.ps1` (`Invoke-UiRefresh`, `Wait-ProcessWithUiRefresh`), `03_AppDetection.ps1` (`Find-InstalledApp`), `04_Download.ps1` (`Get-ProgramInstaller`), `05_Winget.ps1` (`Test-Winget`, `Install-WithWinget`), `06_InstallApplication.ps1` (`Install-OneApp`, `Install-Programs`). Moduli se učitavaju samo jednom; funkcije se ne izvršavaju pri učitavanju.
- **Download (`04_Download.ps1`):** `System.Net.WebClient` sa Chrome User-Agent-om, 10-minutni timeout, privremeni `.partial` fajl i provjera `MinBytes` prije premještanja.
- **Winget (`05_Winget.ps1`):** sinhronizovano (`--silent --exact --accept-package-agreements --accept-source-agreements --disable-interactivity`), 15-minutni timeout, log `<App>_Winget.log`. Koristi se samo na **Windows 10** putanji (`$Global:OSVersion -ne "Windows11"`) i kada je winget dostupan; pri neuspjehu pada na klasični installer.
- **Klasična instalacija (`06_InstallApplication.ps1`):** `Start-Process -PassThru` + `Wait-ProcessWithUiRefresh` (5-minutni timeout) za MSI (`msiexec`) i EXE; prihvaćeni exit kodovi `0/1641/3010/1/2/3`, zatim verifikacija u registru/AppX (`Find-InstalledApp`).
- **Sekvencijalna instalacija:** svaka instalacija se čeka do završetka uz provjeru prisutnosti aplikacije prije prelaska na sljedeću.
- **Cooldown između aplikacija:** podrazumijevano **5 sekundi** (`Core\Installers\01_Configuration.ps1`, `$Global:InstallerSettings.InstallCooldownSeconds = 5`). `Core\InstallerHelpers.ps1`: `Get-InstallCooldownSeconds` i `Invoke-InstallCooldown` (log, odbrojavanje, `Start-Sleep`; 0 preskače čekanje). Poziva se u `finally` bloku `Install-OneApp` (`Core\Installers\06_InstallApplication.ps1`).
- **Napredak:** CLI/GUI batch prikazuje progres (`Progress: X of Y`, `INSTALL PROGRESS: Index/Total`).

## Deinstalacija (Uninstaller)

- **`Core\Uninstallers\Uninstaller.ps1`** – agregira module 01–07 (dijeljeni uninstaller engine):
  - `01_Configuration.ps1`: Uninstaller config (timeout settings, AppX/MSI/EXE/Winget enable flags)
  - `02_RegistryDetection.ps1`: `Get-InstalledProgramsFromRegistry`, `Get-AllInstalledProgramsFromRegistry` (registar Uninstall HKLM/HKCU 64/32-bit)
  - `03_AppXDetection.ps1`: `Get-AllInstalledProgramsFromAppx`, `Get-InstalledProgramsFromAppx`, `Find-InstalledAppByAppx` (AppX package detection)
  - `04_UninstallCommandResolver.ps1`: `Resolve-UninstallCommand`, `Find-InstalledProgramFromDbApp` (MSI/AppX/EXE/Winget command resolution)
  - `05_UninstallExecution.ps1`: `Execute-UninstallCommand` (silent execution, timeout handling)
  - `06_UninstallVerification.ps1`: `Verify-MsiUninstall`, `Verify-AppxUninstall`, `Verify-Uninstall` (post-uninstall verification)
  - `07_UninstallLogging.ps1`: `Write-UninstallLog`, `Get-UninstallStorePath`, `Read-ManagedStore`, `Write-ManagedStore`, `Register-ManagedProgram`, `Unregister-ManagedProgram`, `Get-ManagedPrograms`, `Get-InstalledPrograms` (logging + managed store)
- **Detekcija:** `Get-InstalledPrograms` čita registar `Uninstall` (HKLM/HKCU, 64/32-bit) i AppX pakete.
- **Komanda:** `Find-UninstallCommand` bira `msiexec /x {GUID} /qn` za MSI, `Remove-AppxPackage` za AppX, ili `UninstallString`/`QuietUninstallString` za ostale.
- **Izvršavanje:** `Uninstall-OneApp` (u `Uninstaller.ps1`) pokreće deinstalaciju (opciono silent), čeka (10-minutni timeout), verifikuje uklanjanje, piše u `Logs\Uninstall.log` i uklanja unos iz managed stora. `Uninstall-MultipleApps` radi istu stvar po aplikaciji sa progresom.
- **Managed store:** `Logs\ManagedPrograms.json` (preko `Get-UninstallStorePath` iz `07_UninstallLogging.ps1`).
- **Pristup:** kroz GUI **Apps Installer** u **Uninstall** modu (dugme "Switch to Uninstall Mode") ili direktno pozivom funkcija iz `Core\Uninstallers\Uninstaller.ps1`.

## Core moduli i funkcije

| Fajl | Funkcije / varijable | Opis |
|------|-----------------------|------|
| `main.ps1` | `Write-Log` | OS router; detekcija OS-a, log u `Logs\main.log`, pokretanje `Windows10\install.ps1` ili `Windows11\install.ps1`. |
| `Core\Model.ps1` | `Get-WindowsVersion`, `Get-OSConfig` | Detekcija OS-a (build >= 22000 → Windows11) i učitavanje odgovarajućeg `Windows10/Windows11\Config.ps1`. |
| `Core\Controller.ps1` | `Get-SelectedApps`, `Show-MainMenu`, `Show-OSSpecs`, `Run-Installation` | CLI kontroler/meni (programi, tema, wallpaper, specifikacije). |
| `Core\Installer.ps1` | (shim) | Kompatibilni ulaz koji učitava `Core\Installers\Programs.ps1` (nije korišten u aktivnim tokovima). |
| `Core\InstallerHelpers.ps1` | `Get-InstallCooldownSeconds`, `Invoke-InstallCooldown` | Cooldown između instalacija (log, odbrojavanje, `Start-Sleep`; 0 preskače čekanje). Učitava ga `Core\Installers\Programs.ps1` i GUI backend. |
| `Core\Installers\01_Configuration.ps1` | `$Global:OSVersion`, `$Global:PinkConfig`, `$Global:DownloadFolder`, `$Global:LogFolder`, `$Global:InstallerSettings` | OS detekcija, učitavanje OS config-a, folderi, TLS, InstallerSettings (InstallCooldownSeconds = 5). |
| `Core\Installers\02_UiHelpers.ps1` | `Invoke-UiRefresh`, `Wait-ProcessWithUiRefresh` | Održavanje WinForms responzivnosti tokom čekanja. |
| `Core\Installers\03_AppDetection.ps1` | `Find-InstalledApp` | Detekcija instaliranih aplikacija (registry Uninstall + AppX). |
| `Core\Installers\04_Download.ps1` | `Get-ProgramInstaller` | Download i validacija instalera (WebClient, `.partial`, MinBytes). |
| `Core\Installers\05_Winget.ps1` | `Test-Winget`, `Install-WithWinget` | Winget detekcija i sinhrona instalacija (15 min timeout). |
| `Core\Installers\06_InstallApplication.ps1` | `Install-OneApp`, `Install-Programs` | MSI/EXE/winget tok instalacije + verifikacija + cooldown. |
| `Core\Installers\Programs.ps1` | (loader) | Učitava module 01–06 i `Core\InstallerHelpers.ps1`; nema vlastitih funkcija. |
| `Core\Logging.ps1` | `Write-AppLog` | Centralizovano logovanje (`Activity.log`, `Installation.log`, `Errors.log`). |
| `Core\Paths.ps1` | `Get-ProjectRoot`, `$Global:ProjectRoot`, `$Global:DataFolder`, `$Global:PhotosFolder`, `$Global:LogsFolder` | Pronalaženje root-a projekta i standardnih putanja. |
| `Core\ProgramDatabase.ps1` | (wrapper) | Učitava `DATABASE\ProgramDatabase.ps1`. |
| `Core\ThemeEngine.ps1` | `Set-ThemeDword`, `ConvertTo-WindowsColor`, `New-AccentPalette`, `Invoke-ThemeRefresh`, `Set-WindowsAccentTheme` | Primjena Windows accent/theme podešavanja. |
| `Core\ThemeManager.ps1` | `Get-ThemeCatalog`, `Get-TargetThemeOS`, `Initialize-ThemeBackend`, `Get-ThemeDefinition`, `Invoke-Theme`, `Install-PinkTheme`, `Install-BlueTheme`, `Install-YellowTheme`, `Install-GreenTheme` | Katalog tema i dispatch primjene teme. |
| `Core\Uninstallers\Uninstaller.ps1` | (loader) | Učitava module 01–07 (dijeljeni uninstaller engine); funkcije: `Get-UninstallStorePath`, `Read-ManagedStore`, `Write-ManagedStore`, `Register-ManagedProgram`, `Unregister-ManagedProgram`, `Get-InstalledPrograms`, `Get-ManagedPrograms`, `Find-UninstallCommand`, `Write-UninstallLog`, `Uninstall-OneApp`, `Uninstall-MultipleApps` | Deinstalacija (registry + AppX) i managed store (`Logs\ManagedPrograms.json`, `Logs\Uninstall.log`). |
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
| `GUI\OtherWindows\AppsInstaller.ps1` | Dual-mode GUI (`-Mode Install|Uninstall` + dugme za prebacivanje moda). Učitava `Core\Uninstallers\Uninstaller.ps1`; prikazuje/aplikira aplikacije (checkbox lista, Select/Deselect All, profili). Install: `Install-OneApp` sa progresom. Uninstall: `Uninstall-MultipleApps -Silent` nad instaliranim aplikacijama iz baze. |
| `GUI\OtherWindows\ProfileInstaller.ps1` | Installation Manager – custom profili (Create/Edit/Delete/Install) uz `ProfileModel`/`ProfileController`. |
| `GUI\Models\ProfileModel.ps1` | JSON persistencija custom profila (`DATA\Profiles\CustomProfiles.json`). |
| `GUI\Controllers\ProfileController.ps1` | CRUD operacije i validacija profila. |
| `GUI\OtherWindows\ThemeManager.ps1` | Prikaz tema iz `Get-ThemeCatalog` i primjena preko `Invoke-Theme`. |
| `GUI\OtherWindows\WallpaperManager.ps1` | Prikaz/listanje JPG wallpaper-a iz `DATA\Photos`. |
| `GUI\OtherWindows\LogViewer.ps1` | `Load-Log`; combobox izbor log fajla (`InstallationHistory.log` podrazumijevano, uz `Activity.log`, `Errors.log`, `Installation.log`, `Google_Chrome.log`). |
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
- `Logs\`: runtime logovi (`main.log`, `Activity.log`, `Errors.log`, `Installation.log`, `InstallationHistory.log`, `Uninstall.log`) i managed store (`ManagedPrograms.json`, po potrebi). Pojedinačni instalacijski logovi (npr. `Google_Chrome.log`) nastaju po aplikaciji.
- `START\Logs\`: log folder za START tok.

## Napomene

- Zajedničke komponente: `Core/`, `DATABASE/`, `GUI/`, `START/`; Windows-specific: `Windows10/` i `Windows11/` (config, entry, theme wrapperi). Instalacioni engine (moduli 01–06), cooldown, uninstaller, wallpaper i system-spec helper su dijeljeni u `Core/`.
- `Core\Installer.ps1` je kompatibilni shim koji učitava `Core\Installers\Programs.ps1`; aktivni tokovi (GUI backend, `PinkSetup.ps1`) učitavaju `Programs.ps1` direktno.
- Deinstalacija je dostupna kroz GUI **Apps Installer** (Uninstall mod) i funkcije `Core\Uninstallers\Uninstaller.ps1`.
- `Linux\install.ps1` i `MacOS\install.ps1` su prazni placeholderi.
- `START\PinkSetup.ps1` opcija 5 ("Complete Installation") poziva `GUI\ProgramInstaller.ps1`, koji nije prisutan u projektu.