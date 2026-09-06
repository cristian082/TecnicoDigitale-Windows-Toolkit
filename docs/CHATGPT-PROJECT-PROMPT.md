# Prompt di continuità progetto – TecnicoDigitale Windows Toolkit

Repository: `cristian082/TecnicoDigitale-Windows-Toolkit`.

Sto sviluppando con ChatGPT un Toolkit Windows 11 per tecnici informatici, pensato come coltellino svizzero per PC cliente: diagnostica, manutenzione, ottimizzazione sicura, pulizia/riparazione, rete, stampanti, dischi/hardware, software separato, Backup/Undo, strumenti tecnici e report prima/dopo.

## Filosofia non negoziabile
Il Toolkit deve essere sicuro anche su PC sconosciuti. Non deve disabilitare Defender, Firewall, Windows Update, UAC o pagefile; niente mass-disable servizi, tweak HPET/timer/scheduler/core parking/TCP casuali, rotture Edge/WebView2/rete/stampanti/audio/Bluetooth, cancellazioni Office/utenti, registry cleaning aggressivo o tweak placebo.

> Il Toolkit non applica una modifica che non sappiamo spiegare. Se una modifica non produce un beneficio concreto, documentiamo il motivo e non la applichiamo.

## Metodo di lavoro obbligatorio
- GitHub è la fonte di verità: prima di modificare un file, leggere sempre la versione live corrente.
- Compatibilità Windows PowerShell 5.1.
- Ogni modifica deve essere documentata e tecnicamente giustificabile.
- Dopo ogni modifica indicare il commit SHA.
- Ogni build testabile/distribuita incrementa `version` e `build`, così locale e remoto sono distinguibili.
- Non patchare alla cieca: prima raccogliere evidenze dal test/errore, poi correggere.

## Versione corrente
`v0.1.9 - Build 9 [development]`.

L'updater è operativo e nei test reali sta funzionando molto bene: il Toolkit riesce ad aggiornarsi correttamente alle nuove build. Non modificare l'updater senza una ragione concreta e un test mirato.

## Preset e transizioni
STANDARD = velocità sicura/base comune per PC sconosciuti.
GAMING = Standard + estensioni Gaming sensate.
BUSINESS = Standard + affidabilità/strumenti utili in ambiente lavoro.
PERSONALIZZATA/AVANZATA = futura.

Regola fondamentale: deve essere possibile passare da qualunque preset a qualunque altro, ad esempio `Standard → Gaming → Business → Standard`, senza formattare, senza residui incompatibili e senza sovrascrivere ciecamente preferenze preesistenti del cliente.

Le impostazioni specifiche di profilo sono possedute temporaneamente dal Toolkit: quando si esce dal profilo vengono ripristinate al valore precedente solo se sono ancora al valore applicato dal Toolkit. Se nel frattempo utente/app le hanno cambiate, il Toolkit non deve sovrascriverle e deve avvisare.

Undo resta per-esecuzione: ripristina lo stato precedente alla singola esecuzione, non significa “torna a Standard”.

## ProfileState
`modules/ProfileState.ps1` usa `backups/ProfileState.json`.

Gaming gestisce/ripristina:
- `HKCU\Software\Microsoft\GameBar\AutoGameModeEnabled`
- `HKCU\Software\Microsoft\GameBar\AllowAutoGameMode`
- `HKCU\System\GameConfigStore\GameDVR_Enabled`

Business gestisce/ripristina:
- `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarAl`

## Matrice funzionale testata in VM
VM: Windows 11 Pro build 26200, VirtualBox, circa 8 GB RAM.

Risultati:
- Standard → Gaming: PASS.
- Gaming → Business: PASS; valori Gaming ripristinati allo stato precedente.
- Business: Start a sinistra PASS.
- Business → Standard: PASS immediato; Start centrato, `TaskbarAl` rimosso quando originariamente assente, `GameDVR_Enabled=1`, nessun residuo Gaming.

### Bug TaskbarAl / Active Setup corretto in Build 7
Dopo un login successivo Start poteva tornare a sinistra nonostante Standard fosse stato applicato correttamente. Causa: vecchio `Set-TDTUserDword` con `AllUsers=true` registrava Active Setup HKLM per `TaskbarAl=0`, che poteva rieseguire la modifica al login fuori dal ProfileState.

