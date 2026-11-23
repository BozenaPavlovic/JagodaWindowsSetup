# ==========================================
# STRAWBERRY WINDOWS - UNINSTALLER ENGINE
# Central loader that loads modules 01-07 in order.
# ==========================================

$UninstallerModuleFiles = @(
    "01_Configuration.ps1"
    "02_RegistryDetection.ps1"
    "03_AppXDetection.ps1"
    "04_UninstallCommandResolver.ps1"
    "05_UninstallExecution.ps1"
    "06_UninstallVerification.ps1"
    "07_UninstallLogging.ps1"
)

$UninstallerHelpersPath = Join-Path (Split-Path $PSScriptRoot -Parent) "InstallerHelpers.ps1"

# ==========================================
# VALIDATE MODULE FILES
# ==========================================

foreach ($moduleFile in $UninstallerModuleFiles) {

    $modulePath = Join-Path $PSScriptRoot $moduleFile

    if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
        throw "Required uninstaller module not found: $modulePath"
    }
}

if (-not (Test-Path -LiteralPath $UninstallerHelpersPath -PathType Leaf)) {
    throw "Required installer helper not found: $UninstallerHelpersPath"
}

# ==========================================
# LOAD SHARED CORE HELPERS
# ==========================================

if (-not (Get-Command Invoke-InstallCooldown -ErrorAction SilentlyContinue)) {
    . $UninstallerHelpersPath
}

# ==========================================
# LOAD UNINSTALLER MODULES
# ==========================================

foreach ($moduleFile in $UninstallerModuleFiles) {
    . (Join-Path $PSScriptRoot $moduleFile)
}

# ==========================================
# PUBLIC UNINSTALL FUNCTIONS
# ==========================================

