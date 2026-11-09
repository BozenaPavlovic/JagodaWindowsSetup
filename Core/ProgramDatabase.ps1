
# ==========================================
# STRAWBERRY WINDOWS - PROGRAM DATABASE
# ==========================================

$Global:Apps = @(

    @{
        Number = "2"
        Name = "Google Chrome"
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
        Match = "7-Zip"
        File = "7zipSetup.exe"
        URL = "https://www.7-zip.org/a/7z2603-x64.exe"
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
        Match = "Python 3.14"
        File = "PythonSetup.exe"
        URL = "https://www.python.org/ftp/python/3.14.7/python-3.14.7-amd64.exe"
        Type = "EXE"
        InteractiveArguments = "InstallAllUsers=0 PrependPath=1 Include_test=0"
        SilentArguments = "/quiet InstallAllUsers=0 PrependPath=1 Include_test=0"
        MinBytes = 10000000
        Publisher = "Python Software Foundation"
        WingetID = "Python.Python.3.14"
    }
)
