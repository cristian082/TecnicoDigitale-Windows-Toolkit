# Strumenti Tecnico

`Strumenti-Tecnico.ps1` carica il set operativo completo degli Strumenti Tecnico, il catalogo offline `Comandi del tecnico` e lo strumento manuale per ibernazione e `hiberfil.sys`. Obiettivo: assistenza su PC Windows 11 sconosciuti con diagnostica ricca, azioni esplicite e un prontuario offline senza dover cercare sul Web i comandi ricorrenti.

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
3. `modules/HibernationTools.ps1` — stato e gestione volontaria dell'ibernazione;
4. `modules/PrinterToolsExtension.ps1` — estensione isolata del sottomenu Stampanti;
5. `modules/TechnicianToolsMenu.ps1` — integrazione delle voci aggiuntive 13 e 14.

## Strumenti operativi preservati dal Build 8
TECH-NET-001 — rete: diagnostica rapida e avanzata, configurazione IP, profili rete, route, proxy, porte TCP, DNS e restart adattatore.

TECH-WU-001 — Windows Update: stato servizi, hotfix, ricerca aggiornamenti senza installazione, riparazione cache esplicita e rilevazione reboot pendente anche tramite `PendingFileRenameOperations`.

TECH-REPAIR-001 — DISM CheckHealth/ScanHealth/RestoreHealth, SFC e sequenza DISM + SFC.

TECH-DISK-001 — dischi/SMART/CHKDSK scan, inclusi `Get-StorageReliabilityCounter` quando esposto dal controller.

TECH-PRINT-001 — stampanti, porte usate, spooler e reset coda esplicito.

Build 16 estende il sottomenu Stampanti senza riscrivere il modulo operativo Build 8. Sono disponibili: diagnostica completa di stampanti/driver/porte/Spooler, elenco read-only dei documenti in coda, pagina di prova su stampante selezionata, apertura delle interfacce moderna/classica/Print Management e reset controllato della coda.

Il reset mostra prima i documenti, richiede conferma e tenta inizialmente l'arresto normale dello Spooler. Se questo fallisce, mostra l'errore e offre un secondo tentativo con `-Force`, soggetto a un'ulteriore conferma esplicita. I file nella directory di spool vengono eliminati solo dopo aver verificato che il servizio sia realmente fermo; infine viene ripristinato e verificato lo stato precedente. La pagina di prova richiede selezione e conferma esplicite. DISM e SFC non vengono avviati come presunta riparazione universale della stampa.

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

Build 14 aggiunge `APP-004 - Tutte le applicazioni (AppsFolder)`: il catalogo ricorda il comando rapido `shell:AppsFolder` e il dispatcher controllato lo apre tramite `explorer.exe`. La voce e read-only, non richiede privilegi amministrativi e facilita anche la creazione manuale di collegamenti sul desktop.

Build 15 estende lo stesso gruppo con nove scorciatoie Shell selezionate: Avvio automatico utente e comune, Invia a, Elementi recenti, Download, Cestino, Caratteri, Stampanti e Risorse di rete. Il dispatcher passa ogni destinazione come argomento fisso a `explorer.exe`; nessun testo del catalogo viene valutato come codice.

## TECH-POWER-001 — Ibernazione e hiberfil.sys
La voce 14 e separata dai preset e non applica modifiche all'apertura. Mostra se `hiberfil.sys` e presente, la sua dimensione, lo spazio libero sul disco di sistema e, su richiesta, l'output read-only di `powercfg /a`.

La disattivazione usa esclusivamente `powercfg /hibernate off` dopo la conferma testuale `DISATTIVA`. Il Toolkit avverte che vengono disabilitati Ibernazione, Sospensione ibrida e Avvio rapido; la sospensione S3 resta disponibile soltanto quando supportata dall'hardware. La riattivazione usa `powercfg /hibernate on` dopo la conferma `ATTIVA` e avverte che `hiberfil.sys` verra ricreato occupando spazio.

Dopo ogni modifica viene controllata la presenza o assenza di `hiberfil.sys`. Nessun riavvio viene eseguito. La modifica non fa parte dell'Undo per-sessione: la stessa schermata offre l'azione inversa esplicita.

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
