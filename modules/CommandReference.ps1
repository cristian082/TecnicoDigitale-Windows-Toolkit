function Get-TDTCommandCatalog {
    param([Parameter(Mandatory)][string]$Root)
    $path = Join-Path $Root 'data\TechnicianCommands.json'
    if (-not (Test-Path -LiteralPath $path)) { throw "Catalogo comandi non trovato: $path" }
    return @(Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json)
}

function Show-TDTCommandCard {
    param([Parameter(Mandatory)]$Item)
    Clear-Host
    Write-Host '========================================================' -ForegroundColor DarkGray
    Write-Host (" {0} - {1}" -f $Item.Id,$Item.Title) -ForegroundColor Cyan
    Write-Host '========================================================' -ForegroundColor DarkGray
    Write-Host ("Categoria : {0}" -f $Item.Category)
    Write-Host ("Impatto   : {0}" -f $Item.Impact)
    Write-Host ("Admin     : {0}" -f $(if($Item.Admin){'SI'}else{'NO'}))
    Write-Host ("Riavvio   : {0}" -f $(if($Item.Reboot){'SI'}else{'NO'}))
    Write-Host "`nComando:" -ForegroundColor Yellow
    Write-Host $Item.Command -ForegroundColor White
    Write-Host "`nServe per:" -ForegroundColor Green
    Write-Host $Item.Purpose
    Write-Host "`nNon serve / attenzione:" -ForegroundColor Yellow
    Write-Host $Item.NotFor
}

function Copy-TDTCommandToClipboard {
    param([Parameter(Mandatory)][string]$Command)
    try {
        Set-Clipboard -Value $Command -ErrorAction Stop
        Write-Host 'Comando copiato negli appunti.' -ForegroundColor Green
    }
    catch { Write-Warning "Impossibile copiare negli appunti: $($_.Exception.Message)" }
}

function Test-TDTReferenceCommandExecutable {
    param([Parameter(Mandatory)][string]$Id)
    # Only IDs explicitly handled by Invoke-TDTReferenceCommandControlled may run.
    # The text stored in JSON is never evaluated as PowerShell code.
    return $Id -in @(
        'WIN-001','WIN-002','WIN-003','WIN-004','WIN-005',
        'NET-001','NET-002','NET-003','NET-004','NET-005','NET-006','NET-007','NET-008','NET-009','NET-010','NET-011','NET-012',
        'PRN-001','PRN-002','PRN-003',
        'DSK-001','DSK-002','DSK-003',
        'DRV-001','DRV-002','DRV-003',
        'USR-001','USR-002','SVC-001',
        'WU-001','WU-002','BOOT-001','BOOT-002',
        'SHR-001','SHR-002','SHR-003',
        'PWR-001','PWR-002','APP-001','APP-004'
    )
}

