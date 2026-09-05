$ErrorActionPreference = 'Stop'
$BloodrightRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $BloodrightRoot

Write-Output 'Publishing Bloodright content...'
npm run publish

Write-Output 'Running Bloodright tests...'
npm test

git add --all
git diff --cached --quiet
if ($LASTEXITCODE -eq 0) {
    Write-Output 'No local changes to push. main is already current.'
    exit 0
}

$BuildStamp = Get-Date -Format 'yyyy-MM-dd HH:mm'
git commit -m "Publish Bloodright build $BuildStamp"
git push origin main
Write-Output 'Bloodright build pushed to origin/main.'
