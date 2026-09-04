# Privacy e contenuti suggeriti

Documentazione di `modules/Privacy.ps1`.

Il modulo è volutamente conservativo: non disabilita Defender, Windows Update, servizi fondamentali o l'intera infrastruttura di diagnostica di Windows.

## PRIVACY-001 — Suggerimenti e contenuti promozionali Windows

**Che cos'è:** Windows utilizza `ContentDeliveryManager` per diverse esperienze suggerite e contenuti proposti nell'interfaccia.

**Cosa fa il Toolkit:** disattiva le categorie attualmente configurate nel modulo (`SystemPaneSuggestionsEnabled` e i valori `SubscribedContent` selezionati).

**Perché:** riduce suggerimenti e contenuti promozionali non necessari mantenendo intatti i componenti fondamentali del sistema.

**Cosa non fa:** non disabilita Windows Update, Microsoft Store, Defender o Windows Search e non pretende di eliminare tutta la telemetria di Windows.

**Prestazioni:** il beneficio prestazionale atteso è trascurabile; lo scopo principale è rendere l'esperienza più pulita.

**Rischio:** basso.

**Ripristino:** sì per i valori registrati dal sistema di backup del Toolkit.

**Dettaglio tecnico:** valori DWORD impostati a `0` sotto `HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager`.

## PRIVACY-002 — ID pubblicitario

**Che cos'è:** Windows può mettere a disposizione delle app un identificatore pubblicitario per personalizzare alcune esperienze pubblicitarie.

**Cosa fa il Toolkit:** disabilita l'ID pubblicitario quando l'opzione è prevista dal preset.

**Perché:** limita la personalizzazione pubblicitaria basata su questo identificatore.

**Cosa non fa:** non blocca Internet, cookie, pubblicità nei browser o tutti i meccanismi di telemetria.

**Prestazioni:** nessun beneficio significativo.

**Rischio:** basso; alcune app possono offrire contenuti pubblicitari meno personalizzati.

**Dettaglio tecnico:** `HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo`, `Enabled=0`.