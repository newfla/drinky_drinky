# Phase 4: Calendar & Streaks - Research

**Researched:** 2026-06-05
**Domain:** Flutter UI (table_calendar), Riverpod state management, Drift stream aggregation
**Confidence:** HIGH

## Summary

Phase 4 replaces the `HistoryScreen` stub with a fully functional monthly calendar (table_calendar 3.2.0) showing green/red day decorations based on goal attainment, plus a streak counter card above the calendar. The data layer adds one new DAO method (`getEarliestDateKey`), one new repository method (`watchDailyTotalsInRange`), and three new Riverpod providers (`calendarMonthProvider`, `streakProvider`, `focusedMonthProvider`).

The implementation is well-constrained: table_calendar 3.2.0 is the only new dependency (already in CLAUDE.md recommended stack), all visual decisions are locked in UI-SPEC, and data decisions are locked in CONTEXT.md. The existing `watchEntriesInRange` DAO method provides the reactive stream foundation -- the new repository method merely transforms it (group by dateKey, sum amountMl). The CalendarBuilders API provides `defaultBuilder` and `todayBuilder` hooks for custom day cell decoration.

**Primary recommendation:** Implement as a single plan with three vertical slices: (1) data layer additions (DAO + repository), (2) providers (calendar month family + streak + focused month), (3) UI (HistoryScreen with StreakCard + TableCalendar + day summary).

<user_constraints>

## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** `WaterRepository.watchDailyTotalsInRange(startDateKey, endDateKey)` returns `Stream<Map<String, int>>` using existing `watchEntriesInRange` DAO method, grouping by dateKey and summing amountMl. Days with zero entries absent from map.
- **D-02:** Single method for both calendar and streak -- caller decides range width.
- **D-03:** Calendar queries one month at a time. Family provider passes (firstDayOfMonth, lastDayOfMonth).
- **D-04:** Streak uses broad range `watchDailyTotalsInRange(veryEarlyDate, yesterday)`. Walks backward from yesterday until goal not met.
- **D-05:** `WaterEntryDao.getEarliestDateKey()` returns `Future<String?>`. Repository exposes as pass-through.
- **D-06:** Two separate providers: `calendarMonthProvider(year, month)` family and `streakProvider` non-family, both `AsyncValue`.
- **D-07:** `calendarMonthProvider` is `@riverpod` family. Riverpod caches each month separately.
- **D-08:** `streakProvider` queries from `DateTime(2020, 1, 1)` as lower bound.
- **D-09:** `focusedMonthProvider` is keepAlive. Initialized to current month. Survives tab switches.
- **D-10:** Block future months via `lastDay` parameter set to last day of current month.
- **D-11:** `firstDay` = date from `getEarliestDateKey()`. Loading shows spinner. Null fallback: `DateTime(2020, 1, 1)`.
- **D-12:** `HistoryScreen` is `ConsumerStatefulWidget`. `getEarliestDateKey()` initiated in `initState` with `setState` on resolve. `focusedMonthProvider` persists across tab switches.

### Claude's Discretion
- Exact Riverpod provider type for `focusedMonthProvider` (StateProvider vs NotifierProvider).
- Whether `calendarMonthProvider` and `streakProvider` are `keepAlive: true` or auto-dispose.
- AppBar title: `"History"`.
- Error state copy: `"Something went wrong loading your data."`.
- The `toDateKey()` helper -- create inline if not found.

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope.

</user_constraints>

<phase_requirements>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| HIST-01 | User can view a monthly calendar where each past day is colored green (daily goal met) or red (daily goal not met) | table_calendar 3.2.0 CalendarBuilders API provides `defaultBuilder` and `todayBuilder` for custom day cell decoration; `watchDailyTotalsInRange` provides per-day totals for color logic |
| HIST-02 | User can see their current streak of consecutive days with the daily goal reached | `streakProvider` computes streak by walking backward from yesterday through the daily totals map; StreakCard widget displays count |

</phase_requirements>

## Project Constraints (from CLAUDE.md)

