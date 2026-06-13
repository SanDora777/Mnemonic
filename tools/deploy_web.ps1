# Build release web bundle and deploy to Firebase Hosting.
# Requires: flutter, firebase CLI, firebase login
# Usage: .\tools\deploy_web.ps1

Set-Location $PSScriptRoot\..

Write-Host "Building web release..." -ForegroundColor Cyan
flutter build web --release --no-web-resources-cdn
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Deploying to Firebase Hosting (project neural-hack-5ab7d)..." -ForegroundColor Cyan
# cmd обходит блокировку npm.ps1 в PowerShell на Windows
cmd /c "firebase deploy --only hosting"
exit $LASTEXITCODE
