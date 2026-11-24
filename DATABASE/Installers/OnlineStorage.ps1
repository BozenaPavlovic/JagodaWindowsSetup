# Online Storage
@(
    @{
        Number = "40"
        Name = "Dropbox"
        Category = "Online Storage"
        Description = "Online Backup / File Sync"
        Version = "280.4.5053"
        Match = "Dropbox"
        File = "DropboxInstaller.exe"
        URL = "https://www.dropbox.com/download"
        Type = "EXE"
        InteractiveArguments = ""
        SilentArguments = "/S"
        MinBytes = 5000000
        Publisher = "Dropbox, Inc."
        WingetID = "Dropbox.Dropbox"
        IconURL = "https://ninite.com/static/app_icons2/K4S33DWJMHIJLGM4ZP6LNH2EV4.png"
    },

    @{
        Number = "41"
        Name = "Google Drive for Desktop"
        Category = "Online Storage"
        Description = "Online File Sync"
        Version = "134.0.1.0"
        Match = "Google Drive"
        File = "GoogleDriveSetup.exe"
        URL = "https://dl.google.com/drive/download/GoogleDriveInstaller.exe"
        Type = "EXE"
        InteractiveArguments = ""
        SilentArguments = "/S"
        MinBytes = 50000000
        Publisher = "Google LLC"
        WingetID = "Google.GoogleDrive"
        IconURL = "https://ninite.com/static/app_icons2/M2YU6HDJA4HEIQZDWKCE4ZIQYY.png"
    },

    @{
        Number = "42"
        Name = "OneDrive"
        Category = "Online Storage"
        Description = "OneDrive"
        Version = ""
        Match = "OneDrive"
        File = "OneDriveSetup.exe"
        URL = "https://onedrive.live.com/?id=documents&cid=00000000000000000000000000000000"
        Type = "EXE"
        InteractiveArguments = ""
        SilentArguments = "/S"
        MinBytes = 1000000
        Publisher = "Microsoft Corporation"
        WingetID = "Microsoft.OneDrive"
        IconURL = "https://ninite.com/static/app_icons2/R7YFCGQNSZONF5VJ6I2U3RXCM4.png"
    }
)