# Prompt di continuità progetto – TecnicoDigitale Windows Toolkit

Sto sviluppando con te il repository GitHub `cristian082/TecnicoDigitale-Windows-Toolkit`.

È un Toolkit Windows 11 per tecnici informatici: diagnostica, manutenzione, ottimizzazione sicura, pulizia, riparazione Windows, rete, stampanti, dischi/hardware, software/bloatware, strumenti rapidi, Backup/Undo e report prima/dopo.

## Filosofia non negoziabile

Il Toolkit deve essere sicuro anche su PC cliente sconosciuti. Non deve disabilitare Defender, Firewall, Windows Update, UAC o pagefile; non deve fare mass-disable dei servizi, tweak HPET/timer/scheduler/core parking/TCP casuali, rompere Edge/WebView2/rete/stampanti/audio/Bluetooth, cancellare software scelto dall'utente o usare optimizer placebo.

> Il Toolkit non applica una modifica che non sappiamo spiegare. Se una modifica non produce un beneficio concreto, documentiamo il motivo e non la applichiamo.

Flusso: `Diagnostica → Backup/Undo → Restore Point → ottimizzazione sicura → software opzionale separato → riparazione → report finale`.

## Metodo di lavoro obbligatorio

- GitHub è la fonte di verità.
- Prima di modificare un file, leggere sempre la versione corrente dalla repo.
- Dopo ogni modifica indicare il commit SHA.
- Correggere la causa reale degli errori.
- Compatibilità Windows PowerShell 5.1.
- Documentare le modifiche importanti.
- Ogni build destinata a test deve incrementare `version` e `build` in `VERSION.json`.

## Versione corrente

`v0.1.3 - Build 3 [development]`

Regola pratica: `0.1.1 Build 1 → 0.1.2 Build 2 → 0.1.3 Build 3` e così via. L'updater mostra versione/build locale, remota e installata.

## Architettura preset – REGOLA FONDAMENTALE

I preset sono stati definiti come stati desiderati, non come tweak da accumulare alla cieca.

- STANDARD = base sicura generale.
- GAMING = Standard + sole estensioni Gaming.
- BUSINESS = Standard + sole estensioni Business.

Deve essere possibile passare `Standard → Gaming → Business → Standard` senza formattare il PC, senza residui incompatibili e senza danneggiare impostazioni preesistenti del cliente.

Una modifica specifica di profilo deve essere reversibile. Quando si esce da un profilo, il Toolkit deve ripristinare lo stato precedente solo per le impostazioni di cui ha preso possesso. Se una di quelle impostazioni è stata modificata manualmente dopo l'applicazione del profilo, il Toolkit non deve sovrascriverla automaticamente: deve lasciarla invariata e avvisare.

Undo significa “riporta le impostazioni modificate da quella esecuzione allo stato precedente”, non “torna a Standard”.

## Stato transizioni Build 3

È stato introdotto `modules/ProfileState.ps1`.

Per Gaming registra in `backups/ProfileState.json` lo stato originale di:

- `HKCU\Software\Microsoft\GameBar\AutoGameModeEnabled`
- `HKCU\Software\Microsoft\GameBar\AllowAutoGameMode`
- `HKCU\System\GameConfigStore\GameDVR_Enabled`

Gaming applica le modifiche tramite `Set-TDTRegistryDword`, quindi anche la normale sessione Undo registra i valori precedenti.

Quando si passa da Gaming a Standard/Business, il Toolkit ripristina i valori pre-Gaming solo se sono ancora uguali ai valori applicati dal Toolkit. Se sono cambiati nel frattempo, non li sovrascrive e genera un warning.

`WhatIf` non deve modificare `ProfileState.json`.

Commit principali Build 3:

- `7bf26a2f6714b598b657da08e24c166b4475f1d5` — Gaming passa dal backup centralizzato.
- `02c794196b18652876415f6c4ba2163baefff310` — primo ProfileState.
- `575615ee1cb5ddf99f03d15eb156d4767608b6ae` — cattura stato originale prima di Gaming.
- `4babc8c6be5993ac284d5999cfcf9c580ddd9e7d` — Setup gestisce uscita sicura da Gaming.
- `384b1fb6de7dc22410010fc75107e93a3fae26ac` — WhatIf non muta ProfileState.

## Icone Desktop

Dalla Build 2 le icone dipendono dal preset, non dall'edizione Windows.

Standard/Gaming:
- Questo PC
- File utente
- Cestino
- Rete nascosta
- Pannello di controllo nascosto

