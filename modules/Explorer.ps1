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
}
