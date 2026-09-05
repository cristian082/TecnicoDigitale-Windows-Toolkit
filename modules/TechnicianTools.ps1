function Test-TDTAdministrator {
    $id=[Security.Principal.WindowsIdentity]::GetCurrent()
    $p=New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-TDTFlushDns {
    Write-Host "`n[RETE] Pulizia cache DNS..." -ForegroundColor Cyan
    Clear-DnsClientCache -ErrorAction SilentlyContinue
    & ipconfig.exe /flushdns
}

function Restart-TDTNetworkAdapter {
    $adapters=@(Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object Status -ne 'Disabled')
    if(-not $adapters){ Write-Warning 'Nessuna scheda di rete fisica attiva rilevata.'; return }
    Write-Host "`nSchede disponibili:" -ForegroundColor Cyan
    for($i=0;$i-lt $adapters.Count;$i++){ Write-Host (" [{0}] {1} - {2}" -f ($i+1),$adapters[$i].Name,$adapters[$i].Status) }
    $s=Read-Host 'Scheda da riavviare (INVIO annulla)'
    if(-not $s){return}; $n=0
    if(-not [int]::TryParse($s,[ref]$n) -or $n-lt 1 -or $n-gt $adapters.Count){Write-Warning 'Scelta non valida.';return}
    $a=$adapters[$n-1]
    Write-Warning "La connessione sulla scheda '$($a.Name)' verra temporaneamente interrotta."
    if((Read-Host 'Confermi? [S/N]') -notmatch '^[SsYy]'){return}
    Restart-NetAdapter -Name $a.Name -Confirm:$false
    Write-Host 'Scheda riavviata.' -ForegroundColor Green
}

function Set-TDTDnsPreset {
    $adapters=@(Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object Status -eq 'Up')
    if(-not $adapters){Write-Warning 'Nessuna scheda con link attivo.';return}
    Write-Host "`nSchede connesse:" -ForegroundColor Cyan
    for($i=0;$i-lt $adapters.Count;$i++){Write-Host (" [{0}] {1} - {2}" -f ($i+1),$adapters[$i].Name,$adapters[$i].InterfaceDescription)}
    $s=Read-Host 'Scheda (INVIO annulla)'; if(-not $s){return}; $n=0
    if(-not [int]::TryParse($s,[ref]$n) -or $n-lt 1 -or $n-gt $adapters.Count){Write-Warning 'Scelta non valida.';return}
    $a=$adapters[$n-1]
    $old=@(Get-DnsClientServerAddress -InterfaceIndex $a.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses
    Write-Host ("DNS attuali: {0}" -f ($old -join ', '))
    Write-Host ' [1] Automatico (DHCP)';Write-Host ' [2] Cloudflare 1.1.1.1 / 1.0.0.1';Write-Host ' [3] Google 8.8.8.8 / 8.8.4.4';Write-Host ' [4] Quad9 9.9.9.9 / 149.112.112.112'
    $p=Read-Host 'Preset'
    switch($p){
      '1' {Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ResetServerAddresses}
      '2' {Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses @('1.1.1.1','1.0.0.1')}
      '3' {Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses @('8.8.8.8','8.8.4.4')}
      '4' {Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses @('9.9.9.9','149.112.112.112')}
      default {Write-Warning 'Nessuna modifica.';return}
    }
    Clear-DnsClientCache -ErrorAction SilentlyContinue
    $new=@(Get-DnsClientServerAddress -InterfaceIndex $a.ifIndex -AddressFamily IPv4).ServerAddresses
    Write-Host ("DNS impostati: {0}" -f ($new -join ', ')) -ForegroundColor Green
}

function Invoke-TDTNetworkCheck {
    Write-Host "`n[RETE] Diagnostica rapida" -ForegroundColor Cyan
    $cfg=Get-NetIPConfiguration -ErrorAction SilentlyContinue | Where-Object {$_.IPv4Address -and $_.NetAdapter.Status -eq 'Up'}
    foreach($c in $cfg){Write-Host ("{0}: IP {1}  Gateway {2}  DNS {3}" -f $c.InterfaceAlias,$c.IPv4Address.IPAddress,$c.IPv4DefaultGateway.NextHop,($c.DNSServer.ServerAddresses -join ','))}
    $gateway=($cfg|Where-Object IPv4DefaultGateway|Select-Object -First 1).IPv4DefaultGateway.NextHop
    if($gateway){$gatewayOk=Test-Connection $gateway -Count 1 -Quiet -ErrorAction SilentlyContinue;Write-Host ("Gateway: {0}" -f $(if($gatewayOk){'OK'}else{'ERRORE'}))}
    $internetOk=Test-Connection '1.1.1.1' -Count 1 -Quiet -ErrorAction SilentlyContinue
    Write-Host ("Internet IP: {0}" -f $(if($internetOk){'OK'}else{'ERRORE'}))
    try{Resolve-DnsName 'www.microsoft.com' -Type A -ErrorAction Stop|Out-Null;Write-Host 'DNS: OK'}catch{Write-Host 'DNS: ERRORE' -ForegroundColor Yellow}
}

function Reset-TDTPrintSpooler {
    Write-Host "`n[STAMPA] Reset Spooler" -ForegroundColor Cyan
    Write-Warning 'Questa operazione elimina i documenti attualmente presenti nella coda di stampa.'
    if((Read-Host 'Confermi? [S/N]') -notmatch '^[SsYy]'){return}
    Stop-Service Spooler -Force -ErrorAction Stop
    $queue=Join-Path $env:SystemRoot 'System32\spool\PRINTERS'
    Get-ChildItem -LiteralPath $queue -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Start-Service Spooler -ErrorAction Stop
    $svc=Get-Service Spooler
    Write-Host ("Spooler: {0}" -f $svc.Status) -ForegroundColor Green
}

function Get-TDTProcessTriage {
    Write-Host "`n[SICUREZZA] Triage processi - sola analisi" -ForegroundColor Cyan
    Write-Host 'ATTENZIONE: un elemento segnalato non equivale a malware.' -ForegroundColor Yellow
    $startupText=((Get-CimInstance Win32_StartupCommand -ErrorAction SilentlyContinue).Command -join "`n")
    $pf86=[Environment]::GetFolderPath('ProgramFilesX86')
    $items=foreach($proc in Get-CimInstance Win32_Process -ErrorAction SilentlyContinue){
      if(-not $proc.ExecutablePath){continue}
      $path=$proc.ExecutablePath; $sig=$null
      try{$sig=Get-AuthenticodeSignature -LiteralPath $path -ErrorAction Stop}catch{}
      $score=0;$reasons=New-Object System.Collections.Generic.List[string]
      $trustedPath=($path -like "$env:SystemRoot\System32\*" -or $path -like "$env:ProgramFiles\*" -or ($pf86 -and $path -like "$pf86\*"))
      if(-not $sig -or $sig.Status -ne 'Valid'){$score+=2;$reasons.Add('firma non valida/assente')}
      if($path -like "$env:TEMP\*" -or $path -like "$env:LOCALAPPDATA\Temp\*"){$score+=3;$reasons.Add('esecuzione da TEMP')}
      elseif($path -like "$env:APPDATA\*" -or $path -like "$env:LOCALAPPDATA\*"){$score+=1;$reasons.Add('esecuzione da profilo utente')}
      if($startupText -and $startupText.IndexOf($path,[StringComparison]::OrdinalIgnoreCase)-ge 0){$score+=1;$reasons.Add('avvio automatico')}
      if($trustedPath -and $sig -and $sig.Status -eq 'Valid'){$score=[math]::Max(0,$score-1)}
      if($score -ge 2){[pscustomobject]@{Score=$score;PID=$proc.ProcessId;Name=$proc.Name;Publisher=if($sig -and $sig.SignerCertificate){$sig.SignerCertificate.Subject}else{''};Signature=if($sig){[string]$sig.Status}else{'Non disponibile'};Path=$path;Reasons=($reasons -join ', ')}}
    }
    $items=@($items|Sort-Object -Property @{Expression='Score';Descending=$true},Name)
    if(-not $items){Write-Host 'Nessun processo con indicatori elementari di attenzione.' -ForegroundColor Green;return @()}
    $items|Format-Table Score,PID,Name,Signature,Reasons -AutoSize
    Write-Host "`nI risultati richiedono verifica tecnica: nessun processo viene terminato o cancellato." -ForegroundColor Yellow
    return $items
}

function Show-TDTTechnicianTools {
    if(-not(Test-TDTAdministrator)){throw 'Gli Strumenti Tecnico richiedono privilegi amministrativi.'}
    do{
      Write-Host "`n=================================================="
      Write-Host ' TECNICO DIGITALE - STRUMENTI RAPIDI' -ForegroundColor Cyan
      Write-Host '=================================================='
      Write-Host ' [1] Diagnostica rete'
      Write-Host ' [2] Pulisci cache DNS'
      Write-Host ' [3] Cambia DNS rapidamente'
      Write-Host ' [4] Riavvia scheda di rete'
      Write-Host ' [5] Reset Spooler / coda di stampa'
      Write-Host ' [6] Triage processi sospetti (read-only)'
      Write-Host ' [0] Torna al menu principale'
      $c=Read-Host 'Scelta'
      try{switch($c){'1'{Invoke-TDTNetworkCheck};'2'{Invoke-TDTFlushDns};'3'{Set-TDTDnsPreset};'4'{Restart-TDTNetworkAdapter};'5'{Reset-TDTPrintSpooler};'6'{Get-TDTProcessTriage|Out-Null};'0'{return};default{Write-Warning 'Scelta non valida.'}}}catch{Write-Warning $_.Exception.Message}
      if($c-ne'0'){Read-Host 'INVIO per continuare'|Out-Null}
    }while($true)
}
