$ErrorActionPreference = 'Stop'

$BloodrightRoot = Split-Path -Parent $PSScriptRoot
$BloodrightStateDir = Join-Path $BloodrightRoot '.bloodright'
$BloodrightLog = Join-Path $BloodrightStateDir 'background-updater.log'
$BloodrightNotice = Join-Path $BloodrightStateDir 'last-update-notice.txt'
$BloodrightGit = @(
    "$env:ProgramFiles\Git\cmd\git.exe",
    "${env:ProgramFiles(x86)}\Git\cmd\git.exe"
) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1

New-Item -ItemType Directory -Force -Path $BloodrightStateDir | Out-Null

function Write-BloodrightLog([string]$Message) {
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $Message" | Add-Content -LiteralPath $BloodrightLog -Encoding utf8
}

function Show-BloodrightToast([string]$Title, [string]$Message, [string]$Version) {
    if ((Test-Path -LiteralPath $BloodrightNotice) -and (Get-Content -LiteralPath $BloodrightNotice -Raw).Trim() -eq $Version) { return }
    try {
        Add-Type -AssemblyName System.Runtime.WindowsRuntime
        $null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
        $null = [Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime]
        $null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]
        $SafeTitle = [System.Security.SecurityElement]::Escape($Title)
        $SafeMessage = [System.Security.SecurityElement]::Escape($Message)
        $ToastMarkup = @"
<toast activationType="protocol" launch="bloodright://launch">
  <visual><binding template="ToastGeneric"><text>$SafeTitle</text><text>$SafeMessage</text></binding></visual>
  <actions><action content="Restart Bloodright" arguments="bloodright://launch" activationType="protocol" /></actions>
</toast>
"@
        $xml = New-Object -TypeName Windows.Data.Xml.Dom.XmlDocument
        $xml.LoadXml($ToastMarkup)
        $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Microsoft.WindowsPowerShell').Show($toast)
        Set-Content -LiteralPath $BloodrightNotice -Value $Version -Encoding utf8
        Write-BloodrightLog "Notification shown: $Title"
    } catch {
        Write-BloodrightLog "Notification failed: $($_.Exception.Message)"
    }
}

try {
    Set-Location -LiteralPath $BloodrightRoot
    if (-not (Test-Path -LiteralPath (Join-Path $BloodrightRoot '.git'))) { throw 'This folder is not a Git workspace.' }
    if (-not $BloodrightGit) { throw 'Git is not installed on this Windows computer.' }
    if ($env:BLOODRIGHT_TEST_NOTIFICATION -eq '1') {
        Show-BloodrightToast 'Bloodright updater connected' 'Windows will notify you when a new Bloodright build is available.' 'updater-test-v2'
        exit 0
    }
    & $BloodrightGit fetch --quiet origin main
    if ($LASTEXITCODE -ne 0) { throw 'Could not check GitHub for updates.' }
    $LocalRevision = (& $BloodrightGit rev-parse HEAD).Trim()
    $RemoteRevision = (& $BloodrightGit rev-parse origin/main).Trim()
    if ($LocalRevision -eq $RemoteRevision) { Write-BloodrightLog 'No new build found.'; exit 0 }
    $LocalEdits = & $BloodrightGit status --porcelain
    if ($LocalEdits) {
        Show-BloodrightToast 'Bloodright update waiting' 'A new build is available, but your local edits were left untouched. Push or commit them first.' "waiting-$RemoteRevision"
        exit 0
    }
    & $BloodrightGit pull --ff-only --quiet origin main
    if ($LASTEXITCODE -ne 0) { throw 'The new build could not be installed safely.' }
    Show-BloodrightToast 'Bloodright updated' 'A new game build was installed. Start or restart Bloodright to play it.' "installed-$RemoteRevision"
    Write-BloodrightLog "Installed $RemoteRevision"
} catch {
    Write-BloodrightLog "Update check failed: $($_.Exception.Message)"
}
