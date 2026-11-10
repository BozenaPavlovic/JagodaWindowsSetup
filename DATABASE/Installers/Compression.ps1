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