Build 7:
- Business applica `TaskbarAl` solo all'utente corrente (`AllUsers=false`), gestito dal ProfileState;
- helper per individuare/rimuovere esclusivamente l'Active Setup deterministico del Toolkit;
- migrazione del vecchio residuo `TaskbarAl=0` con backup;
- nessuna rimozione di componenti Active Setup estranei.

Commit principali Build 7:
- `d2bde95c5d3d971a244f4a0e58be5bf69445d3a6` — cleanup Active Setup.
- `2fc24aa03037abd7be212cb4dd298b5c02754763` — TaskbarAl utente corrente + migrazione.
- `0169570746d7b346a5996fc1f16097424066dae6` — versione Build 7.

Il retest Standard immediato è risultato corretto. Prima della certificazione definitiva cliente resta utile confermare ancora il comportamento dopo logout/login o riavvio.

## Visual Effects Build 6
Alleggerimento conservativo comune ai preset, senza `UserPreferencesMask` globale:
- VISUAL-001: animazione minimizza/massimizza disattivata.
- VISUAL-002: animazioni taskbar disattivate.
- VISUAL-003: `MenuShowDelay=100`.

Restano intatti font smoothing, miniature, ombre e trasparenze. Non attribuire a queste modifiche guadagni miracolosi di RAM/FPS.

## Icone Desktop
Standard/Gaming: Questo PC, File utente, Cestino; Rete e Pannello di controllo nascosti.
Business: aggiunge Rete e Pannello di controllo.
Sono namespace Windows via `HideDesktopIcons`, non collegamenti `.lnk`.

## Backup/Undo
`modules/Backup.ps1` crea sessioni JSON in `backups/Session-YYYYMMDD-HHMMSS.json` e salva lo stato Registry una sola volta per sessione. Le modifiche Gaming/Business gestite dal ProfileState passano anche dal backup Registry.

Gap noti:
- Active Setup non è ancora completamente coperto dall'Undo;
- Undo servizi futuro;
- migliorare UX selezione sessione;
- alcune azioni non-registry non hanno ancora rollback completo.

## Software
I preset non installano software. `Installa-Software.ps1` è separato. Software selezionabili: Chrome, Firefox, VLC, WinRAR, 7-Zip, Everything, Adobe Reader, SumatraPDF, Steam, Playnite.

## Standard baseline
Primo test pulito Standard sulla VM:
- processi 140 → 132;
- RAM fisica 2886 → 2709 MB (-177 MB);
- startup 6 → 6;
- servizi running 88 → 88;
- Edge/WebView 16 → 13;
- Edge/WebView working set circa -92 MB;
- AppX provisioned 47 → 47;
- feature 14 → 14;
- capability 47 → 47;
- nessun programma installato/rimosso.

BITS/MDCoreSvc mostrarono differenze runtime, ma non risultano modifiche intenzionali Standard nel codice.

## Lab
Strumenti principali: `lab/Deep-Audit.ps1`, `Compare-Baseline.ps1`, `Services-Audit.ps1`, `Compare-Services.ps1` e baseline `Windows11-Pro-Clean-Before-Standard.json`. LTSC è stato rimosso dal flusso operativo.

## Strumenti Tecnico Build 8
Build 8 ha trasformato `Strumenti-Tecnico.ps1` in un menu tecnico a categorie:
1. Rete
2. Windows Update
3. Integrità Windows - DISM / SFC
4. Dischi / SMART / CHKDSK
5. Stampanti
6. Servizi
7. Driver / dispositivi
8. Avvio automatico read-only
9. Eventi Windows recenti
10. BitLocker read-only
11. Spazio disco / TEMP read-only
12. Triage processi sospetti read-only

Funzioni Build 8: diagnostica rete rapida/avanzata, DNS, restart adattatore; stato/ricerca/riparazione cache Windows Update; DISM/SFC; SMART/StorageReliabilityCounter/CHKDSK scan; stampanti/driver/porte/spooler; servizi importanti e restart singolo esplicito senza cambiare StartType; PnP/driver; startup e task Logon; eventi Critical/Error; stato BitLocker senza recovery key; spazio/TEMP senza cancellazione; triage processi read-only.

Commit Build 8:
- `e5d25ad71816b4dfecbc5df4827339735cf192b6` — menu tecnico completo.
- `1e6a11a01063bf934233129208f96f4b1498aab0` — documentazione.
- `a35c1a0ee5bc7453da2f71b1645fbf0b9c2caca1` — v0.1.8 Build 8.

