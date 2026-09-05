# Prompt di continuità progetto – TecnicoDigitale Windows Toolkit

Copia e incolla questo prompt in una nuova chat ChatGPT per riprendere il progetto senza ricostruire il contesto.

---

Sto sviluppando con te il repository GitHub:

`cristian082/TecnicoDigitale-Windows-Toolkit`

Il progetto si chiama **TecnicoDigitale Windows Toolkit** ed è un toolkit Windows 11 per tecnici informatici, pensato come un “coltellino svizzero” per PC cliente: diagnostica, manutenzione, ottimizzazione sicura, pulizia, riparazione Windows, rete, stampanti, dischi/hardware, software/bloatware, strumenti rapidi, backup/Undo e report prima/dopo.

## Filosofia generale

Il Toolkit deve essere sicuro anche su PC sconosciuti.

NON deve:

- disabilitare Microsoft Defender;
- disabilitare Windows Firewall;
- disabilitare Windows Update;
- disabilitare UAC;
- disabilitare il pagefile;
- fare mass-disable dei servizi;
- applicare tweak HPET/timer/scheduler/core parking;
- applicare tweak TCP casuali;
- rompere Edge/WebView2;
- rompere rete, stampanti, audio o Bluetooth;
- cancellare software scelto o usato dall'utente senza elevata certezza che sia bloat/promozionale;
- usare registry cleaner, RAM cleaner o “optimizer” placebo.

Principio del progetto:

> Il Toolkit non applica una modifica che non sappiamo spiegare. E se una modifica non produce un beneficio concreto, documentiamo il motivo e non la applichiamo.

Flusso ideale:

`Diagnostica → Backup/Undo → Restore Point → ottimizzazione sicura → software opzionale separato → riparazione → report finale`

## Metodo di lavoro obbligatorio

Quando lavori su questo progetto:

- usa il repository GitHub come fonte di verità;
- **prima di modificare un file, leggine sempre la versione corrente dalla repo**;
- non basarti solo su questo prompt se il codice live è diverso;
- dopo ogni modifica al repository, indica il commit SHA;
- quando trovi un errore, correggi la causa reale e non limitarti a nasconderlo;
- preferisci soluzioni semplici, leggibili e compatibili con Windows PowerShell 5.1;
- evita sintassi PowerShell troppo compressa o fragile;
- documenta le modifiche importanti;
- considera il Toolkit ancora in sviluppo e non pronto per l'uso “alla cieca” sui PC clienti finché i test in VM non sono solidi.

## Regola di versioning – IMPORTANTISSIMA

Da ora ogni **build distribuibile/testabile** del Toolkit deve avere un numero diverso.

`VERSION.json` contiene:

- `version`
- `build`
- `status`
- `schemaVersion`

Build corrente:

- versione: `0.1.1`
- build: `1`
- status: `development`

Regola pratica: ogni nuova build che deve essere aggiornata/testata incrementa il numero, ad esempio:

`0.1.1 Build 1 → 0.1.2 Build 2 → 0.1.3 Build 3`

Non lasciare più `VERSION.json` invariato dopo modifiche destinate ai test, altrimenti sulla VM non possiamo sapere se stiamo usando davvero l'ultima build.

`modules/Version.ps1` ora legge il build esplicito da `VERSION.json` e il banner deve mostrare qualcosa tipo:

`TecnicoDigitale Windows Toolkit v0.1.1 - Build 1 [development]`

L'updater deve mostrare versione e build sia locale sia remota e, a fine aggiornamento, la versione installata.

Commit versioning:

- `67085ad77bcba3421d4f41142cdf1440110c89f5` — VERSION.json 0.1.1 Build 1
- `a8a7a2d93183fa42a4fb6a8e5e242cbdd7238994` — Version.ps1 con build esplicita
- `91369c7b2a8f743c1f43c557b49698c61caf8e54` — updater mostra versione + build

## Preset

I preset sono profili d'uso, non livelli di aggressività.

### STANDARD = VELOCITÀ SICURA