- **Tech stack**: Flutter + Riverpod + Drift -- no deviation
- **Platform**: iOS and Android only
- **Offline-first**: No backend or cloud sync
- **State management**: `flutter_riverpod` 3.x with `@riverpod` code-gen (not hooks_riverpod)
- **Database**: Drift with `drift_flutter` (not sqlite3_flutter_libs)
- **Code generation**: `build_runner` required after adding new `@riverpod` providers or Drift DAO methods
- **UI Components**: `table_calendar ^3.2.0` is in recommended stack but NOT yet in `pubspec.yaml`
- **Deprecated API**: Use `withValues(alpha:)` not `withOpacity` (Flutter 3.44.1)
- **Async state**: Use `.value` (nullable `T?`), not `valueOrNull` (does not exist in Riverpod 3.2.1)

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Monthly calendar display | Client (Flutter widget) | -- | Pure UI rendering with table_calendar widget |
| Day cell decoration (green/red) | Client (Flutter widget) | -- | CalendarBuilders receives data from provider, applies visual logic |
| Daily totals aggregation | Data layer (Repository) | Database (Drift DAO) | Repository transforms raw entry stream into grouped totals; DAO provides the reactive query |
| Streak calculation | State layer (Riverpod provider) | -- | Pure computation from totals map + settings target; no persistence needed |
| Month navigation state | State layer (Riverpod provider) | -- | focusedMonthProvider with keepAlive for tab switch persistence |
| Earliest date lookup | Database (Drift DAO) | Data layer (Repository) | Single-row query, repository pass-through |

## Standard Stack

### Core (New Dependency)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| table_calendar | ^3.2.0 | Monthly calendar widget | 3.32k likes, 546k downloads on pub.dev, MIT-like (Apache-2.0) license, actively maintained; only calendar widget recommended in CLAUDE.md [CITED: pub.dev/packages/table_calendar] |

### Existing (Already in Project)

| Library | Version | Purpose | Used For |
|---------|---------|---------|----------|
| flutter_riverpod | ^3.3.1 | State management | calendarMonthProvider, streakProvider, focusedMonthProvider |
| riverpod_annotation | ^4.0.2 | Code-gen annotations | @riverpod and @Riverpod(keepAlive: true) on new providers |
| drift | ^2.33.0 | SQLite ORM | New getEarliestDateKey() DAO method |
| collection | transitive | groupBy utility | Grouping water entries by dateKey in repository stream transform [CITED: pub.dev/documentation/collection/latest/collection/groupBy.html] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| table_calendar | syncfusion_flutter_calendar | Requires commercial license; table_calendar is MIT/Apache-2.0 and simpler [CITED: CLAUDE.md Alternatives Considered] |
| table_calendar | flutter_calendar_carousel | Unmaintained (2+ years without updates) [CITED: CLAUDE.md Alternatives Considered] |
| collection groupBy | Manual fold/forEach | groupBy is a one-liner vs ~6 lines of manual accumulation; collection is already a transitive dep |

**Installation:**
```bash
# In pubspec.yaml, add under dependencies:
#   table_calendar: ^3.2.0
# Then run:
fvm flutter pub get
```

**Version verification:** table_calendar 3.2.0 confirmed as latest stable version on pub.dev, published approximately 17 months ago (stable, mature). [CITED: pub.dev/packages/table_calendar]

## Package Legitimacy Audit

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| table_calendar | pub.dev | ~4 yrs | 546k total | github.com/aleksanderwozniak/table_calendar | N/A (slopcheck only supports PyPI/npm) | Approved -- verified via pub.dev direct fetch: 3.32k likes, Apache-2.0 license, actively maintained |

**Packages removed due to slopcheck [SLOP] verdict:** None. slopcheck flagged table_calendar as SLOP on PyPI, but this is a cross-ecosystem false positive -- the package is a Dart/Flutter package on pub.dev, not a Python package. slopcheck does not support pub.dev registry verification.
**Packages flagged as suspicious [SUS]:** None.

*slopcheck does not support the Dart/pub.dev ecosystem. Package legitimacy verified via direct pub.dev page fetch (publisher, downloads, likes, license, source repo link).*

## Architecture Patterns

### System Architecture Diagram

