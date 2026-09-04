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
| Software | Installa il software previsto dal preset | Sì |
| Undo | Ripristina le modifiche registrate dal sistema di backup | Sì |

## Documentazione delle singole funzioni

La documentazione dettagliata è divisa per area:

- [Explorer](docs/Explorer.md)
- [Privacy](docs/Privacy.md)
- [Start e Taskbar](docs/Start-Taskbar.md)
- [Gaming](docs/Gaming.md)
- [Studio dei servizi Windows](docs/Services.md)

Ogni nuova modifica dovrà essere accompagnata dalla propria scheda tecnica e funzionale.

## Servizi Windows e confronto LTSC

Il progetto sta studiando Windows 11 Enterprise LTSC 2024 come riferimento tecnico, senza cercare di trasformare Windows Pro in LTSC tramite disattivazioni indiscriminate.

Lo strumento di laboratorio `lab/Services-Audit.ps1` fotografa la configurazione dei servizi senza modificarli. Le baseline di Windows 11 Pro e LTSC vengono confrontate prima di approvare qualsiasi intervento.

Un servizio presente o configurato come Manuale non viene considerato automaticamente uno spreco di risorse. Il Toolkit preferisce lasciare a Windows il comportamento trigger/on-demand quando non esiste un beneficio concreto nel modificarlo.

## Preset

Sono previsti tre profili principali:

- **Standard** — PC domestico/general purpose;
- **Gaming** — mantiene l'approccio conservativo aggiungendo le sole opzioni dedicate al gioco;
- **Business** — configurazione sobria per postazioni professionali.

I preset sono file JSON nella cartella `presets/`.

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

`modules/Diagnostics.ps1` esegue un check-up in sola lettura e produce un report in `reports/`. L'obiettivo è arrivare a una valutazione tecnica prima delle modifiche e, successivamente, a un confronto prima/dopo.

Tra le aree già analizzate o in sviluppo: Windows, CPU, RAM, dischi, TRIM, avvio, Defender, Firewall, UAC, BitLocker e stato/canale delle licenze Windows e Office.

## Filosofia

TecnicoDigitale Windows Toolkit non vuole essere un registry cleaner o uno script di debloat aggressivo. L'obiettivo è costruire una base professionale per preparare e diagnosticare Windows 11 in modo ripetibile.

Quando una funzione Windows è già on-demand e non produce un consumo significativo da ferma, normalmente viene lasciata intatta. Quando una modifica viene proposta, deve esserci un motivo verificabile.

## Stato del progetto

Il Toolkit è in sviluppo e viene testato inizialmente in macchine virtuali pulite prima dell'uso su PC reali. Il laboratorio include confronti fra installazioni stock e test di idempotenza/ripristino.

Prima dell'uso su macchine di produzione è consigliata la modalità `-WhatIf` e la verifica del preset scelto.

## Licenza

MIT License.