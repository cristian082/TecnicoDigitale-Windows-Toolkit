[CmdletBinding()]
param([string]$Label = 'CURRENT')

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Safe {
    param([scriptblock]$Script, $Default = $null)
    try { & $Script } catch { $Default }
}

function Prop {
    param($Object, [string]$Name, $Default = '')
    if ($null -eq $Object) { return $Default }
    $p = $Object.PSObject.Properties[$Name]
    if ($null -eq $p) { return $Default }
    return $p.Value
}

$reportDir = Join-Path $PSScriptRoot 'reports'
if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}

$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
$cpu = @(Get-CimInstance Win32_Processor)

$safeLabel = $Label -replace '[^A-Za-z0-9._-]', '_'
$safeComputer = $env:COMPUTERNAME -replace '[^A-Za-z0-9._-]', '_'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmssfff'
$unique = [guid]::NewGuid().ToString('N').Substring(0,8)
$outName = "DeepAudit-$safeLabel-Build$($os.BuildNumber)-$safeComputer-$stamp-$unique.json"
$outPath = Join-Path $reportDir $outName

Write-Host '=============================================================='
Write-Host ' TecnicoDigitale - Windows 11 Deep Audit (READ-ONLY)' -ForegroundColor Cyan
Write-Host '=============================================================='
Write-Host "Windows: $($os.Caption) - Build $($os.BuildNumber)"
Write-Host "Computer: $env:COMPUTERNAME"
Write-Host 'Nessuna impostazione verra modificata.'
Write-Host ''

$processes = @(
    Get-Process | Sort-Object ProcessName, Id | ForEach-Object {
        [pscustomobject]@{
            Name            = $_.ProcessName
            Id              = $_.Id
            CPUSeconds      = Safe { [math]::Round([double]$_.CPU, 2) } 0
            WorkingSetMB    = [math]::Round($_.WorkingSet64 / 1MB, 2)
            PrivateMemoryMB = [math]::Round($_.PrivateMemorySize64 / 1MB, 2)
            HandleCount     = Safe { $_.HandleCount } $null
            Path            = Safe { $_.Path } $null
            Company         = Safe { $_.Company } $null
        }
    }
)

$tasks = @()
if (Get-Command Get-ScheduledTask -ErrorAction SilentlyContinue) {
    $tasks = @(
        Get-ScheduledTask -ErrorAction SilentlyContinue | Sort-Object TaskPath, TaskName | ForEach-Object {
            [pscustomobject]@{
                TaskPath = [string](Prop $_ 'TaskPath' '')
                TaskName = [string](Prop $_ 'TaskName' '')
                State    = [string](Prop $_ 'State' '')
                Enabled  = Safe { [bool]$_.Settings.Enabled } $false
                Hidden   = Safe { [bool]$_.Settings.Hidden } $false
            }
        }
    )
}

$appx = @()
if (Get-Command Get-AppxPackage -ErrorAction SilentlyContinue) {
    $appx = @(
        Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Sort-Object Name, Version | ForEach-Object {
            [pscustomobject]@{
                Name    = [string](Prop $_ 'Name' '')
                Version = [string](Prop $_ 'Version' '')
            }
        }
    )
}

$prov = @()
if (Get-Command Get-AppxProvisionedPackage -ErrorAction SilentlyContinue) {
    $prov = @(
        Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Sort-Object DisplayName | ForEach-Object {
            [pscustomobject]@{
                DisplayName = [string](Prop $_ 'DisplayName' '')
                Version     = [string](Prop $_ 'Version' '')
            }
        }
    )
}

$features = @()
if (Get-Command Get-WindowsOptionalFeature -ErrorAction SilentlyContinue) {
    $features = @(
        Get-WindowsOptionalFeature -Online -ErrorAction SilentlyContinue | ForEach-Object {
            [pscustomobject]@{
                FeatureName = [string](Prop $_ 'FeatureName' '')
                State       = [string](Prop $_ 'State' '')
            }
        }
    )
}

$caps = @()
if (Get-Command Get-WindowsCapability -ErrorAction SilentlyContinue) {
    $caps = @(
        Get-WindowsCapability -Online -ErrorAction SilentlyContinue | ForEach-Object {
            [pscustomobject]@{
                Name  = [string](Prop $_ 'Name' '')
                State = [string](Prop $_ 'State' '')
            }
        }
    )
}

