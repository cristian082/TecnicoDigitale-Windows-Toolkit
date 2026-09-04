[CmdletBinding()]
param(
    [string]$Label = 'Windows',
    [string]$OutputDirectory = (Join-Path $PSScriptRoot 'reports')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}

function Get-TDTNormalizedServiceName {
    param([Parameter(Mandatory)][string]$Name)

    # Per-user service instances receive a logon-specific hexadecimal suffix,
    # e.g. cbdhsvc_516e3. Remove only that suffix for cross-machine comparison.
    return ($Name -replace '_[0-9A-Fa-f]{5,}$', '')
}

function Get-TDTDelayedAutoStart {
    param([Parameter(Mandatory)][string]$Name)

    try {
        $path = "HKLM:\SYSTEM\CurrentControlSet\Services\$Name"
        $item = Get-ItemProperty -LiteralPath $path -Name DelayedAutoStart -ErrorAction Stop
        return ([int]$item.DelayedAutoStart -eq 1)
    }
    catch {
        return $false
    }
}

function Get-TDTServiceDependencies {
    param([Parameter(Mandatory)][string]$Name)

    try {
        $svc = Get-Service -Name $Name -ErrorAction Stop
        return @($svc.ServicesDependedOn | ForEach-Object Name | Sort-Object -Unique)
    }
    catch {
        return @()
    }
}

function Get-TDTServiceDependents {
    param([Parameter(Mandatory)][string]$Name)

    try {
        $svc = Get-Service -Name $Name -ErrorAction Stop
        return @($svc.DependentServices | ForEach-Object Name | Sort-Object -Unique)
    }
    catch {
        return @()
    }
}

function Get-TDTServiceTriggerInfo {
    param([Parameter(Mandatory)][string]$Name)

    try {
        $output = @(& sc.exe qtriggerinfo $Name 2>&1)
        $exitCode = $LASTEXITCODE
        return [pscustomobject]@{
            ExitCode = $exitCode
            Raw      = @($output | ForEach-Object { [string]$_ })
        }
    }
    catch {
        return [pscustomobject]@{
            ExitCode = -1
            Raw      = @([string]$_.Exception.Message)
        }
    }
}

$os = Get-CimInstance Win32_OperatingSystem
$computer = Get-CimInstance Win32_ComputerSystem

$services = @(Get-CimInstance Win32_Service | Sort-Object Name | ForEach-Object {
    $trigger = Get-TDTServiceTriggerInfo -Name $_.Name

    [pscustomobject]@{
        Name             = $_.Name
        NormalizedName   = Get-TDTNormalizedServiceName -Name $_.Name
        DisplayName      = $_.DisplayName
        State            = $_.State
        StartMode        = $_.StartMode
        DelayedAutoStart = if ($_.StartMode -eq 'Auto') { Get-TDTDelayedAutoStart -Name $_.Name } else { $false }
        StartName        = $_.StartName
        PathName         = $_.PathName
        ProcessId        = $_.ProcessId
        ServiceType      = $_.ServiceType
        Dependencies     = @(Get-TDTServiceDependencies -Name $_.Name)
        Dependents       = @(Get-TDTServiceDependents -Name $_.Name)
        TriggerQueryCode = $trigger.ExitCode
        TriggerInfoRaw   = @($trigger.Raw)
    }
})

$running = @($services | Where-Object State -eq 'Running')
$automatic = @($services | Where-Object StartMode -eq 'Auto')
$delayed = @($services | Where-Object DelayedAutoStart)
$manual = @($services | Where-Object StartMode -eq 'Manual')
$disabled = @($services | Where-Object StartMode -eq 'Disabled')

$report = [pscustomobject]@{
    SchemaVersion = 2
    GeneratedAt   = (Get-Date).ToString('s')
    Label         = $Label
    Computer      = [pscustomobject]@{
        Manufacturer = $computer.Manufacturer
        Model        = $computer.Model
    }
    Windows       = [pscustomobject]@{
        Caption     = $os.Caption
        Version     = $os.Version
        BuildNumber = $os.BuildNumber
    }
    Summary       = [pscustomobject]@{
        Total                = $services.Count
        Running              = $running.Count
        Automatic            = $automatic.Count
        AutomaticDelayed     = $delayed.Count
        Manual               = $manual.Count
        Disabled             = $disabled.Count
        NormalizedServiceSet = @($services.NormalizedName | Sort-Object -Unique).Count
    }
    Services      = $services
}

$safeLabel = ($Label -replace '[^a-zA-Z0-9_-]', '_')
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$jsonPath = Join-Path $OutputDirectory ("Services-$safeLabel-$stamp.json")
$csvPath = Join-Path $OutputDirectory ("Services-$safeLabel-$stamp.csv")

$report | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $jsonPath -Encoding UTF8
$services | Select-Object Name, NormalizedName, DisplayName, State, StartMode, DelayedAutoStart, StartName, PathName, ProcessId, ServiceType,
    @{Name='Dependencies';Expression={($_.Dependencies -join ';')}},
    @{Name='Dependents';Expression={($_.Dependents -join ';')}},
    TriggerQueryCode,
    @{Name='TriggerInfo';Expression={($_.TriggerInfoRaw -join ' | ')}} |
    Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8

Write-Host '==================================================' -ForegroundColor Cyan
Write-Host ' TECNICO DIGITALE - SERVICES AUDIT V2 (READ-ONLY)' -ForegroundColor Cyan
Write-Host '==================================================' -ForegroundColor Cyan
Write-Host ("Sistema: {0} - build {1}" -f $os.Caption, $os.BuildNumber)
Write-Host ("Servizi totali: {0}" -f $services.Count)
Write-Host ("In esecuzione: {0}" -f $running.Count)
Write-Host ("Automatici: {0}" -f $automatic.Count)
Write-Host ("  di cui ritardati: {0}" -f $delayed.Count)
Write-Host ("Manuali: {0}" -f $manual.Count)
Write-Host ("Disabilitati: {0}" -f $disabled.Count)
Write-Host ("Nomi normalizzati: {0}" -f $report.Summary.NormalizedServiceSet)
Write-Host "JSON: $jsonPath"
Write-Host "CSV : $csvPath"
Write-Host ''
Write-Host 'Nessun servizio o stato modificato.' -ForegroundColor Green
