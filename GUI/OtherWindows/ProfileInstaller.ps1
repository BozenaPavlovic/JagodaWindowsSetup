Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

. "$PSScriptRoot\..\Windows10\Installers\Programs.ps1"

$profiles = @{ "Profil A"=@("2","4","6","7"); "Profil B"=@("2","4"); "Profil C"=@("6","7") }
$profile = $null

$form = New-Object System.Windows.Forms.Form
$form.Text = "Profile Installer"
$form.Size = New-Object System.Drawing.Size(320,240)
$y=20
foreach ($name in $profiles.Keys) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $name
    $b.Location = New-Object System.Drawing.Point(40,$y)
    $b.Size = New-Object System.Drawing.Size(220,40)
    $b.Add_Click({ $script:profile=$this.Text; $form.Close() })
    $form.Controls.Add($b)
    $y+=50
}
[void]$form.ShowDialog()

if ($profile) {
    & "$PSScriptRoot\AppsInstaller.ps1" $profile
}
