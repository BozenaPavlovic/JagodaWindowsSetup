
<#
.SYNOPSIS
    Profile Installer GUI.
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ==========================================
# PROFILES
# ==========================================

$profiles = @{
    "Profil A" = @("2", "4", "6", "7")
    "Profil B" = @("2", "4")
    "Profil C" = @("6", "7")
}

# ==========================================
# PROFILE SELECTION
# ==========================================

function Show-ProfileForm {

    $form = New-Object System.Windows.Forms.Form

    $form.Text = "STRAWBERRY WINDOWS - PROFILE INSTALLER"
    $form.Size = New-Object System.Drawing.Size(350, 290)
    $form.StartPosition = "CenterScreen"
    $form.BackColor = [System.Drawing.Color]::WhiteSmoke
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false

    $title = New-Object System.Windows.Forms.Label
    $title.Text = "SELECT INSTALLATION PROFILE"
    $title.Font = New-Object System.Drawing.Font(
        "Segoe UI", 11, [System.Drawing.FontStyle]::Bold
    )
    $title.AutoSize = $true
    $title.Location = New-Object System.Drawing.Point(45, 15)

    $form.Controls.Add($title)

    $y = 55

    foreach ($name in $profiles.Keys) {

        $btn = New-Object System.Windows.Forms.Button

        $btn.Text = $name
        $btn.Tag = $name

        $btn.Location = New-Object System.Drawing.Point(45, $y)
        $btn.Size = New-Object System.Drawing.Size(240, 40)

        $btn.Font = New-Object System.Drawing.Font("Segoe UI", 10)

        $btn.Add_Click({

            $form.Tag = $this.Tag
            $form.Close()

        }.GetNewClosure())

        $form.Controls.Add($btn)

        $y += 48
    }

    $form.Add_FormClosed({
        $form.Dispose()
    })

    [void]$form.ShowDialog()

    return $form.Tag
}

# ==========================================
# PROFILE NAVIGATION
# ==========================================

$appsInstallerPath = Join-Path $PSScriptRoot "AppsInstaller.ps1"

while ($true) {

    $selectedProfile = Show-ProfileForm

    if (-not $selectedProfile) {
        break
    }

    try {

        $result = & $appsInstallerPath `
            -ProfileName $selectedProfile

        if ($result -ne "Back") {
            break
        }

    }
    catch {

        [System.Windows.Forms.MessageBox]::Show(
            "Profile installation error:`n$($_.Exception.Message)",
            "Strawberry Windows",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null

        break
    }
}
