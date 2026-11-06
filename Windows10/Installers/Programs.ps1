
# ==========================================
# PINK WINDOWS - PROGRAM INSTALLER
# VERSION 4.0
# ==========================================

$ErrorActionPreference = "Stop"

# LOAD CONFIG
$ConfigPath = Join-Path $PSScriptRoot "..\Config.ps1"

if (!(Test-Path $ConfigPath)) {
    throw "Config.ps1 not found!"
}

. $ConfigPath

$Global:OSVersion = "Windows10"
$DownloadFolder = $Global:PinkConfig.DownloadFolder
$LogFolder = $Global:PinkConfig.LogFolder

New-Item -ItemType Directory -Force -Path $DownloadFolder | Out-Null
New-Item -ItemType Directory -Force -Path $LogFolder | Out-Null

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ==========================================
# APPLICATION DATABASE
# ==========================================

$Apps = @(
    @{
        Number="2"
        Name="Google Chrome"
        Match="Google Chrome"
        File="ChromeEnterprise.msi"
        URL="https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi"
        Type="MSI"
        InteractiveArguments=""
        SilentArguments="/qn /norestart"
        MinBytes=30000000
        Publisher="Google LLC"
         WingetID="Google.Chrome"
    },
    @{
        Number="4"
        Name="VLC Media Player"
        Match="VLC media player"
        File="VLCSetup.exe"
        URL="https://get.videolan.org/vlc/3.0.24/win64/vlc-3.0.24-win64.exe"
        Type="EXE"
        InteractiveArguments=""
        SilentArguments="/S"
        MinBytes=10000000
        Publisher="VideoLAN"
         WingetID="VideoLAN.VLC"
    },
    @{
        Number="5"
        Name="LibreOffice"
        Match="LibreOffice"
        File="LibreOffice.msi"
        URL="https://download.documentfoundation.org/libreoffice/stable/26.8.2/win/x86_64/LibreOffice_26.8.2_Win_x86-64.msi"
        Type="MSI"
        InteractiveArguments=""
        SilentArguments="/qn /norestart"
        MinBytes=100000000
        Publisher="The Document Foundation"
         WingetID="TheDocumentFoundation.LibreOffice"
    },
    @{
        Number="6"
        Name="7-Zip"
        Match="7-Zip"
        File="7zipSetup.exe"
        URL="https://www.7-zip.org/a/7z2603-x64.exe"
        Type="EXE"
        InteractiveArguments=""
        SilentArguments="/S"
        MinBytes=500000
        Publisher="Igor Pavlov"
         WingetID="7zip.7zip"
    },
    @{
        Number="7"
        Name="Python 3.14"
        Match="Python 3.14"
        File="PythonSetup.exe"
        URL="https://www.python.org/ftp/python/3.14.7/python-3.14.7-amd64.exe"
        Type="EXE"
        InteractiveArguments="InstallAllUsers=0 PrependPath=1 Include_test=0"
        SilentArguments="/quiet InstallAllUsers=0 PrependPath=1 Include_test=0"
        MinBytes=10000000
        Publisher="Python Software Foundation"
         WingetID="Python.Python.3.14"
    }
)

# ==========================================
# FIND INSTALLED APPLICATION
# ==========================================

function Find-InstalledApp {

    param([string]$Pattern)

    $Paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($Path in $Paths) {

        $Found = Get-ItemProperty $Path -ErrorAction SilentlyContinue |
            Where-Object {
                $_.DisplayName -like "*$Pattern*"
            }

        if ($Found) {
            return $Found | Select-Object -First 1
        }
    }

    return $null
}

# ==========================================
# DOWNLOAD INSTALLER
# ==========================================


