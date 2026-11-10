
<#
.SYNOPSIS
    Theme Manager GUI.

.DESCRIPTION
    Displays available themes and applies them using the shared
    Core\ThemeManager.ps1 backend.
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ==========================================
# LOAD THEME BACKEND
# ==========================================

try {
    . "$PSScriptRoot\LoadInstallerBackend.ps1"
}
catch {
    [System.Windows.Forms.MessageBox]::Show(
        $_.Exception.Message,
        "Backend Error",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null

    return
}

if (-not (Get-Command Invoke-Theme -ErrorAction SilentlyContinue)) {
    $fallbackThemeManager = Join-Path $PSScriptRoot "..\..\Core\ThemeManager.ps1"
    if (Test-Path -LiteralPath $fallbackThemeManager) {
        . $fallbackThemeManager
        if (Get-Command Initialize-ThemeBackend -ErrorAction SilentlyContinue) {
            Initialize-ThemeBackend | Out-Null
        }
    }
} else {
    # Ensure latest engine/definitions are loaded in long-lived sessions
    if (Get-Command Initialize-ThemeBackend -ErrorAction SilentlyContinue) {
        Initialize-ThemeBackend | Out-Null
    }
}

if (-not (Get-Command Invoke-Theme -ErrorAction SilentlyContinue) -or -not (Get-Command Get-ThemeCatalog -ErrorAction SilentlyContinue)) {
    [System.Windows.Forms.MessageBox]::Show(
        "Theme manager functions could not be loaded.",
        "Backend Error",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
    return
}

# ==========================================
# THEME DEFINITIONS
# ==========================================

$availableThemes = @(Get-ThemeCatalog)

if ($availableThemes.Count -eq 0) {
    [System.Windows.Forms.MessageBox]::Show(
        "No themes available in the theme manager.",
        "Theme Manager",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null

    return
}

# Shared state used by all event handlers.
$state = [PSCustomObject]@{
    SelectedTheme = $null
}

# ==========================================
# MAIN FORM
# ==========================================

$form = New-Object System.Windows.Forms.Form

$form.Text = "STRAWBERRY WINDOWS - THEME MANAGER"
$form.Size = New-Object System.Drawing.Size(400, 380)
$form.MinimumSize = New-Object System.Drawing.Size(350, 300)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::WhiteSmoke
$form.MaximizeBox = $false

# ==========================================
# TITLE
# ==========================================

$title = New-Object System.Windows.Forms.Label
$title.Text = "SELECT A WINDOWS THEME"
$title.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    12,
    [System.Drawing.FontStyle]::Bold
)
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(20, 15)

$form.Controls.Add($title)

# ==========================================
# THEME BUTTONS / ACTIONS
# ==========================================

$baseY = 55
$buttonSpacing = 48
$actionsY = $baseY + ($availableThemes.Count * $buttonSpacing) + 10

# Apply button created before theme buttons so click handlers can enable it.
$apply = New-Object System.Windows.Forms.Button
$apply.Text = "Apply Theme"
$apply.Location = New-Object System.Drawing.Point(30, $actionsY)
$apply.Size = New-Object System.Drawing.Size(150, 35)
$apply.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$apply.BackColor = [System.Drawing.Color]::LavenderBlush
$apply.Enabled = $false

$y = $baseY

foreach ($theme in $availableThemes) {

    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $theme.Name
    $btn.Tag = $theme
    $btn.Location = New-Object System.Drawing.Point(30, $y)
    $btn.Size = New-Object System.Drawing.Size(320, 40)
    $btn.Font = New-Object System.Drawing.Font("Segoe UI", 10)

    # Set button background color.
    try {
        $rgb = $theme.Color.Substring(1)

        $r = [Convert]::ToInt32($rgb.Substring(0, 2), 16)
        $g = [Convert]::ToInt32($rgb.Substring(2, 2), 16)
        $b = [Convert]::ToInt32($rgb.Substring(4, 2), 16)

        $btn.BackColor = [System.Drawing.Color]::FromArgb($r, $g, $b)
    }
    catch {
        # Keep the default button color if parsing fails.
    }

    # Store the selected theme in the shared state object.
    $btn.Add_Click({
        $state.SelectedTheme = $this.Tag

        $apply.Enabled = $true
    }.GetNewClosure())

    $form.Controls.Add($btn)

    $y += $buttonSpacing
}

# ==========================================
# APPLY BUTTON
# ==========================================

$apply.Add_Click({

    if ($null -eq $state.SelectedTheme) {
        [System.Windows.Forms.MessageBox]::Show(
            "Please select a theme first.",
            "Theme Manager",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null

        return
    }

    $themeId = $state.SelectedTheme.Id
    $themeName = $state.SelectedTheme.Name

    try {
        $ErrorActionPreference = "Stop"

        Invoke-Theme -ThemeId $themeId

        [System.Windows.Forms.MessageBox]::Show(
            "$themeName theme applied successfully.",
            "Theme Manager",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Failed to apply $themeName theme:`n$($_.Exception.Message)",
            "Theme Manager",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }

}.GetNewClosure())

$form.Controls.Add($apply)

# ==========================================
# CLOSE BUTTON
# ==========================================

$close = New-Object System.Windows.Forms.Button
$close.Text = "Close"
$close.Location = New-Object System.Drawing.Point(210, $actionsY)
$close.Size = New-Object System.Drawing.Size(150, 35)
$close.Font = New-Object System.Drawing.Font("Segoe UI", 10)

$close.Add_Click({
    $form.Close()
}.GetNewClosure())

$form.Controls.Add($close)

# ==========================================
# SHOW FORM
# ==========================================

[void]$form.ShowDialog()
$form.Dispose()
