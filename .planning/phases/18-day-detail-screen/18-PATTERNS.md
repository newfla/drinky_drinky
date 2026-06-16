# Phase 18: Day Detail Screen - Pattern Map

**Mapped:** 2026-06-16
**Files analyzed:** 4 new/modified files
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/presentation/screens/day_detail_screen.dart` | screen/widget | streaming (watch provider) | `lib/presentation/screens/history_screen.dart` | exact |
| `lib/core/router/app_router.dart` | config/router | request-response | self (existing GoRoute pattern at lines 42-55) | exact |
| `lib/presentation/screens/history_screen.dart` | screen/widget | streaming | self (modify existing file) | exact |
| `lib/l10n/app_en.arb` + `app_it/fr/es.arb` | l10n | — | self (existing ARB entries) | exact |

---

## Pattern Assignments

### `lib/presentation/screens/day_detail_screen.dart` (new screen, streaming)

**Analog:** `lib/presentation/screens/history_screen.dart`

**Imports pattern** (lines 1-9 of history_screen.dart):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/stream_providers.dart';
import '../../domain/entities/target_history_entry.dart';
import '../../l10n/l10n_extensions.dart';
import '../widgets/monthly_bar_chart.dart';
```
For DayDetailScreen, replace `monthly_bar_chart.dart` with `fl_chart/fl_chart.dart` (for inline BarChart) and keep `stream_providers.dart`.

**Widget declaration pattern** (history_screen.dart lines 34-39):
```dart
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}
```
DayDetailScreen receives `dateKey` as a constructor parameter — use `ConsumerWidget` (stateless is sufficient: no local mutable state needed):
```dart
class DayDetailScreen extends ConsumerWidget {
  const DayDetailScreen({super.key, required this.dateKey});
  final String dateKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) { ... }
}
```

**Provider watch pattern — streaming with AsyncValue.when** (history_screen.dart lines 47-60):
```dart
final earliestAsync = ref.watch(earliestDateKeyProvider);
return Scaffold(
  appBar: AppBar(title: Text(context.l10n.historyTitle)),
  body: earliestAsync.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (e, _) => Center(child: Text(context.l10n.errorLoadingData)),
    data: (value) { ... },
  ),
);
```
DayDetailScreen will watch two providers:
```dart
final entriesAsync = ref.watch(waterEntriesForDateProvider(dateKey));
final targetsAsync = ref.watch(allTargetHistoryProvider);
```
Chain `.when()` — outer on `entriesAsync`, inner on `targetsAsync` (same nesting pattern as history_screen lines 90-96).

**`_toDateKey` helper — duplicate locally** (history_screen.dart lines 13-15, monthly_bar_chart.dart lines 12-14):
```dart
String _toDateKey(DateTime d) {
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
```
Per Phase 17 strategy: duplicate in the new file rather than extracting to a shared utility.

**`_findActiveTarget` helper — duplicate locally** (history_screen.dart lines 22-32):
```dart
int _findActiveTarget(List<TargetHistoryEntry> targets, String dateKey) {
  int result = 2000;
  for (final t in targets) {
    if (t.effectiveDate.compareTo(dateKey) <= 0) {
      result = t.targetMl;
    } else {
      break;
    }
  }
  return result;
}
```

**AppBar title with locale-formatted date** (history_screen.dart `_buildDaySummary` lines 362-366):
```dart
final locale = Localizations.localeOf(context).toString();
final dateLabel = DateFormat.yMMMMd(locale).format(day);
```
Parse `dateKey` → `DateTime.parse(dateKey)` then format with `DateFormat.yMMMMd(locale)`.

**Card with margin + padding — shared layout pattern** (history_screen.dart lines 374-385, monthly_bar_chart.dart lines 151-155):
```dart
Card(
  margin: const EdgeInsets.symmetric(horizontal: 16),
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: ...,
  ),
)
```

**fl_chart BarChart core pattern** (monthly_bar_chart.dart lines 156-277 — full SizedBox+BarChart block):
```dart
SizedBox(
  height: 180, // increase to 220+ if HH:mm labels need vertical space
  child: BarChart(
    key: ValueKey('day-$dateKey'), // MANDATORY — prevents render artefacts (WR-01)
    BarChartData(
      alignment: BarChartAlignment.spaceEvenly,
      maxY: maxY,          // MANDATORY explicit value (WR-02, Pitfall 1)
      minY: 0,
      barGroups: barGroups,
      barTouchData: BarTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) { ... },
        ),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            getTitlesWidget: (value, meta) { ... },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) { ... },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: const FlGridData(drawVerticalLine: false, drawHorizontalLine: true),
      borderData: FlBorderData(show: false),
    ),
  ),
)
```
For daily chart: x-axis = minutes-since-midnight (or grouped by HH:mm string label), y-axis = ml. Bar color = `Theme.of(context).colorScheme.primary` (not green/red — D-06, CONTEXT decisions). Grouped bars for same-minute entries use `BarChartGroupData` with multiple `barRods`.

