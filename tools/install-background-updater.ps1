$ErrorActionPreference = 'Stop'
$BloodrightUpdater = Join-Path $PSScriptRoot 'background-updater.ps1'
$BloodrightTaskName = 'Bloodright Background Updater'
$BloodrightTaskCommand = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$BloodrightUpdater`""

schtasks.exe /Create /TN $BloodrightTaskName /TR $BloodrightTaskCommand /SC MINUTE /MO 15 /RU $env:USERNAME /IT /F
if ($LASTEXITCODE -ne 0) { throw 'Windows could not create the Bloodright Background Updater task.' }
schtasks.exe /Run /TN $BloodrightTaskName
Write-Output 'Bloodright Background Updater installed. It checks main every 15 minutes while you are signed in.'