Business:
- Questo PC
- File utente
- Cestino
- Rete
- Pannello di controllo

Le icone sono namespace Windows tramite `HideDesktopIcons`, non collegamenti `.lnk`.

Il test Build 2 su Windows 11 Pro ha confermato che rilanciando Standard sopra la precedente Standard Build 1, Rete e Pannello di controllo sono stati rimossi e Standard è terminato senza errori. Quindi il primo test di riapplicazione/idempotenza Standard è PASSATO.

## Preset e software

Standard non installa software. L'installazione è separata in `Installa-Software.ps1` con Chrome, Firefox, VLC, WinRAR, 7-Zip, Everything, Adobe Reader, SumatraPDF, Steam e Playnite.

Gaming deve evitare HPET/timer/scheduler/TCP/core parking/pagefile/mitigazioni. Business deve privilegiare affidabilità, sicurezza, BitLocker/Update/licenze/storage/pending reboot/M365/OneDrive e policy supportate.

## Backup / Undo

Le sessioni sono JSON in `backups`. `Undo.ps1` valida macchina e schema e ripristina i valori Registry registrati.

Gap ancora aperti:
- Active Setup non è ancora coperto completamente dall'Undo;
- Undo servizi da completare quando verranno introdotte modifiche servizi;
- migliorare ulteriormente selezione sessione/UX Undo;
- il nuovo gestore transizioni deve essere validato in VM prima di dichiararlo certificato.

## Standard: test pulito superato

Baseline Windows 11 Pro build 26200, VirtualBox, circa 8 GB RAM. Primo confronto pulito Standard:

- processi 140 → 132
- Working Set 4266.26 → 3822.48 MB
- Private Memory 1714.29 → 1515.79 MB
- RAM fisica usata 2886 → 2709 MB
- startup 6 → 6
- servizi running 88 → 88
- Edge/WebView processi 16 → 13
- AppX provisioned 47 → 47
- feature 14 → 14
- capability 47 → 47

BITS e MDCoreSvc hanno mostrato differenze nel comparatore, ma non esiste una modifica Standard intenzionale per quei servizi: non attribuirle al Toolkit senza prova.

## Lab

LTSC è rimosso dal flusso operativo. Usare:
- `lab/Deep-Audit.ps1`
- `lab/Compare-Baseline.ps1`
- `lab/Services-Audit.ps1`
- `lab/Compare-Services.ps1`
- `lab/baselines/Windows11-Pro-Clean-Before-Standard.json`

Deep Audit è read-only, SchemaVersion 4.

## Updater

Scarica `main.zip`, estrae in TEMP, valida il Toolkit, preserva backup/log/report e `lab/reports`, copia i file, elimina componenti LTSC obsoleti e verifica i file obbligatori.

Bug storici già corretti: vecchio `GetFullPath`, cartella spuria `n`, confronto path TEMP lungo vs alias 8.3. Se ricompaiono problemi path non aggiungere workaround infiniti: semplificare l'architettura.

## Prossimo test IMMEDIATO

Sulla VM attualmente in Standard Build 2:

1. aggiornare a `v0.1.3 Build 3`;
2. lanciare Gaming;
3. verificare log, icone e creazione `backups/ProfileState.json`;
4. senza snapshot intermedio, lanciare Business;
5. verificare che le impostazioni Gaming vengano ripristinate allo stato pre-Gaming e che compaiano Rete/Pannello di controllo;
6. lanciare Standard;
7. verificare che Rete/Pannello di controllo spariscano e non rimangano residui Business/Gaming;
8. solo dopo questi test considerare certificata la matrice base `Standard → Gaming → Business → Standard`.

Non usare ancora questa Build 3 alla cieca sui PC clienti: prima completare il test VM delle transizioni.

## Prossimi sviluppi

Dopo le transizioni: Check rapido/Semaforo Tecnico `OK / ATTENZIONE / PROBLEMA`, miglioramento comparatore servizi, diagnostica SMART/pending reboot/Update/pagefile/Secure Boot/VBS/Core Isolation e report più leggibili.

## Perimetro

Questo prompt riguarda esclusivamente TecnicoDigitale Windows Toolkit. Non riguarda rEFInd, Batocera, Home Assistant o altri progetti.

Quando ricevi questo prompt in una nuova chat: leggi prima lo stato live della repo, verifica `VERSION.json`, `Setup.ps1`, `modules/ProfileState.ps1`, `modules/Gaming.ps1`, `modules/Explorer.ps1`, i tre preset e il Lab; poi riprendi dal test delle transizioni Build 3 senza reinventare il progetto.
