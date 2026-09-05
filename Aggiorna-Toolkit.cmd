@echo off
setlocal EnableExtensions
cd /d "%~dp0"

set "TDT_UPDATE_PS=%TEMP%\TDT-Update-%RANDOM%-%RANDOM%.ps1"

>"%TDT_UPDATE_PS%" echo $ErrorActionPreference = 'Stop'
>>"%TDT_UPDATE_PS%" echo $ProgressPreference = 'SilentlyContinue'
>>"%TDT_UPDATE_PS%" echo $target = [IO.Path]::GetFullPath($args[0]).TrimEnd('\')
>>"%TDT_UPDATE_PS%" echo $repo = 'https://github.com/cristian082/TecnicoDigitale-Windows-Toolkit/archive/refs/heads/main.zip'
>>"%TDT_UPDATE_PS%" echo $tmp = Join-Path $env:TEMP ('TDT-Toolkit-Update-' + [guid]::NewGuid().ToString('N'))
>>"%TDT_UPDATE_PS%" echo $zip = Join-Path $tmp 'Toolkit.zip'
>>"%TDT_UPDATE_PS%" echo $extract = Join-Path $tmp 'extract'
>>"%TDT_UPDATE_PS%" echo $source = Join-Path $extract 'TecnicoDigitale-Windows-Toolkit-main'
>>"%TDT_UPDATE_PS%" echo $log = Join-Path $target 'Aggiornamento-Toolkit.log'
>>"%TDT_UPDATE_PS%" echo try {
>>"%TDT_UPDATE_PS%" echo   Write-Host '=============================================================='
>>"%TDT_UPDATE_PS%" echo   Write-Host '      TECNICO DIGITALE - AGGIORNAMENTO TOOLKIT'
>>"%TDT_UPDATE_PS%" echo   Write-Host '=============================================================='
>>"%TDT_UPDATE_PS%" echo   Write-Host ('Cartella Toolkit: ' + $target)
>>"%TDT_UPDATE_PS%" echo   New-Item -ItemType Directory -Path $tmp,$extract -Force ^| Out-Null
>>"%TDT_UPDATE_PS%" echo   ('=== Updater ' + (Get-Date) + ' ===') ^| Set-Content -LiteralPath $log
>>"%TDT_UPDATE_PS%" echo   Write-Host '[1/4] Download ultima versione...'
>>"%TDT_UPDATE_PS%" echo   Invoke-WebRequest -Uri $repo -OutFile $zip
>>"%TDT_UPDATE_PS%" echo   Write-Host '[2/4] Estrazione...'
>>"%TDT_UPDATE_PS%" echo   Expand-Archive -LiteralPath $zip -DestinationPath $extract -Force
>>"%TDT_UPDATE_PS%" echo   if(-not (Test-Path (Join-Path $source 'VERSION.json'))) { throw 'Archivio GitHub non valido: VERSION.json non trovato.' }
>>"%TDT_UPDATE_PS%" echo   Write-Host '[3/4] Aggiornamento file...'
>>"%TDT_UPDATE_PS%" echo   $excluded = @('lab\reports','backups','logs')
>>"%TDT_UPDATE_PS%" echo   Get-ChildItem -LiteralPath $source -Recurse -File ^| ForEach-Object {
>>"%TDT_UPDATE_PS%" echo     $rel = $_.FullName.Substring($source.Length).TrimStart('\')
>>"%TDT_UPDATE_PS%" echo     if($rel -eq 'Aggiornamento-Toolkit.log') { return }
>>"%TDT_UPDATE_PS%" echo     foreach($x in $excluded) { if($rel -eq $x -or $rel.StartsWith($x + '\',[StringComparison]::OrdinalIgnoreCase)) { return } }
>>"%TDT_UPDATE_PS%" echo     $dest = Join-Path $target $rel
>>"%TDT_UPDATE_PS%" echo     $dir = Split-Path -Parent $dest
>>"%TDT_UPDATE_PS%" echo     if(-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force ^| Out-Null }
>>"%TDT_UPDATE_PS%" echo     Copy-Item -LiteralPath $_.FullName -Destination $dest -Force
>>"%TDT_UPDATE_PS%" echo     ('COPIATO: ' + $rel) ^| Add-Content -LiteralPath $log
>>"%TDT_UPDATE_PS%" echo   }
>>"%TDT_UPDATE_PS%" echo   Write-Host '[4/4] Pulizia file temporanei...'
>>"%TDT_UPDATE_PS%" echo   Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
>>"%TDT_UPDATE_PS%" echo   Write-Host ''
>>"%TDT_UPDATE_PS%" echo   Write-Host 'Aggiornamento completato correttamente.' -ForegroundColor Green
>>"%TDT_UPDATE_PS%" echo   exit 0
>>"%TDT_UPDATE_PS%" echo } catch {
>>"%TDT_UPDATE_PS%" echo   Write-Host ''
>>"%TDT_UPDATE_PS%" echo   Write-Host ('ERRORE: ' + $_.Exception.Message) -ForegroundColor Red
>>"%TDT_UPDATE_PS%" echo   try { ('ERRORE: ' + $_.Exception.ToString()) ^| Add-Content -LiteralPath $log } catch {}
>>"%TDT_UPDATE_PS%" echo   Write-Host ('Log: ' + $log)
>>"%TDT_UPDATE_PS%" echo   exit 1
>>"%TDT_UPDATE_PS%" echo }

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%TDT_UPDATE_PS%" "%~dp0"
set "RC=%ERRORLEVEL%"
del /q "%TDT_UPDATE_PS%" >nul 2>&1

echo.
if not "%RC%"=="0" echo L'aggiornamento e terminato con errore %RC%.
echo Premi un tasto per chiudere.
pause >nul
exit /b %RC%
