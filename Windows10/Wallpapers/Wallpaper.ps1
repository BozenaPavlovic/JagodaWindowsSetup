# WALLPAPER MODULE

function WALLPAPERS {
    param([int]$Number = 1)

    $PhotosFolder = Join-Path $PSScriptRoot "..\DATA\Photos"
    $Photos = @(
        (Join-Path $PhotosFolder "Pink-Strawberry.jpg")
        (Join-Path $PhotosFolder "Yellow-Flowers-Blue-Sky.jpg")
    )

    if ($Number -lt 1 -or $Number -gt $Photos.Count) {
        Write-Host "Invalid wallpaper number." -ForegroundColor Red
        return
    }

    $Wallpaper = $Photos[$Number - 1]
    if (!(Test-Path $Wallpaper)) {
        Write-Host "Wallpaper file not found: $Wallpaper" -ForegroundColor Red
        return
    }

    Set-ItemProperty "HKCU:\Control Panel\Desktop" WallpaperStyle "10"
    Set-ItemProperty "HKCU:\Control Panel\Desktop" TileWallpaper "0"

    if (!("WallpaperAPI" -as [type])) {
        Add-Type @"
using System.Runtime.InteropServices;
public class WallpaperAPI {
    [DllImport("user32.dll", CharSet=CharSet.Unicode)]
    public static extern bool SystemParametersInfo(int action, int param, string path, int flags);
}
"@
    }

    if (![WallpaperAPI]::SystemParametersInfo(20, 0, $Wallpaper, 3)) {
        Write-Host "Could not apply wallpaper." -ForegroundColor Red
        return
    }

    Write-Host "Wallpaper applied: $Wallpaper" -ForegroundColor Green
}
