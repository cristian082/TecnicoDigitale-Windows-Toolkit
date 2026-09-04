# Servizi Windows

Questa pagina documenta il metodo usato dal progetto prima di modificare qualsiasi servizio Windows.

## Principio

**Il Toolkit non disabilita servizi perché il loro nome sembra inutile.**

Windows 11 utilizza ampiamente servizi manuali, trigger-start e per-utente. Un servizio installato ma fermo può avere un costo praticamente irrilevante e può essere avviato solo quando una funzione lo richiede.

Per questo il progetto preferisce, quando tecnicamente giustificato, il comportamento **Manuale / on-demand** alla disabilitazione permanente.

## Baseline LTSC 2024

È stata acquisita una prima fotografia pulita di Windows 11 Enterprise LTSC 2024 (build 26100) in VirtualBox tramite `lab/Services-Audit.ps1`.

Risultato iniziale:

- servizi totali: 261;
- in esecuzione al momento del rilevamento: 84;
- automatici: 59;
- manuali: 191;
- disabilitati: 11.

Questo dato è importante: LTSC non ottiene il proprio comportamento semplicemente disabilitando in massa i servizi. La maggior parte rimane disponibile in modalità manuale/on-demand.

La baseline Windows 11 Pro 25H2 verrà acquisita separatamente e confrontata con LTSC prima di approvare modifiche.

## Classificazione prevista

Ogni servizio studiato dovrà finire in una delle seguenti categorie:

### NON TOCCARE
Servizio strutturale, di sicurezza, manutenzione, rete o comunque privo di un beneficio concreto derivante dalla modifica.

### MANUALE / ON-DEMAND
Possibile candidato solo quando il comportamento è verificato, le dipendenze sono comprese e la modifica porta Pro verso un comportamento Windows già supportato.

### DISABILITABILE SE LA FUNZIONE NON SERVE
Categoria riservata a funzionalità realmente opzionali e solo dopo test. Non significa che il Toolkit debba disabilitarle automaticamente.

## Scheda obbligatoria per ogni servizio modificato

Prima di inserire un servizio nel Toolkit dovranno essere documentati:

- nome tecnico e nome visualizzato;
- a cosa serve;
- stato e tipo di avvio su Windows 11 Pro stock;
- stato e tipo di avvio su Windows 11 Enterprise LTSC stock;
- eventuale avvio ritardato;
- trigger di avvio;
- dipendenze e servizi dipendenti;
- funzionalità Windows coinvolte;
- beneficio atteso;
- possibili effetti collaterali;
- test effettuati;
- decisione TecnicoDigitale;
- modalità di Undo.

## Servizi che non verranno trattati come normali tweak

Il progetto non intende disabilitare per ottenere presunte prestazioni servizi strutturali o di sicurezza come Windows Update, BITS, RPC, WMI, Registro eventi, Utilità di pianificazione, DHCP/DNS, Plug and Play, Servizi di crittografia, Windows Installer, Defender e Firewall.

Anche Windows Search non verrà disabilitato semplicemente per ridurre il numero di servizi: ricerca e indicizzazione devono essere valutate come funzionalità Windows, non come processo da eliminare.

## Stato dello studio

`lab/Services-Audit.ps1` è attualmente uno strumento di sola lettura. **Non modifica né arresta servizi.**

Prima di creare un modulo `Services.ps1` verranno confrontate almeno le baseline LTSC 2024 e Pro 25H2 e verranno eseguiti test funzionali sui candidati. Fino ad allora questa documentazione descrive lo studio, non una lista di servizi approvati per la disabilitazione.