Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

. "$PSScriptRoot\..\Windows10\Installers\Programs.ps1"

$form = New-Object System.Windows.Forms.Form
$form.Text = "Apps Installer"
$form.Size = New-Object System.Drawing.Size(460, (80 + 30*$Apps.Count + 60))

$y=10
$checks=@()
foreach ($app in $Apps) {
    $cb = New-Object System.Windows.Forms.CheckBox
    $cb.Text = $app.Name
    $cb.Checked = $true
    $cb.Location = New-Object System.Drawing.Point(20,$y)
    $cb.Size = New-Object System.Drawing.Size(400,24)
    $cb.Tag = $app
    $form.Controls.Add($cb)
    $checks += $cb
    $y += 28
}

$selectAll = New-Object System.Windows.Forms.Button
$selectAll.Text = "Select All"
$selectAll.Location = New-Object System.Drawing.Point(20,$y)
$selectAll.Size = New-Object System.Drawing.Size(120,30)
$selectAll.Add_Click({ foreach ($cb in $checks) { $cb.Checked = $true } })
$form.Controls.Add($selectAll)

$install = New-Object System.Windows.Forms.Button
$install.Text = "Install Selected"
$install.Location = New-Object System.Drawing.Point(150,$y)
$install.Size = New-Object System.Drawing.Size(140,30)
$install.Add_Click({
    $Global:AutoMode = $true
    foreach ($cb in $checks) {
        if ($cb.Checked) { Install-OneApp $cb.Tag }
    }
    [System.Windows.Forms.MessageBox]::Show("Done.")
    $form.Close()
})
$form.Controls.Add($install)

[void]$form.ShowDialog()