function Invoke-TDTReferenceCommandControlled {
    param([Parameter(Mandatory)][string]$Id)

    switch ($Id) {
        'WIN-001' { & dism.exe /Online /Cleanup-Image /CheckHealth }
        'WIN-002' { & dism.exe /Online /Cleanup-Image /ScanHealth }
        'WIN-003' { & dism.exe /Online /Cleanup-Image /RestoreHealth }
        'WIN-004' { & sfc.exe /scannow }
        'WIN-005' { Start-Process winver.exe }

        'NET-001' { & ipconfig.exe /all }
        'NET-002' { & ipconfig.exe /flushdns }
        'NET-003' { & ipconfig.exe /release }
        'NET-004' { & ipconfig.exe /renew }
        'NET-005' { & netsh.exe winsock reset }
        'NET-006' { & netsh.exe int ip reset }
        'NET-007' { & arp.exe -a }
        'NET-008' { & route.exe print }
        'NET-009' { & netstat.exe -ano }
        'NET-010' { & tracert.exe 1.1.1.1 }
        'NET-011' { & netsh.exe winhttp show proxy }
        'NET-012' { & netsh.exe wlan show profiles }

        'PRN-001' { Start-Process control.exe -ArgumentList 'printers' }
        'PRN-002' { Start-Process printmanagement.msc }
        'PRN-003' { & sc.exe query spooler }

        'DSK-001' { & chkdsk.exe C: /scan }
        'DSK-002' { Start-Process diskmgmt.msc }
        'DSK-003' { Get-Disk | Format-Table Number,FriendlyName,BusType,HealthStatus,OperationalStatus,PartitionStyle,Size -AutoSize | Out-Host }

        'DRV-001' { Start-Process devmgmt.msc }
        'DRV-002' { Get-PnpDevice | Where-Object Status -ne 'OK' | Format-Table Status,Class,FriendlyName,InstanceId -AutoSize | Out-Host }
        'DRV-003' { & pnputil.exe /scan-devices }

        'USR-001' { & net.exe user }
        'USR-002' { Start-Process lusrmgr.msc }
        'SVC-001' { Start-Process services.msc }

        'WU-001' { Start-Process 'ms-settings:windowsupdate' }
        'WU-002' { Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 20 | Format-Table -AutoSize | Out-Host }
        'BOOT-001' { & bcdedit.exe /enum }
        'BOOT-002' { Start-Process msconfig.exe }

        'SHR-001' { & net.exe share }
        'SHR-002' { & net.exe use }
        'SHR-003' { Start-Process mstsc.exe }

        'PWR-001' { & powercfg.exe /batteryreport }
        'PWR-002' { & powercfg.exe /a }
        'APP-001' { & winget.exe list }
        'APP-004' { Start-Process explorer.exe -ArgumentList 'shell:AppsFolder' }

        default { throw "Il comando $Id non e abilitato per l'esecuzione diretta. Usa Copia comando." }
    }
}

function Invoke-TDTReferenceCommand {
    param([Parameter(Mandatory)]$Item)

    if ($Item.Command -match '<[^>]+>') {
        Write-Warning 'Il comando contiene un segnaposto. Copialo e sostituisci il valore prima di eseguirlo.'
        return
    }
    if (-not (Test-TDTReferenceCommandExecutable -Id $Item.Id)) {
        Write-Warning 'Questo comando e disponibile come riferimento/copia ma non e abilitato per l esecuzione diretta.'
        return
    }
    if ($Item.Impact -ne 'BASSO') {
        Write-Warning ("Impatto dichiarato: {0}. {1}" -f $Item.Impact,$Item.NotFor)
    }
    if ($Item.Reboot) {
        Write-Warning 'Questa operazione puo richiedere un riavvio per avere effetto.'
    }

    $confirm = Read-Host ("Eseguire adesso '{0}'? [S/N]" -f $Item.Command)
    if ($confirm -notmatch '^[SsYy]') { return }

    Write-Host "`n--- OUTPUT COMANDO ---" -ForegroundColor Cyan
    try { Invoke-TDTReferenceCommandControlled -Id $Item.Id }
    catch { Write-Warning $_.Exception.Message }
    Write-Host '--- FINE OUTPUT ---' -ForegroundColor Cyan
}

function Show-TDTCommandItemMenu {
    param([Parameter(Mandatory)]$Item)
    do {
        Show-TDTCommandCard -Item $Item
        if (Test-TDTReferenceCommandExecutable -Id $Item.Id) {
            Write-Host "`n [E] Esegui (dispatcher controllato)"
        }
        else {
            Write-Host "`n [E] Esecuzione diretta non disponibile" -ForegroundColor DarkGray
        }
        Write-Host ' [C] Copia comando'
        Write-Host ' [0] Indietro'
        $choice = Read-Host 'Scelta'
        switch ($choice.ToUpperInvariant()) {
            'E' { Invoke-TDTReferenceCommand -Item $Item; [void](Read-Host 'INVIO per continuare') }
            'C' { Copy-TDTCommandToClipboard -Command $Item.Command; [void](Read-Host 'INVIO per continuare') }
            '0' { return }
            default { Write-Warning 'Scelta non valida.'; Start-Sleep -Milliseconds 600 }
        }
    } while ($true)
}

