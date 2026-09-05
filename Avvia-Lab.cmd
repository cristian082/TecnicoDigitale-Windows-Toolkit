@echo off
setlocal EnableExtensions
cd /d "%~dp0"

set "TDT_VERSION=sconosciuta"
for /f "usebackq delims=" %%V in (`powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$v=Get-Content '%~dp0VERSION.json' -Raw|ConvertFrom-Json; $v.version"`) do set "TDT_VERSION=%%V"

:: Il laboratorio usa privilegi elevati per ottenere dati completi e coerenti.
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -Verb RunAs -ArgumentList '/c ""%~f0""'"
    exit /b
)

:MENU
cls
echo ==============================================================
echo       TECNICO DIGITALE - TEST LAB
echo                Toolkit v%TDT_VERSION%
echo ==============================================================
echo.
echo   [1] AUDIT SERVIZI - WINDOWS 11 PRO 25H2
echo   [2] AUDIT SERVIZI - WINDOWS 11 LTSC 2024
echo   [3] CONFRONTA ULTIMI AUDIT SERVIZI PRO vs LTSC
echo.
echo   [4] LTSC DEEP AUDIT - RILEVAMENTO AUTOMATICO WINDOWS
echo.
echo   [5] APRI CARTELLA REPORT
echo   [6] ESCI
echo.
set "scelta="
set /p "scelta=Scelta: "

if "%scelta%"=="1" goto AUDIT_PRO
if "%scelta%"=="2" goto AUDIT_LTSC
if "%scelta%"=="3" goto COMPARE
if "%scelta%"=="4" goto DEEP_AUTO
if "%scelta%"=="5" goto REPORTS
if "%scelta%"=="6" exit /b

echo.
echo Scelta non valida.
pause
goto MENU

:AUDIT_PRO
cls
echo ==============================================================
echo AUDIT SERVIZI - PRO 25H2
echo ==============================================================
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0lab\Services-Audit.ps1" -Label "PRO-25H2"
goto FINE

:AUDIT_LTSC
cls
echo ==============================================================
echo AUDIT SERVIZI - LTSC 2024
echo ==============================================================
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0lab\Services-Audit.ps1" -Label "LTSC-2024"
goto FINE

:COMPARE
cls
echo ==============================================================
echo CONFRONTO ULTIMI AUDIT - LTSC 2024 vs PRO 25H2
echo ==============================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "$reports=Join-Path '%~dp0' 'lab\reports';" ^
  "$l=Get-ChildItem $reports -Filter 'Services-LTSC-2024-*.json' -ErrorAction SilentlyContinue ^| Sort-Object LastWriteTime -Descending ^| Select-Object -First 1;" ^
  "$p=Get-ChildItem $reports -Filter 'Services-PRO-25H2-*.json' -ErrorAction SilentlyContinue ^| Sort-Object LastWriteTime -Descending ^| Select-Object -First 1;" ^
  "if(-not $l -or -not $p){Write-Host 'ERRORE: servono almeno un report LTSC e uno PRO in lab\reports.' -ForegroundColor Red; exit 2};" ^
  "Write-Host ('LTSC: ' + $l.Name); Write-Host ('PRO : ' + $p.Name); Write-Host '';" ^
  "& '%~dp0lab\Compare-Services.ps1' -ReferencePath $l.FullName -CandidatePath $p.FullName"

goto FINE

:DEEP_AUTO
cls
echo ==============================================================
echo LTSC DEEP AUDIT - RILEVAMENTO AUTOMATICO
 echo ==============================================================
echo.
echo Il test e READ-ONLY: non modifica Windows.
echo Puo richiedere alcuni minuti.
echo.

set "DEEP_LABEL="
for /f "usebackq delims=" %%L in (`powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$os=Get-CimInstance Win32_OperatingSystem; if($os.Caption -match 'LTSC'){ 'LTSC-2024' } elseif($os.Caption -match 'Windows 11 Pro'){ 'PRO-25H2' } else { 'WINDOWS-' + $os.BuildNumber }"`) do set "DEEP_LABEL=%%L"

if not defined DEEP_LABEL (
    echo ERRORE: impossibile rilevare automaticamente l'edizione Windows.
    goto FINE
)

echo Sistema rilevato: %DEEP_LABEL%
echo Il report verra salvato con questa etichetta.
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0lab\LTSC-Deep-Audit.ps1" -Label "%DEEP_LABEL%"
goto FINE

:REPORTS
if not exist "%~dp0lab\reports" mkdir "%~dp0lab\reports"
start "" "%~dp0lab\reports"
goto MENU

:FINE
echo.
echo ==============================================================
echo Operazione terminata.
echo ==============================================================
pause
goto MENU
