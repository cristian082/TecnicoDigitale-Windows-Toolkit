# Gaming

Documentazione di `modules/Gaming.ps1`.

## GAMING-001 — Game Mode

**Che cos'è:** Game Mode è la modalità di Windows dedicata alla gestione dei carichi di gioco.

**Cosa fa il Toolkit:** abilita Game Mode e ne consente l'attivazione automatica quando previsto dal preset Gaming.

**Perché:** utilizza il meccanismo previsto da Windows invece di applicare tweak aggressivi a scheduler, timer, priorità CPU o servizi.

**Cosa non fa:** non garantisce più FPS e non modifica overclock, core parking, HPET o priorità permanenti dei processi.

**Rischio:** basso.

**Dettaglio tecnico:** valori `AutoGameModeEnabled=1` e `AllowAutoGameMode=1` sotto `HKCU\Software\Microsoft\GameBar`.

**Nota Undo:** il modulo Gaming attuale scrive direttamente nel registro. Prima di considerare il ripristino completo, queste scritture dovranno essere integrate nel sistema di backup centralizzato del Toolkit.

## GAMING-002 — Game DVR

**Che cos'è:** Game DVR fa parte delle funzioni Windows per cattura/registrazione dell'attività di gioco.

**Cosa fa il Toolkit:** disabilita Game DVR quando previsto dal preset Gaming.

**Perché:** evita la funzione di registrazione/cattura quando non desiderata, senza intervenire su componenti strutturali di Windows.

**Cosa non fa:** non disabilita la GPU, Game Mode o i driver grafici.

**Prestazioni:** l'effetto dipende dall'uso effettivo delle funzioni di cattura; non viene promesso un aumento generalizzato degli FPS.

**Rischio:** basso per chi non utilizza Game DVR; la relativa funzione di cattura non sarà disponibile finché la modifica rimane applicata.

**Dettaglio tecnico:** `HKCU\System\GameConfigStore`, `GameDVR_Enabled=0`.

**Nota Undo:** come sopra, questa scrittura deve ancora essere collegata al backup centralizzato.