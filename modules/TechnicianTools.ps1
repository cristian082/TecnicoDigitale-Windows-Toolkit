function Test-TDTAdministrator {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Confirm-TDTAction {
    param([Parameter(Mandatory)][string]$Message)
    Write-Warning $Message
    return ((Read-Host 'Confermi? [S/N]') -match '^[SsYy]')
}

function Wait-TDTMenu {
    [void](Read-Host 'INVIO per continuare')
}

function Get-TDTFolderSizeMB {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    try {
        $sum = (Get-ChildItem -LiteralPath $Path -Force -File -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        if ($null -eq $sum) { $sum = 0 }
        return [math]::Round(($sum / 1MB), 1)
    }
    catch { return $null }
}

# ----------------------------- RETE -----------------------------
function Invoke-TDTFlushDns {
    Write-Host "`n[RETE] Pulizia cache DNS..." -ForegroundColor Cyan
    Clear-DnsClientCache -ErrorAction SilentlyContinue
    & ipconfig.exe /flushdns
}

function Restart-TDTNetworkAdapter {
    $adapters = @(Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object Status -ne 'Disabled')
    if (-not $adapters) { Write-Warning 'Nessuna scheda di rete fisica attiva rilevata.'; return }
    Write-Host "`nSchede disponibili:" -ForegroundColor Cyan
    for ($i=0; $i -lt $adapters.Count; $i++) { Write-Host (" [{0}] {1} - {2}" -f ($i+1),$adapters[$i].Name,$adapters[$i].Status) }
    $s = Read-Host 'Scheda da riavviare (INVIO annulla)'
    if (-not $s) { return }
    $n = 0
    if (-not [int]::TryParse($s,[ref]$n) -or $n -lt 1 -or $n -gt $adapters.Count) { Write-Warning 'Scelta non valida.'; return }
    $a = $adapters[$n-1]
    if (-not (Confirm-TDTAction "La connessione sulla scheda '$($a.Name)' verra temporaneamente interrotta.")) { return }
    Restart-NetAdapter -Name $a.Name -Confirm:$false
    Write-Host 'Scheda riavviata.' -ForegroundColor Green
}

function Set-TDTDnsPreset {
    $adapters = @(Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object Status -eq 'Up')
    if (-not $adapters) { Write-Warning 'Nessuna scheda con link attivo.'; return }
    Write-Host "`nSchede connesse:" -ForegroundColor Cyan
    for ($i=0; $i -lt $adapters.Count; $i++) { Write-Host (" [{0}] {1} - {2}" -f ($i+1),$adapters[$i].Name,$adapters[$i].InterfaceDescription) }
    $s = Read-Host 'Scheda (INVIO annulla)'
    if (-not $s) { return }
    $n = 0
    if (-not [int]::TryParse($s,[ref]$n) -or $n -lt 1 -or $n -gt $adapters.Count) { Write-Warning 'Scelta non valida.'; return }
    $a = $adapters[$n-1]
    $old = @(Get-DnsClientServerAddress -InterfaceIndex $a.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses
    Write-Host ("DNS attuali: {0}" -f ($old -join ', '))
    Write-Host ' [1] Automatico (DHCP)'
    Write-Host ' [2] Cloudflare 1.1.1.1 / 1.0.0.1'
    Write-Host ' [3] Google 8.8.8.8 / 8.8.4.4'
    Write-Host ' [4] Quad9 9.9.9.9 / 149.112.112.112'
    $p = Read-Host 'Preset'
    switch ($p) {
        '1' { Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ResetServerAddresses }
        '2' { Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses @('1.1.1.1','1.0.0.1') }
        '3' { Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses @('8.8.8.8','8.8.4.4') }
        '4' { Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses @('9.9.9.9','149.112.112.112') }
        default { Write-Warning 'Nessuna modifica.'; return }
    }
    Clear-DnsClientCache -ErrorAction SilentlyContinue
    $new = @(Get-DnsClientServerAddress -InterfaceIndex $a.ifIndex -AddressFamily IPv4).ServerAddresses
    Write-Host ("DNS impostati: {0}" -f ($new -join ', ')) -ForegroundColor Green
}

function Invoke-TDTNetworkCheck {
    Write-Host "`n[RETE] Diagnostica rapida" -ForegroundColor Cyan
    $cfg = Get-NetIPConfiguration -ErrorAction SilentlyContinue | Where-Object { $_.IPv4Address -and $_.NetAdapter.Status -eq 'Up' }
    foreach ($c in $cfg) {
        Write-Host ("{0}: IP {1}  Gateway {2}  DNS {3}" -f $c.InterfaceAlias,$c.IPv4Address.IPAddress,$c.IPv4DefaultGateway.NextHop,($c.DNSServer.ServerAddresses -join ','))
    }
    $gateway = ($cfg | Where-Object IPv4DefaultGateway | Select-Object -First 1).IPv4DefaultGateway.NextHop
    if ($gateway) {
        $gatewayOk = Test-Connection $gateway -Count 1 -Quiet -ErrorAction SilentlyContinue
        Write-Host ("Gateway: {0}" -f $(if($gatewayOk){'OK'}else{'ERRORE'}))
    }
    $internetOk = Test-Connection '1.1.1.1' -Count 1 -Quiet -ErrorAction SilentlyContinue
    Write-Host ("Internet IP: {0}" -f $(if($internetOk){'OK'}else{'ERRORE'}))
    try { Resolve-DnsName 'www.microsoft.com' -Type A -ErrorAction Stop | Out-Null; Write-Host 'DNS: OK' }
    catch { Write-Host 'DNS: ERRORE' -ForegroundColor Yellow }
}

function Get-TDTNetworkAdvanced {
    Write-Host "`n[RETE] Diagnostica avanzata - sola analisi" -ForegroundColor Cyan
    Write-Host "`nSchede:" -ForegroundColor DarkGray
    Get-NetAdapter -ErrorAction SilentlyContinue | Sort-Object Status,Name | Select-Object Name,Status,LinkSpeed,MacAddress,InterfaceDescription | Format-Table -AutoSize | Out-Host
    Write-Host "`nConfigurazione IP:" -ForegroundColor DarkGray
    Get-NetIPConfiguration -ErrorAction SilentlyContinue | Where-Object IPv4Address | ForEach-Object {
        [pscustomobject]@{ Scheda=$_.InterfaceAlias; IPv4=$_.IPv4Address.IPAddress; Gateway=$_.IPv4DefaultGateway.NextHop; DNS=($_.DNSServer.ServerAddresses -join ', ') }
    } | Format-Table -AutoSize | Out-Host
    Write-Host "`nProfili firewall rete:" -ForegroundColor DarkGray
    Get-NetConnectionProfile -ErrorAction SilentlyContinue | Select-Object InterfaceAlias,Name,NetworkCategory,IPv4Connectivity | Format-Table -AutoSize | Out-Host
    Write-Host "`nRoute predefinite:" -ForegroundColor DarkGray
    Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue | Select-Object InterfaceAlias,NextHop,RouteMetric | Format-Table -AutoSize | Out-Host
    Write-Host "`nProxy WinHTTP:" -ForegroundColor DarkGray
    & netsh.exe winhttp show proxy
    Write-Host "`nPorte TCP in ascolto (prime 30):" -ForegroundColor DarkGray
    Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Sort-Object LocalPort | Select-Object -First 30 LocalAddress,LocalPort,OwningProcess | Format-Table -AutoSize | Out-Host
}

# ------------------------ WINDOWS UPDATE ------------------------
function Test-TDTPendingReboot {
    $paths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending',
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
    )
    foreach ($path in $paths) { if (Test-Path $path) { return $true } }
    try {
        $value = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name PendingFileRenameOperations -ErrorAction SilentlyContinue).PendingFileRenameOperations
        if ($value) { return $true }
    } catch {}
    return $false
}

function Get-TDTWindowsUpdateStatus {
    Write-Host "`n[WINDOWS UPDATE] Stato" -ForegroundColor Cyan
    Get-Service wuauserv,bits,UsoSvc,cryptsvc -ErrorAction SilentlyContinue | Select-Object Name,Status,StartType | Format-Table -AutoSize | Out-Host
    Write-Host ("Riavvio in sospeso: {0}" -f $(if(Test-TDTPendingReboot){'SI'}else{'NO'}))
    Write-Host "`nUltimi aggiornamenti installati:" -ForegroundColor DarkGray
    Get-HotFix -ErrorAction SilentlyContinue | Sort-Object InstalledOn -Descending | Select-Object -First 10 HotFixID,Description,InstalledOn | Format-Table -AutoSize | Out-Host
}

function Find-TDTWindowsUpdates {
    Write-Host "`n[WINDOWS UPDATE] Ricerca aggiornamenti disponibili" -ForegroundColor Cyan
    Write-Host 'La ricerca puo richiedere qualche minuto.' -ForegroundColor DarkGray
    $session = New-Object -ComObject Microsoft.Update.Session
    $searcher = $session.CreateUpdateSearcher()
    $result = $searcher.Search("IsInstalled=0 and IsHidden=0")
    if ($result.Updates.Count -eq 0) { Write-Host 'Nessun aggiornamento disponibile rilevato.' -ForegroundColor Green; return }
    $items = for ($i=0; $i -lt $result.Updates.Count; $i++) {
        $u = $result.Updates.Item($i)
        [pscustomobject]@{ Titolo=$u.Title; RiavvioRichiesto=[bool]$u.RebootRequired }
    }
    $items | Format-Table -Wrap -AutoSize | Out-Host
    Write-Host ("Aggiornamenti trovati: {0}" -f $items.Count) -ForegroundColor Yellow
    Write-Host 'Nessun aggiornamento viene installato automaticamente da questo controllo.' -ForegroundColor DarkGray
}

function Repair-TDTWindowsUpdateCache {
    if (-not (Confirm-TDTAction 'Ripristinera la cache di Windows Update. I servizi Update/BITS/Crittografia verranno fermati solo durante la riparazione e poi riavviati. Le policy di Windows Update non vengono modificate.')) { return }
    Write-Host "`n[WINDOWS UPDATE] Riparazione cache" -ForegroundColor Cyan
    $services = @('bits','wuauserv','cryptsvc')
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    try {
        foreach ($name in $services) { Stop-Service -Name $name -Force -ErrorAction SilentlyContinue }
        $sd = Join-Path $env:SystemRoot 'SoftwareDistribution'
        $cr = Join-Path $env:SystemRoot 'System32\catroot2'
        if (Test-Path $sd) { Rename-Item -LiteralPath $sd -NewName ("SoftwareDistribution.TDT-$stamp.old") -ErrorAction Stop }
        if (Test-Path $cr) { Rename-Item -LiteralPath $cr -NewName ("catroot2.TDT-$stamp.old") -ErrorAction Stop }
        Write-Host 'Cache Windows Update rigenerabile rimossa dal percorso attivo.' -ForegroundColor Green
    }
    finally {
        foreach ($name in @('cryptsvc','wuauserv','bits')) { Start-Service -Name $name -ErrorAction SilentlyContinue }
    }
}

# -------------------------- DISM / SFC --------------------------
function Invoke-TDTDismCheckHealth {
    Write-Host "`n[DISM] CheckHealth" -ForegroundColor Cyan
    & dism.exe /Online /Cleanup-Image /CheckHealth
}

function Invoke-TDTDismScanHealth {
    Write-Host "`n[DISM] ScanHealth" -ForegroundColor Cyan
    & dism.exe /Online /Cleanup-Image /ScanHealth
}

function Invoke-TDTDismRestoreHealth {
    if (-not (Confirm-TDTAction 'DISM /RestoreHealth puo modificare il component store di Windows per riparare file corrotti.')) { return }
    Write-Host "`n[DISM] RestoreHealth" -ForegroundColor Cyan
    & dism.exe /Online /Cleanup-Image /RestoreHealth
}

function Invoke-TDTSfcScan {
    if (-not (Confirm-TDTAction 'SFC /scannow controllera e, se necessario, sostituira file di sistema Windows corrotti.')) { return }
    Write-Host "`n[SFC] Controllo file di sistema" -ForegroundColor Cyan
    & sfc.exe /scannow
}

function Invoke-TDTWindowsComponentRepair {
    if (-not (Confirm-TDTAction 'Eseguira DISM /RestoreHealth seguito da SFC /scannow. Non verra effettuato alcun riavvio automatico.')) { return }
    Write-Host "`n[WINDOWS] Riparazione componenti" -ForegroundColor Cyan
    & dism.exe /Online /Cleanup-Image /RestoreHealth
    if ($LASTEXITCODE -ne 0) { Write-Warning "DISM terminato con codice $LASTEXITCODE. SFC verra comunque eseguito." }
    & sfc.exe /scannow
    Write-Host 'Sequenza completata. Valutare un riavvio in base all esito mostrato sopra.' -ForegroundColor Green
}

# ------------------------- DISCHI / SMART -----------------------
function Get-TDTDiskHealth {
    Write-Host "`n[DISCHI] Stato dischi e SMART" -ForegroundColor Cyan
    $physical = @(Get-PhysicalDisk -ErrorAction SilentlyContinue)
    if ($physical) {
        $physical | Select-Object FriendlyName,MediaType,BusType,HealthStatus,OperationalStatus,@{N='SizeGB';E={[math]::Round($_.Size/1GB,1)}} | Format-Table -AutoSize | Out-Host
        Write-Host "`nContatori affidabilita disponibili:" -ForegroundColor DarkGray
        foreach ($disk in $physical) {
            try {
                $r = $disk | Get-StorageReliabilityCounter -ErrorAction Stop
                [pscustomobject]@{
                    Disco=$disk.FriendlyName
                    Temperatura=$r.Temperature
                    OreAcceso=$r.PowerOnHours
                    ErroriLettura=$r.ReadErrorsTotal
                    ErroriScrittura=$r.WriteErrorsTotal
                    Wear=$r.Wear
                } | Format-Table -AutoSize | Out-Host
            }
            catch { Write-Host ("{0}: contatori SMART dettagliati non esposti dal driver/controller." -f $disk.FriendlyName) -ForegroundColor DarkGray }
        }
    }
    else {
        Write-Warning 'Get-PhysicalDisk non ha restituito dischi. Mostro dati CIM di base.'
        Get-CimInstance Win32_DiskDrive -ErrorAction SilentlyContinue | Select-Object Model,InterfaceType,Status,@{N='SizeGB';E={[math]::Round($_.Size/1GB,1)}} | Format-Table -AutoSize | Out-Host
    }
}

function Invoke-TDTChkdskScan {
    $volumes = @(Get-Volume -ErrorAction SilentlyContinue | Where-Object { $_.DriveLetter -and $_.DriveType -eq 'Fixed' })
    if (-not $volumes) { Write-Warning 'Nessun volume fisso con lettera rilevato.'; return }
    for ($i=0; $i -lt $volumes.Count; $i++) { Write-Host (" [{0}] {1}:  {2}  {3}" -f ($i+1),$volumes[$i].DriveLetter,$volumes[$i].FileSystemLabel,$volumes[$i].FileSystem) }
    $s = Read-Host 'Volume da controllare con CHKDSK /scan (INVIO annulla)'
    if (-not $s) { return }
    $n=0
    if (-not [int]::TryParse($s,[ref]$n) -or $n -lt 1 -or $n -gt $volumes.Count) { Write-Warning 'Scelta non valida.'; return }
    $drive = "$($volumes[$n-1].DriveLetter):"
    Write-Host "`n[DISCHI] CHKDSK $drive /scan" -ForegroundColor Cyan
    & chkdsk.exe $drive /scan
}

# --------------------------- STAMPA -----------------------------
function Get-TDTPrinterStatus {
    Write-Host "`n[STAMPA] Diagnostica stampanti" -ForegroundColor Cyan
    $printers = @(Get-Printer -ErrorAction SilentlyContinue)
    if (-not $printers) { Write-Warning 'Nessuna stampante rilevata.'; return }
    $printers | Select-Object Name,DriverName,PortName,PrinterStatus,Shared,Published | Format-Table -Wrap -AutoSize | Out-Host
    Write-Host "`nPorte usate:" -ForegroundColor DarkGray
    $ports = $printers.PortName | Sort-Object -Unique
    Get-PrinterPort -ErrorAction SilentlyContinue | Where-Object { $ports -contains $_.Name } | Select-Object Name,PrinterHostAddress,PortNumber,Protocol | Format-Table -AutoSize | Out-Host
    Write-Host "`nSpooler:" -ForegroundColor DarkGray
    Get-Service Spooler | Select-Object Name,Status,StartType | Format-Table -AutoSize | Out-Host
}

function Reset-TDTPrintSpooler {
    Write-Host "`n[STAMPA] Reset Spooler" -ForegroundColor Cyan
    if (-not (Confirm-TDTAction 'Questa operazione elimina i documenti attualmente presenti nella coda di stampa.')) { return }
    Stop-Service Spooler -Force -ErrorAction Stop
    $queue = Join-Path $env:SystemRoot 'System32\spool\PRINTERS'
    Get-ChildItem -LiteralPath $queue -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Start-Service Spooler -ErrorAction Stop
    $svc = Get-Service Spooler
    Write-Host ("Spooler: {0}" -f $svc.Status) -ForegroundColor Green
}

# --------------------------- SERVIZI ----------------------------
function Get-TDTServiceHealth {
    Write-Host "`n[SERVIZI] Controllo rapido - sola analisi" -ForegroundColor Cyan
    $critical = @('WinDefend','mpssvc','wuauserv','bits','Spooler','Dhcp','Dnscache','Audiosrv','EventLog')
    Write-Host 'Servizi importanti:' -ForegroundColor DarkGray
    Get-Service -Name $critical -ErrorAction SilentlyContinue | Select-Object Name,DisplayName,Status,StartType | Format-Table -AutoSize | Out-Host
    Write-Host "`nServizi Automatici attualmente fermi:" -ForegroundColor DarkGray
    $stopped = @(Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.StartType -eq 'Automatic' -and $_.Status -eq 'Stopped' })
    if ($stopped) { $stopped | Select-Object Name,DisplayName,Status,StartType | Format-Table -AutoSize | Out-Host }
    else { Write-Host 'Nessuno.' -ForegroundColor Green }
    Write-Host 'Un servizio Automatico fermo non implica necessariamente un guasto: alcuni sono trigger-start.' -ForegroundColor Yellow
}

