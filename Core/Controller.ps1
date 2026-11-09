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
        Write-Host "[4] System Info"
        Write-Host "[0] Exit"
        Write-Host ""

        $choice = Read-Host "Choose option"

        switch ($choice) {
            "1" { Install-Programs }
            "2" { Install-PinkTheme }
            "3" { WALLPAPERS 1 }
            "4" { Get-SystemSpecs }
            "0" { return }
            default { Write-Host "Invalid option!" -ForegroundColor Red }
        }

        if ($choice -ne "0") {
            Write-Host ""
            Read-Host "Press ENTER to return to menu"
        }
    }
}

function Run-Installation {
    Show-MainMenu
}