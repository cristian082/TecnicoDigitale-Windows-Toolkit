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
`v0.1.7 - Build 7 [development]`.

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
- Business → Standard: PASS al termine dell'esecuzione; Start tornato centrato, `TaskbarAl` rimosso perché prima di Business non esisteva, `GameDVR_Enabled=1`, nessun residuo Gaming.

### Bug scoperto dopo la matrice
Dopo un login successivo, nonostante Standard fosse stato applicato correttamente, Start e tornato a sinistra.

Causa: le build precedenti usavano `Set-TDTUserDword` con `AllUsers=true` anche per `TaskbarAl`. Business quindi registrava un componente Active Setup HKLM che, al login successivo, rieseguiva `reg.exe add ... TaskbarAl=0`. Questo avveniva fuori da ProfileState e poteva riapplicare Business dopo che Standard aveva correttamente rimosso `TaskbarAl`.

Build 7 corregge il problema:
- `TaskbarAl` Business viene applicato solo all'utente corrente (`AllUsers=false`) ed e gestito esclusivamente da ProfileState.
- Aggiunto helper per individuare/rimuovere l'Active Setup deterministico creato dal Toolkit.
- Migrazione Build 7: se esiste il vecchio Active Setup `TaskbarAl`, viene rimosso. Se si entra in Standard/Gaming e quel vecchio componente ha lasciato `TaskbarAl=0`, il residuo viene rimosso con backup della sessione, riportando il comportamento Windows predefinito centrato.
- Non vengono rimossi componenti Active Setup non riconosciuti come `TecnicoDigitale`.

Commit Build 7:
- `d2bde95c5d3d971a244f4a0e58be5bf69445d3a6` — helper cleanup Active Setup.
- `2fc24aa03037abd7be212cb4dd298b5c02754763` — TaskbarAl solo utente corrente + migrazione residuo.
- `0169570746d7b346a5996fc1f16097424066dae6` — v0.1.7 Build 7.

## Visual Effects Build 6
Build 6 ha introdotto un alleggerimento conservativo comune ai preset, senza usare `UserPreferencesMask` globale:
- VISUAL-001: animazione minimizza/massimizza disattivata.
- VISUAL-002: animazioni taskbar disattivate.
- VISUAL-003: `MenuShowDelay=100`.
Restano intatti font smussati, miniature, ombre e trasparenze.

## Icone Desktop
Standard/Gaming: Questo PC, File utente, Cestino; Rete e Pannello di controllo nascosti.
Business: aggiunge Rete e Pannello di controllo.
Le icone sono namespace Windows via `HideDesktopIcons`, non `.lnk`.

## Backup/Undo
Le scritture Gaming e Business gestite dal ProfileState passano anche dal backup Registry della sessione. Gap aperti: Active Setup non completamente coperto dall'Undo; Undo servizi futuro; migliorare UX selezione sessione.

## Software
I preset non installano software. `Installa-Software.ps1` e separato: Chrome, Firefox, VLC, WinRAR, 7-Zip, Everything, Adobe Reader, SumatraPDF, Steam, Playnite.

## Strumenti Tecnico attuali
`modules/TechnicianTools.ps1` include:
- diagnostica rete;
- flush DNS;
- cambio DNS rapido;
- riavvio scheda di rete;
- reset spooler/coda;
- triage processi sospetti read-only.

## Standard baseline
VM Windows 11 Pro build 26200, VirtualBox, ~8 GB. Primo test pulito Standard: processi 140→132; RAM fisica 2886→2709 MB; startup 6→6; servizi running 88→88; Edge/WebView 16→13; AppX provisioned 47→47; feature 14→14; capability 47→47. BITS/MDCoreSvc hanno mostrato differenze runtime ma nessuna modifica intenzionale Standard e presente nel codice.

## Lab
Usare `lab/Deep-Audit.ps1`, `Compare-Baseline.ps1`, `Services-Audit.ps1`, `Compare-Services.ps1` e baseline `Windows11-Pro-Clean-Before-Standard.json`. LTSC rimosso dal flusso operativo.

## Test immediato Build 7
Aggiornare la VM a Build 7 e rilanciare Standard. Verificare:
1. log con v0.1.7 Build 7;
2. eventuale riga `[Start/Taskbar] Rimosso residuo TaskbarAl della vecchia gestione Active Setup.`;
3. Start centrato;
4. `(Get-ItemProperty ... -Name TaskbarAl -ErrorAction SilentlyContinue).TaskbarAl` senza output;
5. dopo logout/login o riavvio Start deve restare centrato.

Solo dopo questo retest il bug post-login puo essere considerato chiuso.
