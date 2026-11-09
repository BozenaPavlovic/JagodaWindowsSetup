<#
.SYNOPSIS
    Main Menu Controller.

.DESCRIPTION
    Handles menu button events, application navigation and exit.
#>

# ==========================================
# INITIALIZE MAIN MENU CONTROLLER
# ==========================================

function Initialize-MainMenuController {

    # ==========================================
    # MENU BUTTON EVENTS
    # ==========================================

    foreach ($btn in $script:MenuButtons) {

        $btn.Add_Click({

            $selectedItem = [string]$this.Tag

            # Convert button name to filename.
            $fileName = $selectedItem -replace '\s+', ''

            # Build OtherWindows path.
            $windowPath = Join-Path `
                $script:ProjectRoot `
                "OtherWindows\$fileName.ps1"

            # ==========================================
            # CHECK FILE
            # ==========================================

            if (-not (Test-Path -LiteralPath $windowPath -PathType Leaf)) {

                [System.Windows.Forms.MessageBox]::Show(
                    "Window script not found:`n$windowPath",
                    "Strawberry Windows",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Warning
                ) | Out-Null

                return
            }

            # ==========================================
            # OPEN WINDOW
            # ==========================================

            try {

                & $windowPath

            }
            catch {

                [System.Windows.Forms.MessageBox]::Show(
                    "Unable to open $selectedItem.`n`n$($_.Exception.Message)",
                    "Strawberry Windows",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Error
                ) | Out-Null
            }
        })
    }

    # ==========================================
    # EXIT BUTTON EVENT
    # ==========================================

    $script:ExitButton.Add_Click({

        $script:Form.Close()
    })
}