function Restart-TDTServiceByName {
    $name = Read-Host 'Nome servizio da riavviare (es. Spooler; INVIO annulla)'
    if (-not $name) { return }
    $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
    if (-not $svc) { Write-Warning 'Servizio non trovato.'; return }
    Write-Host ("{0} ({1}) - Stato: {2} - Avvio: {3}" -f $svc.DisplayName,$svc.Name,$svc.Status,$svc.StartType)
    if (-not (Confirm-TDTAction "Riavviare il servizio '$($svc.Name)'? Nessun tipo di avvio verra modificato.")) { return }
    Restart-Service -Name $svc.Name -Force -ErrorAction Stop
    Write-Host 'Servizio riavviato.' -ForegroundColor Green
}

# --------------------------- DRIVER -----------------------------
function Get-TDTDriverStatus {
    Write-Host "`n[DRIVER] Dispositivi con problemi" -ForegroundColor Cyan
    $bad = @(Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object Status -ne 'OK')
    if ($bad) { $bad | Select-Object Status,Class,FriendlyName,InstanceId | Format-Table -Wrap -AutoSize | Out-Host }
    else { Write-Host 'Nessun dispositivo PnP con stato anomalo rilevato.' -ForegroundColor Green }
    Write-Host "`nDriver firmati installati di recente (primi 25):" -ForegroundColor DarkGray
    Get-CimInstance Win32_PnPSignedDriver -ErrorAction SilentlyContinue | Where-Object DeviceName | Sort-Object DriverDate -Descending | Select-Object -First 25 DeviceName,Manufacturer,DriverVersion,DriverDate,IsSigned | Format-Table -Wrap -AutoSize | Out-Host
}

