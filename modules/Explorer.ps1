function Invoke-TDTExplorer {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param([Parameter(Mandatory)]$Config)

    Write-Host '[Explorer] Configurazione Esplora file'
    $allUsers = if ($null -ne $Config.PSObject.Properties['AllUsers']) { [bool]$Config.AllUsers } else { $true }
    $relative = 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'

    if ($Config.ShowFileExtensions -and $PSCmdlet.ShouldProcess('Explorer', 'Mostrare estensioni file')) {
        Set-TDTUserDword -RelativePath $relative -Name 'HideFileExt' -Value 0 -AllUsers $allUsers
    }

    if ($Config.OpenThisPC -and $PSCmdlet.ShouldProcess('Explorer', 'Aprire Esplora file su Questo PC')) {
        Set-TDTUserDword -RelativePath $relative -Name 'LaunchTo' -Value 1 -AllUsers $allUsers
    }

    if ($Config.ShowHiddenFiles -and $PSCmdlet.ShouldProcess('Explorer', 'Mostrare file nascosti')) {
        Set-TDTUserDword -RelativePath $relative -Name 'Hidden' -Value 1 -AllUsers $allUsers
    }

    if ($null -ne $Config.PSObject.Properties['DesktopIcons'] -and $null -ne $Config.DesktopIcons) {
        $desktopIconPaths = @(
            'Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel',
            'Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu'
        )
        $knownIcons = [ordered]@{
            ThisPC       = @{ Guid = '{20D04FE0-3AEA-1069-A2D8-08002B30309D}'; Label = 'Questo PC' }
            UserFiles    = @{ Guid = '{59031A47-3F72-44A7-89C5-5595FE6B30EE}'; Label = 'File utente' }
            RecycleBin   = @{ Guid = '{645FF040-5081-101B-9F08-00AA002F954E}'; Label = 'Cestino' }
            Network      = @{ Guid = '{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}'; Label = 'Rete' }
            ControlPanel = @{ Guid = '{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}'; Label = 'Pannello di controllo' }
        }

        foreach ($iconName in $knownIcons.Keys) {
            $property = $Config.DesktopIcons.PSObject.Properties[$iconName]
            if ($null -eq $property) { continue }
            $show = [bool]$property.Value
            $icon = $knownIcons[$iconName]
            $action = if ($show) { "Mostrare icona $($icon.Label)" } else { "Nascondere icona $($icon.Label)" }
            if ($PSCmdlet.ShouldProcess('Desktop', $action)) {
                $value = if ($show) { 0 } else { 1 }
                foreach ($desktopPath in $desktopIconPaths) {
                    Set-TDTUserDword -RelativePath $desktopPath -Name $icon.Guid -Value $value -AllUsers $allUsers
                }
            }
        }
        Write-Host '[Explorer] Icone desktop applicate secondo il preset selezionato.' -ForegroundColor DarkGray
    }
}
