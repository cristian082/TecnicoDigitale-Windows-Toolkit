function Invoke-TDTStartTaskbar {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param([Parameter(Mandatory)]$Config)

    Write-Host '[Start/Taskbar] Configurazione barra e menu Start'
    $allUsers = if ($null -ne $Config.PSObject.Properties['AllUsers']) { [bool]$Config.AllUsers } else { $true }
    $advanced = 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'

    # Widgets: use the documented machine policy instead of the protected per-user TaskbarDa value.
    if ($Config.HideWidgets -and $PSCmdlet.ShouldProcess('HKLM:\SOFTWARE\Policies\Microsoft\Dsh', 'Disabilitare Widgets per il dispositivo')) {
        $widgetsPolicy = 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh'
        [void](Set-TDTRegistryDword -Path $widgetsPolicy -Name 'AllowNewsAndInterests' -Value 0)
    }

    if ($Config.LeftAlignTaskbar -and $PSCmdlet.ShouldProcess('Taskbar', 'Allineare Start a sinistra')) {
        Set-TDTUserDword -RelativePath $advanced -Name 'TaskbarAl' -Value 0 -AllUsers $allUsers
    }

    if ($Config.DisableSearchHighlights -and $PSCmdlet.ShouldProcess('SearchSettings', 'Disabilitare evidenziazioni ricerca')) {
        Set-TDTUserDword -RelativePath 'Software\Microsoft\Windows\CurrentVersion\SearchSettings' -Name 'IsDynamicSearchBoxEnabled' -Value 0 -AllUsers $allUsers
    }

    # Removes web suggestions from the Windows search box without disabling Windows Search/indexing.
    if ($Config.DisableWebSearchSuggestions -and $PSCmdlet.ShouldProcess('Windows Search', 'Disabilitare suggerimenti web nella casella di ricerca')) {
        Set-TDTUserDword -RelativePath 'Software\Policies\Microsoft\Windows\Explorer' -Name 'DisableSearchBoxSuggestions' -Value 1 -AllUsers $allUsers
    }

    # Windows 11: enables the useful "End task" command on taskbar app context menus.
    if ($Config.EnableTaskbarEndTask -and $PSCmdlet.ShouldProcess('Taskbar', 'Abilitare Termina attivita dal menu della barra')) {
        Set-TDTUserDword -RelativePath 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings' -Name 'TaskbarEndTask' -Value 1 -AllUsers $allUsers
    }
}
