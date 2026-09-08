function Get-TDTWiFiProfiles {
    param([switch]$IncludeKeys)

    $temporaryPath = Join-Path ([IO.Path]::GetTempPath()) ("TDT-WiFi-{0}" -f [Guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $temporaryPath -Force -ErrorAction Stop)

    try {
        $arguments = @('wlan', 'export', 'profile', ("folder={0}" -f $temporaryPath))
        if ($IncludeKeys) { $arguments += 'key=clear' }

        $output = & "$env:SystemRoot\System32\netsh.exe" @arguments 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Impossibile leggere i profili Wi-Fi: $($output -join ' ')"
        }

        $profiles = foreach ($file in Get-ChildItem -LiteralPath $temporaryPath -Filter '*.xml' -File -ErrorAction SilentlyContinue) {
            try {
                [xml]$xml = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 -ErrorAction Stop
                $root = $xml.SelectSingleNode("/*[local-name()='WLANProfile']")
                if (-not $root) { continue }

                $nameNode = $root.SelectSingleNode("./*[local-name()='name']")
                $authNode = $root.SelectSingleNode(".//*[local-name()='authEncryption']/*[local-name()='authentication']")
                $encryptionNode = $root.SelectSingleNode(".//*[local-name()='authEncryption']/*[local-name()='encryption']")
                $keyNode = if ($IncludeKeys) { $root.SelectSingleNode(".//*[local-name()='sharedKey']/*[local-name()='keyMaterial']") } else { $null }

                [pscustomobject]@{
                    Name           = if ($nameNode) { $nameNode.InnerText } else { $file.BaseName }
                    Authentication = if ($authNode) { $authNode.InnerText } else { 'Non disponibile' }
                    Encryption     = if ($encryptionNode) { $encryptionNode.InnerText } else { 'Non disponibile' }
                    Password       = if ($keyNode) { $keyNode.InnerText } else { $null }
                }
            }
            catch {
                Write-Warning ("Profilo non leggibile ignorato: {0}" -f $file.Name)
            }
        }

        return @($profiles | Sort-Object Name)
    }
    finally {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Select-TDTWiFiProfile {
    param([Parameter(Mandatory)][array]$Profiles)

    if (-not $Profiles -or $Profiles.Count -eq 0) {
        Write-Warning 'Nessun profilo Wi-Fi salvato trovato.'
        return $null
    }

    for ($i = 0; $i -lt $Profiles.Count; $i++) {
        Write-Host (" [{0}] {1}" -f ($i + 1), $Profiles[$i].Name)
    }
    $raw = Read-Host 'Seleziona rete (INVIO annulla)'
    if (-not $raw) { return $null }

    $number = 0
    if (-not [int]::TryParse($raw, [ref]$number) -or $number -lt 1 -or $number -gt $Profiles.Count) {
        Write-Warning 'Scelta non valida.'
        return $null
    }
    return $Profiles[$number - 1]
}

function Show-TDTWiFiProfiles {
    Write-Host "`n[WI-FI] Profili salvati - sola lettura" -ForegroundColor Cyan
    $profiles = @(Get-TDTWiFiProfiles)
    if (-not $profiles) {
        Write-Warning 'Nessun profilo Wi-Fi salvato trovato.'
        return
    }
    $profiles | Select-Object Name,Authentication,Encryption | Format-Table -AutoSize | Out-Host
}

function Show-TDTWiFiPassword {
    Write-Warning 'La password selezionata verra mostrata in chiaro sullo schermo. Verificare che nessuno possa leggerla o fotografarla.'
    if ((Read-Host 'Scrivere MOSTRA per continuare') -cne 'MOSTRA') {
        Write-Host 'Operazione annullata.'
        return
    }

    $profiles = @(Get-TDTWiFiProfiles -IncludeKeys)
    $profile = Select-TDTWiFiProfile -Profiles $profiles
    if (-not $profile) { return }

    Write-Host "`nRete          : $($profile.Name)" -ForegroundColor Cyan
    Write-Host "Autenticazione: $($profile.Authentication)"
    Write-Host "Crittografia  : $($profile.Encryption)"
    if ($profile.Password) {
        Write-Host "Password      : $($profile.Password)" -ForegroundColor Yellow
    }
    else {
        Write-Host 'Password      : non presente o non esportabile (rete aperta/aziendale).' -ForegroundColor Yellow
    }
    Write-Host 'La password non e stata salvata nei log del Toolkit.' -ForegroundColor DarkGray
}

function Export-TDTWiFiProfiles {
    Write-Warning 'Il backup XML portabile contiene le password Wi-Fi in chiaro. Chiunque acceda ai file potra leggerle.'
    if ((Read-Host 'Scrivere ESPORTA per continuare') -cne 'ESPORTA') {
        Write-Host 'Operazione annullata.'
        return
    }

    $desktop = [Environment]::GetFolderPath('Desktop')
    $defaultPath = Join-Path $desktop ("TecnicoDigitale-WiFi-{0}" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
    $destination = Read-Host "Cartella destinazione (INVIO per $defaultPath)"
    if ([string]::IsNullOrWhiteSpace($destination)) { $destination = $defaultPath }

    [void](New-Item -ItemType Directory -Path $destination -Force -ErrorAction Stop)
    if (Get-ChildItem -LiteralPath $destination -Filter '*.xml' -File -ErrorAction SilentlyContinue) {
        Write-Warning 'La cartella contiene gia file XML. Scegliere una cartella vuota per evitare di mescolare backup diversi.'
        return
    }
    $output = & "$env:SystemRoot\System32\netsh.exe" wlan export profile ("folder={0}" -f $destination) key=clear 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Esportazione non riuscita: $($output -join ' ')"
    }

    $files = @(Get-ChildItem -LiteralPath $destination -Filter '*.xml' -File -ErrorAction SilentlyContinue)
    if (-not $files) { throw 'Netsh non ha creato alcun profilo XML.' }

    Write-Host ("Profili esportati: {0}" -f $files.Count) -ForegroundColor Green
    Write-Host ("Cartella: {0}" -f $destination) -ForegroundColor Green
    Write-Warning 'Conservare la cartella in un luogo protetto ed eliminarla quando non serve piu.'
}

function Import-TDTWiFiProfiles {
    $source = Read-Host 'Cartella contenente i profili Wi-Fi XML (INVIO annulla)'
    if ([string]::IsNullOrWhiteSpace($source)) { return }
    if (-not (Test-Path -LiteralPath $source -PathType Container)) {
        Write-Warning 'Cartella non trovata.'
        return
    }

    $validProfiles = foreach ($file in Get-ChildItem -LiteralPath $source -Filter '*.xml' -File -ErrorAction SilentlyContinue) {
        try {
            [xml]$xml = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 -ErrorAction Stop
            $root = $xml.SelectSingleNode("/*[local-name()='WLANProfile']")
            $nameNode = if ($root) { $root.SelectSingleNode("./*[local-name()='name']") } else { $null }
            if ($root -and $nameNode) {
                [pscustomobject]@{ Name=$nameNode.InnerText; Path=$file.FullName }
            }
        }
        catch {
            Write-Warning ("XML non valido ignorato: {0}" -f $file.Name)
        }
    }

    $validProfiles = @($validProfiles)
    if (-not $validProfiles) {
        Write-Warning 'Nessun profilo Wi-Fi XML valido trovato.'
        return
    }

    Write-Host "`nProfili da importare:" -ForegroundColor Cyan
    $validProfiles | Select-Object Name,Path | Format-Table -Wrap -AutoSize | Out-Host
    Write-Host "I profili verranno aggiunti per l'utente corrente; quelli con lo stesso nome possono essere sostituiti. Il Toolkit non avviera una connessione." -ForegroundColor Yellow
    if ((Read-Host 'Scrivere IMPORTA per continuare') -cne 'IMPORTA') {
        Write-Host 'Operazione annullata.'
        return
    }

    $success = 0
    foreach ($profile in $validProfiles) {
        $output = & "$env:SystemRoot\System32\netsh.exe" wlan add profile ("filename={0}" -f $profile.Path) user=current 2>&1
        if ($LASTEXITCODE -eq 0) {
            $success++
            Write-Host ("Importato: {0}" -f $profile.Name) -ForegroundColor Green
        }
        else {
            Write-Warning ("Importazione fallita per {0}: {1}" -f $profile.Name, ($output -join ' '))
        }
    }
    Write-Host ("Importazione completata: {0}/{1} profili." -f $success, $validProfiles.Count) -ForegroundColor Cyan
}

function Show-TDTWiFiCredentialTools {
    do {
        Write-Host "`n=================================================="
        Write-Host ' PASSWORD E BACKUP WI-FI' -ForegroundColor Cyan
        Write-Host '=================================================='
        Write-Host ' [1] Elenca profili salvati (read-only)'
        Write-Host ' [2] Visualizza password di una rete'
        Write-Host ' [3] Esporta tutti i profili per reimportazione'
        Write-Host " [4] Importa profili XML per l'utente corrente"
        Write-Host ' [0] Torna agli Strumenti Tecnico'

        $choice = Read-Host 'Scelta'
        try {
            switch ($choice) {
                '1' { Show-TDTWiFiProfiles; Wait-TDTMenu }
                '2' { Show-TDTWiFiPassword; Wait-TDTMenu }
                '3' { Export-TDTWiFiProfiles; Wait-TDTMenu }
                '4' { Import-TDTWiFiProfiles; Wait-TDTMenu }
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
