$ErrorActionPreference = 'Stop'
$BloodrightRoot = Split-Path -Parent $PSScriptRoot
$BloodrightStatusPath = Join-Path $PSScriptRoot 'push-status.json'
Set-Location -LiteralPath $BloodrightRoot

function Set-BloodrightStatus([string]$Stage, [string]$Message) {
    $statusJson = @{ stage = $Stage; message = $Message; updatedAt = (Get-Date).ToString('o') } |
        ConvertTo-Json -Compress
    $written = $false
    for ($attempt = 1; $attempt -le 20 -and -not $written; $attempt++) {
        try {
            Set-Content -LiteralPath $BloodrightStatusPath -Value $statusJson -Encoding utf8 -ErrorAction Stop
            $written = $true
        }
        catch {
            if ($attempt -eq 20) { throw }
            Start-Sleep -Milliseconds 50
        }
    }
    Write-Output $Message
}

try {
    Set-BloodrightStatus 'publishing' 'Publishing Bloodright content…'
    npm run publish
    if ($LASTEXITCODE -ne 0) { throw 'Content publishing failed.' }

    Set-BloodrightStatus 'testing' 'Running Bloodright tests…'
    npm test
    if ($LASTEXITCODE -ne 0) { throw 'Tests failed. Nothing was pushed.' }

    Set-BloodrightStatus 'committing' 'Preparing the current local changes for main…'
    git add --all
    git diff --cached --quiet
    if ($LASTEXITCODE -eq 0) {
        Set-BloodrightStatus 'complete' 'No local changes to push. main is already current.'
        exit 0
    }

    $BuildStamp = Get-Date -Format 'yyyy-MM-dd HH:mm'
    git commit -m "Publish Bloodright build $BuildStamp"
    if ($LASTEXITCODE -ne 0) { throw 'Git could not create the build commit.' }

    Set-BloodrightStatus 'pushing' 'Pushing the new Bloodright build to main…'
    git push origin main
    if ($LASTEXITCODE -ne 0) { throw 'GitHub rejected the push.' }
    Set-BloodrightStatus 'complete' 'Bloodright build pushed to origin/main.'
}
catch {
    Set-BloodrightStatus 'failed' ("Push failed: " + $_.Exception.Message)
    exit 1
}
