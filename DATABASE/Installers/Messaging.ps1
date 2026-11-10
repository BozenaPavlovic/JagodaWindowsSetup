# Messaging
@(
    @{
        Number = "15"
        Name = "Zoom"
        Category = "Messaging"
        Description = "Video Conference"
        Version = "7.2.5.51704"
        Match = "Zoom"
        File = "ZoomInstallerFull.msi"
        URL = "https://zoom.us/client/latest/ZoomInstallerFull.msi?archType=x64"
        Type = "MSI"
        InteractiveArguments = ""
        SilentArguments = "/qn /norestart"
        MinBytes = 10000000
        Publisher = "Zoom Video Communications, Inc."
        WingetID = "Zoom.Zoom"
    },

    @{
        Number = "16"
        Name = "Discord"
        Category = "Messaging"
        Description = "Voice and Text Chat"
        Version = "1.0.9267"
        Match = "Discord"
        File = "DiscordSetup.exe"
        URL = "https://discord.com/api/downloads/distributions/app/installers/latest?channel=stable&platform=win&arch=x64"
        Type = "EXE"
        InteractiveArguments = ""
        SilentArguments = "-s"
        MinBytes = 50000000
        Publisher = "Discord Inc."
        WingetID = "Discord.Discord"
    },

    @{
        Number = "17"
        Name = "Microsoft Teams"
        Category = "Messaging"
        Description = "Video Conferencing, Meetings, Calling"
        Version = ""
        Match = "Microsoft Teams"
        File = "TeamsBootstrapper.exe"
        URL = "https://go.microsoft.com/fwlink/?linkid=2243204&clcid=0x409"
        Type = "EXE"
        InteractiveArguments = ""
        SilentArguments = "-p"
        MinBytes = 1000000
        Publisher = "Microsoft Corporation"
        WingetID = "Microsoft.Teams"
    },

    @{
        Number = "18"
        Name = "Slack"
        Category = "Messaging"
        Description = "Team Messaging and Collaboration"
        Version = "4.53.287"
        Match = "Slack"
        File = "SlackSetup.msi"
        URL = "https://slack.com/ssb/download-win64-msi"
        Type = "MSI"
        InteractiveArguments = ""
        SilentArguments = "/qn /norestart"
        MinBytes = 50000000
        Publisher = "Slack Technologies Inc."
        WingetID = "SlackTechnologies.Slack"
    },

    @{
        Number = "19"
        Name = "Telegram"
        Category = "Messaging"
        Description = "Fast, Secure Messaging App"
        Version = "7.4.1"
        Match = "Telegram"
        File = "TelegramSetup.exe"
        URL = "https://telegram.org/dl/desktop/win64"
        Type = "EXE"
        InteractiveArguments = ""
        SilentArguments = "/VERYSILENT /NORESTART"
        MinBytes = 20000000
        Publisher = "Telegram FZ-LLC"
        WingetID = "Telegram.TelegramDesktop"
    },

    @{
        Number = "20"
        Name = "WhatsApp"
        Category = "Messaging"
        Description = "Messaging and Calling"
        Version = ""
        Match = "WhatsApp"
        File = "WhatsAppSetup.exe"
        URL = "https://web.whatsapp.com/desktop/windows/release/x64/WhatsAppSetup.exe"
        Type = "EXE"
        InteractiveArguments = ""
        SilentArguments = "--silent"
        MinBytes = 50000000
        Publisher = "WhatsApp Inc."
        WingetID = "WhatsApp.WhatsApp"
    }
)
