# Architecture Patterns: fl_chart Bar Charts Integration

**Domain:** Adding bar chart visualizations to an existing Flutter + Riverpod + Drift hydration tracker
**Researched:** 2026-06-16
**Confidence:** HIGH (all patterns verified against existing codebase and fl_chart Context7 docs)

---

## Executive Summary

The existing architecture already provides both data streams needed for charts. No new Drift queries or DAO methods are required. The monthly bar chart consumes `calendarMonthProvider(year, month)` which already emits `Map<String, int>` of daily totals. The day detail bar chart consumes `waterEntriesForDateProvider(dateKey)` which already emits `List<WaterEntryEntity>` with `loggedAt` timestamps and `amountMl` values. The work is purely additive: a new widget for the monthly chart, a new screen + route for the day detail, and the fl_chart dependency itself.

---

## 1. Data Flow Diagram

```
MONTHLY BAR CHART (embedded in HistoryScreen)
===============================================
Drift (water_entries table)
  |
  v
WaterEntryDao.watchEntriesInRange(startKey, endKey)  [EXISTING]
  |
  v
WaterRepository.watchDailyTotalsInRange(start, end)  [EXISTING]
  |
  v
calendarMonthProvider(year, month)                    [EXISTING - stream_providers.dart]
  |  emits: Stream<Map<String, int>>  {dateKey -> totalMl}
  v
MonthlyBarChart widget                                [NEW - presentation/widgets/]
  |  transforms Map<String,int> -> List<BarChartGroupData>
  v
fl_chart BarChart widget


DAY DETAIL SCREEN (pushed from HistoryScreen)
===============================================
Drift (water_entries table)
  |
  v
WaterEntryDao.watchEntriesForDate(dateKey)            [EXISTING]
  |
  v
WaterRepository.watchEntriesForDate(dateKey)          [EXISTING]
  |
  v
waterEntriesForDateProvider(dateKey)                   [EXISTING - stream_providers.dart]
  |  emits: Stream<List<WaterEntryEntity>>
  v
DayDetailScreen (new ConsumerWidget)                  [NEW - presentation/screens/]
  |  transforms List<WaterEntryEntity> -> List<BarChartGroupData>
  v
fl_chart BarChart widget
```

---

## 2. Component Boundaries

| Component | Responsibility | Status | Communicates With |
|-----------|---------------|--------|-------------------|
| `WaterEntryDao` | Raw Drift queries against water_entries table | EXISTS -- no changes | AppDatabase |
| `WaterRepository` | Domain mapping (WaterEntry -> WaterEntryEntity), grouping | EXISTS -- no changes | WaterEntryDao |
| `calendarMonthProvider` | Reactive stream of `Map<String, int>` daily totals for a (year, month) | EXISTS -- no changes | WaterRepository |
| `waterEntriesForDateProvider` | Reactive stream of `List<WaterEntryEntity>` for a dateKey | EXISTS -- no changes | WaterRepository |
| `effectiveTargetForDateProvider` | Reactive stream of the target ml for a date | EXISTS -- no changes | TargetHistoryDao |
| `allTargetHistoryProvider` | All target history rows for batch target lookup | EXISTS -- no changes | TargetHistoryDao |
| `MonthlyBarChart` | Transforms month totals map into fl_chart BarChartData, renders chart | **NEW widget** | calendarMonthProvider (via parent), allTargetHistoryProvider (via parent) |
| `DayDetailScreen` | Full screen showing entries for one day as a bar chart | **NEW screen** | waterEntriesForDateProvider, effectiveTargetForDateProvider |
| `app_router.dart` | GoRouter configuration | **MODIFIED** -- add /history/day/:dateKey child route | DayDetailScreen |
| `history_screen.dart` | Calendar + streak + day summary | **MODIFIED** -- embed MonthlyBarChart, modify day-tap to navigate | MonthlyBarChart, GoRouter |

---

## 3. Integration Points

### 3.1 Monthly Bar Chart -- Embedded in HistoryScreen

**Data source:** The same `calendarMonthProvider(focused.year, focused.month)` that HistoryScreen already watches. The `monthTotals` variable (line 97-98 of history_screen.dart) is passed directly to the new widget. No new provider needed.

