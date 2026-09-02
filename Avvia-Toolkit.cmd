@echo off
setlocal
cd /d "%~dp0"

:: Richiede i privilegi di amministratore prima di mostrare il menu.
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -Verb RunAs -ArgumentList '/c ""%~f0""'"
    exit /b
)

:MENU
cls
echo ==================================================
echo       TECNICO DIGITALE - WINDOWS TOOLKIT
echo ==================================================
echo.
echo Scegli il profilo da applicare:
echo.
echo   [1] STANDARD
echo       PC domestici e uso generale
echo.
echo   [2] GAMING
echo       PC dedicati principalmente ai videogiochi
echo.
echo   [3] BUSINESS
echo       PC professionali e postazioni di lavoro
echo.
echo   [4] ESCI
echo.
set "scelta="
set /p "scelta=Scelta: "

if "%scelta%"=="1" set "preset=Standard"& goto AVVIA
if "%scelta%"=="2" set "preset=Gaming"& goto AVVIA
if "%scelta%"=="3" set "preset=Business"& goto AVVIA
if "%scelta%"=="4" exit /b

echo.
echo Scelta non valida. Premi un tasto e riprova.
pause >nul
goto MENU

:AVVIA
cls
echo ==================================================
echo       TECNICO DIGITALE - WINDOWS TOOLKIT
echo ==================================================
echo.
echo Profilo selezionato: %preset%
echo.
echo Avvio del toolkit...
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Setup.ps1" -Preset "%preset%"

echo.
echo ==================================================
echo Esecuzione terminata. Premi un tasto per chiudere.
echo ==================================================
pause >nul
endlocal