function Invoke-TDTPnpRescan {
    if (-not (Confirm-TDTAction 'Forzera una nuova scansione Plug and Play dei dispositivi. Non rimuove driver.')) { return }
    Write-Host "`n[DRIVER] Scansione hardware PnP" -ForegroundColor Cyan
    & pnputil.exe /scan-devices
}

# ------------------------ AVVIO AUTOMATICO ----------------------
function Get-TDTStartupItems {
    Write-Host "`n[AVVIO] Elementi di avvio - sola analisi" -ForegroundColor Cyan
    $items = @(Get-CimInstance Win32_StartupCommand -ErrorAction SilentlyContinue | Select-Object Name,Location,User,Command)
    if ($items) { $items | Format-Table -Wrap -AutoSize | Out-Host }
    else { Write-Host 'Nessun elemento Win32_StartupCommand rilevato.' -ForegroundColor Green }
    Write-Host "`nAttivita pianificate con trigger Logon (prime 30):" -ForegroundColor DarkGray
    $tasks = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.Triggers | Where-Object { $_.CimClass.CimClassName -eq 'MSFT_TaskLogonTrigger' } } | Select-Object -First 30 TaskPath,TaskName,State
    if ($tasks) { $tasks | Format-Table -AutoSize | Out-Host } else { Write-Host 'Nessuna attivita Logon rilevata.' -ForegroundColor DarkGray }
    Write-Host 'Questa schermata non disabilita automaticamente alcun elemento.' -ForegroundColor Yellow
}

