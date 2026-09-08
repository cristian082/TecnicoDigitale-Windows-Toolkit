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
- Lascia invariata la preferenza Widget dell'utente.
- Può allineare Start a sinistra.
- Disabilita evidenziazioni dinamiche della ricerca.
- Può disabilitare i suggerimenti web nella casella di ricerca senza disattivare Windows Search o l'indicizzazione.
- Può abilitare `Termina attività` nel menu contestuale delle app sulla barra delle applicazioni.
- Ambito: utente.

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
- Microsoft PowerToys è disponibile come scelta individuale tramite l'ID ufficiale `Microsoft.PowerToys` e non è incluso automaticamente nei pacchetti rapidi.
- Google Chrome dispone di fallback sull'installer ufficiale se l'installazione winget fallisce.
- Non usa driver updater di terze parti.
- Ambito: macchina/installer, secondo il pacchetto.

## Catalogo comandi applicazioni
- `shell:AppsFolder` e disponibile nel catalogo offline per aprire tutte le applicazioni installate e facilitare la creazione manuale di collegamenti.
- L'esecuzione controllata apre `explorer.exe shell:AppsFolder`; non installa, disinstalla o modifica applicazioni.
- Sono disponibili anche scorciatoie read-only per Avvio automatico utente/comune, Invia a, Elementi recenti, Download, Cestino, Caratteri, Stampanti e Risorse di rete.
- Le cartelle vengono soltanto aperte: eventuali aggiunte, spostamenti o eliminazioni restano azioni manuali dell'operatore.

## Strumenti Stampanti
- Mostra stampanti configurate, driver, porte, stato, condivisione e stato dello Spooler.
- Elenca i documenti presenti nelle code senza modificarli.
- Puo inviare una pagina di prova alla stampante selezionata dopo conferma.
- Apre Impostazioni Stampanti e scanner, Dispositivi e stampanti e Gestione stampa.
- Il reset della coda mostra prima i documenti, richiede conferma, arresta lo Spooler senza forzatura, elimina esclusivamente i file di spool e verifica il riavvio del servizio.
- Non esegue automaticamente DISM o SFC per un problema di stampa.

## Ibernazione e hiberfil.sys
- Strumento manuale separato disponibile negli Strumenti Tecnico; non viene eseguito dai preset.
- Mostra stato, dimensione di `hiberfil.sys`, spazio libero e stati di sospensione supportati.
- Puo disattivare l'ibernazione con `powercfg /hibernate off`, liberando lo spazio del file ma disabilitando anche Sospensione ibrida e Avvio rapido.
- Puo riattivarla con `powercfg /hibernate on`, ricreando `hiberfil.sys` e le funzioni dipendenti supportate dal PC.
- Entrambe le modifiche richiedono una conferma testuale esplicita; il Toolkit non riavvia il PC e verifica il risultato.
- Ambito: macchina. La modifica non entra nel backup/Undo della sessione; il ripristino e disponibile dalla stessa schermata.

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
