
. "$PSScriptRoot\..\Config.ps1"

# ==========================================
# PINK WINDOWS - STRAWBERRY THEME ENGINE
# Windows 10
# ==========================================

function Set-Dword {
    param(
        [string]$Path,
        [string]$Name,
        [int]$Value
    )

    if (!(Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }

    New-ItemProperty -Path $Path `
        -Name $Name `
        -Value $Value `
        -PropertyType DWord `
        -Force | Out-Null
}

function ConvertTo-WindowsColor {
    param([string]$Color)

    $RGB = $Color.TrimStart("#")

    if ($RGB -notmatch '^[0-9A-Fa-f]{6}$') {
        throw "Invalid color: $Color"
    }

    $R = [Convert]::ToInt32($RGB.Substring(0,2),16)
    $G = [Convert]::ToInt32($RGB.Substring(2,2),16)
    $B = [Convert]::ToInt32($RGB.Substring(4,2),16)

    $ABGR = [uint32](
        0xFF000000L -bor
        ($B -shl 16) -bor
        ($G -shl 8) -bor
        $R
    )

    return [BitConverter]::ToInt32(
        [BitConverter]::GetBytes($ABGR), 0
    )
}

function New-AccentPalette {
    param([string]$Color)

    $RGB = $Color.TrimStart("#")

    $R = [Convert]::ToInt32($RGB.Substring(0,2),16)
    $G = [Convert]::ToInt32($RGB.Substring(2,2),16)
    $B = [Convert]::ToInt32($RGB.Substring(4,2),16)

    $Factors = @(0.75,0.85,0.95,1.0,0.65,0.55,1.10,1.20)

    $Palette = New-Object 'System.Collections.Generic.List[byte]'

    foreach ($Factor in $Factors) {
        $Palette.Add([byte][Math]::Min(255,[Math]::Round($R*$Factor)))
        $Palette.Add([byte][Math]::Min(255,[Math]::Round($G*$Factor)))
        $Palette.Add([byte][Math]::Min(255,[Math]::Round($B*$Factor)))
        $Palette.Add(255)
    }

    return ,([byte[]]$Palette.ToArray())
}

function Set-WindowsAccentTheme {
    param(
        [string]$Name,
        [string]$Color,
        [ConsoleColor]$DisplayColor
    )

    Write-Host ""
    Write-Host "Applying $Name Windows theme..." -ForegroundColor $DisplayColor

    try {
        $Personalize = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
        $DWM = "HKCU:\Software\Microsoft\Windows\DWM"
        $AccentPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent"

        $Accent = ConvertTo-WindowsColor $Color
        $Palette = New-AccentPalette $Color

        # Windows appearance
        Set-Dword $Personalize "SystemUsesLightTheme" 0
        Set-Dword $Personalize "AppsUseLightTheme" 1
        Set-Dword $Personalize "EnableTransparency" 1

        # Taskbar and Start Menu
        Set-Dword $Personalize "ColorPrevalence" 1

        # Window borders and title bars
        Set-Dword $DWM "ColorPrevalence" 1
        Set-Dword $DWM "AccentColor" $Accent
        Set-Dword $DWM "ColorizationColor" $Accent

        # Explorer accent colors
        Set-Dword $AccentPath "AccentColorMenu" $Accent
        Set-Dword $AccentPath "StartColorMenu" $Accent

        # Accent palette
        New-ItemProperty -Path $AccentPath `
            -Name "AccentPalette" `
            -PropertyType Binary `
            -Value $Palette `
            -Force | Out-Null

        Write-Host "Registry updated successfully." -ForegroundColor Gray

        # Notify Windows of the personalization change
        if (-not ('StrawberryThemeRefresh' -as [type])) {
            Add-Type @'
using System;
using System.Runtime.InteropServices;

public class StrawberryThemeRefresh {
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern IntPtr SendMessageTimeout(
        IntPtr hWnd,
        uint Msg,
        UIntPtr wParam,
        string lParam,
        uint flags,
        uint timeout,
        out UIntPtr result
    );
}
'@
        }

        $Result = [UIntPtr]::Zero

        [StrawberryThemeRefresh]::SendMessageTimeout(
            [IntPtr]0xffff,
            0x001A,
            [UIntPtr]::Zero,
            "ImmersiveColorSet",
            2,
            5000,
            [ref]$Result
        ) | Out-Null

        # Refresh Explorer shell without opening a folder window
        Write-Host "Refreshing Windows taskbar..." -ForegroundColor Yellow

        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue

        Start-Sleep -Milliseconds 1500

        Start-Process "$env:WINDIR\explorer.exe" -ArgumentList "/n,/e,::{20D04FE0-3AEA-1069-A2D8-08002B30309D}"

        Write-Host ""
        Write-Host "====================================" -ForegroundColor Green
        Write-Host " $Name WINDOWS THEME APPLIED!" -ForegroundColor Green
        Write-Host "====================================" -ForegroundColor Green
    }
    catch {
        Write-Host "THEME ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ==========================================
# THEME OPTIONS
# ==========================================

function Install-PinkTheme {
    Set-WindowsAccentTheme "Pink" "#FF69B4" Magenta
}

function Install-BlueTheme {
    Set-WindowsAccentTheme "Blue" "#1E90FF" Cyan
}

function Install-YellowTheme {
    Set-WindowsAccentTheme "Yellow" "#FFD700" Yellow
}

function Install-GreenTheme {
    Set-WindowsAccentTheme "Green" "#32CD32" Green
}
