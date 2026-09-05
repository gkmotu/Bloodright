$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$stateDirectory = Join-Path $projectRoot '.bloodright'
$logPath = Join-Path $stateDirectory 'launcher.log'
New-Item -ItemType Directory -Force -Path $stateDirectory | Out-Null

function Show-BloodrightLaunchSplash([string]$imagePath) {
    if (-not (Test-Path -LiteralPath $imagePath)) { return $null }
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $form = New-Object System.Windows.Forms.Form
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
    $form.WindowState = [System.Windows.Forms.FormWindowState]::Maximized
    $form.BackColor = [System.Drawing.Color]::Black
    $form.TopMost = $true
    $form.ShowInTaskbar = $false
    $art = New-Object System.Windows.Forms.PictureBox
    $art.Dock = [System.Windows.Forms.DockStyle]::Fill
    $art.ImageLocation = $imagePath
    $art.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::StretchImage
    $form.Controls.Add($art)
    $title = New-Object System.Windows.Forms.Label
    $title.Text = 'BLOODRIGHT'
    $title.AutoSize = $true
    $title.Font = New-Object System.Drawing.Font('Palatino Linotype', 54, [System.Drawing.FontStyle]::Bold)
    $title.ForeColor = [System.Drawing.Color]::FromArgb(214, 174, 95)
    $title.BackColor = [System.Drawing.Color]::Transparent
    $art.Controls.Add($title)
    $subtitle = New-Object System.Windows.Forms.Label
    $subtitle.Text = 'THE LONG NIGHT STIRS'
    $subtitle.AutoSize = $true
    $subtitle.Font = New-Object System.Drawing.Font('Palatino Linotype', 16, [System.Drawing.FontStyle]::Bold)
    $subtitle.ForeColor = [System.Drawing.Color]::FromArgb(225, 210, 173)
    $subtitle.BackColor = [System.Drawing.Color]::Transparent
    $art.Controls.Add($subtitle)
    $loading = New-Object System.Windows.Forms.Label
    $loading.Text = 'LOADING THE FIRST VAULT'
    $loading.AutoSize = $true
    $loading.Font = New-Object System.Drawing.Font('Palatino Linotype', 12, [System.Drawing.FontStyle]::Regular)
    $loading.ForeColor = [System.Drawing.Color]::FromArgb(199, 185, 146)
    $loading.BackColor = [System.Drawing.Color]::Transparent
    $art.Controls.Add($loading)
    $centerTitle = {
        $title.Left = [int](($art.ClientSize.Width - $title.Width) / 2)
        $title.Top = [int](($art.ClientSize.Height / 2) - $title.Height - 12)
        $subtitle.Left = [int](($art.ClientSize.Width - $subtitle.Width) / 2)
        $subtitle.Top = $title.Top + $title.Height + 4
        $loading.Left = [int](($art.ClientSize.Width - $loading.Width) / 2)
        $loading.Top = $art.ClientSize.Height - $loading.Height - 54
    }
    $art.Add_Resize($centerTitle)
    $title.BringToFront()
    $subtitle.BringToFront()
    $loading.BringToFront()
    $form.Show()
    & $centerTitle
    [System.Windows.Forms.Application]::DoEvents()
    return $form
}

function Wait-WithLaunchSplash([int]$milliseconds) {
    $remaining = $milliseconds
    while ($remaining -gt 0) {
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 50
        $remaining -= 50
    }
}

function Fade-BloodrightLaunchSplash($form) {
    if (-not $form) { return }
    for ($opacity = 1.0; $opacity -gt 0; $opacity -= 0.05) {
        $form.Opacity = $opacity
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 50
    }
}

function Write-LaunchLog([string]$message) {
    Add-Content -LiteralPath $logPath -Value ("{0:u}  {1}" -f (Get-Date), $message)
}

try {
    Set-Location -LiteralPath $projectRoot
    $updated = $false
    $launchSplash = Show-BloodrightLaunchSplash (Join-Path $projectRoot 'assets\splash\bloodright-castle-splash.png')

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
    Wait-WithLaunchSplash 3000
    Fade-BloodrightLaunchSplash $launchSplash
    if ($launchSplash) { $launchSplash.Close(); $launchSplash.Dispose() }
}
catch {
    if ($launchSplash) { $launchSplash.Close(); $launchSplash.Dispose() }
    Write-LaunchLog ("Launch failed: {0}" -f $_.Exception.Message)
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show($_.Exception.Message + "`n`nBloodright was not started. Check your connection and try again.", 'Bloodright') | Out-Null
}
