@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0executar-app.ps1" -GerarApk %*
pause
