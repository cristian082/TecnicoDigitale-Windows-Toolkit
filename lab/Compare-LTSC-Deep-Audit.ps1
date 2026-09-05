[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$ReferencePath,

    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$CandidatePath,

    [string]$OutputDirectory
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

function Convert-ToSafeName {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return 'UNKNOWN' }
    return ($Value -replace '[^A-Za-z0-9._-]', '_')
}

function Normalize-ServiceName {
    param([string]$Name)
    if ([string]::IsNullOrWhiteSpace($Name)) { return '' }
    # I servizi per-user ricevono un suffisso casuale diverso su ogni installazione.
    return ($Name -replace '_[0-9A-Fa-f]{5,}$', '_*')
}

function Normalize-Text {
    param($Value)
    if ($null -eq $Value) { return '' }
    return ([string]$Value).Trim()
}

function Get-TaskActionSignature {
    param($Actions)
    $parts = @()
    foreach ($a in @($Actions)) {
        $parts += ('{0}|{1}|{2}' -f (Normalize-Text (Get-Prop $a 'Execute' '')), (Normalize-Text (Get-Prop $a 'Arguments' '')), (Normalize-Text (Get-Prop $a 'WorkingDirectory' '')))
    }
    return ($parts -join ' || ')
}

function Get-GroupedProcessMap {
    param($Items)
    $map = @{}
    foreach ($group in @($Items | Group-Object Name)) {
        $ws = [math]::Round((($group.Group | Measure-Object WorkingSetMB -Sum).Sum), 2)
        $private = [math]::Round((($group.Group | Measure-Object PrivateMemoryMB -Sum).Sum), 2)
        $cpu = [math]::Round((($group.Group | Measure-Object CPUSeconds -Sum).Sum), 2)
        $map[[string]$group.Name] = [pscustomobject]@{
            Name            = [string]$group.Name
            Count           = [int]$group.Count
            WorkingSetMB    = $ws
            PrivateMemoryMB = $private
            CPUSeconds      = $cpu
        }
    }
    return $map
}

function Get-KeyedMap {
    param(
        $Items,
        [scriptblock]$KeyScript,
        [scriptblock]$ValueScript = $null
    )
    $map = @{}
    foreach ($item in @($Items)) {
        $key = [string](& $KeyScript $item)
        if ([string]::IsNullOrWhiteSpace($key)) { continue }
        if ($null -eq $ValueScript) { $map[$key] = $item }
        else { $map[$key] = & $ValueScript $item }
    }
    return $map
}

function Compare-Map {
    param(
        [hashtable]$ReferenceMap,
        [hashtable]$CandidateMap,
        [scriptblock]$DifferenceScript
    )

    $onlyReference = @()
    $onlyCandidate = @()
    $different = @()
    $same = @()

    $keys = @($ReferenceMap.Keys + $CandidateMap.Keys | Sort-Object -Unique)
    foreach ($key in $keys) {
        $hasR = $ReferenceMap.ContainsKey($key)
        $hasC = $CandidateMap.ContainsKey($key)
        if ($hasR -and -not $hasC) {
            $onlyReference += $ReferenceMap[$key]
            continue
        }
        if ($hasC -and -not $hasR) {
            $onlyCandidate += $CandidateMap[$key]
            continue
        }

        $diff = & $DifferenceScript $ReferenceMap[$key] $CandidateMap[$key] $key
        if ($null -ne $diff) { $different += $diff }
        else { $same += $key }
    }

    [pscustomobject]@{
        OnlyReference = @($onlyReference)
        OnlyCandidate = @($onlyCandidate)
        Different     = @($different)
        SameKeys      = @($same)
    }
}

function New-SimpleDifference {
    param([string]$Key, $ReferenceValue, $CandidateValue)
    if ((Normalize-Text $ReferenceValue) -eq (Normalize-Text $CandidateValue)) { return $null }
    [pscustomobject]@{
        Key       = $Key
        Reference = $ReferenceValue
        Candidate = $CandidateValue
    }
}

