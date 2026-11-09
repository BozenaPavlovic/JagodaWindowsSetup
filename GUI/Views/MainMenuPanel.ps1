<#
.SYNOPSIS
    Main Menu Panel View.
#>

# ==========================================
# MAIN MENU PANEL
# ==========================================

$script:MainMenuPanel = New-Object System.Windows.Forms.Panel

$script:MainMenuPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$script:MainMenuPanel.BackColor = [System.Drawing.Color]::WhiteSmoke
$script:MainMenuPanel.Padding = New-Object System.Windows.Forms.Padding(20)

# ==========================================
# MENU TITLE
# ==========================================

$script:MenuTitle = New-Object System.Windows.Forms.Label

$script:MenuTitle.Text = "STRAWBERRY WINDOWS"

$script:MenuTitle.Font = New-Object System.Drawing.Font(
    "Segoe UI", 16, [System.Drawing.FontStyle]::Bold
)

$script:MenuTitle.ForeColor = [System.Drawing.Color]::DarkMagenta
$script:MenuTitle.AutoSize = $true
$script:MenuTitle.Location = New-Object System.Drawing.Point(45, 20)

$script:MainMenuPanel.Controls.Add($script:MenuTitle)

# ==========================================
# MENU DESCRIPTION
# ==========================================

$script:MenuDescription = New-Object System.Windows.Forms.Label

$script:MenuDescription.Text = "System management and configuration"
$script:MenuDescription.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$script:MenuDescription.ForeColor = [System.Drawing.Color]::DimGray
$script:MenuDescription.AutoSize = $true
$script:MenuDescription.Location = New-Object System.Drawing.Point(47, 52)

$script:MainMenuPanel.Controls.Add($script:MenuDescription)

# ==========================================
# MENU BUTTONS
# ==========================================

$script:MenuButtons = @()

$script:MenuItems = @(
    "Profile Installer",
    "Apps Installer",
    "Theme Manager",
    "Wallpaper Manager",
    "Log Viewer",
    "About"
)

$buttonWidth = 290
$buttonHeight = 40
$buttonSpacing = 48

$y = 95

foreach ($item in $script:MenuItems) {

    $btn = New-Object System.Windows.Forms.Button

    $btn.Text = $item
    $btn.Tag = $item

    $btn.Location = New-Object System.Drawing.Point(45, $y)

    $btn.Size = New-Object System.Drawing.Size(
        $buttonWidth,
        $buttonHeight
    )

    $btn.Font = New-Object System.Drawing.Font("Segoe UI", 10)

    $btn.BackColor = [System.Drawing.Color]::White
    $btn.ForeColor = [System.Drawing.Color]::DarkSlateGray

    $btn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btn.FlatAppearance.BorderColor = [System.Drawing.Color]::LightGray
    $btn.FlatAppearance.BorderSize = 1

    $btn.Cursor = [System.Windows.Forms.Cursors]::Hand

    $script:MenuButtons += $btn

    $script:MainMenuPanel.Controls.Add($btn)

    $y += $buttonSpacing
}

# ==========================================
# EXIT BUTTON
# ==========================================

$script:ExitButton = New-Object System.Windows.Forms.Button

$script:ExitButton.Text = "Exit"

$script:ExitButton.Location = New-Object System.Drawing.Point(
    45, ($y + 5)
)

$script:ExitButton.Size = New-Object System.Drawing.Size(
    $buttonWidth,
    $buttonHeight
)

$script:ExitButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)

$script:ExitButton.BackColor = [System.Drawing.Color]::White
$script:ExitButton.ForeColor = [System.Drawing.Color]::DarkRed

$script:ExitButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$script:ExitButton.FlatAppearance.BorderColor = [System.Drawing.Color]::LightGray

$script:ExitButton.Cursor = [System.Windows.Forms.Cursors]::Hand

$script:MainMenuPanel.Controls.Add($script:ExitButton)

# ==========================================
# RESPONSIVE LAYOUT
# ==========================================

$script:MainMenuPanel.Add_Resize({

    $panelWidth = $script:MainMenuPanel.ClientSize.Width

    $centerX = [math]::Max(
        20,
        [int](($panelWidth - $buttonWidth) / 2)
    )

    # TITLE
    $script:MenuTitle.Left = [int](
        ($panelWidth - $script:MenuTitle.Width) / 2
    )

    # DESCRIPTION
    $script:MenuDescription.Left = [int](
        ($panelWidth - $script:MenuDescription.Width) / 2
    )

    # BUTTONS
    foreach ($btn in $script:MenuButtons) {
        $btn.Left = $centerX
    }

    # EXIT
    $script:ExitButton.Left = $centerX
})