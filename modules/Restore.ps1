function Invoke-TDTRestore {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param([Parameter(Mandatory)]$Config)

    Write-Host '[Restore] Verifica protezione sistema e creazione punto di ripristino'
    if (-not $Config.CreateRestorePoint) { return }

    if ($PSCmdlet.ShouldProcess('C:', 'Creare punto di ripristino')) {
        try {
            Enable-ComputerRestore -Drive 'C:\' -ErrorAction Stop
        } catch {
            Write-Warning "Impossibile abilitare Protezione sistema: $($_.Exception.Message)"
        }

        try {
            Checkpoint-Computer -Description 'TecnicoDigitale Windows Toolkit' -RestorePointType 'MODIFY_SETTINGS'
        } catch {
            Write-Warning "Punto di ripristino non creato: $($_.Exception.Message)"
        }
    }
}
