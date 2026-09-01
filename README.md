# TecnicoDigitale Windows Toolkit

Toolkit PowerShell modulare per **preparare, ottimizzare e standardizzare PC Windows 11** in modo rapido, ripetibile e controllato.

Pensato per configurazioni post-installazione, PC personali, gaming e macchine da consegnare a clienti: invece di ripetere manualmente decine di impostazioni e installazioni, il toolkit applica una configurazione coerente tramite preset documentati.

## Perché usarlo

Su una nuova installazione di Windows molte operazioni sono sempre le stesse: creare un punto di ripristino, togliere suggerimenti e contenuti promozionali, sistemare Esplora file e barra delle applicazioni, rimuovere app preinstallate non necessarie, configurare alcune opzioni gaming e installare il software di base.

TecnicoDigitale Windows Toolkit automatizza queste operazioni con alcuni vantaggi pratici:

- **risparmio di tempo** nella preparazione di un PC;
- **configurazione coerente** tra macchine diverse;
- **preset separati** per PC standard, gaming e business;
- **moduli indipendenti**, quindi ogni area può essere modificata senza riscrivere tutto;
- **logging completo** dell'esecuzione per sapere cosa è stato fatto;
- **supporto `-WhatIf`** per simulare l'intervento prima di applicarlo;
- **punto di ripristino automatico** prima delle modifiche;
- configurazione tramite file JSON leggibili e facili da personalizzare;
- installazione automatica del software tramite **winget**;
- approccio conservativo, adatto anche a PC che devono rimanere semplici da diagnosticare e mantenere nel tempo.

## Cosa fa

### 1. Protezione e punto di ripristino

Il modulo `Restore.ps1` prova ad abilitare Protezione sistema sull'unità `C:` e crea un punto di ripristino chiamato:

`TecnicoDigitale Windows Toolkit`

Viene eseguito prima degli altri interventi, così la macchina dispone di un riferimento precedente alla configurazione.

### 2. Privacy e contenuti promozionali

Il modulo `Privacy.ps1` riduce alcuni contenuti promozionali e suggerimenti integrati in Windows.

Attualmente:

- disabilita suggerimenti nel pannello di sistema;
- disabilita varie categorie di contenuti suggeriti di Windows;
- disabilita l'ID pubblicitario quando previsto dal preset.

Lo scopo non è "smontare" la telemetria di Windows, ma rendere l'esperienza più pulita senza intervenire sui componenti fondamentali del sistema.

### 3. Esplora file

Il modulo `Explorer.ps1` applica impostazioni pratiche per l'uso quotidiano:

- mostra le **estensioni dei file**;
- apre Esplora file su **Questo PC** invece della Home quando previsto dal preset;
- può mostrare i **file nascosti** se abilitato nel preset.

Mostrare le estensioni è particolarmente utile anche in assistenza tecnica, perché permette di distinguere immediatamente il tipo reale di un file.

### 4. Start e barra delle applicazioni

Il modulo `Start-Taskbar.ps1` rende l'interfaccia più essenziale e prevedibile.

Può:

- nascondere i **Widget**;
- allineare Start e icone della barra **a sinistra**;
- disabilitare le **evidenziazioni dinamiche della ricerca**.

Le opzioni cambiano in base al preset: per esempio il profilo Business usa l'allineamento a sinistra, mentre Standard e Gaming mantengono quello predefinito di Windows 11.

### 5. Debloat selettivo

Il modulo `Debloat.ps1` rimuove soltanto le app indicate esplicitamente nel preset, invece di applicare un debloat indiscriminato.

Tra i pacchetti che possono essere rimossi:

- Microsoft Bing News;
- Microsoft Bing Weather;
- Microsoft Get Help;
- Microsoft Get Started;
- Microsoft Solitaire Collection;
- Feedback Hub;
- Groove Music / Media Player legacy package;
- Film e TV.

Il preset Gaming mantiene Solitaire, mentre Standard e Business lo rimuovono.

La rimozione viene eseguita solo sui pacchetti elencati nel JSON del preset, quindi la selezione rimane trasparente e modificabile.

### 6. Ottimizzazioni gaming

Il modulo `Gaming.ps1` contiene tweak semplici e mirati.

Nel preset Gaming:

- abilita **Windows Game Mode**;
- abilita l'attivazione automatica di Game Mode;
- disabilita **Game DVR** in background.

L'obiettivo è evitare registrazioni/catture non richieste e lasciare a Windows la gestione prevista per i carichi di gioco, senza applicare tweak estremi a scheduler, timer, rete o servizi di sistema.

### 7. Installazione automatica software

Il modulo `Software.ps1` usa `winget` per installare in modalità silenziosa il software previsto dal preset, accettando automaticamente gli accordi dei pacchetti e delle sorgenti.

Se `winget` non è disponibile, il modulo viene semplicemente saltato e l'esecuzione prosegue.

Software attualmente previsto:

| Software | Standard | Gaming | Business |
|---|:---:|:---:|:---:|
| WinRAR | ✅ | ✅ | ✅ |
| VLC | ✅ | ✅ | ✅ |
| Google Chrome | ✅ | ✅ | ✅ |
| Everything | ✅ | ✅ | ✅ |
| Adobe Acrobat Reader 64-bit | ✅ | — | ✅ |
| Steam | — | ✅ | — |
| Playnite | — | ✅ | — |

