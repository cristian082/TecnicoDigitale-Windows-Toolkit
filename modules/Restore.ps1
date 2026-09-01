function Invoke-TDTRestore {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param([Parameter(Mandatory)]$Config)

    Write-Host '[Restore] Verifica protezione sistema e creazione punto di ripristino'
    if (-not $Config.CreateRestorePoint) { return }

    if (-not $PSCmdlet.ShouldProcess('C:', 'Creare punto di ripristino')) { return }

    try {
        Enable-ComputerRestore -Drive 'C:\' -ErrorAction Stop
    }
    catch {
        throw "Impossibile abilitare Protezione sistema: $($_.Exception.Message)"
    }

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

        # 0 disabilita temporaneamente il limite temporale tra due punti creati da Checkpoint-Computer.
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
