# Registro modifiche

Questo documento descrive cosa modifica il toolkit e con quale ambito.

## Restore
- Abilita Protezione sistema su `C:` quando possibile.
- Crea un punto di ripristino prima delle modifiche.
- Ambito: macchina.

## Privacy
- Disabilita suggerimenti/promozioni di Windows tramite chiavi utente.
- Disabilita l'ID pubblicitario, se richiesto dal preset.
- Ambito: utente corrente.
- Non disabilita telemetria di sistema, Defender, Firewall, UAC o Windows Update.

## Explorer
- Mostra estensioni file.
- Può aprire Esplora file su Questo PC.
- Può mostrare file nascosti.
- Ambito: utente corrente.

## Start e Taskbar
- Può nascondere Widgets.
- Può allineare Start a sinistra.
- Disabilita evidenziazioni dinamiche della ricerca.
- Ambito: utente corrente.

## Debloat
- Rimuove solo i pacchetti Appx esplicitamente elencati nel preset.
- Non rimuove Microsoft Store, Edge, componenti runtime, WebView2 o framework.
- Ambito: utente corrente.

## Gaming
- Può abilitare Game Mode.
- Può disabilitare Game DVR in background.
- Non modifica timer, HPET, scheduler, mitigazioni CPU, rete o servizi di sistema.
- Ambito: utente corrente.

## Software
- Installa software mediante `winget` usando ID espliciti.
- Non usa driver updater di terze parti.
- Ambito: macchina/installer, secondo il pacchetto winget.

## Da non fare
Il progetto evita intenzionalmente tweak che disabilitano o alterano:
- Microsoft Defender
- Windows Firewall
- UAC
- Windows Update
- pagefile
- mitigazioni di sicurezza
- TCP/IP e stack rete
- HPET / timer di sistema
- scheduler CPU
- servizi critici

## Ripristino
Le modifiche per-utente sono reversibili reimpostando le relative chiavi di registro. Il punto di ripristino offre un ulteriore livello di sicurezza per le modifiche di sistema.