$ErrorActionPreference = 'Stop'
$BloodrightUpdater = Join-Path $PSScriptRoot 'background-updater.ps1'
$BloodrightRoot = Split-Path -Parent $PSScriptRoot
$BloodrightLauncher = Join-Path $BloodrightRoot 'Start Bloodright Debug.bat'
$BloodrightTaskName = 'Bloodright Background Updater'
$BloodrightTaskCommand = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$BloodrightUpdater`""

schtasks.exe /Create /TN $BloodrightTaskName /TR $BloodrightTaskCommand /SC MINUTE /MO 15 /RU $env:USERNAME /IT /F
if ($LASTEXITCODE -ne 0) { throw 'Windows could not create the Bloodright Background Updater task.' }
$BloodrightProtocol = 'HKCU:\Software\Classes\bloodright'
$BloodrightCommandKey = Join-Path $BloodrightProtocol 'shell\open\command'
New-Item -Path $BloodrightProtocol -Force | Out-Null
Set-Item -Path $BloodrightProtocol -Value 'URL:Bloodright Protocol'
New-ItemProperty -Path $BloodrightProtocol -Name 'URL Protocol' -Value '' -PropertyType String -Force | Out-Null
New-Item -Path $BloodrightCommandKey -Force | Out-Null
Set-Item -Path $BloodrightCommandKey -Value "cmd.exe /c `"`"$BloodrightLauncher`"`""
schtasks.exe /Run /TN $BloodrightTaskName
Write-Output 'Bloodright Background Updater installed. It checks main every 15 minutes while you are signed in.'
