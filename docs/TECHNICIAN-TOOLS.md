# Strumenti Tecnico

`Strumenti-Tecnico.ps1` carica gli strumenti operativi e il catalogo offline `Comandi del tecnico`. Obiettivo: assistenza su PC Windows 11 sconosciuti senza dover ricordare o cercare sul Web i comandi ricorrenti.

## Regole di sicurezza
- Nessuno strumento disabilita Defender, Firewall, UAC o Windows Update.
- Nessun mass-disable di servizi.
- Le analisi non rimuovono software, driver o file utente.
- Le azioni operative sensibili richiedono conferma.
- Nessun riavvio automatico.

## Strumenti operativi
TECH-NET-001 — rete: diagnostica, DNS e adattatori.
TECH-WU-001 — Windows Update: stato, ricerca e riparazione cache esplicita.
TECH-REPAIR-001 — DISM/SFC.
TECH-DISK-001 — dischi/SMART/CHKDSK scan.
TECH-PRINT-001 — stampanti/spooler.
TECH-SVC-001 — servizi senza modifiche massive.
TECH-DRV-001 — driver/PnP.
TECH-STARTUP-001 — startup read-only.
TECH-EVENT-001 — errori/critici recenti.
TECH-BITLOCKER-001 — stato BitLocker senza chiavi.
TECH-SPACE-001 — spazio disco/TEMP read-only.
TECH-PROC-001 — triage processi read-only.

## TECH-CMD-001 — Comandi del tecnico / catalogo offline
Build 9 introduce un prontuario interattivo separato dalla logica degli strumenti.

File:
- `data/TechnicianCommands.json`: catalogo dati estendibile.
- `modules/CommandReference.ps1`: UI, ricerca, schede, copia ed esecuzione.

Ogni voce contiene ID stabile, categoria, titolo, comando, quando serve, quando non serve/attenzioni, impatto, necessita amministratore, necessita riavvio e parole chiave.

Funzioni disponibili:
- navigazione per categoria;
- ricerca offline per problema/parole chiave;
- scheda descrittiva prima dell'azione;
- copia negli appunti;
- esecuzione volontaria con conferma;
- blocco dell'esecuzione diretta se il comando contiene segnaposto come `<PID>`.

Categorie iniziali: Windows/riparazione, rete/DNS, stampanti, dischi, driver, utenti, servizi/processi, Windows Update, boot/BCD, SMB/RDP, energia/batteria, app/Winget, BitLocker, log, Firewall e informazioni PC.

Il catalogo iniziale contiene circa 50 comandi realmente utili. Non deve diventare una raccolta indiscriminata: aggiungere solo comandi tecnicamente giustificabili e documentare le avvertenze.

### Sicurezza del prontuario
La presenza di un comando nel catalogo non significa che sia sicuro in qualsiasi contesto. I comandi a impatto MEDIO/ALTO mostrano l'avvertenza prima dell'esecuzione. Le operazioni distruttive o non coerenti con la filosofia del Toolkit non devono essere aggiunte solo per completezza.

## Compatibilita e test
Target: Windows 11, Windows PowerShell 5.1, esecuzione amministrativa. Alcune informazioni dipendono da hardware, driver ed edizione.

Build 9 da testare in VM:
1. apertura `Strumenti-Tecnico.ps1`;
2. voce 13 `Comandi del tecnico`;
3. caricamento JSON e conteggio catalogo;
4. navigazione di almeno tre categorie;
5. ricerca `stampante`, `wifi`, `boot`, `disco`;
6. copia comando;
7. esecuzione di un comando read-only (es. `ipconfig /all`);
8. verifica che `tasklist /fi "PID eq <PID>"` non venga eseguito direttamente;
9. annullamento di un comando MEDIO/ALTO.
