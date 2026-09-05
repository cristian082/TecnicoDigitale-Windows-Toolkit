[CmdletBinding()]
param(
    [string]$TargetPath
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Write-Step {
    param([string]$Text)
    Write-Host $Text -ForegroundColor Cyan
}

# IMPORTANTE: non usare $PSScriptRoot come valore predefinito nel blocco param.
# In Windows PowerShell 5.1 puo non essere ancora valorizzato durante il binding
# dei parametri. Risolviamo il target solo dopo l'avvio dello script.
if ([string]::IsNullOrWhiteSpace($TargetPath)) {
    $target = $PSScriptRoot
}
else {
    $cleanTarget = ([string]$TargetPath).Trim().Trim('"')
    if (-not (Test-Path -LiteralPath $cleanTarget -PathType Container)) {
        throw "Cartella Toolkit non trovata: $cleanTarget"
    }
    $target = (Resolve-Path -LiteralPath $cleanTarget).Path
}

if ([string]::IsNullOrWhiteSpace($target) -or -not (Test-Path -LiteralPath $target -PathType Container)) {
    throw "Impossibile determinare la cartella del Toolkit. PSScriptRoot='$PSScriptRoot'"
}

$repoZip = 'https://github.com/cristian082/TecnicoDigitale-Windows-Toolkit/archive/refs/heads/main.zip'
$tmpRoot = Join-Path $env:TEMP ('TDT-Toolkit-Update-' + [guid]::NewGuid().ToString('N'))
$zipPath = Join-Path $tmpRoot 'Toolkit.zip'
$extractPath = Join-Path $tmpRoot 'extract'
$sourcePath = Join-Path $extractPath 'TecnicoDigitale-Windows-Toolkit-main'
$logPath = Join-Path $target 'Aggiornamento-Toolkit.log'

$protectedPrefixes = @(
    'backups',
    'logs',
    'reports',
    'lab\reports'
)

$obsoleteFiles = @(
    'lab\LTSC-Deep-Audit.ps1',
    'lab\Compare-LTSC-Deep-Audit.ps1'
)

function Test-ProtectedRelativePath {
    param([string]$RelativePath)
    foreach ($prefix in $protectedPrefixes) {
        if ($RelativePath.Equals($prefix, [StringComparison]::OrdinalIgnoreCase) -or
            $RelativePath.StartsWith($prefix + '\', [StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }
    return $false
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
    ('Target: ' + $target) | Add-Content -LiteralPath $logPath -Encoding UTF8

    Write-Step '[1/5] Download ultima versione da GitHub...'
    Invoke-WebRequest -Uri $repoZip -OutFile $zipPath -UseBasicParsing
    if (-not (Test-Path -LiteralPath $zipPath) -or (Get-Item -LiteralPath $zipPath).Length -lt 1024) {
        throw 'Download non valido o incompleto.'
    }

    Write-Step '[2/5] Estrazione archivio...'
    New-Item -ItemType Directory -Path $extractPath -Force | Out-Null
    Expand-Archive -LiteralPath $zipPath -DestinationPath $extractPath -Force

    if (-not (Test-Path -LiteralPath (Join-Path $sourcePath 'VERSION.json'))) {
        throw 'Archivio GitHub non valido: VERSION.json non trovato.'
    }
    if (-not (Test-Path -LiteralPath (Join-Path $sourcePath 'Avvia-Toolkit.cmd'))) {
        throw 'Archivio GitHub non valido: Avvia-Toolkit.cmd non trovato.'
    }

    $remoteVersion = '?'
    $localVersion = '?'
    try { $remoteVersion = (Get-Content (Join-Path $sourcePath 'VERSION.json') -Raw | ConvertFrom-Json).version } catch { }
    try { $localVersion = (Get-Content (Join-Path $target 'VERSION.json') -Raw | ConvertFrom-Json).version } catch { }
    Write-Host ("Versione locale : {0}" -f $localVersion)
    Write-Host ("Versione remota : {0}" -f $remoteVersion)
    Write-Host ''

    Write-Step '[3/5] Aggiornamento file...'
    $copied = 0
    foreach ($file in Get-ChildItem -LiteralPath $sourcePath -Recurse -File) {
        $relative = $file.FullName.Substring($sourcePath.Length).TrimStart('\')
        if (Test-ProtectedRelativePath $relative) { continue }
        if ($relative.Equals('Aggiornamento-Toolkit.log', [StringComparison]::OrdinalIgnoreCase)) { continue }

        $destination = Join-Path $target $relative
        $destinationDir = Split-Path -Parent $destination
        if (-not (Test-Path -LiteralPath $destinationDir)) {
            New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
        }
        Copy-Item -LiteralPath $file.FullName -Destination $destination -Force
        ('COPIATO: ' + $relative) | Add-Content -LiteralPath $logPath -Encoding UTF8
        $copied++
    }

    Write-Step '[4/5] Rimozione componenti obsoleti...'
    foreach ($relative in $obsoleteFiles) {
        $path = Join-Path $target $relative
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            Remove-Item -LiteralPath $path -Force
            ('RIMOSSO OBSOLETO: ' + $relative) | Add-Content -LiteralPath $logPath -Encoding UTF8
            Write-Host ('  Rimosso: ' + $relative)
        }
    }

    Write-Step '[5/5] Verifica finale...'
    $required = @(
        'VERSION.json',
        'Avvia-Toolkit.cmd',
        'Avvia-Lab.cmd',
        'Setup.ps1',
        'Update-Toolkit.ps1',
        'lab\Deep-Audit.ps1',
        'lab\Compare-Baseline.ps1',
        'lab\baselines\Windows11-Pro-Clean-Before-Standard.json'
    )
    foreach ($relative in $required) {
        if (-not (Test-Path -LiteralPath (Join-Path $target $relative) -PathType Leaf)) {
            throw "Verifica finale fallita: manca $relative"
        }
    }

    ('File copiati: ' + $copied) | Add-Content -LiteralPath $logPath -Encoding UTF8
    ('RISULTATO: OK') | Add-Content -LiteralPath $logPath -Encoding UTF8

    Write-Host ''
    Write-Host ("Aggiornamento completato. File aggiornati: {0}" -f $copied) -ForegroundColor Green
    Write-Host ('Log: ' + $logPath)
    exit 0
}
catch {
    try { ('ERRORE: ' + $_.Exception.ToString()) | Add-Content -LiteralPath $logPath -Encoding UTF8 } catch { }
    Write-Host ''
    Write-Host ('ERRORE AGGIORNAMENTO: ' + $_.Exception.Message) -ForegroundColor Red
    Write-Host ('Log: ' + $logPath) -ForegroundColor Yellow
    exit 1
}
finally {
    Remove-Item -LiteralPath $tmpRoot -Recurse -Force -ErrorAction SilentlyContinue
}
