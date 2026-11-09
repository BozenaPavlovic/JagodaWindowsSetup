# Core/Controller.ps1 - Application orchestration

function Get-SelectedApps {
    param($ids)
    $Global:Apps | Where-Object { $_.Number -in $ids }
}

function Show-MainMenu {
    $root = $PSScriptRoot
    $config = Get-OSConfig

    while ($true) {
        Clear-Host
        Write-Host "====================================" -ForegroundColor Magenta
        Write-Host "   STRAWBERRY WINDOWS SETUP" -ForegroundColor Magenta
        Write-Host "====================================" -ForegroundColor Magenta
        Write-Host "Detected OS: $($config.OS)" -ForegroundColor Cyan
        Write-Host "Theme: $($config.Theme)" -ForegroundColor Cyan
        Write-Host "Dark Mode: $($config.EnableDarkMode)" -ForegroundColor Cyan
        Write-Host "====================================" -ForegroundColor Magenta
        Write-Host ""
        Write-Host "[1] Install Programs"
        Write-Host "[2] Apply Theme"
        Write-Host "[3] Set Wallpaper"
        Write-Host "[4] OS Specifications"
        Write-Host "[0] Exit"
        Write-Host ""

        $choice = Read-Host "Choose option"

        switch ($choice) {
            "1" { Install-Programs }
            "2" { Install-PinkTheme }
            "3" { WALLPAPERS 1 }
            "4" { Show-OSSpecs }
            "0" { return }
            default { Write-Host "Invalid option!" -ForegroundColor Red }
        }

        if ($choice -ne "0") {
            Write-Host ""
            Read-Host "Press ENTER to return to menu"
        }
    }
}

function Show-OSSpecs {
    $spec = Get-SystemSpecs
    Clear-Host
    Write-Host "====================================" -ForegroundColor Magenta
    Write-Host "   OS SPECIFICATIONS" -ForegroundColor Magenta
    Write-Host "====================================" -ForegroundColor Magenta
    Write-Host "OS:            $($spec.OS)" -ForegroundColor Cyan
    Write-Host "Platform:      $($spec.Platform)" -ForegroundColor Cyan
    Write-Host "IsWindows:     $($spec.IsWindows)" -ForegroundColor Cyan
    Write-Host "Computer:      $($spec.ComputerName)" -ForegroundColor Cyan
    Write-Host "User:          $($spec.UserName)" -ForegroundColor Cyan
    Write-Host "64Bit:         $($spec.Is64Bit)" -ForegroundColor Cyan
    Write-Host "PowerShell:    $($spec.PowerShell)" -ForegroundColor Cyan
    Write-Host "====================================" -ForegroundColor Magenta
    Write-Host ""
    Read-Host "Press ENTER to return to menu"
}

function Run-Installation {
    Show-MainMenu
}