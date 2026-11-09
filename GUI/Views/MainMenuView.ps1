<#
.SYNOPSIS
    Main Menu View.
    Creates and combines all visual components.
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ==========================================
# MAIN FORM
# ==========================================

$script:Form = New-Object System.Windows.Forms.Form

$script:Form.Text = "STRAWBERRY WINDOWS"

$script:Form.Size = New-Object System.Drawing.Size(450, 750)

$script:Form.StartPosition = `
    [System.Windows.Forms.FormStartPosition]::CenterScreen

$script:Form.BackColor = [System.Drawing.Color]::WhiteSmoke

$script:Form.MinimumSize = New-Object System.Drawing.Size(400, 650)

$script:Form.FormBorderStyle = `
    [System.Windows.Forms.FormBorderStyle]::Sizable

$script:Form.MaximizeBox = $true
$script:Form.MinimizeBox = $true

$script:Form.AutoScaleMode = `
    [System.Windows.Forms.AutoScaleMode]::Font

# ==========================================
# LOAD MAIN MENU PANEL
# ==========================================

. "$PSScriptRoot\MainMenuPanel.ps1"

# ==========================================
# LOAD SYSTEM INFORMATION PANEL
# ==========================================

. "$PSScriptRoot\SystemInformationPanel.ps1"

# ==========================================
# ADD PANELS TO FORM
# ==========================================

# Main menu fills the remaining space.
$script:Form.Controls.Add($script:MainMenuPanel)

# System information stays at the bottom.
$script:Form.Controls.Add($script:SystemInformationPanel)