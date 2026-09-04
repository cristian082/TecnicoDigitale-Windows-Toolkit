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

$os = Get-CimInstance Win32_OperatingSystem
$computer = Get-CimInstance Win32_ComputerSystem

$services = @(Get-CimInstance Win32_Service | Sort-Object Name | ForEach-Object {
    [pscustomobject]@{
        Name        = $_.Name
        DisplayName = $_.DisplayName
        State       = $_.State
        StartMode   = $_.StartMode
        StartName   = $_.StartName
        PathName    = $_.PathName
        ProcessId   = $_.ProcessId
        ServiceType = $_.ServiceType
    }
})

$running = @($services | Where-Object State -eq 'Running')
$automatic = @($services | Where-Object StartMode -eq 'Auto')
$manual = @($services | Where-Object StartMode -eq 'Manual')
$disabled = @($services | Where-Object StartMode -eq 'Disabled')

$report = [pscustomobject]@{
    SchemaVersion = 1
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
        Total     = $services.Count
        Running   = $running.Count
        Automatic = $automatic.Count
        Manual    = $manual.Count
        Disabled  = $disabled.Count
    }
    Services      = $services
}

$safeLabel = ($Label -replace '[^a-zA-Z0-9_-]', '_')
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$jsonPath = Join-Path $OutputDirectory ("Services-$safeLabel-$stamp.json")
$csvPath = Join-Path $OutputDirectory ("Services-$safeLabel-$stamp.csv")

$report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $jsonPath -Encoding UTF8
$services | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8

Write-Host '==================================================' -ForegroundColor Cyan
Write-Host ' TECNICO DIGITALE - SERVICES AUDIT (READ-ONLY)' -ForegroundColor Cyan
Write-Host '==================================================' -ForegroundColor Cyan
Write-Host ("Sistema: {0} - build {1}" -f $os.Caption, $os.BuildNumber)
Write-Host ("Servizi totali: {0}" -f $services.Count)
Write-Host ("In esecuzione: {0}" -f $running.Count)
Write-Host ("Automatici: {0}" -f $automatic.Count)
Write-Host ("Manuali: {0}" -f $manual.Count)
Write-Host ("Disabilitati: {0}" -f $disabled.Count)
Write-Host "JSON: $jsonPath"
Write-Host "CSV : $csvPath"
Write-Host ''
Write-Host 'Nessun servizio e stato modificato.' -ForegroundColor Green