# --------------------------- EVENTI -----------------------------
function Get-TDTRecentErrors {
    Write-Host "`n[EVENTI] Errori e critici recenti (ultime 24 ore)" -ForegroundColor Cyan
    $start = (Get-Date).AddHours(-24)
    foreach ($log in @('System','Application')) {
        Write-Host "`n$log" -ForegroundColor DarkGray
        $events = @(Get-WinEvent -FilterHashtable @{LogName=$log; Level=1,2; StartTime=$start} -MaxEvents 30 -ErrorAction SilentlyContinue)
        if ($events) {
            $events | Select-Object TimeCreated,Id,ProviderName,@{N='Messaggio';E={ if($_.Message){$_.Message.Replace("`r",' ').Replace("`n",' ')}else{''} }} | Format-Table -Wrap -AutoSize | Out-Host
        } else { Write-Host 'Nessun evento Critico/Errore nelle ultime 24 ore.' -ForegroundColor Green }
    }
}

# -------------------------- BITLOCKER ---------------------------
function Get-TDTBitLockerStatus {
    Write-Host "`n[BITLOCKER] Stato cifratura - sola analisi" -ForegroundColor Cyan
    if (Get-Command Get-BitLockerVolume -ErrorAction SilentlyContinue) {
        Get-BitLockerVolume -ErrorAction SilentlyContinue | Select-Object MountPoint,VolumeStatus,ProtectionStatus,EncryptionPercentage,EncryptionMethod,AutoUnlockEnabled | Format-Table -AutoSize | Out-Host
    } else {
        & manage-bde.exe -status
    }
    Write-Host 'Nessuna chiave viene mostrata, esportata o modificata.' -ForegroundColor DarkGray
}

