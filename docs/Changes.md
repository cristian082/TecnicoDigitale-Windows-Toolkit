# Registro modifiche

Questo documento descrive cosa modifica il toolkit e con quale ambito.

## Restore
- Abilita Protezione sistema su `C:` quando possibile.
- Chiede se creare un nuovo punto di ripristino prima delle modifiche.
- Ambito: macchina.

## Privacy
- Disabilita suggerimenti/promozioni di Windows tramite chiavi utente.
- Disabilita l'ID pubblicitario, se richiesto dal preset.
- Ambito: utente.
- Non disabilita telemetria di sistema, Defender, Firewall, UAC o Windows Update.

## Explorer
- Mostra estensioni file.
- Può aprire Esplora file su Questo PC.
- Può mostrare file nascosti.
- Ambito: utente.

## Start e Taskbar
- Può nascondere Widgets tramite policy macchina.
- Può allineare Start a sinistra.
- Disabilita evidenziazioni dinamiche della ricerca.
- Può disabilitare i suggerimenti web nella casella di ricerca senza disattivare Windows Search o l'indicizzazione.
- Può abilitare `Termina attività` nel menu contestuale delle app sulla barra delle applicazioni.
- Ambito: macchina per Widgets, utente per le altre impostazioni.

## Debloat
- Rimuove solo i pacchetti Appx esplicitamente elencati nel preset.
- Non rimuove Microsoft Store, Edge, componenti runtime, WebView2 o framework.
- Ambito: utente/pacchetto secondo il componente.

## Gaming
- Può abilitare Game Mode.
- Può disabilitare Game DVR in background.
- Non modifica timer, HPET, scheduler, mitigazioni CPU, rete o servizi di sistema.
- Ambito: utente.

## Software
- Installa software mediante `winget` usando ID espliciti.
- Google Chrome dispone di fallback sull'installer ufficiale se l'installazione winget fallisce.
- Non usa driver updater di terze parti.
- Ambito: macchina/installer, secondo il pacchetto.

## Laboratorio VirtualBox
La procedura di test e documentata in `lab/README.md`.

La baseline deve essere installata offline per evitare che Windows Setup/OOBE scarichi aggiornamenti, driver o app durante la creazione dell'immagine di riferimento.

Snapshot previsti:
- `00-WIN11-STOCK-OFFLINE`: Windows appena installato, rete mai abilitata e nessun tweak applicato.
- `01-WIN11-UPDATED`: Windows aggiornato e pronto per i normali test del Toolkit.

L'obiettivo e distinguere chiaramente:

`Windows stock offline -> Windows aggiornato -> Windows dopo TecnicoDigitale Toolkit`

## Check-up diagnostico - pianificato
Il prossimo modulo diagnostico dovra essere inizialmente read-only e includere almeno:
- Windows: edizione, build, stato di attivazione e canale OEM/Retail/Volume MAK/KMS;
- eventuale licenza OEM firmware, senza mostrare product key completi;
- Office: versione, stato di attivazione, canale e scadenza quando disponibile;
- classificazione licenze: `OK`, `DA VERIFICARE`, `NON ATTIVO`;
- CPU, RAM, dischi, spazio, TRIM e salute disco quando disponibile;
- programmi in avvio automatico;
- stato Defender, Firewall e UAC;
- eventuale riavvio Windows Update pendente.

Un'attivazione Volume/KMS non deve essere automaticamente classificata come falsa: puo essere legittima in un'organizzazione autorizzata.

## Da non fare
Il progetto evita intenzionalmente tweak che disabilitano o alterano:
- Microsoft Defender
- Windows Firewall
- UAC
- Windows Update
- pagefile
- mitigazioni di sicurezza
- Core Isolation / VBS / HVCI come presunta ottimizzazione generale
- TCP/IP e stack rete
- HPET / timer di sistema
- scheduler CPU
- servizi critici

## Ripristino
Le modifiche per-utente sono reversibili reimpostando le relative chiavi di registro. Il punto di ripristino offre un ulteriore livello di sicurezza per le modifiche di sistema. E pianificato un modulo Undo con backup esplicito delle impostazioni modificate.
