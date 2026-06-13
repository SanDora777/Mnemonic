@echo off
cd /d "%~dp0.."
echo Installing Firebase CLI (via cmd, works when PowerShell blocks npm)...
call npm install -g firebase-tools
if errorlevel 1 exit /b 1
echo.
echo Firebase version:
call firebase --version
echo.
echo If not logged in yet, run: firebase login
pause
