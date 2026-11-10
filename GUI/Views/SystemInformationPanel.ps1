<#
.SYNOPSIS
    System Information Panel View.
#>

# ==========================================
# SYSTEM INFORMATION PANEL
# ==========================================

$script:SystemInformationPanel = New-Object System.Windows.Forms.Panel

$script:SystemInformationPanel.Dock = [System.Windows.Forms.DockStyle]::Bottom
$script:SystemInformationPanel.Height = 350
$script:SystemInformationPanel.AutoScroll = $true

$script:SystemInformationPanel.BackColor = [System.Drawing.Color]::LavenderBlush

$script:SystemInformationPanel.BorderStyle = `
    [System.Windows.Forms.BorderStyle]::FixedSingle

# ==========================================
# PANEL TITLE
# ==========================================

$script:LabelTitle = New-Object System.Windows.Forms.Label

$script:LabelTitle.Text = "SYSTEM INFORMATION"

$script:LabelTitle.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    10,
    [System.Drawing.FontStyle]::Bold
)

$script:LabelTitle.ForeColor = [System.Drawing.Color]::DarkMagenta

$script:LabelTitle.Location = New-Object System.Drawing.Point(10, 8)

$script:LabelTitle.AutoSize = $true

# ==========================================
# SYSTEM INFORMATION LABEL
# ==========================================

$script:LabelInfo = New-Object System.Windows.Forms.Label

$script:LabelInfo.Text = "Loading system information..."

$script:LabelInfo.Font = New-Object System.Drawing.Font(
    "Consolas",
    8
)

$script:LabelInfo.ForeColor = [System.Drawing.Color]::DarkSlateGray

$script:LabelInfo.Location = New-Object System.Drawing.Point(10, 32)

$script:LabelInfo.AutoSize = $true
$script:LabelInfo.MaximumSize = New-Object System.Drawing.Size(410, 0)

$script:LabelInfo.UseCompatibleTextRendering = $true

$script:LabelInfo.AutoEllipsis = $false

# ==========================================
# ADD CONTROLS
# ==========================================

$script:SystemInformationPanel.Controls.Add($script:LabelTitle)

$script:SystemInformationPanel.Controls.Add($script:LabelInfo)

# ==========================================
# RESPONSIVE WIDTH
# ==========================================

$script:SystemInformationPanel.Add_Resize({

    $maxWidth = [math]::Max(
        100,
        $script:SystemInformationPanel.ClientSize.Width - 30
    )

    $script:LabelInfo.MaximumSize = New-Object System.Drawing.Size($maxWidth, 0)
})