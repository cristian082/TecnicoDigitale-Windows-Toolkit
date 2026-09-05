# TecnicoDigitale Test Lab

Il laboratorio serve a misurare il Toolkit su Windows 11 Pro in modo riproducibile. Il riferimento operativo e una baseline pulita: non si tenta di rendere un PC cliente identico alla baseline, ma si usano le differenze per capire cosa e cambiato e individuare regressioni.

## Baseline

Baseline corrente:

`lab/baselines/Windows11-Pro-Clean-Before-Standard.json`

E stata catturata su Windows 11 Pro build 26200 prima dell'applicazione del preset Standard.

Le misure runtime (RAM, processi, servizi Running) sono snapshot e vanno confrontate dopo riavvio e in condizioni simili. Le differenze strutturali come AppX provisioned, startup e StartMode dei servizi sono piu significative.

## Deep Audit

`Deep-Audit.ps1` e read-only e salva i report in `lab/reports`.

Raccoglie processi, memoria, task, AppX, feature, capability, programmi installati, startup e servizi.

## Confronto baseline

`Compare-Baseline.ps1` confronta la baseline Windows 11 Pro con un Deep Audit del sistema attuale. Il confronto mostra metriche BEFORE/AFTER e differenze di processi, AppX provisioned, startup, servizi e software.

`Avvia-Lab.cmd` automatizza il flusso:

1. CREA DEEP AUDIT SISTEMA ATTUALE
2. CONFRONTA ULTIMO AUDIT CON BASELINE WINDOWS 11 PRO
3. AUDIT SERVIZI SISTEMA ATTUALE
4. APRI CARTELLA REPORT
5. APRI CARTELLA BASELINE
0. ESCI

L'opzione 2 seleziona automaticamente il Deep Audit piu recente in `lab/reports` e lo confronta con la baseline inclusa nel repository.

## Test Standard pulito

Sequenza consigliata:

1. ripristinare lo snapshot Windows 11 Pro pulito;
2. verificare che il Toolkit sia aggiornato;
3. eseguire solo Standard, senza installazione software;
4. riavviare Windows;
5. eseguire Deep Audit;
6. confrontare l'audit con la baseline;
7. controllare differenze e regressioni;
8. provare Undo e idempotenza in test separati.

L'installazione software e separata dai preset proprio per non contaminare il confronto prestazionale.

## Servizi

`Services-Audit.ps1` resta uno strumento read-only per studiare la configurazione del sistema corrente. Nessuna differenza rilevata diventa automaticamente un tweak: prima servono funzione, dipendenze, rischio, beneficio misurabile e test di regressione.

## Regola fondamentale

Il laboratorio deve trasformare ogni modifica del Toolkit da ipotesi a intervento misurato, documentato e ripristinabile. Non si approvano mass-disable di servizi, tweak prestazionali magici o modifiche che compromettono sicurezza, aggiornamenti, rete, stampa, audio, Bluetooth, Edge/WebView2 o software dell'utente.
