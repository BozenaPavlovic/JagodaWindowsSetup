
# ==========================================
# STRAWBERRY WINDOWS - INSTALLER HELPERS
# ==========================================

function Invoke-UiRefresh {

    try {
        if ("System.Windows.Forms.Application" -as [type]) {
            [System.Windows.Forms.Application]::DoEvents()
        }
    } catch {}
}

function Wait-ProcessWithUiRefresh {

    param(
        [System.Diagnostics.Process]$Process,
        [int]$TimeoutMs = 300000
    )

    $waited = 0

    while (-not $Process.WaitForExit(1000)) {

        Invoke-UiRefresh

        $waited += 1000

        if ($waited -ge $TimeoutMs) {
            try { $Process.Kill() } catch {}
            return $false
        }
    }

    return $true
}

function Initialize-InstallerBackend {

    param(
        [string]$ProjectRoot
    )

    if (-not $ProjectRoot) {
        $ProjectRoot = Split-Path $PSScriptRoot -Parent
    }

    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    $build = 0
    if ($os) {
        $build = [int]$os.BuildNumber
    }

    if ($build -ge 22000) {
        $osVersion = "Windows11"
    }
    else {
        $osVersion = "Windows10"
    }

    $configPath = Join-Path $ProjectRoot "$osVersion\Config.ps1"

    if (-not (Test-Path $configPath)) {
        throw "Configuration not found: $configPath"
    }

    # Load OS configuration.
    . $configPath

    # Support both old PinkConfig and new WindowsConfig.
    $config = $null

    if ($Global:WindowsConfig) {
        $config = $Global:WindowsConfig
    }
    elseif ($Global:PinkConfig) {
        $config = $Global:PinkConfig
    }
    elseif ($WindowsConfig) {
        $config = $WindowsConfig
    }
    elseif ($PinkConfig) {
        $config = $PinkConfig
    }

    $downloadFolder = $null
    $logFolder = $null

    if ($config) {
        $downloadFolder = $config.DownloadFolder
        $logFolder = $config.LogFolder
    }

    # Fallback folders.
    if (-not $downloadFolder) {
        $downloadFolder = Join-Path $ProjectRoot "Downloads"
    }

    if (-not $logFolder) {
        $logFolder = Join-Path $ProjectRoot "Logs"
    }

    New-Item -ItemType Directory -Path $downloadFolder -Force |
        Out-Null

    New-Item -ItemType Directory -Path $logFolder -Force |
        Out-Null

    $Global:InstallerConfig = [PSCustomObject]@{
        OSVersion = $osVersion
        Build = $build
        DownloadFolder = $downloadFolder
        LogFolder = $logFolder
    }

    $Global:OSVersion = $osVersion

    Write-Host "Installer initialized: $osVersion" -ForegroundColor Green

    return $Global:InstallerConfig
}

# ==========================================
# INSTALLED APPLICATION DETECTION
# ==========================================

function Find-InstalledApp {

    param(
        [Parameter(Mandatory)]
        [string]$Pattern
    )

    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($path in $paths) {

        $found = Get-ItemProperty $path -ErrorAction SilentlyContinue |
            Where-Object {
                $_.DisplayName -like "*$Pattern*"
            } |
            Select-Object -First 1

        if ($found) {
            return $found
        }
    }

    $appx = Get-AppxPackage -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -like "*$Pattern*" -or $_.PackageFullName -like "*$Pattern*"
        } |
        Select-Object -First 1

    if ($appx) {
        return [PSCustomObject]@{
            DisplayName = $appx.Name
            DisplayVersion = $appx.Version
            PackageFullName = $appx.PackageFullName
        }
    }

    return $null
}

# ==========================================
# WINGET
# ==========================================

function Test-Winget {

    return [bool](Get-Command winget.exe -ErrorAction SilentlyContinue)
}

