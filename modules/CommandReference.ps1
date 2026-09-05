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

function Invoke-TDTReferenceCommand {
    param([Parameter(Mandatory)]$Item)
    if ($Item.Command -match '<[^>]+>') {
        Write-Warning 'Il comando contiene un segnaposto. Copialo e sostituisci il valore prima di eseguirlo.'
        return
    }
    if ($Item.Impact -ne 'BASSO') {
        Write-Warning ("Impatto dichiarato: {0}. {1}" -f $Item.Impact,$Item.NotFor)
    }
    if ($Item.Reboot) { Write-Warning 'Questa operazione puo richiedere un riavvio per avere effetto.' }
    $confirm = Read-Host ("Eseguire adesso '{0}'? [S/N]" -f $Item.Command)
    if ($confirm -notmatch '^[SsYy]') { return }
    Write-Host "`n--- OUTPUT COMANDO ---" -ForegroundColor Cyan
    try { Invoke-Expression $Item.Command }
    catch { Write-Warning $_.Exception.Message }
    Write-Host "--- FINE OUTPUT ---" -ForegroundColor Cyan
}

function Show-TDTCommandItemMenu {
    param([Parameter(Mandatory)]$Item)
    do {
        Show-TDTCommandCard -Item $Item
        Write-Host "`n [E] Esegui"
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
    if (-not $Items -or $Items.Count -eq 0) { Write-Warning 'Nessun comando trovato.'; [void](Read-Host 'INVIO per continuare'); return }
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
        } else { Write-Warning 'Scelta non valida.'; Start-Sleep -Milliseconds 600 }
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
        foreach ($token in $tokens) { if ($haystack.IndexOf($token) -lt 0) { $ok = $false; break } }
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
        for ($i=0; $i -lt $categories.Count; $i++) { Write-Host (" [{0}] {1}" -f ($i+1),$categories[$i]) }
        Write-Host "`n [C] Cerca comando / problema" -ForegroundColor Yellow
        Write-Host ' [0] Torna agli Strumenti Tecnico'
        $choice = Read-Host 'Scelta'
        if ($choice -eq '0') { return }
        if ($choice -match '^[Cc]$') { Search-TDTCommandCatalog -Catalog $catalog; continue }
        $n = 0
        if ([int]::TryParse($choice,[ref]$n) -and $n -ge 1 -and $n -le $categories.Count) {
            $category = $categories[$n-1]
            $items = @($catalog | Where-Object Category -eq $category)
            Select-TDTCommandFromList -Items $items -Title $category
        } else { Write-Warning 'Scelta non valida.'; Start-Sleep -Milliseconds 600 }
    } while ($true)
}
