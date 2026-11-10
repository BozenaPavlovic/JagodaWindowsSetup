
# ==========================================
# STRAWBERRY WINDOWS - PROGRAM DATABASE
# ==========================================

$Global:Apps = @(

    @{
        Number = "2"
        Name = "Google Chrome"
        Category = "Web Browsers"
        Match = "Google Chrome"
        File = "ChromeEnterprise.msi"
        URL = "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi"
        Type = "MSI"
        InteractiveArguments = ""
        SilentArguments = "/qn /norestart"
        MinBytes = 30000000
        Publisher = "Google LLC"
        WingetID = "Google.Chrome"
    },

    @{
        Number = "4"
        Name = "VLC Media Player"
        Category = "Media"
        Match = "VLC media player"
        File = "VLCSetup.exe"
        URL = "https://get.videolan.org/vlc/3.0.24/win64/vlc-3.0.24-win64.exe"
        Type = "EXE"
        InteractiveArguments = ""
        SilentArguments = "/S"
        MinBytes = 10000000
        Publisher = "VideoLAN"
        WingetID = "VideoLAN.VLC"
    },

    @{
        Number = "5"
        Name = "LibreOffice"
        Category = "Office"
        Match = "LibreOffice"
        File = "LibreOffice.msi"
        URL = "https://download.documentfoundation.org/libreoffice/stable/26.8.2/win/x86_64/LibreOffice_26.8.2_Win_x86-64.msi"
        Type = "MSI"
        InteractiveArguments = ""
        SilentArguments = "/qn /norestart"
        MinBytes = 100000000
        Publisher = "The Document Foundation"
        WingetID = "TheDocumentFoundation.LibreOffice"
    },

    @{
        Number = "6"
        Name = "7-Zip"
        Category = "Compression"
        Description = "Great Compression App"
        Version = "26.06"
        Match = "7-Zip"
        File = "7zipSetup.exe"
        URL = "https://www.7-zip.org/a/7z2606-x64.exe"
        Type = "EXE"
        InteractiveArguments = ""
        SilentArguments = "/S"
        MinBytes = 500000
        Publisher = "Igor Pavlov"
        WingetID = "7zip.7zip"
    },

    @{
        Number = "7"
        Name = "Python 3.14"
        Category = "Development"
        Description = "Programming Language"
        Version = "3.14.7"
        Match = "Python 3.14"
        File = "PythonSetup.exe"
        URL = "https://www.python.org/ftp/python/3.14.7/python-3.14.7-amd64.exe"
        Type = "EXE"
        InteractiveArguments = "InstallAllUsers=0 PrependPath=1 Include_test=0"
        SilentArguments = "/quiet InstallAllUsers=0 PrependPath=1 Include_test=0"
        MinBytes = 10000000
        Publisher = "Python Software Foundation"
        WingetID = "Python.Python.3.14"
    },

    @{
        Number = "8"
        Name = "Opera"
        Category = "Web Browsers"
        Match = "Opera"
        File = "OperaSetup.exe"
        URL = "https://net.geo.opera.com/opera/stable/windows"
        Type = "EXE"
        InteractiveArguments = ""
        SilentArguments = "/silent /install"
        MinBytes = 2000000
        Publisher = "Opera Software"
        WingetID = "Opera.Opera"
    },

    @{
        Number = "9"
        Name = "Mozilla Firefox"
        Category = "Web Browsers"
        Match = "Mozilla Firefox"
        File = "FirefoxSetup.exe"
        URL = "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US"
        Type = "EXE"
        InteractiveArguments = ""
        SilentArguments = "/S"
        MinBytes = 30000000
        Publisher = "Mozilla"
        WingetID = "Mozilla.Firefox"
    },

    @{
        Number = "10"
        Name = "Microsoft Edge"
        Category = "Web Browsers"
        Match = "Microsoft Edge"
        File = "MicrosoftEdgeEnterprise.msi"
        URL = "https://go.microsoft.com/fwlink/?linkid=2109047&Channel=Stable&language=en&brand=M100"
        Type = "MSI"
        InteractiveArguments = ""
        SilentArguments = "/qn /norestart"
        MinBytes = 100000000
        Publisher = "Microsoft Corporation"
        WingetID = "Microsoft.Edge"
    },

    @{
        Number = "11"
        Name = "Brave"
        Category = "Web Browsers"
        Match = "Brave"
        File = "BraveBrowserSetup.exe"
        URL = "https://laptop-updates.brave.com/latest/winx64"
        Type = "EXE"
        InteractiveArguments = ""
        SilentArguments = "--install --silent --system-level"
        MinBytes = 100000000
        Publisher = "Brave Software Inc"
        WingetID = "Brave.Brave"
    },

    @{
        Number = "12"
        Name = "Vivaldi"
        Category = "Web Browsers"
        Match = "Vivaldi"
        File = "VivaldiSetup.exe"
        URL = "https://downloads.vivaldi.com/stable/Vivaldi.7.10.4432.100.x64.exe"
        Type = "EXE"
        InteractiveArguments = ""
        SilentArguments = "--silent --do-not-launch-chrome"
        MinBytes = 100000000
        Publisher = "Vivaldi Technologies AS"
        WingetID = "Vivaldi.Vivaldi"
    },

    @{
        Number = "13"
        Name = "PeaZip"
        Category = "Compression"
        Description = "File Compression Tool"
        Version = "11.4.0"
        Match = "PeaZip"
        File = "PeaZipSetup.exe"
        URL = "https://github.com/peazip/PeaZip/releases/download/11.4.0/peazip-11.4.0.WIN64.exe"
        Type = "EXE"
        InteractiveArguments = ""
        SilentArguments = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-"
        MinBytes = 5000000
        Publisher = "Giorgio Tani"
        WingetID = "GiorgioTani.PeaZip"
    },

    @{
        Number = "14"
        Name = "WinRAR"
        Category = "Compression"
        Description = "Another Compression Tool"
        Version = "7.23"
        Match = "WinRAR"
        File = "WinRARSetup.exe"
        URL = "https://www.rarlab.com/rar/winrar-x64-723.exe"
        Type = "EXE"
        InteractiveArguments = ""
        SilentArguments = "/S"
        MinBytes = 3000000
        Publisher = "RARLAB"
        WingetID = "RARLab.WinRAR"
    }
)