**BarChartGroupData with multiple barRods — same-minute grouping** (monthly_bar_chart.dart lines 130-145 for single-rod reference):
```dart
BarChartGroupData(
  x: xValue,   // minutes-since-midnight (0..1439) for daily chart
  barRods: [
    BarChartRodData(
      toY: entry.ml.toDouble(),
      width: 10,
      color: colorScheme.primary,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
    ),
    // additional rods for same-minute entries
  ],
)
```

**Dark mode color** (monthly_bar_chart.dart lines 95-100, history_screen.dart lines 106-108):
```dart
final brightness = Theme.of(context).brightness;
// For daily bars: use primary color (theme-aware, no conditional needed)
final barColor = Theme.of(context).colorScheme.primary;
```

**Empty state pattern** (monthly_bar_chart.dart lines 67-82):
```dart
if (entries.isEmpty) {
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          context.l10n.dayDetailNoEntries, // new L10N key
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    ),
  );
}
```

**maxY computation — mandatory explicit ceiling** (monthly_bar_chart.dart lines 147-149):
```dart
final computedMax = actualMaxValue * 1.1;
final maxY = max(computedMax, 100.0);
```
For daily chart: no target line needed (D-09 says no horizontal line for daily additions). maxY = `max(actualMaxMl * 1.1, 100.0)`.

---

### `lib/core/router/app_router.dart` (modify — add top-level route)

**Analog:** self, existing `/calculator` and `/permission` routes (lines 42-55)

**Top-level GoRoute pattern** (app_router.dart lines 42-55):
```dart
// /calculator is a TOP-LEVEL route so it renders without the bottom NavigationBar.
GoRoute(
  path: '/calculator',
  builder: (context, state) => HydrationCalculatorScreen(
    isOnboarding: state.extra as bool? ?? true,
  ),
),
```

**New route to add** — insert after `/calculator` route, before `StatefulShellRoute.indexedStack` (after line 55, before line 57):
```dart
// /day/:dateKey is a TOP-LEVEL route (outside StatefulShellRoute) so it
// renders without the bottom NavigationBar.
GoRoute(
  path: '/day/:dateKey',
  builder: (context, state) => DayDetailScreen(
    dateKey: state.pathParameters['dateKey']!,
  ),
),
```

**Redirect guard exemption** — add to the guard block at lines 27-28:
```dart
if (state.matchedLocation.startsWith('/day/')) return null;
```

**Import to add at top of app_router.dart:**
```dart
import '../../presentation/screens/day_detail_screen.dart';
```

---

### `lib/presentation/screens/history_screen.dart` (modify — replace tap logic, remove dead code)

**Analog:** self

**onDaySelected — replace setState with context.push** (history_screen.dart lines 169-177):

Current code to replace:
```dart
onDaySelected: (selectedDay, focusedDay) {
  if (selectedDay.isAfter(DateTime.now())) return;
  setState(() {
    _selectedDay = selectedDay;
  });
  ref.read(focusedMonthProvider.notifier).set(focusedDay);
},
```

New pattern (D-01, D-05):
```dart
onDaySelected: (selectedDay, focusedDay) {
  if (selectedDay.isAfter(DateTime.now())) return;
  // Update focused month regardless (Pitfall 4: year/month only).
  ref.read(focusedMonthProvider.notifier).set(focusedDay);
  // Navigate only for days with data (D-02).
  final dateKey = _toDateKey(selectedDay);
  if (monthTotals[dateKey] != null && monthTotals[dateKey]! > 0) {
    context.push('/day/$dateKey');
  }
},
```
`context.push` requires `go_router` import — already present in history_screen.dart via GoRouter (confirm: not currently imported; add `import 'package:go_router/go_router.dart';`).

**Dead code to remove:**
- Field `DateTime? _selectedDay;` (line 43)
- `selectedDayPredicate: (day) => isSameDay(_selectedDay, day),` (line 168)
- Entire `AnimatedSwitcher` block (lines 268-279) and the `SizedBox(height: 16)` immediately before it (line 265)
- Entire `_buildDaySummary()` method (lines 356-385)
- The class becomes a `ConsumerStatelessWidget` IF `_selectedDay` is the only state. But `_selectedDay` is the only `setState` usage → confirm no other local state before promoting to stateless. If other state exists, keep `ConsumerStatefulWidget` and simply delete the field.

**`selectedDayPredicate` to remove** — after removing `_selectedDay`, also remove the `selectedDayPredicate` line from `TableCalendar` (line 168):
```dart
selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
// DELETE this line
```

---

### `lib/l10n/app_en.arb` + `app_it.arb` + `app_fr.arb` + `app_es.arb` (modify — add CHART-11 strings)

