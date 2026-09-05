# Strumenti Tecnico

`Strumenti-Tecnico.ps1` carica `modules/TechnicianTools.ps1` e apre un menu separato dai preset. Gli strumenti sono pensati per assistenza tecnica su PC Windows 11 sconosciuti: diagnostica prima, azioni di riparazione solo esplicite e confermate.

## Regole di sicurezza

- Nessuno strumento disabilita Defender, Firewall, UAC o Windows Update.
- Nessuno strumento modifica tipi di avvio dei servizi in massa.
- Le funzioni di analisi non rimuovono driver, processi, software o file utente.
- Le operazioni che interrompono temporaneamente servizi, cancellano code o riparano componenti richiedono conferma.
- Nessun riavvio viene eseguito automaticamente.
- I comandi DISM/SFC/CHKDSK usano gli strumenti Microsoft inclusi in Windows.

## Menu principale

### TECH-NET-001 — Rete
Comprende diagnostica rapida, diagnostica avanzata, flush DNS, cambio DNS e riavvio esplicito di una scheda. La diagnostica avanzata mostra adattatori, configurazione IP, profili rete, route predefinite, proxy WinHTTP e prime porte TCP in ascolto.

Rischio: basso. Il cambio DNS e il riavvio della scheda modificano temporaneamente la connettivita e sono azioni volontarie.

### TECH-WU-001 — Windows Update
Mostra stato dei servizi Windows Update/BITS/UsoSvc/CryptSvc, presenza di riavvio pendente e ultimi hotfix. La ricerca aggiornamenti usa Windows Update Agent e non installa automaticamente nulla.

La riparazione cache ferma temporaneamente BITS, Windows Update e CryptSvc, rinomina `SoftwareDistribution` e `catroot2`, quindi riavvia i servizi. Non modifica policy Windows Update.

Rischio: medio solo per la riparazione cache; richiede conferma.

### TECH-REPAIR-001 — Integrita Windows / DISM / SFC
Azioni disponibili:
- `DISM /Online /Cleanup-Image /CheckHealth`
- `DISM /Online /Cleanup-Image /ScanHealth`
- `DISM /Online /Cleanup-Image /RestoreHealth`
- `SFC /scannow`
- sequenza completa RestoreHealth + SFC.

CheckHealth/ScanHealth sono diagnostici; RestoreHealth/SFC possono modificare file/componenti Windows corrotti e richiedono conferma. Nessun riavvio automatico.

### TECH-DISK-001 — Dischi / SMART / CHKDSK
Mostra `Get-PhysicalDisk`, stato salute, tipo bus/media e, se il controller li espone, contatori di affidabilita/SMART. Fallback CIM se Storage Spaces non espone i dischi.

`CHKDSK /scan` viene eseguito solo sul volume scelto dal tecnico e non pianifica automaticamente correzioni offline.

### TECH-PRINT-001 — Stampanti
Mostra stampanti, driver, porte e stato Spooler. Il reset Spooler elimina i job presenti nella coda e richiede conferma.

### TECH-SVC-001 — Servizi
Mostra lo stato di servizi importanti e i servizi con StartType Automatic attualmente fermi. Non presume che ogni Automatico fermo sia un errore, perche alcuni servizi sono trigger-start.

Permette di riavviare un singolo servizio digitandone esplicitamente il nome e confermando. Non modifica StartType.

### TECH-DRV-001 — Driver / dispositivi
Mostra dispositivi PnP con stato diverso da OK e un riepilogo dei driver firmati piu recenti. La scansione PnP usa `pnputil /scan-devices` e non rimuove driver.

### TECH-STARTUP-001 — Avvio automatico
Sola analisi. Mostra `Win32_StartupCommand` e fino a 30 attivita pianificate con trigger Logon. Nessun elemento viene disabilitato automaticamente.

### TECH-EVENT-001 — Eventi Windows
Sola analisi. Mostra eventi Critici/Errori delle ultime 24 ore dai log System e Application, fino a 30 per log.

### TECH-BITLOCKER-001 — BitLocker
Sola analisi. Mostra stato cifratura/protezione tramite `Get-BitLockerVolume` o fallback `manage-bde -status`. Non mostra, esporta o modifica chiavi di ripristino.

### TECH-SPACE-001 — Spazio disco
Sola analisi. Mostra capacita, spazio libero e percentuale libera dei volumi; calcola una stima delle cartelle TEMP dell'utente e di Windows. Non cancella file.

### TECH-PROC-001 — Triage processi
Sola analisi. Assegna indicatori elementari in base a firma digitale, percorso TEMP/AppData e presenza all'avvio. Un punteggio non equivale a malware. Nessun processo viene terminato o cancellato.

## Compatibilita e test

Target: Windows 11, Windows PowerShell 5.1, esecuzione amministrativa. Alcune informazioni (SMART dettagliato, BitLocker cmdlet, PnP) dipendono da hardware, driver ed edizione Windows; in caso di dati non esposti il tool deve degradare in modo sicuro mostrando informazioni parziali o un avviso.

Prima dell'uso su PC cliente, testare la build in VM almeno su: apertura di ogni sottomenu, funzioni read-only, annullamento delle conferme e una sequenza controllata DISM/SFC/Windows Update cache su snapshot sacrificabile.
