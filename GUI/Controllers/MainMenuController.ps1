
<#
.SYNOPSIS
    Main Menu Controller.

.DESCRIPTION
    Handles menu navigation and opens scripts from OtherWindows.
#>

# ==========================================
# WINDOW FILE MAPPING
# ==========================================

$script:WindowFiles = @{
    "Profile Installer" = "ProfileInstaller.ps1"
    "Apps Installer"    = "AppsInstaller.ps1"
    "Theme Manager"     = "ThemeManager.ps1"
    "Wallpaper Manager" = "WallpaperManager.ps1"
    "Log Viewer"        = "LogViewer.ps1"
    "About"             = "About.ps1"
}

# ==========================================
# INITIALIZE CONTROLLER
# ==========================================

function Initialize-MainMenuController {

    # ==========================================
    # MENU BUTTON EVENTS
    # ==========================================

    foreach ($btn in $script:MenuButtons) {

        $btn.Add_Click({

            param($sender, $eventArgs)

            $selectedItem = [string]$sender.Tag

            # GET FILE NAME
            $fileName = $script:WindowFiles[$selectedItem]

            if ([string]::IsNullOrWhiteSpace($fileName)) {

                [System.Windows.Forms.MessageBox]::Show(
                    "No window is registered for: $selectedItem",
                    "Strawberry Windows"
                ) | Out-Null

                return
            }

            # ==========================================
            # BUILD WINDOW PATH
            # ==========================================

            $otherWindowsFolder = Join-Path `
                $script:ProjectRoot `
                "OtherWindows"

            $windowPath = Join-Path `
                $otherWindowsFolder `
                $fileName

            # ==========================================
            # CHECK FOLDER
            # ==========================================

            if (-not (Test-Path -LiteralPath $otherWindowsFolder -PathType Container)) {

                [System.Windows.Forms.MessageBox]::Show(
                    "OtherWindows folder not found:`n$otherWindowsFolder",
                    "Strawberry Windows"
                ) | Out-Null

                return
            }

            # ==========================================
            # CHECK FILE
            # ==========================================

            if (-not (Test-Path -LiteralPath $windowPath -PathType Leaf)) {

                [System.Windows.Forms.MessageBox]::Show(
                    "Window script not found:`n$windowPath",
                    "Strawberry Windows"
                ) | Out-Null

                return
            }

            # ==========================================
            # OPEN WINDOW
            # ==========================================

            try {

                Write-Host "Opening window: $windowPath" -ForegroundColor Cyan

                & $windowPath

            }
            catch {

                [System.Windows.Forms.MessageBox]::Show(
                    "Failed to open $selectedItem.`n`n$($_.Exception.Message)",
                    "Strawberry Windows",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Error
                ) | Out-Null
            }
        })
    }

    # ==========================================
    # EXIT BUTTON
    # ==========================================

    $script:ExitButton.Add_Click({

        $script:Form.Close()

    })
}
