# Gaming

Documentazione di `modules/Gaming.ps1`.

## Regola di sicurezza dei preset

Gaming e un'estensione del profilo Standard, non un profilo aggressivo indipendente. Le modifiche specifiche Gaming devono essere registrate dal sistema Backup/Undo prima della scrittura. Il Toolkit non deve forzare valori Gaming opposti quando si passa a Standard o Business: l'uscita da Gaming dovra ripristinare lo stato precedente registrato dal Toolkit, evitando di sovrascrivere una preferenza che esisteva gia sul PC cliente.

Fino al completamento del gestore automatico delle transizioni, il passaggio Gaming -> Standard/Business non va considerato ancora certificato.

## GAMING-001 — Game Mode

**Che cos'è:** Game Mode è la modalità di Windows dedicata alla gestione dei carichi di gioco.

**Cosa fa il Toolkit:** abilita Game Mode e ne consente l'attivazione automatica quando previsto dal preset Gaming.

**Perché:** utilizza il meccanismo previsto da Windows invece di applicare tweak aggressivi a scheduler, timer, priorità CPU o servizi.

**Cosa non fa:** non garantisce più FPS e non modifica overclock, core parking, HPET o priorità permanenti dei processi.

**Rischio:** basso.

**Dettaglio tecnico:** valori `AutoGameModeEnabled=1` e `AllowAutoGameMode=1` sotto `HKCU\Software\Microsoft\GameBar`.

**Undo:** le scritture passano da `Set-TDTRegistryDword`, quindi il valore/esistenza precedente viene registrato nella sessione Undo prima della modifica.

## GAMING-002 — Game DVR

**Che cos'è:** Game DVR fa parte delle funzioni Windows per cattura/registrazione dell'attività di gioco.

**Cosa fa il Toolkit:** disabilita Game DVR quando previsto dal preset Gaming.

**Perché:** evita la funzione di registrazione/cattura quando non desiderata, senza intervenire su componenti strutturali di Windows.

**Cosa non fa:** non disabilita la GPU, Game Mode o i driver grafici.

**Prestazioni:** l'effetto dipende dall'uso effettivo delle funzioni di cattura; non viene promesso un aumento generalizzato degli FPS.

**Rischio:** basso per chi non utilizza Game DVR; la relativa funzione di cattura non sarà disponibile finché la modifica rimane applicata.

**Dettaglio tecnico:** `HKCU\System\GameConfigStore`, `GameDVR_Enabled=0`.

**Undo:** anche questa scrittura passa dal backup centralizzato e puo essere riportata al valore/esistenza precedente tramite la sessione Undo.