Profilo principale per PC cliente sconosciuto.

Deve mantenere funzionanti Office, Edge, WebView2, Defender, Firewall, Windows Update, Store/infrastruttura Microsoft, driver, rete, stampanti, audio, Bluetooth, Windows Search, pagefile e servizi critici.

Può ridurre in modo conservativo suggerimenti/promozioni, Widgets/background consumer, elementi Start/Taskbar/Explorer non utili, temporanei sicuri e startup realmente superfluo.

**Standard NON installa software.**

### GAMING

Standard + modifiche gaming sensate e documentabili. Niente tweak HPET/timer/scheduler/TCP/core parking/pagefile/mitigazioni.

### BUSINESS

Standard + affidabilità e controlli orientati al lavoro: BitLocker, Update, sicurezza, licenze, SMART/TRIM/storage, pending reboot, M365/OneDrive e policy supportate.

## Software separato dai preset

File principale:

`Installa-Software.ps1`

Software selezionabili:

1. Chrome
2. Firefox
3. VLC
4. WinRAR
5. 7-Zip
6. Everything
7. Adobe Acrobat Reader
8. SumatraPDF
9. Steam
10. Playnite

Scorciatoie:

- `N` = PC NUOVO
- `G` = GAMING
- `C` = azzera selezione
- `A` = installa
- `0` = esci

## Menu principale

```text
[1] STANDARD
[2] GAMING
[3] BUSINESS
[4] INSTALLA SOFTWARE
[5] STRUMENTI RAPIDI TECNICO
[6] RIPRISTINA MODIFICHE TOOLKIT
[7] ESCI
```

## Backup / Undo / Restore

Il Toolkit crea un punto di ripristino prima delle modifiche reali e mantiene sessioni Undo JSON.

Gap noti:

- alcune scritture Active Setup possono non essere completamente incluse nel backup;
- alcune modifiche Gaming storiche possono bypassare il backup;
- Undo servizi da completare;
- migliorare WhatIf/admin/validazione macchina/sessione più recente;
- verificare gestione tipi Registry.

## Lab generico

LTSC è stato rimosso dal flusso operativo.

Il laboratorio usa:

- `lab/Deep-Audit.ps1`
- `lab/Compare-Baseline.ps1`
- `lab/Services-Audit.ps1`
- `lab/Compare-Services.ps1`
- `lab/baselines/Windows11-Pro-Clean-Before-Standard.json`

Deep Audit è read-only e usa `SchemaVersion = 4`.

## Baseline Windows 11 Pro pulita

Baseline ufficiale:

`lab/baselines/Windows11-Pro-Clean-Before-Standard.json`

Origine: VM Windows 11 Pro build 26200 pulita, prima di Standard.

Snapshot baseline principale:

- ProcessCount: 140
- TotalWorkingSetMB: 4266.26
- TotalPrivateMemoryMB: 1714.29
- PhysicalMemoryUsedMB: 2886
- PhysicalMemoryFreeMB: 5287
- EnabledScheduledTasks: 212
- InstalledAppxCount: 115
- ProvisionedAppxCount: 47
- EnabledFeatureCount: 14
- InstalledCapabilityCount: 47
- StartupItemCount: 6
- RunningServiceCount: 88
- EdgeWebViewProcessCount: 16
- EdgeWebViewWorkingSetMB: 865.51

La baseline è un riferimento diagnostico, non uno stato da clonare sui PC clienti.

## Standard: primo test pulito SUPERATO

VM:

- Windows 11 Pro
- build 26200
- VirtualBox
- circa 8 GB RAM

Dopo Standard + riavvio + Deep Audit:

