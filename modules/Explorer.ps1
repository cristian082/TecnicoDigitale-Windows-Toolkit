function Invoke-TDTExplorer {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param([Parameter(Mandatory)]$Config)

    Write-Host '[Explorer] Configurazione Esplora file'
    $advanced = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'

    if ($Config.ShowFileExtensions -and $PSCmdlet.ShouldProcess($advanced, 'Mostrare estensioni file')) {
        New-ItemProperty -Path $advanced -Name HideFileExt -PropertyType DWord -Value 0 -Force | Out-Null
    }

    if ($Config.OpenThisPC -and $PSCmdlet.ShouldProcess($advanced, 'Aprire Esplora file su Questo PC')) {
        New-ItemProperty -Path $advanced -Name LaunchTo -PropertyType DWord -Value 1 -Force | Out-Null
    }

    if ($Config.ShowHiddenFiles -and $PSCmdlet.ShouldProcess($advanced, 'Mostrare file nascosti')) {
        New-ItemProperty -Path $advanced -Name Hidden -PropertyType DWord -Value 1 -Force | Out-Null
    }
}
