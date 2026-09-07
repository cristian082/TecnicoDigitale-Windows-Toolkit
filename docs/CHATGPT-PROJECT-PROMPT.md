# Prompt di continuità progetto – TecnicoDigitale Windows Toolkit

Repository: `cristian082/TecnicoDigitale-Windows-Toolkit`.

Sto sviluppando con ChatGPT un Toolkit Windows 11 per tecnici informatici, pensato come coltellino svizzero per PC cliente: diagnostica, manutenzione, ottimizzazione sicura, pulizia/riparazione, rete, stampanti, dischi/hardware, software separato, Backup/Undo, strumenti tecnici e report prima/dopo.

## Filosofia non negoziabile
Il Toolkit deve essere sicuro anche su PC sconosciuti. Non deve disabilitare Defender, Firewall, Windows Update, UAC o pagefile; niente mass-disable servizi, tweak HPET/timer/scheduler/core parking/TCP casuali, rotture Edge/WebView2/rete/stampanti/audio/Bluetooth, cancellazioni Office/utenti, registry cleaning aggressivo o tweak placebo.

> Il Toolkit non applica una modifica che non sappiamo spiegare. Se una modifica non produce un beneficio concreto, documentiamo il motivo e non la applichiamo.

## Metodo di lavoro obbligatorio
- GitHub e la fonte di verita: leggere sempre il file live prima di modificarlo.
- Compatibilita Windows PowerShell 5.1.
- Ogni modifica deve essere documentata e tecnicamente giustificabile.
- Dopo ogni modifica indicare il commit SHA.
- Ogni build testabile/distribuita incrementa `version` e `build`.
- Non patchare alla cieca: raccogliere evidenze dal test/errore, poi correggere.
- Non riscrivere un modulo funzionante quando basta una modifica minima/integration layer.

## Versione corrente
`v0.1.12 - Build 12 [development]`.

L'updater e operativo ed e stato usato con successo per aggiornare le build in VM. Il proprietario riferisce che l'aggiornamento funziona benissimo. Non modificare l'updater senza una ragione concreta e un test mirato.

## Preset e transizioni
STANDARD = velocita sicura/base comune per PC sconosciuti.
GAMING = Standard + estensioni Gaming sensate.
BUSINESS = Standard + affidabilita/strumenti utili in ambiente lavoro.
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

Risultati gia ottenuti:
- Standard → Gaming: PASS.
- Gaming → Business: PASS; valori Gaming ripristinati allo stato precedente.
- Business: Start a sinistra PASS.
- Business → Standard: PASS immediato; Start centrato, `TaskbarAl` rimosso quando originariamente assente, `GameDVR_Enabled=1`, nessun residuo Gaming.

### Bug TaskbarAl / Active Setup corretto in Build 7
Un vecchio Active Setup HKLM poteva riapplicare `TaskbarAl=0` al login successivo. Build 7 ha spostato TaskbarAl Business sul solo utente corrente/ProfileState e aggiunto cleanup deterministico del vecchio componente del Toolkit senza toccare Active Setup estranei.

Commit principali Build 7:
- `d2bde95c5d3d971a244f4a0e58be5bf69445d3a6` — cleanup Active Setup.
- `2fc24aa03037abd7be212cb4dd298b5c02754763` — TaskbarAl utente corrente + migrazione.
- `0169570746d7b346a5996fc1f16097424066dae6` — versione Build 7.

Il retest Standard immediato e risultato corretto. Prima della certificazione definitiva cliente resta utile confermare ancora il comportamento dopo logout/login o riavvio.

## Visual Effects Build 6
Alleggerimento conservativo comune ai preset, senza `UserPreferencesMask` globale:
- VISUAL-001: animazione minimizza/massimizza disattivata.
- VISUAL-002: animazioni taskbar disattivate.
- VISUAL-003: `MenuShowDelay=100`.

Restano intatti font smoothing, miniature, ombre e trasparenze. Non attribuire a queste modifiche guadagni miracolosi di RAM/FPS.

## Icone Desktop
Standard/Gaming: Questo PC, File utente, Cestino; Rete e Pannello di controllo nascosti.
Business: aggiunge Rete e Pannello di controllo.
Sono namespace Windows via `HideDesktopIcons`, non `.lnk`.

## Backup/Undo
`modules/Backup.ps1` crea sessioni JSON `backups/Session-YYYYMMDD-HHMMSS.json` e salva lo stato Registry una sola volta per sessione. Le modifiche Gaming/Business gestite dal ProfileState passano anche dal backup Registry.

Gap noti:
- Active Setup non completamente coperto dall'Undo;
- Undo servizi futuro;
- alcune azioni non-registry non hanno rollback completo;
- UX selezione sessione migliorabile.

