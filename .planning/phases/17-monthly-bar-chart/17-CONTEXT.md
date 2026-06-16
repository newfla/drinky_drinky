# Phase 17: Monthly Bar Chart - Context

**Gathered:** 2026-06-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Aggiungere un grafico a barre mensile (`MonthlyBarChart`) nella `HistoryScreen` esistente, posizionato sotto il calendario e sopra la day summary card. Il chart mostra i ml totali giornalieri per il mese visualizzato, con colori verde/rosso e linea orizzontale per il target.

**In scope:** fl_chart dependency, widget `MonthlyBarChart`, embedding in `HistoryScreen`, empty state, tooltip su barra, sincronizzazione con `focusedMonthProvider`.

**Out of scope:** schermata di dettaglio giornaliero (Phase 18), navigazione da barra a day detail (Phase 18), localizzazione ARB (Phase 18).

</domain>

<decisions>
## Implementation Decisions

### Layout e sizing

- **D-01:** Il chart è contenuto in un `Card` con elevation standard, `margin: EdgeInsets.symmetric(horizontal: 16)`, `padding: EdgeInsets.all(16)` interno — stesso stile di `StreakCard` e `_buildDaySummary`.
- **D-02:** Altezza fissa `SizedBox(height: 180)` intorno al widget `BarChart`.
- **D-03:** Posizione nel Column: dopo `TableCalendar`, prima di `AnimatedSwitcher` (day summary). Ordine: StreakCard → spazio → Calendario → spazio → **Chart mensile** → spazio → Day summary.

### Colori delle barre

- **D-04:** Colori verde/rosso coerenti con il calendario — stessa logica di `_findActiveTarget()` e `_buildDayCell()`:
  - `total >= dailyTarget && dailyTarget > 0` → verde (`Colors.green.shade400` dark / `Colors.green.shade600` light)
  - `total > 0 && total < dailyTarget` → rosso (`Colors.red.shade400` dark / `Colors.red.shade600` light)
  - `total == 0` (nessuna entry) → `toY: 0`, nessuna barra visibile.
- **D-05:** Giorni futuri (dopo `DateTime.now()`) → nessuna barra (esclusi dalla lista di `BarChartGroupData`).

### Linea target

- **D-06:** Linea orizzontale dashed (`ExtraLinesData → HorizontalLine`) con il target dell'**ultimo giorno del mese visualizzato** — calcolato con `_findActiveTarget(targets, endDateKey)` dove `endDateKey` è l'ultimo giorno del mese. Una sola linea per semplicità.

### Claude's Discretion

- Spessore e dash pattern della linea target (es. `dashArray: [8, 4]`) — a discrezione del planner.
- Label asse X (es. mostrarli ogni 5 giorni o ai giorni 1/5/10/15/20/25/ultimo) — a discrezione, purché non si sovrappongano.
- Label asse Y con `reservedSize: 40` (valore a 4 cifre non clippa) — obbligatorio per correttezza.
- `ValueKey('$year-$month')` sul `BarChart` per prevenire artefatti di animazione al cambio mese — obbligatorio (pitfall noto).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope
- `.planning/ROADMAP.md` §Phase 17 — goal e success criteria
- `.planning/REQUIREMENTS.md` §CHART-01…CHART-06 — requisiti coperti da questa fase

### Data providers (già esistenti, zero modifiche)
- `lib/core/providers/stream_providers.dart` — `calendarMonth(year, month)`, `waterEntriesForDateProvider`, `focusedMonthProvider`, `allTargetHistoryProvider`

### Schermata da modificare
- `lib/presentation/screens/history_screen.dart` — file principale. Contiene `_findActiveTarget()`, `_buildDayCell()`, layout del Column scrollabile, `AnimatedSwitcher` day summary.

### fl_chart pitfalls (research)
- `.planning/research/PITFALLS.md` — pitfalls critici: maxY esplicito, ValueKey per mese, no showingTooltipIndicators, altezza bounded, reservedSize asse Y.
- `.planning/research/STACK.md` — API fl_chart: BarChart, BarChartData, BarChartGroupData, BarChartRodData, ExtraLinesData.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `_findActiveTarget(targets, dateKey)` in `history_screen.dart` — calcola il target per una data. Riutilizzare per determinare il colore di ogni barra E per la linea orizzontale (passando l'ultimo giorno del mese).
- `_buildDayCell()` color logic — riferimento per i valori colore verde/rosso con dark mode support.
- `calendarMonthProvider(year, month)` — già watchato in `HistoryScreen`, ritorna `Map<String, int>` (dateKey → ml). Passare direttamente al widget `MonthlyBarChart`.
- `allTargetHistoryProvider` — già watchato, ritorna `List<TargetHistoryEntry>`. Passare al widget per calcolo target.
- `focusedMonthProvider` — già watchato. Il mese è `focused.year / focused.month`.

### Established Patterns
- Widget chart come `StatelessWidget` (non ConsumerWidget) — riceve dati via costruttore da `HistoryScreen` che è già Consumer. Pattern: tutto il watching rimane in `HistoryScreen`, il widget chart è puro.
- Card con `margin: EdgeInsets.symmetric(horizontal: 16)` e `child: Padding(padding: EdgeInsets.all(16), ...)` — pattern esistente per StreakCard.
- Dark mode via `Theme.of(context).brightness` — pattern già usato in `_buildDayCell()`.

### Integration Points
- **Column in `_HistoryScreenState.build()`** — inserire `MonthlyBarChart` widget tra `TableCalendar` e `AnimatedSwitcher`.
- **`pubspec.yaml`** — aggiungere `fl_chart: ^1.2.0` come prima cosa.
- **`lib/presentation/widgets/`** — creare la directory se non esiste, aggiungere `monthly_bar_chart.dart`.

</code_context>

<specifics>
## Specific Ideas

- "Verde/rosso come il calendario" — coerenza visiva esplicita richiesta dall'utente.
- Card con elevation, non inline — stesso linguaggio visivo del resto della schermata.
- 180px di altezza — abbastanza per leggere 31 barre su schermi 360dp+.
- Nessuna barra fantasma per giorni vuoti — altezza zero, spazio vuoto.
- Target line = ultimo giorno del mese, non target di oggi.

</specifics>

<deferred>
## Deferred Ideas

Nessuna idea fuori scope emersa durante la discussione — la conversazione è rimasta nell'ambito della Phase 17.

</deferred>

---

*Phase: 17-Monthly Bar Chart*
*Context gathered: 2026-06-16*
