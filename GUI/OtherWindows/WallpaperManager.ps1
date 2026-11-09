Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$photoDir = "C:\Users\Božena\Desktop\JagodaWindowsSetup\Windows10\DATA\Photos"
$files = Get-ChildItem $photoDir -Filter *.jpg

$form = New-Object System.Windows.Forms.Form
$form.Text = "Wallpaper Manager"
$form.Size = New-Object System.Drawing.Size(400,300)
$lb = New-Object System.Windows.Forms.ListBox
$lb.Location = New-Object System.Drawing.Point(10,10)
$lb.Size = New-Object System.Drawing.Size(360,200)
foreach ($f in $files) { $lb.Items.Add($f.Name) | Out-Null }
$form.Controls.Add($lb)
[void]$form.ShowDialog()