function Select-TDTCommandFromList {
    param([Parameter(Mandatory)][array]$Items,[Parameter(Mandatory)][string]$Title)
    if (-not $Items -or $Items.Count -eq 0) {
        Write-Warning 'Nessun comando trovato.'
        [void](Read-Host 'INVIO per continuare')
        return
    }
    do {
        Clear-Host
        Write-Host "`n$Title" -ForegroundColor Cyan
        Write-Host ('-' * [Math]::Min(70,[Math]::Max(20,$Title.Length))) -ForegroundColor DarkGray
        for ($i=0; $i -lt $Items.Count; $i++) {
            Write-Host (" [{0}] {1,-10} {2}" -f ($i+1),$Items[$i].Id,$Items[$i].Title)
        }
        Write-Host ' [0] Indietro'
        $raw = Read-Host 'Scelta'
        if ($raw -eq '0') { return }
        $n = 0
        if ([int]::TryParse($raw,[ref]$n) -and $n -ge 1 -and $n -le $Items.Count) {
            Show-TDTCommandItemMenu -Item $Items[$n-1]
        }
        else { Write-Warning 'Scelta non valida.'; Start-Sleep -Milliseconds 600 }
    } while ($true)
}

function Search-TDTCommandCatalog {
    param([Parameter(Mandatory)][array]$Catalog)
    $query = Read-Host 'Cerca comando/problema (es. stampante, wifi, boot, disco)'
    if (-not $query) { return }
    $tokens = @($query.ToLowerInvariant().Split(' ',[StringSplitOptions]::RemoveEmptyEntries))
    $matches = @($Catalog | Where-Object {
        $haystack = ("{0} {1} {2} {3} {4} {5}" -f $_.Id,$_.Category,$_.Title,$_.Purpose,$_.NotFor,$_.Keywords).ToLowerInvariant()
        $ok = $true
        foreach ($token in $tokens) {
            if ($haystack.IndexOf($token) -lt 0) { $ok = $false; break }
        }
        $ok
    })
    Select-TDTCommandFromList -Items $matches -Title ("RISULTATI: {0}" -f $query)
}

function Show-TDTCommandReference {
    param([Parameter(Mandatory)][string]$Root)
    $catalog = Get-TDTCommandCatalog -Root $Root
    $categories = @($catalog.Category | Sort-Object -Unique)
    do {
        Clear-Host
        Write-Host '========================================================'
        Write-Host ' TECNICO DIGITALE - COMANDI DEL TECNICO' -ForegroundColor Cyan
        Write-Host '========================================================'
        Write-Host (" Catalogo offline: {0} comandi" -f $catalog.Count) -ForegroundColor DarkGray
        Write-Host ' Esecuzione: solo dispatcher controllato; nessun Invoke-Expression.' -ForegroundColor DarkGray
        for ($i=0; $i -lt $categories.Count; $i++) {
            Write-Host (" [{0}] {1}" -f ($i+1),$categories[$i])
        }
        Write-Host "`n [C] Cerca comando / problema" -ForegroundColor Yellow
        Write-Host ' [0] Torna agli Strumenti Tecnico'
        $choice = Read-Host 'Scelta'
        if ($choice -eq '0') { return }
        if ($choice -match '^[Cc]$') {
            Search-TDTCommandCatalog -Catalog $catalog
            continue
        }
        $n = 0
        if ([int]::TryParse($choice,[ref]$n) -and $n -ge 1 -and $n -le $categories.Count) {
            $category = $categories[$n-1]
            $items = @($catalog | Where-Object Category -eq $category)
            Select-TDTCommandFromList -Items $items -Title $category
        }
        else { Write-Warning 'Scelta non valida.'; Start-Sleep -Milliseconds 600 }
    } while ($true)
}