# ------------------------- SPAZIO DISCO -------------------------
function Get-TDTDiskSpaceReport {
    Write-Host "`n[SPAZIO DISCO] Panoramica" -ForegroundColor Cyan
    Get-Volume -ErrorAction SilentlyContinue | Where-Object DriveLetter | ForEach-Object {
        $size = [double]$_.Size
        $free = [double]$_.SizeRemaining
        [pscustomobject]@{
            Volume = "$($_.DriveLetter):"
            Etichetta = $_.FileSystemLabel
            FileSystem = $_.FileSystem
            TotaleGB = if($size){[math]::Round($size/1GB,1)}else{0}
            LiberiGB = if($free){[math]::Round($free/1GB,1)}else{0}
            LiberiPct = if($size){[math]::Round(($free/$size)*100,1)}else{0}
        }
    } | Format-Table -AutoSize | Out-Host

    Write-Host "`nCartelle temporanee principali (stima):" -ForegroundColor DarkGray
    $paths = @($env:TEMP,(Join-Path $env:SystemRoot 'Temp')) | Select-Object -Unique
    foreach ($path in $paths) {
        $mb = Get-TDTFolderSizeMB -Path $path
        if ($null -ne $mb) { Write-Host ("{0} : {1} MB" -f $path,$mb) }
    }
    Write-Host 'Nessun file viene cancellato da questa analisi.' -ForegroundColor DarkGray
}

