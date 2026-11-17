$ModuleFiles = @(
    "01_Configuration.ps1"
    "02_UiHelpers.ps1"
    "03_AppDetection.ps1"
    "04_Download.ps1"
    "05_Winget.ps1"
    "06_InstallApplication.ps1"
)

foreach ($Module in $ModuleFiles) {
    $ModulePath = Join-Path $PSScriptRoot $Module
    if (!(Test-Path $ModulePath)) {
        throw "Module not found: $ModulePath"
    }
    . $ModulePath
}

Write-Host "[OK] STRAWBERRY WINDOWS installer module loaded." -ForegroundColor Green