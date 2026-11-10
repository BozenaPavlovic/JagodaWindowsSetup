# Core/ThemeEngine.ps1 - Shared theme engine for Windows 10/11
# Low-level accent/theme operations. No config side effects on load.

function global:Set-ThemeDword {
    param(
        [AllowNull()][AllowEmptyString()][string]$Path,
        [AllowNull()][AllowEmptyString()][string]$Name,
        [Parameter(Mandatory)][int]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw "Set-ThemeDword: registry path is null/empty for value '$Name'."
    }
    if ([string]::IsNullOrWhiteSpace($Name)) {
        throw "Set-ThemeDword: registry name is null/empty for path '$Path'."
    }

    if (!(Test-Path -LiteralPath $Path)) {
        New-Item -Path $Path -Force -ErrorAction Stop | Out-Null
    }

    New-ItemProperty -LiteralPath $Path `
        -Name $Name `
        -Value $Value `
        -PropertyType DWord `
        -Force `
        -ErrorAction Stop | Out-Null
}

function global:ConvertTo-WindowsColor {
    param([Parameter(Mandatory)][string]$Color)

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

    return [BitConverter]::ToInt32([BitConverter]::GetBytes($ABGR), 0)
}

function global:New-AccentPalette {
    param([Parameter(Mandatory)][string]$Color)

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

function global:Invoke-ThemeRefresh {
    param([string]$OS)

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

    # Shared refresh for Win10/Win11; OS hook point for future divergence.
    Write-Host "Refreshing Windows taskbar..." -ForegroundColor Yellow

    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 1500
    Start-Process "$env:WINDIR\explorer.exe" -ArgumentList "/n,/e,::{20D04FE0-3AEA-1069-A2D8-08002B30309D}"
}

function global:Set-WindowsAccentTheme {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Color,
        [ConsoleColor]$DisplayColor = [ConsoleColor]::Magenta,
        [string]$OS
    )

    Write-Host ""
    Write-Host "Applying $Name Windows theme..." -ForegroundColor $DisplayColor

    try {
        $personalizePath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
        $dwmPath         = 'HKCU:\Software\Microsoft\Windows\DWM'
        $accentPath      = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent'

        foreach ($kv in @(
            @{ N = 'Personalize'; P = $personalizePath },
            @{ N = 'DWM';         P = $dwmPath },
            @{ N = 'Accent';      P = $accentPath }
        )) {
            if ([string]::IsNullOrWhiteSpace($kv.P)) {
                throw "Theme registry path '$($kv.N)' is null/empty."
            }
        }

        $Accent = ConvertTo-WindowsColor $Color
        $Palette = New-AccentPalette $Color

        Set-ThemeDword -Path $personalizePath -Name 'SystemUsesLightTheme' -Value 0
        Set-ThemeDword -Path $personalizePath -Name 'AppsUseLightTheme'    -Value 1
        Set-ThemeDword -Path $personalizePath -Name 'EnableTransparency'   -Value 1
        Set-ThemeDword -Path $personalizePath -Name 'ColorPrevalence'      -Value 1

        Set-ThemeDword -Path $dwmPath -Name 'ColorPrevalence'    -Value 1
        Set-ThemeDword -Path $dwmPath -Name 'AccentColor'        -Value $Accent
        Set-ThemeDword -Path $dwmPath -Name 'ColorizationColor'  -Value $Accent

        Set-ThemeDword -Path $accentPath -Name 'AccentColorMenu' -Value $Accent
        Set-ThemeDword -Path $accentPath -Name 'StartColorMenu'  -Value $Accent

        if (!(Test-Path -LiteralPath $accentPath)) {
            New-Item -Path $accentPath -Force -ErrorAction Stop | Out-Null
        }

        New-ItemProperty -LiteralPath $accentPath `
            -Name 'AccentPalette' `
            -PropertyType Binary `
            -Value $Palette `
            -Force `
            -ErrorAction Stop | Out-Null

        Write-Host "Registry updated successfully." -ForegroundColor Gray

        Invoke-ThemeRefresh -OS $OS

        Write-Host ""
        Write-Host "====================================" -ForegroundColor Green
        Write-Host " $Name WINDOWS THEME APPLIED!" -ForegroundColor Green
        Write-Host "====================================" -ForegroundColor Green
    }
    catch {
        $detail = $_.Exception.Message
        if ($_.ScriptStackTrace) { $detail += "`n$($_.ScriptStackTrace)" }
        Write-Host "THEME ERROR: $detail" -ForegroundColor Red
        throw $detail
    }
}
