function Get-TDTNotepadStatePath {
    Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsNotepad_8wekyb3d8bbwe\LocalState'
}

function Get-TDTNotepadSessionStatus {
    $localState = Get-TDTNotepadStatePath
    Write-Host "`n[BLOCCO NOTE] Stato sessione" -ForegroundColor Cyan
    Write-Host ("Utente       : {0}" -f $env:USERNAME)
    Write-Host ("Cartella     : {0}" -f $localState)

    if (-not (Test-Path -LiteralPath $localState -PathType Container)) {
        Write-Warning 'Cartella del Blocco note moderno non trovata per l utente corrente.'
        return
    }

    foreach ($name in @('TabState','WindowState')) {
        $path = Join-Path $localState $name
        if (Test-Path -LiteralPath $path) {
            $item = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
            Write-Host ("{0,-12}: presente - ultima modifica {1}" -f $name,$item.LastWriteTime)
        }
        else {
            Write-Host ("{0,-12}: non presente" -f $name)
        }
    }

    $preserved = @(Get-ChildItem -LiteralPath $localState -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^(TabState|WindowState)\.TDT-(backup|before-restore)-\d{8}-\d{6}$' })
    Write-Host ("Stati TDT    : {0} elementi conservati" -f $preserved.Count)
}

function Stop-TDTNotepadSafely {
    $processes = @(Get-Process -Name Notepad -ErrorAction SilentlyContinue)
    if (-not $processes) { return $true }

    Write-Warning 'Blocco note e ancora aperto. Salvare i documenti importanti e chiuderlo normalmente.'
    if ((Read-Host 'Dopo aver provato a chiuderlo, scrivere CONTROLLA') -cne 'CONTROLLA') {
        Write-Host 'Operazione annullata.'
        return $false
    }

    $processes = @(Get-Process -Name Notepad -ErrorAction SilentlyContinue)
    if (-not $processes) { return $true }

    Write-Warning 'Blocco note non si e chiuso. La chiusura forzata puo perdere modifiche non ancora registrate nella sessione.'
    if ((Read-Host 'Scrivere FORZA per terminare Blocco note') -cne 'FORZA') {
        Write-Host 'Operazione annullata.'
        return $false
    }

    Stop-Process -Name Notepad -Force -ErrorAction Stop
    Start-Sleep -Milliseconds 500
    return -not [bool](Get-Process -Name Notepad -ErrorAction SilentlyContinue)
}

function Reset-TDTNotepadSession {
    $localState = Get-TDTNotepadStatePath
    if (-not (Test-Path -LiteralPath $localState -PathType Container)) {
        Write-Warning 'Cartella del Blocco note moderno non trovata per l utente corrente.'
        return
    }

    $present = @('TabState','WindowState') | Where-Object {
        Test-Path -LiteralPath (Join-Path $localState $_)
    }
    if (-not $present) {
        Write-Host 'Nessuno stato di sessione attivo da ripristinare.' -ForegroundColor Green
        return
    }

    Write-Warning 'TabState puo contenere appunti mai salvati. Il Toolkit non li cancellera: rinominera lo stato per permettere il ripristino.'
    if ((Read-Host 'Scrivere PULISCI per avviare Blocco note con una sessione nuova') -cne 'PULISCI') {
        Write-Host 'Operazione annullata.'
        return
    }
    if (-not (Stop-TDTNotepadSafely)) { return }

    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    foreach ($name in $present) {
        Rename-Item -LiteralPath (Join-Path $localState $name) -NewName ("{0}.TDT-backup-{1}" -f $name,$stamp) -ErrorAction Stop
    }

    Write-Host 'Sessione precedente conservata tramite rinomina.' -ForegroundColor Green
    Write-Host 'Riaprire Blocco note: dovrebbe partire senza le vecchie schede.' -ForegroundColor Green
    Write-Host ("Identificativo backup: {0}" -f $stamp) -ForegroundColor Cyan
}

function Restore-TDTNotepadSession {
    $localState = Get-TDTNotepadStatePath
    if (-not (Test-Path -LiteralPath $localState -PathType Container)) {
        Write-Warning 'Cartella del Blocco note moderno non trovata per l utente corrente.'
        return
    }

    $backupStamps = @(Get-ChildItem -LiteralPath $localState -Force -ErrorAction SilentlyContinue |
        ForEach-Object {
            if ($_.Name -match '^(TabState|WindowState)\.TDT-backup-(\d{8}-\d{6})$') {
                $Matches[2]
            }
        } | Sort-Object -Unique -Descending)
    if (-not $backupStamps) {
        Write-Warning 'Nessun backup di sessione creato dal Toolkit trovato.'
        return
    }

    $stamp = $backupStamps[0]
    Write-Host ("Ultimo backup: {0}" -f $stamp) -ForegroundColor Cyan
    Write-Warning 'Il Toolkit ripristinera l ultima sessione salvata. L eventuale stato attuale verra a sua volta rinominato, non cancellato.'
    if ((Read-Host 'Scrivere RIPRISTINA per continuare') -cne 'RIPRISTINA') {
        Write-Host 'Operazione annullata.'
        return
    }
    if (-not (Stop-TDTNotepadSafely)) { return }

    $restoreStamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    foreach ($name in @('TabState','WindowState')) {
        $current = Join-Path $localState $name
        $backup = Join-Path $localState ("{0}.TDT-backup-{1}" -f $name,$stamp)
        if (Test-Path -LiteralPath $current) {
            Rename-Item -LiteralPath $current -NewName ("{0}.TDT-before-restore-{1}" -f $name,$restoreStamp) -ErrorAction Stop
        }
        if (Test-Path -LiteralPath $backup) {
            Rename-Item -LiteralPath $backup -NewName $name -ErrorAction Stop
        }
    }

    Write-Host 'Sessione ripristinata. Riaprire Blocco note per verificarla.' -ForegroundColor Green
}

function Open-TDTNotepadStateFolder {
    $localState = Get-TDTNotepadStatePath
    if (-not (Test-Path -LiteralPath $localState -PathType Container)) {
        Write-Warning 'Cartella del Blocco note moderno non trovata per l utente corrente.'
        return
    }
    Start-Process -FilePath "$env:SystemRoot\explorer.exe" -ArgumentList $localState
}

function Show-TDTNotepadSessionTools {
    do {
        Write-Host "`n=================================================="
        Write-Host ' RIPRISTINO SESSIONE BLOCCO NOTE' -ForegroundColor Cyan
        Write-Host '=================================================='
        Write-Host ' [1] Mostra stato sessione (read-only)'
        Write-Host ' [2] Avvia con sessione pulita (conserva backup)'
        Write-Host ' [3] Ripristina ultima sessione conservata'
        Write-Host ' [4] Apri cartella LocalState'
        Write-Host ' [0] Torna agli Strumenti Tecnico'

        $choice = Read-Host 'Scelta'
        try {
            switch ($choice) {
                '1' { Get-TDTNotepadSessionStatus; Wait-TDTMenu }
                '2' { Reset-TDTNotepadSession; Wait-TDTMenu }
                '3' { Restore-TDTNotepadSession; Wait-TDTMenu }
                '4' { Open-TDTNotepadStateFolder; Wait-TDTMenu }
                '0' { return }
                default { Write-Warning 'Scelta non valida.' }
            }
        }
        catch {
            Write-Warning $_.Exception.Message
            Wait-TDTMenu
        }
    } while ($true)
}
