[CmdletBinding()]
param(
    [string]$TargetPath
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Write-Step { param([string]$Text) Write-Host $Text -ForegroundColor Cyan }

if ([string]::IsNullOrWhiteSpace($TargetPath)) { $target = $PSScriptRoot }
else {
    $cleanTarget = ([string]$TargetPath).Trim().Trim('"')
    if (-not (Test-Path -LiteralPath $cleanTarget -PathType Container)) { throw "Cartella Toolkit non trovata: $cleanTarget" }
    $target = (Resolve-Path -LiteralPath $cleanTarget).Path
}
if ([string]::IsNullOrWhiteSpace($target) -or -not (Test-Path -LiteralPath $target -PathType Container)) { throw "Impossibile determinare la cartella del Toolkit." }

$repoZip = 'https://github.com/cristian082/TecnicoDigitale-Windows-Toolkit/archive/refs/heads/main.zip'
$tmpRoot = Join-Path $env:TEMP ('TDT-Toolkit-Update-' + [guid]::NewGuid().ToString('N'))
$zipPath = Join-Path $tmpRoot 'Toolkit.zip'
$extractPath = Join-Path $tmpRoot 'extract'
$sourcePath = Join-Path $extractPath 'TecnicoDigitale-Windows-Toolkit-main'
$logPath = Join-Path $target 'Aggiornamento-Toolkit.log'
$protectedPrefixes = @('backups','logs','reports','lab\reports')
$obsoleteFiles = @('lab\LTSC-Deep-Audit.ps1','lab\Compare-LTSC-Deep-Audit.ps1')

function Test-ProtectedRelativePath {
    param([string]$RelativePath)
    foreach ($prefix in $protectedPrefixes) {
        if ($RelativePath.Equals($prefix,[StringComparison]::OrdinalIgnoreCase) -or $RelativePath.StartsWith($prefix+'\',[StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
    return $false
}

function Remove-StrayUpdaterDirectory {
    param([string]$Root)
    $stray = Join-Path $Root 'n'
    if (-not (Test-Path -LiteralPath $stray -PathType Container)) { return }
    $signature = @('VERSION.json','Avvia-Toolkit.cmd','Setup.ps1','modules','presets')
    foreach ($item in $signature) { if (-not (Test-Path -LiteralPath (Join-Path $stray $item))) { return } }
    Write-Host "  Rimozione cartella spuria del vecchio updater: $stray" -ForegroundColor Yellow
    Remove-Item -LiteralPath $stray -Recurse -Force
    ('RIMOSSA CARTELLA SPURIA: n') | Add-Content -LiteralPath $logPath -Encoding UTF8
}

try {
    Write-Host '=============================================================='
    Write-Host '      TECNICO DIGITALE - AGGIORNAMENTO TOOLKIT'
    Write-Host '=============================================================='
    Write-Host ('Cartella Toolkit: ' + $target)
    Write-Host ''
    try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { }
    New-Item -ItemType Directory -Path $tmpRoot -Force | Out-Null
    ('=== Aggiornamento Toolkit {0} ===' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) | Set-Content -LiteralPath $logPath -Encoding UTF8
    ('Target: '+$target) | Add-Content -LiteralPath $logPath -Encoding UTF8

    Write-Step '[1/5] Download ultima versione da GitHub...'
    Invoke-WebRequest -Uri $repoZip -OutFile $zipPath -UseBasicParsing
    if (-not (Test-Path -LiteralPath $zipPath) -or (Get-Item -LiteralPath $zipPath).Length -lt 1024) { throw 'Download non valido o incompleto.' }

    Write-Step '[2/5] Estrazione archivio...'
    New-Item -ItemType Directory -Path $extractPath -Force | Out-Null
    Expand-Archive -LiteralPath $zipPath -DestinationPath $extractPath -Force
    if (-not (Test-Path -LiteralPath (Join-Path $sourcePath 'VERSION.json'))) { throw 'Archivio GitHub non valido: VERSION.json non trovato.' }
    if (-not (Test-Path -LiteralPath (Join-Path $sourcePath 'Avvia-Toolkit.cmd'))) { throw 'Archivio GitHub non valido: Avvia-Toolkit.cmd non trovato.' }

    $remoteVersion='?'; $localVersion='?'; $remoteBuild='?'; $localBuild='?'
    try {
        $remoteInfo = Get-Content (Join-Path $sourcePath 'VERSION.json') -Raw | ConvertFrom-Json
        $remoteVersion = [string]$remoteInfo.version
        if ($null -ne $remoteInfo.PSObject.Properties['build']) { $remoteBuild = [string]$remoteInfo.build }
    } catch {}
    try {
        $localInfo = Get-Content (Join-Path $target 'VERSION.json') -Raw | ConvertFrom-Json
        $localVersion = [string]$localInfo.version
        if ($null -ne $localInfo.PSObject.Properties['build']) { $localBuild = [string]$localInfo.build }
    } catch {}
    Write-Host ("Versione locale : {0} (Build {1})" -f $localVersion,$localBuild)
    Write-Host ("Versione remota : {0} (Build {1})" -f $remoteVersion,$remoteBuild)
    Write-Host ''

    Write-Step '[3/5] Aggiornamento file...'
    $copied=0
    # Non confrontiamo stringhe di path assoluti: Windows puo restituire lo stesso TEMP
    # in forma lunga (Users\Win11 Pro) o 8.3 (Users\WIN11P~1). Enumeriamo invece
    # i file relativamente alla directory sorgente, eliminando alla radice il problema.
    Push-Location -LiteralPath $sourcePath
    try {
        foreach ($file in Get-ChildItem -LiteralPath . -Recurse -File) {
            $relative = $file.FullName.Substring((Get-Location).Path.Length).TrimStart('\')
            if ([string]::IsNullOrWhiteSpace($relative) -or [IO.Path]::IsPathRooted($relative)) { throw "Percorso relativo non valido: $relative" }
            if (Test-ProtectedRelativePath $relative) { continue }
            if ($relative.Equals('Aggiornamento-Toolkit.log',[StringComparison]::OrdinalIgnoreCase)) { continue }
            $destination=Join-Path $target $relative
            $destinationDir=Split-Path -Parent $destination
            if (-not (Test-Path -LiteralPath $destinationDir)) { New-Item -ItemType Directory -Path $destinationDir -Force|Out-Null }
            Copy-Item -LiteralPath $file.FullName -Destination $destination -Force
            ('COPIATO: '+$relative)|Add-Content -LiteralPath $logPath -Encoding UTF8
            $copied++
        }
    }
    finally { Pop-Location }

    Write-Step '[4/5] Pulizia componenti obsoleti...'
    foreach ($relative in $obsoleteFiles) {
        $path=Join-Path $target $relative
        if (Test-Path -LiteralPath $path -PathType Leaf) { Remove-Item -LiteralPath $path -Force; ('RIMOSSO OBSOLETO: '+$relative)|Add-Content -LiteralPath $logPath -Encoding UTF8 }
    }
    Remove-StrayUpdaterDirectory -Root $target

    Write-Step '[5/5] Verifica finale...'
    $required=@('VERSION.json','Avvia-Toolkit.cmd','Avvia-Lab.cmd','Setup.ps1','Update-Toolkit.ps1','lab\Deep-Audit.ps1','lab\Compare-Baseline.ps1','lab\baselines\Windows11-Pro-Clean-Before-Standard.json')
    foreach ($relative in $required) { if (-not (Test-Path -LiteralPath (Join-Path $target $relative) -PathType Leaf)) { throw "Verifica finale fallita: manca $relative" } }
    if (Test-Path -LiteralPath (Join-Path $target 'n') -PathType Container) { Write-Warning "Esiste ancora una cartella 'n'. Non rimossa per sicurezza." }
    ('File copiati: '+$copied)|Add-Content -LiteralPath $logPath -Encoding UTF8
    'RISULTATO: OK'|Add-Content -LiteralPath $logPath -Encoding UTF8
    Write-Host ''
    Write-Host ("Aggiornamento completato. File aggiornati: {0}" -f $copied) -ForegroundColor Green
    Write-Host ("Versione installata: {0} (Build {1})" -f $remoteVersion,$remoteBuild) -ForegroundColor Green
    Write-Host ('Log: '+$logPath)
    exit 0
}
catch {
    try { ('ERRORE: '+$_.Exception.ToString())|Add-Content -LiteralPath $logPath -Encoding UTF8 } catch {}
    Write-Host ''
    Write-Host ('ERRORE AGGIORNAMENTO: '+$_.Exception.Message) -ForegroundColor Red
    Write-Host ('Log: '+$logPath) -ForegroundColor Yellow
    exit 1
}
finally { Remove-Item -LiteralPath $tmpRoot -Recurse -Force -ErrorAction SilentlyContinue }
