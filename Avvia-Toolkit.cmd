@echo off
setlocal
cd /d "%~dp0"

:: Avvia il preset Standard con privilegi di amministratore.
:: Se il file viene aperto con doppio clic, Windows mostrera' la richiesta UAC.
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -NoExit -File ""%~dp0Setup.ps1"" -Preset Standard'"
    exit /b
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -NoExit -File "%~dp0Setup.ps1" -Preset Standard
endlocal
