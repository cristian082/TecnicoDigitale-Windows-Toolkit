function Get-TDTHibernationStatus {
    $systemDrive = $env:SystemDrive
    if ([string]::IsNullOrWhiteSpace($systemDrive)) {
        $systemDrive = 'C:'
    }

    $hiberFilePath = Join-Path ($systemDrive + '\') 'hiberfil.sys'
    $hiberFile = Get-Item -LiteralPath $hiberFilePath -Force -ErrorAction SilentlyContinue
    $drive = Get-CimInstance -ClassName Win32_LogicalDisk -Filter ("DeviceID='{0}'" -f $systemDrive) -ErrorAction SilentlyContinue

    [pscustomobject]@{
        Enabled       = ($null -ne $hiberFile)
        HiberFilePath = $hiberFilePath
        HiberFileGB   = if ($hiberFile) { [math]::Round($hiberFile.Length / 1GB, 2) } else { 0 }
        FreeSpaceGB   = if ($drive) { [math]::Round($drive.FreeSpace / 1GB, 2) } else { $null }
    }
}

function Write-TDTHibernationStatus {
    param([Parameter(Mandatory)]$Status)

    Write-Host "`nStato corrente:" -ForegroundColor Cyan
    if ($Status.Enabled) {
        Write-Host ' Ibernazione     : ATTIVA' -ForegroundColor Green
        Write-Host (" hiberfil.sys    : {0:N2} GB" -f $Status.HiberFileGB)
    }
    else {
        Write-Host ' Ibernazione     : DISATTIVATA' -ForegroundColor Yellow
        Write-Host ' hiberfil.sys    : non presente'
    }

    if ($null -ne $Status.FreeSpaceGB) {
        Write-Host (" Spazio libero   : {0:N2} GB su {1}" -f $Status.FreeSpaceGB, $env:SystemDrive)
    }
}

function Invoke-TDTHibernationChange {
    param([Parameter(Mandatory)][ValidateSet('On', 'Off')][string]$Mode)

    $statusBefore = Get-TDTHibernationStatus

    if ($Mode -eq 'Off') {
        if (-not $statusBefore.Enabled) {
            Write-Host 'L''ibernazione risulta gia disattivata.' -ForegroundColor Yellow
            return
        }

        Write-Warning 'La disattivazione elimina hiberfil.sys e rende non disponibili Ibernazione, Sospensione ibrida e Avvio rapido.'
        Write-Host 'La normale sospensione S3 resta disponibile solo se supportata dal PC.'
        Write-Host 'Conferma richiesta: scrivere DISATTIVA per continuare.' -ForegroundColor Yellow
        if ((Read-Host 'Conferma') -cne 'DISATTIVA') {
            Write-Host 'Operazione annullata.'
            return
        }

        $powerMode = 'off'
        $expectedEnabled = $false
    }
    else {
        if ($statusBefore.Enabled) {
            Write-Host 'L''ibernazione risulta gia attiva.' -ForegroundColor Green
            return
        }

        Write-Warning 'La riattivazione ricrea hiberfil.sys e puo occupare diversi GB sul disco di sistema.'
        Write-Host 'Riabilita anche le funzioni dipendenti supportate dal PC, come Avvio rapido e Sospensione ibrida.'
        Write-Host 'Conferma richiesta: scrivere ATTIVA per continuare.' -ForegroundColor Yellow
        if ((Read-Host 'Conferma') -cne 'ATTIVA') {
            Write-Host 'Operazione annullata.'
            return
        }

        $powerMode = 'on'
        $expectedEnabled = $true
    }

    $output = & "$env:SystemRoot\System32\powercfg.exe" /hibernate $powerMode 2>&1
    $exitCode = $LASTEXITCODE
    if ($output) {
        $output | ForEach-Object { Write-Host $_ }
    }
    if ($exitCode -ne 0) {
        throw "powercfg non ha completato l'operazione (codice $exitCode)."
    }

    $statusAfter = Get-TDTHibernationStatus
    if ($statusAfter.Enabled -ne $expectedEnabled) {
        throw 'Il comando e terminato, ma la verifica di hiberfil.sys non conferma il nuovo stato.'
    }

    Write-Host 'Operazione completata e verificata.' -ForegroundColor Green
    Write-TDTHibernationStatus -Status $statusAfter
}

function Show-TDTHibernationTools {
    do {
        Write-Host "`n=================================================="
        Write-Host ' IBERNAZIONE E HIBERFIL.SYS' -ForegroundColor Cyan
        Write-Host '=================================================='
        Write-TDTHibernationStatus -Status (Get-TDTHibernationStatus)
        Write-Host "`n [1] Mostra stati di sospensione supportati (read-only)"
        Write-Host ' [2] Disattiva ibernazione e rimuovi hiberfil.sys'
        Write-Host ' [3] Riattiva ibernazione'
        Write-Host ' [0] Torna agli Strumenti Tecnico'

        $choice = Read-Host 'Scelta'
        try {
            switch ($choice) {
                '1' {
                    & "$env:SystemRoot\System32\powercfg.exe" /a
                    if ($LASTEXITCODE -ne 0) {
                        throw "powercfg /a non e riuscito (codice $LASTEXITCODE)."
                    }
                    Wait-TDTMenu
                }
                '2' { Invoke-TDTHibernationChange -Mode Off; Wait-TDTMenu }
                '3' { Invoke-TDTHibernationChange -Mode On; Wait-TDTMenu }
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
