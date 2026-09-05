# TecnicoDigitale Windows Toolkit

Toolkit PowerShell modulare per **preparare, diagnosticare, ottimizzare e standardizzare PC Windows 11** in modo controllato e ripetibile.

Il progetto segue un approccio conservativo: niente tweak prestazionali “magici”, niente disattivazioni indiscriminate di servizi e nessuna modifica a Defender, Firewall, UAC, Windows Update, pagefile, mitigazioni di sicurezza, stack TCP/IP, HPET o scheduler.

## Principio fondamentale

**Ogni modifica deve essere spiegabile, documentata e, quando tecnicamente possibile, ripristinabile.**

Non basta sapere quale chiave di registro viene cambiata: la documentazione spiega anche a cosa serve la funzione originale di Windows, perché il Toolkit interviene, cosa non viene modificato, quali effetti collaterali sono possibili e come avviene il ripristino.

Consulta l'[indice della documentazione](docs/README.md).

## Moduli principali

| Area | Scopo | Modifica Windows |
|---|---|:---:|
| Diagnostica | Raccoglie informazioni su sistema, hardware, sicurezza e licenze | No |
| Restore/Backup | Protegge lo stato precedente alle modifiche | Sì |
| Explorer | Configura opzioni pratiche di Esplora file | Sì |
| Privacy | Riduce suggerimenti e contenuti promozionali selezionati | Sì |
| Start/Taskbar | Configura Widget, ricerca e barra delle applicazioni | Sì |
| Gaming | Applica solo opzioni gaming conservative | Sì |
| Debloat | Rimuove solo pacchetti esplicitamente previsti dal profilo | Sì |
| Software | Installa solo i programmi scelti manualmente, separatamente dai preset | Sì |
| Undo | Ripristina le modifiche registrate dal sistema di backup | Sì |

## Documentazione delle singole funzioni

La documentazione dettagliata è divisa per area:

- [Explorer](docs/Explorer.md)
- [Privacy](docs/Privacy.md)
- [Start e Taskbar](docs/Start-Taskbar.md)
- [Gaming](docs/Gaming.md)
- [Software](docs/Software.md)
- [Studio dei servizi Windows](docs/Services.md)

Ogni nuova modifica dovrà essere accompagnata dalla propria scheda tecnica e funzionale.

## Preset

Sono previsti tre profili principali:

- **Standard** — PC domestico/general purpose;
- **Gaming** — mantiene l'approccio conservativo aggiungendo le sole opzioni dedicate al gioco;
- **Business** — configurazione sobria per postazioni professionali.

I preset sono file JSON nella cartella `presets/`.

**I preset non installano software.** Questo rende gli interventi più prevedibili sui PC dei clienti e permette test BEFORE/AFTER puliti, senza confondere le ottimizzazioni Windows con processi, servizi, task o elementi di avvio aggiunti da applicazioni appena installate.

## Installazione software

Dal launcher `Avvia-Toolkit.cmd` è disponibile la voce **INSTALLA SOFTWARE**.

`Installa-Software.ps1` permette di selezionare singolarmente i programmi desiderati oppure usare selezioni rapide per PC nuovo o gaming. L'installazione effettiva è gestita da `modules/Software.ps1` tramite winget.

L'installazione software è volontaria e separata da Standard/Gaming/Business.

## Avvio

Aprire PowerShell come amministratore nella cartella del progetto:

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\Setup.ps1 -Preset Standard
```

Per simulare l'intervento prima di applicarlo:

```powershell
.\Setup.ps1 -Preset Standard -WhatIf
```

È disponibile anche `Avvia-Toolkit.cmd` come launcher interattivo.

## Backup e Undo

Prima delle modifiche registrabili il Toolkit crea una sessione di backup nella cartella `backups/`. `Undo.ps1` può utilizzare queste informazioni per riportare i valori registrati allo stato precedente.

Il sistema Undo è ancora in sviluppo: non tutte le categorie di intervento sono già coperte. La documentazione segnala esplicitamente i casi non ancora gestiti completamente, invece di promettere un ripristino che il codice non può garantire.

## Diagnostica

`modules/Diagnostics.ps1` esegue un check-up in sola lettura e produce un report in `reports/`. L'obiettivo è arrivare a una valutazione tecnica prima delle modifiche e a un confronto prima/dopo.

Tra le aree già analizzate o in sviluppo: Windows, CPU, RAM, dischi, TRIM, avvio, Defender, Firewall, UAC, BitLocker e stato/canale delle licenze Windows e Office.

## Baseline e laboratorio

La direzione del laboratorio è il confronto fra una **baseline Windows 11 Pro pulita** e lo stato della macchina dopo un intervento.

La baseline non è un'immagine da imporre ai PC dei clienti: è un riferimento diagnostico. Un computer reale può avere legittimamente Office, stampanti, VPN, gestionali, driver, servizi e software professionali diversi dalla macchina di riferimento.

La baseline iniziale è conservata in:

`lab/baselines/Windows11-Pro-Clean-Before-Standard.json`

La precedente ricerca Pro vs LTSC resta utile come studio storico, soprattutto perché ha mostrato che non esiste una giustificazione per disabilitare servizi Windows in massa. Il lavoro futuro del laboratorio è orientato a confronti BEFORE/AFTER e alla rilevazione di regressioni.

## Filosofia

TecnicoDigitale Windows Toolkit non vuole essere un registry cleaner o uno script di debloat aggressivo. L'obiettivo è costruire una base professionale per preparare e diagnosticare Windows 11 in modo ripetibile.

Quando una funzione Windows è già on-demand e non produce un consumo significativo da ferma, normalmente viene lasciata intatta. Quando una modifica viene proposta, deve esserci un motivo verificabile.

## Stato del progetto

Il Toolkit è in sviluppo e viene testato inizialmente in macchine virtuali pulite prima dell'uso su PC reali.

Per misurare un preset in modo corretto il flusso di test è:

1. snapshot/baseline pulita;
2. esecuzione del solo preset;
3. riavvio;
4. audit AFTER;
5. confronto BEFORE/AFTER;
6. controllo delle regressioni;
7. eventuale installazione software solo successivamente.

Prima dell'uso su macchine di produzione è consigliata la modalità `-WhatIf` e la verifica del preset scelto.

## Licenza

MIT License.