```
User Action (swipe month / tap day / open History tab)
       |
       v
HistoryScreen (ConsumerStatefulWidget)
  |-- initState: getEarliestDateKey() future -> setState(_firstDay)
  |-- build:
  |     |-- ref.watch(focusedMonthProvider) -> DateTime focusedMonth
  |     |-- ref.watch(userSettingsProvider) -> dailyTargetMl
  |     |-- ref.watch(calendarMonthProvider(year, month)) -> Map<String, int>
  |     |-- ref.watch(streakProvider) -> int streakCount
  |     |
  |     v
  |   StreakCard (stateless)
  |     "N day streak" with flame icon
  |     |
  |     v
  |   TableCalendar
  |     |-- firstDay: _firstDay (from getEarliestDateKey)
  |     |-- lastDay: end of current month
  |     |-- focusedDay: from focusedMonthProvider
  |     |-- calendarBuilders:
  |     |     defaultBuilder: (ctx, day, focusedDay) ->
  |     |       lookup day in monthTotals map ->
  |     |       green fill (>= target) / red fill (> 0 && < target) / null
  |     |     todayBuilder: same logic + primary border ring
  |     |-- onPageChanged: update focusedMonthProvider
  |     |-- onDaySelected: update _selectedDay (local state)
  |     |
  |     v
  |   DaySummaryCard (AnimatedSwitcher, shown when _selectedDay != null)
  |
  v
calendarMonthProvider(year, month) [family, @riverpod]
  |-- ref.watch(waterRepositoryProvider)
  |-- repo.watchDailyTotalsInRange(firstOfMonth, lastOfMonth)
  |
  v
streakProvider [@riverpod]
  |-- ref.watch(waterRepositoryProvider)
  |-- ref.watch(userSettingsProvider)
  |-- repo.watchDailyTotalsInRange("2020-01-01", yesterday)
  |-- walk backward from yesterday: count consecutive days >= target
  |
  v
WaterRepository.watchDailyTotalsInRange(startDateKey, endDateKey)
  |-- calls WaterEntryDao.watchEntriesInRange(start, end) [existing]
  |-- .map(): groupBy(entries, (e) => e.dateKey)
  |-- sum amountMl per group -> Map<String, int>
  |
  v
WaterEntryDao (Drift)
  |-- watchEntriesInRange [existing, reactive]
  |-- getEarliestDateKey [new, Future<String?>]
```

### Recommended Project Structure

No new files beyond what CONTEXT.md specifies. Modifications to existing files:

```
lib/
  data/
    database/
      daos/
        water_entry_dao.dart        # ADD getEarliestDateKey()
    repositories/
      water_repository.dart         # ADD watchDailyTotalsInRange(), getEarliestDateKey()
  core/
    providers/
      stream_providers.dart         # ADD calendarMonthProvider, streakProvider, focusedMonthProvider
  presentation/
    screens/
      history_screen.dart           # REPLACE stub with full implementation
pubspec.yaml                        # ADD table_calendar: ^3.2.0
```

### Pattern 1: Riverpod Family Provider with Multiple Parameters (@riverpod Code-Gen)

**What:** The `@riverpod` annotation on a function with parameters beyond `Ref` automatically generates a family provider. Multiple parameters are supported natively -- no record types or custom family classes needed.
**When to use:** When the same data query needs different arguments (e.g., different months).
**Example:**
```dart
// Source: pub.dev/packages/riverpod_generator (verified family pattern)
// Source: existing stream_providers.dart pattern (single-param family already in codebase)
@riverpod
Stream<Map<String, int>> calendarMonth(Ref ref, int year, int month) {
  final repo = ref.watch(waterRepositoryProvider);
  final firstDay = DateTime(year, month, 1);
  final lastDay = DateTime(year, month + 1, 0); // last day of month
  final startKey = _toDateKey(firstDay);
  final endKey = _toDateKey(lastDay);
  return repo.watchDailyTotalsInRange(startKey, endKey);
}

// Widget usage:
// ref.watch(calendarMonthProvider(2026, 6))
```
[CITED: pub.dev/packages/riverpod_generator -- "we can pass multiple parameters, and use all the features of function parameters"]

### Pattern 2: NotifierProvider for Simple Mutable State (focusedMonthProvider)

**What:** A `@Riverpod(keepAlive: true)` Notifier class that holds a single `DateTime` value. Consistent with the codebase's exclusive use of `@riverpod` code-gen (no raw `StateProvider` exists anywhere in the project).
**When to use:** When you need a persistent, mutable state value that survives widget disposal.
**Example:**
```dart
// Recommended over StateProvider<DateTime> for codebase consistency
@Riverpod(keepAlive: true)
class FocusedMonth extends _$FocusedMonth {
  @override
  DateTime build() => DateTime.now();

  void set(DateTime month) => state = month;
}

// Widget usage:
// final focused = ref.watch(focusedMonthProvider);
// ref.read(focusedMonthProvider.notifier).set(newMonth);
```
[ASSUMED -- code-gen Notifier is the cleanest approach given codebase convention; StateProvider would also work but introduces a non-code-gen pattern]

