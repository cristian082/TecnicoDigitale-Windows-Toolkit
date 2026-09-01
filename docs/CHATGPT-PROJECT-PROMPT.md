# Prompt di continuità progetto – TecnicoDigitale Windows Toolkit

Copia e incolla questo prompt in una nuova chat ChatGPT per riprendere il lavoro sul progetto senza dover ricostruire tutto il contesto.

---

Sto sviluppando con te il repository GitHub:

`cristian082/TecnicoDigitale-Windows-Toolkit`

Il progetto si chiama **TecnicoDigitale Windows Toolkit** ed è un toolkit PowerShell modulare per preparare, ottimizzare e standardizzare PC Windows 11 in modo conservativo, ripetibile, documentato e adatto in futuro anche all'uso sui PC dei clienti.

## Obiettivo del progetto

Voglio un'alternativa personale e più prudente a toolkit/debloater generici come WinUtil/CTT. Il toolkit deve fare solo modifiche comprensibili, reversibili quando possibile e facilmente verificabili. Non deve applicare tweak aggressivi o “magici”.

Il toolkit deve:

- creare SEMPRE un punto di ripristino prima di qualunque modifica;
- interrompere l'esecuzione se il punto di ripristino non viene creato;
- usare preset configurabili;
- produrre log completi;
- supportare `-WhatIf`;
- essere idempotente: rilanciare lo stesso preset non deve creare problemi;
- applicare correttamente le impostazioni sia all'utente corrente sia agli altri utenti quando previsto;
- installare software tramite winget in modo robusto;
- avere in futuro un vero sistema di backup/Undo delle modifiche;
- essere testato prima in macchina virtuale e solo dopo su PC reali.

## Filosofia di sicurezza

NON disabilitare o alterare in modo aggressivo:

- Microsoft Defender;
- Windows Firewall;
- UAC;
- Windows Update;
- pagefile;
- mitigazioni di sicurezza;
- scheduler;
- HPET/timer;
- stack TCP/IP;
- servizi critici di Windows;
- componenti necessari al servicing di Windows.

Niente registry cleaner, optimizer generici, script di “gaming latency” non documentati o rimozione indiscriminata di Appx/componenti Windows.

## Struttura attuale del repository

```text
LICENSE
README.md
Setup.ps1
docs/
modules/
presets/
```

Moduli principali:

```text
modules/Common.ps1
modules/Restore.ps1
modules/Privacy.ps1
modules/Explorer.ps1
modules/Start-Taskbar.ps1
modules/Debloat.ps1
modules/Gaming.ps1
modules/Software.ps1
```

Preset:

```text
presets/Standard.json
presets/Gaming.json
presets/Business.json
```

`Setup.ps1` carica il preset JSON, avvia il logging e richiama i moduli in ordine circa:

`Common → Restore → Privacy → Explorer → Start-Taskbar → Debloat → Gaming → Software`

## Stato importante del modulo Restore

In origine `Checkpoint-Computer` non creava un nuovo punto se ne esisteva uno nelle precedenti 24 ore.

Questo è stato corretto: il modulo deve forzare temporaneamente la possibilità di creare un nuovo restore point, creare `TecnicoDigitale Windows Toolkit`, poi ripristinare il precedente valore del Registro relativo alla frequenza.

Requisito tassativo: **ogni esecuzione reale deve avere il proprio punto di ripristino**. Se la creazione fallisce, il toolkit non deve continuare.

Un test reale ha già mostrato correttamente:

```text
[Restore] Punto di ripristino creato.
```

## Gestione delle impostazioni per utente

Il primo approccio provava a caricare direttamente `NTUSER.DAT` degli altri profili sotto `HKEY_USERS` e a scrivere le chiavi. Windows ha restituito più volte `UnauthorizedAccessException`, in particolare su:

```text
Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDa
```

Anche la scrittura diretta su:

```text
HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDa
```

è risultata non autorizzata sulla macchina reale testata.

Quindi NON dobbiamo insistere nel forzare `TaskbarDa`.

Per nascondere/disabilitare Widgets è stato deciso di usare invece il criterio macchina:

```text
HKLM\SOFTWARE\Policies\Microsoft\Dsh
AllowNewsAndInterests = 0
```

La strategia generale per impostazioni per utente deve essere affidabile e non basata su modifiche brutali degli hive offline. È stata introdotta/valutata una strategia con applicazione immediata all'utente corrente e Active Setup per gli altri utenti/al primo accesso. Prima di modificarla ulteriormente, leggi SEMPRE i file correnti della repo perché il codice può essere già cambiato.

## Privacy / Explorer / Start-Taskbar

Le modifiche devono restare conservative.

Esempi previsti:

- disattivare suggerimenti/promozioni Windows;
- disattivare Advertising ID se previsto dal preset;
- mostrare estensioni file;
- aprire Esplora file su “Questo PC”;
- mostrare file nascosti solo se esplicitamente richiesto dal preset;
- nascondere Widgets con policy affidabile;
- eventualmente allineare Start a sinistra;
- disattivare Search Highlights.

Non presumere che una specifica chiave Registry funzioni su tutte le build: verificare sempre compatibilità Windows 11 24H2/25H2 e preferire policy/documentazione Microsoft quando disponibili.

## Debloat

Il debloat deve essere selettivo, mai indiscriminato.

Il preset Standard ha previsto la rimozione di app tipo:

```text
Microsoft.BingNews
Microsoft.BingWeather
Microsoft.GetHelp
Microsoft.Getstarted
Microsoft.MicrosoftSolitaireCollection
Microsoft.WindowsFeedbackHub
Microsoft.ZuneMusic
Microsoft.ZuneVideo
```

