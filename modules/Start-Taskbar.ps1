function Invoke-TDTStartTaskbar {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param([Parameter(Mandatory)]$Config)

    Write-Host '[Start/Taskbar] Configurazione barra e menu Start'
    $advanced = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'

    if ($Config.HideWidgets -and $PSCmdlet.ShouldProcess($advanced, 'Nascondere Widgets')) {
        New-ItemProperty -Path $advanced -Name TaskbarDa -PropertyType DWord -Value 0 -Force | Out-Null
    }

    if ($Config.LeftAlignTaskbar -and $PSCmdlet.ShouldProcess($advanced, 'Allineare Start a sinistra')) {
        New-ItemProperty -Path $advanced -Name TaskbarAl -PropertyType DWord -Value 0 -Force | Out-Null
    }

    if ($Config.DisableSearchHighlights) {
        $search = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings'
        if (-not (Test-Path $search)) { New-Item -Path $search -Force | Out-Null }
        if ($PSCmdlet.ShouldProcess($search, 'Disabilitare evidenziazioni ricerca')) {
            New-ItemProperty -Path $search -Name IsDynamicSearchBoxEnabled -PropertyType DWord -Value 0 -Force | Out-Null
        }
    }
}
