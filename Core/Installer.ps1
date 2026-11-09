# Core/Installer.ps1
function Install-OneApp {
    param($app)
    $os = (Get-CimInstance Win32_OperatingSystem).Caption
    if ($os -like "*Windows 10*") {
        & "$PSScriptRoot\..\Windows10\Installers\Programs.ps1" $app
    } elseif ($os -like "*Windows 11*") {
        & "$PSScriptRoot\..\Windows11\Installers\Programs.ps1" $app
    }
}

# ==========================================
# STRAWBERRY WINDOWS - CORE INSTALLER
# ==========================================

function Install-OneApp {
    param(
        [Parameter(Mandatory)]
        $App
    )

    Write-AppLog `
        -Message "Installation requested: $($App.Name)" `
        -LogType INSTALLATION

    try {
        $result = Invoke-AppInstallation -App $App

        Write-AppLog `
            -Message "Installation successful: $($App.Name)" `
            -Level SUCCESS `
            -LogType INSTALLATION

        return $result
    }
    catch {
        Write-AppLog `
            -Message "Installation failed: $($App.Name). Error: $($_.Exception.Message)" `
            -Level ERROR `
            -LogType INSTALLATION

        throw
    }
}
