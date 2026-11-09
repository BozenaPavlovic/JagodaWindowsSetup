
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ==========================================
# SYSTEM INFORMATION
# ==========================================

$os = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$computer = Get-CimInstance Win32_ComputerSystem

# RAM
$ram = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)

# GPU
$gpu = Get-CimInstance Win32_VideoController |
    Select-Object -First 1 -ExpandProperty Name

# COMPUTER
$computerName = $env:COMPUTERNAME
$username = $env:USERNAME
$computerModel = $computer.Model

# ==========================================
# UPTIME
# ==========================================

try {
    $lastBoot = $os.LastBootUpTime

    if ($lastBoot -is [datetime]) {
        $bootTime = $lastBoot
    }
    else {
        $bootTime = [Management.ManagementDateTimeConverter]::ToDateTime(
            [string]$lastBoot
        )
    }

    $uptime = (Get-Date) - $bootTime

    $uptimeText = "{0} days, {1} hours, {2} minutes" -f `
        $uptime.Days, $uptime.Hours, $uptime.Minutes
}
catch {
    $uptimeText = "Unavailable"
}

# ==========================================
# ADMINISTRATOR
# ==========================================

$currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()

$principal = New-Object System.Security.Principal.WindowsPrincipal($currentIdentity)

$isAdmin = $principal.IsInRole(
    [System.Security.Principal.WindowsBuiltInRole]::Administrator
)

$adminText = if ($isAdmin) { "Yes" } else { "No" }

# ==========================================
# ARCHITECTURE
# ==========================================

$architecture = $os.OSArchitecture

# ==========================================
# DISK
# ==========================================

$diskFree = [math]::Round($disk.FreeSpace / 1GB, 2)
$diskSize = [math]::Round($disk.Size / 1GB, 2)

# ==========================================
# SYSTEM INFORMATION TEXT
# ==========================================

$osText = @"
OS: $($os.Caption) | Version: $($os.Version) | Build: $($os.BuildNumber)

PC: $computerName | Model: $computerModel

CPU: $($cpu.Name)

GPU: $gpu

RAM: $ram GB | Disk C: $diskFree GB free / $diskSize GB

Architecture: $architecture | PowerShell: $($PSVersionTable.PSVersion)

Uptime: $uptimeText

Administrator: $adminText

User: $username
"@

# ==========================================
# MAIN FORM
# ==========================================

$form = New-Object System.Windows.Forms.Form
$form.Text = "STRAWBERRY WINDOWS"
$form.Size = New-Object System.Drawing.Size(450, 750)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::WhiteSmoke
$form.MinimumSize = New-Object System.Drawing.Size(200, 200)

# ==========================================
# MENU BUTTONS
# ==========================================

$items = @(
    "Profile Installer",
    "Apps Installer",
    "Theme Manager",
    "Wallpaper Manager",
    "Log Viewer",
    "About"
)

$y = 20

foreach ($item in $items) {

    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $item
    $btn.Location = New-Object System.Drawing.Point(45, $y)
    $btn.Size = New-Object System.Drawing.Size(290, 40)
    $btn.Font = New-Object System.Drawing.Font("Segoe UI", 10)

    $btn.Add_Click({
        $name = $this.Text -replace ' ', ''
        $path = Join-Path $PSScriptRoot "$name.ps1"

        if (Test-Path $path) {
            & $path
        }
        else {
            [System.Windows.Forms.MessageBox]::Show(
                "File not found: $path",
                "Strawberry Windows"
            )
        }
    })

    $form.Controls.Add($btn)
    $y += 48
}

# ==========================================
# EXIT BUTTON
# ==========================================

$exit = New-Object System.Windows.Forms.Button
$exit.Text = "Exit"
$exit.Location = New-Object System.Drawing.Point(45, ($y + 5))
$exit.Size = New-Object System.Drawing.Size(290, 40)
$exit.Font = New-Object System.Drawing.Font("Segoe UI", 10)

$exit.Add_Click({
    $form.Close()
})

$form.Controls.Add($exit)

# ==========================================
# OS INFORMATION PANEL
# ==========================================

$panel = New-Object System.Windows.Forms.Panel
$panel.Dock = [System.Windows.Forms.DockStyle]::Bottom
$panel.Height = 350
$panel.BackColor = [System.Drawing.Color]::LavenderBlush
$panel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

# PANEL TITLE

$labelTitle = New-Object System.Windows.Forms.Label
$labelTitle.Text = "SYSTEM INFORMATION"
$labelTitle.Font = New-Object System.Drawing.Font(
    "Segoe UI", 10, [System.Drawing.FontStyle]::Bold
)
$labelTitle.ForeColor = [System.Drawing.Color]::DarkMagenta
$labelTitle.Location = New-Object System.Drawing.Point(10, 8)
$labelTitle.AutoSize = $true

# SYSTEM DETAILS

$labelInfo = New-Object System.Windows.Forms.Label
$labelInfo.Text = $osText
$labelInfo.Font = New-Object System.Drawing.Font("Consolas", 8)
$labelInfo.ForeColor = [System.Drawing.Color]::DarkSlateGray
$labelInfo.Location = New-Object System.Drawing.Point(10, 32)
$labelInfo.Size = New-Object System.Drawing.Size(465, 310)
$labelInfo.AutoSize = $false
$labelInfo.UseCompatibleTextRendering = $true
$labelInfo.AutoEllipsis = $true

# ADD CONTROLS

$panel.Controls.Add($labelTitle)
$panel.Controls.Add($labelInfo)

$form.Controls.Add($panel)

# ==========================================
# RESPONSIVE PANEL WIDTH
# ==========================================

$form.Add_Resize({
    $labelInfo.Width = $panel.ClientSize.Width - 20
})

# ==========================================
# START APPLICATION
# ==========================================

[void]$form.ShowDialog()