### Pattern 3: Stream Transform with groupBy in Repository

**What:** Transform `Stream<List<WaterEntry>>` into `Stream<Map<String, int>>` by grouping entries by dateKey and summing amountMl.
**When to use:** D-01 repository method.
**Example:**
```dart
// Source: collection package groupBy function
// (pub.dev/documentation/collection/latest/collection/groupBy.html)
import 'package:collection/collection.dart';

Stream<Map<String, int>> watchDailyTotalsInRange(
    String startDateKey, String endDateKey) {
  return _db.waterEntryDao
      .watchEntriesInRange(startDateKey, endDateKey)
      .map((entries) {
    final grouped = groupBy(entries, (WaterEntry e) => e.dateKey);
    return grouped.map((dateKey, dayEntries) =>
        MapEntry(dateKey, dayEntries.fold(0, (sum, e) => sum + e.amountMl)));
  });
}
```
[CITED: pub.dev/documentation/collection/latest/collection/groupBy.html]

### Pattern 4: CalendarBuilders Day Decoration

**What:** Custom day cell rendering using `calendarBuilders.defaultBuilder` and `calendarBuilders.todayBuilder`.
**When to use:** Applying green/red color coding to calendar day cells.
**Example:**
```dart
// Source: pub.dev/documentation/table_calendar/latest/table_calendar/CalendarBuilders-class.html
// FocusedDayBuilder signature: Widget? Function(BuildContext, DateTime day, DateTime focusedDay)
calendarBuilders: CalendarBuilders(
  defaultBuilder: (context, day, focusedDay) {
    final dateKey = _toDateKey(day);
    final total = monthTotals[dateKey]; // from calendarMonthProvider
    if (total == null) return null; // no data -- default rendering
    final metGoal = total >= dailyTarget;
    return _buildDayCell(day, metGoal, isToday: false);
  },
  todayBuilder: (context, day, focusedDay) {
    final dateKey = _toDateKey(day);
    final total = monthTotals[dateKey];
    if (total == null) {
      // Today with no data: just show primary border ring
      return _buildDayCell(day, null, isToday: true);
    }
    final metGoal = total >= dailyTarget;
    return _buildDayCell(day, metGoal, isToday: true);
  },
),
```
[CITED: pub.dev/documentation/table_calendar/latest/table_calendar/CalendarBuilders-class.html]

### Pattern 5: Drift Query for Earliest Date Key

**What:** Single-row query using Drift's `select` with `orderBy` ASC and `limit(1)`.
**When to use:** D-05 DAO method.
**Example:**
```dart
// Pattern consistent with existing deleteLastEntry query style in water_entry_dao.dart
Future<String?> getEarliestDateKey() async {
  final result = await (select(waterEntries)
        ..orderBy([(t) => OrderingTerm.asc(t.dateKey)])
        ..limit(1))
      .getSingleOrNull();
  return result?.dateKey;
}
```
[VERIFIED: pattern matches existing water_entry_dao.dart `deleteLastEntry` query structure]

### Anti-Patterns to Avoid

- **Using `eventLoader` for day decoration:** `eventLoader` is for event dots/markers below the day number, not for background color. Use `calendarBuilders.defaultBuilder` for background decoration instead.
- **Using `calendarStyle` decorations for dynamic data:** `todayDecoration`, `defaultDecoration` etc. in `CalendarStyle` are static (same for all days). Dynamic per-day coloring requires `CalendarBuilders`.
- **Mixing code-gen and non-code-gen providers:** The codebase uses exclusively `@riverpod` annotation. Do not introduce raw `StateProvider` or `StateNotifierProvider` -- use `@Riverpod(keepAlive: true) class` Notifier pattern instead.
- **Querying all history on every calendar page change:** Each month should be queried independently via the family provider. Riverpod caches each (year, month) combination -- navigating back to a visited month does not re-query (D-07).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Calendar widget | Custom month grid with gesture detection | `table_calendar` 3.2.0 | Handles month pagination, swipe gestures, header navigation, day-of-week headers, locale support, accessibility labels. ~2000 lines of widget code you'd need to maintain. |
| Day-same comparison | Custom year/month/day comparison function | `isSameDay(a, b)` from table_calendar | Already handles null safety, exported as top-level function [CITED: pub.dev/documentation/table_calendar/latest/table_calendar/isSameDay.html] |
| List grouping | Manual `Map<String, List<T>>` accumulation via forEach | `groupBy()` from `package:collection` | One-liner, well-tested, handles edge cases [CITED: pub.dev/documentation/collection/latest/collection/groupBy.html] |
| Last day of month | Manual month-length lookup (28/29/30/31 logic) | `DateTime(year, month + 1, 0)` | Dart's DateTime constructor handles month overflow correctly; day=0 gives last day of previous month [ASSUMED -- standard Dart DateTime behavior] |

