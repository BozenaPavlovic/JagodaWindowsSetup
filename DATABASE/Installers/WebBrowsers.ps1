# Web Browsers
@(
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
    }
)
