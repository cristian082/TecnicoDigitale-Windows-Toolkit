function Invoke-TDTStartTaskbar {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param([Parameter(Mandatory)]$Config)

    Write-Host '[Start/Taskbar] Configurazione barra e menu Start'
    $allUsers = if ($null -ne $Config.PSObject.Properties['AllUsers']) { [bool]$Config.AllUsers } else { $true }
    $advanced = 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    $advancedPath = "HKCU:\$advanced"

    # Build 7 migration: le build precedenti registravano TaskbarAl via Active Setup.
    # Questo poteva riapplicare l'allineamento Business a sinistra a un login successivo,
    # anche dopo che ProfileState aveva correttamente ripristinato Standard.
    # TaskbarAl e ora intenzionalmente solo per l'utente corrente e gestito da ProfileState.
    $staleTaskbarActiveSetup = $false
    $taskbarComponentPath = Get-TDTActiveSetupComponentPath -RelativePath $advanced -Name 'TaskbarAl'
    if (Test-Path $taskbarComponentPath) {
        if ($PSCmdlet.ShouldProcess($taskbarComponentPath, 'Rimuovere vecchio Active Setup TaskbarAl del Toolkit')) {
            $staleTaskbarActiveSetup = Remove-TDTActiveSetupDword -RelativePath $advanced -Name 'TaskbarAl'
        }
    }

    # Se stiamo migrando da una build affetta dal bug e il vecchio Active Setup ha appena
    # riapplicato TaskbarAl=0 fuori dal controllo di ProfileState, rimuoviamo solo quel valore.
    # L'assenza di TaskbarAl corrisponde al comportamento Windows predefinito (centrato).
    if ($staleTaskbarActiveSetup -and -not $Config.LeftAlignTaskbar -and (Test-Path $advancedPath)) {
        try {
            $key = Get-Item -LiteralPath $advancedPath -ErrorAction Stop
            if ($key.GetValueNames() -contains 'TaskbarAl') {
                $current = $key.GetValue('TaskbarAl',$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
                if ([int]$current -eq 0 -and $PSCmdlet.ShouldProcess("$advancedPath\TaskbarAl", 'Rimuovere valore residuo della vecchia gestione Business')) {
                    if (Get-Command Add-TDTRegistryBackup -ErrorAction SilentlyContinue) {
                        Add-TDTRegistryBackup -Path $advancedPath -Name 'TaskbarAl'
                    }
                    Remove-ItemProperty -LiteralPath $advancedPath -Name 'TaskbarAl' -ErrorAction Stop
                    Write-Host '[Start/Taskbar] Rimosso residuo TaskbarAl della vecchia gestione Active Setup.' -ForegroundColor DarkGray
                }
            }
        }
        catch {
            Write-Warning "Impossibile ripulire il vecchio TaskbarAl: $($_.Exception.Message)"
        }
    }

    # Widgets: use the documented machine policy instead of the protected per-user TaskbarDa value.
    if ($Config.HideWidgets -and $PSCmdlet.ShouldProcess('HKLM:\SOFTWARE\Policies\Microsoft\Dsh', 'Disabilitare Widgets per il dispositivo')) {
        $widgetsPolicy = 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh'
        [void](Set-TDTRegistryDword -Path $widgetsPolicy -Name 'AllowNewsAndInterests' -Value 0)
    }

    if ($Config.LeftAlignTaskbar -and $PSCmdlet.ShouldProcess('Taskbar', 'Allineare Start a sinistra')) {
        # Impostazione specifica Business: niente Active Setup globale, altrimenti puo
        # sopravvivere alla transizione di profilo e riapplicarsi ai login successivi.
        Set-TDTUserDword -RelativePath $advanced -Name 'TaskbarAl' -Value 0 -AllUsers $false
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
