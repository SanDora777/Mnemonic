# Build release APK.
# If Windows blocks font-subset.exe (App Control / Smart App Control), retries without icon tree-shaking.
# Usage: .\tools\build_apk.ps1

Set-Location $PSScriptRoot\..

Write-Host "Building Android release APK..." -ForegroundColor Cyan
flutter build apk --release
if ($LASTEXITCODE -eq 0) { exit 0 }

Write-Host ""
Write-Host "Retrying with --no-tree-shake-icons (skips font-subset.exe blocked by Windows policy)..." -ForegroundColor Yellow
flutter build apk --release --no-tree-shake-icons
exit $LASTEXITCODE
