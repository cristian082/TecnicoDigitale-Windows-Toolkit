function Invoke-TDTRestore {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param([Parameter(Mandatory)]$Config)

    Write-Host '[Restore] Verifica protezione sistema'
    if (-not $Config.CreateRestorePoint) { return }

    try {
        Enable-ComputerRestore -Drive 'C:\' -ErrorAction Stop
    }
    catch {
        throw "Impossibile abilitare Protezione sistema: $($_.Exception.Message)"
    }

    if (-not $WhatIfPreference) {
        $lastRestore = Get-ComputerRestorePoint -ErrorAction SilentlyContinue |
            Sort-Object CreationTime -Descending |
            Select-Object -First 1

        Write-Host ''
        if ($lastRestore) {
            try {
                $lastDate = [Management.ManagementDateTimeConverter]::ToDateTime($lastRestore.CreationTime)
                Write-Host ("Ultimo punto di ripristino: {0:dd/MM/yyyy HH:mm} - {1}" -f $lastDate, $lastRestore.Description)
            }
            catch {
                Write-Host "Ultimo punto di ripristino presente: $($lastRestore.Description)"
            }
        }
        else {
            Write-Host 'Nessun punto di ripristino esistente rilevato.'
        }

        Write-Host ''
        Write-Host 'Creare un nuovo punto di ripristino prima di procedere?'
        Write-Host '  [1] SI - Crea un nuovo punto di ripristino'
        Write-Host '  [2] NO - Continua senza crearne uno'
        Write-Host '  [3] ANNULLA - Interrompi il toolkit'
        Write-Host ''

        do {
            $choice = Read-Host 'Scelta'
        } until ($choice -in @('1','2','3'))

        if ($choice -eq '2') {
            Write-Host '[Restore] Creazione punto di ripristino saltata su richiesta.' -ForegroundColor Yellow
            return
        }
        if ($choice -eq '3') {
            throw 'Operazione annullata dall utente prima di applicare modifiche.'
        }
    }

    if (-not $PSCmdlet.ShouldProcess('C:', 'Creare punto di ripristino')) { return }

    $restoreKey = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore'
    $valueName = 'SystemRestorePointCreationFrequency'
    $hadValue = $false
    $oldValue = $null

    try {
        if (-not (Test-Path $restoreKey)) {
            New-Item -Path $restoreKey -Force -ErrorAction Stop | Out-Null
        }

        $existing = Get-ItemProperty -Path $restoreKey -Name $valueName -ErrorAction SilentlyContinue
        if ($null -ne $existing) {
            $hadValue = $true
            $oldValue = $existing.$valueName
        }

        # Consente la creazione esplicita anche se esiste un punto creato recentemente.
        New-ItemProperty -Path $restoreKey -Name $valueName -PropertyType DWord -Value 0 -Force -ErrorAction Stop | Out-Null

        Checkpoint-Computer -Description 'TecnicoDigitale Windows Toolkit' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop
        Write-Host '[Restore] Punto di ripristino creato.' -ForegroundColor Green
    }
    catch {
        throw "Punto di ripristino non creato. Il toolkit viene interrotto per sicurezza: $($_.Exception.Message)"
    }
    finally {
        try {
            if ($hadValue) {
                New-ItemProperty -Path $restoreKey -Name $valueName -PropertyType DWord -Value ([int]$oldValue) -Force -ErrorAction Stop | Out-Null
            }
            else {
                Remove-ItemProperty -Path $restoreKey -Name $valueName -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Warning "Impossibile ripristinare $valueName al valore precedente: $($_.Exception.Message)"
        }
    }
}
