# ==========================================
# STRAWBERRY WINDOWS - INSTALLER DOWNLOAD
# Downloads, validates and stages installers.
# Validates HTTPS, file integrity, Authenticode signatures, SHA256.
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

        if (Test-Path -LiteralPath $installer) {
            Write-Host "Existing installer found, validating..." -ForegroundColor Yellow
            $validationResult = Test-InstallerIntegrity -Path $installer -App $App
            if ($validationResult.IsValid) {
                Write-Host "Existing installer is valid, reusing." -ForegroundColor Green
                return $installer
            }
            else {
                Write-Host "Existing installer failed validation: $($validationResult.Reason)" -ForegroundColor Yellow
                Remove-Item -LiteralPath $installer -Force
            }
        }

        $oldProgressPreference = $ProgressPreference
        $ProgressPreference = "SilentlyContinue"

        $downloadSuccess = $false

        try {
            $url = $App.URL

            if (-not $url.StartsWith("https://", [StringComparison]::OrdinalIgnoreCase)) {
                throw "URL must use HTTPS: $url"
            }

            $client = New-Object System.Net.WebClient
            $client.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
            $client.Headers.Add("Accept", "*/*")

            $downloadTask = $client.DownloadFileTaskAsync($url, $temporary)

            if (-not $downloadTask.Wait(600000)) {
                $client.CancelAsync()
                throw "Download timed out after 10 minutes."
            }

            $client.Dispose()

            if (-not (Test-Path -LiteralPath $temporary -PathType Leaf)) {
                throw "Downloaded file does not exist."
            }

            $size = (Get-Item -LiteralPath $temporary).Length

            if ($size -lt $App.MinBytes) {
                throw "Incomplete download: $size bytes (expected at least $($App.MinBytes))."
            }

            Write-Host "Download complete, validating installer..." -ForegroundColor Cyan

            $validationResult = Test-InstallerIntegrity -Path $temporary -App $App

            if (-not $validationResult.IsValid) {
                throw "Installer validation failed: $($validationResult.Reason)"
            }

            Move-Item -LiteralPath $temporary -Destination $installer -Force

            $downloadSuccess = $true

            Write-Host "DOWNLOAD COMPLETE!" -ForegroundColor Green
            Write-Host "Size: $([math]::Round($size / 1MB, 2)) MB" -ForegroundColor Gray
            Write-Host "SHA256: $($validationResult.SHA256)" -ForegroundColor Gray
            Write-Host "Signature: $($validationResult.SignatureStatus)" -ForegroundColor Gray

            if (Get-Command Write-AppLog -ErrorAction SilentlyContinue) {
                Write-AppLog -Message "Downloaded $($App.Name) to $installer (Size: $([math]::Round($size / 1MB, 2)) MB, SHA256: $($validationResult.SHA256), Signature: $($validationResult.SignatureStatus))" -LogType INSTALLATION -Level SUCCESS
            }

            return $installer
        }
        finally {
            if (-not $downloadSuccess -and (Test-Path -LiteralPath $temporary)) {
                try { Remove-Item -LiteralPath $temporary -Force } catch {}
            }
            $ProgressPreference = $oldProgressPreference
        }
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

        if (Get-Command Write-AppLog -ErrorAction SilentlyContinue) {
            Write-AppLog -Message "Download failed for $($App.Name): $($ex.Message)" -LogType INSTALLATION -Level ERROR
        }

        throw
    }
}

function Test-InstallerIntegrity {

    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        $App
    )

    $result = @{
        IsValid = $false
        SHA256 = $null
        SignatureStatus = "NotChecked"
        Reason = ""
    }

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        $result.Reason = "File does not exist"
        return $result
    }

    try {
        $sha256 = Get-FileHash -Path $Path -Algorithm SHA256
        $result.SHA256 = $sha256.Hash.ToLowerInvariant()
        Write-Host "SHA256: $($result.SHA256)" -ForegroundColor Gray
    }
    catch {
        $result.Reason = "Failed to compute SHA256: $($_.Exception.Message)"
        return $result
    }

    if ($App.Publisher) {
        try {
            $sig = Get-AuthenticodeSignature -FilePath $Path
            $result.SignatureStatus = $sig.Status.ToString()

            Write-Host "Authenticode Status: $($sig.Status)" -ForegroundColor Gray

            if ($sig.Status -eq "Valid") {
                $signer = $sig.SignerCertificate
                if ($signer -and $signer.Subject -like "*$($App.Publisher)*") {
                    Write-Host "Publisher verified: $($signer.Subject)" -ForegroundColor Green
                }
                else {
                    Write-Host "Warning: Publisher mismatch. Expected: $($App.Publisher), Got: $($signer.Subject)" -ForegroundColor Yellow
                }
            }
            elseif ($sig.Status -eq "NotSigned") {
                $result.Reason = "File is not digitally signed"
                return $result
            }
            elseif ($sig.Status -in @("HashMismatch", "UnknownError")) {
                $result.Reason = "Invalid digital signature: $($sig.Status)"
                return $result
            }
        }
        catch {
            Write-Host "Warning: Could not verify Authenticode signature: $($_.Exception.Message)" -ForegroundColor Yellow
            $result.SignatureStatus = "Error: $($_.Exception.Message)"
        }
    }

    if ($App.ExpectedSHA256) {
        if ($result.SHA256 -ne $App.ExpectedSHA256.ToLowerInvariant()) {
            $result.Reason = "SHA256 mismatch. Expected: $($App.ExpectedSHA256), Got: $($result.SHA256)"
            return $result
        }
        Write-Host "SHA256 matches expected value." -ForegroundColor Green
    }

    $result.IsValid = $true
    $result.Reason = "All checks passed"
    return $result
}

function Get-FileHash {

    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [string]$Algorithm = "SHA256"
    )

    $stream = [System.IO.File]::OpenRead($Path)
    try {
        $hashAlgorithm = [System.Security.Cryptography.HashAlgorithm]::Create($Algorithm)
        $hashBytes = $hashAlgorithm.ComputeHash($stream)
        return [PSCustomObject]@{
            Hash = ($hashBytes | ForEach-Object { "{0:x2}" -f $_ }) -join ""
            Algorithm = $Algorithm
            Path = $Path
        }
    }
    finally {
        $stream.Close()
        $hashAlgorithm.Dispose()
    }
}