**Target line:** The monthly chart also needs the daily target to draw a goal line (horizontal `ExtraLinesData`). Use the target derived from `allTargetHistoryProvider` (already watched by HistoryScreen as `targetsAsync`) via the existing `_findActiveTarget` helper. Use the effective target for the last day of the displayed month as a single horizontal line value.

**Widget design:**

```dart
// presentation/widgets/monthly_bar_chart.dart
class MonthlyBarChart extends StatelessWidget {
  const MonthlyBarChart({
    super.key,
    required this.year,
    required this.month,
    required this.dailyTotals,     // Map<String, int> from calendarMonthProvider
    required this.dailyTargetMl,   // int - effective target for goal line
    required this.onBarTapped,     // void Function(String dateKey)? - navigate to day detail
  });
}
```

**Why StatelessWidget, not ConsumerWidget:** The parent HistoryScreen already watches the providers and passes data down. This keeps the chart widget pure and testable -- it only transforms data to fl_chart structures. This follows the existing pattern (e.g., `_IntakeBottomSheet` in home_screen.dart receives data via constructor, not via providers).

**fl_chart data transformation (inside build):**

```dart
// For a 28-31 day month: x = day number (1-31), toY = totalMl for that day
// Days with no data -> toY = 0 (absent keys in Map)
final daysInMonth = DateTime(year, month + 1, 0).day;
final barGroups = List.generate(daysInMonth, (i) {
  final day = i + 1;
  final dateKey = _toDateKey(DateTime(year, month, day));
  final total = dailyTotals[dateKey] ?? 0;
  return BarChartGroupData(
    x: day,
    barRods: [
      BarChartRodData(
        toY: total.toDouble(),
        color: total >= dailyTargetMl ? goalMetColor : primaryColor,
        width: barWidth,  // calculated from LayoutBuilder constraints
        borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
      ),
    ],
  );
});
```

**Goal line via ExtraLinesData:**

```dart
extraLinesData: ExtraLinesData(
  horizontalLines: [
    HorizontalLine(
      y: dailyTargetMl.toDouble(),
      color: colorScheme.outline.withValues(alpha: 0.5),
      strokeWidth: 1,
      dashArray: [8, 4],
      label: HorizontalLineLabel(
        show: true,
        labelResolver: (_) => '${dailyTargetMl} ml',
      ),
    ),
  ],
),
```

