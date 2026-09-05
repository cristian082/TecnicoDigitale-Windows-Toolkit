[CmdletBinding()]
param(
 [string]$BaselinePath=(Join-Path $PSScriptRoot 'baselines\Windows11-Pro-Clean-Before-Standard.json'),
 [Parameter(Mandatory=$true)][string]$CurrentPath,
 [string]$OutputDirectory=(Join-Path $PSScriptRoot 'reports')
)
Set-StrictMode -Version 2.0;$ErrorActionPreference='Stop'
if(!(Test-Path -LiteralPath $BaselinePath)){throw "Baseline non trovata: $BaselinePath"};if(!(Test-Path -LiteralPath $CurrentPath)){throw "Audit corrente non trovato: $CurrentPath"}
$b=Get-Content -LiteralPath $BaselinePath -Raw -Encoding UTF8|ConvertFrom-Json;$c=Get-Content -LiteralPath $CurrentPath -Raw -Encoding UTF8|ConvertFrom-Json
if(!(Test-Path $OutputDirectory)){New-Item -ItemType Directory $OutputDirectory -Force|Out-Null}
function P($o,$n,$d=$null){if($null-eq$o){return$d};$p=$o.PSObject.Properties[$n];if($null-eq$p){return$d};$p.Value}
function NormSvc([string]$n){if(!$n){return''};$n-replace'_[0-9A-Fa-f]{5,}$','_*'}
function NormStart([string]$n){if(!$n){return''};$n-replace'MicrosoftEdgeAutoLaunch_[A-Fa-f0-9]+','MicrosoftEdgeAutoLaunch_{HASH}'}
Write-Host '=============================================================='
Write-Host ' TECNICO DIGITALE - BASELINE vs SISTEMA ATTUALE' -ForegroundColor Cyan
Write-Host '=============================================================='
Write-Host "Baseline : $($b.BaselineType) / Build $($b.Windows.BuildNumber)"
Write-Host "Attuale  : $($c.Windows.Caption) / Build $($c.Windows.BuildNumber)"
if([string]$b.Windows.BuildNumber-ne[string]$c.Windows.BuildNumber){Write-Warning 'Build Windows diversa dalla baseline: interpretare i delta con cautela.'}
$metrics=@('ProcessCount','TotalWorkingSetMB','TotalPrivateMemoryMB','PhysicalMemoryUsedMB','PhysicalMemoryFreeMB','EnabledScheduledTasks','InstalledAppxCount','ProvisionedAppxCount','EnabledFeatureCount','InstalledCapabilityCount','StartupItemCount','RunningServiceCount','EdgeWebViewProcessCount','EdgeWebViewWorkingSetMB')
$rows=@();foreach($m in $metrics){$x=P $b.Snapshot $m;$y=P $c.Snapshot $m;$d=$null;try{$d=[math]::Round([double]$y-[double]$x,2)}catch{};$rows+=[pscustomobject]@{Metrica=$m;Baseline=$x;Attuale=$y;Delta=$d}}
Write-Host '';Write-Host 'IMPATTO MISURATO' -ForegroundColor Cyan;$rows|Format-Table -AutoSize|Out-Host
# Process counts
$bc=@{};foreach($p in $b.ProcessCounts.PSObject.Properties){$bc[$p.Name]=[int]$p.Value};$cc=@{};foreach($g in @($c.Processes|Group-Object Name)){$cc[$g.Name]=[int]$g.Count}
$proc=@();foreach($k in @($bc.Keys+$cc.Keys|Sort-Object -Unique)){$x=if($bc.ContainsKey($k)){$bc[$k]}else{0};$y=if($cc.ContainsKey($k)){$cc[$k]}else{0};if($x-ne$y){$proc+=[pscustomobject]@{Nome=$k;Baseline=$x;Attuale=$y;Delta=$y-$x}}}
Write-Host 'PROCESSI CON CONTEGGIO DIVERSO' -ForegroundColor Cyan;if($proc.Count){$proc|Sort-Object Delta,Nome|Format-Table -AutoSize|Out-Host}else{Write-Host '(nessuno)'}
# Provisioned AppX
$bp=@($b.AppxProvisionedNames);$cp=@($c.AppxProvisioned|ForEach-Object{$_.DisplayName});$removed=@($bp|Where-Object{$_-notin$cp}|Sort-Object);$added=@($cp|Where-Object{$_-notin$bp}|Sort-Object)
Write-Host 'APPX PROVISIONED RIMOSSE' -ForegroundColor Cyan;if($removed.Count){$removed|ForEach-Object{Write-Host "  - $_"}}else{Write-Host '  (nessuna)'}
Write-Host 'APPX PROVISIONED AGGIUNTE' -ForegroundColor Cyan;if($added.Count){$added|ForEach-Object{Write-Host "  + $_"}}else{Write-Host '  (nessuna)'}
# Startup conceptual comparison
$bs=@($b.StartupItems|ForEach-Object{NormStart $_.Name});$cs=@($c.StartupItems|ForEach-Object{NormStart $_.Name});$bsu=@($bs|Sort-Object -Unique);$csu=@($cs|Sort-Object -Unique);$sr=@($bsu|Where-Object{$_-notin$csu});$sa=@($csu|Where-Object{$_-notin$bsu})
Write-Host 'STARTUP - DIFFERENZE' -ForegroundColor Cyan;if(!$sr.Count-and!$sa.Count){Write-Host '  (nessuna differenza concettuale)'}else{$sr|ForEach-Object{Write-Host "  rimosso: $_"};$sa|ForEach-Object{Write-Host "  aggiunto: $_"}}
# Service start modes vs compact baseline
$bm=@{};foreach($p in $b.NonManualServiceStartModes.PSObject.Properties){$bm[$p.Name]=[string]$p.Value};$cm=@{};foreach($s in $c.Services){$n=NormSvc $s.Name;if($s.StartMode-ne'Manual'){$cm[$n]=[string]$s.StartMode}}
$svc=@();foreach($k in @($bm.Keys+$cm.Keys|Sort-Object -Unique)){$x=if($bm.ContainsKey($k)){$bm[$k]}else{'Manual/Absent'};$y=if($cm.ContainsKey($k)){$cm[$k]}else{'Manual/Absent'};if($x-ne$y){$svc+=[pscustomobject]@{Servizio=$k;Baseline=$x;Attuale=$y}}
Write-Host 'SERVIZI - START MODE DIFFERENTE' -ForegroundColor Cyan;if($svc.Count){$svc|Format-Table -AutoSize|Out-Host}else{Write-Host '  (nessuna differenza)'}
# Installed programs informational
$bn=@($b.InstalledPrograms|ForEach-Object{$_.Name});$cn=@($c.InstalledPrograms|ForEach-Object{$_.DisplayName});$pa=@($cn|Where-Object{$_-notin$bn}|Sort-Object -Unique);$pr=@($bn|Where-Object{$_-notin$cn}|Sort-Object -Unique)
Write-Host 'SOFTWARE DIFFERENTE DALLA BASELINE (INFORMATIVO)' -ForegroundColor Cyan;$pr|ForEach-Object{Write-Host "  rimosso: $_"};$pa|ForEach-Object{Write-Host "  aggiunto: $_"};if(!$pr.Count-and!$pa.Count){Write-Host '  (nessuno)'}
$stamp=Get-Date -Format 'yyyyMMdd-HHmmss';$out=Join-Path $OutputDirectory "BaselineCompare-$stamp.json"
[ordered]@{GeneratedAt=(Get-Date).ToString('s');Baseline=$BaselinePath;Current=$CurrentPath;Snapshot=$rows;ProcessDifferences=$proc;ProvisionedAppxRemoved=$removed;ProvisionedAppxAdded=$added;StartupRemoved=$sr;StartupAdded=$sa;ServiceStartModeDifferences=$svc;ProgramsRemoved=$pr;ProgramsAdded=$pa}|ConvertTo-Json -Depth 6|Set-Content $out -Encoding UTF8
Write-Host '';Write-Host "Report confronto: $out" -ForegroundColor Green
Write-Host 'Nota: RAM/processi sono snapshot runtime; AppX, startup e start mode servizi sono differenze strutturali.' -ForegroundColor DarkGray
