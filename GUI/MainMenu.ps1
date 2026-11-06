Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "STRAWBERRY WINDOWS"
$form.Size = New-Object System.Drawing.Size(360, 520)

$items = @(
    "Profile Installer",
    "Apps Installer",
    "OS Info",
    "Theme Manager",
    "Wallpaper Manager",
    "Log Viewer",
    "About"
)

$y = 10
foreach ($item in $items) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $item
    $btn.Location = New-Object System.Drawing.Point(30, $y)
    $btn.Size = New-Object System.Drawing.Size(280, 36)
    $btn.Add_Click({
        $name = $this.Text -replace ' ', ''
        $path = Join-Path $PSScriptRoot "$name.ps1"
        if (Test-Path $path) { & $path }
    })
    $form.Controls.Add($btn)
    $y += 42
}

$exit = New-Object System.Windows.Forms.Button
$exit.Text = "Exit"
$exit.Location = New-Object System.Drawing.Point(30, $y)
$exit.Size = New-Object System.Drawing.Size(280, 36)
$exit.Add_Click({ $form.Close() })
$form.Controls.Add($exit)

[void]$form.ShowDialog()