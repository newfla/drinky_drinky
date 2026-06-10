# Phase 10: Target History Integration - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-10
**Phase:** 10-target-history-integration
**Areas discussed:** Midnight reset (BUG-02), "Oggi/domani" UX (TARGET-02), Streak con target storico (TARGET-04 scope)

---

## Midnight Reset (BUG-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Timer preciso a mezzanotte | Notifier keepAlive calcola secondi fino a mezzanotte, Timer unico per notte | ✓ |
| Polling ogni 60 secondi | Timer.periodic(60s) con controllo cambio data | |
| AppLifecycleState.resumed | Aggiornamento solo quando l'app torna in foreground | |

**User's choice:** Timer preciso a mezzanotte

---

| Option | Description | Selected |
|--------|-------------|----------|
| StateProvider + Notifier con Timer interno | Classe Notifier keepAlive con Timer scheduale a mezzanotte | ✓ |
| AsyncNotifier con Stream | StreamController che emette nuovi dateKey | |
| Tu decidi | Claude sceglie l'implementazione più semplice | |

**User's choice:** StateProvider + Notifier con Timer interno

---

| Option | Description | Selected |
|--------|-------------|----------|
| HomeScreen + streak in HistoryScreen | Solo i consumer della data odierna hanno bisogno del reset | ✓ |
| Tutti gli screen incluso HistoryScreen | Anche le query del calendario passano per todayDateKeyProvider | |
| Tu decidi | Claude determina quali widget hanno bisogno del reset | |

**User's choice:** HomeScreen + streak in HistoryScreen

---

## "Oggi/Domani" UX (TARGET-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Toggle persistente nei Settings | SegmentedButton/Switch salvato in SharedPreferences o Drift | ✓ |
| Dialog per-change al rilascio slider | BottomSheet/Dialog per ogni modifica del target | |
| Sempre da oggi (no scelta) | Non soddisfa TARGET-02 | |

**User's choice:** Toggle persistente nei Settings

---

| Option | Description | Selected |
|--------|-------------|----------|
| SharedPreferences | Chiave 'drinky_applyTargetFromTomorrow' | |
| Nuova colonna in UserSettings (Drift, no migration) | applyFromTomorrow BOOLEAN DEFAULT false — schemaVersion resta 1 | ✓ |
| Tu decidi | Claude sceglie la soluzione più semplice | |

**User's choice:** Colonna Drift su UserSettings senza migration
**Notes:** L'utente ha specificato "senza migration perché non ci sono altre versioni dell'app installate" — coerente con la scelta di Phase 9 di considerare questa la prima vera installazione.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Upsert per data (ultima modifica conta) | insertOrReplace comporta unico record per effectiveDate | ✓ |
| Ogni modifica crea una riga separata | Richiede timestamp sub-day | |
| Tu decidi | Claude gestisce i casi edge | |

**User's choice:** Upsert per data — solo l'ultima modifica conta

---

## Streak con Target Storico (TARGET-04 scope)

| Option | Description | Selected |
|--------|-------------|----------|
| Target storico per giorno | Ogni giorno valutato con il target che era attivo | ✓ |
| Target globale corrente (invariato) | Continua a usare settings.dailyTargetMl per tutti i giorni | |
| Tu decidi | Claude sceglie in base alla coerenza del prodotto | |

**User's choice:** Target storico per giorno

---

| Option | Description | Selected |
|--------|-------------|----------|
| Fetch target_history una volta, applica per range | Singola query watchAll(), scan in-memory per giorno | ✓ |
| effectiveTargetForDateProvider per ogni giorno | N query SQL separate | |
| Tu decidi | Claude sceglie l'approccio più efficiente | |

**User's choice:** Fetch target_history una volta, applica per range

---

## Claude's Discretion

- Naming esatto del provider (`todayDateKeyProvider` come classe Notifier o funzione `@riverpod`)
- Forma di `effectiveTargetForDateProvider` (annotated function vs manual `StreamProvider.family`)
- Posizionamento del toggle "Applica da" nel layout di SettingsScreen
- Strategia di re-schedule Timer se l'orologio del device cambia

## Deferred Ideas

- `updateTargetWithHistory()` chiamato dal button "Usa come target" del calcolatore → Phase 11
- Provider wiring per la schermata calcolatore → Phase 11
- UI polish per il toggle "Applica da" → future
- Calendar heat-map / color intensity → future milestone
