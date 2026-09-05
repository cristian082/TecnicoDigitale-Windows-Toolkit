@echo off
setlocal EnableExtensions
cd /d "%~dp0"

set "REPO_ZIP=https://github.com/cristian082/TecnicoDigitale-Windows-Toolkit/archive/refs/heads/main.zip"
set "TMPROOT=%TEMP%\TDT-Toolkit-Update"
set "ZIPFILE=%TMPROOT%\Toolkit.zip"
set "EXTRACT=%TMPROOT%\extract"
set "SOURCE=%EXTRACT%\TecnicoDigitale-Windows-Toolkit-main"

cls
echo ==============================================================
echo       TECNICO DIGITALE - AGGIORNAMENTO TOOLKIT
echo ==============================================================
echo.
echo Scarico l'ultima versione da GitHub senza usare Git.
echo I report, backup e log gia presenti NON vengono cancellati.
echo.

if exist "%TMPROOT%" rmdir /s /q "%TMPROOT%"
mkdir "%TMPROOT%" >nul 2>&1
mkdir "%EXTRACT%" >nul 2>&1

echo [1/4] Download ultima versione...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest '%REPO_ZIP%' -OutFile '%ZIPFILE%'"
if errorlevel 1 goto ERRORE

echo [2/4] Estrazione...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "Expand-Archive -LiteralPath '%ZIPFILE%' -DestinationPath '%EXTRACT%' -Force"
if errorlevel 1 goto ERRORE

if not exist "%SOURCE%\VERSION.json" (
    echo ERRORE: archivio estratto non valido.
    goto ERRORE
)

echo [3/4] Aggiornamento file...
robocopy "%SOURCE%" "%~dp0" /E /R:2 /W:1 /NFL /NDL /NJH /NJS /NP >nul
set "RC=%ERRORLEVEL%"
if %RC% GEQ 8 goto ERRORE

echo [4/4] Pulizia file temporanei...
rmdir /s /q "%TMPROOT%" >nul 2>&1

echo.
echo ==============================================================
echo Aggiornamento completato.
echo Nessun Git richiesto.
echo ==============================================================
echo.
echo Puoi ora avviare Avvia-Lab.cmd oppure Avvia-Toolkit.cmd
pause
exit /b 0

:ERRORE
echo.
echo ==============================================================
echo AGGIORNAMENTO NON RIUSCITO
 echo Nessun file personale e stato cancellato intenzionalmente.
echo ==============================================================
echo.
pause
exit /b 1