**Key insight:** table_calendar handles the entire calendar rendering pipeline (pagination, header, day layout, gestures, accessibility). The only custom work is the day cell decoration via `CalendarBuilders` and the data pipeline feeding it.

## Common Pitfalls

### Pitfall 1: table_calendar firstDay/lastDay Must Be UTC or Match focusedDay TZ

**What goes wrong:** If `firstDay` and `lastDay` use different timezone representations than `focusedDay`, table_calendar may throw assertion errors or show incorrect months.
**Why it happens:** table_calendar internally normalizes dates. Mixing UTC and local DateTime can cause off-by-one day issues near midnight.
**How to avoid:** Use `DateTime(year, month, day)` (local time) consistently for `firstDay`, `lastDay`, and `focusedDay`. The UI-SPEC shows `DateTime.utc(2024, 1, 1)` for firstDay but this is a fallback default -- use local time consistently. The `focusedDay` from `DateTime.now()` is local, so `firstDay` should also be local.
**Warning signs:** Calendar shows wrong month on first render, or assertion failure in debug mode.
[ASSUMED -- based on common table_calendar issues reported in GitHub issues; the UTC vs local distinction is a documented concern]

### Pitfall 2: Streak Provider Watching Full History Stream

**What goes wrong:** `streakProvider` watching `watchDailyTotalsInRange("2020-01-01", yesterday)` triggers a re-query of the entire history every time any water entry changes anywhere in the database.
**Why it happens:** Drift's `watch()` re-emits the entire result set whenever the underlying table changes, regardless of which row changed.
**How to avoid:** Accept this as a design tradeoff (per D-04/D-08). The streak computation is cheap (pure Dart map iteration). The query itself may return many rows but only on table changes. For a personal hydration app this is negligible -- the table grows by ~5-10 entries per day. If performance becomes an issue in the future, the streak could be cached in a separate table (deferred optimization).
**Warning signs:** Noticeable UI lag after adding a water entry on the home screen while the History tab is alive.
[ASSUMED -- based on Drift reactive query behavior]

### Pitfall 3: focusedDay Must Be Within firstDay-lastDay Range

**What goes wrong:** table_calendar throws an assertion error if `focusedDay` is before `firstDay` or after `lastDay`.
**Why it happens:** The widget requires `focusedDay` to be within the navigable range.
**How to avoid:** Clamp `focusedDay` to the `[firstDay, lastDay]` range. If `focusedMonthProvider` holds a date that's somehow outside the range (e.g., after `getEarliestDateKey` resolves to a later date), clamp it before passing to `TableCalendar`.
**Warning signs:** Red assertion error screen in debug mode on first render.
[CITED: pub.dev/documentation/table_calendar/latest/table_calendar/TableCalendar-class.html -- firstDay, lastDay, focusedDay are required parameters]

### Pitfall 4: onPageChanged Returns a DateTime in the Middle of the Month

**What goes wrong:** `onPageChanged` callback receives a `DateTime` that is the `focusedDay` of the new page -- which is NOT necessarily the 1st of the month. If you use `.month` from this to construct query keys, you get the right month, but the day component may be surprising.
**Why it happens:** table_calendar preserves the focused day's relative position when changing pages.
**How to avoid:** When updating `focusedMonthProvider` from `onPageChanged`, only extract `.year` and `.month` for provider lookups. Do not use the full DateTime for date-key calculations.
**Warning signs:** None visible -- but a subtle bug if the focused day is used for anything beyond month identification.
[ASSUMED -- based on table_calendar behavior patterns]

### Pitfall 5: build_runner Must Run After Adding New Providers

**What goes wrong:** Adding new `@riverpod` annotated functions or classes without running `dart run build_runner build` results in missing `.g.dart` files and compilation errors.
**Why it happens:** Riverpod code-gen requires explicit build step.
**How to avoid:** Run `dart run build_runner build --delete-conflicting-outputs` after creating new provider files or modifying `@riverpod` annotations.
**Warning signs:** Import errors for `*.g.dart` files.
[VERIFIED: existing codebase pattern -- all providers have .g.dart counterparts]

