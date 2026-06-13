# Local dev: opens Mnemonik in Chrome (hot reload).
# Usage: .\tools\run_web.ps1
#        .\tools\run_web.ps1 -Port 7357

param(
    [int]$Port = 7357
)

Set-Location $PSScriptRoot\..
Write-Host "Starting Mnemonik web on http://localhost:$Port ..." -ForegroundColor Cyan
cmd /c "flutter run -d chrome --web-port=$Port --web-hostname=localhost"
