# TecnicoDigitale Test Lab - VirtualBox

Questa cartella documenta il laboratorio usato per sviluppare e verificare il TecnicoDigitale Windows Toolkit su una macchina Windows 11 pulita e riproducibile.

## VM di riferimento

Configurazione consigliata iniziale:

- Windows 11 Pro 25H2 x64, italiano
- 2 vCPU
- 6-8 GB RAM
- disco virtuale dinamico da 80 GB
- EFI/UEFI abilitato
- TPM 2.0 se disponibile; per il solo laboratorio e possibile usare il bypass dei requisiti
- nessun software aggiuntivo prima dello snapshot base

Nome VM consigliato:

`TDT-Win11-Pro-25H2`

## Regola fondamentale: installazione offline

La prima installazione deve essere eseguita con la scheda di rete della VM disabilitata.

Motivo: Windows Setup/OOBE puo scaricare aggiornamenti, driver, app e contenuti durante l'installazione. Questo rende la baseline non riproducibile e rende piu difficile capire se un comportamento dipende da Windows originale, da Windows Update o dal Toolkit.

### VirtualBox GUI

Prima di avviare il setup:

1. Spegnere completamente la VM.
2. Aprire `Impostazioni > Rete > Scheda 1`.
3. Togliere la spunta a `Abilita scheda di rete`.
4. Installare Windows fino al desktop senza rete.

### VBoxManage

Per disattivare completamente la NIC:

```cmd
VBoxManage modifyvm "TDT-Win11-Pro-25H2" --nic1 none
```

Per riattivarla successivamente in NAT:

```cmd
VBoxManage modifyvm "TDT-Win11-Pro-25H2" --nic1 nat
```

## Snapshot obbligatori

### 00-WIN11-STOCK-OFFLINE

Crearlo appena raggiunto il desktop per la prima volta, prima di:

- abilitare la rete;
- eseguire Windows Update;
- installare Guest Additions;
- installare software;
- eseguire il Toolkit;
- applicare modifiche manuali.

Questo snapshot rappresenta Windows appena installato.

### 01-WIN11-UPDATED

Dopo lo snapshot `00-WIN11-STOCK-OFFLINE`:

1. riattivare la rete;
2. eseguire Windows Update fino a quando non restano aggiornamenti normali disponibili;
3. riavviare tutte le volte necessarie;
4. installare i driver/Guest Additions necessari al laboratorio;
5. verificare che il sistema sia stabile;
6. creare lo snapshot `01-WIN11-UPDATED`.

Questo e lo snapshot principale da cui eseguire i test normali del Toolkit.

## Sequenza di test consigliata

Per ogni ciclo di sviluppo:

1. ripristinare `01-WIN11-UPDATED`;
2. avviare Windows;
3. copiare/scaricare la versione del Toolkit da testare;
4. eseguire prima `-WhatIf` quando applicabile;
5. eseguire il preset reale;
6. salvare i log;
7. riavviare Windows;
8. verificare le impostazioni applicate;
9. eseguire una seconda volta lo stesso preset per verificare l'idempotenza;
10. ripristinare lo snapshot prima del test successivo.

## Baseline futura

Il laboratorio verra usato anche per il nuovo modulo di Check-up, che dovra essere inizialmente read-only e rilevare almeno:

- edizione/build/attivazione Windows;
- canale licenza Windows: OEM, Retail, Volume MAK/KMS;
- eventuale chiave OEM nel firmware senza mostrare il product key completo;
- Microsoft Office installato, stato di attivazione e canale di licenza;
- CPU e RAM;
- dischi, tipo, spazio libero, TRIM e salute quando disponibile;
- app/programmi in avvio automatico;
- stato Defender, Firewall e UAC;
- eventuale riavvio Windows Update pendente.

Le licenze devono essere classificate in modo prudente come `OK`, `DA VERIFICARE` o `NON ATTIVO`. Una licenza Volume/KMS non va automaticamente definita falsa: puo essere legittima in un'organizzazione autorizzata.

## Cosa NON deve fare la baseline

La VM base non deve usare un autounattend aggressivo che:

- rimuove in massa AppX o Windows capabilities;
- disabilita UAC;
- disabilita SmartScreen;
- disabilita Defender o Firewall;
- disabilita Core Isolation/VBS/HVCI;
- forza modifiche prestazionali;
- rimuove Edge, OneDrive o altri componenti prima dei test;
- applica i tweak che vogliamo misurare tramite il Toolkit.

Se verra aggiunto un `autounattend.xml` al laboratorio, dovra limitarsi all'automazione dell'installazione e dell'OOBE, mantenendo Windows il piu possibile stock.

## Obiettivo

Separare chiaramente tre stati della macchina:

`Windows stock offline` -> `Windows aggiornato` -> `Windows dopo TecnicoDigitale Toolkit`

In questo modo ogni modifica del Toolkit puo essere testata, ripetuta e confrontata senza dubbi sulla baseline.
