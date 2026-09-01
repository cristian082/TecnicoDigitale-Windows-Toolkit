function Invoke-TDTSoftware {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param([Parameter(Mandatory)]$Config)

    Write-Host '[Software] Installazione software via winget'
    if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
        Write-Warning 'winget non disponibile. Modulo Software saltato.'
        return
    }

    # Aggiorna i metadati delle sorgenti una sola volta prima di lavorare sui pacchetti.
    & winget source update --accept-source-agreements 2>$null | Out-Null

    foreach ($id in $Config.WingetPackages) {
        if (-not $PSCmdlet.ShouldProcess($id, 'Installare o aggiornare pacchetto winget')) { continue }

        $listOutput = & winget list --id $id --exact --accept-source-agreements 2>$null | Out-String
        $isInstalled = ($LASTEXITCODE -eq 0 -and $listOutput -match [regex]::Escape($id))

        if ($isInstalled) {
            Write-Host "[Software] $id gia installato. Verifica aggiornamenti..."
            & winget upgrade --id $id --exact --silent --accept-package-agreements --accept-source-agreements
            $code = $LASTEXITCODE

            # Winget usa anche codici non zero per indicare che non esiste alcun aggiornamento.
            if ($code -eq 0) {
                Write-Host "[Software] $id aggiornato o gia alla versione piu recente."
            }
            else {
                $verifyOutput = & winget list --id $id --exact --accept-source-agreements 2>$null | Out-String
                if ($verifyOutput -match [regex]::Escape($id)) {
                    Write-Host "[Software] $id presente; nessun intervento necessario."
                }
                else {
                    Write-Warning "Impossibile verificare/aggiornare $id (codice winget $code)."
                }
            }
            continue
        }

        Write-Host "[Software] Installazione $id..."
        & winget install --id $id --exact --silent --accept-package-agreements --accept-source-agreements
        $code = $LASTEXITCODE

        if ($code -ne 0) {
            # Un hash mismatch puo dipendere da un manifest/sorgente appena cambiato: aggiorna e ritenta una volta.
            Write-Warning "Prima installazione di $id non riuscita (codice $code). Aggiorno le sorgenti e ritento una volta."
            & winget source update --accept-source-agreements 2>$null | Out-Null
            & winget install --id $id --exact --silent --accept-package-agreements --accept-source-agreements
            $code = $LASTEXITCODE
        }

        if ($code -eq 0) {
            Write-Host "[Software] $id installato correttamente."
        }
        else {
            Write-Warning "Installazione di $id non riuscita dopo il secondo tentativo (codice winget $code)."
        }
    }
}
