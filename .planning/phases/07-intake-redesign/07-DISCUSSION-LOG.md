# Phase 7: Intake Redesign - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-08
**Phase:** 7-Intake Redesign
**Areas discussed:** Chiusura del sheet, 4° preset nel DB, Comportamento undo dal sheet

---

## Chiusura del Sheet

| Option | Description | Selected |
|--------|-------------|----------|
| Sheet si chiude subito (preset) | L'azione è completata, l'utente torna alla home. Pattern standard per azioni one-shot. | ✓ |
| Sheet rimane aperto (preset) | L'utente può aggiungere più drink consecutivi senza riaprire il sheet. | |

| Option | Description | Selected |
|--------|-------------|----------|
| Sheet si chiude subito (custom) | Coerente con il comportamento dei preset. Azione completata = sheet chiuso. | ✓ |
| Campo si svuota, sheet resta aperto | Permette di aggiungere valori custom multipli di fila. | |

**User's choice:** Sheet si chiude subito in entrambi i casi (preset e custom ml)
**Notes:** Comportamento one-shot coerente tra le due modalità di aggiunta.

---

## 4° Preset nel DB

| Option | Description | Selected |
|--------|-------------|----------|
| UI-only: mostra solo i primi 3 | Il seed resta a 4, ma sheet e impostazioni prendono solo sortOrder 0-1-2. Nessuna migrazione DB. | |
| Nuovo seed a 3 + migrazione DB | Migrazione Drift che elimina il preset sortOrder=3. Chi ha già l'app perde il 4° preset. | |
| Nuovo seed a 3, nessuna migrazione | Nuovi utenti partono con 3 preset. Chi ha già l'app mantiene 4 nel DB ma ne vede solo 3. | ✓ |

| Option | Description | Selected |
|--------|-------------|----------|
| 150 / 250 / 500 ml | Copre bicchiere piccolo, bicchiere standard, bottiglietta. | ✓ |
| Mantieni 200 / 300 / 400 ml | Progressione lineare uniforme, simile a v1.0. | |
| Tu decidi | Lascio i valori a Claude | |

**User's choice:** Nuovo seed a 3 senza migrazione; valori 150/250/500 ml
**Notes:** Comportamento ibrido accettato — utenti esistenti con 4 preset nel DB ne vedono solo 3 nell'UI (take(3) al layer presentazione).

---

## Comportamento Undo dal Sheet

| Option | Description | Selected |
|--------|-------------|----------|
| Sheet chiude prima, poi SnackBar | Navigator.pop() prima di showSnackBar(). L'utente vede la home aggiornata e lo SnackBar in basso. | ✓ |
| Simultaneo | Sheet e SnackBar compaiono insieme. Tecnicamente più complesso, visivamente strano su iOS. | |

| Option | Description | Selected |
|--------|-------------|----------|
| Sì, identico | Stesso formato '+X ml added', stesso tasto Undo, stesso comportamento persist: false. | ✓ |
| Modifica il testo | Cambia il messaggio per il contesto del sheet | |

**User's choice:** Sequenziale (sheet chiude prima); SnackBar identico al formato v1.0
**Notes:** Coerenza con l'esperienza attuale; nessuna variazione nel testo o nel comportamento undo.

---

## Claude's Discretion

- Esatta implementazione widget del sheet (`showModalBottomSheet` con drag handle standard)
- Se estrarre il contenuto sheet in `_IntakeBottomSheet` widget separato o costruire inline
- Strategia di disposal del `TextEditingController` per l'input custom
- Range validazione custom ml (1–9999): disable del bottone se vuoto/zero

## Deferred Ideas

None.
