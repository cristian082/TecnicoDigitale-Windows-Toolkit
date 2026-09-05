@echo off
setlocal EnableExtensions
cd /d "%~dp0"

set "UPDATER=%~dp0Update-Toolkit.ps1"

if not exist "%UPDATER%" (
    echo ==============================================================
    echo       TECNICO DIGITALE - AGGIORNAMENTO TOOLKIT
    echo ==============================================================
    echo.
    echo ERRORE: manca Update-Toolkit.ps1.
    echo Questa copia del Toolkit e troppo vecchia per usare il nuovo updater.
    echo Aggiorna manualmente una volta la cartella dal repository GitHub,
    echo poi gli aggiornamenti successivi potranno essere eseguiti da qui.
    echo.
    pause
    exit /b 2
)

REM Non passiamo %%~dp0 come argomento: termina con backslash e, se quotato,
REM puo essere interpretato da PowerShell con una virgoletta finale nel path.
REM Update-Toolkit.ps1 usa gia $PSScriptRoot come cartella di destinazione.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%UPDATER%"
set "RC=%ERRORLEVEL%"

echo.
if "%RC%"=="0" (
    echo Aggiornamento terminato correttamente.
) else (
    echo Aggiornamento terminato con errore %RC%.
    echo Controlla Aggiornamento-Toolkit.log nella cartella del Toolkit.
)
echo.
echo Premi un tasto per chiudere.
pause >nul
exit /b %RC%
