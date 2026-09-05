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

    if ($null -ne $Config.PSObject.Properties['DesktopIconsByEdition'] -and $Config.DesktopIconsByEdition) {
        $editionId = ''
        try {
            $editionId = [string](Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name EditionID -ErrorAction Stop).EditionID
        }
        catch {
            Write-Warning "[Explorer] Impossibile rilevare EditionID: $($_.Exception.Message)"
        }

        $isProLike = $editionId -match '^(Professional|ProfessionalEducation|ProfessionalWorkstation|Enterprise|EnterpriseS|Education|Server)'
        $editionLabel = if ($isProLike) { 'Pro/Business' } else { 'Home/Consumer' }
        Write-Host "[Explorer] Icone desktop: profilo $editionLabel (EditionID: $editionId)" -ForegroundColor DarkGray

        $baseIcons = [ordered]@{
            '{20D04FE0-3AEA-1069-A2D8-08002B30309D}' = 'Questo PC'
            '{59031A47-3F72-44A7-89C5-5595FE6B30EE}' = 'File utente'
            '{645FF040-5081-101B-9F08-00AA002F954E}' = 'Cestino'
        }
        $proIcons = [ordered]@{
            '{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}' = 'Rete'
            '{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}' = 'Pannello di controllo'
        }

        $icons = [ordered]@{}
        foreach ($entry in $baseIcons.GetEnumerator()) { $icons[$entry.Key] = $entry.Value }
        if ($isProLike) {
            foreach ($entry in $proIcons.GetEnumerator()) { $icons[$entry.Key] = $entry.Value }
        }

        $desktopIconPaths = @(
            'Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel',
            'Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu'
        )

        foreach ($icon in $icons.GetEnumerator()) {
            if ($PSCmdlet.ShouldProcess('Desktop', "Mostrare icona $($icon.Value)")) {
                foreach ($desktopPath in $desktopIconPaths) {
                    Set-TDTUserDword -RelativePath $desktopPath -Name $icon.Key -Value 0 -AllUsers $allUsers
                }
            }
        }
    }
}