# -------------------- SICUREZZA / PROCESSI ---------------------
function Get-TDTProcessTriage {
    Write-Host "`n[SICUREZZA] Triage processi - sola analisi" -ForegroundColor Cyan
    Write-Host 'ATTENZIONE: un elemento segnalato non equivale a malware.' -ForegroundColor Yellow
    $startupText = ((Get-CimInstance Win32_StartupCommand -ErrorAction SilentlyContinue).Command -join "`n")
    $pf86 = [Environment]::GetFolderPath('ProgramFilesX86')
    $items = foreach ($proc in Get-CimInstance Win32_Process -ErrorAction SilentlyContinue) {
        if (-not $proc.ExecutablePath) { continue }
        $path = $proc.ExecutablePath
        $sig = $null
        try { $sig = Get-AuthenticodeSignature -LiteralPath $path -ErrorAction Stop } catch {}
        $score = 0
        $reasons = New-Object System.Collections.Generic.List[string]
        $trustedPath = ($path -like "$env:SystemRoot\System32\*" -or $path -like "$env:ProgramFiles\*" -or ($pf86 -and $path -like "$pf86\*"))
        if (-not $sig -or $sig.Status -ne 'Valid') { $score += 2; $reasons.Add('firma non valida/assente') }
        if ($path -like "$env:TEMP\*" -or $path -like "$env:LOCALAPPDATA\Temp\*") { $score += 3; $reasons.Add('esecuzione da TEMP') }
        elseif ($path -like "$env:APPDATA\*" -or $path -like "$env:LOCALAPPDATA\*") { $score += 1; $reasons.Add('esecuzione da profilo utente') }
        if ($startupText -and $startupText.IndexOf($path,[StringComparison]::OrdinalIgnoreCase) -ge 0) { $score += 1; $reasons.Add('avvio automatico') }
        if ($trustedPath -and $sig -and $sig.Status -eq 'Valid') { $score = [math]::Max(0,$score-1) }
        if ($score -ge 2) {
            [pscustomobject]@{ Score=$score; PID=$proc.ProcessId; Name=$proc.Name; Publisher=if($sig -and $sig.SignerCertificate){$sig.SignerCertificate.Subject}else{''}; Signature=if($sig){[string]$sig.Status}else{'Non disponibile'}; Path=$path; Reasons=($reasons -join ', ') }
        }
    }
    $items = @($items | Sort-Object -Property @{Expression='Score';Descending=$true},Name)
    if (-not $items) { Write-Host 'Nessun processo con indicatori elementari di attenzione.' -ForegroundColor Green; return @() }
    $items | Format-Table Score,PID,Name,Signature,Reasons -AutoSize | Out-Host
    Write-Host "`nI risultati richiedono verifica tecnica: nessun processo viene terminato o cancellato." -ForegroundColor Yellow
    return $items
}