function Get-ProgramInstaller {
    param($App)

    Write-Host "`nDOWNLOADING $($App.Name)..." -ForegroundColor Cyan

    try {
        $DownloadFolder = [IO.Path]::GetFullPath(
            $Global:PinkConfig.DownloadFolder
        )

        if (!(Test-Path -LiteralPath $DownloadFolder -PathType Container)) {
            New-Item -ItemType Directory -Path $DownloadFolder -Force -ErrorAction Stop | Out-Null
        }

        $Installer = Join-Path $DownloadFolder $App.File
        $Temporary = "$Installer.partial"

        Write-Host "Download folder: $DownloadFolder" -ForegroundColor Gray
        Write-Host "Installer path: $Installer" -ForegroundColor Gray

        if (Test-Path -LiteralPath $Temporary) {
            Remove-Item -LiteralPath $Temporary -Force
        }

        Invoke-WebRequest `
            -Uri $App.URL `
            -OutFile $Temporary `
            -UseBasicParsing `
            -TimeoutSec 600 `
            -ErrorAction Stop

        if (!(Test-Path -LiteralPath $Temporary -PathType Leaf)) {
            throw "Downloaded file does not exist."
        }

        $Size = (Get-Item -LiteralPath $Temporary).Length

        if ($Size -lt $App.MinBytes) {
            throw "Incomplete download: $Size bytes."
        }

        Move-Item -LiteralPath $Temporary -Destination $Installer -Force

        Write-Host "DOWNLOAD COMPLETE!" -ForegroundColor Green
        Write-Host "Size: $([math]::Round($Size / 1MB, 2)) MB"

        return $Installer
    }
    catch {
        Write-Host "DOWNLOAD DIAGNOSTICS:" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Category: $($_.CategoryInfo.Category)" -ForegroundColor Yellow
        Write-Host "Target: $($_.CategoryInfo.TargetName)" -ForegroundColor Yellow
        Write-Host "Position: $($_.InvocationInfo.PositionMessage)" -ForegroundColor Yellow

        throw
    }
}


# ==========================================
# WINGET SUPPORT
# ==========================================

function Test-Winget {
    try {
        winget --version | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Install-WithWinget {
    param($App)

    Write-Host "Winget detected - using winget installer." -ForegroundColor Green
    Write-Host "Installing $($App.Name) using winget..." -ForegroundColor Cyan

    winget install --id $App.WingetID --silent --accept-package-agreements --accept-source-agreements --force

    if ($LASTEXITCODE -ne 0) {
        throw "Winget installation failed with exit code $LASTEXITCODE"
    }

    Write-Host "Winget installation successful!" -ForegroundColor Green
}

# ==========================================
# INSTALL APPLICATION
# ==========================================

function Install-OneApp {

    param($App)

    Write-Host "`n========================================" -ForegroundColor Magenta
    Write-Host " $($App.Name)" -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta

    try {

        $Existing = Find-InstalledApp $App.Match

        if ($Existing -and $Global:AutoMode) {
            Write-Host "$($App.Name) already installed - verified, skipping." -ForegroundColor Green
            return
        }

        if ($Existing -and -not $Global:AutoMode) {

            Write-Host "ALREADY INSTALLED!" -ForegroundColor Yellow
            Write-Host "Version: $($Existing.DisplayVersion)"

            $Action = Read-Host "[S] Skip / [R] Reinstall"

            if ($Action -notmatch "^[Rr]") {
                return
            }
        }

        if ($Global:OSVersion -ne "Windows11") {
            if (Test-Winget) {
                try {
                    Install-WithWinget $App
                    return
                } catch {
                    Write-Host "Winget failed, falling back to classic installer." -ForegroundColor Yellow
                }
            } else {
                Write-Host "Winget not available - using classic installer." -ForegroundColor Yellow
            }
        } else {
            Write-Host "Detected Windows 11 - winget mode disabled." -ForegroundColor Yellow
        }

        if ($Global:AutoMode) {
            $Mode = "2"
        } else {
            Write-Host ""
            Write-Host "[1] Interactive installation"
            Write-Host "[2] Automatic installation"

            $Mode = Read-Host "Choose installation mode"

            if ($Mode -notin @("1","2")) {
                throw "Invalid installation mode."
            }
        }

        $Installer = Get-ProgramInstaller $App

        $SafeName = $App.Name -replace '[^a-zA-Z0-9]', '_'
        $Log = Join-Path $LogFolder "$SafeName.log"

        Write-Host "`nSTARTING INSTALLATION..." -ForegroundColor Cyan

        if ($App.Type -eq "MSI") {

            $Arguments = "/i `"$Installer`""

            if ($Mode -eq "2") {
                $Arguments += " $($App.SilentArguments)"
            }

            $Arguments += " /L*v `"$Log`""

            $Process = Start-Process `
                -FilePath "msiexec.exe" `
                -ArgumentList $Arguments `
                -Wait -PassThru

        }
        else {

            if ($Mode -eq "2") {
                $Arguments = $App.SilentArguments
            }
            else {
                $Arguments = $App.InteractiveArguments
            }

            $Process = Start-Process `
                -FilePath $Installer `
                -ArgumentList $Arguments `
                -Wait -PassThru
        }

        if ($Process.ExitCode -notin @(0,1641,3010)) {
            throw "Installer exit code: $($Process.ExitCode)"
        }

        Write-Host "`nVERIFYING INSTALLATION..." -ForegroundColor Cyan

        $Verified = $null

        for ($i = 1; $i -le 12; $i++) {

            Start-Sleep -Seconds 5

            $Verified = Find-InstalledApp $App.Match

            if ($Verified) {
                break
            }
        }

        if (!$Verified) {
            throw "Application not found in Windows registry."
        }

        Write-Host "`nINSTALLATION SUCCESSFUL!" -ForegroundColor Green
        Write-Host "Application: $($Verified.DisplayName)"
        Write-Host "Version: $($Verified.DisplayVersion)"

        Add-Content "$LogFolder\InstallationHistory.log" `
            "$(Get-Date) SUCCESS: $($App.Name)"

    }
    catch {

        Write-Host "`nINSTALLATION FAILED!" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red

        Add-Content "$LogFolder\InstallationHistory.log" `
            "$(Get-Date) FAILED: $($App.Name) - $($_.Exception.Message)"
    }

    if (-not $Global:AutoMode) {
        Read-Host "`nPress ENTER to continue"
    }
}

# ==========================================
# YOUTUBE SHORTCUT
# ==========================================

function Install-YouTubeShortcut {

    $Desktop = [Environment]::GetFolderPath("Desktop")
    $Shortcut = Join-Path $Desktop "YouTube.url"

    @"
[InternetShortcut]
URL=https://www.youtube.com/
"@ | Set-Content -Path $Shortcut -Encoding ASCII

    Write-Host "YouTube shortcut created!" -ForegroundColor Green
}

# ==========================================
# MAIN INSTALLER MENU
# ==========================================

function Install-Programs {

    while ($true) {

        Clear-Host

        Write-Host "========================================" -ForegroundColor Magenta
        Write-Host " PINK WINDOWS PROGRAM INSTALLER" -ForegroundColor Magenta
        Write-Host "========================================" -ForegroundColor Magenta

        Write-Host ""
        Write-Host "[1] INSTALL ALL PROGRAMS" -ForegroundColor Magenta
        Write-Host "[2] Google Chrome"
        Write-Host "[3] YouTube shortcut"
        Write-Host "[4] VLC Media Player"
        Write-Host "[5] LibreOffice"
        Write-Host "[6] 7-Zip"
        Write-Host "[7] Python 3.14"
        Write-Host "[0] Back"
        Write-Host ""

        $Choice = Read-Host "Choose program"

        if ($Choice -eq "0") {
            return
        }

        if ($Choice -eq "3") {
            Install-YouTubeShortcut
            Read-Host "Press ENTER"
            continue
        }

        if ($Choice -eq "1") {
            $Global:AutoMode = $true
            $Selected = $Apps
        } else {
            $Global:AutoMode = $false
            $Selected = @($Apps | Where-Object {
                $_.Number -eq $Choice
            })
        }

        if ($Selected.Count -eq 0) {
            Write-Host "Invalid option!" -ForegroundColor Red
            Start-Sleep 2
            continue
        }

        foreach ($App in $Selected) {
            Install-OneApp $App
        }

        Write-Host "`nINSTALLATION SESSION FINISHED!" -ForegroundColor Magenta
        Read-Host "Press ENTER to return"
    }
}

Write-Host "[OK] Pink Windows installer module loaded." -ForegroundColor Green