**Bar width calculation -- use LayoutBuilder:**

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final chartWidth = constraints.maxWidth - 48; // padding + axis label space
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final barWidth = (chartWidth / daysInMonth) * 0.6; // 60% bar, 40% gap
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceEvenly,
          // ...
        ),
        duration: Duration(milliseconds: 250),
      ),
    );
  },
)
```

**Placement in HistoryScreen:** Insert between the TableCalendar widget and the existing DaySummaryArea (AnimatedSwitcher at line 256). The monthly chart sits inside the existing `SingleChildScrollView`, so it scrolls naturally with the rest of the content.

### 3.2 Day Detail Screen -- Pushed from History

**Data source:** `waterEntriesForDateProvider(dateKey)` -- already exists in stream_providers.dart. Each `WaterEntryEntity` has `loggedAt` (DateTime with hour/minute) and `amountMl`.

**fl_chart data transformation:**

```dart
// x = entry index (0-based), toY = amountMl
// Using entry index is simpler than hour-based positioning and avoids
// overlapping bars when multiple entries share the same hour.
final barGroups = entries.asMap().entries.map((e) {
  final entry = e.value;
  return BarChartGroupData(
    x: e.key,
    barRods: [
      BarChartRodData(
        toY: entry.amountMl.toDouble(),
        width: barWidth,
        color: colorScheme.primary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
    ],
  );
}).toList();
```

**Bottom axis labels:** Format `loggedAt` as HH:mm using `getTitlesWidget` callback:

```dart
bottomTitles: AxisTitles(
  sideTitles: SideTitles(
    showTitles: true,
    reservedSize: 30,
    getTitlesWidget: (value, meta) {
      final index = value.toInt();
      if (index < 0 || index >= entries.length) return const SizedBox();
      final entry = entries[index];
      final time = '${entry.loggedAt.hour.toString().padLeft(2, '0')}:'
                    '${entry.loggedAt.minute.toString().padLeft(2, '0')}';
      return SideTitleWidget(
        meta: meta,
        child: Text(time, style: TextStyle(fontSize: 10)),
      );
    },
  ),
),
```

**Screen structure:**

```dart
// presentation/screens/day_detail_screen.dart
class DayDetailScreen extends ConsumerWidget {
  const DayDetailScreen({super.key, required this.dateKey});
  final String dateKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(waterEntriesForDateProvider(dateKey));
    final targetAsync = ref.watch(effectiveTargetForDateProvider(dateKey));

    return Scaffold(
      appBar: AppBar(
        title: Text(_formatDateTitle(context, dateKey)),
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(context.l10n.errorLoadingData)),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(child: Text(context.l10n.noEntriesForDay));
          }
          final targetMl = targetAsync.value ?? 2000;
          final totalMl = entries.fold(0, (sum, e) => sum + e.amountMl);
          return _buildContent(context, entries, totalMl, targetMl);
        },
      ),
    );
  }
}
```

**Why ConsumerWidget (not ConsumerStatefulWidget):** The screen has no local mutable state. It receives `dateKey` via constructor (from GoRouter path parameter), watches providers, and renders. The existing `HomeScreen` is `ConsumerStatefulWidget` because it manages lifecycle listeners and SnackBar state. `DayDetailScreen` has neither concern.

### 3.3 GoRouter -- Day Detail Route

**Current route structure (history branch, app_router.dart lines 85-95):**

```dart
StatefulShellBranch(
  routes: [
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
  ],
),
```

**Modified route structure:**

```dart
StatefulShellBranch(
  routes: [
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
      routes: [
        GoRoute(
          path: 'day/:dateKey',
          builder: (context, state) {
            final dateKey = state.pathParameters['dateKey']!;
            return DayDetailScreen(dateKey: dateKey);
          },
        ),
      ],
    ),
  ],
),
```

**Full URL path:** `/history/day/2026-06-16`

**Navigation from HistoryScreen:**

```dart
// On calendar day tap or monthly chart bar tap:
context.go('/history/day/$dateKey');
```

**Why child route under `/history` (not top-level):** A child route under `/history` means the day detail screen renders inside the history branch's navigator. GoRouter's `StatefulShellRoute.indexedStack` preserves the HistoryScreen state underneath, so pressing back returns to the calendar with the same focused month. If the bottom NavigationBar should be hidden on day detail, use `parentNavigatorKey` on the child route to push on the root navigator instead -- but for a utility app, keeping the nav bar visible is standard UX.

**Why path parameter over `extra`:** The `dateKey` is a simple YYYY-MM-DD string that is URL-safe and supports deep linking. Using `state.extra` would break deep links and lose state on browser back button if the app ever targets web.

### 3.4 HistoryScreen Modifications

**Current day tap behavior (lines 168-177):** `onDaySelected` sets `_selectedDay` local state and shows a `_buildDaySummary` card below the calendar.

**New day tap behavior -- two options:**

**Option A -- Replace day summary with navigation (recommended):**
Remove `_selectedDay` state and `_buildDaySummary`. Tap a calendar day to push the day detail screen. The monthly bar chart provides the at-a-glance view that `_buildDaySummary` used to provide.

```dart
onDaySelected: (selectedDay, focusedDay) {
  if (selectedDay.isAfter(DateTime.now())) return;
  final dateKey = _toDateKey(selectedDay);
  context.go('/history/day/$dateKey');
  ref.read(focusedMonthProvider.notifier).set(focusedDay);
},
```

This simplifies HistoryScreen by removing: `_selectedDay` field, `setState` call, `_buildDaySummary` method, and the `AnimatedSwitcher` wrapper. HistoryScreen becomes a pure `ConsumerWidget` (no longer needs `ConsumerStatefulWidget`).

**Option B -- Keep day summary, add detail navigation:**
Keep current behavior but add a "View details" chevron or button in the day summary card that navigates to `DayDetailScreen`. More taps but preserves existing UX.

**Recommendation:** Option A. The monthly bar chart replaces the inline day summary. A single tap for full details is more efficient and less cluttered.

---

## 4. New Files to Create

| File | Type | Purpose |
|------|------|---------|
| `lib/presentation/widgets/monthly_bar_chart.dart` | Widget | Renders fl_chart BarChart from month totals map |
| `lib/presentation/screens/day_detail_screen.dart` | Screen | Full-screen day detail with entry-level bar chart |

## 5. Existing Files to Modify

| File | Change | Scope |
|------|--------|-------|
| `pubspec.yaml` | Add `fl_chart: ^1.2.0` dependency | 1 line |
| `lib/core/router/app_router.dart` | Add `/history/day/:dateKey` child route + import DayDetailScreen | ~10 lines |
| `lib/presentation/screens/history_screen.dart` | Import + embed `MonthlyBarChart`; modify `onDaySelected` to navigate; optionally remove `_selectedDay` state | ~20 lines changed |
| ARB files (4) | Add l10n keys for day detail screen title + empty state | ~4-6 keys per file |

## 6. Files NOT Modified

| File | Why Not |
|------|---------|
| `lib/data/database/daos/water_entry_dao.dart` | Existing `watchEntriesForDate` and `watchEntriesInRange` already provide all needed data |
| `lib/data/repositories/water_repository.dart` | Existing `watchDailyTotalsInRange` and `watchEntriesForDate` already provide all needed data |
| `lib/core/providers/stream_providers.dart` | `calendarMonthProvider` and `waterEntriesForDateProvider` already exist with exactly the right signatures |
| `lib/core/providers/repository_providers.dart` | No new repositories needed |
| `lib/core/providers/database_provider.dart` | No database changes needed |
| `lib/data/database/app_database.dart` | No schema changes, no new tables, no migration needed |

---

## 7. Patterns to Follow

### Pattern 1: Data Transformation at Widget Level

**What:** Transform `Map<String, int>` / `List<WaterEntryEntity>` into `List<BarChartGroupData>` inside the widget's `build` method (or a helper method on the widget).

**Why:** This follows the existing pattern where HistoryScreen transforms `monthTotals` into calendar builder decoration inline. The Drift layer provides domain data; the presentation layer handles chart-library-specific mapping. No intermediate "chart data" provider is needed.

**When:** Always. Do not create a provider that returns `BarChartData` -- that couples the provider layer to fl_chart.

### Pattern 2: Family Provider Reuse

**What:** `calendarMonthProvider(year, month)` is already a family provider that caches per (year, month) pair. The monthly bar chart automatically benefits from this -- switching months that were previously viewed hits the Riverpod cache, not Drift.

**Why:** D-07 design decision from the original implementation. No additional caching needed.

**When:** Anytime you need per-month or per-date data. Never create a new provider that duplicates existing family providers.

### Pattern 3: ConsumerWidget for Read-Only Screens

**What:** `DayDetailScreen` should be a `ConsumerWidget` (stateless), not `ConsumerStatefulWidget`. It receives `dateKey` via constructor (from GoRouter path parameter), watches providers, and renders.

**Why:** The screen has no local mutable state. No lifecycle listeners, no TextEditingControllers, no SnackBar management. Existing `HomeScreen` is `ConsumerStatefulWidget` because it manages `AppLifecycleListener` -- `DayDetailScreen` has no such concern.

### Pattern 4: Theme-Aware Chart Colors

**What:** Use `Theme.of(context).colorScheme` for chart colors, not hardcoded values.

**Why:** The app supports Material You dynamic color (THEME-01). Hardcoded chart colors would break theme consistency. Use `colorScheme.primary` for normal bars, green for goal-met bars (matching the calendar cell pattern in HistoryScreen lines 297-308), and `colorScheme.outlineVariant` for grid lines.

```dart
final colorScheme = Theme.of(context).colorScheme;
final goalMetColor = Theme.of(context).brightness == Brightness.dark
    ? Colors.green.shade400
    : Colors.green.shade600;
