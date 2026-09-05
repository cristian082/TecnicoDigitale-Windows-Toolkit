@echo off
setlocal EnableExtensions
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
echo ==============================================================
echo       TECNICO DIGITALE - TEST LAB
echo                Toolkit v%TDT_VERSION%
echo ==============================================================
echo.
echo   [1] CREA DEEP AUDIT SISTEMA ATTUALE
echo   [2] CONFRONTA ULTIMO AUDIT CON BASELINE WINDOWS 11 PRO
echo   [3] AUDIT SERVIZI SISTEMA ATTUALE
echo   [4] APRI CARTELLA REPORT
echo   [5] APRI CARTELLA BASELINE
echo   [0] ESCI
echo.
set "scelta="
set /p "scelta=Scelta: "
if "%scelta%"=="1" goto DEEP
if "%scelta%"=="2" goto BASELINE_COMPARE
if "%scelta%"=="3" goto SERVICES
if "%scelta%"=="4" goto REPORTS
if "%scelta%"=="5" goto BASELINES
if "%scelta%"=="0" exit /b
echo Scelta non valida.&pause&goto MENU
:DEEP
cls
echo ==============================================================
echo DEEP AUDIT - SISTEMA ATTUALE - READ ONLY
echo ==============================================================
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0lab\Deep-Audit.ps1" -Label "CURRENT"
goto FINE
:BASELINE_COMPARE
cls
echo ==============================================================
echo CONFRONTO BASELINE WINDOWS 11 PRO vs SISTEMA ATTUALE
echo ==============================================================
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$reports=Join-Path '%~dp0' 'lab\reports'; $current=Get-ChildItem $reports -Filter 'DeepAudit-*.json' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1; if(-not $current){Write-Host 'ERRORE: nessun Deep Audit trovato. Esegui prima opzione [1].' -ForegroundColor Red; exit 2}; $baseline=Join-Path '%~dp0' 'lab\baselines\Windows11-Pro-Clean-Before-Standard.json'; if(-not(Test-Path $baseline)){Write-Host 'ERRORE: baseline Windows 11 Pro non trovata.' -ForegroundColor Red; exit 3}; Write-Host ('BASELINE: ' + $baseline); Write-Host ('ATTUALE : ' + $current.FullName); Write-Host ''; & '%~dp0lab\Compare-Baseline.ps1' -BaselinePath $baseline -CurrentPath $current.FullName -OutputDirectory $reports"
goto FINE
:SERVICES
cls
echo ==============================================================
echo AUDIT SERVIZI - SISTEMA ATTUALE - READ ONLY
echo ==============================================================
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0lab\Services-Audit.ps1" -Label "CURRENT"
goto FINE
:REPORTS
if not exist "%~dp0lab\reports" mkdir "%~dp0lab\reports"
start "" "%~dp0lab\reports"
goto MENU
:BASELINES
if not exist "%~dp0lab\baselines" mkdir "%~dp0lab\baselines"
start "" "%~dp0lab\baselines"
goto MENU
:FINE
echo.
echo ==============================================================
echo Operazione terminata.
echo ==============================================================
pause
goto MENU
