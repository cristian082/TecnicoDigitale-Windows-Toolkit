# TecnicoDigitale Windows Toolkit

Toolkit PowerShell conservativo per preparazione, ottimizzazione e manutenzione di PC Windows 11.

## Obiettivi
- modifiche documentate e reversibili quando possibile;
- niente disattivazione di Defender, Firewall, UAC o Windows Update;
- restore point prima delle modifiche;
- logging delle operazioni;
- preset separati per uso Standard, Gaming e Business;
- moduli indipendenti e riutilizzabili.

## Avvio
Aprire PowerShell come amministratore nella cartella del progetto e usare:

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\Setup.ps1 -Preset Standard
```

Preset disponibili: `Standard`, `Gaming`, `Business`.

Per simulare senza applicare modifiche:

```powershell
.\Setup.ps1 -Preset Standard -WhatIf
```

## Sicurezza
Il toolkit evita volutamente tweak aggressivi o difficili da diagnosticare. Non modifica pagefile, mitigazioni di sicurezza, TCP/IP, HPET, scheduler, Windows Update, Defender, Firewall o UAC.

## Struttura
- `Setup.ps1` orchestratore principale
- `modules/` moduli PowerShell
- `presets/` configurazioni JSON
- `docs/Changes.md` registro delle modifiche e ambito

## Licenza
MIT.