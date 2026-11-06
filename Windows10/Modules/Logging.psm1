function Write-Log {
    param([string]$Message)
    $logPath = Join-Path $PSScriptRoot "..\Logs\app.log"
    Add-Content -Path $logPath -Value "$(Get-Date) $Message"
}
Export-ModuleMember -Function Write-Log