**Analog:** existing ARB entries — `daySummaryWithEntries`, `daySummaryNoEntries` (app_en.arb lines 243-266)

**ARB entry pattern with placeholders** (app_en.arb lines 243-256):
```json
"daySummaryWithEntries": "{date} -- {total} of {target} ml",
"@daySummaryWithEntries": {
  "description": "Day summary text shown below the calendar when a day with entries is tapped on the History screen",
  "placeholders": {
    "date": { "type": "String" },
    "total": { "type": "num" },
    "target": { "type": "num" }
  }
},
```

**New keys to add in app_en.arb** (after last entry, before closing `}`):
```json
"dayDetailTitle": "{date}",
"@dayDetailTitle": {
  "description": "AppBar title on the Day Detail screen — locale-formatted date (e.g. June 16, 2026)",
  "placeholders": {
    "date": { "type": "String" }
  }
},

"dayDetailTotal": "{total} ml / {target} ml target",
"@dayDetailTotal": {
  "description": "Total ml line shown above the bar chart in the Day Detail screen",
  "placeholders": {
    "total": { "type": "num" },
    "target": { "type": "num" }
  }
},

"dayDetailNoEntries": "No entries for this day",
"@dayDetailNoEntries": {
  "description": "Empty state text on the Day Detail screen when no water was logged for the selected date"
},

"dayDetailChartTitleTime": "Time",
"@dayDetailChartTitleTime": {
  "description": "X-axis label describing the time axis on the daily bar chart in the Day Detail screen"
}
```

**app_it.arb translations** (pattern from app_it.arb — no `@` metadata blocks, just key-value pairs):
```json
"dayDetailTitle": "{date}",
"dayDetailTotal": "{total} ml / {target} ml obiettivo",
"dayDetailNoEntries": "Nessun dato per questo giorno",
"dayDetailChartTitleTime": "Ora"
```

**app_fr.arb translations:**
```json
"dayDetailTitle": "{date}",
"dayDetailTotal": "{total} ml / {target} ml objectif",
"dayDetailNoEntries": "Aucune entrée pour ce jour",
"dayDetailChartTitleTime": "Heure"
```

**app_es.arb translations:**
```json
"dayDetailTitle": "{date}",
"dayDetailTotal": "{total} ml / {target} ml objetivo",
"dayDetailNoEntries": "Sin registros para este día",
"dayDetailChartTitleTime": "Hora"
```

Note: `dayDetailTitle` may be unnecessary as a L10N key if the AppBar title is built directly with `DateFormat.yMMMMd(locale).format(DateTime.parse(dateKey))` — the planner should decide whether to use a key or format inline. The `dayDetailTotal` and `dayDetailNoEntries` keys are required.

---

## Shared Patterns

### go_router navigation: `context.push`
**Source:** `lib/core/router/app_router.dart`, `lib/presentation/screens/hydration_calculator_screen.dart`
**Apply to:** `history_screen.dart` (onDaySelected), `day_detail_screen.dart` (back navigation is handled by AppBar automatically)
```dart
import 'package:go_router/go_router.dart';
// Usage:
context.push('/day/$dateKey');
```

### AsyncValue.when double-nesting for two providers
**Source:** `lib/presentation/screens/history_screen.dart` lines 90-99
**Apply to:** `day_detail_screen.dart`
```dart
return entriesAsync.when(
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (e, _) => Center(child: Text(context.l10n.errorLoadingData)),
  data: (entries) {
    return targetsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(context.l10n.errorLoadingData)),
      data: (targets) { /* build chart */ },
    );
  },
);
```

### Card layout
**Source:** `lib/presentation/screens/history_screen.dart` lines 128-150, `lib/presentation/widgets/monthly_bar_chart.dart` lines 151-155
**Apply to:** `day_detail_screen.dart` (chart card + total text inside same card)
```dart
Card(
  margin: const EdgeInsets.symmetric(horizontal: 16),
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(totalText, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 12),
        SizedBox(height: 220, child: BarChart(...)),
      ],
    ),
  ),
)
```

### ValueKey on BarChart (mandatory)
**Source:** `lib/presentation/widgets/monthly_bar_chart.dart` line 158, Phase 17 REVIEW.md WR-01
**Apply to:** `day_detail_screen.dart`
```dart
BarChart(
  key: ValueKey('day-$dateKey'),
  ...
)
```

---

## No Analog Found

No files in this phase lack a codebase analog. All patterns are fully covered by existing files.

---

## Metadata

**Analog search scope:** `lib/presentation/screens/`, `lib/presentation/widgets/`, `lib/core/router/`, `lib/core/providers/`, `lib/l10n/`
**Files read:** 7 (app_router.dart, history_screen.dart, monthly_bar_chart.dart, app_en.arb, app_it.arb, l10n_extensions.dart, stream_providers.dart)
**Pattern extraction date:** 2026-06-16
