function Invoke-TDTGaming {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param([Parameter(Mandatory)]$Config,[string]$Root)

    Write-Host '[Gaming] Configurazione opzioni gaming sicure'

    if (-not $WhatIfPreference -and $Root) {
        Initialize-TDTGamingOwnership -Root $Root
    }

    if ($Config.EnableGameMode) {
        $gameBar = 'HKCU:\Software\Microsoft\GameBar'
        if ($PSCmdlet.ShouldProcess($gameBar, 'Abilitare Game Mode')) {
            [void](Set-TDTRegistryDword -Path $gameBar -Name 'AutoGameModeEnabled' -Value 1)
            [void](Set-TDTRegistryDword -Path $gameBar -Name 'AllowAutoGameMode' -Value 1)
        }
    }

    if ($Config.DisableGameDVR) {
        $capture = 'HKCU:\System\GameConfigStore'
        if ($PSCmdlet.ShouldProcess($capture, 'Disabilitare Game DVR in background')) {
            [void](Set-TDTRegistryDword -Path $capture -Name 'GameDVR_Enabled' -Value 0)
        }
    }
}
