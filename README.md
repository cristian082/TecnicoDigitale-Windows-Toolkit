# TecnicoDigitale Windows Toolkit

Toolkit PowerShell modulare per **preparare, diagnosticare, ottimizzare e standardizzare PC Windows 11** in modo controllato e ripetibile.

Il progetto segue un approccio conservativo: niente tweak prestazionali “magici”, niente disattivazioni indiscriminate di servizi e nessuna modifica a Defender, Firewall, UAC, Windows Update, pagefile, mitigazioni di sicurezza, stack TCP/IP, HPET o scheduler.

## Principio fondamentale

**Ogni modifica deve essere spiegabile, documentata e, quando tecnicamente possibile, ripristinabile.**

Consulta l'[indice della documentazione](docs/README.md).

## Moduli principali

| Area | Scopo | Modifica Windows |
|---|---|:---:|
| Diagnostica | Sistema, hardware, sicurezza e licenze | No |
| Restore/Backup | Protegge lo stato precedente | Sì |
| Explorer | Opzioni pratiche di Esplora file | Sì |
| Privacy | Riduce suggerimenti/promozioni selezionati | Sì |
| Start/Taskbar | Widget, ricerca e barra applicazioni | Sì |
| Gaming | Opzioni gaming conservative | Sì |
| Debloat | Solo pacchetti esplicitamente previsti | Sì |
| Software | Programmi scelti manualmente, separati dai preset | Sì |
| Undo | Ripristina le modifiche registrate | Sì |

## Preset

- **Standard** — PC domestico/general purpose;
- **Gaming** — Standard con sole opzioni gaming conservative;
- **Business** — postazioni professionali.

**I preset non installano software.** Questo mantiene prevedibili gli interventi e rende puliti i test BEFORE/AFTER.

## Installazione software

`Avvia-Toolkit.cmd` contiene una voce **INSTALLA SOFTWARE** separata. `Installa-Software.ps1` permette la scelta individuale dei programmi o selezioni rapide; `modules/Software.ps1` esegue le installazioni tramite winget.

## Avvio

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\Setup.ps1 -Preset Standard
```

Per simulare:

```powershell
.\Setup.ps1 -Preset Standard -WhatIf
```

## Backup e Undo

Prima delle modifiche registrabili il Toolkit crea una sessione in `backups/`. `Undo.ps1` usa queste informazioni per ripristinare i valori coperti dal sistema di backup. Undo è ancora in sviluppo e la documentazione deve indicare esplicitamente le aree non ancora coperte.

## Diagnostica

`modules/Diagnostics.ps1` produce report in `reports/` e analizza Windows, CPU, RAM, dischi, TRIM, startup, Defender, Firewall, UAC, BitLocker e licenze Windows/Office.

## Baseline e laboratorio

Il laboratorio usa una **baseline Windows 11 Pro pulita** come riferimento diagnostico:

`lab/baselines/Windows11-Pro-Clean-Before-Standard.json`

La baseline non viene imposta ai PC clienti. Office, stampanti, VPN, gestionali, driver, servizi e software professionali possono essere perfettamente legittimi.

Il flusso operativo del Lab è:

1. Deep Audit del sistema attuale;
2. confronto automatico con la baseline Windows 11 Pro;
3. analisi delle differenze strutturali e runtime;
4. verifica delle regressioni.

`Avvia-Lab.cmd` automatizza il flusso e `lab/Compare-Baseline.ps1` produce il confronto.

## Filosofia

TecnicoDigitale Windows Toolkit non è un registry cleaner né uno script di debloat aggressivo. Un servizio on-demand che non produce un consumo significativo da fermo viene normalmente lasciato intatto. Ogni modifica deve avere un motivo verificabile e un beneficio concreto.

## Test

Per misurare un preset:

1. ripristinare snapshot/baseline pulita;
2. eseguire solo il preset;
3. riavviare;
4. creare Deep Audit AFTER;
5. confrontare con la baseline;
6. controllare regressioni;
7. installare eventuale software solo successivamente.

## Licenza

MIT License.
