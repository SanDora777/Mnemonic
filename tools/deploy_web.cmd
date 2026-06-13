@echo off
cd /d "%~dp0.."
echo Building web release...
call flutter build web --release --no-web-resources-cdn
if errorlevel 1 exit /b 1
echo.
echo Deploying to Firebase Hosting...
call firebase deploy --only hosting
if errorlevel 1 (
  echo.
  echo Deploy failed. This is a known Firebase CLI bug on slow networks.
  echo Run this file again - each attempt uploads more files.
  exit /b 1
)
echo.
echo Done! Open: https://neural-hack-5ab7d.web.app
pause
