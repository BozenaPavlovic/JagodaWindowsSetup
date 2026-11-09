# JagodaWindowsSetup

Skripta za automatsku instalaciju i postavljanje Windows okruženja (Strawberry Windows Setup).

## Struktura projekta

```text
JagodaWindowsSetup/
├── main.ps1
├── README.md
├── Core/
│   ├── Controller.ps1
│   ├── Installer.ps1
│   └── Model.ps1
├── GUI/
│   ├── About.ps1
│   ├── AppsExplorer.ps1
│   ├── AppsInstaller.ps1
│   ├── LogViewer.ps1
│   ├── MainMenu.ps1
│   ├── OSInfo.ps1
│   ├── ProfileInstaller.ps1
│   ├── ProgramInstaller.ps1
│   ├── Settings.ps1
│   ├── SystemTools.ps1
│   ├── ThemeManager.ps1
│   └── WallpaperManager.ps1
├── Koncepti/
│   ├── DrugiKoncept.txt
│   ├── PrviKoncept.txt
│   └── TrećiKoncept.txt
├── Linux/
│   └── install.ps1
├── Logs/
│   ├── Google_Chrome.log
│   └── InstallationHistory.log
├── MacOS/
│   └── install.ps1
├── Windows10/
│   ├── Config.ps1
│   ├── install.ps1
│   ├── PinkSetup.ps1
│   ├── START.bat
│   ├── START.ps1
│   ├── Config/
│   │   └── settings.json
│   ├── DATA/
│   │   ├── Photos/
│   │   │   ├── Pink-Strawberry.jpg
│   │   │   └── Yellow-Flowers-Blue-Sky.jpg
│   │   └── SystemSpecs/
│   ├── Functions/
│   ├── Installers/
│   │   └── Programs.ps1
│   ├── Logs/
│   ├── Modules/
│   │   └── Logging.psm1
│   ├── SystemTools/
│   │   ├── Get-SystemSpecs.ps1
│   │   └── PCInfo.ps1
│   ├── Themes/
│   │   └── PinkTheme.ps1
│   └── Wallpapers/
│       └── Wallpaper.ps1
└── Windows11/
    └── install.ps1
```