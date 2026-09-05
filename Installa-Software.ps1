Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $Root 'modules\Software.ps1')

function Test-Administrator {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($id)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    throw 'Eseguire Installa-Software.ps1 come amministratore.'
}

$catalog = @(
    [pscustomobject]@{ Key='1'; Name='Google Chrome';       Id='Google.Chrome';                    Selected=$false },
    [pscustomobject]@{ Key='2'; Name='Mozilla Firefox';     Id='Mozilla.Firefox';                  Selected=$false },
    [pscustomobject]@{ Key='3'; Name='VLC media player';    Id='VideoLAN.VLC';                     Selected=$false },
    [pscustomobject]@{ Key='4'; Name='WinRAR';              Id='RARLab.WinRAR';                    Selected=$false },
    [pscustomobject]@{ Key='5'; Name='7-Zip';               Id='7zip.7zip';                        Selected=$false },
    [pscustomobject]@{ Key='6'; Name='Everything';          Id='voidtools.Everything';             Selected=$false },
    [pscustomobject]@{ Key='7'; Name='Adobe Acrobat Reader';Id='Adobe.Acrobat.Reader.64-bit';      Selected=$false },
    [pscustomobject]@{ Key='8'; Name='SumatraPDF';          Id='SumatraPDF.SumatraPDF';            Selected=$false },
    [pscustomobject]@{ Key='9'; Name='Steam';               Id='Valve.Steam';                      Selected=$false },
    [pscustomobject]@{ Key='10';Name='Playnite';            Id='Playnite.Playnite';                Selected=$false }
)

function Set-TDTSelection {
    param([string[]]$Ids)
    foreach ($item in $catalog) { $item.Selected = ($item.Id -in $Ids) }
}

function Show-TDTSoftwareMenu {
    while ($true) {
        Clear-Host
        Write-Host '==============================================================' -ForegroundColor Cyan
        Write-Host '       TECNICO DIGITALE - INSTALLAZIONE SOFTWARE' -ForegroundColor Cyan
        Write-Host '==============================================================' -ForegroundColor Cyan
        Write-Host ''
        Write-Host 'Seleziona solo il software che vuoi installare/aggiornare.'
        Write-Host 'I preset Standard/Gaming/Business NON installano piu software.' -ForegroundColor DarkGray
        Write-Host ''

        foreach ($item in $catalog) {
            $mark = if ($item.Selected) { 'X' } else { ' ' }
            Write-Host ('[{0}] [{1}] {2}' -f $item.Key, $mark, $item.Name)
        }

        Write-Host ''
        Write-Host '[N] Pacchetto PC NUOVO  (Chrome, VLC, WinRAR, Everything, Acrobat Reader)'
        Write-Host '[G] Pacchetto GAMING    (Chrome, VLC, 7-Zip, Steam, Playnite)'
        Write-Host '[C] Cancella selezione'
        Write-Host '[A] Installa selezionati'
        Write-Host '[0] Torna al menu principale'
        Write-Host ''

        $choice = (Read-Host 'Scelta').Trim()

        if ($choice -eq '0') { return }
        if ($choice -match '^(?i)C$') {
            Set-TDTSelection -Ids @()
            continue
        }
        if ($choice -match '^(?i)N$') {
            Set-TDTSelection -Ids @('Google.Chrome','VideoLAN.VLC','RARLab.WinRAR','voidtools.Everything','Adobe.Acrobat.Reader.64-bit')
            continue
        }
        if ($choice -match '^(?i)G$') {
            Set-TDTSelection -Ids @('Google.Chrome','VideoLAN.VLC','7zip.7zip','Valve.Steam','Playnite.Playnite')
            continue
        }
        if ($choice -match '^(?i)A$') {
            $selected = @($catalog | Where-Object Selected)
            if ($selected.Count -eq 0) {
                Write-Host ''
                Write-Warning 'Nessun software selezionato.'
                Start-Sleep -Seconds 2
                continue
            }

            Clear-Host
            Write-Host 'Software selezionato:' -ForegroundColor Cyan
            foreach ($item in $selected) { Write-Host (' - ' + $item.Name) }
            Write-Host ''
            $confirm = Read-Host 'Procedere? [S/N]'
            if ($confirm -notmatch '^(?i)S$') { continue }

            $config = [pscustomobject]@{ WingetPackages = @($selected.Id) }
            Invoke-TDTSoftware -Config $config
            Write-Host ''
            Write-Host 'Operazione software terminata. Premi INVIO per tornare al menu.' -ForegroundColor Green
            [void](Read-Host)
            continue
        }

        $itemToToggle = $catalog | Where-Object Key -eq $choice | Select-Object -First 1
        if ($itemToToggle) {
            $itemToToggle.Selected = -not $itemToToggle.Selected
            continue
        }

        Write-Warning 'Scelta non valida.'
        Start-Sleep -Seconds 1
    }
}

Show-TDTSoftwareMenu