function Uninstall-OneApp {
    param(
        [Parameter(Mandatory)]
        [string]$ProgramName,
        [object]$InputProgram,
        [switch]$Silent
    )

    $result = [PSCustomObject]@{
        ProgramName       = $ProgramName
        Status            = "FAILED"
        Message           = $null
        ExitCode          = $null
        UninstallCommand  = $null
        Timestamp         = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }

    try {
        $commandInfo = Resolve-UninstallCommand -ProgramName $ProgramName -InputProgram $InputProgram

        if (-not $commandInfo) {
            $result.Message = "Program not found: $ProgramName"
            Write-UninstallLog -ProgramName $ProgramName -Status FAILED -Message $result.Message
            return $result
        }

        if (-not $commandInfo.Command) {
            $result.Message = "No uninstall command available for: $ProgramName"
            $result.Status = "SKIPPED"
            Write-UninstallLog -ProgramName $ProgramName -Status SKIPPED -Message $result.Message
            return $result
        }

        $result.UninstallCommand = "$($commandInfo.Command) $($commandInfo.Arguments)"

        Write-Host "Uninstalling: $ProgramName" -ForegroundColor Cyan

        if ($commandInfo.IsAppx) {
            $execResult = Execute-UninstallCommand -Command $commandInfo.Command -Arguments $commandInfo.Arguments `
                -IsAppx $true -PackageFullName $commandInfo.PackageFullName

            if ($execResult.Success) {
                $verified = Verify-AppxUninstall -PackageFullName $commandInfo.PackageFullName

                if ($verified) {
                    $result.Status = "SUCCESS"
                    $result.Message = "AppX package removed."
                    Write-UninstallLog -ProgramName $ProgramName -Status SUCCESS -Message $result.Message -UninstallCommand $result.UninstallCommand
                    Unregister-ManagedProgram -Name $ProgramName
                    return $result
                }
                else {
                    $result.Status = "FAILED"
                    $result.Message = "AppX uninstall completed but verification failed."
                }
            }
            else {
                $result.Status = "FAILED"
                $result.Message = $execResult.Error
                $result.ExitCode = $execResult.ExitCode
            }

            Write-UninstallLog -ProgramName $ProgramName -Status $result.Status -Message $result.Message -ExitCode $result.ExitCode -UninstallCommand $result.UninstallCommand
            return $result
        }

        $execResult = Execute-UninstallCommand `
            -Command $commandInfo.Command `
            -Arguments $commandInfo.Arguments `
            -IsMsi $commandInfo.IsMsi `
            -IsExe $commandInfo.IsExe `
            -IsWinget $commandInfo.IsWinget

        $result.ExitCode = $execResult.ExitCode

        if ($execResult.Success) {
            $verified = $false

            if ($commandInfo.IsMsi -and $commandInfo.ProductCode) {
                $verified = Verify-MsiUninstall -ProductCode $commandInfo.ProductCode
            }
            else {
                $verified = Verify-Uninstall -ProgramName $ProgramName
            }

            if ($verified) {
                $result.Status = "SUCCESS"
                $result.Message = "Program uninstalled successfully."
                Unregister-ManagedProgram -Name $ProgramName
            }
            else {
                $result.Status = "FAILED"
                $result.Message = "Uninstaller finished but program is still present."
            }
        }
        else {
            $result.Status = "FAILED"
            $result.Message = if ($execResult.Error) { $execResult.Error } else { "Uninstaller exit code: $($execResult.ExitCode)" }
        }

        Write-UninstallLog -ProgramName $ProgramName -Status $result.Status -Message $result.Message -ExitCode $result.ExitCode -UninstallCommand $result.UninstallCommand

        return $result
    }
    catch {
        $result.Message = $_.Exception.Message
        $result.ExitCode = $null

        Write-UninstallLog -ProgramName $ProgramName -Status FAILED -Message $result.Message -UninstallCommand $result.UninstallCommand

        Write-Host "Uninstall failed for ${ProgramName}: $($_.Exception.Message)" -ForegroundColor Red

        return $result
    }
    finally {
        if (Get-Command Invoke-UiRefresh -ErrorAction SilentlyContinue) {
            Invoke-UiRefresh
        }
    }
}

function Uninstall-MultipleApps {
    param(
        [Parameter(Mandatory)]
        [array]$Programs,
        [switch]$Silent
    )

    $programs = @($Programs)
    $results = @()

    # Expand apps that carry multiple installed components (e.g. Python's 9 MSI entries)
    # so each component gets its own uninstall pass.
    $expanded = @()

    foreach ($app in $programs) {

        $subs = @()

        if ($app -is [PSCustomObject] -and $app.PSObject.Properties['InstalledPrograms']) {
            $subs = @($app.InstalledPrograms | Where-Object { $null -ne $_ })
        }

        if ($subs.Count -gt 0) {
            foreach ($sub in $subs) {
                $expanded += $sub
            }
        }
        else {
            $expanded += $app
        }
    }

    $total = $expanded.Count
    $current = 0

    foreach ($app in $expanded) {
        $current++

        $appName = $null

        if ($app -is [string]) {
            $appName = $app
        }
        elseif ($app -is [hashtable] -or $app -is [PSCustomObject]) {
            if ($app.DisplayName) { $appName = $app.DisplayName }
            elseif ($app.Name) { $appName = $app.Name }
            elseif ($app.PSChildName) { $appName = $app.PSChildName }
        }

        if (-not $appName) {
            continue
        }

        if ($current -gt 1) {
            Write-Host "`nProgress: $current of $total applications" -ForegroundColor Cyan
        }

        $result = Uninstall-OneApp -ProgramName $appName -InputProgram $app -Silent:$Silent

        $results += $result
    }

    Write-Host "`nUNINSTALL SESSION FINISHED!" -ForegroundColor Magenta

    $successCount = @($results | Where-Object { $_.Status -eq "SUCCESS" }).Count
    $failedCount = @($results | Where-Object { $_.Status -eq "FAILED" }).Count
    $skippedCount = @($results | Where-Object { $_.Status -eq "SKIPPED" }).Count

    Write-Host "SUCCESS: $successCount | FAILED: $failedCount | SKIPPED: $skippedCount" -ForegroundColor Cyan

    return $results
}

Write-Host "[OK] STRAWBERRY WINDOWS uninstaller module loaded." -ForegroundColor Green