I pacchetti sono definiti nei JSON e possono essere aggiunti o rimossi senza modificare il modulo PowerShell.

## I preset

### Standard

Pensato per un PC domestico o general purpose appena installato.

Applica privacy, Explorer, pulizia della barra, debloat selettivo e installa il pacchetto software di base: WinRAR, VLC, Chrome, Everything e Adobe Reader.

È il preset consigliato come punto di partenza.

### Gaming

Pensato per un PC destinato anche ai giochi.

Oltre alla configurazione generale:

- abilita Game Mode;
- disabilita Game DVR;
- installa Steam;
- installa Playnite;
- evita alcune rimozioni non necessarie al profilo gaming.

### Business

Pensato per postazioni da lavoro o PC da consegnare a clienti professionali.

Mantiene una configurazione sobria e prevedibile:

- privacy e suggerimenti ridotti;
- Explorer configurato per uso pratico;
- Widget nascosti;
- Start allineato a sinistra;
- debloat selettivo;
- software base con Adobe Reader;
- nessuna modifica gaming.

## Come funziona

`Setup.ps1` è l'orchestratore principale.

All'avvio:

1. verifica che PowerShell sia in esecuzione come amministratore;
2. crea una cartella `logs` se non esiste;
3. avvia una trascrizione completa dell'esecuzione;
4. carica il preset JSON scelto;
5. carica i moduli PowerShell;
6. esegue i moduli abilitati dal preset nell'ordine previsto;
7. salva il log con data e ora.

Ordine attuale:

`Restore → Privacy → Explorer → Start/Taskbar → Debloat → Gaming → Software`

## Avvio rapido

Aprire PowerShell **come amministratore** nella cartella del progetto.

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\Setup.ps1 -Preset Standard
```

Preset disponibili:

```text
Standard
Gaming
Business
```

Esempio Gaming:

```powershell
.\Setup.ps1 -Preset Gaming
```

Esempio Business:

```powershell
.\Setup.ps1 -Preset Business
```

## Modalità simulazione

Prima di applicare le modifiche è possibile vedere cosa verrebbe eseguito usando `-WhatIf`:

```powershell
.\Setup.ps1 -Preset Standard -WhatIf
```

È utile durante lo sviluppo dei preset o prima di usare il toolkit su una macchina cliente.

## Personalizzazione

I preset si trovano in `presets/` e sono normali file JSON.

È quindi possibile creare facilmente profili differenti, per esempio:

- PC scuola;
- PC ufficio;
- PC gaming essenziale;
- macchina laboratorio;
- configurazione specifica per un cliente.

Ogni sezione può essere abilitata/disabilitata e le liste software/debloat possono essere modificate senza toccare il codice principale.

## Logging

Ogni esecuzione crea automaticamente un file nella cartella:

```text
logs/
```

con nome simile a:

```text
Toolkit-20260902-013000.log
```

Il log permette di ricostruire l'intervento effettuato su una macchina e facilita assistenza e troubleshooting successivi.

## Architettura

```text
TecnicoDigitale-Windows-Toolkit/
├── README.md
├── LICENSE
├── Setup.ps1
├── modules/
│   ├── Common.ps1
│   ├── Restore.ps1
│   ├── Privacy.ps1
│   ├── Explorer.ps1
│   ├── Start-Taskbar.ps1
│   ├── Debloat.ps1
│   ├── Gaming.ps1
│   └── Software.ps1
├── presets/
│   ├── Standard.json
│   ├── Gaming.json
│   └── Business.json
└── docs/
    └── Changes.md
```

`Common.ps1` contiene funzioni riutilizzabili per il registro di sistema e la gestione degli hive utente, compreso il supporto tecnico per applicare in futuro impostazioni anche ai profili esistenti e al profilo Default.

## Filosofia del progetto

Il toolkit privilegia modifiche comprensibili, documentabili e semplici da diagnosticare.

Per questo le ottimizzazioni puntano soprattutto a:

- eliminare distrazioni e contenuti promozionali;
- migliorare l'usabilità quotidiana;
- rimuovere solo software chiaramente selezionato;
- installare velocemente gli strumenti realmente utili;
- mantenere Windows aggiornabile e facilmente manutenibile;
- evitare tweak prestazionali "magici" che spesso creano più problemi di quanti ne risolvano.

Non è quindi un semplice script di debloat: è una **base di preparazione Windows ripetibile**, pensata per trasformare una nuova installazione in una macchina pronta all'uso con pochi comandi.

## Sicurezza

Il progetto mantiene intenzionalmente attivi i componenti fondamentali di sicurezza e manutenzione di Windows. Non disabilita Defender, Firewall, UAC o Windows Update e non modifica pagefile, mitigazioni di sicurezza, stack TCP/IP, HPET o scheduler.

Questa scelta rende il toolkit più adatto anche a macchine che dovranno essere assistite mesi dopo, perché evita configurazioni difficili da ricostruire o dipendenti da tweak non standard.

## Stato del progetto

Il toolkit è in sviluppo. Le modifiche e il loro ambito vengono documentati in `docs/Changes.md`.

Prima dell'uso su PC di produzione è consigliato eseguire il preset desiderato con `-WhatIf` e verificare le opzioni del relativo file JSON.

## Licenza

MIT License.