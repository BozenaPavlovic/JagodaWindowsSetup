# Core/Installer.ps1

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
