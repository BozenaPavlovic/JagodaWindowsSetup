# Core/Controller.ps1
function Get-SelectedApps { param($ids) $Global:Apps | Where-Object { $_.Number -in $ids } }