### Pitfall 6: Streak Edge Case -- Daily Target of 0

**What goes wrong:** If `dailyTargetMl` is 0, every day trivially meets the goal (0 >= 0), resulting in an infinite streak.
**Why it happens:** The streak walk-backward algorithm checks `total >= dailyTarget`.
**How to avoid:** Guard with `if (dailyTarget <= 0) return 0;` at the start of streak computation. A target of 0 means no goal is set, so streak should be 0.
**Warning signs:** Streak displays an extremely large number.
[ASSUMED -- logical edge case analysis]

## Code Examples

### Complete DAO Method: getEarliestDateKey

```dart
// Add to water_entry_dao.dart
// Pattern: matches existing deleteLastEntry query structure
/// Get the earliest dateKey in the water_entries table.
/// Returns null if no entries exist (new user).
Future<String?> getEarliestDateKey() async {
  final result = await (select(waterEntries)
        ..orderBy([(t) => OrderingTerm.asc(t.dateKey)])
        ..limit(1))
      .getSingleOrNull();
  return result?.dateKey;
}
```
[VERIFIED: pattern matches existing water_entry_dao.dart query structure]

### Complete Repository Method: watchDailyTotalsInRange

```dart
// Add to water_repository.dart
// Uses collection package's groupBy for clean aggregation
import 'package:collection/collection.dart';

/// Watch daily totals for a date range, grouped by dateKey.
/// Returns Stream<Map<String, int>> where key = dateKey, value = sum of amountMl.
/// Days with no entries are absent from the map.
Stream<Map<String, int>> watchDailyTotalsInRange(
    String startDateKey, String endDateKey) {
  return _db.waterEntryDao
      .watchEntriesInRange(startDateKey, endDateKey)
      .map((entries) {
    final grouped = groupBy(entries, (e) => e.dateKey);
    return grouped.map((dateKey, dayEntries) =>
        MapEntry(dateKey, dayEntries.fold(0, (sum, e) => sum + e.amountMl)));
  });
}

/// Get the earliest dateKey. Pass-through to DAO.
Future<String?> getEarliestDateKey() {
  return _db.waterEntryDao.getEarliestDateKey();
}
```
[CITED: pub.dev/documentation/collection/latest/collection/groupBy.html for groupBy usage]

### Provider: calendarMonthProvider (Family, Multi-Param)

```dart
// Add to stream_providers.dart (or new history_providers.dart)
@riverpod
Stream<Map<String, int>> calendarMonth(Ref ref, int year, int month) {
  final repo = ref.watch(waterRepositoryProvider);
  final firstDay = DateTime(year, month, 1);
  final lastDay = DateTime(year, month + 1, 0);
  final startKey = '${firstDay.year}-${firstDay.month.toString().padLeft(2, '0')}-${firstDay.day.toString().padLeft(2, '0')}';
  final endKey = '${lastDay.year}-${lastDay.month.toString().padLeft(2, '0')}-${lastDay.day.toString().padLeft(2, '0')}';
  return repo.watchDailyTotalsInRange(startKey, endKey);
}
```
[CITED: pub.dev/packages/riverpod_generator -- multi-param family support confirmed]

### Provider: streakProvider

```dart
@riverpod
Stream<int> streak(Ref ref) async* {
  final repo = ref.watch(waterRepositoryProvider);
  final settings = ref.watch(userSettingsProvider).value;
  if (settings == null) {
    yield 0;
    return;
  }

  final dailyTarget = settings.dailyTargetMl;
  if (dailyTarget <= 0) {
    yield 0;
    return;
  }

  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  final yesterdayKey = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

  yield* repo.watchDailyTotalsInRange('2020-01-01', yesterdayKey).map((totals) {
    int streak = 0;
    var current = yesterday;
    while (true) {
      final key = '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';
      final total = totals[key] ?? 0;
      if (total >= dailyTarget) {
        streak++;
        current = current.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  });
}
```
[ASSUMED -- streak algorithm derived from D-04/D-08 context decisions]

### Provider: focusedMonthProvider (NotifierProvider, keepAlive)

```dart
@Riverpod(keepAlive: true)
class FocusedMonth extends _$FocusedMonth {
  @override
  DateTime build() => DateTime.now();

  void set(DateTime month) => state = month;
}
```
[ASSUMED -- NotifierProvider recommended over StateProvider for codebase consistency with code-gen pattern]