# -------------------------- SOTTOMENU ---------------------------
function Show-TDTNetworkTools {
    do {
        Write-Host "`n--- RETE ---" -ForegroundColor Cyan
        Write-Host ' [1] Diagnostica rapida'
        Write-Host ' [2] Diagnostica avanzata'
        Write-Host ' [3] Pulisci cache DNS'
        Write-Host ' [4] Cambia DNS rapidamente'
        Write-Host ' [5] Riavvia scheda di rete'
        Write-Host ' [0] Indietro'
        $c = Read-Host 'Scelta'
        try { switch($c){ '1'{Invoke-TDTNetworkCheck}; '2'{Get-TDTNetworkAdvanced}; '3'{Invoke-TDTFlushDns}; '4'{Set-TDTDnsPreset}; '5'{Restart-TDTNetworkAdapter}; '0'{return}; default{Write-Warning 'Scelta non valida.'} } } catch { Write-Warning $_.Exception.Message }
        if ($c -ne '0') { Wait-TDTMenu }
    } while ($true)
}

function Show-TDTWindowsUpdateTools {
    do {
        Write-Host "`n--- WINDOWS UPDATE ---" -ForegroundColor Cyan
        Write-Host ' [1] Stato Windows Update / riavvio pendente'
        Write-Host ' [2] Cerca aggiornamenti disponibili (non installa)'
        Write-Host ' [3] Ripara cache Windows Update'
        Write-Host ' [0] Indietro'
        $c = Read-Host 'Scelta'
        try { switch($c){ '1'{Get-TDTWindowsUpdateStatus}; '2'{Find-TDTWindowsUpdates}; '3'{Repair-TDTWindowsUpdateCache}; '0'{return}; default{Write-Warning 'Scelta non valida.'} } } catch { Write-Warning $_.Exception.Message }
        if ($c -ne '0') { Wait-TDTMenu }
    } while ($true)
}

function Show-TDTWindowsRepairTools {
    do {
        Write-Host "`n--- INTEGRITA WINDOWS ---" -ForegroundColor Cyan
        Write-Host ' [1] DISM CheckHealth (rapido)'
        Write-Host ' [2] DISM ScanHealth (analisi)'
        Write-Host ' [3] DISM RestoreHealth (riparazione)'
        Write-Host ' [4] SFC /scannow'
        Write-Host ' [5] Riparazione completa DISM + SFC'
        Write-Host ' [0] Indietro'
        $c = Read-Host 'Scelta'
        try { switch($c){ '1'{Invoke-TDTDismCheckHealth}; '2'{Invoke-TDTDismScanHealth}; '3'{Invoke-TDTDismRestoreHealth}; '4'{Invoke-TDTSfcScan}; '5'{Invoke-TDTWindowsComponentRepair}; '0'{return}; default{Write-Warning 'Scelta non valida.'} } } catch { Write-Warning $_.Exception.Message }
        if ($c -ne '0') { Wait-TDTMenu }
    } while ($true)
}

function Show-TDTDiskTools {
    do {
        Write-Host "`n--- DISCHI / SMART ---" -ForegroundColor Cyan
        Write-Host ' [1] Stato dischi / SMART'
        Write-Host ' [2] CHKDSK /scan su volume scelto'
        Write-Host ' [0] Indietro'
        $c = Read-Host 'Scelta'
        try { switch($c){ '1'{Get-TDTDiskHealth}; '2'{Invoke-TDTChkdskScan}; '0'{return}; default{Write-Warning 'Scelta non valida.'} } } catch { Write-Warning $_.Exception.Message }
        if ($c -ne '0') { Wait-TDTMenu }
    } while ($true)
}

