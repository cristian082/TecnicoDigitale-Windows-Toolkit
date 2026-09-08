function Get-TDTPrinterSelection {
    $printers = @(Get-CimInstance -ClassName Win32_Printer -ErrorAction SilentlyContinue | Sort-Object Name)
    if (-not $printers) {
        Write-Warning 'Nessuna stampante rilevata.'
        return $null
    }

    for ($i = 0; $i -lt $printers.Count; $i++) {
        $default = if ($printers[$i].Default) { ' [PREDEFINITA]' } else { '' }
        Write-Host (" [{0}] {1}{2}" -f ($i + 1), $printers[$i].Name, $default)
    }

    $raw = Read-Host 'Seleziona stampante (INVIO annulla)'
    if (-not $raw) { return $null }

    $number = 0
    if (-not [int]::TryParse($raw, [ref]$number) -or $number -lt 1 -or $number -gt $printers.Count) {
        Write-Warning 'Scelta non valida.'
        return $null
    }

    return $printers[$number - 1]
}

function Get-TDTPrintJobs {
    Write-Host "`n[STAMPA] Documenti nelle code - sola lettura" -ForegroundColor Cyan
    $printers = @(Get-Printer -ErrorAction SilentlyContinue | Sort-Object Name)
    if (-not $printers) {
        Write-Warning 'Nessuna stampante rilevata.'
        return
    }

    $jobs = foreach ($printer in $printers) {
        Get-PrintJob -PrinterName $printer.Name -ErrorAction SilentlyContinue | Select-Object @{N='Stampante';E={$printer.Name}},Id,DocumentName,JobStatus,SubmittedTime,UserName,Size
    }

    if ($jobs) {
        $jobs | Format-Table -Wrap -AutoSize | Out-Host
    }
    else {
        Write-Host 'Nessun documento presente nelle code di stampa.' -ForegroundColor Green
    }
}

function Invoke-TDTPrinterTestPage {
    Write-Host "`n[STAMPA] Pagina di prova" -ForegroundColor Cyan
    $printer = Get-TDTPrinterSelection
    if (-not $printer) { return }

    if (-not (Confirm-TDTAction ("Inviare una pagina di prova a '{0}'? Consumera carta e inchiostro/toner." -f $printer.Name))) {
        return
    }

    $result = Invoke-CimMethod -InputObject $printer -MethodName PrintTestPage -ErrorAction Stop
    if ($result.ReturnValue -eq 0) {
        Write-Host 'Pagina di prova inviata alla coda di stampa.' -ForegroundColor Green
    }
    else {
        throw "La stampante non ha accettato la pagina di prova (codice $($result.ReturnValue))."
    }
}

function Reset-TDTPrintSpooler {
    Write-Host "`n[STAMPA] Reset controllato Spooler e coda" -ForegroundColor Cyan
    Get-TDTPrintJobs
    Write-Warning 'Questa operazione arresta temporaneamente lo Spooler ed elimina tutti i documenti in coda per tutte le stampanti.'
    if (-not (Confirm-TDTAction 'Procedere con la pulizia completa della coda di stampa?')) { return }

    $spooler = Get-Service -Name Spooler -ErrorAction Stop
    $wasRunning = ($spooler.Status -ne 'Stopped')
    try {
        if ($wasRunning) {
            try {
                Stop-Service -Name Spooler -ErrorAction Stop
                $spooler.WaitForStatus('Stopped', [TimeSpan]::FromSeconds(15))
            }
            catch {
                Write-Warning ("Arresto normale dello Spooler non riuscito: {0}" -f $_.Exception.Message)
                $spooler = Get-Service -Name Spooler -ErrorAction Stop
                if ($spooler.Status -ne 'Stopped') {
                    if (-not (Confirm-TDTAction 'Tentare l arresto forzato dello Spooler e dei servizi dipendenti?')) {
                        Write-Host 'Pulizia della coda annullata; nessun file e stato eliminato.' -ForegroundColor Yellow
                        return
                    }
                    Stop-Service -Name Spooler -Force -ErrorAction Stop
                    $spooler.WaitForStatus('Stopped', [TimeSpan]::FromSeconds(15))
                }
            }
        }

        $spooler = Get-Service -Name Spooler -ErrorAction Stop
        if ($spooler.Status -ne 'Stopped') {
            throw 'Lo Spooler non risulta arrestato: i file di coda non verranno eliminati.'
        }

        $queue = Join-Path $env:SystemRoot 'System32\spool\PRINTERS'
        $queuedFiles = @(Get-ChildItem -LiteralPath $queue -Force -File -ErrorAction SilentlyContinue)
        if ($queuedFiles) {
            $queuedFiles | Remove-Item -Force -ErrorAction Stop
            Write-Host ("File di coda rimossi: {0}" -f $queuedFiles.Count)
        }
        else {
            Write-Host 'Nessun file di coda da rimuovere.'
        }
    }
    finally {
        if ($wasRunning -and (Get-Service -Name Spooler -ErrorAction SilentlyContinue).Status -ne 'Running') {
            Start-Service -Name Spooler -ErrorAction Stop
        }
    }

    $spooler = Get-Service -Name Spooler -ErrorAction Stop
    if ($wasRunning) {
        $spooler.WaitForStatus('Running', [TimeSpan]::FromSeconds(15))
        Write-Host 'Spooler riavviato e stato verificato: Running.' -ForegroundColor Green
    }
    else {
        Write-Host 'Coda pulita; lo Spooler era gia arrestato e non e stato avviato dal Toolkit.' -ForegroundColor Green
    }
}

function Show-TDTPrinterTools {
    do {
        Write-Host "`n=================================================="
        Write-Host ' STRUMENTI STAMPANTI' -ForegroundColor Cyan
        Write-Host '=================================================='
        Write-Host ' [1] Diagnostica stampanti, driver, porte e Spooler'
        Write-Host ' [2] Mostra documenti nelle code (read-only)'
        Write-Host ' [3] Stampa pagina di prova'
        Write-Host ' [4] Apri Impostazioni Stampanti e scanner'
        Write-Host ' [5] Apri Dispositivi e stampanti classico'
        Write-Host ' [6] Apri Gestione stampa avanzata'
        Write-Host ' [7] Reset controllato Spooler e coda'
        Write-Host ' [0] Torna agli Strumenti Tecnico'

        $choice = Read-Host 'Scelta'
        try {
            switch ($choice) {
                '1' { Get-TDTPrinterStatus; Wait-TDTMenu }
                '2' { Get-TDTPrintJobs; Wait-TDTMenu }
                '3' { Invoke-TDTPrinterTestPage; Wait-TDTMenu }
                '4' { Start-Process 'ms-settings:printers' }
                '5' { Start-Process control.exe -ArgumentList 'printers' }
                '6' { Start-Process printmanagement.msc -ErrorAction Stop }
                '7' { Reset-TDTPrintSpooler; Wait-TDTMenu }
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
