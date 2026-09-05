[CmdletBinding()]
param(
    [string]$BaselinePath = (Join-Path $PSScriptRoot 'baselines\Windows11-Pro-Clean-Before-Standard.json'),
    [Parameter(Mandatory = $true)]
    [string]$CurrentPath,
    [string]$OutputDirectory = (Join-Path $PSScriptRoot 'reports')
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Get-Prop {
    param($Object, [string]$Name, $Default = $null)
    if ($null -eq $Object) { return $Default }
    $p = $Object.PSObject.Properties[$Name]
    if ($null -eq $p) { return $Default }
    return $p.Value
}

function Normalize-ServiceName {
    param([string]$Name)
    if ([string]::IsNullOrWhiteSpace($Name)) { return '' }
    return ($Name -replace '_[0-9A-Fa-f]{5,}$', '_*')
}

function Normalize-StartupName {
    param([string]$Name)
    if ([string]::IsNullOrWhiteSpace($Name)) { return '' }
    return ($Name -replace 'MicrosoftEdgeAutoLaunch_[A-Fa-f0-9]+', 'MicrosoftEdgeAutoLaunch_{HASH}')
}

if (-not (Test-Path -LiteralPath $BaselinePath -PathType Leaf)) {
    throw "Baseline non trovata: $BaselinePath"
}
if (-not (Test-Path -LiteralPath $CurrentPath -PathType Leaf)) {
    throw "Audit corrente non trovato: $CurrentPath"
}
if (-not (Test-Path -LiteralPath $OutputDirectory -PathType Container)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}

$baseline = Get-Content -LiteralPath $BaselinePath -Raw -Encoding UTF8 | ConvertFrom-Json
$current  = Get-Content -LiteralPath $CurrentPath  -Raw -Encoding UTF8 | ConvertFrom-Json

Write-Host '=============================================================='
Write-Host ' TECNICO DIGITALE - BASELINE vs SISTEMA ATTUALE' -ForegroundColor Cyan
Write-Host '=============================================================='
Write-Host ("Baseline : {0} / Build {1}" -f $baseline.BaselineType, $baseline.Windows.BuildNumber)
Write-Host ("Attuale  : {0} / Build {1}" -f $current.Windows.Caption, $current.Windows.BuildNumber)
Write-Host ''

if ([string]$baseline.Windows.BuildNumber -ne [string]$current.Windows.BuildNumber) {
    Write-Warning 'Build Windows diversa dalla baseline: interpretare i delta con cautela.'
}

$metrics = @(
    'ProcessCount',
    'TotalWorkingSetMB',
    'TotalPrivateMemoryMB',
    'PhysicalMemoryUsedMB',
    'PhysicalMemoryFreeMB',
    'EnabledScheduledTasks',
    'InstalledAppxCount',
    'ProvisionedAppxCount',
    'EnabledFeatureCount',
    'InstalledCapabilityCount',
    'StartupItemCount',
    'RunningServiceCount',
    'EdgeWebViewProcessCount',
    'EdgeWebViewWorkingSetMB'
)

$rows = @()
foreach ($metric in $metrics) {
    $before = Get-Prop $baseline.Snapshot $metric
    $after  = Get-Prop $current.Snapshot $metric
    $delta = $null
    try {
        $delta = [math]::Round(([double]$after - [double]$before), 2)
    }
    catch { }

    $rows += [pscustomobject]@{
        Metrica  = $metric
        Baseline = $before
        Attuale  = $after
        Delta    = $delta
    }
}

Write-Host 'IMPATTO MISURATO' -ForegroundColor Cyan
$rows | Format-Table -AutoSize | Out-Host

# Processi: confronto per nome/conteggio, ignorando i PID.
$baselineCounts = @{}
foreach ($p in $baseline.ProcessCounts.PSObject.Properties) {
    $baselineCounts[$p.Name] = [int]$p.Value
}

$currentCounts = @{}
foreach ($group in @($current.Processes | Group-Object Name)) {
    $currentCounts[$group.Name] = [int]$group.Count
}

$processDifferences = @()
$processKeys = @($baselineCounts.Keys + $currentCounts.Keys | Sort-Object -Unique)
foreach ($key in $processKeys) {
    if ($baselineCounts.ContainsKey($key)) { $before = $baselineCounts[$key] } else { $before = 0 }
    if ($currentCounts.ContainsKey($key))  { $after  = $currentCounts[$key]  } else { $after  = 0 }

    if ($before -ne $after) {
        $processDifferences += [pscustomobject]@{
            Nome     = $key
            Baseline = $before
            Attuale  = $after
            Delta    = ($after - $before)
        }
    }
}

Write-Host 'PROCESSI CON CONTEGGIO DIVERSO' -ForegroundColor Cyan
if ($processDifferences.Count -gt 0) {
    $processDifferences | Sort-Object Delta, Nome | Format-Table -AutoSize | Out-Host
}
else {
    Write-Host '  (nessuno)'
}

# AppX provisioned.
$baselineProvisioned = @($baseline.AppxProvisionedNames)
$currentProvisioned = @(
    $current.AppxProvisioned | ForEach-Object { Get-Prop $_ 'DisplayName' '' }
)

$removedProvisioned = @($baselineProvisioned | Where-Object { $_ -notin $currentProvisioned } | Sort-Object)
$addedProvisioned   = @($currentProvisioned  | Where-Object { $_ -notin $baselineProvisioned } | Sort-Object)

Write-Host 'APPX PROVISIONED RIMOSSE' -ForegroundColor Cyan
if ($removedProvisioned.Count -gt 0) {
    $removedProvisioned | ForEach-Object { Write-Host ("  - {0}" -f $_) }
}
else { Write-Host '  (nessuna)' }

Write-Host 'APPX PROVISIONED AGGIUNTE' -ForegroundColor Cyan
if ($addedProvisioned.Count -gt 0) {
    $addedProvisioned | ForEach-Object { Write-Host ("  + {0}" -f $_) }
}
else { Write-Host '  (nessuna)' }

# Startup: confronto concettuale normalizzando l'hash Edge.
$baselineStartup = @(
    $baseline.StartupItems | ForEach-Object { Normalize-StartupName (Get-Prop $_ 'Name' '') }
)
$currentStartup = @(
    $current.StartupItems | ForEach-Object { Normalize-StartupName (Get-Prop $_ 'Name' '') }
)

$baselineStartupUnique = @($baselineStartup | Sort-Object -Unique)
$currentStartupUnique  = @($currentStartup  | Sort-Object -Unique)
$startupRemoved = @($baselineStartupUnique | Where-Object { $_ -notin $currentStartupUnique })
$startupAdded   = @($currentStartupUnique  | Where-Object { $_ -notin $baselineStartupUnique })

Write-Host 'STARTUP - DIFFERENZE' -ForegroundColor Cyan
if (($startupRemoved.Count -eq 0) -and ($startupAdded.Count -eq 0)) {
    Write-Host '  (nessuna differenza concettuale)'
}
else {
    $startupRemoved | ForEach-Object { Write-Host ("  rimosso: {0}" -f $_) }
    $startupAdded   | ForEach-Object { Write-Host ("  aggiunto: {0}" -f $_) }
}

# Servizi: confronta gli StartMode non-Manual della baseline compatta con l'attuale.
$baselineServiceModes = @{}
foreach ($p in $baseline.NonManualServiceStartModes.PSObject.Properties) {
    $baselineServiceModes[$p.Name] = [string]$p.Value
}

$currentServiceModes = @{}
foreach ($service in @($current.Services)) {
    $normalizedName = Normalize-ServiceName (Get-Prop $service 'Name' '')
    $startMode = [string](Get-Prop $service 'StartMode' '')
    if ($startMode -ne 'Manual' -and -not [string]::IsNullOrWhiteSpace($normalizedName)) {
        $currentServiceModes[$normalizedName] = $startMode
    }
}

$serviceDifferences = @()
$serviceKeys = @($baselineServiceModes.Keys + $currentServiceModes.Keys | Sort-Object -Unique)
foreach ($key in $serviceKeys) {
    if ($baselineServiceModes.ContainsKey($key)) { $before = $baselineServiceModes[$key] } else { $before = 'Manual/Absent' }
    if ($currentServiceModes.ContainsKey($key))  { $after  = $currentServiceModes[$key]  } else { $after  = 'Manual/Absent' }

    if ($before -ne $after) {
        $serviceDifferences += [pscustomobject]@{
            Servizio = $key
            Baseline = $before
            Attuale  = $after
        }
    }
}

Write-Host 'SERVIZI - START MODE DIFFERENTE' -ForegroundColor Cyan
if ($serviceDifferences.Count -gt 0) {
    $serviceDifferences | Format-Table -AutoSize | Out-Host
}
else {
    Write-Host '  (nessuna differenza)'
}

# Programmi installati: solo informativo.
$baselinePrograms = @($baseline.InstalledPrograms | ForEach-Object { Get-Prop $_ 'Name' '' })
$currentPrograms  = @($current.InstalledPrograms  | ForEach-Object { Get-Prop $_ 'DisplayName' '' })

$programsAdded   = @($currentPrograms  | Where-Object { $_ -and ($_ -notin $baselinePrograms) } | Sort-Object -Unique)
$programsRemoved = @($baselinePrograms | Where-Object { $_ -and ($_ -notin $currentPrograms)  } | Sort-Object -Unique)

Write-Host 'SOFTWARE DIFFERENTE DALLA BASELINE (INFORMATIVO)' -ForegroundColor Cyan
if (($programsAdded.Count -eq 0) -and ($programsRemoved.Count -eq 0)) {
    Write-Host '  (nessuno)'
}
else {
    $programsRemoved | ForEach-Object { Write-Host ("  rimosso: {0}" -f $_) }
    $programsAdded   | ForEach-Object { Write-Host ("  aggiunto: {0}" -f $_) }
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$outputPath = Join-Path $OutputDirectory ("BaselineCompare-{0}.json" -f $stamp)

[ordered]@{
    GeneratedAt                 = (Get-Date).ToString('s')
    Baseline                    = $BaselinePath
    Current                     = $CurrentPath
    Snapshot                    = $rows
    ProcessDifferences          = $processDifferences
    ProvisionedAppxRemoved      = $removedProvisioned
    ProvisionedAppxAdded        = $addedProvisioned
    StartupRemoved              = $startupRemoved
    StartupAdded                = $startupAdded
    ServiceStartModeDifferences = $serviceDifferences
    ProgramsRemoved             = $programsRemoved
    ProgramsAdded               = $programsAdded
} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $outputPath -Encoding UTF8

Write-Host ''
Write-Host ("Report confronto: {0}" -f $outputPath) -ForegroundColor Green
Write-Host 'Nota: RAM/processi sono snapshot runtime; AppX, startup e StartMode servizi sono differenze strutturali.' -ForegroundColor DarkGray