function Show-TDTPrinterTools {
    do {
        Write-Host "`n--- STAMPANTI ---" -ForegroundColor Cyan
        Write-Host ' [1] Diagnostica stampanti / porte / spooler'
        Write-Host ' [2] Reset Spooler / coda di stampa'
        Write-Host ' [0] Indietro'
        $c = Read-Host 'Scelta'
        try { switch($c){ '1'{Get-TDTPrinterStatus}; '2'{Reset-TDTPrintSpooler}; '0'{return}; default{Write-Warning 'Scelta non valida.'} } } catch { Write-Warning $_.Exception.Message }
        if ($c -ne '0') { Wait-TDTMenu }
    } while ($true)
}

function Show-TDTServiceTools {
    do {
        Write-Host "`n--- SERVIZI ---" -ForegroundColor Cyan
        Write-Host ' [1] Controllo servizi importanti / Automatici fermi'
        Write-Host ' [2] Riavvia un servizio per nome'
        Write-Host ' [0] Indietro'
        $c = Read-Host 'Scelta'
        try { switch($c){ '1'{Get-TDTServiceHealth}; '2'{Restart-TDTServiceByName}; '0'{return}; default{Write-Warning 'Scelta non valida.'} } } catch { Write-Warning $_.Exception.Message }
        if ($c -ne '0') { Wait-TDTMenu }
    } while ($true)
}

function Show-TDTDriverTools {
    do {
        Write-Host "`n--- DRIVER / DISPOSITIVI ---" -ForegroundColor Cyan
        Write-Host ' [1] Dispositivi con problemi + driver recenti'
        Write-Host ' [2] Nuova scansione hardware PnP'
        Write-Host ' [0] Indietro'
        $c = Read-Host 'Scelta'
        try { switch($c){ '1'{Get-TDTDriverStatus}; '2'{Invoke-TDTPnpRescan}; '0'{return}; default{Write-Warning 'Scelta non valida.'} } } catch { Write-Warning $_.Exception.Message }
        if ($c -ne '0') { Wait-TDTMenu }
    } while ($true)
}

function Show-TDTTechnicianTools {
    if (-not (Test-TDTAdministrator)) { throw 'Gli Strumenti Tecnico richiedono privilegi amministrativi.' }
    do {
        Write-Host "`n=================================================="
        Write-Host ' TECNICO DIGITALE - STRUMENTI TECNICI' -ForegroundColor Cyan
        Write-Host '=================================================='
        Write-Host ' [1]  Rete'
        Write-Host ' [2]  Windows Update'
        Write-Host ' [3]  Integrita Windows - DISM / SFC'
        Write-Host ' [4]  Dischi / SMART / CHKDSK'
        Write-Host ' [5]  Stampanti'
        Write-Host ' [6]  Servizi'
        Write-Host ' [7]  Driver / dispositivi'
        Write-Host ' [8]  Avvio automatico (read-only)'
        Write-Host ' [9]  Eventi Windows recenti'
        Write-Host ' [10] BitLocker (read-only)'
        Write-Host ' [11] Spazio disco / TEMP (read-only)'
        Write-Host ' [12] Triage processi sospetti (read-only)'
        Write-Host ' [0]  Torna al menu principale'
        $c = Read-Host 'Scelta'
        try {
            switch ($c) {
                '1'  { Show-TDTNetworkTools }
                '2'  { Show-TDTWindowsUpdateTools }
                '3'  { Show-TDTWindowsRepairTools }
                '4'  { Show-TDTDiskTools }
                '5'  { Show-TDTPrinterTools }
                '6'  { Show-TDTServiceTools }
                '7'  { Show-TDTDriverTools }
                '8'  { Get-TDTStartupItems; Wait-TDTMenu }
                '9'  { Get-TDTRecentErrors; Wait-TDTMenu }
                '10' { Get-TDTBitLockerStatus; Wait-TDTMenu }
                '11' { Get-TDTDiskSpaceReport; Wait-TDTMenu }
                '12' { Get-TDTProcessTriage | Out-Null; Wait-TDTMenu }
                '0'  { return }
                default { Write-Warning 'Scelta non valida.' }
            }
        }
        catch { Write-Warning $_.Exception.Message; Wait-TDTMenu }
    } while ($true)
}
