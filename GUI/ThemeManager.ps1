Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "Theme Manager"
$form.Size = New-Object System.Drawing.Size(300,220)
$themes = @("Pink","Blue","Yellow","Green")
$y=10
foreach ($t in $themes) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $t
    $b.Location = New-Object System.Drawing.Point(30,$y)
    $b.Size = New-Object System.Drawing.Size(220,36)
    $form.Controls.Add($b)
    $y += 42
}
[void]$form.ShowDialog()