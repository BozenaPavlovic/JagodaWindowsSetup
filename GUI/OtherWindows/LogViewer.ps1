<#
.SYNOPSIS
    Log Viewer GUI.

.DESCRIPTION
    Displays installation logs from the Logs folder.
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ==========================================
# GET LOG FILES
# ==========================================

$script:ProjectRoot = Split-Path $PSScriptRoot -Parent
$script:ProjectRoot = Split-Path $script:ProjectRoot -Parent

$logDir = Join-Path $script:ProjectRoot "Logs"
$logFiles = @(
    "InstallationHistory.log"
    "Activity.log"
    "Errors.log"
    "Installation.log"
    "Google_Chrome.log"
)

$availableLogs = @()
foreach ($lf in $logFiles) {
    $fullPath = Join-Path $logDir $lf
    if (Test-Path $fullPath) {
        $availableLogs += @{ Name = $lf; Path = $fullPath }
    }
}

if ($availableLogs.Count -eq 0) {
    [System.Windows.Forms.MessageBox]::Show(
        "No log files found in:`n$logDir",
        "Log Viewer",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    ) | Out-Null
    return
}

# ==========================================
# MAIN FORM
# ==========================================

$form = New-Object System.Windows.Forms.Form
$form.Text = "STRAWBERRY WINDOWS - LOG VIEWER"
$form.Size = New-Object System.Drawing.Size(700, 500)
$form.MinimumSize = New-Object System.Drawing.Size(500, 350)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::WhiteSmoke

# ==========================================
# TITLE
# ==========================================

$title = New-Object System.Windows.Forms.Label
$title.Text = "INSTALLATION LOGS"
$title.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(20, 15)
$form.Controls.Add($title)

# ==========================================
# LOG SELECTOR COMBOBOX
# ==========================================

$comboLabel = New-Object System.Windows.Forms.Label
$comboLabel.Text = "Select log file:"
$comboLabel.Location = New-Object System.Drawing.Point(20, 55)
$comboLabel.AutoSize = $true
$form.Controls.Add($comboLabel)

$combo = New-Object System.Windows.Forms.ComboBox
$combo.Location = New-Object System.Drawing.Point(20, 80)
$combo.Size = New-Object System.Drawing.Size(300, 25)
$combo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$combo.Font = New-Object System.Drawing.Font("Segoe UI", 10)

foreach ($log in $availableLogs) {
    $combo.Items.Add($log.Name) | Out-Null
}
$combo.SelectedIndex = 0

$form.Controls.Add($combo)

# ==========================================
# LOG TEXTBOX
# ==========================================

$box = New-Object System.Windows.Forms.TextBox
$box.Multiline = $true
$box.ReadOnly = $true
$box.ScrollBars = "Vertical"
$box.Location = New-Object System.Drawing.Point(20, 120)
$box.Size = New-Object System.Drawing.Size(640, 320)
$box.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$box.Font = New-Object System.Drawing.Font("Consolas", 9)
$box.BackColor = [System.Drawing.Color]::White
$box.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

$form.Controls.Add($box)

# ==========================================
# LOAD LOG FUNCTION
# ==========================================

function Load-Log {
    $selectedName = $combo.SelectedItem
    $log = $availableLogs | Where-Object { $_.Name -eq $selectedName } | Select-Object -First 1
    if ($log) {
        try {
            $content = Get-Content $log.Path -Raw -ErrorAction Stop
            if ([string]::IsNullOrWhiteSpace($content)) {
                $box.Text = "(Log file is empty)"
            }
            else {
                $box.Text = $content
            }
        }
        catch {
            $box.Text = "Error reading log: $($_.Exception.Message)"
        }
    }
}

# Initial load
Load-Log

# Reload on selection change
$combo.Add_SelectedIndexChanged({ Load-Log })

# ==========================================
# REFRESH BUTTON
# ==========================================

$refreshBtn = New-Object System.Windows.Forms.Button
$refreshBtn.Text = "Refresh"
$refreshBtn.Location = New-Object System.Drawing.Point(340, 78)
$refreshBtn.Size = New-Object System.Drawing.Size(100, 30)
$refreshBtn.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$refreshBtn.Add_Click({ Load-Log })
$form.Controls.Add($refreshBtn)

# ==========================================
# CLOSE BUTTON
# ==========================================

$closeBtn = New-Object System.Windows.Forms.Button
$closeBtn.Text = "Close"
$closeBtn.Location = New-Object System.Drawing.Point(560, 78)
$closeBtn.Size = New-Object System.Drawing.Size(100, 30)
$closeBtn.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$closeBtn.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$closeBtn.Add_Click({ $form.Close() })
$form.Controls.Add($closeBtn)

# ==========================================
# RESPONSIVE LAYOUT
# ==========================================

$form.Add_Resize({
    $box.Width = [math]::Max(100, $form.ClientSize.Width - 40)
    $box.Height = [math]::Max(50, $form.ClientSize.Height - 160)
    $closeBtn.Left = $form.ClientSize.Width - $closeBtn.Width - 20
})

# ==========================================
# SHOW FORM
# ==========================================

[void]$form.ShowDialog()
$form.Dispose()