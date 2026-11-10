
<#
.SYNOPSIS
    Apps Installer GUI.

.DESCRIPTION
    Displays applications from Programs.ps1.
    Supports profile filtering and manual selection.
#>

param(
    [string]$ProfileName
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ==========================================
# LOAD BACKEND
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

# ==========================================
# PROFILE DEFINITIONS
# ==========================================

$profiles = @{
    "Profil A" = @("2", "4", "6", "7")
    "Profil B" = @("2", "4")
    "Profil C" = @("6", "7")
}

# ==========================================
# FILTER APPLICATIONS
# ==========================================

if ($ProfileName) {

    if (-not $profiles.ContainsKey($ProfileName)) {

        [System.Windows.Forms.MessageBox]::Show(
            "Unknown profile: $ProfileName",
            "Apps Installer"
        ) | Out-Null

        return
    }

    $selectedIds = $profiles[$ProfileName]

    $appsToDisplay = @(
        $Apps | Where-Object {
            [string]$_.Number -in $selectedIds
        }
    )

}
else {

    $appsToDisplay = @($Apps)
}

# ==========================================
# CHECK APPLICATIONS
# ==========================================

if ($appsToDisplay.Count -eq 0) {

    [System.Windows.Forms.MessageBox]::Show(
        "No applications found for this selection.",
        "Apps Installer"
    ) | Out-Null

    return
}

# ==========================================
# MAIN FORM
# ==========================================

$form = New-Object System.Windows.Forms.Form

$form.Text = if ($ProfileName) {
    "STRAWBERRY WINDOWS - $ProfileName"
}
else {
    "STRAWBERRY WINDOWS - APPS INSTALLER"
}

$form.Size = New-Object System.Drawing.Size(700, 680)
$form.MinimumSize = New-Object System.Drawing.Size(520, 420)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::WhiteSmoke

# ==========================================
# TITLE
# ==========================================

$title = New-Object System.Windows.Forms.Label

$title.Text = if ($ProfileName) {
    "$ProfileName - SELECT APPLICATIONS"
}
else {
    "SELECT APPLICATIONS"
}

$title.Font = New-Object System.Drawing.Font(
    "Segoe UI", 12, [System.Drawing.FontStyle]::Bold
)

$title.Location = New-Object System.Drawing.Point(20, 15)
$title.AutoSize = $true

$form.Controls.Add($title)

# ==========================================
# APPLICATION PANEL
# ==========================================

$appPanel = New-Object System.Windows.Forms.Panel

$appPanel.Location = New-Object System.Drawing.Point(20, 50)
$appPanel.Size = New-Object System.Drawing.Size(645, 480)
$appPanel.Anchor = (
    [System.Windows.Forms.AnchorStyles]::Top -bor
    [System.Windows.Forms.AnchorStyles]::Bottom -bor
    [System.Windows.Forms.AnchorStyles]::Left -bor
    [System.Windows.Forms.AnchorStyles]::Right
)

$appPanel.AutoScroll = $true
$appPanel.BorderStyle = "FixedSingle"
$appPanel.BackColor = [System.Drawing.Color]::White

$form.Controls.Add($appPanel)

# ==========================================
# APPLICATION CHECKBOXES (GROUPED BY CATEGORY)
# ==========================================

$checks = @()

$groupedApps = $appsToDisplay | Group-Object -Property {
    if ($_.Category) { $_.Category } else { "Other" }
} | Sort-Object Name

$y = 10

foreach ($group in $groupedApps) {

    $header = New-Object System.Windows.Forms.Label
    $header.Text = $group.Name
    $header.Font = New-Object System.Drawing.Font(
        "Segoe UI", 10, [System.Drawing.FontStyle]::Bold
    )
    $header.Location = New-Object System.Drawing.Point(10, $y)
    $header.Size = New-Object System.Drawing.Size(600, 22)
    $header.ForeColor = [System.Drawing.Color]::FromArgb(40, 40, 40)

    $appPanel.Controls.Add($header)
    $y += 26

    foreach ($app in ($group.Group | Sort-Object Name)) {

        $cb = New-Object System.Windows.Forms.CheckBox

        $displayText = $app.Name
        if ($app.Version) {
            $displayText += " $($app.Version)"
        }
        if ($app.Description) {
            $displayText += "  -  $($app.Description)"
        }

        $cb.Text = $displayText
        $cb.Tag = $app
        $cb.Checked = $true
        $cb.Location = New-Object System.Drawing.Point(28, $y)
        $cb.Size = New-Object System.Drawing.Size(590, 24)
        $cb.Font = New-Object System.Drawing.Font("Segoe UI", 9)
        $cb.AutoEllipsis = $true

        $appPanel.Controls.Add($cb)
        $checks += $cb

        $y += 26
    }

    $y += 8
}

# ==========================================
# SELECT ALL BUTTON
# ==========================================

$selectAll = New-Object System.Windows.Forms.Button

$selectAll.Text = "Select All"
$selectAll.Location = New-Object System.Drawing.Point(20, 545)
$selectAll.Size = New-Object System.Drawing.Size(115, 35)
$selectAll.Anchor = "Bottom, Left"

$selectAll.Add_Click({

    foreach ($cb in $checks) {
        $cb.Checked = $true
    }

})

$form.Controls.Add($selectAll)

# ==========================================
# DESELECT ALL BUTTON
# ==========================================

$deselectAll = New-Object System.Windows.Forms.Button

$deselectAll.Text = "Deselect All"
$deselectAll.Location = New-Object System.Drawing.Point(145, 545)
$deselectAll.Size = New-Object System.Drawing.Size(115, 35)
$deselectAll.Anchor = "Bottom, Left"

$deselectAll.Add_Click({

    foreach ($cb in $checks) {
        $cb.Checked = $false
    }

})

$form.Controls.Add($deselectAll)

# ==========================================
# INSTALL BUTTON
# ==========================================

$install = New-Object System.Windows.Forms.Button

$install.Text = "Install Selected"
$install.Location = New-Object System.Drawing.Point(495, 545)
$install.Size = New-Object System.Drawing.Size(170, 35)
$install.Anchor = "Bottom, Right"

$install.BackColor = [System.Drawing.Color]::LavenderBlush

$install.Add_Click({

    $selectedApps = @(
        $checks |
            Where-Object { $_.Checked } |
            ForEach-Object { $_.Tag }
    )

    if ($selectedApps.Count -eq 0) {

        [System.Windows.Forms.MessageBox]::Show(
            "Select at least one application.",
            "Apps Installer"
        ) | Out-Null

        return
    }

    $confirmation = [System.Windows.Forms.MessageBox]::Show(
        "Install $($selectedApps.Count) selected applications?",
        "Confirm Installation",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

    if ($confirmation -ne [System.Windows.Forms.DialogResult]::Yes) {
        return
    }

    # ==========================================
    # INSTALL SELECTED APPLICATIONS
    # ==========================================

    $Global:AutoMode = $true

    $installErrors = @()

    foreach ($app in $selectedApps) {

        try {

            Install-OneApp $app -ErrorAction Stop

        }
        catch {

            $installErrors += "$($app.Name): $($_.Exception.Message)"

        }
    }

    # ==========================================
    # RESULTS
    # ==========================================

    if ($installErrors.Count -eq 0) {

        [System.Windows.Forms.MessageBox]::Show(
            "Installation session finished.",
            "Apps Installer",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null

    }
    else {

        [System.Windows.Forms.MessageBox]::Show(
            "Some installations failed:`n`n$($installErrors -join "`n")",
            "Installation Results",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null

    }

    $form.Tag = "Done"
    $form.Close()

})

$form.Controls.Add($install)

# ==========================================
# BACK / CLOSE BUTTON
# ==========================================

$back = New-Object System.Windows.Forms.Button

$back.Text = if ($ProfileName) { "Back" } else { "Close" }

$back.Location = New-Object System.Drawing.Point(20, 590)
$back.Size = New-Object System.Drawing.Size(115, 35)
$back.Anchor = "Bottom, Left"

$back.Add_Click({

    if ($ProfileName) {
        $form.Tag = "Back"
    }
    else {
        $form.Tag = "Closed"
    }

    $form.Close()

})

$form.Controls.Add($back)

# ==========================================
# SHOW FORM
# ==========================================

[void]$form.ShowDialog()

$result = if ($form.Tag) {
    $form.Tag
}
else {
    "Closed"
}

$form.Dispose()

return $result
