Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$logPath = "C:\Users\Božena\Desktop\JagodaWindowsSetup\Logs\InstallationHistory.log"
$text = if (Test-Path $logPath) { Get-Content $logPath -Raw } else { "No log found." }

$form = New-Object System.Windows.Forms.Form
$form.Text = "Log Viewer"
$form.Size = New-Object System.Drawing.Size(500,400)
$box = New-Object System.Windows.Forms.TextBox
$box.Multiline = $true
$box.ReadOnly = $true
$box.ScrollBars = "Vertical"
$box.Text = $text
$box.Location = New-Object System.Drawing.Point(10,10)
$box.Size = New-Object System.Drawing.Size(470,340)
$form.Controls.Add($box)
[void]$form.ShowDialog()