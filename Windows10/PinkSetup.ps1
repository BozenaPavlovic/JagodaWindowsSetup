
# ==========================================
# PINK WINDOWS - MAIN MENU DEBUG VERSION
# ==========================================

$ErrorActionPreference = "Stop"

function Get-OSSpecs {
    $reg = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
    [PSCustomObject]@{
        OSName  = "Windows 10"
        Version = $reg.DisplayVersion
        Build   = $reg.CurrentBuild
        Edition = $reg.EditionID
        Arch    = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
    }
}

try {

    $Root = $PSScriptRoot

    Write-Host "Loading Pink Windows modules..." -ForegroundColor Magenta

    # Check files
    $Modules = @(
        "$Root\Config.ps1",
        "$Root\Wallpapers\Wallpaper.ps1",
        "$Root\Themes\PinkTheme.ps1",
        "$Root\Installers\Programs.ps1"
    )

    foreach ($Module in $Modules) {

        if (!(Test-Path $Module)) {
            throw "Missing module: $Module"
        }

        Write-Host "[OK] $Module" -ForegroundColor Green
    }

    # Load modules
    . "$Root\Config.ps1"
    . "$Root\Wallpapers\Wallpaper.ps1"
    . "$Root\Themes\PinkTheme.ps1"
    . "$Root\Installers\Programs.ps1"

    Write-Host "All modules loaded!" -ForegroundColor Green

    while ($true) {

        Clear-Host

        $spec = Get-OSSpecs
        Write-Host "====================================" -ForegroundColor Magenta
        Write-Host "   PINK WINDOWS - STRAWBERRY       " -ForegroundColor Magenta
        Write-Host "====================================" -ForegroundColor Magenta
        Write-Host "Detected OS: $($spec.OSName)" -ForegroundColor Cyan
        Write-Host "Version: $($spec.Version)" -ForegroundColor Cyan
        Write-Host "Build: $($spec.Build)" -ForegroundColor Cyan
        Write-Host "Edition: $($spec.Edition)" -ForegroundColor Cyan
        Write-Host "Architecture: $($spec.Arch)" -ForegroundColor Cyan
        Write-Host "====================================" -ForegroundColor Magenta

        Write-Host ""
        Write-Host "[1] Choose Wallpaper"
        Write-Host "[2] Choose Theme"
        Write-Host "[3] Install Programs"
        Write-Host "[4] Complete Installation"
        Write-Host "[0] Exit"
        Write-Host ""

        $Choice = Read-Host "Choose option"

        try {

            switch ($Choice) {

                "1" {
                    Write-Host "[1] Pink Strawberry"
                    Write-Host "[2] Yellow Flowers Blue Sky"
                    $W = Read-Host "Choose wallpaper"
                    if ($W -eq "1") { WALLPAPERS 1 } else { WALLPAPERS 2 }
                }

                "2" {
                    Write-Host "[1] Pink"
                    Write-Host "[2] Blue"
                    Write-Host "[3] Yellow"
                    Write-Host "[4] Green"
                    $T = Read-Host "Choose theme"
                    switch ($T) {
                        "1" { Install-PinkTheme }
                        "2" { Install-BlueTheme }
                        "3" { Install-YellowTheme }
                        "4" { Install-GreenTheme }
                    }
                }

                "3" {
                    Install-Programs
                }

                "4" {
                    & "$PSScriptRoot\..\GUI\ProgramInstaller.ps1"
                }

                "0" {
                    return
                }

                default {
                    Write-Host "Invalid option!" -ForegroundColor Red
                }
            }

        }
        catch {

            Write-Host ""
            Write-Host "MODULE ERROR!" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
            Write-Host $_.ScriptStackTrace -ForegroundColor Yellow
        }

        if ($Choice -ne "0") {
            Write-Host ""
            Read-Host "Press ENTER to return to menu"
        }
    }

}
catch {

    Write-Host ""
    Write-Host "MAIN SYSTEM ERROR!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Yellow

}
finally {

    Write-Host ""
    Read-Host "Press ENTER to close Pink Windows"

}
