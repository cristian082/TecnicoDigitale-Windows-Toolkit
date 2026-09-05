# TecnicoDigitale Test Lab - VirtualBox

Questa cartella documenta il laboratorio usato per sviluppare e verificare il TecnicoDigitale Windows Toolkit su macchine Windows 11 pulite e riproducibili.

## VM di riferimento

Configurazione consigliata:

- Windows 11 Pro 25H2 x64, italiano;
- Windows 11 Enterprise LTSC 2024 x64, italiano, come riferimento comparativo;
- 2 vCPU;
- 6-8 GB RAM;
- disco virtuale dinamico da 80 GB;
- EFI/UEFI abilitato;
- TPM 2.0 se disponibile;
- nessun software aggiuntivo prima dello snapshot base.

## Regola fondamentale: baseline pulita

La prima installazione deve essere il piu possibile stock. Prima di eseguire il Toolkit, rimuovere software, disabilitare servizi o applicare tweak manuali, creare uno snapshot della VM.

## Snapshot consigliati

### 00-WIN11-STOCK-OFFLINE

Crearlo appena raggiunto il desktop per la prima volta, prima di rete, aggiornamenti, Guest Additions, software o Toolkit.

### 01-WIN11-UPDATED

Dopo aver aggiornato Windows e verificato la stabilita della VM, creare lo snapshot usato per i normali test del Toolkit.

## Audit servizi Windows

`Services-Audit.ps1` e uno strumento **read-only**. Non cambia tipo di avvio, stato o configurazione dei servizi.

La versione 2 raccoglie per ogni servizio:

- nome reale;
- nome normalizzato per confrontare servizi per-utente con suffisso diverso fra installazioni;
- nome visualizzato;
- stato Running/Stopped;
- StartMode;
- Automatic Delayed Start quando presente;
- account di avvio;
- percorso eseguibile;
- PID;
- tipo di servizio;
- dipendenze;
- servizi dipendenti;
- output grezzo di `sc.exe qtriggerinfo` per lo studio dei trigger.

Esempio:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\lab\Services-Audit.ps1" -Label "PRO-25H2"
```

Per LTSC:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\lab\Services-Audit.ps1" -Label "LTSC-2024"
```

I report vengono salvati in `lab\reports` in formato JSON e CSV.

## Confronto Pro ↔ LTSC

`Compare-Services.ps1` confronta due report generati da `Services-Audit.ps1`. Supporta anche i vecchi report schema 1: se manca `NormalizedName`, lo calcola durante il confronto.

Esempio, usando LTSC come riferimento e Pro come candidato:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\lab\Compare-Services.ps1" `
  -ReferencePath ".\lab\reports\Services-LTSC-2024-XXXXXXXX-XXXXXX.json" `
  -CandidatePath ".\lab\reports\Services-PRO-25H2-XXXXXXXX-XXXXXX.json"
```

Il comparatore divide i risultati in:

- `REFERENCE_ONLY` — presente solo nella baseline di riferimento;
- `CANDIDATE_ONLY` — presente solo nella macchina candidata;
- `START_CONFIGURATION_DIFFERENT` — StartMode o Delayed Auto Start differente;
- `STATE_DIFFERENT` — configurazione di avvio uguale ma stato corrente diverso;
- `IDENTICAL_CORE_STATE` — configurazione e stato principali coincidenti.

I suffissi delle istanze per-utente, ad esempio `_516e3`, vengono rimossi solo ai fini del confronto. Il nome originale resta nel report.

### Attenzione alle build

Il comparatore segnala esplicitamente quando le build Windows sono diverse. Una differenza fra LTSC e Pro non deve essere attribuita automaticamente all'edizione: puo dipendere anche dalla diversa build, dallo stato della VM, dal login, dall'hardware virtuale o da un trigger appena eseguito.

Per questo **nessuna differenza rilevata dal comparatore diventa automaticamente un tweak del Toolkit**.

## LTSC Deep Audit

`LTSC-Deep-Audit.ps1` e un secondo strumento **read-only** pensato per cercare le differenze reali fra Windows 11 Pro e Windows 11 Enterprise LTSC al di fuori del solo elenco servizi.

