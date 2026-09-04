# Documentazione TecnicoDigitale Windows Toolkit

Questa cartella spiega **cosa fa ogni singola funzione del Toolkit**, perché esiste e quali effetti può avere su Windows.

## Regola del progetto

Una modifica non deve entrare nel Toolkit se non sappiamo:

1. che cosa modifica;
2. a cosa serve la funzione originale di Windows;
3. perché conviene modificarla;
4. quali effetti collaterali può avere;
5. come ripristinare lo stato precedente;
6. su quali versioni di Windows è stata verificata.

Il Toolkit privilegia modifiche conservative e comprensibili. Un servizio o un componente fermo non viene considerato automaticamente inutile: se Windows lo gestisce già on-demand, normalmente viene lasciato così.

## Documenti

- [Explorer](Explorer.md) — Esplora file e visualizzazione dei file.
- [Privacy](Privacy.md) — suggerimenti, contenuti promozionali e ID pubblicitario.
- [Start e Taskbar](Start-Taskbar.md) — Widget, ricerca e barra delle applicazioni.
- [Gaming](Gaming.md) — Game Mode e Game DVR.
- [Services](Services.md) — metodologia di studio e classificazione dei servizi Windows.

La documentazione verrà estesa insieme ai moduli: ogni nuova modifica deve essere accompagnata dalla relativa spiegazione.