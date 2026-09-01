function Invoke-TDTGaming {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param([Parameter(Mandatory)]$Config)

    Write-Host '[Gaming] Configurazione opzioni gaming sicure'

    if ($Config.EnableGameMode) {
        $gameBar = 'HKCU:\Software\Microsoft\GameBar'
        if (-not (Test-Path $gameBar)) { New-Item -Path $gameBar -Force | Out-Null }
        if ($PSCmdlet.ShouldProcess($gameBar, 'Abilitare Game Mode')) {
            New-ItemProperty -Path $gameBar -Name AutoGameModeEnabled -PropertyType DWord -Value 1 -Force | Out-Null
            New-ItemProperty -Path $gameBar -Name AllowAutoGameMode -PropertyType DWord -Value 1 -Force | Out-Null
        }
    }

    if ($Config.DisableGameDVR) {
        $capture = 'HKCU:\System\GameConfigStore'
        if (-not (Test-Path $capture)) { New-Item -Path $capture -Force | Out-Null }
        if ($PSCmdlet.ShouldProcess($capture, 'Disabilitare Game DVR in background')) {
            New-ItemProperty -Path $capture -Name GameDVR_Enabled -PropertyType DWord -Value 0 -Force | Out-Null
        }
    }
}
