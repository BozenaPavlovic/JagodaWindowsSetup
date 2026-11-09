<#
.SYNOPSIS
    Main Menu Model.

.DESCRIPTION
    Retrieves operating system, hardware, disk and security information.
    Returns all information as a PSCustomObject.
#>

function Get-SystemInformation {

    # ==========================================
    # DEFAULT VALUES
    # ==========================================

    $os = $null
    $cpu = $null
    $disk = $null
    $computer = $null

    $gpu = "Unavailable"
    $ram = "Unavailable"
    $diskFree = "Unavailable"
    $diskSize = "Unavailable"
    $uptimeText = "Unavailable"
    $architecture = "Unavailable"
    $computerModel = "Unavailable"
    $adminText = "Unavailable"

    # ==========================================
    # OPERATING SYSTEM
    # ==========================================

    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop

        $architecture = $os.OSArchitecture

        $ram = [math]::Round(
            $os.TotalVisibleMemorySize / 1MB, 2
        )
    }
    catch {
        Write-Warning "Unable to retrieve OS information: $_"
    }

    # ==========================================
    # CPU
    # ==========================================

    try {
        $cpu = Get-CimInstance Win32_Processor -ErrorAction Stop |
            Select-Object -First 1
    }
    catch {
        Write-Warning "Unable to retrieve CPU information: $_"
    }

    # ==========================================
    # GPU
    # ==========================================

    try {
        $gpuResult = Get-CimInstance Win32_VideoController -ErrorAction Stop |
            Select-Object -First 1 -ExpandProperty Name

        if (-not [string]::IsNullOrWhiteSpace($gpuResult)) {
            $gpu = $gpuResult
        }
    }
    catch {
        Write-Warning "Unable to retrieve GPU information: $_"
    }

    # ==========================================
    # COMPUTER
    # ==========================================

    try {
        $computer = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop

        if ($computer.Model) {
            $computerModel = $computer.Model
        }
    }
    catch {
        Write-Warning "Unable to retrieve computer information: $_"
    }

    # ==========================================
    # DISK
    # ==========================================

    try {
        $disk = Get-CimInstance Win32_LogicalDisk `
            -Filter "DeviceID='C:'" `
            -ErrorAction Stop

        if ($null -ne $disk) {
            $diskFree = [math]::Round($disk.FreeSpace / 1GB, 2)
            $diskSize = [math]::Round($disk.Size / 1GB, 2)
        }
    }
    catch {
        Write-Warning "Unable to retrieve disk information: $_"
    }

    # ==========================================
    # UPTIME
    # ==========================================

    try {
        if ($null -ne $os -and $null -ne $os.LastBootUpTime) {

            $bootTime = $os.LastBootUpTime

            if ($bootTime -isnot [datetime]) {
                $bootTime = [Management.ManagementDateTimeConverter]::ToDateTime(
                    [string]$bootTime
                )
            }

            $uptime = (Get-Date) - $bootTime

            $uptimeText = "{0} days, {1} hours, {2} minutes" -f `
                [int]$uptime.TotalDays, `
                $uptime.Hours, `
                $uptime.Minutes
        }
    }
    catch {
        $uptimeText = "Unavailable"
    }

    # ==========================================
    # ADMINISTRATOR
    # ==========================================

    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()

        $principal = New-Object Security.Principal.WindowsPrincipal(
            $identity
        )

        $isAdmin = $principal.IsInRole(
            [Security.Principal.WindowsBuiltInRole]::Administrator
        )

        $adminText = if ($isAdmin) { "Yes" } else { "No" }
    }
    catch {
        $adminText = "Unavailable"
    }

    # ==========================================
    # RETURN SYSTEM INFORMATION
    # ==========================================

    return [PSCustomObject]@{

        OS                = if ($os) { $os.Caption } else { "Unavailable" }
        Version           = if ($os) { $os.Version } else { "Unavailable" }
        Build             = if ($os) { $os.BuildNumber } else { "Unavailable" }

        ComputerName      = $env:COMPUTERNAME
        Model             = $computerModel
        Username          = $env:USERNAME

        CPU               = if ($cpu) { $cpu.Name } else { "Unavailable" }
        GPU               = $gpu
        RAM               = $ram

        DiskFree          = $diskFree
        DiskSize          = $diskSize

        Architecture      = $architecture
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()

        Uptime            = $uptimeText
        Administrator     = $adminText
    }
}