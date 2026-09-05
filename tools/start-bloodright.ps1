$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$stateDirectory = Join-Path $projectRoot '.bloodright'
$logPath = Join-Path $stateDirectory 'launcher.log'
New-Item -ItemType Directory -Force -Path $stateDirectory | Out-Null

function Write-LaunchLog([string]$message) {
    Add-Content -LiteralPath $logPath -Value ("{0:u}  {1}" -f (Get-Date), $message)
}

try {
    Set-Location -LiteralPath $projectRoot
    $updated = $false

    if (Test-Path -LiteralPath (Join-Path $projectRoot '.git')) {
        & git fetch --quiet origin main
        if ($LASTEXITCODE -ne 0) { throw 'GitHub could not be reached to verify Bloodright master.' }

        $localRevision = (& git rev-parse HEAD).Trim()
        $masterRevision = (& git rev-parse origin/main).Trim()
        $updated = $localRevision -ne $masterRevision

        & git merge-base --is-ancestor origin/main HEAD
        if ($LASTEXITCODE -ne 0) {
            & git branch ("bloodright-recovery-{0}" -f (Get-Random)) HEAD
        }
        & git stash push --include-untracked --quiet -m 'Bloodright automatic pre-master sync'
        & git reset --hard --quiet origin/main
        if ($LASTEXITCODE -ne 0) { throw 'The verified Bloodright master could not be installed.' }
    }

    $godot = Get-Command 'godot.exe' -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source
    if (-not $godot) {
        $wingetPackages = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'
        $godot = Get-ChildItem -LiteralPath $wingetPackages -Recurse -Filter 'Godot_v*-stable_win64.exe' -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notlike '*console*' } |
            Select-Object -First 1 -ExpandProperty FullName
    }
    if (-not $godot) { throw 'Godot could not be found.' }

    $env:BLOODRIGHT_UPDATED = if ($updated) { '1' } else { '0' }
    Write-LaunchLog ("Launching verified master {0}" -f ((& git rev-parse --short HEAD).Trim()))
    Start-Process -FilePath $godot -WorkingDirectory $projectRoot -ArgumentList @('--path', $projectRoot, '--debug', '--maximized')
}
catch {
    Write-LaunchLog ("Launch failed: {0}" -f $_.Exception.Message)
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show($_.Exception.Message + "`n`nBloodright was not started. Check your connection and try again.", 'Bloodright') | Out-Null
}