function Install-WithWinget {

    param($App)

    if (-not $App.WingetID) {
        throw "Winget ID missing for $($App.Name)"
    }

    Write-Host "Installing $($App.Name) with Winget..." -ForegroundColor Cyan

    $wingetExe = (Get-Command winget.exe -ErrorAction SilentlyContinue).Source

    if (-not $wingetExe) {
        throw "winget.exe not found."
    }

    $wingetArguments = @(
        "install",
        "--id", $App.WingetID,
        "--exact",
        "--silent",
        "--accept-package-agreements",
        "--accept-source-agreements",
        "--disable-interactivity"
    )

    $argumentString = $wingetArguments -join ' '

    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = "$env:SystemRoot\System32\cmd.exe"
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $false
    $startInfo.Arguments = "/v:on /c `"$wingetExe`" $argumentString & exit /b !errorlevel!"

    $wingetProcess = [System.Diagnostics.Process]::Start($startInfo)

    if (-not (Wait-ProcessWithUiRefresh -Process $wingetProcess -TimeoutMs 300000)) {
        throw "Winget installation timed out after 5 minutes."
    }

    $wingetProcess.WaitForExit()
    $exitCode = $wingetProcess.ExitCode

    if ($exitCode -notin @(0, 3010)) {
        throw "Winget failed with exit code $exitCode"
    }

    Write-Host "Winget installation completed." -ForegroundColor Green
}

# ==========================================
# DOWNLOAD INSTALLER
# ==========================================

function Get-ProgramInstaller {

    param($App)

    if (-not $Global:InstallerConfig) {
        throw "Installer backend is not initialized."
    }

    $folder = $Global:InstallerConfig.DownloadFolder

    $installer = Join-Path $folder $App.File
    $temporary = "$installer.partial"

    Write-Host "Downloading $($App.Name)..." -ForegroundColor Cyan

    if (Test-Path $temporary) {
        Remove-Item $temporary -Force
    }

    $client = New-Object System.Net.WebClient
    $client.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")

    try {
        $downloadTask = $client.DownloadFileTaskAsync($App.URL, $temporary)

        if (-not $downloadTask.Wait(600000)) {
            $client.CancelAsync()
            throw "Download timed out after 10 minutes."
        }
    }
    finally {
        $client.Dispose()
    }

    if (-not (Test-Path $temporary)) {
        throw "Download failed."
    }

    $size = (Get-Item $temporary).Length

    if ($size -lt $App.MinBytes) {
        Remove-Item $temporary -Force
        throw "Downloaded file is incomplete."
    }

    Move-Item $temporary $installer -Force

    Write-Host "Download completed." -ForegroundColor Green

    return $installer
}

# ==========================================
# INSTALLATION LOG
# ==========================================

function Write-InstallerLog {

    param(
        [string]$AppName,
        [string]$Status,
        [string]$Message
    )

    if (-not $Global:InstallerConfig) {
        return
    }

    $logFile = Join-Path `
        $Global:InstallerConfig.LogFolder `
        "InstallationHistory.log"

    $entry = "{0} | {1} | {2} | {3}" -f `
        (Get-Date -Format "yyyy-MM-dd HH:mm:ss"),
        $Status,
        $AppName,
        $Message

    Add-Content -Path $logFile -Value $entry
}

# ==========================================
# INSTALLATION COOLDOWN
# ==========================================

function Get-InstallCooldownSeconds {

    $configPath = Join-Path $PSScriptRoot "InstallerConfig.ps1"
    if (-not $Global:InstallerSettings -and (Test-Path -LiteralPath $configPath)) {
        . $configPath
    }

    $value = $null

    if ($Global:InstallerSettings -and $Global:InstallerSettings.ContainsKey("InstallCooldownSeconds")) {
        $value = $Global:InstallerSettings.InstallCooldownSeconds
    }
    elseif ($Global:WindowsConfig -and $Global:WindowsConfig.ContainsKey("InstallCooldownSeconds")) {
        $value = $Global:WindowsConfig.InstallCooldownSeconds
    }
    elseif ($Global:PinkConfig -and $Global:PinkConfig.ContainsKey("InstallCooldownSeconds")) {
        $value = $Global:PinkConfig.InstallCooldownSeconds
    }

    if ($null -eq $value -or "$value" -eq "") {
        return 5
    }

    try {
        $seconds = [int]$value
    }
    catch {
        return 5
    }

    if ($seconds -lt 0) {
        return 5
    }

    return $seconds
}

function Invoke-InstallCooldown {

    param(
        [string]$AppName
    )

    $seconds = Get-InstallCooldownSeconds

    $name = $AppName
    if ([string]::IsNullOrWhiteSpace($name)) {
        $name = "Unknown application"
    }

    $message = "Installation cooldown for ${name}: ${seconds}s"

    if (Get-Command Write-AppLog -ErrorAction SilentlyContinue) {
        if ($seconds -gt 0) {
            Write-AppLog -Message $message -LogType INSTALLATION
        }
        else {
            Write-AppLog -Message "$message (skipped)" -LogType INSTALLATION
        }
    }

    if ($seconds -gt 0) {
        Write-Host ""
        Write-Host "Cooldown after ${name}: ${seconds}s" -ForegroundColor DarkGray
        for ($remaining = $seconds; $remaining -ge 0; $remaining--) {
            Write-Host ("`rCooldown: {0}s remaining... " -f $remaining) -NoNewline -ForegroundColor DarkGray
            if ($remaining -gt 0) {
                Start-Sleep -Seconds 1
                Invoke-UiRefresh
            }
        }
        Write-Host "`rCooldown complete.            " -ForegroundColor DarkGray
    }
    else {
        Write-Host "Cooldown for ${name}: skipped (0s)" -ForegroundColor DarkGray
    }
}

# ==========================================
# YOUTUBE SHORTCUT
# ==========================================

function Install-YouTubeShortcut {

    $desktop = [Environment]::GetFolderPath("Desktop")
    $shortcut = Join-Path $desktop "YouTube.url"

    @"
[InternetShortcut]
URL=https://www.youtube.com/
"@ | Set-Content -Path $shortcut -Encoding ASCII

    Write-Host "YouTube shortcut created." -ForegroundColor Green
}
