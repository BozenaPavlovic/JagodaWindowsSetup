
<#
.SYNOPSIS
    Apps Installer GUI.

.DESCRIPTION
    Displays applications from Programs.ps1.
    Supports profile filtering and manual selection.
#>

param(
    [string]$ProfileName,

    [ValidateSet("Install", "Uninstall")]
    [string]$Mode = "Install"
)

$script:InstallerMode = $Mode

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
# LOAD UNINSTALLER ENGINE (shared for both modes)
# ==========================================

$UninstallerPath = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "Core\Uninstallers\Uninstaller.ps1"

if (-not (Test-Path -LiteralPath $UninstallerPath -PathType Leaf)) {

    [System.Windows.Forms.MessageBox]::Show(
        "Uninstaller engine not found:`n$UninstallerPath",
        "Apps Installer",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null

    return
}

try {

    . $UninstallerPath

}
catch {

    [System.Windows.Forms.MessageBox]::Show(
        "Failed to load uninstaller engine: $($_.Exception.Message)",
        "Apps Installer",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null

    return

}

# ==========================================
# LOAD OBZ BACKEND (independent of standard engine)
# ==========================================

$script:ObzAvailable = $false
$script:ObzRefreshResult = $null

$ObzRoot = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "Core\OBZ"
$ObzProviderPath = Join-Path $ObzRoot "OBZApplicationProvider.ps1"
$ObzInstallerPath = Join-Path $ObzRoot "OBZInstaller.ps1"

if ((Test-Path -LiteralPath $ObzProviderPath -PathType Leaf) -and (Test-Path -LiteralPath $ObzInstallerPath -PathType Leaf)) {

    try {

        . $ObzProviderPath
        . $ObzInstallerPath

        $script:ObzAvailable = $true
        $script:ObzRefreshResult = Update-OBZApplicationDatabase

    }
    catch {

        Write-Warning "OBZ backend failed to load: $($_.Exception.Message)"

    }

}

# ==========================================
# LOAD PROFILE BACKEND (for custom profiles)
# ==========================================

$guiRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

$profileModelPath = Join-Path $guiRoot "GUI\Models\ProfileModel.ps1"
$profileControllerPath = Join-Path $guiRoot "GUI\Controllers\ProfileController.ps1"

try {
    . $profileModelPath
    . $profileControllerPath
}
catch {
    [System.Windows.Forms.MessageBox]::Show(
        "Failed to load profile backend:`n$($_.Exception.Message)",
        "Apps Installer",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
    return
}

# ==========================================
# LOAD CUSTOM PROFILES
# ==========================================

$script:CustomProfiles = @()
if (Get-Command Get-AllCustomProfiles -ErrorAction SilentlyContinue) {
    $script:CustomProfiles = @(Get-AllCustomProfiles)
}

# ==========================================
# MAIN FORM
# ==========================================

$form = New-Object System.Windows.Forms.Form

$form.Text = if ($script:InstallerMode -eq "Uninstall") {
    if ($ProfileName) {
        "STRAWBERRY WINDOWS - $ProfileName - UNINSTALL"
    }
    else {
        "STRAWBERRY WINDOWS - APP UNINSTALLER"
    }
}
else {
    if ($ProfileName) {
        "STRAWBERRY WINDOWS - $ProfileName"
    }
    else {
        "STRAWBERRY WINDOWS - APPS INSTALLER"
    }
}

$form.Size = New-Object System.Drawing.Size(700, 680)
$form.MinimumSize = New-Object System.Drawing.Size(520, 420)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::WhiteSmoke

# ==========================================
# TITLE
# ==========================================

$title = New-Object System.Windows.Forms.Label

$title.Text = if ($script:InstallerMode -eq "Uninstall") {
    if ($ProfileName) {
        "$ProfileName - UNINSTALL APPLICATIONS"
    }
    else {
        "UNINSTALL APPLICATIONS"
    }
}
else {
    if ($ProfileName) {
        "$ProfileName - SELECT APPLICATIONS"
    }
    else {
        "SELECT APPLICATIONS"
    }
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

$appPanel.Location = New-Object System.Drawing.Point(20, 215)
$appPanel.Size = New-Object System.Drawing.Size(645, 315)
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
# HOVER MOUSE WHEEL SCROLL (no click required)
# ==========================================

$appPanel.Add_MouseWheel({

    param($sender, $eventArgs)

    $pos = $sender.AutoScrollPosition

    $sender.AutoScrollPosition = New-Object System.Drawing.Point(
        $pos.X,
        $pos.Y - $eventArgs.Delta
    )

})

# ==========================================
# OBZ APPLICATION PANEL (TOP)
# ==========================================

$obzPanel = New-Object System.Windows.Forms.Panel

$obzPanel.Location = New-Object System.Drawing.Point(20, 50)
$obzPanel.Size = New-Object System.Drawing.Size(645, 150)
$obzPanel.Anchor = (
    [System.Windows.Forms.AnchorStyles]::Top -bor
    [System.Windows.Forms.AnchorStyles]::Left -bor
    [System.Windows.Forms.AnchorStyles]::Right
)

$obzPanel.AutoScroll = $true
$obzPanel.BorderStyle = "FixedSingle"
$obzPanel.BackColor = [System.Drawing.Color]::White
$obzPanel.Visible = ($script:InstallerMode -eq "Install")

$form.Controls.Add($obzPanel)

# ==========================================
# HOVER MOUSE WHEEL SCROLL (no click required)
# ==========================================

$obzPanel.Add_MouseWheel({

    param($sender, $eventArgs)

    $pos = $sender.AutoScrollPosition

    $sender.AutoScrollPosition = New-Object System.Drawing.Point(
        $pos.X,
        $pos.Y - $eventArgs.Delta
    )

})

# ==========================================
# APPLICATION LIST REFRESH
# ==========================================

function Refresh-AppList {

    $script:checks = @()
    $appPanel.Controls.Clear()

    if ($script:InstallerMode -eq "Uninstall") {

        $installed = @(Get-InstalledPrograms)
        $appsToDisplay = @()
        $seen = @{}

        foreach ($inst in $installed) {

            $found = $Global:Apps | Where-Object {
                $inst.DisplayName -like "*$($_.Name)*" -or
                $inst.DisplayName -like "*$($_.Match)*" -or
                $inst.Name -like "*$($_.Name)*" -or
                $inst.Name -like "*$($_.Match)*"
            } | Select-Object -First 1

            if (-not $found) {
                continue
            }

            $key = if ($null -ne $found.Number) { [string]$found.Number } else { [string]$found.Name }

            if (-not $seen.ContainsKey($key)) {

                $entry = [PSCustomObject]@{
                    Number            = $found.Number
                    Name              = $found.Name
                    DisplayName       = $found.DisplayName
                    Category          = $found.Category
                    Version           = $found.Version
                    Description       = $found.Description
                    WingetID          = $found.WingetID
                    Match             = $found.Match
                    Publisher         = $found.Publisher
                    File              = $found.File
                    Type              = $found.Type
                    InstalledPrograms = @()
                    InstalledVersion  = $null
                }

                $seen[$key] = $entry
                $appsToDisplay += $entry
            }

            $seen[$key].InstalledPrograms += [PSCustomObject]@{
                DisplayName          = $inst.DisplayName
                DisplayVersion       = $inst.DisplayVersion
                Name                 = $inst.Name
                PSChildName          = $inst.PSChildName
                PackageFullName      = $inst.PackageFullName
                UninstallString      = $inst.UninstallString
                QuietUninstallString = $inst.QuietUninstallString
                Source               = $inst.Source
            }

            if (-not $seen[$key].InstalledVersion -and $inst.DisplayVersion) {
                $seen[$key].InstalledVersion = $inst.DisplayVersion
            }
        }

    }
    else {

        if ($ProfileName) {

            $profile = $script:CustomProfiles | Where-Object { $_.Name -eq $ProfileName } | Select-Object -First 1
            if (-not $profile) {
                return
            }

            $resolution = Resolve-ProfileApplications -Profile $profile

            $appsToDisplay = @($resolution.Resolved)

        }
        else {

            $appsToDisplay = @($Apps)
        }
    }

    if ($appsToDisplay.Count -eq 0) {

        return
    }

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

            $displayText = if ($app.DisplayName) { $app.DisplayName } else { $app.Name }
            
            # In uninstall mode, show installed version if available
            $versionToShow = $null
            if ($script:InstallerMode -eq "Uninstall" -and $app.InstalledVersion) {
                $versionToShow = $app.InstalledVersion
            }
            elseif ($app.Version) {
                $versionToShow = $app.Version
            }
            
            if ($versionToShow) {
                $displayText += " $versionToShow"
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
            $script:checks += $cb

            $y += 26
        }

        $y += 8
    }
}

# ==========================================
# OBZ APPLICATION LIST REFRESH
# ==========================================

function Refresh-OBZList {

    $script:obzChecks = @()

    if (-not $obzPanel) {
        return
    }

    $obzPanel.Controls.Clear()

    $header = New-Object System.Windows.Forms.Label
    $header.Text = "OBZ APPLICATIONS"
    $header.Font = New-Object System.Drawing.Font(
        "Segoe UI", 10, [System.Drawing.FontStyle]::Bold
    )
    $header.Location = New-Object System.Drawing.Point(10, 6)
    $header.Size = New-Object System.Drawing.Size(400, 22)
    $header.ForeColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
    $obzPanel.Controls.Add($header)

    $y = 34

    if (-not $script:ObzAvailable) {
        $lbl = New-Object System.Windows.Forms.Label
        $lbl.Text = "OBZ unavailable."
        $lbl.Location = New-Object System.Drawing.Point(10, $y)
        $lbl.Size = New-Object System.Drawing.Size(600, 22)
        $obzPanel.Controls.Add($lbl)
        return
    }

    $obzApps = @(Get-OBZApplication)

    if ($obzApps.Count -eq 0) {
        $lbl = New-Object System.Windows.Forms.Label
        $lbl.Text = $Global:OBZSettings.Messages.NoApplicationsAvailable
        $lbl.Location = New-Object System.Drawing.Point(10, $y)
        $lbl.Size = New-Object System.Drawing.Size(600, 22)
        $obzPanel.Controls.Add($lbl)
        return
    }

    foreach ($obzApp in ($obzApps | Sort-Object Name)) {

        $cb = New-Object System.Windows.Forms.CheckBox
        $cb.Text = "$($obzApp.Name)  ($($obzApp.FileName))"
        $cb.Tag = $obzApp
        $cb.Checked = $true
        $cb.Location = New-Object System.Drawing.Point(28, $y)
        $cb.Size = New-Object System.Drawing.Size(600, 24)
        $cb.Font = New-Object System.Drawing.Font("Segoe UI", 9)
        $cb.AutoEllipsis = $true

        $obzPanel.Controls.Add($cb)
        $script:obzChecks += $cb

        $y += 26
    }
}

# ==========================================
# INITIAL APPLICATION LIST
# ==========================================

Refresh-AppList
Refresh-OBZList

if ($script:checks.Count -eq 0 -and $script:obzChecks.Count -eq 0) {

    [System.Windows.Forms.MessageBox]::Show(
        "No applications found for this selection.",
        "Apps Installer"
    ) | Out-Null

    return
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

    foreach ($cb in $script:checks) {
        $cb.Checked = $true
    }

    foreach ($cb in $script:obzChecks) {
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

    foreach ($cb in $script:checks) {
        $cb.Checked = $false
    }

    foreach ($cb in $script:obzChecks) {
        $cb.Checked = $false
    }

})

$form.Controls.Add($deselectAll)

# ==========================================
# MODE TOGGLE BUTTON
# ==========================================

$toggleMode = New-Object System.Windows.Forms.Button

$toggleMode.Text = if ($script:InstallerMode -eq "Uninstall") { "Switch to Install Mode" } else { "Switch to Uninstall Mode" }
$toggleMode.Location = New-Object System.Drawing.Point(270, 545)
$toggleMode.Size = New-Object System.Drawing.Size(160, 35)
$toggleMode.Anchor = "Bottom, Left"

$toggleMode.Add_Click({

    $script:InstallerMode = if ($script:InstallerMode -eq "Uninstall") { "Install" } else { "Uninstall" }

    $toggleMode.Text = if ($script:InstallerMode -eq "Uninstall") { "Switch to Install Mode" } else { "Switch to Uninstall Mode" }

    $form.Text = if ($script:InstallerMode -eq "Uninstall") {
        if ($ProfileName) {
            "STRAWBERRY WINDOWS - $ProfileName - UNINSTALL"
        }
        else {
            "STRAWBERRY WINDOWS - APP UNINSTALLER"
        }
    }
    else {
        if ($ProfileName) {
            "STRAWBERRY WINDOWS - $ProfileName"
        }
        else {
            "STRAWBERRY WINDOWS - APPS INSTALLER"
        }
    }

    $title.Text = if ($script:InstallerMode -eq "Uninstall") {
        if ($ProfileName) {
            "$ProfileName - UNINSTALL APPLICATIONS"
        }
        else {
            "UNINSTALL APPLICATIONS"
        }
    }
    else {
        if ($ProfileName) {
            "$ProfileName - SELECT APPLICATIONS"
        }
        else {
            "SELECT APPLICATIONS"
        }
    }

    $install.Text = if ($script:InstallerMode -eq "Uninstall") { "Uninstall Selected" } else { "Install Selected" }

    $obzPanel.Visible = ($script:InstallerMode -eq "Install")

    Refresh-AppList
    Refresh-OBZList

})

$form.Controls.Add($toggleMode)

# ==========================================
# INSTALL BUTTON
# ==========================================

$install = New-Object System.Windows.Forms.Button

$install.Text = if ($script:InstallerMode -eq "Uninstall") { "Uninstall Selected" } else { "Install Selected" }
$install.Location = New-Object System.Drawing.Point(495, 545)
$install.Size = New-Object System.Drawing.Size(170, 35)
$install.Anchor = "Bottom, Right"

$install.BackColor = [System.Drawing.Color]::LavenderBlush

$install.Add_Click({

    if (-not $install.Enabled) {
        return
    }

    $selectedApps = @(
        $script:checks |
            Where-Object { $_.Checked } |
            ForEach-Object { $_.Tag }
    )

    $selectedObz = @()
    if ($script:InstallerMode -eq "Install") {
        $selectedObz = @(
            $script:obzChecks |
                Where-Object { $_.Checked } |
                ForEach-Object { $_.Tag }
        )
    }

    if ($selectedApps.Count -eq 0 -and $selectedObz.Count -eq 0) {

        [System.Windows.Forms.MessageBox]::Show(
            "Select at least one application.",
            "Apps Installer"
        ) | Out-Null

        return
    }

    $actionWord = if ($script:InstallerMode -eq "Uninstall") { "Uninstall" } else { "Install" }

    $confirmation = [System.Windows.Forms.MessageBox]::Show(
        "$actionWord $(($selectedApps.Count + $selectedObz.Count)) selected applications?",
        $(if ($script:InstallerMode -eq "Uninstall") { "Confirm Uninstall" } else { "Confirm Installation" }),
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

    if ($confirmation -ne [System.Windows.Forms.DialogResult]::Yes) {
        return
    }

    # ==========================================
    # ACTION SELECTED APPLICATIONS
    # ==========================================
    $Global:AutoMode = $true

    $install.Enabled = $false
    $form.Enabled = $false
    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor

    try {

        if ($script:InstallerMode -eq "Uninstall") {

            $uninstallResults = Uninstall-MultipleApps -Programs $selectedApps -Silent

            $installErrors = @()

            foreach ($r in $uninstallResults) {
                if ($r.Status -eq "FAILED") {
                    $installErrors += "$($r.ProgramName): $($r.Message)"
                }
            }

        }
        else {

            $installErrors = @()

            # --- OBZ applications (independent backend) ---
            if ($selectedObz.Count -gt 0 -and $script:ObzAvailable) {

                $obzTotal = $selectedObz.Count
                $obzCurrent = 0

                foreach ($obzApp in $selectedObz) {

                    $obzCurrent++

                    if (Get-Command Write-Host -ErrorAction SilentlyContinue) {
                        Write-Host "`nOBZ Progress: $obzCurrent of $obzTotal applications" -ForegroundColor Cyan
                    }

                    $obzResult = Install-OBZApplication -Id $obzApp.Id

                    if ($obzResult.Status -ne "Success") {
                        $installErrors += "$($obzApp.Name): $($obzResult.Message)"
                    }

                    [System.Windows.Forms.Application]::DoEvents()
                }

            }

            # --- Standard applications (existing backend) ---
            $totalApps = @($selectedApps).Count
            $currentApp = 0

            foreach ($app in $selectedApps) {

                $currentApp++

                try {

                    if (Get-Command Write-Host -ErrorAction SilentlyContinue) {
                        Write-Host "`nProgress: $currentApp of $totalApps applications" -ForegroundColor Cyan
                    }

                    Install-OneApp -App $app -Index $currentApp -Total $totalApps -ErrorAction Stop

                }

                catch {

                    $installErrors += "$($app.Name): $($_.Exception.Message)"

                }

                [System.Windows.Forms.Application]::DoEvents()
            }

        }
    }
    finally {
        $install.Enabled = $true
        $form.Enabled = $true
        $form.Cursor = [System.Windows.Forms.Cursors]::Default
    }

    # ==========================================
    # RESULTS
    # ==========================================

    if ($installErrors.Count -eq 0) {

        [System.Windows.Forms.MessageBox]::Show(
            $(if ($script:InstallerMode -eq "Uninstall") { "Uninstall session finished." } else { "Installation session finished." }),
            "Apps Installer",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null

    }
    else {

        [System.Windows.Forms.MessageBox]::Show(
            $(if ($script:InstallerMode -eq "Uninstall") { "Some uninstalls failed:`n`n$($installErrors -join "`n")" } else { "Some installations failed:`n`n$($installErrors -join "`n")" }),
            $(if ($script:InstallerMode -eq "Uninstall") { "Uninstall Results" } else { "Installation Results" }),
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