$programs = @()
$uninstallRoots = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
foreach ($root in $uninstallRoots) {
    foreach ($item in @(Get-ItemProperty $root -ErrorAction SilentlyContinue)) {
        $displayName = [string](Prop $item 'DisplayName' '')
        if ([string]::IsNullOrWhiteSpace($displayName)) { continue }
        $programs += [pscustomobject]@{
            DisplayName    = $displayName
            DisplayVersion = [string](Prop $item 'DisplayVersion' '')
            Publisher      = [string](Prop $item 'Publisher' '')
        }
    }
}
$programs = @($programs | Sort-Object DisplayName, DisplayVersion -Unique)

$startup = @(
    Get-CimInstance Win32_StartupCommand -ErrorAction SilentlyContinue | Sort-Object Name, Location | ForEach-Object {
        [pscustomobject]@{
            Name     = [string](Prop $_ 'Name' '')
            Command  = [string](Prop $_ 'Command' '')
            Location = [string](Prop $_ 'Location' '')
            User     = [string](Prop $_ 'User' '')
        }
    }
)

$services = @(
    Get-CimInstance Win32_Service | Sort-Object Name | ForEach-Object {
        [pscustomobject]@{
            Name      = [string](Prop $_ 'Name' '')
            State     = [string](Prop $_ 'State' '')
            StartMode = [string](Prop $_ 'StartMode' '')
            StartName = [string](Prop $_ 'StartName' '')
            PathName  = [string](Prop $_ 'PathName' '')
        }
    }
)

$total = [math]::Round($os.TotalVisibleMemorySize / 1024, 0)
$free = [math]::Round($os.FreePhysicalMemory / 1024, 0)
$edge = @($processes | Where-Object { $_.Name -match '^(msedge|msedgewebview2)$' })

$report = [ordered]@{
    SchemaVersion = 4
    AuditType      = 'Windows11-Deep-Audit'
    GeneratedAt    = (Get-Date).ToString('s')
    Label          = $Label
    ReportFileName = $outName
    Computer       = [ordered]@{
        ComputerName = $env:COMPUTERNAME
        Manufacturer = $cs.Manufacturer
        Model        = $cs.Model
        TotalRAMMB   = [math]::Round($cs.TotalPhysicalMemory / 1MB, 0)
        Processor    = @($cpu | ForEach-Object { $_.Name })
    }
    Windows = [ordered]@{
        Caption        = $os.Caption
        Version        = $os.Version
        BuildNumber    = $os.BuildNumber
        Architecture   = $os.OSArchitecture
        LastBootUpTime = Safe { ([datetime]$os.LastBootUpTime).ToString('s') } $null
    }
    Snapshot = [ordered]@{
        ProcessCount             = $processes.Count
        TotalWorkingSetMB        = [math]::Round((($processes | Measure-Object WorkingSetMB -Sum).Sum), 2)
        TotalPrivateMemoryMB     = [math]::Round((($processes | Measure-Object PrivateMemoryMB -Sum).Sum), 2)
        PhysicalMemoryTotalMB    = $total
        PhysicalMemoryUsedMB     = $total - $free
        PhysicalMemoryFreeMB     = $free
        EnabledScheduledTasks    = @($tasks | Where-Object Enabled).Count
        InstalledAppxCount       = $appx.Count
        ProvisionedAppxCount     = $prov.Count
        EnabledFeatureCount      = @($features | Where-Object State -eq 'Enabled').Count
        InstalledCapabilityCount = @($caps | Where-Object State -eq 'Installed').Count
        StartupItemCount         = $startup.Count
        RunningServiceCount      = @($services | Where-Object State -eq 'Running').Count
        EdgeWebViewProcessCount  = $edge.Count
        EdgeWebViewWorkingSetMB  = [math]::Round((($edge | Measure-Object WorkingSetMB -Sum).Sum), 2)
    }
    Processes         = $processes
    ScheduledTasks    = $tasks
    AppxInstalled     = $appx
    AppxProvisioned   = $prov
    OptionalFeatures  = $features
    Capabilities      = $caps
    InstalledPrograms = $programs
    StartupItems      = $startup
    Services          = $services
}

$report | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath $outPath -Encoding UTF8

Write-Host 'Riepilogo snapshot:' -ForegroundColor Cyan
Write-Host "  Processi             : $($report.Snapshot.ProcessCount)"
Write-Host "  RAM fisica usata     : $($report.Snapshot.PhysicalMemoryUsedMB) MB / $total MB"
Write-Host "  Startup item          : $($report.Snapshot.StartupItemCount)"
Write-Host "  Servizi Running       : $($report.Snapshot.RunningServiceCount)"
Write-Host "  AppX provisioned      : $($report.Snapshot.ProvisionedAppxCount)"
Write-Host ''
Write-Host "Report creato: $outPath" -ForegroundColor Green
