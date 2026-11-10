# Utilities
@(
    @{
        Number = "21"
        Name = "Wireshark"
        Category = "Utilities"
        Description = "Network Protocol Analyzer"
        Version = "4.6.9"
        Match = "Wireshark"
        File = "WiresharkSetup.exe"
        URL = "https://2.na.dl.wireshark.org/win64/Wireshark-4.6.9-x64.exe"
        Type = "EXE"
        InteractiveArguments = ""
        SilentArguments = "/S"
        MinBytes = 50000000
        Publisher = "The Wireshark developer community"
        WingetID = "WiresharkFoundation.Wireshark"
    },

    @{
        Number = "22"
        Name = "Microsoft PowerToys"
        Category = "Utilities"
        Description = "Windows Power User Utilities"
        Version = "0.102.3101.0"
        Match = "PowerToys"
        File = "PowerToysSetup.exe"
        URL = "https://github.com/microsoft/PowerToys/releases/download/v0.102.3/PowerToysUserSetup-0.102.3-x64.exe"
        Type = "EXE"
        InteractiveArguments = ""
        SilentArguments = "-silent"
        MinBytes = 100000000
        Publisher = "Microsoft Corporation"
        WingetID = "Microsoft.PowerToys"
    },

    @{
        Number = "23"
        Name = "AnyDesk"
        Category = "Utilities"
        Description = "Remote Desktop"
        Version = "9.8.2"
        Match = "AnyDesk"
        File = "AnyDesk.exe"
        URL = "https://download.anydesk.com/AnyDesk.exe"
        Type = "EXE"
        InteractiveArguments = ""
        SilentArguments = "--install `"C:\Program Files (x86)\AnyDesk`" --start-with-win --silent --create-shortcuts --create-desktop-icon"
        MinBytes = 3000000
        Publisher = "AnyDesk Software GmbH"
        WingetID = "AnyDesk.AnyDesk"
    },

    @{
        Number = "24"
        Name = "TeamViewer 15"
        Category = "Utilities"
        Description = "Remote Access Tool"
        Version = "15.83.5"
        Match = "TeamViewer"
        File = "TeamViewerSetup.exe"
        URL = "https://download.teamviewer.com/download/TeamViewer_Setup_x64.exe"
        Type = "EXE"
        InteractiveArguments = ""
        SilentArguments = "/S"
        MinBytes = 30000000
        Publisher = "TeamViewer Germany GmbH"
        WingetID = "TeamViewer.TeamViewer"
    },

    @{
        Number = "25"
        Name = "Windows App"
        Category = "Utilities"
        Description = "Remote Desktop, Windows 365 and Azure Virtual Desktop Client"
        Version = "2.0.1485"
        Match = "Windows App"
        File = "WindowsApp.msixbundle"
        URL = "https://go.microsoft.com/fwlink/?linkid=2262633"
        Type = "EXE"
        InteractiveArguments = ""
        SilentArguments = ""
        MinBytes = 10000000
        Publisher = "Microsoft Corporation"
        WingetID = "Microsoft.WindowsApp"
    },

    @{
        Number = "26"
        Name = "ImgBurn"
        Category = "Utilities"
        Description = "Disc Burner"
        Version = "2.5.8.0"
        Match = "ImgBurn"
        File = "ImgBurnSetup.exe"
        URL = "https://download.imgburn.com/SetupImgBurn_2.5.8.0.exe"
        Type = "EXE"
        InteractiveArguments = ""
        SilentArguments = "/S"
        MinBytes = 3000000
        Publisher = "LIGHTNING UK!"
        WingetID = "LIGHTNINGUK.ImgBurn"
    },

    @{
        Number = "27"
        Name = "TightVNC"
        Category = "Utilities"
        Description = "TightVNC Remote Desktop Software"
        Version = "2.8.90"
        Match = "TightVNC"
        File = "TightVNCSetup.msi"
        URL = "https://www.tightvnc.com/download/2.8.90/tightvnc-2.8.90-gpl-setup-64bit.msi"
        Type = "MSI"
        InteractiveArguments = ""
        SilentArguments = "/qn /norestart"
        MinBytes = 2000000
        Publisher = "GlavSoft LLC"
        WingetID = "GlavSoft.TightVNC"
    },

    @{
        Number = "28"
        Name = "UltraVNC"
        Category = "Utilities"
        Description = "VNC Remote Desktop Viewer and Server"
        Version = "1.8.3.2"
        Match = "UltraVNC"
        File = "UltraVNCSetup.exe"
        URL = "https://uvnc.eu/download/1832/UltraVNC_1_8_3_2_X64_Setup.exe"
        Type = "EXE"
        InteractiveArguments = ""
        SilentArguments = "/VERYSILENT /NORESTART"
        MinBytes = 4000000
        Publisher = "UltraVNC Team"
        WingetID = "uvncbvba.UltraVnc"
    },

    @{
        Number = "29"
        Name = "RustDesk"
        Category = "Utilities"
        Description = "Open-Source Remote Desktop"
        Version = "1.5.1"
        Match = "RustDesk"
        File = "RustDeskSetup.exe"
        URL = "https://github.com/rustdesk/rustdesk/releases/download/1.5.1/rustdesk-1.5.1-x86_64.exe"
        Type = "EXE"
        InteractiveArguments = ""
        SilentArguments = "--silent-install"
        MinBytes = 10000000
        Publisher = "RustDesk"
        WingetID = "RustDesk.RustDesk"
    },

    @{
        Number = "30"
        Name = "Tailscale"
        Category = "Utilities"
        Description = "Mesh VPN Built on WireGuard"
        Version = "1.104.5"
        Match = "Tailscale"
        File = "TailscaleSetup.msi"
        URL = "https://pkgs.tailscale.com/stable/tailscale-setup-1.104.5-amd64.msi"
        Type = "MSI"
        InteractiveArguments = ""
        SilentArguments = "/qn /norestart"
        MinBytes = 20000000
        Publisher = "Tailscale Inc."
        WingetID = "Tailscale.Tailscale"
    },

    @{
        Number = "31"
        Name = "WireGuard"
        Category = "Utilities"
        Description = "Fast, Modern, Secure VPN Tunnel"
        Version = "1.1.1"
        Match = "WireGuard"
        File = "WireGuardSetup.msi"
        URL = "https://download.wireguard.com/windows-client/wireguard-amd64-0.5.3.msi"
        Type = "MSI"
        InteractiveArguments = ""
        SilentArguments = "/qn /norestart"
        MinBytes = 2000000
        Publisher = "WireGuard LLC"
        WingetID = "WireGuard.WireGuard"
    },

    @{
        Number = "32"
        Name = "TeraCopy"
        Category = "Utilities"
        Description = "Better File Copy"
        Version = "4.0.5"
        Match = "TeraCopy"
        File = "TeraCopySetup.exe"
        URL = "https://www.codesector.com/files/teracopy.exe"
        Type = "EXE"
        InteractiveArguments = ""
        SilentArguments = "/VERYSILENT /NORESTART"
        MinBytes = 5000000
        Publisher = "Code Sector"
        WingetID = "CodeSector.TeraCopy"
    },

    @{
        Number = "33"
        Name = "CDBurnerXP"
        Category = "Utilities"
        Description = "Disc Burner"
        Version = "4.5.8.7128"
        Match = "CDBurnerXP"
        File = "CDBurnerXPSetup.msi"
        URL = "https://download.cdburnerxp.se/msi/cdbxp_setup_x64_4.5.8.7128.msi"
        Type = "MSI"
        InteractiveArguments = ""
        SilentArguments = "/qn /norestart"
        MinBytes = 5000000
        Publisher = "Canneverbe Limited"
        WingetID = "Canneverbe.CDBurnerXP"
    },

    @{
        Number = "34"
        Name = "Revo Uninstaller"
        Category = "Utilities"
        Description = "App Uninstaller/Reverse Ninite"
        Version = "2.7.2"
        Match = "Revo Uninstaller"
        File = "RevoUninstallerSetup.exe"
        URL = "https://download.revouninstaller.com/download/revosetup.exe"
        Type = "EXE"
        InteractiveArguments = ""
        SilentArguments = "/VERYSILENT /NORESTART"
        MinBytes = 7000000
        Publisher = "VS Revo Group"
        WingetID = "RevoUninstaller.RevoUninstaller"
    },

    @{
        Number = "35"
        Name = "Launchy"
        Category = "Utilities"
        Description = "Hotkey Launcher"
        Version = "2.5"
        Match = "Launchy"
        File = "LaunchySetup.exe"
        URL = "https://www.launchy.net/downloads/win/Launchy2.5.exe"
        Type = "EXE"
        InteractiveArguments = ""
        SilentArguments = "/VERYSILENT /NORESTART"
        MinBytes = 3000000
        Publisher = "Launchy"
        WingetID = "OpenJS.Launchy"
    },

    @{
        Number = "36"
        Name = "WinDirStat"
        Category = "Utilities"
        Description = "Directory Statistics"
        Version = "2.9.3.2253"
        Match = "WinDirStat"
        File = "WinDirStatSetup.exe"
        URL = "https://github.com/windirstat/windirstat/releases/download/release%2F2.9.3/WinDirStat-x64.msi"
        Type = "MSI"
        InteractiveArguments = ""
        SilentArguments = "/qn /norestart"
        MinBytes = 2000000
        Publisher = "WinDirStat Team"
        WingetID = "WinDirStat.WinDirStat"
    },

    @{
        Number = "37"
        Name = "WizTree"
        Category = "Utilities"
        Description = "Directory Statistics"
        Version = "4.33"
        Match = "WizTree"
        File = "WizTreeSetup.exe"
        URL = "https://wiztreefree.com/files/wiztree_4_33_setup.exe"
        Type = "EXE"
        InteractiveArguments = ""
        SilentArguments = "/VERYSILENT /NORESTART"
        MinBytes = 3000000
        Publisher = "Antibody Software"
        WingetID = "AntibodySoftware.WizTree"
    },

    @{
        Number = "38"
        Name = "Advanced IP Scanner"
        Category = "Utilities"
        Description = "Network Scanner"
        Version = "2.5.4594.1"
        Match = "Advanced IP Scanner"
        File = "AdvancedIPScannerSetup.exe"
        URL = "https://download.advanced-ip-scanner.com/download/files/Advanced_IP_Scanner_2.5.4594.1.exe"
        Type = "EXE"
        InteractiveArguments = ""
        SilentArguments = "/VERYSILENT /NORESTART"
        MinBytes = 10000000
        Publisher = "Famatech"
        WingetID = "Famatech.AdvancedIPScanner"
    },

    @{
        Number = "39"
        Name = "Glary Utilities"
        Category = "Utilities"
        Description = "System Utilities"
        Version = "6.50.0.54"
        Match = "Glary Utilities"
        File = "GlaryUtilitiesSetup.exe"
        URL = "https://download.glarysoft.com/gu5setup.exe"
        Type = "EXE"
        InteractiveArguments = ""
        SilentArguments = "/S"
        MinBytes = 10000000
        Publisher = "Glarysoft Ltd"
        WingetID = "Glarysoft.GlaryUtilities"
    },

    @{
        Number = "40"
        Name = "InfraRecorder"
        Category = "Utilities"
        Description = "Disc Burner"
        Version = "0.53.0"
        Match = "InfraRecorder"
        File = "InfraRecorderSetup.msi"
        URL = "https://sourceforge.net/projects/infrarecorder/files/InfraRecorder/0.53/ir053_x64.msi/download"
        Type = "MSI"
        InteractiveArguments = ""
        SilentArguments = "/qn /norestart"
        MinBytes = 3000000
        Publisher = "Christian Kindahl"
        WingetID = "ChristianKindahl.InfraRecorder"
    },

    @{
        Number = "41"
        Name = "Open-Shell"
        Category = "Utilities"
        Description = "Old-Style Start Menu"
        Version = "4.4.198"
        Match = "Open-Shell"
        File = "OpenShellSetup.exe"
        URL = "https://github.com/Open-Shell/Open-Shell-Menu/releases/download/v4.4.198/OpenShellSetup_4_4_198.exe"
        Type = "EXE"
        InteractiveArguments = ""
        SilentArguments = "/qn ADDLOCAL=StartMenu"
        MinBytes = 5000000
        Publisher = "Open-Shell"
        WingetID = "Open-Shell.Open-Shell-Menu"
    },

    @{
        Number = "42"
        Name = "CCleaner"
        Category = "Utilities"
        Description = "PC Crap Remover"
        Version = "6.41.11567"
        Match = "CCleaner"
        File = "CCleanerSetup.exe"
        URL = "https://bits.avcdn.net/productfamily_CCLEANER/insttype_FREE/platform_WIN_PIR/installertype_ONLINE/build_RELEASE"
        Type = "EXE"
        InteractiveArguments = ""
        SilentArguments = "/S"
        MinBytes = 30000000
        Publisher = "Piriform Ltd"
        WingetID = "Piriform.CCleaner"
    }
)
