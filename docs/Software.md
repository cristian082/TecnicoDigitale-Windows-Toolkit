# Software — installazione separata dai preset

## SOFTWARE-001 — Installazione software selettiva

### Obiettivo

L'installazione delle applicazioni è separata dai preset `Standard`, `Gaming` e `Business`.

Questa scelta serve a due scopi:

1. evitare che un intervento di ottimizzazione installi programmi non richiesti sul PC del cliente;
2. mantenere puliti i test BEFORE/AFTER dei preset, senza mescolare l'effetto delle ottimizzazioni con nuovi processi, servizi, task o elementi di avvio introdotti dalle applicazioni installate.

### Comportamento

Dal launcher principale è disponibile la voce `INSTALLA SOFTWARE`.

L'utente può selezionare singolarmente le applicazioni desiderate oppure usare una selezione rapida.

Catalogo iniziale:

- Google Chrome
- Mozilla Firefox
- VLC media player
- WinRAR
- 7-Zip
- Everything
- Adobe Acrobat Reader
- SumatraPDF
- Steam
- Playnite

Selezioni rapide iniziali:

- `PC NUOVO`: Chrome, VLC, WinRAR, Everything, Acrobat Reader;
- `GAMING`: Chrome, VLC, 7-Zip, Steam, Playnite.

Prima dell'installazione viene mostrato l'elenco selezionato e richiesta conferma.

### Implementazione

Il menu interattivo è in `Installa-Software.ps1`.

L'installazione effettiva usa `modules/Software.ps1` e `winget`.

Se un pacchetto risulta già installato, il modulo può verificare la presenza di aggiornamenti tramite winget.

### Preset

`Standard`, `Gaming` e `Business` non richiamano più il modulo Software e non contengono più un elenco di pacchetti da installare.

### Rischio

Basso dal punto di vista del sistema operativo, ma l'installazione di software modifica comunque il PC e può introdurre processi, servizi, task pianificati, associazioni file ed elementi in avvio automatico.

Per questo motivo l'installazione non fa parte della normale ottimizzazione.

### Reversibilità

Il sistema Undo del Toolkit non disinstalla automaticamente i software installati tramite questa funzione.

La rimozione deve essere eseguita tramite Windows, winget o il relativo programma di disinstallazione.

### Test BEFORE/AFTER

Per misurare correttamente un preset:

1. partire da una snapshot/baseline pulita;
2. eseguire solo il preset;
3. riavviare;
4. acquisire l'AFTER;
5. confrontare BEFORE e AFTER;
6. installare eventuali software solo dopo il test del preset.
