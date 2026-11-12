<#
.SYNOPSIS
    Installation Manager GUI - custom profiles (Phase 2).
    View: uses ProfileModel/ProfileController for persistence and operations.
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ==========================================
# LOAD MODEL / CONTROLLER (MVC)
# ==========================================

. (Join-Path $PSScriptRoot "..\Models\ProfileModel.ps1")
. (Join-Path $PSScriptRoot "..\Controllers\ProfileController.ps1")

# ==========================================
# LOAD APPLICATION DATABASE (read-only)
# ==========================================

try {
    $coreDbPath = Join-Path $PSScriptRoot "..\..\Core\ProgramDatabase.ps1"
    if (-not (Test-Path -LiteralPath $coreDbPath -PathType Leaf)) {
        throw "Application database not found: $coreDbPath"
    }
    . $coreDbPath
}
catch {
    [System.Windows.Forms.MessageBox]::Show(
        "Failed to load application database:`n$($_.Exception.Message)",
        "Installation Manager",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
    return
}

$script:AllApps = @($Global:Apps | Where-Object { $_ -and $_.Name })

$script:CurrentView = "Overview" # Overview | Create | Edit
$script:EditingProfileId = $null

# ==========================================
# MAIN FORM
# ==========================================

$form = New-Object System.Windows.Forms.Form
$form.Text = "STRAWBERRY WINDOWS - INSTALLATION MANAGER"
$form.Size = New-Object System.Drawing.Size(980, 720)
$form.MinimumSize = New-Object System.Drawing.Size(860, 620)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::WhiteSmoke
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

# ==========================================
# OVERVIEW PANEL
# ==========================================

$overviewPanel = New-Object System.Windows.Forms.Panel
$overviewPanel.Dock = "Fill"
$overviewPanel.BackColor = [System.Drawing.Color]::WhiteSmoke
$form.Controls.Add($overviewPanel)

$ovTitle = New-Object System.Windows.Forms.Label
$ovTitle.Text = "INSTALLATION MANAGER"
$ovTitle.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$ovTitle.AutoSize = $true
$ovTitle.Location = New-Object System.Drawing.Point(20, 15)
$overviewPanel.Controls.Add($ovTitle)

$ovSubtitle = New-Object System.Windows.Forms.Label
$ovSubtitle.Text = "Manage custom installation profiles."
$ovSubtitle.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$ovSubtitle.ForeColor = [System.Drawing.Color]::DimGray
$ovSubtitle.AutoSize = $true
$ovSubtitle.Location = New-Object System.Drawing.Point(22, 45)
$overviewPanel.Controls.Add($ovSubtitle)

$profilesGroup = New-Object System.Windows.Forms.GroupBox
$profilesGroup.Text = "Profiles"
$profilesGroup.Location = New-Object System.Drawing.Point(20, 75)
$profilesGroup.Size = New-Object System.Drawing.Size(920, 520)
$profilesGroup.Anchor = "Top,Bottom,Left,Right"
$profilesGroup.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$overviewPanel.Controls.Add($profilesGroup)

$profilesList = New-Object System.Windows.Forms.FlowLayoutPanel
$profilesList.Location = New-Object System.Drawing.Point(15, 30)
$profilesList.Size = New-Object System.Drawing.Size(890, 470)
$profilesList.Anchor = "Top,Bottom,Left,Right"
$profilesList.AutoScroll = $true
$profilesList.FlowDirection = "TopDown"
$profilesList.WrapContents = $false
$profilesList.BackColor = [System.Drawing.Color]::White
$profilesList.BorderStyle = "FixedSingle"
$profilesGroup.Controls.Add($profilesList)

$btnCreate = New-Object System.Windows.Forms.Button
$btnCreate.Text = "Create New Profile"
$btnCreate.Size = New-Object System.Drawing.Size(170, 36)
$btnCreate.Location = New-Object System.Drawing.Point(20, 610)
$btnCreate.Anchor = "Bottom,Left"
$btnCreate.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$overviewPanel.Controls.Add($btnCreate)

$btnCloseOverview = New-Object System.Windows.Forms.Button
$btnCloseOverview.Text = "Close"
$btnCloseOverview.Size = New-Object System.Drawing.Size(110, 36)
$btnCloseOverview.Location = New-Object System.Drawing.Point(830, 610)
$btnCloseOverview.Anchor = "Bottom,Right"
$btnCloseOverview.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$overviewPanel.Controls.Add($btnCloseOverview)

# ==========================================
# EDITOR PANEL
# ==========================================

$editorPanel = New-Object System.Windows.Forms.Panel
$editorPanel.Dock = "Fill"
$editorPanel.BackColor = [System.Drawing.Color]::WhiteSmoke
$editorPanel.Visible = $false
$form.Controls.Add($editorPanel)

$edTitle = New-Object System.Windows.Forms.Label
$edTitle.Text = "CREATE PROFILE"
$edTitle.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$edTitle.AutoSize = $true
$edTitle.Location = New-Object System.Drawing.Point(20, 15)
$editorPanel.Controls.Add($edTitle)

$lblName = New-Object System.Windows.Forms.Label
$lblName.Text = "Profile name:"
$lblName.AutoSize = $true
$lblName.Location = New-Object System.Drawing.Point(22, 55)
$lblName.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$editorPanel.Controls.Add($lblName)

$txtProfileName = New-Object System.Windows.Forms.TextBox
$txtProfileName.Location = New-Object System.Drawing.Point(120, 51)
$txtProfileName.Size = New-Object System.Drawing.Size(320, 25)
$txtProfileName.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$editorPanel.Controls.Add($txtProfileName)

$appsGroup = New-Object System.Windows.Forms.GroupBox
$appsGroup.Text = "Applications"
$appsGroup.Location = New-Object System.Drawing.Point(20, 90)
$appsGroup.Size = New-Object System.Drawing.Size(920, 500)
$appsGroup.Anchor = "Top,Bottom,Left,Right"
$appsGroup.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$editorPanel.Controls.Add($appsGroup)

$lblSearch = New-Object System.Windows.Forms.Label
$lblSearch.Text = "Search:"
$lblSearch.AutoSize = $true
$lblSearch.Location = New-Object System.Drawing.Point(15, 32)
$lblSearch.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
$appsGroup.Controls.Add($lblSearch)

$txtSearch = New-Object System.Windows.Forms.TextBox
$txtSearch.Location = New-Object System.Drawing.Point(70, 28)
$txtSearch.Size = New-Object System.Drawing.Size(300, 25)
$txtSearch.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
$appsGroup.Controls.Add($txtSearch)

$btnSelectAll = New-Object System.Windows.Forms.Button
$btnSelectAll.Text = "Select All"
$btnSelectAll.Location = New-Object System.Drawing.Point(385, 26)
$btnSelectAll.Size = New-Object System.Drawing.Size(100, 28)
$btnSelectAll.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
$appsGroup.Controls.Add($btnSelectAll)

$btnDeselectAll = New-Object System.Windows.Forms.Button
$btnDeselectAll.Text = "Deselect All"
$btnDeselectAll.Location = New-Object System.Drawing.Point(495, 26)
$btnDeselectAll.Size = New-Object System.Drawing.Size(100, 28)
$btnDeselectAll.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
$appsGroup.Controls.Add($btnDeselectAll)

$lblCounter = New-Object System.Windows.Forms.Label
$lblCounter.Text = "Selected: 0"
$lblCounter.AutoSize = $true
$lblCounter.Location = New-Object System.Drawing.Point(615, 31)
$lblCounter.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$appsGroup.Controls.Add($lblCounter)

$appListPanel = New-Object System.Windows.Forms.Panel
$appListPanel.Location = New-Object System.Drawing.Point(15, 62)
$appListPanel.Size = New-Object System.Drawing.Size(890, 430)
$appListPanel.Anchor = "Top,Bottom,Left,Right"
$appListPanel.AutoScroll = $true
$appListPanel.BorderStyle = "FixedSingle"
$appListPanel.BackColor = [System.Drawing.Color]::White
$appsGroup.Controls.Add($appListPanel)

# Dedicated bottom action area - always visible, outside scrollable application list
$editorActionsPanel = New-Object System.Windows.Forms.Panel
$editorActionsPanel.Dock = "Bottom"
$editorActionsPanel.Height = 56
$editorActionsPanel.BackColor = [System.Drawing.Color]::WhiteSmoke
$editorActionsPanel.Padding = New-Object System.Windows.Forms.Padding(10, 8, 20, 8)
$editorPanel.Controls.Add($editorActionsPanel)

$btnSave = New-Object System.Windows.Forms.Button
$btnSave.Text = "Create Profile"
$btnSave.Size = New-Object System.Drawing.Size(150, 36)
$btnSave.Anchor = "Top,Right"
$btnSave.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$btnSave.BackColor = [System.Drawing.Color]::LavenderBlush

$btnCancel = New-Object System.Windows.Forms.Button
$btnCancel.Text = "Cancel"
$btnCancel.Size = New-Object System.Drawing.Size(110, 36)
$btnCancel.Anchor = "Top,Right"
$btnCancel.Font = New-Object System.Drawing.Font("Segoe UI", 9)

# Right-align buttons inside action panel
$btnCancel.Location = New-Object System.Drawing.Point(($editorActionsPanel.ClientSize.Width - $btnCancel.Width - 12), 10)
$btnSave.Location = New-Object System.Drawing.Point(($btnCancel.Left - $btnSave.Width - 10), 10)

$editorActionsPanel.Controls.Add($btnSave)
$editorActionsPanel.Controls.Add($btnCancel)

# Keep action buttons right-aligned on resize and reserve space above action panel
$editorActionsPanel.Add_Resize({
    $btnCancel.Left = [Math]::Max(10, $editorActionsPanel.ClientSize.Width - $btnCancel.Width - 12)
    $btnSave.Left = [Math]::Max(10, $btnCancel.Left - $btnSave.Width - 10)
}.GetNewClosure())

$editorPanel.Add_Resize({
    $h = $editorPanel.ClientSize.Height - $appsGroup.Top - $editorActionsPanel.Height - 8
    if ($h -lt 150) { $h = 150 }
    $appsGroup.Height = $h
}.GetNewClosure())

# Ensure docking/layout order: bottom action area stays fixed, apps group fills space above it
$editorActionsPanel.BringToFront()

# ==========================================
# EDITOR HELPERS
# ==========================================

$script:AppCheckBoxes = @()

function Update-SelectedCounter {
    $count = 0
    foreach ($cb in $script:AppCheckBoxes) {
        if ($cb.Checked) { $count++ }
    }
    $lblCounter.Text = "Selected: $count"
}

function Get-AppDisplayText {
    param($app)
    $text = [string]$app.Name
    if ($app.Version) { $text += " $($app.Version)" }
    if ($app.Category) { $text += " [$($app.Category)]" }
    if ($app.Description) { $text += " - $($app.Description)" }
    return $text
}

function Build-AppCheckboxList {
    param([string[]]$selectedIds)

    $appListPanel.SuspendLayout()
    $appListPanel.Controls.Clear()
    $script:AppCheckBoxes = @()

    $selectedSet = @{}
    foreach ($id in @($selectedIds)) { $selectedSet[[string]$id] = $true }

    $grouped = $script:AllApps | Group-Object -Property {
        if ($_.Category) { [string]$_.Category } else { "Other" }
    } | Sort-Object Name

    $y = 8
    foreach ($group in $grouped) {
        $header = New-Object System.Windows.Forms.Label
        $header.Text = $group.Name
        $header.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
        $header.Location = New-Object System.Drawing.Point(10, $y)
        $header.Size = New-Object System.Drawing.Size(840, 22)
        $header.ForeColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
        $appListPanel.Controls.Add($header)
        $y += 24

        foreach ($app in ($group.Group | Sort-Object Name)) {
            $cb = New-Object System.Windows.Forms.CheckBox
            $cb.Text = (Get-AppDisplayText -app $app)
            $cb.Tag = $app
            $cb.AutoSize = $false
            $cb.Location = New-Object System.Drawing.Point(26, $y)
            $cb.Size = New-Object System.Drawing.Size(830, 22)
            $cb.Font = New-Object System.Drawing.Font("Segoe UI", 9)
            $cb.AutoEllipsis = $true
            $appId = [string]$app.Number
            $cb.Checked = $selectedSet.ContainsKey($appId)
            $cb.Add_CheckedChanged({ Update-SelectedCounter })
            $appListPanel.Controls.Add($cb)
            $script:AppCheckBoxes += $cb
            $y += 24
        }
        $y += 6
    }

    $appListPanel.ResumeLayout()
    Update-SelectedCounter
}

function Apply-AppSearchFilter {
    param([string]$filter)

    $term = ""
    if ($filter) { $term = $filter.Trim().ToLowerInvariant() }
    $appListPanel.SuspendLayout()
    foreach ($ctrl in $appListPanel.Controls) {
        if ($ctrl -is [System.Windows.Forms.CheckBox]) {
            $app = $ctrl.Tag
            if ([string]::IsNullOrWhiteSpace($term)) {
                $ctrl.Visible = $true
            }
            else {
                $hay = @($ctrl.Text, [string]$app.Name, [string]$app.Category, [string]$app.Description) -join " "
                $ctrl.Visible = $hay.ToLowerInvariant().Contains($term)
            }
        }
        elseif ($ctrl -is [System.Windows.Forms.Label]) {
            $ctrl.Visible = $true
        }
    }
    $appListPanel.ResumeLayout()
}

function Get-SelectedEditorAppIds {
    $ids = @()
    foreach ($cb in $script:AppCheckBoxes) {
        if ($cb.Checked -and $cb.Tag -and $cb.Tag.Number) {
            $ids += [string]$cb.Tag.Number
        }
    }
    return @($ids | Select-Object -Unique)
}

# ==========================================
# VIEW NAVIGATION
# ==========================================

function Show-Overview {
    $script:CurrentView = "Overview"
    $editorPanel.Visible = $false
    $overviewPanel.Visible = $true
    $overviewPanel.BringToFront()
    Refresh-ProfilesList
}

function Show-Editor {
    param(
        [string]$mode,
        $profile
    )
    $script:CurrentView = $mode
    $script:EditingProfileId = $null

    if ($mode -eq "Create") {
        $edTitle.Text = "CREATE PROFILE"
        $btnSave.Text = "Create Profile"
        $txtProfileName.Text = ""
        Build-AppCheckboxList -selectedIds @()
    }
    else {
        $edTitle.Text = "EDIT PROFILE"
        $btnSave.Text = "Save Changes"
        $txtProfileName.Text = [string]$profile.Name
        $script:EditingProfileId = [string]$profile.Id
        Build-AppCheckboxList -selectedIds @($profile.AppIds)
    }

    $txtSearch.Text = ""
    Apply-AppSearchFilter -filter ""

    $overviewPanel.Visible = $false
    $editorPanel.Visible = $true
    $editorPanel.BringToFront()
}

# ==========================================
# PROFILE OVERVIEW RENDERING
# ==========================================

function Refresh-ProfilesList {
    $profilesList.SuspendLayout()
    $profilesList.Controls.Clear()

    $profiles = @()
    try { $profiles = @(Get-AllCustomProfiles) } catch { $profiles = @() }

    if ($profiles.Count -eq 0) {
        $empty = New-Object System.Windows.Forms.Label
        $empty.Text = "No custom profiles yet. Click 'Create New Profile' to add one."
        $empty.AutoSize = $true
        $empty.ForeColor = [System.Drawing.Color]::DimGray
        $empty.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)
        $empty.Margin = New-Object System.Windows.Forms.Padding(12, 12, 12, 12)
        $profilesList.Controls.Add($empty)
        $profilesList.ResumeLayout()
        return
    }

    foreach ($profile in $profiles) {
        $row = New-Object System.Windows.Forms.Panel
        $row.Size = New-Object System.Drawing.Size(860, 52)
        $row.Margin = New-Object System.Windows.Forms.Padding(8, 8, 8, 0)
        $row.BackColor = [System.Drawing.Color]::WhiteSmoke
        $row.BorderStyle = "FixedSingle"

        $lbl = New-Object System.Windows.Forms.Label
        $count = @($profile.AppIds).Count
        $lbl.Text = "$($profile.Name)   ($count applications)"
        $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
        $lbl.AutoSize = $false
        $lbl.Location = New-Object System.Drawing.Point(10, 14)
        $lbl.Size = New-Object System.Drawing.Size(420, 24)
        $row.Controls.Add($lbl)

        $btnInstall = New-Object System.Windows.Forms.Button
        $btnInstall.Text = "Install"
        $btnInstall.Tag = $profile.Id
        $btnInstall.Size = New-Object System.Drawing.Size(90, 30)
        $btnInstall.Location = New-Object System.Drawing.Point(450, 10)
        $btnInstall.Font = New-Object System.Drawing.Font("Segoe UI", 9)
        $btnInstall.BackColor = [System.Drawing.Color]::LavenderBlush
        $btnInstall.Add_Click({
            $pid = [string]$this.Tag
            Invoke-InstallCustomProfile -ProfileId $pid
        }.GetNewClosure())
        $row.Controls.Add($btnInstall)

        $btnEdit = New-Object System.Windows.Forms.Button
        $btnEdit.Text = "Edit"
        $btnEdit.Tag = $profile.Id
        $btnEdit.Size = New-Object System.Drawing.Size(90, 30)
        $btnEdit.Location = New-Object System.Drawing.Point(550, 10)
        $btnEdit.Font = New-Object System.Drawing.Font("Segoe UI", 9)
        $btnEdit.Add_Click({
            $pid = [string]$this.Tag
            $p = @(Get-AllCustomProfiles | Where-Object { $_.Id -eq $pid }) | Select-Object -First 1
            if ($p) { Show-Editor -mode "Edit" -profile $p }
            else {
                [System.Windows.Forms.MessageBox]::Show("Profile not found or was removed.", "Installation Manager") | Out-Null
                Refresh-ProfilesList
            }
        }.GetNewClosure())
        $row.Controls.Add($btnEdit)

        $btnDelete = New-Object System.Windows.Forms.Button
        $btnDelete.Text = "Delete"
        $btnDelete.Tag = $profile.Id
        $btnDelete.Size = New-Object System.Drawing.Size(90, 30)
        $btnDelete.Location = New-Object System.Drawing.Point(650, 10)
        $btnDelete.Font = New-Object System.Drawing.Font("Segoe UI", 9)
        $btnDelete.Add_Click({
            $pid = [string]$this.Tag
            $p = @(Get-AllCustomProfiles | Where-Object { $_.Id -eq $pid }) | Select-Object -First 1
            $pname = if ($p) { $p.Name } else { $pid }
            $confirm = [System.Windows.Forms.MessageBox]::Show(
                "Delete profile '$pname'? This will permanently remove it.",
                "Delete Profile",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Question
            )
            if ($confirm -eq [System.Windows.Forms.DialogResult]::Yes) {
                try {
                    Remove-CustomProfile -Id $pid | Out-Null
                    Refresh-ProfilesList
                }
                catch {
                    [System.Windows.Forms.MessageBox]::Show(
                        "Failed to delete profile:`n$($_.Exception.Message)",
                        "Installation Manager",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Error
                    ) | Out-Null
                    Refresh-ProfilesList
                }
            }
        }.GetNewClosure())
        $row.Controls.Add($btnDelete)

        $profilesList.Controls.Add($row)
    }

    $profilesList.ResumeLayout()
}

