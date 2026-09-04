[CmdletBinding(SupportsShouldProcess=$true)]
param([string]$BackupPath)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

function Test-Administrator {$id=[Security.Principal.WindowsIdentity]::GetCurrent();$principal=New-Object Security.Principal.WindowsPrincipal($id);return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)}
if(-not(Test-Administrator)){throw 'Eseguire Undo.ps1 come amministratore.'}

$versionModule=Join-Path $Root 'modules\Version.ps1';if(Test-Path $versionModule){. $versionModule;$currentVersion=Get-TDTVersionInfo -Root $Root}else{$currentVersion=$null}
if(-not $BackupPath){$backupDir=Join-Path $Root 'backups';$latest=Get-ChildItem -LiteralPath $backupDir -Filter 'Session-*.json' -File -ErrorAction SilentlyContinue|Sort-Object LastWriteTime -Descending|Select-Object -First 1;if(-not $latest){throw 'Nessun backup del Toolkit trovato.'};$BackupPath=$latest.FullName}
$BackupPath=(Resolve-Path -LiteralPath $BackupPath).Path;$backup=Get-Content -LiteralPath $BackupPath -Raw|ConvertFrom-Json
if([int]$backup.SchemaVersion-ne 1){throw "Formato backup non supportato: $($backup.SchemaVersion)"}
if($backup.ComputerName-and $backup.ComputerName-ne $env:COMPUTERNAME){throw "Il backup appartiene al PC '$($backup.ComputerName)', non a '$env:COMPUTERNAME'."}

Write-Host '==================================================' -ForegroundColor Cyan
Write-Host ' TECNICO DIGITALE - RIPRISTINO MODIFICHE' -ForegroundColor Cyan
Write-Host '==================================================' -ForegroundColor Cyan
if($currentVersion){Write-Host ("Toolkit corrente: v{0} - Build {1}" -f $currentVersion.Version,$currentVersion.Build)}
if($backup.PSObject.Properties.Name -contains 'ToolkitVersion'){Write-Host ("Backup creato da: v{0} - Build {1}" -f $backup.ToolkitVersion,$backup.ToolkitBuild)}
Write-Host "Backup: $BackupPath";Write-Host "Preset: $($backup.Preset)";Write-Host "Creato: $($backup.CreatedAt)";Write-Host "Valori registro da ripristinare: $(@($backup.Registry).Count)";Write-Host ''
if(-not $WhatIfPreference){$answer=Read-Host 'Procedere con il ripristino? [S/N]';if($answer-notmatch'^(s|si|sì|y|yes)$'){Write-Host 'Ripristino annullato.' -ForegroundColor Yellow;return}}
$errors=0
foreach($entry in @($backup.Registry)){try{if($entry.ValueExisted){if($PSCmdlet.ShouldProcess("$($entry.Path)\$($entry.Name)",'Ripristinare valore originale')){if(-not(Test-Path $entry.Path)){New-Item -Path $entry.Path -Force|Out-Null};$propertyType=switch($entry.Kind){'DWord'{'DWord'}'QWord'{'QWord'}'Binary'{'Binary'}'MultiString'{'MultiString'}'ExpandString'{'ExpandString'}default{'String'}};New-ItemProperty -Path $entry.Path -Name $entry.Name -PropertyType $propertyType -Value $entry.Value -Force|Out-Null}}else{if($PSCmdlet.ShouldProcess("$($entry.Path)\$($entry.Name)",'Rimuovere valore creato dal Toolkit')){if(Test-Path $entry.Path){Remove-ItemProperty -Path $entry.Path -Name $entry.Name -ErrorAction SilentlyContinue}}}}catch{$errors++;Write-Warning "Ripristino fallito per $($entry.Path)\$($entry.Name): $($_.Exception.Message)"}}
if($errors-eq 0){Write-Host 'Ripristino completato per le modifiche di registro registrate.' -ForegroundColor Green}else{Write-Warning "Ripristino completato con $errors errore/i."}
Write-Host 'Nota: in questa prima versione Undo copre le modifiche di registro registrate.' -ForegroundColor Yellow
