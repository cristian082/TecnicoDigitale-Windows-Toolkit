[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ReferencePath,
    [Parameter(Mandatory)][string]$CandidatePath,
    [string]$OutputDirectory = (Join-Path $PSScriptRoot 'reports')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $ReferencePath)) {
    throw "File di riferimento non trovato: $ReferencePath"
}
if (-not (Test-Path -LiteralPath $CandidatePath)) {
    throw "File candidato non trovato: $CandidatePath"
}
if (-not (Test-Path -LiteralPath $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}

function Get-TDTNormalizedServiceName {
    param([Parameter(Mandatory)][string]$Name)
    return ($Name -replace '_[0-9A-Fa-f]{5,}$', '')
}

function Import-TDTServicesReport {
    param([Parameter(Mandatory)][string]$Path)

    $report = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not $report.Services) {
        throw "Il file non contiene Services: $Path"
    }

    foreach ($svc in $report.Services) {
        if (-not $svc.PSObject.Properties['NormalizedName'] -or [string]::IsNullOrWhiteSpace([string]$svc.NormalizedName)) {
            $svc | Add-Member -NotePropertyName NormalizedName -NotePropertyValue (Get-TDTNormalizedServiceName -Name ([string]$svc.Name)) -Force
        }
        if (-not $svc.PSObject.Properties['DelayedAutoStart']) {
            $svc | Add-Member -NotePropertyName DelayedAutoStart -NotePropertyValue $false -Force
        }
    }

    return $report
}

function ConvertTo-TDTServiceMap {
    param([Parameter(Mandatory)]$Services)

    $map = @{}
    foreach ($group in @($Services | Group-Object NormalizedName)) {
        $instances = @($group.Group | Sort-Object Name)
        $representative = $instances[0]
        $map[$group.Name] = [pscustomobject]@{
            NormalizedName   = $group.Name
            DisplayName      = $representative.DisplayName
            Instances        = @($instances.Name)
            States           = @($instances.State | Sort-Object -Unique)
            StartModes       = @($instances.StartMode | Sort-Object -Unique)
            DelayedAutoStart = @($instances.DelayedAutoStart | Sort-Object -Unique)
            StartNames       = @($instances.StartName | Where-Object { $_ } | Sort-Object -Unique)
            Paths            = @($instances.PathName | Where-Object { $_ } | Sort-Object -Unique)
        }
    }
    return $map
}

function Join-TDTValues {
    param($Value)
    return (@($Value) -join ', ')
}

$reference = Import-TDTServicesReport -Path $ReferencePath
$candidate = Import-TDTServicesReport -Path $CandidatePath

$refMap = ConvertTo-TDTServiceMap -Services $reference.Services
$candMap = ConvertTo-TDTServiceMap -Services $candidate.Services

$allNames = @($refMap.Keys + $candMap.Keys | Sort-Object -Unique)
$rows = foreach ($name in $allNames) {
    $ref = $refMap[$name]
    $cand = $candMap[$name]

    if ($null -eq $ref) {
        $category = 'CANDIDATE_ONLY'
    }
    elseif ($null -eq $cand) {
        $category = 'REFERENCE_ONLY'
    }
    else {
        $modeDiff = (Join-TDTValues $ref.StartModes) -ne (Join-TDTValues $cand.StartModes)
        $delayedDiff = (Join-TDTValues $ref.DelayedAutoStart) -ne (Join-TDTValues $cand.DelayedAutoStart)
        $stateDiff = (Join-TDTValues $ref.States) -ne (Join-TDTValues $cand.States)

        if ($modeDiff -or $delayedDiff) {
            $category = 'START_CONFIGURATION_DIFFERENT'
        }
        elseif ($stateDiff) {
            $category = 'STATE_DIFFERENT'
        }
        else {
            $category = 'IDENTICAL_CORE_STATE'
        }
    }

    [pscustomobject]@{
        NormalizedName            = $name
        DisplayName               = if ($cand) { $cand.DisplayName } else { $ref.DisplayName }
        Category                  = $category
        ReferenceInstances        = if ($ref) { Join-TDTValues $ref.Instances } else { '' }
        CandidateInstances        = if ($cand) { Join-TDTValues $cand.Instances } else { '' }
        ReferenceStartMode        = if ($ref) { Join-TDTValues $ref.StartModes } else { '' }
        CandidateStartMode        = if ($cand) { Join-TDTValues $cand.StartModes } else { '' }
        ReferenceDelayedAutoStart = if ($ref) { Join-TDTValues $ref.DelayedAutoStart } else { '' }
        CandidateDelayedAutoStart = if ($cand) { Join-TDTValues $cand.DelayedAutoStart } else { '' }
        ReferenceState            = if ($ref) { Join-TDTValues $ref.States } else { '' }
        CandidateState            = if ($cand) { Join-TDTValues $cand.States } else { '' }
    }
}

