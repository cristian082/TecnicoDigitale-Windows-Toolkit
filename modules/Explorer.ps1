function Invoke-TDTExplorer {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param([Parameter(Mandatory)]$Config)

    Write-Host '[Explorer] Configurazione Esplora file'
    $advanced = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'

    if ($Config.ShowFileExtensions -and $PSCmdlet.ShouldProcess($advanced, 'Mostrare estensioni file')) {
        Set-ItemProperty -Path $advanced -Name HideFileExt -Type DWord -Value 0
    }

    if ($Config.OpenThisPC -and $PSCmdlet.ShouldProcess($advanced, 'Aprire Esplora file su Questo PC')) {
        Set-ItemProperty -Path $advanced -Name LaunchTo -Type DWord -Value 1
    }

    if ($Config.ShowHiddenFiles -and $PSCmdlet.ShouldProcess($advanced, 'Mostrare file nascosti')) {
        Set-ItemProperty -Path $advanced -Name Hidden -Type DWord -Value 1
    }
}
