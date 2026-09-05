# Prompt di continuità progetto – TecnicoDigitale Windows Toolkit

Repository: `cristian082/TecnicoDigitale-Windows-Toolkit`.

Toolkit Windows 11 per tecnici: diagnostica, manutenzione, ottimizzazione sicura, pulizia/riparazione, rete/stampanti/storage, software separato, Backup/Undo e report.

## Filosofia non negoziabile
Il Toolkit deve essere sicuro su PC cliente sconosciuti. Non disabilitare Defender, Firewall, Update, UAC, pagefile; niente mass-disable servizi, HPET/timer/scheduler/core parking/TCP casuali, rotture Edge/WebView2/rete/stampanti/audio/Bluetooth, rimozione software utente o optimizer placebo.

> Il Toolkit non applica una modifica che non sappiamo spiegare. Se non produce beneficio concreto, la documentiamo e non la applichiamo.

## Metodo
- GitHub e fonte di verita; leggere sempre il file live prima di modificarlo.
- Compatibilita Windows PowerShell 5.1.
- Dopo modifiche indicare commit SHA.
- Ogni build testabile incrementa `version` e `build`.

## Versione corrente
`v0.1.8 - Build 8 [development]`.

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
- Business → Standard: PASS al termine dell'esecuzione; Start tornato centrato, `TaskbarAl` rimosso perche prima di Business non esisteva, `GameDVR_Enabled=1`, nessun residuo Gaming.

### Bug TaskbarAl / Active Setup corretto in Build 7
Dopo un login successivo, nonostante Standard fosse stato applicato correttamente, Start era tornato a sinistra.

Causa: le build precedenti usavano `Set-TDTUserDword` con `AllUsers=true` anche per `TaskbarAl`. Business registrava quindi un componente Active Setup HKLM che, al login successivo, rieseguiva `reg.exe add ... TaskbarAl=0`, fuori dal controllo del ProfileState.

Build 7 corregge il problema:
- `TaskbarAl` Business viene applicato solo all'utente corrente (`AllUsers=false`) ed e gestito esclusivamente da ProfileState.
- helper per individuare/rimuovere l'Active Setup deterministico creato dal Toolkit.
- migrazione: se esiste il vecchio Active Setup `TaskbarAl`, viene rimosso; in Standard/Gaming un eventuale residuo `TaskbarAl=0` viene eliminato con backup della sessione.
- non vengono rimossi componenti Active Setup non riconosciuti come TecnicoDigitale.

Commit Build 7:
- `d2bde95c5d3d971a244f4a0e58be5bf69445d3a6` — helper cleanup Active Setup.
- `2fc24aa03037abd7be212cb4dd298b5c02754763` — TaskbarAl solo utente corrente + migrazione residuo.
- `0169570746d7b346a5996fc1f16097424066dae6` — v0.1.7 Build 7.

Il retest Standard immediato e risultato corretto visivamente. Resta utile, prima della certificazione cliente, confermare ancora una volta che dopo logout/login o riavvio Start resti centrato.

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

## Strumenti Tecnico Build 8
`Strumenti-Tecnico.ps1` carica `modules/TechnicianTools.ps1`. Build 8 trasforma il vecchio menu rapido in un vero menu tecnico a categorie.

Menu principale:
1. Rete
2. Windows Update
3. Integrita Windows - DISM / SFC
4. Dischi / SMART / CHKDSK
5. Stampanti
6. Servizi
7. Driver / dispositivi
8. Avvio automatico (read-only)
9. Eventi Windows recenti
10. BitLocker (read-only)
11. Spazio disco / TEMP (read-only)
12. Triage processi sospetti (read-only)

Funzioni principali:
- rete rapida/avanzata, flush DNS, preset DNS, restart scheda;
- stato Windows Update, ricerca aggiornamenti senza installazione, reset cache Update con conferma;
- DISM CheckHealth/ScanHealth/RestoreHealth, SFC e sequenza completa DISM+SFC;
- stato dischi/SMART e CHKDSK `/scan` sul volume scelto;
- diagnostica stampanti/porte/spooler e reset coda;
- stato servizi importanti, Automatici fermi, restart singolo servizio esplicito senza cambiare StartType;
- dispositivi PnP problematici, driver recenti, `pnputil /scan-devices`;
- startup e task Logon read-only;
- errori/critici System+Application ultime 24 ore;
- stato BitLocker senza mostrare/esportare chiavi;
- volumi, spazio libero e stima TEMP senza cancellazioni;
- triage processi read-only.

Documentazione dettagliata: `docs/TECHNICIAN-TOOLS.md`.

Commit Build 8:
- `e5d25ad71816b4dfecbc5df4827339735cf192b6` — menu tecnico completo.
- `1e6a11a01063bf934233129208f96f4b1498aab0` — documentazione Strumenti Tecnico.
- `a35c1a0ee5bc7453da2f71b1645fbf0b9c2caca1` — v0.1.8 Build 8.

## Standard baseline
VM Windows 11 Pro build 26200, VirtualBox, ~8 GB. Primo test pulito Standard: processi 140→132; RAM fisica 2886→2709 MB; startup 6→6; servizi running 88→88; Edge/WebView 16→13; AppX provisioned 47→47; feature 14→14; capability 47→47. BITS/MDCoreSvc hanno mostrato differenze runtime ma nessuna modifica intenzionale Standard e presente nel codice.

## Lab
Usare `lab/Deep-Audit.ps1`, `Compare-Baseline.ps1`, `Services-Audit.ps1`, `Compare-Services.ps1` e baseline `Windows11-Pro-Clean-Before-Standard.json`. LTSC rimosso dal flusso operativo.

## Test immediato Build 8
Aggiornare la VM a v0.1.8 Build 8 e aprire `Strumenti-Tecnico.ps1`.

Smoke test minimo:
1. aprire tutti i sottomenu e tornare indietro;
2. eseguire tutte le funzioni read-only;
3. verificare che le azioni con impatto chiedano conferma e che `N` annulli davvero;
4. testare rete/spooler su VM;
5. su snapshot sacrificabile testare Windows Update cache, DISM RestoreHealth, SFC e CHKDSK `/scan`;
6. nessuna funzione deve riavviare automaticamente Windows o modificare Defender/Firewall/UAC/Update policy/start type servizi.