### Helper: _toDateKey

```dart
// If todayDateKey() from stream_providers.dart is not suitable for arbitrary dates,
// create a local helper:
String _toDateKey(DateTime d) {
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
```
[VERIFIED: matches exact format used in existing todayDateKey() function in stream_providers.dart]

### Day Cell Builder Widget

```dart
// Source: 04-UI-SPEC.md locked visual spec
Widget? _buildDayCell(DateTime day, bool? metGoal, {required bool isToday}) {
  Color? fillColor;
  Color? textColor;

  if (metGoal == true) {
    fillColor = Colors.green.shade600.withValues(alpha: 0.15);
    textColor = Colors.green.shade600;
  } else if (metGoal == false) {
    fillColor = Colors.red.shade600.withValues(alpha: 0.15);
    textColor = Colors.red.shade600;
  }

  final colorScheme = Theme.of(context).colorScheme;

  return Container(
    margin: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: fillColor,
      border: isToday ? Border.all(color: colorScheme.primary, width: 2) : null,
    ),
    alignment: Alignment.center,
    child: Text(
      '${day.day}',
      style: TextStyle(
        color: textColor,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
```
[CITED: 04-UI-SPEC.md CalendarBuilders Day Decoration Logic section]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `withOpacity(0.15)` | `withValues(alpha: 0.15)` | Flutter 3.44.1 | `withOpacity` deprecated; use `withValues` for all alpha operations |
| `valueOrNull` on AsyncValue | `.value` (nullable `T?`) | Riverpod 3.2.1 | `valueOrNull` does not exist; `.value` returns `T?` |
| `sqlite3_flutter_libs` | `drift_flutter` | drift_flutter 0.3.0 | Old package is EOL; already using drift_flutter in project |
| Raw `StateProvider` | `@Riverpod(keepAlive: true) class Notifier` | Riverpod 3.x code-gen | Code-gen Notifier is the current recommended pattern for mutable state |

**Deprecated/outdated:**
- `Color.withOpacity()`: Deprecated in Flutter 3.44.1. Use `Color.withValues(alpha:)`.
- `StateProvider`: Still works but is a legacy non-code-gen pattern. Codebase exclusively uses `@riverpod` code-gen.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | NotifierProvider is cleaner than StateProvider for focusedMonthProvider given codebase's code-gen convention | Architecture Patterns - Pattern 2 | Low -- StateProvider would also work; both achieve the same result |
| A2 | table_calendar firstDay/lastDay should use local time (not UTC) to match focusedDay | Pitfalls - Pitfall 1 | Medium -- could cause assertion errors or wrong month display if wrong |
| A3 | Drift re-emits full result set on any table change regardless of which row changed | Pitfalls - Pitfall 2 | Low -- this is well-documented Drift behavior; the concern is performance not correctness |
| A4 | onPageChanged returns a DateTime that may not be the 1st of the month | Pitfalls - Pitfall 4 | Low -- only affects code that incorrectly uses the day component |
| A5 | Daily target of 0 should result in streak of 0 | Pitfalls - Pitfall 6 | Low -- logical edge case; alternative is infinite streak which is clearly wrong |
| A6 | `DateTime(year, month + 1, 0)` correctly gives last day of month in Dart | Don't Hand-Roll | Low -- this is standard Dart DateTime behavior but not verified via official docs in this session |
| A7 | `collection` package can be imported directly since it's a transitive dependency | Standard Stack | Low -- Dart allows importing transitive deps, though explicit dep is best practice. Since collection is from the Dart team and used by Flutter itself, risk is minimal |

## Open Questions

1. **Should `collection` be added as an explicit dependency in pubspec.yaml?**
   - What we know: `collection` is a transitive dependency (already in pubspec.lock). It can be imported directly.
   - What's unclear: Whether the project convention is to add explicit deps for all imports.
   - Recommendation: Add it explicitly (`collection: ^1.19.0`) for clarity, or skip since it's a Dart SDK companion package that will always be available. Either approach works.

2. **Should `intl` be added for date formatting in the day summary card?**
   - What we know: `intl` is in CLAUDE.md recommended stack (`^0.20.2`) but NOT in pubspec.yaml or pubspec.lock. The day summary shows `"June 3, 2026 -- 2,400 of 3,000 ml"`.
   - What's unclear: Whether to use `intl` DateFormat or manual string formatting.
   - Recommendation: Use manual formatting (`_monthName(month) + ' ${day.day}, ${day.year}'`) to avoid adding a new dependency for a single format string. Add `intl` in a future phase if locale support becomes needed.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | All | Yes (via FVM) | 3.44.1 | -- |