## Build 9 — Comandi del tecnico offline
Build 9 introduce un prontuario offline per evitare di dover ricordare o cercare sul Web i comandi ricorrenti durante un intervento.

File principali:
- `data/TechnicianCommands.json` — catalogo di circa 50 comandi con ID, categoria, titolo, comando, scopo, controindicazioni, impatto, admin, reboot e keyword.
- `modules/CommandReference.ps1` — navigazione, ricerca, scheda descrittiva, copia ed esecuzione volontaria.
- `Strumenti-Tecnico.ps1` — carica CommandReference + TechnicianTools.
- voce 13 del menu: `Comandi del tecnico - catalogo offline`.

Categorie: Windows/riparazione, rete/Internet/DNS, stampanti, dischi/file system, driver/hardware, utenti/account, servizi/processi, Windows Update, boot/BCD, SMB/condivisioni/RDP, energia/batteria, app/Winget/Store, BitLocker, log/Event Viewer, Firewall e informazioni PC.

Sicurezza prevista: segnaposto come `<PID>` non devono essere eseguiti direttamente; azioni MEDIO/ALTO richiedono conferma; nessun comando deve contraddire la filosofia del Toolkit.

Commit Build 9:
- `b2e452000961c4bc6d1cf9d0584460aade876200` — catalogo JSON.
- `beaa9040dc7107c32e333a13bf2ad5ff23e751d3` — CommandReference.
- `aa592401ff194c9dabd6239127ff3fdfec6c8a68` — launcher Strumenti Tecnico.
- `29bb2cc05acf68b398f1ad45456b3a02e6a1180f` — integrazione voce 13.
- `f344777c4c7c83910dff7e475329964b8fe67dca` — v0.1.9 Build 9.
- `5a954837327d2cdcaa1704fb0b49e81ceea93ac1` — documentazione Build 9.

### Audit necessario prima di considerare Build 9 pronta per PC cliente
Durante l'integrazione Build 9 `modules/TechnicianTools.ps1` è stato reimplementato/compresso invece di ricevere una modifica minima sopra il Build 8. Prima dell'uso reale va quindi confrontato con il Build 8 e ripristinata ogni funzione/dettaglio perso. In particolare verificare: PendingFileRenameOperations, StorageReliabilityCounter, dettagli stampanti/driver/porte, task Logon, scoring triage processi e messaggi/guardie.

Inoltre:
- controllare eventuali stringhe menu con newline letterali dovuti alle virgolette singole;
- `CommandReference.ps1` usa attualmente `Invoke-Expression`: sostituirlo con un dispatcher controllato prima dell'uso su PC cliente;
- rivalutare `Restart-Service -Force` per il restart manuale dei servizi;
- mantenere il catalogo offline, ma separare chiaramente copia del comando ed esecuzione sicura.

Questa correzione dovrà diventare la prossima build testabile: `v0.1.10 - Build 10`, mantenendo integralmente le capacità Build 8 e aggiungendo Build 9 in modo minimale e sicuro.

## Stato test reale / prossimo passo
L'updater è stato usato con successo ed è considerato operativo.

Resta da provare il Toolkit sul PC personale del proprietario prima di passare a PC cliente. Non usare Build 9 sul PC personale finché non è stato completato l'audit/correzione sopra e fatto almeno uno smoke test in VM della Build 10.

Dopo Build 10 + smoke test VM, il PC personale sarà il primo test hardware reale. Il profilo da scegliere va deciso in base all'uso effettivo del PC:
- Standard se si vuole validare la base sicura e più rappresentativa dei PC cliente;
- Business se è soprattutto una workstation di lavoro e si vuole validare anche l'estensione Business;
- Gaming solo se il PC viene realmente usato anche per gaming e si vogliono testare quelle estensioni.

Per massimizzare il valore del test, partire da diagnostica/baseline prima, creare punto di ripristino, applicare il profilo scelto, riavviare, ripetere diagnostica e confrontare. Successivamente testare il passaggio a un altro preset e il ritorno a Standard per verificare la reversibilità su hardware reale.

## Prossimo lavoro consigliato nella nuova chat
1. Leggere i file live prima di modificarli.
2. Creare Build 10 correggendo l'integrazione Build 9 senza perdere nulla del Build 8.
3. Eliminare `Invoke-Expression` dal CommandReference con esecuzione controllata.
4. Aggiornare documentazione e questo prompt di continuità.
5. Smoke test Build 10 in VM.
6. Solo dopo, test sul PC personale con baseline prima/dopo e prova di transizione preset.
