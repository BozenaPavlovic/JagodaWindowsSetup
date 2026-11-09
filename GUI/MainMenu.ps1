<#
.SYNOPSIS
    Strawberry Windows - Main Application Entry Point.
#>

# ==========================================
# INITIALIZATION
# ==========================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ==========================================
# PROJECT ROOT
# ==========================================

$script:ProjectRoot = $PSScriptRoot

# ==========================================
# LOAD MODEL
# ==========================================

. "$PSScriptRoot\Models\MainMenuModel.ps1"

# ==========================================
# LOAD FORMATTER
# ==========================================

. "$PSScriptRoot\Helpers\SystemInformationFormatter.ps1"

# ==========================================
# LOAD VIEW
# ==========================================

. "$PSScriptRoot\Views\MainMenuView.ps1"

# ==========================================
# LOAD CONTROLLER
# ==========================================

. "$PSScriptRoot\Controllers\MainMenuController.ps1"

# ==========================================
# GET SYSTEM INFORMATION
# ==========================================

try {

    $script:SystemInfo = Get-SystemInformation

    $script:LabelInfo.Text = Format-SystemInformation `
        -SystemInfo $script:SystemInfo

}
catch {

    $script:LabelInfo.Text = "Unable to load system information.`r`n`r`n$($_.Exception.Message)"
}

# ==========================================
# INITIALIZE CONTROLLER
# ==========================================

Initialize-MainMenuController

# ==========================================
# START APPLICATION
# ==========================================

[void]$script:Form.ShowDialog()

# ==========================================
# CLEANUP
# ==========================================

$script:Form.Dispose()