Il preset Gaming non deve rimuovere Solitaire se la configurazione corrente lo prevede.

Mai fare blanket removal di tutti gli Appx.

## Gaming

Il modulo Gaming deve limitarsi a modifiche ragionevoli e documentabili, per esempio Game Mode e, se previsto, Game DVR.

NON introdurre tweak HPET, timer, scheduler, TCP, core parking o simili senza una motivazione tecnica estremamente solida e verificabile.

## Software / winget

Preset Standard previsto con programmi come:

```text
RARLab.WinRAR
VideoLAN.VLC
Google.Chrome
voidtools.Everything
Adobe.Acrobat.Reader.64-bit
```

Preset Gaming anche con Steam e Playnite.

Durante un test reale:

- WinRAR era già installato e winget restituiva un codice non-zero perché non esisteva un aggiornamento;
- VLC installato correttamente;
- Chrome ha dato `Installer hash does not match`;
- Everything installato correttamente;
- Adobe Reader installato correttamente.

Il modulo Software è stato migliorato per distinguere meglio “già installato/già aggiornato” dai veri errori e per poter aggiornare le sorgenti/riprovare quando opportuno.

Prima di cambiare codice leggi il file live `modules/Software.ps1` dalla repo.

## Preset

Esistono almeno:

- `Standard`: configurazione generale conservativa;
- `Gaming`: stessa base prudente + impostazioni gaming ragionevoli + software gaming;
- `Business`: configurazione più orientata al lavoro.

I preset devono restare JSON facili da leggere e modificare.

## README

Il README è già stato riscritto per spiegare non solo cosa il toolkit NON fa, ma soprattutto:

- cosa fa;
- perché conviene usarlo;
- i moduli;
- i preset;
- il logging;
- `-WhatIf`;
- winget;
- filosofia di sicurezza;
- struttura del progetto.

Mantenerlo aggiornato quando cambia il comportamento reale.

## Cose ancora da sviluppare / verificare

Priorità attuali:

1. Testare tutto in una **VM Windows 11**, non più sul PC reale usato finora come banco prova.
2. Usare **VirtualBox** come laboratorio iniziale.
3. Preparare un `autounattend.xml` per installare Windows 11 in modo ripetibile e pulito.
4. L'unattended deve occuparsi solo dell'installazione/OOBE e NON delle ottimizzazioni, altrimenti non sapremmo distinguere cosa modifica Windows e cosa modifica il toolkit.
5. Creare una cartella di laboratorio tipo:

```text
test-lab/
├── autounattend.xml
├── README.md
└── Test-Toolkit.ps1
```

6. Creare snapshot VirtualBox, ad esempio:

```text
00-CLEAN
01-UPDATES
02-STANDARD
```

7. Costruire `Test-Toolkit.ps1` che verifichi automaticamente che il toolkit abbia fatto davvero ciò che promette, ad esempio:

- restore point presente;
- chiavi Registry attese;
- software installati;
- Appx previsti rimossi;
- Defender attivo;
- Firewall attivo;
- Windows Update non disabilitato;
- servizi critici non alterati;
- preset eseguito due volte senza errori;
- comportamento con secondo utente e utente nuovo.

L'obiettivo è arrivare a risultati tipo “25/25 test superati”, non solo “lo script non ha mostrato errori”.

8. Implementare un vero sistema Undo/backup:

- salvare valori Registry precedenti in JSON prima delle modifiche;
- distinguere valore inesistente da valore presente;
- ripristinare o eliminare correttamente i valori durante Undo;
- documentare separatamente cosa è reversibile per Appx/software.

9. Aggiungere `.gitignore` almeno per `logs/` ed eventualmente `backups/`.
10. Verificare sintassi PowerShell e possibilmente aggiungere PSScriptAnalyzer/CI GitHub Actions.
11. Controllare idempotenza di ogni modulo.
12. Verificare accuratamente i package ID winget.
13. Aggiornare `docs/Changes.md` se non riflette più la reale gestione dello scope utente/macchina.
14. Gestire bene transcript/log anche in caso di errore o esecuzione non amministrativa.

## Metodo di lavoro che voglio da te

Quando riprendiamo il progetto:

- usa direttamente il repository GitHub come fonte di verità;
- prima di modificare un file, leggine la versione corrente dalla repo;
- non basarti solo su questo prompt se il codice live è diverso;
- proponi modifiche conservative;
- quando trovi un errore, individua la causa e correggi il progetto, non limitarti a nasconderlo;
- mantieni log comprensibili;
- evita modifiche irreversibili;
- documenta le decisioni importanti;
- se una modifica Registry è fragile o non documentata, preferisci una policy Windows ufficiale quando disponibile;
- considera il toolkit **ancora in sviluppo e non pronto per essere eseguito alla cieca sui PC dei clienti** fino a quando i test in VM non saranno solidi.

## Nota di perimetro

Questo prompt riguarda **esclusivamente TecnicoDigitale Windows Toolkit**.

NON riguarda rEFInd, dual boot, Batocera, configurazioni EFI, hardware del PC, Home Assistant o altri progetti.

Quando ricevi questo prompt in una nuova chat, inizia leggendo lo stato attuale del repository `cristian082/TecnicoDigitale-Windows-Toolkit`, poi dimmi brevemente dove siamo arrivati e riprendiamo dal laboratorio VirtualBox + `autounattend.xml` + test automatici.

---
