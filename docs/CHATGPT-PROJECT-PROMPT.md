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

## Preset

I preset sono profili d'uso, non livelli di aggressività.

### STANDARD = VELOCITÀ SICURA

Profilo principale per PC cliente sconosciuto.

Deve mantenere funzionanti:

- Office;
- Edge;
- WebView2;
- Defender;
- Firewall;
- Windows Update;
- Store/infrastruttura Microsoft necessaria;
- driver;
- rete;
- stampanti;
- audio;
- Bluetooth;
- Windows Search;
- pagefile;
- servizi critici.

Può ridurre in modo conservativo:

- animazioni non necessarie;
- suggerimenti e contenuti promozionali;
- Widgets/background consumer;
- alcune attività Edge in background/preload solo se motivate;
- elementi Start/Taskbar/Explorer non utili;
- file temporanei sicuri;
- startup realmente superfluo e identificato con certezza.

**Il preset Standard NON installa più software.**

### GAMING

Standard + modifiche gaming sensate e documentabili.

Non usare tweak HPET/timer/scheduler/TCP/core parking/pagefile/mitigazioni.

### BUSINESS

Standard + affidabilità e controlli orientati al lavoro: BitLocker, Update, sicurezza, licenze, SMART/TRIM/storage, pending reboot, M365/OneDrive e policy supportate.

### PERSONALIZZATA / AVANZATA

Controllo manuale del tecnico.

## Software: ora è separato dai preset

L'installazione software è stata separata da Standard/Gaming/Business per non contaminare i test prestazionali e per lasciare al tecnico la scelta.

File principale:

`Installa-Software.ps1`

Software selezionabili attualmente:

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

Scorciatoie previste:

- `N` = PC NUOVO
- `G` = GAMING
- `C` = azzera selezione
- `A` = installa
- `0` = esci

Preset rapido PC NUOVO: Chrome, VLC, WinRAR, Everything, Adobe Reader.

Preset rapido GAMING: Chrome, VLC, WinRAR, Everything, Steam, Playnite.

Commit di riferimento della separazione software dai preset:

- Setup/preset: `5b327bd138d1842547ad0ac8cae415f2fdc8b23d`
- installer selettivo: `fd6989ae8ca5586fe6bbb7c2f78329e303829c16`
- menu principale con voce software separata: `23b9a743aa9f6f6536368635836964696415edda`

## Menu principale attuale

```text
[1] STANDARD
[2] GAMING
[3] BUSINESS
[4] INSTALLA SOFTWARE
[5] STRUMENTI RAPIDI TECNICO
[6] RIPRISTINA MODIFICHE TOOLKIT
[7] ESCI
```

## Strumenti rapidi tecnico

Esistono:

- diagnostica rete;
- flush DNS;
- cambio DNS rapido;
- riavvio scheda di rete;
- reset Spooler/coda stampa;
- triage processi sospetti read-only.

Il triage processi NON deve dichiarare malware automaticamente: segnala elementi da verificare.

## Backup / Undo / Restore

Il Toolkit crea un punto di ripristino prima delle modifiche reali e mantiene sessioni Undo JSON.

Gap noti ancora da sistemare:

- alcune scritture Active Setup possono non essere ancora incluse completamente nel backup;
- alcune modifiche Gaming storiche possono bypassare il backup;
- Undo servizi da completare;
- migliorare WhatIf/admin/validazione macchina/sessione più recente;
- verificare bene la gestione dei tipi Registry;
- verificare che un rifiuto dell'utente alla creazione restore point non lasci effetti collaterali indesiderati.

## Lab: LTSC rimosso dal flusso operativo

La vecchia logica “LTSC vs Pro” non deve più comparire nel laboratorio operativo.

Sono stati eliminati:

- `lab/LTSC-Deep-Audit.ps1`
- `lab/Compare-LTSC-Deep-Audit.ps1`

Commit rimozioni:

- `54fad41d33d283f26189acb75d943ddef4de9e8c`
- `cddf15205fa5e0512e54880dc8bfb2358b87caf9`

Il laboratorio ora usa:

- `lab/Deep-Audit.ps1`
- `lab/Compare-Baseline.ps1`
- `lab/Services-Audit.ps1`
- `lab/Compare-Services.ps1`
- `lab/baselines/Windows11-Pro-Clean-Before-Standard.json`

## Deep Audit generico

`lab/Deep-Audit.ps1` è read-only e produce report JSON in `lab/reports`.

Schema attuale: `SchemaVersion = 4`

Tipo audit: `Windows11-Deep-Audit`

Raccoglie almeno:

- processi;
- task pianificati;
- AppX installate;
- AppX provisioned;
- optional features;
- capabilities;
- programmi installati;
- startup;
- servizi;
- dati sistema selezionati;
- metriche snapshot.

Metriche principali:

- ProcessCount
- TotalWorkingSetMB
- TotalPrivateMemoryMB
- PhysicalMemoryTotalMB
- PhysicalMemoryUsedMB
- PhysicalMemoryFreeMB
- EnabledScheduledTasks
- InstalledAppxCount
- ProvisionedAppxCount
- EnabledFeatureCount
- InstalledCapabilityCount
- StartupItemCount
- RunningServiceCount
- EdgeWebViewProcessCount
- EdgeWebViewWorkingSetMB

Un bug con `Set-StrictMode` e proprietà opzionali tipo `DisplayName` è stato corretto introducendo accesso sicuro alle proprietà.

Commit fix Deep Audit:

`2251a103fdcf7edb98eacb99f9f3b0de7d09722d`

## Baseline Windows 11 Pro pulita

Baseline ufficiale del laboratorio:

`lab/baselines/Windows11-Pro-Clean-Before-Standard.json`

Commit baseline:

`9e00f98077108b9c5578b183de63054c999e88da`

Origine: VM Windows 11 Pro build 26200 pulita, prima di Standard.

Snapshot baseline:

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

## Compare-Baseline

`lab/Compare-Baseline.ps1` confronta un Deep Audit corrente con la baseline pulita.

Mostra almeno:

- impatto misurato;
- processi con conteggio diverso;
- AppX provisioned rimosse/aggiunte;
- startup rimosso/aggiunto;
- servizi con StartMode diverso;
- software differente dalla baseline.

Genera un JSON `BaselineCompare-<timestamp>.json`.

Un parser error dovuto a sintassi PowerShell troppo compressa è stato corretto riscrivendo il comparatore in forma leggibile e compatibile.

Commit fix comparatore:

`0e0e743ff823428ae7491f82d6e483af412938ad`

## Primo confronto Standard pulito riuscito

VM:

- Windows 11 Pro
- build 26200
- VirtualBox
- RAM 8173 MB circa

Dopo Standard + riavvio + Deep Audit, primo confronto pulito utilizzabile:

- processi: 140 → 132 = **-8**
- Working Set aggregato: 4266.26 → 3822.48 MB = **-443.78 MB**
- Private Memory: 1714.29 → 1515.79 MB = **-198.50 MB**
- RAM fisica usata: 2886 → 2709 MB = **-177 MB**
- RAM fisica libera: 5287 → 5464 MB = **+177 MB**
- task abilitati: 212 → 213 = +1
- AppX installate: 115 → 117 = +2
- AppX provisioned: 47 → 47 = 0
- feature abilitate: 14 → 14 = 0
- capability installate: 47 → 47 = 0
- startup: 6 → 6 = 0
- servizi running: 88 → 88 = 0
- Edge/WebView processi: 16 → 13 = **-3**
- Edge/WebView Working Set: 865.51 → 773.47 MB = **-92.04 MB**

Differenze runtime interessanti:

- `WidgetBoard`: 1 → 0
- `WidgetService`: 1 → 0
- `RuntimeBroker`: 3 → 1
- `msedge`: 10 → 7

Nessuna differenza strutturale in startup, AppX provisioned o software installato/rimosso nel test pulito.

Da NON interpretare in modo affrettato: RAM/processi sono snapshot runtime e possono variare.

## Servizi da investigare nel confronto

Il comparatore ha segnalato:

- `BITS`: Baseline `Auto`, Attuale `Manual/Absent`
- `MDCoreSvc`: Baseline `Manual/Absent`, Attuale `Auto`

NON concludere automaticamente che Standard abbia modificato questi servizi.

La filosofia del progetto vieta di alterare BITS/Windows Update senza ragione. Prima di cambiare Standard bisogna verificare se:

- è semplice variazione/runtime/trigger-start;
- la baseline compatta rappresenta male alcuni stati;
- il comparatore normalizza male `Manual/Absent`;
- esiste davvero una modifica causata dal Toolkit.

## Updater: stato attuale e bug recenti

File:

- `Aggiorna-Toolkit.cmd`
- `Update-Toolkit.ps1`

Architettura updater:

- scarica `main.zip` da GitHub;
- forza TLS 1.2 se possibile;
- estrae in TEMP;
- valida almeno `VERSION.json` e `Avvia-Toolkit.cmd`;
- copia i file del repository;
- preserva backup/log/report e `lab/reports`;
- rimuove script LTSC obsoleti;
- verifica file obbligatori al termine;
- scrive `Aggiornamento-Toolkit.log`.