## Software
I preset non installano software. `Installa-Software.ps1` e separato. Software selezionabili: Chrome, Firefox, VLC, WinRAR, 7-Zip, Everything, Adobe Reader, SumatraPDF, Steam, Playnite, Microsoft PowerToys.

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
Usare `lab/Deep-Audit.ps1`, `Compare-Baseline.ps1`, `Services-Audit.ps1`, `Compare-Services.ps1` e baseline `Windows11-Pro-Clean-Before-Standard.json`. LTSC e stato rimosso dal flusso operativo.

## Strumenti Tecnico Build 8
Build 8 ha introdotto il menu tecnico completo con 12 aree: rete, Windows Update, DISM/SFC, dischi/SMART/CHKDSK, stampanti, servizi, driver/PnP, startup, eventi, BitLocker, spazio/TEMP, triage processi.

Funzioni importanti da NON perdere: `PendingFileRenameOperations` nel pending reboot, `Get-StorageReliabilityCounter`, porte stampanti, task Logon, driver firmati recenti, servizi importanti, triage processi con firma/percorso/startup/scoring.

Commit Build 8:
- `e5d25ad71816b4dfecbc5df4827339735cf192b6` — menu tecnico completo.
- `1e6a11a01063bf934233129208f96f4b1498aab0` — documentazione.
- `a35c1a0ee5bc7453da2f71b1645fbf0b9c2caca1` — v0.1.8 Build 8.

## Build 9 — catalogo offline
Build 9 ha introdotto `data/TechnicianCommands.json` e `modules/CommandReference.ps1`, con circa 50 comandi organizzati per categorie, ricerca offline, scheda, copia ed esecuzione volontaria.

Durante l'integrazione Build 9 `modules/TechnicianTools.ps1` era stato accidentalmente reimplementato in forma compressa, perdendo dettagli del Build 8. Inoltre `CommandReference.ps1` usava `Invoke-Expression`. Questi problemi sono stati corretti nel Build 10.

## Build 10 — correzione regressione Strumenti Tecnico
Build 10 e la versione corrente.

Correzioni effettuate:
1. `modules/TechnicianTools.ps1` e stato riportato ESATTAMENTE al blob completo del Build 8 (`ea359ecfabc79e1d743dfd7f92d2019de0e5661c`), recuperando tutte le funzioni/dettagli persi.
2. Creato `modules/TechnicianToolsMenu.ps1`: integration layer che sovrascrive soltanto `Show-TDTTechnicianTools` e aggiunge la voce 13, senza riscrivere le funzioni operative Build 8.
3. `Strumenti-Tecnico.ps1` carica nell'ordine: TechnicianTools → CommandReference → TechnicianToolsMenu.
4. `Invoke-Expression` eliminato da `CommandReference.ps1`.
5. L'esecuzione del catalogo usa `Invoke-TDTReferenceCommandControlled`: dispatcher con `switch` e allowlist di ID. Il testo `Command` proveniente dal JSON non viene mai valutato come codice.
6. Comandi non allowlistati restano consultabili/copiabili ma non eseguibili direttamente.
7. Segnaposto come `<PID>` bloccano l'esecuzione diretta.
8. MEDIO/ALTO continuano a mostrare avvertenza e tutte le esecuzioni richiedono conferma.
9. Menu su righe separate: eliminato il problema potenziale dei newline letterali del Build 9.
10. Versione incrementata a `v0.1.10 Build 10`.

Commit Build 10:
- `07a2a68d10e6212d95c1ca57f20fc2923175778a` — ripristino completo TechnicianTools Build 8.
- `46745029c15a1b1b7a70dcee95135cc56a32faa6` — integration layer menu voce 13.
- `6229f87ad3f5b4b048d66f6ea00ddc70ef1014fd` — load order launcher.
- `fb3f34de56cab77d44c7ca79af3dd89ef4cb9dab` — rimozione Invoke-Expression + dispatcher controllato.
- `1d13bafe2144da9a2a7cb572354681fc6d4edc9f` — v0.1.10 Build 10.
- `243331758974c8fb164ae34e0b38e479eea496ab` — documentazione Build 10.

Gap ancora aperto negli Strumenti Tecnico: il restart manuale di un servizio del Build 8 usa ancora `Restart-Service -Force`; rivalutarlo in futuro, ma non e stato modificato nel Build 10 per evitare cambi non necessari prima del test reale.

## Stato attuale dei test — Build 10 VM PASS
Il 06/09/2026 Build 10 e stata aggiornata ed eseguita nella VM. Smoke test mirato: PASS.

