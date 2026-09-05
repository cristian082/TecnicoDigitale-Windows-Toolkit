@echo off
setlocal
cd /d "%~dp0"

set "TDT_VERSION=sconosciuta"
for /f "usebackq delims=" %%V in (`powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$v=Get-Content '%~dp0VERSION.json' -Raw|ConvertFrom-Json; $v.version"`) do set "TDT_VERSION=%%V"

net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -Verb RunAs -ArgumentList '/c ""%~f0""'"
    exit /b
)

:MENU
cls
echo ==================================================
echo       TECNICO DIGITALE - WINDOWS TOOLKIT
echo                 Versione %TDT_VERSION%
echo ==================================================
echo.
echo   [1] STANDARD
 echo      PC domestici e uso generale
echo.
echo   [2] GAMING
 echo      PC dedicati principalmente ai videogiochi
echo.
echo   [3] BUSINESS
 echo      PC professionali e postazioni di lavoro
echo.
echo   [4] STRUMENTI RAPIDI TECNICO
 echo      Rete, DNS, Spooler e triage processi
echo.
echo   [5] RIPRISTINA MODIFICHE TOOLKIT
 echo      Annulla le modifiche registrate nell'ultima sessione
echo.
echo   [6] ESCI
echo.
set "scelta="
set /p "scelta=Scelta: "
if "%scelta%"=="1" set "preset=Standard"& goto AVVIA
if "%scelta%"=="2" set "preset=Gaming"& goto AVVIA
if "%scelta%"=="3" set "preset=Business"& goto AVVIA
if "%scelta%"=="4" goto TOOLS
if "%scelta%"=="5" goto UNDO
if "%scelta%"=="6" exit /b
echo.
echo Scelta non valida. Premi un tasto e riprova.
pause >nul
goto MENU

:AVVIA
cls
echo ==================================================
echo       TECNICO DIGITALE - WINDOWS TOOLKIT
echo                 Versione %TDT_VERSION%
echo ==================================================
echo.
echo Profilo selezionato: %preset%
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Setup.ps1" -Preset "%preset%"
goto FINE

:TOOLS
cls
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Strumenti-Tecnico.ps1"
goto MENU

:UNDO
cls
echo ==================================================
echo       TECNICO DIGITALE - RIPRISTINO MODIFICHE
echo                 Versione %TDT_VERSION%
echo ==================================================
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Undo.ps1"

:FINE
echo.
echo ==================================================
echo Esecuzione terminata. Premi un tasto per chiudere.
echo ==================================================
pause >nul
endlocal