- processi: 140 → 132 = -8
- Working Set aggregato: 4266.26 → 3822.48 MB = -443.78 MB
- Private Memory: 1714.29 → 1515.79 MB = -198.50 MB
- RAM fisica usata: 2886 → 2709 MB = -177 MB
- RAM fisica libera: 5287 → 5464 MB = +177 MB
- task abilitati: 212 → 213 = +1
- AppX installate: 115 → 117 = +2
- AppX provisioned: 47 → 47 = 0
- feature abilitate: 14 → 14 = 0
- capability installate: 47 → 47 = 0
- startup: 6 → 6 = 0
- servizi running: 88 → 88 = 0
- Edge/WebView processi: 16 → 13 = -3
- Edge/WebView Working Set: 865.51 → 773.47 MB = -92.04 MB

Differenze runtime utili osservate:

- WidgetBoard: 1 → 0
- WidgetService: 1 → 0
- RuntimeBroker: 3 → 1
- msedge: 10 → 7

Nessuna differenza strutturale in startup, AppX provisioned o software installato/rimosso.

Conclusione operativa: **Standard è promosso come primo test VM pulito riuscito**. Le metriche RAM/processi restano snapshot runtime e non vanno trattate come valori assoluti garantiti.

## BITS / MDCoreSvc

Il comparatore ha segnalato:

- `BITS`: Baseline `Auto`, Attuale `Manual/Absent`
- `MDCoreSvc`: Baseline `Manual/Absent`, Attuale `Auto`

Non esiste nel codice Standard corrente una modifica intenzionale di questi servizi. Non assumere che Standard li abbia cambiati. Potrebbero essere variazioni Windows oppure un limite del modello compatto `Manual/Absent` del comparatore.

Da migliorare in futuro la rappresentazione dei servizi nel baseline/comparatore per distinguere chiaramente `Manual` da `Absent`.

## Icone Desktop in Standard – nuova build da testare

È stata aggiunta a `modules/Explorer.ps1` la gestione delle icone Desktop di sistema e `Standard.json` abilita `DesktopIconsByEdition`.

Non vengono creati collegamenti `.lnk`: vengono usate le icone di sistema Windows tramite le chiavi Desktop/HideDesktopIcons, con backup Undo tramite il sistema Registry del Toolkit.

Comportamento atteso:

### Windows Home / Consumer

- Questo PC
- File utente
- Cestino

### Windows Pro / Business

- Questo PC
- File utente
- Cestino
- Rete
- Pannello di controllo

Commit:

- `11eccb761bf89a3c8ef8e7ccf952f203250db7b0` — Explorer desktop icons
- `47e6d2c5cdc337e003fc78dc3697249fe84e2aaf` — Standard abilita DesktopIconsByEdition
- `db07bf9d12b7edaa2b8a72348495c455a3cb1ace` — documentazione Explorer

**Test immediato previsto:** aggiornare la VM e rilanciare Standard sopra Standard. Questo serve contemporaneamente a verificare le icone e l'idempotenza del preset.

Sulla VM Windows 11 Pro ci aspettiamo: Questo PC, File utente, Cestino, Rete e Pannello di controllo. Se Explorer non ridisegna subito, provare F5 e poi eventualmente disconnessione/riavvio.

## Updater: bug recenti e stato

File:

- `Aggiorna-Toolkit.cmd`
- `Update-Toolkit.ps1`

Architettura:

- scarica `main.zip` da GitHub;
- estrae in TEMP;
- valida VERSION.json e Avvia-Toolkit.cmd;
- copia la repo;
- preserva backup/log/report e `lab/reports`;
- rimuove componenti LTSC obsoleti;
- verifica i file obbligatori;
- scrive `Aggiornamento-Toolkit.log`.

Bug già incontrati:

1. vecchia copia locale con errore `GetFullPath`;
2. calcolo relativo errato che copiava tutta la repo in `C:\TecnicoDigitale-Windows-Toolkit-main\n\`;
3. confronto fragile tra path TEMP lungo `C:\Users\Win11 Pro\...` e alias 8.3 `C:\Users\WIN11P~1\...`.

Fix principali:

- `b334edf82b811faf27cdeafdcabb087a828c3933` — riconoscimento/rimozione sicura cartella spuria `n`;
- `30d1bb43217c2142a593e99b810ddbd6a59bcee0` — eliminazione del confronto fragile tra path lungo e alias 8.3;
- `91369c7b2a8f743c1f43c557b49698c61caf8e54` — visualizzazione versione + build locale/remota/installata.

All'ultimo aggiornamento del prompt l'updater sembrava finalmente procedere correttamente, ma il test completo finale va comunque confermato dalla VM.

## Strumenti rapidi tecnico

Esistono:

- diagnostica rete;
- flush DNS;
- cambio DNS rapido;
- riavvio scheda di rete;
- reset Spooler/coda stampa;
- triage processi sospetti read-only.

Il triage non deve dichiarare malware automaticamente: segnala elementi da verificare.

## Software/bloatware

Classificare in:

- SAFE REMOVE
- ASK
- PROTECTED

Regola:

> Non rimuovere automaticamente software scelto o utilizzato dall'utente. Rimuovere software identificato con elevata certezza come promozionale, trial, sponsorizzato o bloat OEM, purché la rimozione non comprometta Windows, driver, sicurezza o funzionalità hardware.

## Check rapido / Semaforo Tecnico

Da sviluppare una vista sintetica `OK / ATTENZIONE / PROBLEMA` per:

- PRESTAZIONI
- SICUREZZA
- SSD
- WINDOWS
- AGGIORNAMENTI
- RETE
- STARTUP
- PROCESSI
- SOFTWARE
- SPAZIO DISCO

Controlli utili: edizione Windows, attivazione, Office, Defender, Firewall, UAC, SMART, TRIM, spazio libero, pending reboot, startup, RAM idle, software promozionale, temporanei, OneDrive e BitLocker.

## Edge/WebView

Possibili candidati futuri da testare A/B:

- EDGE-001 Startup Boost condizionale;
- EDGE-002 app/estensioni Edge in background;
- EDGE-003 preload/AutoLaunch da investigare;
- EDGE-004 Edge Update da NON toccare;
- EDGE-005 WebView2 da NON toccare.

Nessuna modifica senza prova misurabile e controllo regressioni.

## VM di test

- Windows 11 Pro
- build 26200
- VirtualBox
- circa 8 GB RAM
- host Ryzen 7 7700
- TPM 2.0
- EFI
- Secure Boot

## Prossimi passi immediati

1. Completare il test dell'updater e verificare che mostri correttamente `0.1.1 Build 1` come remoto/installato.
2. Verificare che la vecchia cartella `n` sia sparita e che root/modules/presets/lab/docs siano aggiornati correttamente.
3. Rilanciare **Standard sopra Standard** sulla VM già ottimizzata.
4. Verificare su Windows 11 Pro la comparsa di Questo PC, File utente, Cestino, Rete e Pannello di controllo.
5. Usare questa seconda esecuzione come test di **idempotenza Standard**: nessun errore, nessun effetto cumulativo indesiderato.
6. Se utile, fare un Deep Audit dopo la seconda Standard per controllare che non emergano regressioni.
7. Migliorare successivamente il comparatore servizi per distinguere `Manual` e `Absent`.
8. Poi iniziare il **Check rapido / Semaforo Tecnico**.

## Nota di perimetro

Questo prompt riguarda esclusivamente TecnicoDigitale Windows Toolkit.

NON riguarda rEFInd, dual boot, Batocera, Home Assistant, hardware domestico o altri progetti.

Quando ricevi questo prompt in una nuova chat:

1. leggi prima lo stato attuale del repository `cristian082/TecnicoDigitale-Windows-Toolkit`;
2. verifica soprattutto `VERSION.json`, `Update-Toolkit.ps1`, `modules/Explorer.ps1`, `presets/Standard.json`, `lab/Deep-Audit.ps1` e `lab/Compare-Baseline.ps1`;
3. controlla che ogni nuova build testabile incrementi versione/build;
4. dimmi brevemente dove siamo arrivati;
5. riprendi dal test Standard-sopra-Standard con icone Desktop e idempotenza.

---