### Bug 1: vecchio `GetFullPath`

Una copia locale vecchia continuava a mostrare errori `GetFullPath`, mentre il file corrente in repo non conteneva più quella chiamata. Questo ha evidenziato che la VM stava eseguendo una copia updater non aggiornata.

### Bug 2: cartella spuria `n`

Un errore nel calcolo del percorso relativo ha copiato **l'intero repository** dentro:

`C:\TecnicoDigitale-Windows-Toolkit-main\n\`

La cartella `n` conteneva root, `docs`, `lab`, `modules`, `presets`, ecc.

L'updater è stato modificato per riconoscere e rimuovere automaticamente `n` SOLO se contiene la firma completa di una copia Toolkit, così da non cancellare una normale cartella utente chiamata `n`.

Commit relativo:

`b334edf82b811faf27cdeafdcabb087a828c3933`

### Bug 3: path TEMP lungo vs alias 8.3

Successivo errore reale:

```text
Percorso sorgente inatteso:
'C:\Users\Win11 Pro\AppData\Local\Temp\...\TecnicoDigitale-Windows-Toolkit-main\Aggiorna-Toolkit.cmd'
non e sotto
'C:\Users\WIN11P~1\AppData\Local\Temp\...\TecnicoDigitale-Windows-Toolkit-main'
```

Windows rappresentava la stessa cartella TEMP in due modi:

- percorso lungo: `C:\Users\Win11 Pro\...`
- alias 8.3: `C:\Users\WIN11P~1\...`

Il confronto stringa dei path assoluti era quindi fragile.

È stato cambiato approccio: l'updater non deve più validare i file confrontando queste due rappresentazioni assolute del TEMP; deve enumerare/copiare relativamente alla directory sorgente per eliminare il problema alla radice.

Ultimo commit updater:

`30d1bb43217c2142a593e99b810ddbd6a59bcee0`

**Stato importantissimo:** al momento di aggiornare questo prompt, il commit `30d1bb...` è stato scritto in repo ma deve ancora essere confermato con un test reale completo in VM.

Poiché un updater che fallisce prima della copia non riesce ad aggiornare se stesso, in questa fase può essere necessario sostituire manualmente `Update-Toolkit.ps1` una volta e poi rilanciare `Aggiorna-Toolkit.cmd`.

Se anche la nuova strategia fallisce, NON continuare con rattoppi infiniti: valutare un updater più semplice e robusto.

## VERSION.json

Attualmente la versione è ancora `0.1.0`.

Questo significa che `Versione locale` e `Versione remota` possono risultare entrambe `0.1.0` anche quando i commit sono diversi. In futuro migliorare versioning/manifest o rilevamento build/commit.

## Avvia-Lab.cmd

Menu attuale circa:

```text
[1] CREA DEEP AUDIT SISTEMA ATTUALE
[2] CONFRONTA ULTIMO AUDIT CON BASELINE WINDOWS 11 PRO
[3] AUDIT SERVIZI SISTEMA ATTUALE
[4] APRI CARTELLA REPORT
[5] APRI CARTELLA BASELINE
[0] ESCI
```

Per il normale test BEFORE/AFTER Standard:

`Standard → riavvio → [1] Deep Audit → [2] Confronto Baseline`

L'audit servizi è un approfondimento separato.

Da migliorare eventualmente le etichette del menu per renderlo ancora più chiaro.

## Regola software/bloatware

Classificare software in:

- SAFE REMOVE
- ASK
- PROTECTED

Regola:

> Non rimuovere automaticamente software scelto o utilizzato dall'utente. Rimuovere software identificato con elevata certezza come promozionale, trial, sponsorizzato o bloat OEM, purché la rimozione non comprometta Windows, driver, sicurezza o funzionalità hardware.

Esempi:

- Office configurato → PROTECTED
- M365 promo/trial non configurato → SAFE REMOVE solo con identificazione certa
- McAfee/Norton OEM trial → candidato, ma verificare il ritorno di Defender
- utility OEM firmware/hotkey/batteria/driver → PROTECTED o ASK

## UX desiderata

Prima di applicare modifiche, arrivare in futuro a una UX tipo:

```text
Profilo selezionato: STANDARD
12 ottimizzazioni consigliate
3 opzionali
2 non applicabili
[V] Mostra cosa verrà modificato
[A] Applica
[I] Indietro
```

Ogni modifica dovrebbe avere un ID stabile e spiegabile, ad esempio:

```text
EDGE-001 — Disattiva Startup Boost
Motivo: Chrome rilevato come browser principale; Edge non utilizzato.
Impatto previsto: basso
Rischio: basso
Reversibile: sì
```

ID/documentazione desiderati come:

- EXPLORER-001
- PRIVACY-003
- SERVICES-004
- EDGE-001
- NETWORK-001
- PRINT-001

Ogni documentazione deve spiegare:

- nome;
- comportamento stock;
- modifica;
- motivo;
- cosa NON viene cambiato;
- effetti collaterali;
- impatto;
- rischio;
- reversibilità;
- preset coinvolti;
- versioni Windows testate;
- implementazione.

## Check rapido / Semaforo Tecnico

Da sviluppare una vista sintetica con stati `OK / ATTENZIONE / PROBLEMA` per categorie come:

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

Controlli utili:

- edizione Windows;
- attivazione;
- Office;
- Defender;
- Firewall;
- UAC;
- SMART;
- TRIM;
- spazio libero;
- pending reboot;
- startup;
- RAM idle;
- software promozionale;
- temporanei;
- OneDrive;
- BitLocker.

## Diagnostica attuale

Esistono funzioni per raccogliere informazioni su:

- hardware/BIOS;
- Windows;
- CPU;
- RAM;
- dischi/spazio libero;
- TRIM;
- startup;
- Defender;
- Firewall;
- UAC;
- BitLocker;
- licenze Windows/Office.

Da migliorare in futuro:

- channel/expiration licenze;
- SMART/temperature;
- pending reboot;
- Windows Update;
- pagefile;
- moduli RAM;
- Secure Boot/VBS/Core Isolation;
- report HTML;
- robustezza TRIM localizzato.

## Conclusione attuale sui servizi

Non esiste finora una giustificazione per fare mass-disable dei servizi Windows.

Le differenze utili osservate vengono soprattutto da:

- meno componenti consumer attivi;
- meno processi Widgets/Edge/background;
- riduzione di alcuni componenti di avvio/runtime.

Lo stato runtime dei servizi può variare tra snapshot, quindi non generalizzare da una singola differenza.

## Edge/WebView

Possibili candidati futuri da testare A/B:

- EDGE-001 Startup Boost condizionale se Chrome/Firefox è browser principale;
- EDGE-002 app/estensioni Edge in background;
- EDGE-003 preload/AutoLaunch da investigare;
- EDGE-004 Edge Update da NON toccare;
- EDGE-005 WebView2 da NON toccare.

Nessuna modifica deve essere aggiunta senza prova misurabile e controllo regressioni.

## VM di test attuale

- Windows 11 Pro
- build 26200
- VirtualBox
- circa 8 GB RAM
- CPU virtuali su host Ryzen 7 7700
- TPM 2.0
- EFI
- Secure Boot

Il laboratorio deve restare ripetibile tramite snapshot puliti.

## Prossimi passi immediati

1. Testare il nuovo updater commit `30d1bb43217c2142a593e99b810ddbd6a59bcee0` nella VM.
2. Verificare che aggiorni i file nella root corretta.
3. Verificare che la cartella spuria `n` venga eliminata.
4. Verificare che `lab`, `modules`, `presets`, `docs` siano realmente aggiornati.
5. Se updater fallisce ancora per path, semplificare radicalmente l'architettura invece di aggiungere altri workaround.
6. Investigare BITS e MDCoreSvc nel confronto baseline senza assumere che Standard li abbia modificati.
7. Non cambiare Standard finché non capiamo se quelle differenze sono reali o artefatti del confronto.
8. Migliorare in seguito versioning/manifest updater.
9. Migliorare eventualmente le etichette del menu Lab.
10. Continuare il ciclo misurato: snapshot pulito → Standard → riavvio → Deep Audit → Compare Baseline → analisi regressioni.

## Nota di perimetro

Questo prompt riguarda **esclusivamente TecnicoDigitale Windows Toolkit**.

NON riguarda rEFInd, dual boot, Batocera, Home Assistant, hardware domestico o altri progetti.

Quando ricevi questo prompt in una nuova chat:

1. leggi prima lo stato attuale del repository `cristian082/TecnicoDigitale-Windows-Toolkit`;
2. verifica in particolare `Update-Toolkit.ps1`, `lab/Deep-Audit.ps1`, `lab/Compare-Baseline.ps1`, `Avvia-Lab.cmd` e `VERSION.json`;
3. dimmi brevemente dove siamo arrivati;
4. riprendi dal test updater e dal laboratorio Standard pulito senza reinventare il progetto.

---
