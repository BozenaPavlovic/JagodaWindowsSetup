function Get-ProgramInstaller {
    param($App)

    Write-Host "`nDOWNLOADING $($App.Name)..." -ForegroundColor Cyan

    try {
        $DownloadFolder = [IO.Path]::GetFullPath(
            $Global:PinkConfig.DownloadFolder
        )

        if (!(Test-Path -LiteralPath $DownloadFolder -PathType Container)) {
            New-Item -ItemType Directory -Path $DownloadFolder -Force -ErrorAction Stop | Out-Null
        }

        $Installer = Join-Path $DownloadFolder $App.File
        $Temporary = "$Installer.partial"

        Write-Host "Download folder: $DownloadFolder" -ForegroundColor Gray
        Write-Host "Installer path: $Installer" -ForegroundColor Gray

        if (Test-Path -LiteralPath $Temporary) {
            Remove-Item -LiteralPath $Temporary -Force
        }

        $oldProgressPreference = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'
        try {
            $client = New-Object System.Net.WebClient
            $client.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")

            try {
                $downloadTask = $client.DownloadFileTaskAsync($App.URL, $Temporary)

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

        if (!(Test-Path -LiteralPath $Temporary -PathType Leaf)) {
            throw "Downloaded file does not exist."
        }

        $Size = (Get-Item -LiteralPath $Temporary).Length

        if ($Size -lt $App.MinBytes) {
            throw "Incomplete download: $Size bytes."
        }

        Move-Item -LiteralPath $Temporary -Destination $Installer -Force

        Write-Host "DOWNLOAD COMPLETE!" -ForegroundColor Green
        Write-Host "Size: $([math]::Round($Size / 1MB, 2)) MB"

        return $Installer
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