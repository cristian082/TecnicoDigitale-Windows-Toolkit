# Start e barra delle applicazioni

Documentazione di `modules/Start-Taskbar.ps1`.

## TASKBAR-001 — Widget lasciati invariati

**Che cos'è:** i Widget di Windows 11 mostrano notizie, meteo e altri contenuti nella relativa esperienza della barra.

**Cosa fa il Toolkit:** non modifica lo stato dei Widget e conserva la preferenza scelta dall'utente nelle Impostazioni di Windows.

**Perché:** nascondere l'icona e soprattutto una preferenza estetica, non una ottimizzazione prestazionale dimostrata. Inoltre il test reale su Windows 11 Pro build `26200.9278` ha verificato che Windows rifiuta la scrittura diretta sia della policy macchina `AllowNewsAndInterests` sia del valore utente `TaskbarDa`, mentre permette il cambio dall'interfaccia ufficiale.

**Cosa non fa:** non forza permessi del Registro, non rimuove Windows Web Experience Pack e non disabilita componenti WebView2.

**Rischio:** nessuno; la configurazione esistente resta invariata.

**Dettaglio tecnico:** nessuna chiave Widget viene scritta. La gestione resta disponibile in `Impostazioni > Personalizzazione > Barra delle applicazioni`.

## TASKBAR-002 — Allinea Start a sinistra

**Che cos'è:** Windows 11 posiziona normalmente Start e le icone principali al centro.

**Cosa fa il Toolkit:** sposta l'allineamento a sinistra quando previsto dal preset.

**Perché:** preferenza di usabilità, utile soprattutto su postazioni Business o per utenti abituati alle versioni precedenti di Windows.

**Prestazioni:** nessun beneficio.

**Rischio:** basso.

**Dettaglio tecnico:** `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced`, `TaskbarAl=0`.

## TASKBAR-003 — Disattiva evidenziazioni dinamiche della ricerca

**Che cos'è:** Windows Search può mostrare contenuti/evidenziazioni dinamiche nell'interfaccia di ricerca.

**Cosa fa il Toolkit:** disabilita questa presentazione quando previsto dal preset.

**Perché:** mantiene l'interfaccia di ricerca più semplice.

**Cosa non fa:** non disabilita Windows Search né l'indicizzazione dei file.

**Prestazioni:** beneficio atteso trascurabile.

**Rischio:** basso.

**Dettaglio tecnico:** `HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings`, `IsDynamicSearchBoxEnabled=0`.

## TASKBAR-004 — Disattiva suggerimenti Web nella ricerca

**Che cos'è:** la casella di ricerca di Windows può integrare suggerimenti provenienti dal Web oltre ai risultati locali.

**Cosa fa il Toolkit:** disabilita i suggerimenti Web tramite policy Explorer.

**Perché:** concentra la ricerca su PC, app, impostazioni e contenuti locali e riduce risultati non richiesti.

**Cosa non fa:** soprattutto, **non disabilita Windows Search e non spegne il servizio di indicizzazione**.

**Prestazioni:** non viene classificato come tweak prestazionale; è principalmente una modifica di comportamento/usabilità.

**Rischio:** basso; vengono meno i suggerimenti Web integrati nella casella di ricerca.

**Dettaglio tecnico:** `HKCU\Software\Policies\Microsoft\Windows\Explorer`, `DisableSearchBoxSuggestions=1`.

## TASKBAR-005 — Abilita “Termina attività” dalla barra

**Che cos'è:** Windows 11 può mostrare un comando `Termina attività` nel menu contestuale delle applicazioni sulla barra.

**Cosa fa il Toolkit:** abilita tale comando.

**Perché:** permette al tecnico o all'utente di terminare rapidamente un'applicazione bloccata senza aprire Gestione attività.

**Cosa non fa:** non termina automaticamente processi e non modifica la priorità delle applicazioni.

**Rischio:** basso, ma usare il comando su un'app con dati non salvati può causarne la perdita.

**Dettaglio tecnico:** `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings`, `TaskbarEndTask=1`.
