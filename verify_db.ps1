. .\DATABASE\ProgramDatabase.ps1
$Global:Apps | ForEach-Object { [PSCustomObject]@{ Number=$_.Number; Name=$_.Name; Category=$_.Category } } | Sort-Object Number