```

### Pattern 5: fl_chart ExtraLinesData for Goal Line

**What:** Use fl_chart's built-in `ExtraLinesData` with a `HorizontalLine` to show the daily target on the monthly chart. This is a first-class fl_chart feature, verified via Context7 documentation.

**Why:** No custom painting needed. The line updates reactively when the target changes because it is derived from provider data passed to the widget.

### Pattern 6: Implicit Animation via BarChart Duration

**What:** Pass `duration` and `curve` parameters to the `BarChart()` widget for smooth transitions when data changes (e.g., when the focused month changes).

**Why:** fl_chart handles implicit animation internally. No `AnimationController` or `StatefulWidget` lifecycle needed. Verified via Context7: `BarChart(BarChartData(...), duration: Duration(milliseconds: 150), curve: Curves.linear)`.

---

## 8. Anti-Patterns to Avoid

### Anti-Pattern 1: Creating Chart-Specific Providers

**What:** Creating a `monthlyBarChartDataProvider` that returns `BarChartData` or `List<BarChartGroupData>`.

**Why bad:** Couples the provider layer to the fl_chart library. If fl_chart is ever replaced, providers would need to change. Providers should return domain data (`Map<String, int>`, `List<WaterEntryEntity>`), not presentation-library types.

**Instead:** Transform domain data to chart data in the widget build method.

### Anti-Pattern 2: New Drift Queries for Data Already Available

**What:** Adding a `watchDailyTotalsForMonth` method to the DAO when `watchEntriesInRange` + repository grouping already produces the same result via `calendarMonthProvider`.

**Why bad:** Duplicates existing logic, creates a second code path to maintain, and the existing stream already has proven correctness through v1.0-v1.4.

**Instead:** Reuse `calendarMonthProvider` for monthly data and `waterEntriesForDateProvider` for single-day data.

### Anti-Pattern 3: Using `context.push` with `extra` for Day Detail

**What:** Passing the entire `List<WaterEntryEntity>` as `state.extra` to avoid re-fetching on the detail screen.

**Why bad:** Breaks deep linking. The data is stale on arrival (not reactive). If the user adds a water entry and then returns to the detail screen, the chart would show outdated data.

**Instead:** Pass `dateKey` as a path parameter. Let `DayDetailScreen` watch `waterEntriesForDateProvider(dateKey)` reactively.

### Anti-Pattern 4: StatefulWidget for Chart Widgets

**What:** Making `MonthlyBarChart` a `StatefulWidget` to manage animation state.

**Why bad:** fl_chart handles its own animation internally via the `duration` and `curve` parameters on the `BarChart` widget. Adding StatefulWidget lifecycle on top would conflict or duplicate effort.

**Instead:** Use `StatelessWidget`. Pass `duration: Duration(milliseconds: 250)` to `BarChart()`.

### Anti-Pattern 5: Top-Level Route for Day Detail

**What:** Adding `/day-detail` as a top-level route outside the `StatefulShellRoute`.

**Why bad:** Top-level routes render outside the shell -- no bottom NavigationBar visible. The user loses navigation context. Also, pressing system back would go to the shell root instead of back to the history tab.

**Instead:** Nest as child route under `/history` within the `StatefulShellBranch`.

---

## 9. Build Order (Dependency-Aware)

The build order respects component dependencies -- each step can be built and verified independently.

### Phase 1: Foundation

1. **Add fl_chart dependency** to pubspec.yaml (`fl_chart: ^1.2.0`)
   - Run `flutter pub get` to verify resolution.
   - No other code depends on this step; it just needs to resolve.

### Phase 2: Monthly Bar Chart Widget + Integration

2. **Create `MonthlyBarChart` widget** (`lib/presentation/widgets/monthly_bar_chart.dart`)
   - Pure StatelessWidget that takes `Map<String, int>`, targetMl, year, month, and optional `onBarTapped` callback.
   - Can be unit tested in isolation with mock data.
   - Depends on: fl_chart (Phase 1)

3. **Embed `MonthlyBarChart` in HistoryScreen**
   - Insert below TableCalendar in the `SingleChildScrollView` Column.
   - Pass existing `monthTotals` and target data (already available as local variables).
   - Depends on: MonthlyBarChart widget (step 2)

### Phase 3: Day Detail Screen + Navigation

4. **Create `DayDetailScreen`** (`lib/presentation/screens/day_detail_screen.dart`)
   - ConsumerWidget with `dateKey` constructor parameter.
   - Watches `waterEntriesForDateProvider(dateKey)` and `effectiveTargetForDateProvider(dateKey)`.
   - Depends on: fl_chart (Phase 1), existing providers (no changes needed)

5. **Add GoRouter child route** (`/history/day/:dateKey` under the history branch)
   - Modify `app_router.dart` to add the child route.
   - Import `DayDetailScreen`.
   - Depends on: DayDetailScreen (step 4)

6. **Wire navigation from HistoryScreen**
   - Modify `onDaySelected` to call `context.go('/history/day/$dateKey')`.
   - Optionally wire `onBarTapped` callback from MonthlyBarChart to navigate.
   - Remove `_selectedDay` state and `_buildDaySummary` if adopting Option A.
   - Depends on: GoRouter route (step 5), MonthlyBarChart callback (step 3)

### Phase 4: Localization and Polish

7. **Add l10n strings** for day detail screen
   - App bar title (formatted date), empty state text, chart axis labels if needed.
   - Update all 4 ARB files (en, it, fr, es).
   - Depends on: DayDetailScreen UI being finalized (step 4)

---

## 10. Target Line Strategy

When the user has changed their target mid-month (via TARGET-01/02/03/04), the "goal line" is ambiguous:

**Option A -- Most recent effective target (recommended):** Draw one horizontal line at the target effective on the last day of the displayed month. Simple, visually clear, correct for the current period.

**Option B -- Per-day target segments:** Draw multiple horizontal line segments, one per target-history entry effective date range. Visually complex, harder to implement with fl_chart's `HorizontalLine` API which is designed for full-width lines.

**Recommendation:** Option A. A single goal line is standard in hydration apps. The per-day color-coding of bars (green vs primary) already communicates whether each individual day met its effective target using the existing `_findActiveTarget` pattern from HistoryScreen.

---

## 11. Day Detail X-Axis Strategy

**Approach A -- Entry index (recommended):** `x = 0, 1, 2, ...` with bottom titles showing `HH:mm` from `loggedAt`. Simple, no overlapping bars, works correctly when multiple entries share the same minute.

**Approach B -- Minute-of-day based:** `x = loggedAt.hour * 60 + loggedAt.minute`. More temporally accurate but bars overlap when entries are close together, and large gaps between entries create uneven visual spacing.

**Recommendation:** Approach A. The goal is to show "what did I drink today and when" -- entry index with time labels achieves this cleanly. The chronological order is preserved because `watchEntriesForDate` orders by `loggedAt ASC` (water_entry_dao.dart line 22).

---

## 12. Scalability Considerations

| Concern | Current Scale | At Scale | Risk |
|---------|--------------|----------|------|
| Data volume per month | 0-150 entries (5/day * 31 days) | No issue -- SQLite handles trivially | NONE |
| Monthly chart bars | 28-31 bars | fl_chart handles 100+ without jank | NONE |
| Day detail chart bars | Typically 5-15 per day | Even 50 renders fine | NONE |
| Riverpod cache | One stream per visited month | Memory bounded by months viewed in session; autoDispose cleans up | NONE |
| Bar width at 31 days | ~6-8px per bar on phone screen | Tight but readable; use LayoutBuilder | LOW -- test on small screens |

---

## Sources

- fl_chart BarChart API (Context7, /imanneo/fl_chart) -- BarChartData, BarChartGroupData, BarChartRodData, BarTouchData, ExtraLinesData properties confirmed (HIGH confidence)
- GoRouter StatefulShellRoute child routes (Context7, /websites/pub_dev_packages_go_router) -- nested route pattern confirmed (HIGH confidence)
- Existing codebase files read directly: water_entry_dao.dart, stream_providers.dart, water_repository.dart, history_screen.dart, app_router.dart, home_screen.dart, database_provider.dart, app_database.dart, water_entry_entity.dart, water_entries_table.dart, repository_providers.dart, target_history_dao.dart (HIGH confidence)
