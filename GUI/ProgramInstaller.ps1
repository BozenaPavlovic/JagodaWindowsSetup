Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

 . "$PSScriptRoot\..\Windows10\Installers\Programs.ps1"

$profiles = @{
    "Profil A" = @("2","4","6","7")
    "Profil B" = @("2","4")
    "Profil C" = @("6","7")
}

function Show-ProfileForm {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "PINK WINDOWS - STRAWBERRY GUI"
    $form.Size = New-Object System.Drawing.Size(320,260)
    $y = 20
    foreach ($name in $profiles.Keys) {
        $btn = New-Object System.Windows.Forms.Button
        $btn.Text = $name
        $btn.Location = New-Object System.Drawing.Point(40,$y)
        $btn.Size = New-Object System.Drawing.Size(220,40)
        $btn.Add_Click({
            $form.Tag = $this.Text
            $form.Close()
        })
        $form.Controls.Add($btn)
        $y += 50
    }
    [void]$form.ShowDialog()
    return $form.Tag
}

function Show-AppsForm {
    param($profileName)
    $selectedIds = $profiles[$profileName]
    $apps = $Apps | Where-Object { $_.Number -in $selectedIds }

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "$profileName - Applications"
    $form.Size = New-Object System.Drawing.Size(340, (40 + 30*$apps.Count + 60))

    $y = 10
    $checks = @()
    foreach ($app in $apps) {
        $cb = New-Object System.Windows.Forms.CheckBox
        $cb.Text = $app.Name
        $cb.Checked = $true
        $cb.Location = New-Object System.Drawing.Point(20,$y)
        $cb.Size = New-Object System.Drawing.Size(280,24)
        $cb.Tag = $app
        $form.Controls.Add($cb)
        $checks += $cb
        $y += 28
    }

    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = "Install Selected"
    $btn.Location = New-Object System.Drawing.Point(20,$y)
    $btn.Size = New-Object System.Drawing.Size(140,30)
    $btn.Add_Click({
        $form.Tag = "install"
        $form.Close()
    })
    $form.Controls.Add($btn)

    $back = New-Object System.Windows.Forms.Button
    $back.Text = "Back"
    $back.Location = New-Object System.Drawing.Point(170,$y)
    $back.Size = New-Object System.Drawing.Size(100,30)
    $back.Add_Click({
        $form.Tag = "back"
        $form.Close()
    })
    $form.Controls.Add($back)

    [void]$form.ShowDialog()
    if ($form.Tag -eq "install") {
        $Global:AutoMode = $true
        foreach ($cb in $checks) {
            if ($cb.Checked) {
                Install-OneApp $cb.Tag
            }
        }
        [System.Windows.Forms.MessageBox]::Show("Installation session finished.")
    }
}

$Global:AutoMode = $true
while ($true) {
    $profile = Show-ProfileForm
    if (-not $profile) { break }
    Show-AppsForm $profile
}
