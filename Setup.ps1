[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [ValidateSet('Standard','Gaming','Business')]
    [string]$Preset = 'Standard'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogDir = Join-Path $Root 'logs'
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }
$LogPath = Join-Path $LogDir ("Toolkit-{0:yyyyMMdd-HHmmss}.log" -f (Get-Date))
Start-Transcript -Path $LogPath -Force | Out-Null

function Test-Administrator {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($id)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) { throw 'Eseguire Setup.ps1 da PowerShell come amministratore.' }

$presetPath = Join-Path $Root "presets\$Preset.json"
if (-not (Test-Path $presetPath)) { throw "Preset non trovato: $presetPath" }
$config = Get-Content $presetPath -Raw | ConvertFrom-Json

$moduleOrder = @('Version','Backup','Common','ProfileState','Diagnostics','Restore','Privacy','Explorer','Start-Taskbar','Debloat','Gaming')
foreach ($module in $moduleOrder) {
    $path = Join-Path $Root "modules\$module.ps1"
    if (-not (Test-Path $path)) { throw "Modulo mancante: $path" }
    . $path
}

$script:TDTVersionInfo = Get-TDTVersionInfo -Root $Root
Write-TDTVersionBanner -VersionInfo $script:TDTVersionInfo
Write-Host "Preset: $Preset" -ForegroundColor Cyan
Write-Host 'Software: nessuna installazione automatica dal preset' -ForegroundColor DarkGray

try {
    if ($config.Diagnostics.Enabled) { [void](Invoke-TDTDiagnostics -Config $config.Diagnostics -VersionInfo $script:TDTVersionInfo) }
    if (-not $WhatIfPreference) { Initialize-TDTBackupSession -Root $Root -Preset $Preset -VersionInfo $script:TDTVersionInfo }

    if ($Preset -ne 'Gaming') { Restore-TDTGamingOwnership -Root $Root -WhatIf:$WhatIfPreference }
    if ($Preset -ne 'Business') { Restore-TDTBusinessOwnership -Root $Root -WhatIf:$WhatIfPreference }
    if ($Preset -eq 'Business' -and -not $WhatIfPreference) { Initialize-TDTBusinessOwnership -Root $Root }

    if ($config.Restore.Enabled) { Invoke-TDTRestore -Config $config.Restore -WhatIf:$WhatIfPreference }
    if ($config.Privacy.Enabled) { Invoke-TDTPrivacy -Config $config.Privacy -WhatIf:$WhatIfPreference }
    if ($config.Explorer.Enabled) { Invoke-TDTExplorer -Config $config.Explorer -WhatIf:$WhatIfPreference }
    if ($config.StartTaskbar.Enabled) { Invoke-TDTStartTaskbar -Config $config.StartTaskbar -WhatIf:$WhatIfPreference }
    if ($config.Debloat.Enabled) { Invoke-TDTDebloat -Config $config.Debloat -WhatIf:$WhatIfPreference }
    if ($config.Gaming.Enabled) { Invoke-TDTGaming -Config $config.Gaming -Root $Root -WhatIf:$WhatIfPreference }

    if (-not $WhatIfPreference) { Complete-TDTBackupSession }
    Write-Host 'Operazione completata. Alcune modifiche richiedono disconnessione o riavvio.' -ForegroundColor Green
}
finally {
    Stop-Transcript | Out-Null
    Write-Host "Log: $LogPath"
}
