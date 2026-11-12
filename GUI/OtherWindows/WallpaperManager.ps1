<#
.SYNOPSIS
    Wallpaper Manager GUI.

.DESCRIPTION
    Displays available wallpapers from DATA/Photos and applies them.
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ==========================================
# LOAD SHARED PATHS
# ==========================================

$pathsModule = Join-Path $PSScriptRoot "..\..\Core\Paths.ps1"
if (Test-Path -LiteralPath $pathsModule) {
    . $pathsModule
}

# ==========================================
# LOAD WALLPAPER BACKEND
# ==========================================

$wallpaperModule = Join-Path $Global:ProjectRoot "Core\Wallpapers\Wallpaper.ps1"
if (Test-Path -LiteralPath $wallpaperModule) {
    . $wallpaperModule
}

# ==========================================
# GET WALLPAPER FILES
# ==========================================

$photosDir = $Global:PhotosFolder
$files = Get-ChildItem $photosDir -Filter *.jpg -ErrorAction SilentlyContinue

if (-not $files -or $files.Count -eq 0) {
    [System.Windows.Forms.MessageBox]::Show(
        "No wallpaper images found in:`n$photosDir",
        "Wallpaper Manager",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    ) | Out-Null
    return
}

# ==========================================
# MAIN FORM
# ==========================================

$form = New-Object System.Windows.Forms.Form
$form.Text = "STRAWBERRY WINDOWS - WALLPAPER MANAGER"
$form.Size = New-Object System.Drawing.Size(500, 450)
$form.MinimumSize = New-Object System.Drawing.Size(400, 350)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::WhiteSmoke

# ==========================================
# TITLE
# ==========================================

$title = New-Object System.Windows.Forms.Label
$title.Text = "SELECT WALLPAPER"
$title.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(20, 15)
$form.Controls.Add($title)

# ==========================================
# LISTBOX WITH WALLPAPERS
# ==========================================

$lb = New-Object System.Windows.Forms.ListBox
$lb.Location = New-Object System.Drawing.Point(20, 55)
$lb.Size = New-Object System.Drawing.Size(440, 250)
$lb.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$lb.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$lb.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

foreach ($f in $files) {
    $lb.Items.Add($f.Name) | Out-Null
}

$form.Controls.Add($lb)

# ==========================================
# PREVIEW LABEL
# ==========================================

$previewLabel = New-Object System.Windows.Forms.Label
$previewLabel.Text = "Double-click a wallpaper to apply"
$previewLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$previewLabel.ForeColor = [System.Drawing.Color]::DimGray
$previewLabel.AutoSize = $true
$previewLabel.Location = New-Object System.Drawing.Point(20, 315)
$form.Controls.Add($previewLabel)

# ==========================================
# APPLY BUTTON
# ==========================================

$applyBtn = New-Object System.Windows.Forms.Button
$applyBtn.Text = "Apply Selected"
$applyBtn.Location = New-Object System.Drawing.Point(20, 345)
$applyBtn.Size = New-Object System.Drawing.Size(150, 35)
$applyBtn.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
$applyBtn.BackColor = [System.Drawing.Color]::LavenderBlush
$applyBtn.Font = New-Object System.Drawing.Font("Segoe UI", 10)

$applyBtn.Add_Click({
    $selected = $lb.SelectedItem
    if (-not $selected) {
        [System.Windows.Forms.MessageBox]::Show(
            "Please select a wallpaper first.",
            "Wallpaper Manager",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        return
    }

    $index = $lb.SelectedIndex
    $wallpaperNumber = $index + 1

    try {
        $ErrorActionPreference = "Stop"
        if (Get-Command WALLPAPERS -ErrorAction SilentlyContinue) {
            WALLPAPERS $wallpaperNumber
        }
        else {
            # Fallback: apply directly
            $wallpaperPath = $files[$index].FullName
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

            if (![WallpaperAPI]::SystemParametersInfo(20, 0, $wallpaperPath, 3)) {
                throw "Could not apply wallpaper."
            }
            Write-Host "Wallpaper applied: $wallpaperPath" -ForegroundColor Green
        }

        [System.Windows.Forms.MessageBox]::Show(
            "Wallpaper applied successfully!",
            "Wallpaper Manager",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Failed to apply wallpaper:`n$($_.Exception.Message)",
            "Wallpaper Manager",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }
})

$form.Controls.Add($applyBtn)

# ==========================================
# CLOSE BUTTON
# ==========================================

$closeBtn = New-Object System.Windows.Forms.Button
$closeBtn.Text = "Close"
$closeBtn.Location = New-Object System.Drawing.Point(185, 345)
$closeBtn.Size = New-Object System.Drawing.Size(150, 35)
$closeBtn.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left
$closeBtn.Font = New-Object System.Drawing.Font("Segoe UI", 10)

$closeBtn.Add_Click({
    $form.Close()
})

$form.Controls.Add($closeBtn)

# ==========================================
# DOUBLE-CLICK TO APPLY
# ==========================================

$lb.Add_DoubleClick({
    $applyBtn.PerformClick()
})

# ==========================================
# SHOW FORM
# ==========================================

[void]$form.ShowDialog()
$form.Dispose()