function Add-TxtSection {
    param(
        [System.Collections.Generic.List[string]]$Lines,
        [string]$Title,
        $Items,
        [scriptblock]$Formatter,
        [int]$MaxItems = 200
    )
    $Lines.Add('')
    $Lines.Add(('=== {0} ===' -f $Title))
    $array = @($Items)
    if ($array.Count -eq 0) {
        $Lines.Add('(nessuno)')
        return
    }
    $shown = 0
    foreach ($item in $array) {
        if ($shown -ge $MaxItems) { break }
        $Lines.Add([string](& $Formatter $item))
        $shown++
    }
    if ($array.Count -gt $shown) {
        $Lines.Add(('... altri {0} elementi nel JSON.' -f ($array.Count - $shown)))
    }
}

$reference = Get-Content -LiteralPath $ReferencePath -Raw -Encoding UTF8 | ConvertFrom-Json
$candidate = Get-Content -LiteralPath $CandidatePath -Raw -Encoding UTF8 | ConvertFrom-Json

$refSchema = [int](Get-Prop $reference 'SchemaVersion' 0)
$candSchema = [int](Get-Prop $candidate 'SchemaVersion' 0)
if ($refSchema -lt 3 -or $candSchema -lt 3) {
    throw 'Il comparatore Deep richiede report LTSC-Deep-Audit SchemaVersion 3 o superiore.'
}

