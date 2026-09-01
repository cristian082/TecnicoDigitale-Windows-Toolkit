function Invoke-TDTSoftware {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param([Parameter(Mandatory)]$Config)

    Write-Host '[Software] Installazione software via winget'
    if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
        Write-Warning 'winget non disponibile. Modulo Software saltato.'
        return
    }

    foreach ($id in $Config.WingetPackages) {
        if ($PSCmdlet.ShouldProcess($id, 'Installare/aggiornare pacchetto winget')) {
            & winget install --id $id --exact --silent --accept-package-agreements --accept-source-agreements
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "winget ha restituito codice $LASTEXITCODE per $id"
            }
        }
    }
}
