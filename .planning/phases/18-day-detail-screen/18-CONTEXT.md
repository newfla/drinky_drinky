# Phase 18: Day Detail Screen - Context

**Gathered:** 2026-06-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Aggiungere una `DayDetailScreen` raggiungibile dal calendario della HistoryScreen tramite tap su un giorno con dati. La schermata mostra un grafico a barre delle singole aggiunte del giorno (asse x = orario HH:mm, asse y = ml), il totale ml del giorno, e un empty state per giorni senza dati. Tutte le nuove stringhe localizzate nelle 4 lingue (en/it/fr/es).

**In scope:** DayDetailScreen, route top-level in GoRouter (`/day/:dateKey`), navigazione da `onDaySelected` nel calendario, rimozione del `_buildDaySummary()` inline, localizzazione stringhe (CHART-11).

**Out of scope:** navigazione da barre del chart mensile (tooltip rimane l'unico feedback), lista testuale delle aggiunte, editing/eliminazione delle entry dalla schermata di dettaglio.

</domain>

<decisions>
## Implementation Decisions

### Trigger di navigazione

- **D-01:** Tap su un giorno nel calendario con dati → `context.push('/day/$dateKey')`. Rimozione completa di `_selectedDay`, `_buildDaySummary()`, e `AnimatedSwitcher` dalla HistoryScreen — non coesistono con la nuova navigazione.
- **D-02:** Tap su un giorno senza dati → nessuna azione (il comportamento esistente di non selezionare già non fa nulla).
- **D-03:** Tap su una barra del MonthlyBarChart → tooltip solo (nessuna navigazione). Il chart mensile non è un entry point per la DayDetailScreen.

### Route e NavigationBar

- **D-04:** Route top-level fuori da `StatefulShellRoute.indexedStack` — NavigationBar nascosta nella DayDetailScreen. Pattern coerente con `/calculator` e `/permission`.
- **D-05:** Path: `/day/:dateKey` dove `dateKey` è il formato `YYYY-MM-DD`. Passato come path parameter, non via `state.extra`. Esempio: `context.push('/day/2026-06-16')`.

### Layout schermata dettaglio

- **D-06:** AppBar title: data nel formato locale via `DateFormat.yMMMMd(locale)` — es. "16 giugno 2026" in italiano, "June 16, 2026" in inglese. Stesso pattern già usato in `_buildDaySummary()`.
- **D-07:** Asse x del grafico giornaliero: orario `HH:mm` per ogni aggiunta. Se due aggiunte nello stesso minuto, le barre si affiancano (grouped bars tramite `BarChartGroupData` con più `barRods`).
- **D-08:** Totale ml del giorno mostrato come testo sopra il grafico, dentro la stessa Card — es. "1.800 ml / 2.000 ml target". Nessuna Card separata.
- **D-09:** La schermata mostra solo grafico + totale. Nessuna lista testuale delle singole aggiunte.

### Claude's Discretion

- Colore delle barre giornaliere: Claude può usare il colore primario del tema (non verde/rosso — quelle barre non rappresentano giorni completi ma singole aggiunte)
- Altezza del SizedBox del BarChart giornaliero: minimo 180px, Claude può aumentare se le etichette HH:mm lo richiedono
- `ValueKey` sul BarChart giornaliero: obbligatorio per prevenire artefatti (stessa pitfall del chart mensile)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope
- `.planning/ROADMAP.md` §Phase 18 — goal e success criteria
- `.planning/REQUIREMENTS.md` §CHART-07…CHART-11 — requisiti coperti da questa fase

### Router (da modificare)
- `lib/core/router/app_router.dart` — file principale del router. Aggiungere route top-level `/day/:dateKey` fuori da `StatefulShellRoute`. Studiare il pattern di `/calculator` come riferimento.

### Schermata da creare
- `lib/presentation/screens/day_detail_screen.dart` — da creare. ConsumerWidget o ConsumerStatelessWidget.

### Schermata da modificare
- `lib/presentation/screens/history_screen.dart` — rimuovere `_selectedDay`, `_buildDaySummary()`, `AnimatedSwitcher`. Aggiungere navigazione `context.push` in `onDaySelected`.

### Data provider (già esistente, zero modifiche)
- `lib/core/providers/stream_providers.dart` → `waterEntriesForDateProvider(dateKey)` — stream di `List<WaterEntryEntity>` per un giorno. Già watchato nella HistoryScreen per la day summary.

### Widget chart mensile (riferimento pattern)
- `lib/presentation/widgets/monthly_bar_chart.dart` — pattern per fl_chart: `ValueKey`, `maxY` esplicito, `handleBuiltInTouches`, `reservedSize`, colori dark mode.

### L10N (già infrastruttura)
- `lib/l10n/arb/app_en.arb` — ARB sorgente. Aggiungere le nuove chiavi qui, poi aggiornare it/fr/es.
- `lib/l10n/l10n_extensions.dart` — extension per accedere alle stringhe via `context.l10n`.

### fl_chart pitfalls (da Phase 17)
- `.planning/phases/17-monthly-bar-chart/17-REVIEW.md` — WR-01/WR-02 applicabili; pitfalls: maxY esplicito, ValueKey per giorno, no showingTooltipIndicators.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `waterEntriesForDateProvider(dateKey)` in `stream_providers.dart` — stream `List<WaterEntryEntity>` già pronto. Ogni entry ha `ml` e `createdAt` (DateTime). Usare direttamente senza modifiche al DAO.
- `allTargetHistoryProvider` — già disponibile se serve il target per la linea orizzontale opzionale nel grafico giornaliero.
- `_toDateKey(DateTime d)` — helper in history_screen.dart e monthly_bar_chart.dart. Il planner può creare una funzione condivisa o duplicarla nella nuova screen (stessa strategia di Phase 17).
- `DateFormat.yMMMMd(locale)` — già usato in `_buildDaySummary()` per il titolo data.

### Established Patterns
- Route top-level senza NavigationBar: `GoRoute(path: '/calculator', builder: ...)` — fuori da `StatefulShellRoute`, NavigationBar non appare.
- fl_chart `BarChart` con `ValueKey`, `maxY` esplicito, `handleBuiltInTouches: true`: tutto documentato in `monthly_bar_chart.dart`.
- Dark mode via `Theme.of(context).brightness` per colori condizionali.
- Card con `margin: EdgeInsets.symmetric(horizontal: 16)` e `child: Padding(padding: EdgeInsets.all(16), ...)` — pattern consolidato.
- L10N: aggiungere chiavi in `app_en.arb`, poi copiare e tradurre in `app_it.arb`, `app_fr.arb`, `app_es.arb`. Rigenerare con `flutter gen-l10n`.

### Integration Points
- **`app_router.dart`** — aggiungere `GoRoute(path: '/day/:dateKey', ...)` come route top-level (dopo `/permission` e `/calculator`, prima di `StatefulShellRoute`).
- **`history_screen.dart`** `onDaySelected` — sostituire la logica `setState(_selectedDay)` con `context.push('/day/$dateKey')` condizionale (solo se `monthTotals[dateKey] != null && monthTotals[dateKey]! > 0`).
- **`history_screen.dart`** layout Column — rimuovere `AnimatedSwitcher` con `_buildDaySummary` (e il `SizedBox(height: 16)` prima). `_selectedDay` e `_buildDaySummary()` diventano dead code da eliminare.

</code_context>

<specifics>
## Specific Ideas

- Il chart giornaliero usa colore primario del tema per le barre (non verde/rosso) — le barre rappresentano singole aggiunte, non il completamento del target giornaliero.
- La navigazione avviene solo se `monthTotals[dateKey] != null && monthTotals[dateKey]! > 0` — giorni senza dati non triggherano il push.
- Bar chart tap dal MonthlyBarChart: tooltip resta, nessuna navigazione — il MonthlyBarChart non viene modificato.

</specifics>

<deferred>
## Deferred Ideas

- **Navigazione da barre del MonthlyBarChart** — l'utente ha preferito mantenere solo il tooltip. Eventuale navigazione da barra potrebbe essere una feature futura.
- **Lista testuale delle singole aggiunte** nella DayDetailScreen — fuori scope. Solo grafico + totale.
- **Editing / eliminazione entry** dalla DayDetailScreen — fuori scope per v1.

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 18-Day Detail Screen*
*Context gathered: 2026-06-16*
