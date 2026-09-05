# Explorer

Documentazione delle modifiche applicate da `modules/Explorer.ps1`.

## EXPLORER-001 — Mostra estensioni file

**Che cos'è:** Windows può nascondere le estensioni dei tipi di file conosciuti.

**Cosa fa il Toolkit:** rende visibili estensioni come `.exe`, `.pdf`, `.jpg` e `.docx`.

**Perché:** rende immediatamente riconoscibile il tipo reale di file ed è utile anche nell'assistenza tecnica e nell'individuazione di nomi ingannevoli.

**Cosa non fa:** non modifica i file e non migliora le prestazioni.

**Rischio:** basso.

**Ripristino:** sì, tramite il backup delle modifiche al registro gestite dal Toolkit.

**Dettaglio tecnico:** `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced`, `HideFileExt=0`.

## EXPLORER-002 — Apri Esplora file su Questo PC

**Che cos'è:** Windows 11 può aprire Esplora file sulla Home, che mostra elementi recenti e posizioni suggerite.

**Cosa fa il Toolkit:** imposta `Questo PC` come pagina iniziale di Esplora file.

**Perché:** consente di raggiungere subito unità e cartelle principali, particolarmente utile durante assistenza e preparazione dei PC.

**Cosa non fa:** non elimina Home, file recenti o cartelle dell'utente.

**Prestazioni:** nessun beneficio significativo; è una scelta di usabilità.

**Rischio:** basso.

**Dettaglio tecnico:** `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced`, `LaunchTo=1`.

## EXPLORER-003 — Mostra file nascosti

**Che cos'è:** Windows nasconde normalmente file e cartelle marcati come nascosti.

**Cosa fa il Toolkit:** abilita la loro visualizzazione quando previsto dal preset.

**Perché:** può essere utile per diagnosi e assistenza tecnica.

**Cosa non fa:** non rende automaticamente visibili tutti i file protetti di sistema.

**Prestazioni:** nessun beneficio.

**Rischio:** basso; l'utente vede più elementi normalmente nascosti.

**Dettaglio tecnico:** `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced`, `Hidden=1`.

## EXPLORER-004 — Icone desktop in base all'edizione

**Che cos'è:** Windows 11 lascia normalmente nascosta una parte delle icone di sistema del desktop.

**Cosa fa il Toolkit:** quando `DesktopIconsByEdition=true`, rende disponibili le icone di sistema utili senza creare collegamenti `.lnk` artificiali.

Su edizioni Home/Consumer mostra:

- Questo PC;
- File utente;
- Cestino.

Su edizioni Pro/Business (Professional, Workstation, Enterprise, Education e derivate) aggiunge anche:

- Rete;
- Pannello di controllo.

**Perché:** su un PC tecnico o professionale Rete e Pannello di controllo sono scorciatoie utili; su un PC Home manteniamo il desktop più semplice.

**Cosa non fa:** non rimuove icone già presenti e non cancella collegamenti dell'utente.

**Prestazioni:** nessun beneficio; è una scelta di usabilità.

**Rischio:** basso.

**Ripristino:** sì, i valori Registry vengono salvati nella sessione Undo.

**Dettaglio tecnico:** usa `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel` e `ClassicStartMenu`, impostando a `0` i CLSID delle icone da mostrare. L'edizione viene rilevata tramite `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\EditionID`.

**Nota:** la comparsa visiva può richiedere un refresh del desktop, disconnessione o riavvio di Explorer/Windows.