Raccoglie in un unico JSON:

- snapshot di RAM fisica usata/libera;
- processi attivi con Working Set e Private Memory;
- task pianificati, stato e azioni principali;
- pacchetti AppX installati per tutti gli utenti;
- pacchetti AppX provisioned nell'immagine;
- Windows Optional Features;
- Windows Capabilities;
- programmi Win32 rilevati dalle chiavi Uninstall, senza usare Win32_Product;
- elementi di avvio automatico;
- configurazione base dei servizi;
- processi Edge e WebView2;
- alcune policy Microsoft rilevanti per Data Collection, Cloud Content, Search, Windows Update, App Privacy, Explorer e Copilot.

Non disinstalla app, non abilita/disabilita feature, non cambia servizi, task, policy o registro.

Esempio Pro:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\lab\LTSC-Deep-Audit.ps1" -Label "PRO-25H2"
```

Esempio LTSC:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\lab\LTSC-Deep-Audit.ps1" -Label "LTSC-2024"
```

Il file prodotto e `lab\reports\DeepAudit-<LABEL>-<timestamp>.json`.

Per evitare comandi manuali, `Avvia-Lab.cmd` espone direttamente sia gli audit servizi sia i due Deep Audit. Il BAT richiede elevazione per ottenere dati piu completi e confrontabili.

### Come eseguire il confronto Deep Audit

Per un confronto attendibile:

1. ripristinare le due VM al rispettivo snapshot baseline;
2. lasciare terminare login e attivita iniziali di Windows;
3. evitare di aprire programmi non necessari;
4. eseguire il Deep Audit una volta sulla Pro e una volta sulla LTSC;
5. confrontare prima le differenze strutturali (AppX, task, feature, capability, startup, policy) e solo dopo le misure istantanee di RAM/processi;
6. non interpretare una differenza di memoria o processo singolo come prova di un'ottimizzazione senza ripetere la misura.

Il Deep Audit serve a trovare **candidati da studiare**, non a trasformare automaticamente ogni differenza LTSC in un tweak.

## Metodo per approvare una modifica ai servizi

Prima di cambiare un servizio occorre:

1. rilevare una differenza interessante;
2. capire la funzione del servizio;
3. verificare StartMode, delayed start e trigger;
4. verificare dipendenze e servizi dipendenti;
5. stabilire se il comportamento dipende da edizione o build;
6. testare la modifica in snapshot;
7. verificare Windows Update, Store, rete, audio, Bluetooth, stampa, ricerca, Hello e le altre funzioni coinvolte;
8. misurare se esiste un beneficio concreto;
9. documentare la decisione in `docs/Services.md`;
10. solo dopo valutare l'inserimento in `modules/Services.ps1` con backup e Undo.

## Sequenza generale di test Toolkit

Per ogni ciclo:

1. ripristinare `01-WIN11-UPDATED`;
2. avviare Windows;
3. eseguire prima `-WhatIf` quando applicabile;
4. eseguire il preset reale;
5. salvare log e report;
6. riavviare Windows;
7. verificare le impostazioni applicate;
8. eseguire una seconda volta lo stesso preset per verificare l'idempotenza;
9. provare Undo;
10. ripristinare lo snapshot prima del test successivo.

## Cosa NON deve fare la baseline

La VM base non deve usare configurazioni aggressive che:

- rimuovono in massa AppX o Windows capabilities;
- disabilitano UAC;
- disabilitano SmartScreen;
- disabilitano Defender o Firewall;
- disabilitano Core Isolation/VBS/HVCI;
- forzano modifiche prestazionali;
- applicano tweak ai servizi che vogliamo misurare;
- rimuovono componenti prima dell'audit.

## Obiettivo

Separare chiaramente:

`Windows stock` -> `Windows aggiornato` -> `Windows dopo TecnicoDigitale Toolkit`

Il laboratorio serve a trasformare ogni modifica del Toolkit da ipotesi a intervento misurato, documentato e ripristinabile.
