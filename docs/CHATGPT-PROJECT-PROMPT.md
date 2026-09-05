# Prompt di continuità progetto – TecnicoDigitale Windows Toolkit

Repository: `cristian082/TecnicoDigitale-Windows-Toolkit`.

Toolkit Windows 11 per tecnici: diagnostica, manutenzione, ottimizzazione sicura, pulizia/riparazione, rete/stampanti/storage, software separato, Backup/Undo e report.

## Filosofia non negoziabile
Il Toolkit deve essere sicuro su PC cliente sconosciuti. Non disabilitare Defender, Firewall, Update, UAC, pagefile; niente mass-disable servizi, HPET/timer/scheduler/core parking/TCP casuali, rotture Edge/WebView2/rete/stampanti/audio/Bluetooth, rimozione software utente o optimizer placebo.

> Il Toolkit non applica una modifica che non sappiamo spiegare. Se non produce beneficio concreto, la documentiamo e non la applichiamo.

## Metodo
- GitHub è fonte di verità; leggere sempre il file live prima di modificarlo.
- Compatibilità Windows PowerShell 5.1.
- Dopo modifiche indicare commit SHA.
- Ogni build testabile incrementa `version` e `build`.

## Versione corrente
`v0.1.5 - Build 5 [development]`.

## Preset e transizioni
STANDARD = base sicura. GAMING = Standard + estensioni Gaming. BUSINESS = Standard + estensioni Business.

Regola fondamentale: deve essere possibile `Standard → Gaming → Business → Standard` senza formattazione, residui incompatibili o sovrascrittura cieca delle preferenze preesistenti. Le impostazioni specifiche di profilo sono possedute temporaneamente dal Toolkit: quando si esce dal profilo vengono ripristinate al valore precedente solo se sono ancora al valore applicato dal Toolkit. Se sono state cambiate manualmente, il Toolkit non le sovrascrive e avvisa.

Undo resta per-esecuzione: ripristina lo stato precedente alla singola esecuzione, non significa “torna a Standard”.

## ProfileState
`modules/ProfileState.ps1` usa `backups/ProfileState.json`.

Gaming gestisce e ripristina:
- `HKCU\Software\Microsoft\GameBar\AutoGameModeEnabled`
- `HKCU\Software\Microsoft\GameBar\AllowAutoGameMode`
- `HKCU\System\GameConfigStore\GameDVR_Enabled`

Business gestisce e ripristina:
- `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarAl`

## Matrice funzionale testata in VM
Su Windows 11 Pro build 26200 / VirtualBox:
- Standard → Gaming: PASS.
- Gaming → Business: PASS; i valori Gaming sono tornati esattamente allo stato precedente.
- Business Build 4: Start a sinistra PASS.
- Business → Standard: PASS; Start tornato centrato, `TaskbarAl` rimosso perché prima di Business non esisteva, `GameDVR_Enabled=1`, nessun residuo Gaming.
- Matrice completa `Standard → Gaming → Business → Standard`: PASS.

Durante l'ultimo controllo `ProfileState.json` mostrava `Business: []` invece di `Business: null`, pur con ownership già vuota. Build 5 corregge solo questa normalizzazione, rimuovendo il wrapping che faceva sopravvivere un array vuoto nel risultato di `Restore-TDTOwnedRegistryEntries`.

Commit Build 5:
- `d810b2dfb34bc37a5c95d508c8573ee03a5005a9` — normalizza ownership vuota a `null`.
- `09ab83d1b44487662078e0ce4a9a94e5bb237b85` — v0.1.5 Build 5.

## Business Build 4
Build 4 ha corretto `presets/Business.json` a `LeftAlignTaskbar=true` e introdotto ownership reversibile di `TaskbarAl`.

Commit principali:
- `fca9b990ea490ed73d46de6387e0e7b49635d4f1` — ownership Business TaskbarAl.
- `6dd0d191d578cdc54a473f65a8a008ba4fb7b99c` — Setup gestisce entrata/uscita Business.
- `d6ab55eb5e994acb45bbefe17ef4b9d262b5b343` — Business Start a sinistra.
- `eb6b555e66d9bab25d20d7a8279c65aac0af1689` — v0.1.4 Build 4.

## Icone Desktop
Standard/Gaming: Questo PC, File utente, Cestino; Rete e Pannello di controllo nascosti.
Business: aggiunge Rete e Pannello di controllo.
Le icone sono namespace Windows via `HideDesktopIcons`, non `.lnk`.

## Backup/Undo
Le scritture Gaming e Business gestite dal ProfileState passano anche dal backup Registry della sessione. Gap aperti: Active Setup non completamente coperto dall'Undo; Undo servizi futuro; migliorare UX selezione sessione.

## Software
I preset non installano software. `Installa-Software.ps1` è separato: Chrome, Firefox, VLC, WinRAR, 7-Zip, Everything, Adobe Reader, SumatraPDF, Steam, Playnite.

## Standard baseline
VM Windows 11 Pro build 26200, VirtualBox, ~8 GB. Primo test pulito Standard: processi 140→132; RAM fisica 2886→2709 MB; startup 6→6; servizi running 88→88; Edge/WebView 16→13; AppX provisioned 47→47; feature 14→14; capability 47→47. BITS/MDCoreSvc hanno mostrato differenze runtime ma nessuna modifica intenzionale Standard è presente nel codice.

## Lab
Usare `lab/Deep-Audit.ps1`, `Compare-Baseline.ps1`, `Services-Audit.ps1`, `Compare-Services.ps1` e baseline `Windows11-Pro-Clean-Before-Standard.json`. LTSC rimosso dal flusso operativo.

## Prossimo sviluppo immediato
Conclusa la matrice preset, il prossimo lavoro è alleggerire le visualizzazioni/animazioni di Windows in modo conservativo e misurabile, senza introdurre tweak aggressivi o peggiorare accessibilità/leggibilità.
