Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "About"
$form.Size = New-Object System.Drawing.Size(400,220)
$label = New-Object System.Windows.Forms.Label
$label.Text = "Strawberry Windows Setup`nAuthor: Bozena Pavlovic`nThis script automates Windows 10/11 app installation via GUI."
$label.Location = New-Object System.Drawing.Point(20,20)
$label.Size = New-Object System.Drawing.Size(360,160)
$form.Controls.Add($label)
[void]$form.ShowDialog()