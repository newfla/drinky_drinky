# Phase 9: Data Foundation & Bug Fixes - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-10
**Phase:** 09-data-foundation-bug-fixes
**Areas discussed:** Bug disposition, target_history seed, Scope del DAO in Phase 9

---

## Bug Disposition (BUG-01, BUG-03)

**Pre-discussion finding:** Codebase scout revealed both bugs are already fixed:
- BUG-01: `water_entry_dao.dart:35–44` already filters by `dateKey` before deleting
- BUG-03: `water_repository.dart:34–47` already has regex + DateTime.tryParse + round-trip validation

| Option | Description | Selected |
|--------|-------------|----------|
| Aggiungi test di conferma | Scrivi unit test che verificano il comportamento cross-day di deleteLastEntry e la validazione semantica di dateKey | ✓ |
| Marca come già completati | Aggiorna roadmap con nota 'già presente nel codice, verificato a mano'. Nessun test. | |

**User's choice:** Aggiungi test di conferma

---

| Option | Description | Selected |
|--------|-------------|----------|
| test/ esistente con in-memory Drift | Aggiungere test al progetto esistente — coerente con i 11 test già presenti | ✓ |
| File di test dedicato per validazione | Crea test/validation_test.dart separato | |

**User's choice:** test/ esistente con in-memory Drift

---

## target_history Seed

| Option | Description | Selected |
|--------|-------------|----------|
| 2000 ml hardcoded | Coerente con default UserSettings.dailyTargetMl (Constant(2000)). Seed semplice. | ✓ |
| Letto da UserSettings dopo insert | Dipendenza asincrona in onCreate — rischio race condition | |

**User's choice:** 2000 ml hardcoded

---

| Option | Description | Selected |
|--------|-------------|----------|
| '2000-01-01' sentinella | Data passato remoto: qualsiasi query trova sempre una riga | |
| Data del primo avvio (DateTime.now()) | Data reale di installazione | ✓ |

**User's choice:** Data del primo avvio
**Notes:** Logica corretta — fresh install non ha entry precedenti, quindi nessuna query storica andrà "prima" del seed.

---

## Scope del DAO in Phase 9

| Option | Description | Selected |
|--------|-------------|----------|
| Table + DAO completo | TargetHistoryDao con metodi read e write. Phase 10 chiama direttamente. | ✓ |
| Solo table + DAO minimale | Solo definizione tabella e query read. Write aggiunto in Phase 10. | |

**User's choice:** Table + DAO completo

---

| Option | Description | Selected |
|--------|-------------|----------|
| Phase 10 | updateTargetWithHistory() appartiene a Phase 10 con la logica 'oggi/domani' | ✓ |
| Phase 9 | Anticipa il metodo repository in Phase 9 come stub | |

**User's choice:** Phase 10

---

## Claude's Discretion

- Nessuna area delegata a Claude — tutte le decisioni chiave prese dall'utente.

## Deferred Ideas

- `updateTargetWithHistory()` repository method → Phase 10
- Provider wiring ed UI integration → Phase 10/11