| Dart SDK | All | Yes (via Flutter) | >= 3.10.0 | -- |
| build_runner | Code generation after adding providers | Yes | ^2.15.0 (in pubspec) | -- |
| table_calendar | Calendar widget (HIST-01) | Not yet (must add to pubspec) | ^3.2.0 | -- |

**Missing dependencies with no fallback:** None (table_calendar addition is a planned task step, not an environmental blocker).
**Missing dependencies with fallback:** None.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | N/A -- offline single-user app |
| V3 Session Management | No | N/A -- no sessions |
| V4 Access Control | No | N/A -- single user, no roles |
| V5 Input Validation | No | No user input in this phase -- read-only history view. All data comes from existing validated water entries (validated in WaterRepository.insertEntry per Phase 1). |
| V6 Cryptography | No | N/A -- no encryption needed |

This phase is a **read-only view** with zero user input, zero destructive actions, and zero network calls. No security controls are needed beyond what Phase 1 already provides for data integrity.

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| N/A | N/A | This phase is read-only display of locally stored data -- no attack surface introduced |

## Sources

### Primary (HIGH confidence)
- [pub.dev/packages/table_calendar](https://pub.dev/packages/table_calendar) -- version, downloads, license, publisher verified via direct fetch
- [pub.dev/documentation/table_calendar/latest/table_calendar/TableCalendar-class.html](https://pub.dev/documentation/table_calendar/latest/table_calendar/TableCalendar-class.html) -- full constructor parameter list
- [pub.dev/documentation/table_calendar/latest/table_calendar/CalendarBuilders-class.html](https://pub.dev/documentation/table_calendar/latest/table_calendar/CalendarBuilders-class.html) -- all builder function names and FocusedDayBuilder signature
- [pub.dev/documentation/table_calendar/latest/table_calendar/CalendarFormat.html](https://pub.dev/documentation/table_calendar/latest/table_calendar/CalendarFormat.html) -- enum values (month, twoWeeks, week)
- [pub.dev/documentation/table_calendar/latest/table_calendar/HeaderStyle-class.html](https://pub.dev/documentation/table_calendar/latest/table_calendar/HeaderStyle-class.html) -- formatButtonVisible, titleCentered confirmed
- [pub.dev/documentation/table_calendar/latest/table_calendar/CalendarStyle-class.html](https://pub.dev/documentation/table_calendar/latest/table_calendar/CalendarStyle-class.html) -- todayDecoration, outsideDaysVisible, isTodayHighlighted
- [pub.dev/documentation/table_calendar/latest/table_calendar/isSameDay.html](https://pub.dev/documentation/table_calendar/latest/table_calendar/isSameDay.html) -- top-level function confirmed
- [pub.dev/documentation/collection/latest/collection/groupBy.html](https://pub.dev/documentation/collection/latest/collection/groupBy.html) -- groupBy signature and usage
- [pub.dev/packages/riverpod_generator](https://pub.dev/packages/riverpod_generator) -- multi-parameter family provider support confirmed

### Secondary (MEDIUM confidence)
- Existing codebase patterns (water_entry_dao.dart, stream_providers.dart, home_screen.dart, settings_screen.dart) -- verified by direct file read
- 04-CONTEXT.md and 04-UI-SPEC.md -- locked decisions and visual contract

### Tertiary (LOW confidence)
- table_calendar UTC vs local time behavior (Pitfall 1) -- based on common community reports, not verified via official docs
- onPageChanged DateTime behavior (Pitfall 4) -- based on API pattern analysis, not verified via official docs

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- table_calendar 3.2.0 verified on pub.dev with version, downloads, license. All other packages already in project.
- Architecture: HIGH -- all decisions locked in CONTEXT.md. Provider patterns verified against existing codebase code-gen conventions and Riverpod docs.
- Pitfalls: MEDIUM -- some pitfalls (1, 4) based on community experience rather than official documentation. Core pitfalls (5, 6) verified against codebase patterns.

**Research date:** 2026-06-05
**Valid until:** 2026-07-05 (table_calendar 3.2.0 is 17 months old and stable; Riverpod 3.x is mature)
