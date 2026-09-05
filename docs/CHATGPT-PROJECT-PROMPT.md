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
`v0.1.4 - Build 4 [development]`.

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

Build 3 testata in VM:
- Standard → Gaming: PASS.
- ProfileState Gaming verificato: i primi due valori non esistevano; `GameDVR_Enabled` era 1; Gaming ha applicato 1/1/0.
- Gaming → Business: PASS. Uscendo da Gaming i primi due valori sono stati rimossi e `GameDVR_Enabled` è tornato a 1, senza warning/errori.

## Business Build 4
Durante il test Business Build 3 è emerso che Start restava centrato anche dopo riavvio. Causa reale: `presets/Business.json` aveva `LeftAlignTaskbar=false`; `Start-Taskbar.ps1` applica `TaskbarAl=0` solo quando il flag è true.

Build 4 corregge Business a `LeftAlignTaskbar=true` e aggiunge ownership reversibile di `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarAl`.

Entrando in Business viene salvato lo stato precedente di `TaskbarAl`; Business applica 0 (sinistra). Uscendo da Business verso Standard/Gaming, il valore precedente viene ripristinato solo se è ancora 0. Questo evita residui Business e non sovrascrive una modifica manuale successiva.

Commit Build 4 principali:
- `fca9b990ea490ed73d46de6387e0e7b49635d4f1` — ownership Business TaskbarAl.
- `6dd0d191d578cdc54a473f65a8a008ba4fb7b99c` — Setup gestisce entrata/uscita Business.
- `d6ab55eb5e994acb45bbefe17ef4b9d262b5b343` — Business Start a sinistra.
- `eb6b555e66d9bab25d20d7a8279c65aac0af1689` — v0.1.4 Build 4.

## Icone Desktop
Standard/Gaming: Questo PC, File utente, Cestino; Rete e Pannello di controllo nascosti.
Business: aggiunge Rete e Pannello di controllo.
Le icone sono namespace Windows via `HideDesktopIcons`, non `.lnk`.

Standard Build 2 riapplicato sopra Standard: PASS, incluse icone e primo smoke test idempotenza.

## Backup/Undo
Le scritture Gaming e Business gestite dal ProfileState passano anche dal backup Registry della sessione. Gap aperti: Active Setup non completamente coperto dall'Undo; Undo servizi futuro; migliorare UX selezione sessione.

## Software
I preset non installano software. `Installa-Software.ps1` è separato: Chrome, Firefox, VLC, WinRAR, 7-Zip, Everything, Adobe Reader, SumatraPDF, Steam, Playnite.

## Standard baseline
VM Windows 11 Pro build 26200, VirtualBox, ~8 GB. Primo test pulito Standard: processi 140→132; RAM fisica 2886→2709 MB; startup 6→6; servizi running 88→88; Edge/WebView 16→13; AppX provisioned 47→47; feature 14→14; capability 47→47. BITS/MDCoreSvc hanno mostrato differenze runtime ma nessuna modifica intenzionale Standard è presente nel codice.

## Lab
Usare `lab/Deep-Audit.ps1`, `Compare-Baseline.ps1`, `Services-Audit.ps1`, `Compare-Services.ps1` e baseline `Windows11-Pro-Clean-Before-Standard.json`. LTSC rimosso dal flusso operativo.

## Test immediato Build 4
La VM è attualmente nello stato Business ottenuto con Build 3, con Start ancora centrato e Gaming già correttamente ripristinato.

1. Aggiornare a v0.1.4 Build 4.
2. Rilanciare Business sopra Business.
3. Verificare che Start vada a sinistra e che Rete/Pannello di controllo restino presenti.
4. Controllare `ProfileState.json`: deve contenere Business/TaskbarAl con stato precedente e AppliedValue=0.
5. Poi lanciare Standard sopra Business.
6. Verificare riga `[Preset] Uscita da Business: ripristino allineamento Start precedente`.
7. Verificare che Start torni al precedente stato centrato, Rete/Pannello di controllo spariscano e Gaming non venga toccato.
8. Solo allora dichiarare completata la prima matrice `Standard → Gaming → Business → Standard`.

Non usare ancora la build alla cieca sui PC clienti prima della chiusura del test VM.