$rows = @($rows | Sort-Object Category, NormalizedName)

$summary = [ordered]@{
    TotalCompared                = $rows.Count
    ReferenceOnly               = @($rows | Where-Object Category -eq 'REFERENCE_ONLY').Count
    CandidateOnly               = @($rows | Where-Object Category -eq 'CANDIDATE_ONLY').Count
    StartConfigurationDifferent = @($rows | Where-Object Category -eq 'START_CONFIGURATION_DIFFERENT').Count
    StateDifferent              = @($rows | Where-Object Category -eq 'STATE_DIFFERENT').Count
    IdenticalCoreState          = @($rows | Where-Object Category -eq 'IDENTICAL_CORE_STATE').Count
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$jsonPath = Join-Path $OutputDirectory "Services-Comparison-$stamp.json"
$csvPath = Join-Path $OutputDirectory "Services-Comparison-$stamp.csv"

$result = [pscustomobject]@{
    SchemaVersion = 1
    GeneratedAt   = (Get-Date).ToString('s')
    Reference     = [pscustomobject]@{
        Path        = (Resolve-Path -LiteralPath $ReferencePath).Path
        Label       = $reference.Label
        Windows     = $reference.Windows
        Schema      = $reference.SchemaVersion
    }
    Candidate     = [pscustomobject]@{
        Path        = (Resolve-Path -LiteralPath $CandidatePath).Path
        Label       = $candidate.Label
        Windows     = $candidate.Windows
        Schema      = $candidate.SchemaVersion
    }
    BuildMismatch = ([string]$reference.Windows.BuildNumber -ne [string]$candidate.Windows.BuildNumber)
    Summary       = [pscustomobject]$summary
    Differences   = @($rows | Where-Object Category -ne 'IDENTICAL_CORE_STATE')
    All           = $rows
}

$result | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $jsonPath -Encoding UTF8
$rows | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8

Write-Host '==================================================' -ForegroundColor Cyan
Write-Host ' TECNICO DIGITALE - SERVICES COMPARISON' -ForegroundColor Cyan
Write-Host '==================================================' -ForegroundColor Cyan
Write-Host ("Reference : {0} - build {1}" -f $reference.Label, $reference.Windows.BuildNumber)
Write-Host ("Candidate : {0} - build {1}" -f $candidate.Label, $candidate.Windows.BuildNumber)
if ($result.BuildMismatch) {
    Write-Warning 'Le build sono diverse: alcune differenze possono dipendere dalla versione di Windows e non dall edizione.'
}
Write-Host ("Solo reference : {0}" -f $summary.ReferenceOnly)
Write-Host ("Solo candidate : {0}" -f $summary.CandidateOnly)
Write-Host ("Start config diversa: {0}" -f $summary.StartConfigurationDifferent)
Write-Host ("Solo stato diverso: {0}" -f $summary.StateDifferent)
Write-Host ("Identici core state: {0}" -f $summary.IdenticalCoreState)
Write-Host "JSON: $jsonPath"
Write-Host "CSV : $csvPath"
