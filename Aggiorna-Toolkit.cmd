@echo off
setlocal EnableExtensions

:: Bootstrap: esegui l'aggiornamento da una copia temporanea, cosi il file
:: Aggiorna-Toolkit.cmd nella cartella del Toolkit puo essere sostituito senza
:: interferire con il batch attualmente in esecuzione.
if /I not "%~1"=="--worker" (
    set "WORKER=%TEMP%\TDT-Aggiorna-Toolkit-%RANDOM%-%RANDOM%.cmd"
    copy /y "%~f0" "%WORKER%" >nul
    if errorlevel 1 (
        echo ERRORE: impossibile creare il processo temporaneo di aggiornamento.
        pause
        exit /b 1
    )
    call "%WORKER%" --worker "%~dp0"
    set "RC=%ERRORLEVEL%"
    del /q "%WORKER%" >nul 2>&1
    exit /b %RC%
)

set "TARGET=%~2"
if not defined TARGET exit /b 1
cd /d "%TARGET%"

set "REPO_ZIP=https://github.com/cristian082/TecnicoDigitale-Windows-Toolkit/archive/refs/heads/main.zip"
set "TMPROOT=%TEMP%\TDT-Toolkit-Update-%RANDOM%-%RANDOM%"
set "ZIPFILE=%TMPROOT%\Toolkit.zip"
set "EXTRACT=%TMPROOT%\extract"
set "SOURCE=%EXTRACT%\TecnicoDigitale-Windows-Toolkit-main"
set "LOGFILE=%TARGET%Aggiornamento-Toolkit.log"

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
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue'; Invoke-WebRequest '%REPO_ZIP%' -OutFile '%ZIPFILE%'"
if errorlevel 1 goto ERRORE

echo [2/4] Estrazione...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; Expand-Archive -LiteralPath '%ZIPFILE%' -DestinationPath '%EXTRACT%' -Force"
if errorlevel 1 goto ERRORE

if not exist "%SOURCE%\VERSION.json" (
    echo ERRORE: archivio estratto non valido.
    goto ERRORE
)

echo [3/4] Aggiornamento file...
echo Dettagli copia: "%LOGFILE%"

:: /E copia l'albero senza cancellare file locali. Le cartelle dati locali sono
:: escluse esplicitamente: report, backup e log non devono essere toccati.
robocopy "%SOURCE%" "%TARGET%" /E /R:2 /W:1 /XD "%SOURCE%\lab\reports" "%SOURCE%\backups" "%SOURCE%\logs" /XF "Aggiornamento-Toolkit.log" /NP /TEE /LOG:"%LOGFILE%"
set "RC=%ERRORLEVEL%"

:: Robocopy: 0-7 = successo (con o senza differenze); >=8 = errore reale.
if %RC% GEQ 8 (
    echo.
    echo ERRORE ROBOCOPY: codice %RC%.
    echo Controlla il log: "%LOGFILE%"
    goto ERRORE
)

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
if exist "%LOGFILE%" echo Log disponibile in: "%LOGFILE%"
pause
exit /b 1
