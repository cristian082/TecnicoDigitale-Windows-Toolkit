@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: Bootstrap: esegui l'aggiornamento da una copia temporanea.
if /I not "%~1"=="--worker" (
    set "WORKER=%TEMP%\TDT-Aggiorna-Toolkit-%RANDOM%-%RANDOM%.cmd"
    copy /y "%~f0" "!WORKER!" >nul
    if errorlevel 1 (
        echo ERRORE: impossibile creare il processo temporaneo di aggiornamento.
        pause
        exit /b 1
    )
    call "!WORKER!" --worker "%~dp0"
    set "RC=!ERRORLEVEL!"
    del /q "!WORKER!" >nul 2>&1
    if not "!RC!"=="0" (
        echo.
        echo L'aggiornamento e terminato con errore !RC!.
        echo La finestra resta aperta per permettere di leggere il messaggio.
        pause
    )
    exit /b !RC!
)

set "TARGET=%~2"
if not defined TARGET (
    echo ERRORE: cartella Toolkit non ricevuta dal processo di aggiornamento.
    pause
    exit /b 1
)
cd /d "%TARGET%" || (
    echo ERRORE: impossibile accedere alla cartella Toolkit: "%TARGET%"
    pause
    exit /b 1
)

set "REPO_ZIP=https://github.com/cristian082/TecnicoDigitale-Windows-Toolkit/archive/refs/heads/main.zip"
set "TMPROOT=%TEMP%\TDT-Toolkit-Update-%RANDOM%-%RANDOM%"
set "ZIPFILE=%TMPROOT%\Toolkit.zip"
set "EXTRACT=%TMPROOT%\extract"
set "SOURCE=%EXTRACT%\TecnicoDigitale-Windows-Toolkit-main"
set "LOGFILE=%TARGET%Aggiornamento-Toolkit.log"

>"%LOGFILE%" echo === Tecnico Digitale Toolkit Updater - %date% %time% ===
cls
echo ==============================================================
echo       TECNICO DIGITALE - AGGIORNAMENTO TOOLKIT
echo ==============================================================
echo.
echo Cartella Toolkit: %TARGET%
echo Scarico l'ultima versione da GitHub senza usare Git.
echo I report, backup e log gia presenti NON vengono cancellati.
echo.

if exist "%TMPROOT%" rmdir /s /q "%TMPROOT%"
mkdir "%TMPROOT%" >nul 2>&1 || goto ERRORE
mkdir "%EXTRACT%" >nul 2>&1 || goto ERRORE

echo [1/4] Download ultima versione...
echo [1/4] Download ultima versione...>>"%LOGFILE%"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri $env:REPO_ZIP -OutFile $env:ZIPFILE" >>"%LOGFILE%" 2>&1
if errorlevel 1 (
    echo ERRORE durante il download da GitHub.
    goto ERRORE
)

echo [2/4] Estrazione...
echo [2/4] Estrazione...>>"%LOGFILE%"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; Expand-Archive -LiteralPath $env:ZIPFILE -DestinationPath $env:EXTRACT -Force" >>"%LOGFILE%" 2>&1
if errorlevel 1 (
    echo ERRORE durante l'estrazione dell'archivio.
    goto ERRORE
)

if not exist "%SOURCE%\VERSION.json" (
    echo ERRORE: archivio estratto non valido.
    echo ERRORE: VERSION.json non trovato in "%SOURCE%">>"%LOGFILE%"
    goto ERRORE
)

echo [3/4] Aggiornamento file...
echo Dettagli copia: "%LOGFILE%"
echo [3/4] Aggiornamento file...>>"%LOGFILE%"
robocopy "%SOURCE%" "%TARGET%" /E /R:2 /W:1 /XD "%SOURCE%\lab\reports" "%SOURCE%\backups" "%SOURCE%\logs" /XF "Aggiornamento-Toolkit.log" /NP /TEE /LOG+:"%LOGFILE%"
set "RC=!ERRORLEVEL!"
if !RC! GEQ 8 (
    echo ERRORE ROBOCOPY: codice !RC!.
    goto ERRORE
)

echo [4/4] Pulizia file temporanei...
rmdir /s /q "%TMPROOT%" >nul 2>&1

echo.
echo ==============================================================
echo Aggiornamento completato.
echo ==============================================================
pause
exit /b 0

:ERRORE
echo.
echo ==============================================================
echo AGGIORNAMENTO NON RIUSCITO
echo ==============================================================
echo Log disponibile in: "%LOGFILE%"
echo.
if exist "%LOGFILE%" type "%LOGFILE%"
echo.
echo La finestra rimarra aperta finche non premi un tasto.
pause
exit /b 1
