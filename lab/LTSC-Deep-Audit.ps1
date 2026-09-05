[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Label
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Get-SafeValue {
    param([scriptblock]$Script, $Default = $null)
    try { & $Script } catch { $Default }
}

function Get-RegistryValuesFlat {
    param([string[]]$Paths)

    $items = @()
    foreach ($path in $Paths) {
        if (-not (Test-Path $path)) { continue }
        try {
            $keys = @((Get-Item $path -ErrorAction Stop))
            $keys += @(Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue)
            foreach ($key in $keys) {
                try {
                    $props = Get-ItemProperty -LiteralPath $key.PSPath -ErrorAction Stop
                    foreach ($p in $props.PSObject.Properties) {
                        if ($p.Name -like 'PS*') { continue }
                        $items += [pscustomobject]@{
                            Path  = $key.Name
                            Name  = $p.Name
                            Value = [string]$p.Value
                        }
                    }
                } catch { }
            }
        } catch { }
    }
    @($items | Sort-Object Path, Name)
}

$root = Split-Path -Parent $PSScriptRoot
$reportDir = Join-Path $PSScriptRoot 'reports'
if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$safeLabel = ($Label -replace '[^A-Za-z0-9._-]', '_')
$outPath = Join-Path $reportDir ("DeepAudit-{0}-{1}.json" -f $safeLabel, $stamp)

Write-Host '=============================================================='
Write-Host ' TecnicoDigitale - LTSC Deep Audit (READ-ONLY)'
Write-Host '=============================================================='
Write-Host ("Label: {0}" -f $Label)
Write-Host 'Nessuna impostazione verra modificata.'
Write-Host ''

$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
$cpu = @(Get-CimInstance Win32_Processor)

$processes = @()
foreach ($p in (Get-Process | Sort-Object ProcessName, Id)) {
    $processes += [pscustomobject]@{
        Name             = $p.ProcessName
        Id               = $p.Id
        CPUSeconds       = Get-SafeValue { [math]::Round([double]$p.CPU, 2) } 0
        WorkingSetMB     = [math]::Round($p.WorkingSet64 / 1MB, 2)
        PrivateMemoryMB  = [math]::Round($p.PrivateMemorySize64 / 1MB, 2)
        HandleCount      = Get-SafeValue { $p.HandleCount } $null
        Path             = Get-SafeValue { $p.Path } $null
        Company          = Get-SafeValue { $p.Company } $null
    }
}

$scheduledTasks = @()
if (Get-Command Get-ScheduledTask -ErrorAction SilentlyContinue) {
    foreach ($t in (Get-ScheduledTask -ErrorAction SilentlyContinue | Sort-Object TaskPath, TaskName)) {
        $actions = @()
        foreach ($a in @($t.Actions)) {
            $actions += [pscustomobject]@{
                Execute          = Get-SafeValue { [string]$a.Execute } $null
                Arguments        = Get-SafeValue { [string]$a.Arguments } $null
                WorkingDirectory = Get-SafeValue { [string]$a.WorkingDirectory } $null
            }
        }
        $scheduledTasks += [pscustomobject]@{
            TaskPath = $t.TaskPath
            TaskName = $t.TaskName
            State    = [string]$t.State
            Enabled  = [bool]$t.Settings.Enabled
            Hidden   = [bool]$t.Settings.Hidden
            Actions  = $actions
        }
    }
}

$appxInstalled = @()
if (Get-Command Get-AppxPackage -ErrorAction SilentlyContinue) {
    foreach ($a in (Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Sort-Object Name, Version)) {
        $appxInstalled += [pscustomobject]@{
            Name              = $a.Name
            Version           = [string]$a.Version
            Publisher         = $a.Publisher
            Architecture      = [string]$a.Architecture
            NonRemovable      = Get-SafeValue { [bool]$a.NonRemovable } $null
            IsFramework       = Get-SafeValue { [bool]$a.IsFramework } $null
            PackageFullName   = $a.PackageFullName
        }
    }
}

$appxProvisioned = @()
if (Get-Command Get-AppxProvisionedPackage -ErrorAction SilentlyContinue) {
    foreach ($a in (Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Sort-Object DisplayName, Version)) {
        $appxProvisioned += [pscustomobject]@{
            DisplayName = $a.DisplayName
            Version     = [string]$a.Version
            PackageName = $a.PackageName
        }
    }
}

$optionalFeatures = @()
if (Get-Command Get-WindowsOptionalFeature -ErrorAction SilentlyContinue) {
    foreach ($f in (Get-WindowsOptionalFeature -Online -ErrorAction SilentlyContinue | Sort-Object FeatureName)) {
        $optionalFeatures += [pscustomobject]@{
            FeatureName = $f.FeatureName
            State       = [string]$f.State
        }
    }
}

$capabilities = @()
if (Get-Command Get-WindowsCapability -ErrorAction SilentlyContinue) {
    foreach ($c in (Get-WindowsCapability -Online -ErrorAction SilentlyContinue | Sort-Object Name)) {
        $capabilities += [pscustomobject]@{
            Name  = $c.Name
            State = [string]$c.State
        }
    }
}

$uninstallRoots = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
$installedPrograms = @()
foreach ($u in $uninstallRoots) {
    foreach ($item in (Get-ItemProperty $u -ErrorAction SilentlyContinue)) {
        if ([string]::IsNullOrWhiteSpace([string]$item.DisplayName)) { continue }
        $installedPrograms += [pscustomobject]@{
            DisplayName     = [string]$item.DisplayName
            DisplayVersion  = [string]$item.DisplayVersion
            Publisher       = [string]$item.Publisher
            InstallLocation = [string]$item.InstallLocation
            UninstallString = [string]$item.UninstallString
        }
    }
}
$installedPrograms = @($installedPrograms | Sort-Object DisplayName, DisplayVersion -Unique)

$startup = @()
foreach ($s in (Get-CimInstance Win32_StartupCommand -ErrorAction SilentlyContinue | Sort-Object Name, Location)) {
    $startup += [pscustomobject]@{
        Name     = $s.Name
        Command  = $s.Command
        Location = $s.Location
        User     = $s.User
    }
}

$services = @()
foreach ($s in (Get-CimInstance Win32_Service | Sort-Object Name)) {
    $services += [pscustomobject]@{
        Name      = $s.Name
        State     = $s.State
        StartMode = $s.StartMode
        StartName = $s.StartName
        PathName  = $s.PathName
    }
}

$policyPaths = @(
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection',
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent',
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search',
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate',
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy',
    'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent',
    'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer',
    'HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot'
)
$policies = Get-RegistryValuesFlat -Paths $policyPaths

$memoryTotalMB = [math]::Round($os.TotalVisibleMemorySize / 1024, 0)
$memoryFreeMB = [math]::Round($os.FreePhysicalMemory / 1024, 0)
$memoryUsedMB = $memoryTotalMB - $memoryFreeMB

$enabledTasks = @($scheduledTasks | Where-Object Enabled)
$runningProcesses = @($processes)
$edgeProcesses = @($processes | Where-Object { $_.Name -match '^(msedge|msedgewebview2)$' })

$report = [ordered]@{
    SchemaVersion = 1
    AuditType      = 'LTSC-Deep-Audit'
    GeneratedAt    = (Get-Date).ToString('s')
    Label          = $Label
    Computer       = [ordered]@{
        Manufacturer = $cs.Manufacturer
        Model        = $cs.Model
        TotalRAMMB   = [math]::Round($cs.TotalPhysicalMemory / 1MB, 0)
        Processor    = @($cpu | ForEach-Object { $_.Name })
    }
    Windows        = [ordered]@{
        Caption     = $os.Caption
        Version     = $os.Version
        BuildNumber = $os.BuildNumber
        Architecture = $os.OSArchitecture
        LastBootUpTime = Get-SafeValue { ([datetime]$os.LastBootUpTime).ToString('s') } $null
    }
    Snapshot       = [ordered]@{
        ProcessCount           = $runningProcesses.Count
        TotalWorkingSetMB      = [math]::Round((($runningProcesses | Measure-Object WorkingSetMB -Sum).Sum), 2)
        TotalPrivateMemoryMB   = [math]::Round((($runningProcesses | Measure-Object PrivateMemoryMB -Sum).Sum), 2)
        PhysicalMemoryTotalMB  = $memoryTotalMB
        PhysicalMemoryUsedMB   = $memoryUsedMB
        PhysicalMemoryFreeMB   = $memoryFreeMB
        EnabledScheduledTasks  = $enabledTasks.Count
        InstalledAppxCount     = $appxInstalled.Count
        ProvisionedAppxCount   = $appxProvisioned.Count
        EnabledFeatureCount    = @($optionalFeatures | Where-Object State -eq 'Enabled').Count
        InstalledCapabilityCount = @($capabilities | Where-Object State -eq 'Installed').Count
        StartupItemCount       = $startup.Count
        RunningServiceCount    = @($services | Where-Object State -eq 'Running').Count
        EdgeWebViewProcessCount = $edgeProcesses.Count
        EdgeWebViewWorkingSetMB = [math]::Round((($edgeProcesses | Measure-Object WorkingSetMB -Sum).Sum), 2)
    }
    Processes       = $processes
    ScheduledTasks  = $scheduledTasks
    AppxInstalled   = $appxInstalled
    AppxProvisioned = $appxProvisioned
    OptionalFeatures = $optionalFeatures
    Capabilities    = $capabilities
    InstalledPrograms = $installedPrograms
    StartupItems    = $startup
    Services        = $services
    Policies        = $policies
}

$report | ConvertTo-Json -Depth 8 | Set-Content -Path $outPath -Encoding UTF8

Write-Host ''
Write-Host 'Riepilogo snapshot:' -ForegroundColor Cyan
Write-Host ("  Processi                    : {0}" -f $report.Snapshot.ProcessCount)
Write-Host ("  RAM fisica usata           : {0} MB / {1} MB" -f $report.Snapshot.PhysicalMemoryUsedMB, $report.Snapshot.PhysicalMemoryTotalMB)
Write-Host ("  Task pianificati abilitati : {0}" -f $report.Snapshot.EnabledScheduledTasks)
Write-Host ("  AppX installate             : {0}" -f $report.Snapshot.InstalledAppxCount)
Write-Host ("  AppX provisioned            : {0}" -f $report.Snapshot.ProvisionedAppxCount)
Write-Host ("  Feature abilitate           : {0}" -f $report.Snapshot.EnabledFeatureCount)
Write-Host ("  Capability installate       : {0}" -f $report.Snapshot.InstalledCapabilityCount)
Write-Host ("  Startup item                : {0}" -f $report.Snapshot.StartupItemCount)
Write-Host ("  Servizi Running             : {0}" -f $report.Snapshot.RunningServiceCount)
Write-Host ("  Edge/WebView processi       : {0}" -f $report.Snapshot.EdgeWebViewProcessCount)
Write-Host ''
Write-Host ("Report creato: {0}" -f $outPath) -ForegroundColor Green
Write-Host 'Carica questo JSON in chat per il confronto.' -ForegroundColor Green