# ==========================================
# INSTALLATION (uses existing workflow)
# ==========================================

function Invoke-InstallCustomProfile {
    param([string]$ProfileId)

    $profile = @(Get-AllCustomProfiles | Where-Object { $_.Id -eq $ProfileId }) | Select-Object -First 1
    if (-not $profile) {
        [System.Windows.Forms.MessageBox]::Show("Profile not found.", "Installation Manager") | Out-Null
        Refresh-ProfilesList
        return
    }

    $resolution = Resolve-ProfileApplications -Profile $profile

    if (@($resolution.Resolved).Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "No valid applications found for this profile. All referenced applications are missing from the database.",
            "Installation Manager",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        return
    }

    $msg = "Install profile '$($profile.Name)'?`n`nApplications to install: $(@($resolution.Resolved).Count)"
    if (@($resolution.Missing).Count -gt 0) {
        $msg += "`n`nWarning: $(@($resolution.Missing).Count) application reference(s) no longer exist in the database and will be skipped:`n$($resolution.Missing -join ', ')"
    }

    $confirm = [System.Windows.Forms.MessageBox]::Show(
        $msg,
        "Confirm Installation",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )
    if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) { return }

    # Load backend (logging, helpers, engine, theme) - same as AppsInstaller
    try {
        . (Join-Path $PSScriptRoot "LoadInstallerBackend.ps1")
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Failed to load installer backend:`n$($_.Exception.Message)",
            "Installation Manager",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
        return
    }

    $Global:AutoMode = $true
    $installErrors = @()
    $selectedApps = @($resolution.Resolved)
    $totalApps = $selectedApps.Count
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
    }

    if ($installErrors.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "Installation session finished.",
            "Installation Manager",
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
}

# ==========================================
# EVENT HANDLERS
# ==========================================

$btnCreate.Add_Click({ Show-Editor -mode "Create" -profile $null })
$btnCloseOverview.Add_Click({ $form.Close() })

$txtSearch.Add_TextChanged({ Apply-AppSearchFilter -filter $txtSearch.Text })

$btnSelectAll.Add_Click({
    foreach ($cb in $script:AppCheckBoxes) { if ($cb.Visible) { $cb.Checked = $true } }
    Update-SelectedCounter
})

$btnDeselectAll.Add_Click({
    foreach ($cb in $script:AppCheckBoxes) { if ($cb.Visible) { $cb.Checked = $false } }
    Update-SelectedCounter
})

$btnCancel.Add_Click({ Show-Overview })

$btnSave.Add_Click({
    $name = $txtProfileName.Text
    if ($null -ne $name) { $name = $name.Trim() } else { $name = "" }
    $selectedIds = @(Get-SelectedEditorAppIds)

    if ($script:CurrentView -eq "Edit" -and $script:EditingProfileId) {
        try {
            $updated = Update-CustomProfile -Id $script:EditingProfileId -Name $name -AppIds $selectedIds
            [System.Windows.Forms.MessageBox]::Show(
                "Profile '$($updated.Name)' saved successfully.",
                "Installation Manager",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            ) | Out-Null
            Show-Overview
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show(
                $_.Exception.Message,
                "Profile Error",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
        }
    }
    else {
        try {
            $created = New-CustomProfile -Name $name -AppIds $selectedIds
            [System.Windows.Forms.MessageBox]::Show(
                "Profile '$($created.Name)' created successfully.",
                "Installation Manager",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            ) | Out-Null
            Show-Overview
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show(
                $_.Exception.Message,
                "Profile Error",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
        }
    }
})

# ==========================================
# SHOW FORM
# ==========================================

Show-Overview
[void]$form.ShowDialog()
$form.Dispose()



