<# Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$os = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$ram = [math]::Round($os.TotalVisibleMemorySize/1MB,2)

$text = "OS: $($os.Caption)`nVersion: $($os.Version)`nBuild: $($os.BuildNumber)`nCPU: $($cpu.Name)`nRAM: $ram GB`nDisk C: $([math]::Round($disk.FreeSpace/1GB,2)) GB free of $([math]::Round($disk.Size/1GB,2)) GB"

$form = New-Object System.Windows.Forms.Form
$form.Text = "OS Info"
$form.Size = New-Object System.Drawing.Size(420,260)
$label = New-Object System.Windows.Forms.Label
$label.Text = $text
$label.Location = New-Object System.Drawing.Point(20,20)
$label.Size = New-Object System.Drawing.Size(380,200)
$form.Controls.Add($label)
[void]$form.ShowDialog() #>