$refLabel = [string](Get-Prop $reference 'Label' 'REFERENCE')
$candLabel = [string](Get-Prop $candidate 'Label' 'CANDIDATE')
$refWindows = Get-Prop $reference 'Windows' $null
$candWindows = Get-Prop $candidate 'Windows' $null
$refSnapshot = Get-Prop $reference 'Snapshot' $null
$candSnapshot = Get-Prop $candidate 'Snapshot' $null

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Split-Path -Parent (Resolve-Path -LiteralPath $CandidatePath).Path
}
if (-not (Test-Path -LiteralPath $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}

Write-Host '=============================================================='
Write-Host ' TecnicoDigitale - Deep Audit Comparator' -ForegroundColor Cyan
Write-Host '=============================================================='
Write-Host ('REFERENCE : {0} - Build {1}' -f $refLabel, (Get-Prop $refWindows 'BuildNumber' '?'))
Write-Host ('CANDIDATE : {0} - Build {1}' -f $candLabel, (Get-Prop $candWindows 'BuildNumber' '?'))
Write-Host ''

# Snapshot: numeri osservati, utili ma non classificati come configurazione.
$snapshotNames = @(
    'ProcessCount','TotalWorkingSetMB','TotalPrivateMemoryMB','PhysicalMemoryTotalMB',
    'PhysicalMemoryUsedMB','PhysicalMemoryFreeMB','EnabledScheduledTasks','InstalledAppxCount',
    'ProvisionedAppxCount','EnabledFeatureCount','InstalledCapabilityCount','StartupItemCount',
    'RunningServiceCount','EdgeWebViewProcessCount','EdgeWebViewWorkingSetMB'
)
$snapshotDiff = @()
foreach ($name in $snapshotNames) {
    $r = Get-Prop $refSnapshot $name $null
    $c = Get-Prop $candSnapshot $name $null
    $delta = $null
    if ($null -ne $r -and $null -ne $c) {
        try { $delta = [math]::Round(([double]$c - [double]$r), 2) } catch { }
    }
    $snapshotDiff += [pscustomobject]@{ Metric = $name; Reference = $r; Candidate = $c; DeltaCandidateMinusReference = $delta }
}

# Processi aggregati per nome: evita che i PID rendano ogni snapshot diverso.
$procRef = Get-GroupedProcessMap (Get-Prop $reference 'Processes' @())
$procCand = Get-GroupedProcessMap (Get-Prop $candidate 'Processes' @())
$processCompare = Compare-Map $procRef $procCand {
    param($r,$c,$key)
    if ($r.Count -eq $c.Count -and [math]::Abs($r.WorkingSetMB - $c.WorkingSetMB) -lt 1) { return $null }
    [pscustomobject]@{
        Name = $key
        ReferenceCount = $r.Count
        CandidateCount = $c.Count
        ReferenceWorkingSetMB = $r.WorkingSetMB
        CandidateWorkingSetMB = $c.WorkingSetMB
        WorkingSetDeltaMB = [math]::Round($c.WorkingSetMB - $r.WorkingSetMB, 2)
    }
}

# Task pianificati: la chiave e Path+Nome; lo State e snapshot runtime, quindi non decide la configurazione.
$taskRef = Get-KeyedMap (Get-Prop $reference 'ScheduledTasks' @()) { param($x) ('{0}{1}' -f (Get-Prop $x 'TaskPath' ''), (Get-Prop $x 'TaskName' '')) }
$taskCand = Get-KeyedMap (Get-Prop $candidate 'ScheduledTasks' @()) { param($x) ('{0}{1}' -f (Get-Prop $x 'TaskPath' ''), (Get-Prop $x 'TaskName' '')) }
$taskCompare = Compare-Map $taskRef $taskCand {
    param($r,$c,$key)
    $rAction = Get-TaskActionSignature (Get-Prop $r 'Actions' @())
    $cAction = Get-TaskActionSignature (Get-Prop $c 'Actions' @())
    $changes = @()
    if ([bool](Get-Prop $r 'Enabled' $false) -ne [bool](Get-Prop $c 'Enabled' $false)) { $changes += 'Enabled' }
    if ([bool](Get-Prop $r 'Hidden' $false) -ne [bool](Get-Prop $c 'Hidden' $false)) { $changes += 'Hidden' }
    if ($rAction -ne $cAction) { $changes += 'Actions' }
    if ($changes.Count -eq 0) { return $null }
    [pscustomobject]@{
        Key = $key
        ChangedFields = @($changes)
        ReferenceEnabled = Get-Prop $r 'Enabled' $null
        CandidateEnabled = Get-Prop $c 'Enabled' $null
        ReferenceHidden = Get-Prop $r 'Hidden' $null
        CandidateHidden = Get-Prop $c 'Hidden' $null
        ReferenceActions = $rAction
        CandidateActions = $cAction
    }
}

# Stato runtime dei task separato: informativo, non suggerisce tweak.
$taskStateOnly = @()
foreach ($key in @($taskRef.Keys | Where-Object { $taskCand.ContainsKey($_) } | Sort-Object)) {
    $rs = Normalize-Text (Get-Prop $taskRef[$key] 'State' '')
    $cs = Normalize-Text (Get-Prop $taskCand[$key] 'State' '')
    if ($rs -ne $cs) { $taskStateOnly += [pscustomobject]@{ Key=$key; ReferenceState=$rs; CandidateState=$cs } }
}

$appxRef = Get-KeyedMap (Get-Prop $reference 'AppxInstalled' @()) { param($x) (Get-Prop $x 'Name' '') }
$appxCand = Get-KeyedMap (Get-Prop $candidate 'AppxInstalled' @()) { param($x) (Get-Prop $x 'Name' '') }
$appxCompare = Compare-Map $appxRef $appxCand {
    param($r,$c,$key)
    $changes = @()
    foreach ($field in @('Version','Architecture','NonRemovable','IsFramework')) {
        if ((Normalize-Text (Get-Prop $r $field '')) -ne (Normalize-Text (Get-Prop $c $field ''))) { $changes += $field }
    }
    if ($changes.Count -eq 0) { return $null }
    [pscustomobject]@{ Name=$key; ChangedFields=@($changes); Reference=$r; Candidate=$c }
}

$provRef = Get-KeyedMap (Get-Prop $reference 'AppxProvisioned' @()) { param($x) (Get-Prop $x 'DisplayName' '') }
$provCand = Get-KeyedMap (Get-Prop $candidate 'AppxProvisioned' @()) { param($x) (Get-Prop $x 'DisplayName' '') }
$provCompare = Compare-Map $provRef $provCand {
    param($r,$c,$key)
    if ((Normalize-Text (Get-Prop $r 'Version' '')) -eq (Normalize-Text (Get-Prop $c 'Version' ''))) { return $null }
    [pscustomobject]@{ Name=$key; ReferenceVersion=Get-Prop $r 'Version' ''; CandidateVersion=Get-Prop $c 'Version' '' }
}

$featureRef = Get-KeyedMap (Get-Prop $reference 'OptionalFeatures' @()) { param($x) (Get-Prop $x 'FeatureName' '') }
$featureCand = Get-KeyedMap (Get-Prop $candidate 'OptionalFeatures' @()) { param($x) (Get-Prop $x 'FeatureName' '') }
$featureCompare = Compare-Map $featureRef $featureCand { param($r,$c,$key) New-SimpleDifference $key (Get-Prop $r 'State' '') (Get-Prop $c 'State' '') }

$capRef = Get-KeyedMap (Get-Prop $reference 'Capabilities' @()) { param($x) (Get-Prop $x 'Name' '') }
$capCand = Get-KeyedMap (Get-Prop $candidate 'Capabilities' @()) { param($x) (Get-Prop $x 'Name' '') }
$capCompare = Compare-Map $capRef $capCand { param($r,$c,$key) New-SimpleDifference $key (Get-Prop $r 'State' '') (Get-Prop $c 'State' '') }

$programRef = Get-KeyedMap (Get-Prop $reference 'InstalledPrograms' @()) { param($x) (Get-Prop $x 'DisplayName' '') }
$programCand = Get-KeyedMap (Get-Prop $candidate 'InstalledPrograms' @()) { param($x) (Get-Prop $x 'DisplayName' '') }
$programCompare = Compare-Map $programRef $programCand {
    param($r,$c,$key)
    $rv = Normalize-Text (Get-Prop $r 'DisplayVersion' '')
    $cv = Normalize-Text (Get-Prop $c 'DisplayVersion' '')
    if ($rv -eq $cv) { return $null }
    [pscustomobject]@{ Name=$key; ReferenceVersion=$rv; CandidateVersion=$cv }
}

$startupRef = Get-KeyedMap (Get-Prop $reference 'StartupItems' @()) { param($x) ('{0}|{1}' -f (Get-Prop $x 'Name' ''), (Get-Prop $x 'Location' '')) }
$startupCand = Get-KeyedMap (Get-Prop $candidate 'StartupItems' @()) { param($x) ('{0}|{1}' -f (Get-Prop $x 'Name' ''), (Get-Prop $x 'Location' '')) }
$startupCompare = Compare-Map $startupRef $startupCand {
    param($r,$c,$key)
    if ((Normalize-Text (Get-Prop $r 'Command' '')) -eq (Normalize-Text (Get-Prop $c 'Command' ''))) { return $null }
    [pscustomobject]@{ Key=$key; ReferenceCommand=Get-Prop $r 'Command' ''; CandidateCommand=Get-Prop $c 'Command' '' }
}

# Servizi: normalizza i suffissi per-user. StartMode = configurazione; State = fotografia runtime.
$serviceRef = Get-KeyedMap (Get-Prop $reference 'Services' @()) { param($x) Normalize-ServiceName (Get-Prop $x 'Name' '') }
$serviceCand = Get-KeyedMap (Get-Prop $candidate 'Services' @()) { param($x) Normalize-ServiceName (Get-Prop $x 'Name' '') }
$serviceCompare = Compare-Map $serviceRef $serviceCand {
    param($r,$c,$key)
    $changes = @()
    if ((Normalize-Text (Get-Prop $r 'StartMode' '')) -ne (Normalize-Text (Get-Prop $c 'StartMode' ''))) { $changes += 'StartMode' }
    if ((Normalize-Text (Get-Prop $r 'StartName' '')) -ne (Normalize-Text (Get-Prop $c 'StartName' ''))) { $changes += 'StartName' }
    if ($changes.Count -eq 0) { return $null }
    [pscustomobject]@{
        Name=$key
        ChangedFields=@($changes)
        ReferenceStartMode=Get-Prop $r 'StartMode' ''
        CandidateStartMode=Get-Prop $c 'StartMode' ''
        ReferenceStartName=Get-Prop $r 'StartName' ''
        CandidateStartName=Get-Prop $c 'StartName' ''
    }
}
$serviceStateOnly = @()
foreach ($key in @($serviceRef.Keys | Where-Object { $serviceCand.ContainsKey($_) } | Sort-Object)) {
    $rs = Normalize-Text (Get-Prop $serviceRef[$key] 'State' '')
    $cs = Normalize-Text (Get-Prop $serviceCand[$key] 'State' '')
    if ($rs -ne $cs) { $serviceStateOnly += [pscustomobject]@{ Name=$key; ReferenceState=$rs; CandidateState=$cs } }
}

$policyRef = Get-KeyedMap (Get-Prop $reference 'Policies' @()) { param($x) ('{0}|{1}' -f (Get-Prop $x 'Path' ''), (Get-Prop $x 'Name' '')) }
$policyCand = Get-KeyedMap (Get-Prop $candidate 'Policies' @()) { param($x) ('{0}|{1}' -f (Get-Prop $x 'Path' ''), (Get-Prop $x 'Name' '')) }
$policyCompare = Compare-Map $policyRef $policyCand { param($r,$c,$key) New-SimpleDifference $key (Get-Prop $r 'Value' '') (Get-Prop $c 'Value' '') }

$stamp = Get-Date -Format 'yyyyMMdd-HHmmssfff'
$outBase = 'DeepCompare-{0}-vs-{1}-{2}' -f (Convert-ToSafeName $refLabel), (Convert-ToSafeName $candLabel), $stamp
$jsonPath = Join-Path $OutputDirectory ($outBase + '.json')
$txtPath = Join-Path $OutputDirectory ($outBase + '.txt')

$result = [ordered]@{
    SchemaVersion = 1
    ComparisonType = 'DeepAudit-Comparison'
    GeneratedAt = (Get-Date).ToString('s')
    Reference = [ordered]@{
        Label = $refLabel
        File = [IO.Path]::GetFileName($ReferencePath)
        WindowsCaption = Get-Prop $refWindows 'Caption' ''
        BuildNumber = Get-Prop $refWindows 'BuildNumber' ''
        TotalRAMMB = Get-Prop (Get-Prop $reference 'Computer' $null) 'TotalRAMMB' $null
        LastBootUpTime = Get-Prop $refWindows 'LastBootUpTime' $null
        GeneratedAt = Get-Prop $reference 'GeneratedAt' $null
    }
    Candidate = [ordered]@{
        Label = $candLabel
        File = [IO.Path]::GetFileName($CandidatePath)
        WindowsCaption = Get-Prop $candWindows 'Caption' ''
        BuildNumber = Get-Prop $candWindows 'BuildNumber' ''
        TotalRAMMB = Get-Prop (Get-Prop $candidate 'Computer' $null) 'TotalRAMMB' $null
        LastBootUpTime = Get-Prop $candWindows 'LastBootUpTime' $null
        GeneratedAt = Get-Prop $candidate 'GeneratedAt' $null
    }
    Warnings = @(
        if ((Get-Prop $refWindows 'BuildNumber' '') -ne (Get-Prop $candWindows 'BuildNumber' '')) { 'Le build Windows sono diverse: alcune differenze possono dipendere dalla build e non dall edizione.' }
        if ((Get-Prop (Get-Prop $reference 'Computer' $null) 'TotalRAMMB' 0) -ne (Get-Prop (Get-Prop $candidate 'Computer' $null) 'TotalRAMMB' 0)) { 'La RAM assegnata e diversa: non usare i valori memoria come benchmark diretto.' }
        'Processi, stato dei servizi/task e memoria sono snapshot runtime: non equivalgono automaticamente a differenze di configurazione.'
    )
    Snapshot = $snapshotDiff
    Processes = $processCompare
    ScheduledTasks = [ordered]@{ Configuration = $taskCompare; StateOnly = $taskStateOnly }
    AppxInstalled = $appxCompare
    AppxProvisioned = $provCompare
    OptionalFeatures = $featureCompare
    Capabilities = $capCompare
    InstalledPrograms = $programCompare
    StartupItems = $startupCompare
    Services = [ordered]@{ Configuration = $serviceCompare; StateOnly = $serviceStateOnly }
    Policies = $policyCompare
}

$result | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$lines = New-Object 'System.Collections.Generic.List[string]'
$lines.Add('TECNICO DIGITALE - DEEP AUDIT COMPARISON')
$lines.Add(('Reference : {0} - Build {1}' -f $refLabel, (Get-Prop $refWindows 'BuildNumber' '?')))
$lines.Add(('Candidate : {0} - Build {1}' -f $candLabel, (Get-Prop $candWindows 'BuildNumber' '?')))
$lines.Add(('Generato  : {0}' -f (Get-Date).ToString('s')))
$lines.Add('')
$lines.Add('NOTA: OnlyReference = presente solo nel sistema di riferimento; OnlyCandidate = presente solo nel candidato.')
foreach ($warning in @($result.Warnings)) { $lines.Add(('ATTENZIONE: {0}' -f $warning)) }

Add-TxtSection $lines 'SNAPSHOT' $snapshotDiff { param($x) ('{0}: REF={1} CAND={2} DELTA={3}' -f $x.Metric,$x.Reference,$x.Candidate,$x.DeltaCandidateMinusReference) }
Add-TxtSection $lines 'PROCESSI - SOLO REFERENCE' $processCompare.OnlyReference { param($x) ('{0} x{1} WS={2}MB' -f $x.Name,$x.Count,$x.WorkingSetMB) }
Add-TxtSection $lines 'PROCESSI - SOLO CANDIDATE' $processCompare.OnlyCandidate { param($x) ('{0} x{1} WS={2}MB' -f $x.Name,$x.Count,$x.WorkingSetMB) }
Add-TxtSection $lines 'PROCESSI - DIVERSI' $processCompare.Different { param($x) ('{0}: count {1}->{2}, WS {3}->{4}MB (delta {5})' -f $x.Name,$x.ReferenceCount,$x.CandidateCount,$x.ReferenceWorkingSetMB,$x.CandidateWorkingSetMB,$x.WorkingSetDeltaMB) }

Add-TxtSection $lines 'APPX PROVISIONED - SOLO REFERENCE' $provCompare.OnlyReference { param($x) ('{0} {1}' -f (Get-Prop $x 'DisplayName' ''),(Get-Prop $x 'Version' '')) }
Add-TxtSection $lines 'APPX PROVISIONED - SOLO CANDIDATE' $provCompare.OnlyCandidate { param($x) ('{0} {1}' -f (Get-Prop $x 'DisplayName' ''),(Get-Prop $x 'Version' '')) }
Add-TxtSection $lines 'APPX INSTALLATE - SOLO REFERENCE' $appxCompare.OnlyReference { param($x) (Get-Prop $x 'Name' '') }
Add-TxtSection $lines 'APPX INSTALLATE - SOLO CANDIDATE' $appxCompare.OnlyCandidate { param($x) (Get-Prop $x 'Name' '') }

Add-TxtSection $lines 'STARTUP - SOLO REFERENCE' $startupCompare.OnlyReference { param($x) ('{0} -> {1}' -f (Get-Prop $x 'Name' ''),(Get-Prop $x 'Command' '')) }
Add-TxtSection $lines 'STARTUP - SOLO CANDIDATE' $startupCompare.OnlyCandidate { param($x) ('{0} -> {1}' -f (Get-Prop $x 'Name' ''),(Get-Prop $x 'Command' '')) }
Add-TxtSection $lines 'STARTUP - CONFIG DIVERSA' $startupCompare.Different { param($x) ('{0}: {1} -> {2}' -f $x.Key,$x.ReferenceCommand,$x.CandidateCommand) }

Add-TxtSection $lines 'SERVIZI - SOLO REFERENCE' $serviceCompare.OnlyReference { param($x) ('{0}: {1}/{2}' -f (Normalize-ServiceName (Get-Prop $x 'Name' '')),(Get-Prop $x 'StartMode' ''),(Get-Prop $x 'State' '')) }
Add-TxtSection $lines 'SERVIZI - SOLO CANDIDATE' $serviceCompare.OnlyCandidate { param($x) ('{0}: {1}/{2}' -f (Normalize-ServiceName (Get-Prop $x 'Name' '')),(Get-Prop $x 'StartMode' ''),(Get-Prop $x 'State' '')) }
Add-TxtSection $lines 'SERVIZI - CONFIG DIVERSA' $serviceCompare.Different { param($x) ('{0}: StartMode {1}->{2}; campi={3}' -f $x.Name,$x.ReferenceStartMode,$x.CandidateStartMode,($x.ChangedFields -join ',')) }
Add-TxtSection $lines 'SERVIZI - SOLO STATO RUNTIME DIVERSO' $serviceStateOnly { param($x) ('{0}: {1}->{2}' -f $x.Name,$x.ReferenceState,$x.CandidateState) }

Add-TxtSection $lines 'TASK - SOLO REFERENCE' $taskCompare.OnlyReference { param($x) ('{0}{1}' -f (Get-Prop $x 'TaskPath' ''),(Get-Prop $x 'TaskName' '')) }
Add-TxtSection $lines 'TASK - SOLO CANDIDATE' $taskCompare.OnlyCandidate { param($x) ('{0}{1}' -f (Get-Prop $x 'TaskPath' ''),(Get-Prop $x 'TaskName' '')) }
Add-TxtSection $lines 'TASK - CONFIG DIVERSA' $taskCompare.Different { param($x) ('{0}: {1}' -f $x.Key,($x.ChangedFields -join ',')) }

Add-TxtSection $lines 'OPTIONAL FEATURES - SOLO REFERENCE' $featureCompare.OnlyReference { param($x) ('{0}: {1}' -f (Get-Prop $x 'FeatureName' ''),(Get-Prop $x 'State' '')) }
Add-TxtSection $lines 'OPTIONAL FEATURES - SOLO CANDIDATE' $featureCompare.OnlyCandidate { param($x) ('{0}: {1}' -f (Get-Prop $x 'FeatureName' ''),(Get-Prop $x 'State' '')) }
Add-TxtSection $lines 'OPTIONAL FEATURES - STATO DIVERSO' $featureCompare.Different { param($x) ('{0}: {1}->{2}' -f $x.Key,$x.Reference,$x.Candidate) }

Add-TxtSection $lines 'CAPABILITIES - SOLO REFERENCE' $capCompare.OnlyReference { param($x) ('{0}: {1}' -f (Get-Prop $x 'Name' ''),(Get-Prop $x 'State' '')) }
Add-TxtSection $lines 'CAPABILITIES - SOLO CANDIDATE' $capCompare.OnlyCandidate { param($x) ('{0}: {1}' -f (Get-Prop $x 'Name' ''),(Get-Prop $x 'State' '')) }
Add-TxtSection $lines 'CAPABILITIES - STATO DIVERSO' $capCompare.Different { param($x) ('{0}: {1}->{2}' -f $x.Key,$x.Reference,$x.Candidate) }

Add-TxtSection $lines 'PROGRAMMI - SOLO REFERENCE' $programCompare.OnlyReference { param($x) ('{0} {1}' -f (Get-Prop $x 'DisplayName' ''),(Get-Prop $x 'DisplayVersion' '')) }
Add-TxtSection $lines 'PROGRAMMI - SOLO CANDIDATE' $programCompare.OnlyCandidate { param($x) ('{0} {1}' -f (Get-Prop $x 'DisplayName' ''),(Get-Prop $x 'DisplayVersion' '')) }
Add-TxtSection $lines 'POLICY - SOLO REFERENCE' $policyCompare.OnlyReference { param($x) ('{0}|{1}={2}' -f (Get-Prop $x 'Path' ''),(Get-Prop $x 'Name' ''),(Get-Prop $x 'Value' '')) }
Add-TxtSection $lines 'POLICY - SOLO CANDIDATE' $policyCompare.OnlyCandidate { param($x) ('{0}|{1}={2}' -f (Get-Prop $x 'Path' ''),(Get-Prop $x 'Name' ''),(Get-Prop $x 'Value' '')) }
Add-TxtSection $lines 'POLICY - VALORE DIVERSO' $policyCompare.Different { param($x) ('{0}: {1}->{2}' -f $x.Key,$x.Reference,$x.Candidate) }

$lines | Set-Content -LiteralPath $txtPath -Encoding UTF8

Write-Host 'Riepilogo:' -ForegroundColor Cyan
Write-Host ('  Processi solo REF/CAND      : {0} / {1}' -f @($processCompare.OnlyReference).Count, @($processCompare.OnlyCandidate).Count)
Write-Host ('  AppX provisioned solo REF/CAND: {0} / {1}' -f @($provCompare.OnlyReference).Count, @($provCompare.OnlyCandidate).Count)
Write-Host ('  Startup solo REF/CAND       : {0} / {1}' -f @($startupCompare.OnlyReference).Count, @($startupCompare.OnlyCandidate).Count)
Write-Host ('  Servizi config diversa      : {0}' -f @($serviceCompare.Different).Count)
Write-Host ('  Task config diversa         : {0}' -f @($taskCompare.Different).Count)
Write-Host ('  Feature stato diverso       : {0}' -f @($featureCompare.Different).Count)
Write-Host ('  Capability stato diverso    : {0}' -f @($capCompare.Different).Count)
Write-Host ''
Write-Host ('JSON: {0}' -f $jsonPath) -ForegroundColor Green
Write-Host ('TXT : {0}' -f $txtPath) -ForegroundColor Green
