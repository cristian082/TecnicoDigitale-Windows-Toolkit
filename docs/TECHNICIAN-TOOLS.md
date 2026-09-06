# Strumenti Tecnico

`Strumenti-Tecnico.ps1` carica il set operativo completo degli Strumenti Tecnico e il catalogo offline `Comandi del tecnico`. Obiettivo: assistenza su PC Windows 11 sconosciuti con diagnostica ricca, azioni esplicite e un prontuario offline senza dover cercare sul Web i comandi ricorrenti.

## Regole di sicurezza
- Nessuno strumento disabilita Defender, Firewall, UAC o Windows Update.
- Nessun mass-disable di servizi.
- Le analisi non rimuovono software, driver o file utente.
- Le azioni operative sensibili richiedono conferma.
- Nessun riavvio automatico.
- Il catalogo offline non usa `Invoke-Expression` e non valuta come codice il testo proveniente dal JSON.

## Architettura Build 10
Build 10 corregge una regressione d'integrazione del Build 9.

`modules/TechnicianTools.ps1` e stato riportato integralmente all'implementazione completa del Build 8. Il catalogo offline non modifica piu quel file: `modules/TechnicianToolsMenu.ps1` sovrascrive esclusivamente il menu principale aggiungendo la voce 13. In questo modo le funzioni operative Build 8 restano intatte e il catalogo Build 9 rimane separato.

Ordine di caricamento di `Strumenti-Tecnico.ps1`:
1. `modules/TechnicianTools.ps1` — implementazione operativa completa Build 8;
2. `modules/CommandReference.ps1` — catalogo offline;
3. `modules/TechnicianToolsMenu.ps1` — sola integrazione della voce 13.

## Strumenti operativi preservati dal Build 8
TECH-NET-001 — rete: diagnostica rapida e avanzata, configurazione IP, profili rete, route, proxy, porte TCP, DNS e restart adattatore.

TECH-WU-001 — Windows Update: stato servizi, hotfix, ricerca aggiornamenti senza installazione, riparazione cache esplicita e rilevazione reboot pendente anche tramite `PendingFileRenameOperations`.

TECH-REPAIR-001 — DISM CheckHealth/ScanHealth/RestoreHealth, SFC e sequenza DISM + SFC.

TECH-DISK-001 — dischi/SMART/CHKDSK scan, inclusi `Get-StorageReliabilityCounter` quando esposto dal controller.

TECH-PRINT-001 — stampanti, porte usate, spooler e reset coda esplicito.

TECH-SVC-001 — servizi importanti, Automatici fermi con avvertenza trigger-start e restart di un singolo servizio esplicitamente scelto senza cambiare StartType.

TECH-DRV-001 — dispositivi PnP problematici, driver firmati recenti e scansione PnP.

TECH-STARTUP-001 — `Win32_StartupCommand` e task pianificati con trigger Logon, sola lettura.

TECH-EVENT-001 — errori/critici recenti System/Application.

TECH-BITLOCKER-001 — stato BitLocker senza mostrare/esportare recovery key.

TECH-SPACE-001 — spazio volumi e stima TEMP senza cancellazioni.

TECH-PROC-001 — triage processi read-only con firma, percorso, startup e scoring elementare. Un elemento segnalato non equivale a malware.

## TECH-CMD-001 — Comandi del tecnico / catalogo offline
File:
- `data/TechnicianCommands.json`: catalogo dati estendibile di circa 50 comandi;
- `modules/CommandReference.ps1`: UI, ricerca, schede, copia e dispatcher controllato;
- `modules/TechnicianToolsMenu.ps1`: integrazione menu.

Ogni voce contiene ID stabile, categoria, titolo, comando, scopo, attenzioni, impatto, necessita amministratore, reboot e parole chiave.

Funzioni:
- navigazione per categoria;
- ricerca offline per problema/parole chiave;
- scheda descrittiva;
- copia negli appunti;
- esecuzione volontaria solo per ID esplicitamente allowlistati;
- blocco dell'esecuzione diretta dei comandi con segnaposto come `<PID>`;
- per i comandi non presenti nel dispatcher resta disponibile la copia manuale.

### Dispatcher controllato Build 10
`Invoke-Expression` e stato rimosso. Il campo `Command` del JSON viene mostrato e copiato, ma non viene mai valutato come PowerShell.

L'esecuzione diretta passa da `Invoke-TDTReferenceCommandControlled`, che usa uno `switch` sugli ID conosciuti e invoca esplicitamente executable/cmdlet con argomenti fissi. Se un ID non e allowlistato, il Toolkit rifiuta l'esecuzione diretta e propone implicitamente l'uso della funzione Copia.

I comandi MEDIO/ALTO continuano a mostrare l'avvertenza e ogni esecuzione diretta richiede conferma. Le voci che possono richiedere riavvio lo segnalano, ma il Toolkit non riavvia automaticamente Windows.

## Compatibilita
Target: Windows 11, Windows PowerShell 5.1, esecuzione amministrativa. SMART dettagliato, BitLocker, PnP e alcune console dipendono da hardware, driver ed edizione Windows; il tool deve degradare in modo sicuro quando una funzione non e disponibile.

## Smoke test Build 10 prima del PC reale
1. Aggiornare la VM a `v0.1.10 Build 10` usando l'updater.
2. Aprire `Strumenti-Tecnico.ps1` e verificare che le voci 1-13 siano visualizzate su righe separate.
3. Aprire tutti i sottomenu Build 8 e tornare indietro.
4. Verificare pending reboot, SMART/reliability, stampanti/porte, startup + task Logon e triage processi.
5. Aprire voce 13 e verificare caricamento catalogo, categorie e ricerca `stampante`, `wifi`, `boot`, `disco`.
6. Copiare un comando.
7. Eseguire un comando read-only allowlistato, ad esempio `NET-001 ipconfig /all`.
8. Verificare che `SVC-002` con `<PID>` non venga eseguito direttamente.
9. Annullare almeno un comando MEDIO/ALTO e verificare che non venga eseguito.
10. Verificare che nel modulo non sia presente `Invoke-Expression`.
11. Nessuna funzione deve riavviare automaticamente Windows o modificare Defender/Firewall/UAC/Windows Update policy.

Dopo questo smoke test, Build 10 puo passare al primo test hardware reale sul PC personale prima dell'uso su PC cliente.