Verificato realmente:
- `Strumenti-Tecnico.ps1` si apre senza errori visibili;
- menu principale completo con voci 1-12 Build 8 + voce 13 `Comandi del tecnico - catalogo offline`;
- formattazione corretta, nessun newline letterale visibile;
- voce 13 carica correttamente il catalogo: 49 comandi, 16 categorie;
- UI dichiara `Esecuzione: solo dispatcher controllato; nessun Invoke-Expression`;
- navigazione del catalogo funzionante;
- `NET-001 - Configurazione IP completa` (`ipconfig /all`) viene eseguito correttamente dal dispatcher solo dopo conferma esplicita;
- `SVC-002 - Processo da PID`, contenente `<PID>`, mostra `Esecuzione diretta non disponibile`: il comando parametrico non puo essere lanciato accidentalmente e resta copiabile;
- nessun errore PowerShell osservato durante questo smoke test.

Questo PASS certifica l'integrazione critica Build 10 verificata sopra; non implica che ogni singola funzione dei 49 comandi o ogni ramo degli Strumenti Tecnico sia stato eseguito in VM.

L'updater continua a funzionare correttamente.

## Build 11 — Widget lasciati invariati dopo test reale
Il 07/09/2026 e stato completato il primo test reale STANDARD su Windows 11 Pro build `26200.9278`, PC personale con 32 GB RAM.

Baseline PRIMA → DOPO il riavvio:
- processi: 161 → 150;
- RAM fisica usata: 3873 → 3424 MB;
- startup: 9 → 9;
- servizi running: 109 → 103;
- AppX provisioned: 55 → 55;
- nessun programma, AppX, feature, capability, task pianificato o StartMode servizio modificato in modo strutturale.

Le differenze di RAM, processi e servizi erano variazioni runtime dopo il riavvio e non devono essere presentate come guadagni certi del Toolkit.

Verifiche manuali PASS:
- Start centrato;
- icone desktop Standard corrette;
- Esplora file su Questo PC ed estensioni visibili;
- `Termina attivita` presente sulla taskbar;
- rete, audio, stampanti configurate, Windows Update, Defender, Firewall, Edge, WebView2 e software principali funzionanti;
- Bluetooth non applicabile per assenza hardware.

Problema reale trovato:
- `AllowNewsAndInterests=0` su `HKLM\SOFTWARE\Policies\Microsoft\Dsh` ha restituito accesso negato e il Widget e rimasto visibile;
- anche `TaskbarDa=0` su `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced` ha restituito accesso negato sia da prompt elevato sia non elevato;
- l'interfaccia ufficiale di Windows ha invece disattivato il Widget e creato `TaskbarDa=0`;
- nascondere il Widget e una preferenza estetica senza beneficio prestazionale dimostrato, quindi non giustifica forzature di ACL, TrustedInstaller, rimozioni AppX o un Undo incompleto.

Decisione Build 11:
- rimosso `HideWidgets` dai preset Standard, Gaming e Business;
- rimosso dal modulo Start/Taskbar il tentativo di scrittura della policy macchina;
- i Widget restano nello stato scelto dall'utente;
- documentazione aggiornata;
- versione incrementata a `v0.1.11 Build 11`.

Retest mirato Build 11 sul PC personale: PASS. STANDARD e terminato senza l'avviso `AllowNewsAndInterests` e ha conservato lo stato Widget scelto manualmente dall'utente.

## Build 12 — Microsoft PowerToys nel catalogo software
- aggiunto `Microsoft PowerToys` come voce 11 del menu `INSTALLA SOFTWARE`;
- ID winget ufficiale: `Microsoft.PowerToys`;
- resta una scelta individuale e non entra nei pacchetti rapidi PC NUOVO o GAMING;
- nessun preset installa PowerToys automaticamente;
- versione incrementata a `v0.1.12 Build 12`.

## Prossimo test sul PC personale
1. aggiornare il Toolkit a `v0.1.12 Build 12`;
2. aprire `INSTALLA SOFTWARE` e verificare che PowerToys appaia come voce 11, inizialmente non selezionata;
3. testare volontariamente installazione o aggiornamento PowerToys e verificarne l'esito;
4. testare `Standard → Business → Standard`;
5. dopo il ritorno a Standard, verificare `TaskbarAl` anche dopo riavvio/login per chiudere definitivamente il vecchio bug Active Setup.

Gaming va usato come test reale solo se il PC viene effettivamente usato anche per gaming.

## Prossimo lavoro nella nuova chat
NON ricreare Build 12: contiene la correzione Widget verificata e PowerToys nel catalogo software.

Partire cosi:
1. leggere questo file e `VERSION.json` live;
2. aggiornare il PC personale a Build 12;
3. verificare la voce PowerToys ed eventualmente provarne l'installazione;
4. provare `Standard → Business → Standard` e verificare reversibilita dopo riavvio/login;
5. documentare i risultati prima di considerare il Toolkit pronto per PC cliente.
