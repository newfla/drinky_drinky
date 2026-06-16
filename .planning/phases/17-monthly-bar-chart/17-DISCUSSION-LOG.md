# Phase 17: Monthly Bar Chart - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-16
**Phase:** 17-Monthly Bar Chart
**Areas discussed:** Layout e sizing, Colori delle barre, Linea target a metà mese

---

## Layout e sizing

**Q1: Wrapper visivo**

| Option | Description | Selected |
|--------|-------------|----------|
| Card con elevation | Stesso stile StreakCard/DaySummaryCard — margin 16px, padding 16px | ✓ |
| Inline senza card | Direttamente nel Column, più minimale | |
| Card full-width | Nessun margin orizzontale, look bold | |

**User's choice:** Card con elevation (Recommended)
**Notes:** Coerenza con il resto della schermata.

**Q2: Altezza**

| Option | Description | Selected |
|--------|-------------|----------|
| 180px fissi | Abbastanza per 31 barre su schermi 360dp+ | ✓ |
| 220px fissi | Più alto, barre più visibili, occupa più spazio | |

**User's choice:** 180px fissi

**Q3: Posizione nel layout**

| Option | Description | Selected |
|--------|-------------|----------|
| Dopo calendario, prima day summary | StreakCard → Calendario → Chart → Day summary | ✓ |
| Prima del calendario | Chart → Calendario → Day summary | |

**User's choice:** Dopo il calendario, prima della day summary card (Recommended)

---

## Colori delle barre

**Q1: Logica colori**

| Option | Description | Selected |
|--------|-------------|----------|
| Verde/rosso come il calendario | Stessa logica _findActiveTarget() e _buildDayCell() | ✓ |
| Colore primario unico | Tutte le barre nel colore primario del tema | |
| Gradiente per percentuale | Scala da rosso a verde in base alla % del target | |

**User's choice:** Verde/rosso come il calendario (Recommended)
**Notes:** Coerenza visiva esplicita — il calendario e il chart usano lo stesso linguaggio colore.

**Q2: Giorni a zero**

| Option | Description | Selected |
|--------|-------------|----------|
| Nessuna barra (altezza zero) | Spazio vuoto — semplice | ✓ |
| Barra fantasma grigia 2-3px | Segnala che il giorno esiste ma senza dati | |

**User's choice:** Nessuna barra (altezza zero)

---

## Linea target a metà mese

**Q1: Quale target come linea orizzontale**

| Option | Description | Selected |
|--------|-------------|----------|
| Target dell'ultimo giorno del mese | Usa _findActiveTarget() con endDateKey del mese | ✓ |
| Nessuna linea se target cambiato | Nasconde la linea in caso di variazione | |
| Target di oggi sempre | Target attuale indipendentemente dal mese | |

**User's choice:** Target dell'ultimo giorno del mese (Recommended)
**Notes:** Approccio conservativo e semplice — una sola linea, la logica _findActiveTarget() già esiste.

---

## Claude's Discretion

- Spessore e dash pattern della linea target (es. `dashArray: [8, 4]`)
- Intervallo label asse X (ogni 5 giorni, o giorni 1/5/10/15/20/25/ultimo)
- `reservedSize: 40` su asse Y (obbligatorio per valori a 4 cifre — non discrezionale ma non discusso esplicitamente)
- `ValueKey('$year-$month')` sul BarChart (obbligatorio per prevenire artefatti — non discrezionale)

## Deferred Ideas

Nessuna idea fuori scope emersa durante la discussione.
