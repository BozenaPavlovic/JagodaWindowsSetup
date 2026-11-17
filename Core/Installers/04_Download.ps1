# ==========================================
# STRAWBERRY WINDOWS - INSTALLER DOWNLOAD
# Downloads, validates and stages installers.
# ==========================================

function Get-ProgramInstaller {

    param($App)

    Write-Host "`nDOWNLOADING $($App.Name)..." -ForegroundColor Cyan

    try {

        $downloadFolder = $DownloadFolder

        if (-not $downloadFolder -and $Global:PinkConfig) {
            $downloadFolder = $Global:PinkConfig.DownloadFolder
        }

        if (-not $downloadFolder) {
            $projectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
            $downloadFolder = Join-Path $projectRoot "Downloads"
        }

        $downloadFolder = [IO.Path]::GetFullPath($downloadFolder)

        if (-not (Test-Path -LiteralPath $downloadFolder -PathType Container)) {
            New-Item -ItemType Directory -Path $downloadFolder -Force -ErrorAction Stop | Out-Null
        }

        $installer = Join-Path $downloadFolder $App.File
        $temporary = "$installer.partial"

        Write-Host "Download folder: $downloadFolder" -ForegroundColor Gray
        Write-Host "Installer path: $installer" -ForegroundColor Gray

        if (Test-Path -LiteralPath $temporary) {
            Remove-Item -LiteralPath $temporary -Force
        }

        $oldProgressPreference = $ProgressPreference
        $ProgressPreference = "SilentlyContinue"

        try {
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
        }
        finally {
            $ProgressPreference = $oldProgressPreference
        }

        if (-not (Test-Path -LiteralPath $temporary -PathType Leaf)) {
            throw "Downloaded file does not exist."
        }

        $size = (Get-Item -LiteralPath $temporary).Length

        if ($size -lt $App.MinBytes) {
            throw "Incomplete download: $size bytes."
        }

        Move-Item -LiteralPath $temporary -Destination $installer -Force

        Write-Host "DOWNLOAD COMPLETE!" -ForegroundColor Green
        Write-Host "Size: $([math]::Round($size / 1MB, 2)) MB"

        return $installer
    }
    catch {

        $ex = $_.Exception

        while ($ex -is [System.AggregateException] -and $ex.InnerException) {
            $ex = $ex.InnerException
        }

        Write-Host "DOWNLOAD DIAGNOSTICS:" -ForegroundColor Red
        Write-Host "Error: $($ex.Message)" -ForegroundColor Red
        Write-Host "Category: $($_.CategoryInfo.Category)" -ForegroundColor Yellow
        Write-Host "Target: $($_.CategoryInfo.TargetName)" -ForegroundColor Yellow
        Write-Host "Position: $($_.InvocationInfo.PositionMessage)" -ForegroundColor Yellow

        throw
    }
}