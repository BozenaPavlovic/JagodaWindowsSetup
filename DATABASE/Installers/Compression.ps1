# Compression
@(
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
