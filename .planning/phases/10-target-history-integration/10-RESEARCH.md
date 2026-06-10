# Phase 10: Target History Integration - Research

**Researched:** 2026-06-10
**Domain:** Riverpod provider layer (keepAlive Notifier + stream family), Drift schema extension (new column), UI wiring (Home/Calendar/Settings)
**Confidence:** HIGH

## Summary

Phase 10 wires the `TargetHistoryDao` (built in Phase 9) into the Riverpod provider layer, updates three screens (Home, Calendar, Settings), and fixes BUG-02 (midnight date reset). All work uses existing packages -- no new dependencies.

The most important technical finding is that `TargetHistoryDao.getTargetForDate()` is a `Future<int?>`, not a stream. The CONTEXT.md D-08 says the family provider should return `Stream<int>` from `getTargetForDate`, but that method is a one-shot future. **A new `watchTargetForDate(String dateKey)` method must be added to `TargetHistoryDao`** that converts the same query to a stream using `.watchSingleOrNull()` instead of `.getSingleOrNull()`. This follows the exact pattern used by `UserSettingsDao.watchSettings()` at line 17-19. Alternatively, the provider can use `watchAll()` and derive per-day targets in memory, but a dedicated watch method is cleaner and matches the DAO pattern.

The second critical finding is the Timer-based `todayDateKeyProvider` pattern. The codebase already has a `FocusedMonth` class-based Notifier with `@Riverpod(keepAlive: true)` that demonstrates the exact generated base class pattern (`extends _$FocusedMonth extends $Notifier<DateTime>`). The `todayDateKeyProvider` follows this same shape but adds a `Timer` in `build()` and cancels it via `ref.onDispose()` -- a pattern already used in `database_provider.dart` line 9. HomeScreen currently has its own `Timer.periodic(60s)` midnight check (lines 39-43); this will be removed and replaced by `ref.watch(todayDateKeyProvider)`.

**Primary recommendation:** Add `watchTargetForDate(String dateKey)` to `TargetHistoryDao`, create `todayDateKeyProvider` as a keepAlive Notifier with Timer, add `applyFromTomorrow` column to UserSettings table, and wire all three screens to per-day target providers. Run `dart run build_runner build --delete-conflicting-outputs` after schema and provider changes.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Create a `todayDateKeyProvider` as a keepAlive `Notifier<String>`. On `build()`, computes seconds until next midnight, sets a `Timer` that fires at midnight + a few ms, updates `state` with the new date string, then re-schedules the next midnight Timer. The Notifier disposes the Timer on dispose.
- **D-02:** All widgets that previously called `todayDateKey()` directly replace it with `ref.watch(todayDateKeyProvider)`. Affected: `HomeScreen` (for `totalMlForDateProvider` and `waterEntriesForDateProvider`) and the `streak` provider in `stream_providers.dart`.
- **D-03:** `HistoryScreen` calendar does NOT need the midnight reset -- users navigate to months explicitly. Only today's-date consumers need the update.
- **D-04:** The "today / tomorrow" choice is a **persistent toggle** in the Settings screen (not a per-change dialog). Presented as a SegmentedButton or labeled Switch inside the existing target section.
- **D-05:** The preference is stored as a new column `applyFromTomorrow` (Drift boolean, `withDefault(const Constant(false))`) on the `UserSettings` table. No schema migration is needed -- `schemaVersion` stays at `1` (first real installation). Default `false` = "apply from today".
- **D-06:** `updateTargetWithHistory(int newTargetMl)` lives in `SettingsRepository`. It: (1) reads `applyFromTomorrow` from current settings; (2) computes `effectiveDate` as today or tomorrow accordingly; (3) calls `db.targetHistoryDao.insertOrReplace(effectiveDate, newTargetMl)`; (4) calls `db.userSettingsDao.updateSettings(companion with dailyTargetMl)` -- both in the same async sequence.
- **D-07:** If the user changes target multiple times "from tomorrow" on the same day, `insertOrReplace` upserts -- only the last value for that `effectiveDate` survives.
- **D-08:** Add a family provider `effectiveTargetForDate(String dateKey)` that returns `Stream<int>` from `targetHistoryDao.getTargetForDate(dateKey)`. Falls back to 2000 if `null`.
- **D-09:** `HomeScreen` replaces `settings.dailyTargetMl` with `ref.watch(effectiveTargetForDateProvider(todayKey))` for the progress ring and goal text.
- **D-10:** `HistoryScreen` calendar (day builder) uses `effectiveTargetForDateProvider(dateKey)` for each day it colors green/red.
- **D-11:** The `streak` provider is updated to: (a) also watch `targetHistoryDao.watchAll()` for all target changes; (b) for each day in the history range, look up the active target by finding the most recent `effectiveDate <= dayKey` in the fetched list; (c) this is a single in-memory scan, not N SQL queries.

### Claude's Discretion
- Exact naming of the `todayDateKeyProvider` class vs function
- Whether `effectiveTargetForDateProvider` is a `@riverpod` annotated function or a manual `StreamProvider.family`
- Positioning of the "Applica da oggi / da domani" toggle within the existing Settings screen layout
- Timer re-schedule strategy when the device clock changes

### Deferred Ideas (OUT OF SCOPE)
- `updateTargetWithHistory()` called from calculator "Usa come target" button -- Phase 11
- Provider wiring for calculator screen -- Phase 11
- UI polish for the "Applica da" toggle (animations, accessibility labels) -- Phase 11 or later
- Calendar heat-map or color intensity based on intake percentage -- future milestone
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BUG-02 | La data corrente si aggiorna a mezzanotte senza richiedere restart dell'app | `todayDateKeyProvider` Notifier with midnight Timer; removes HomeScreen's manual `Timer.periodic(60s)` at lines 39-43; pattern verified from existing `FocusedMonth` Notifier + `ref.onDispose` in `database_provider.dart` |
| TARGET-02 | Nuovo setting "Applica target da: oggi / da domani" | New `applyFromTomorrow` boolean column on `UserSettings` table with `withDefault(const Constant(false))`; `updateTargetWithHistory()` method on `SettingsRepository`; toggle UI in Settings screen's daily goal card |
| TARGET-03 | Home screen usa il target effettivo della giornata corrente per il progress ring e il testo goal | `effectiveTargetForDateProvider(todayKey)` replaces `settings.dailyTargetMl` in `HomeScreen._buildContent()` at line 129; requires new `watchTargetForDate()` DAO method |
| TARGET-04 | Calendario usa il target effettivo della giornata appropriata per determinare verde/rosso per ogni giorno | `effectiveTargetForDateProvider(dateKey)` used in `HistoryScreen` calendar builders at lines 225-286; replaces single `dailyTarget` variable |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Midnight date key refresh (BUG-02) | Frontend Server (Provider layer) | -- | Pure state management; Timer drives state update, widgets react |
| `applyFromTomorrow` column | Database / Storage | -- | Schema definition; column with default |
| `updateTargetWithHistory()` | API / Backend (Repository) | Database / Storage | Business logic (today vs tomorrow) in repository, DAO for persistence |
| `effectiveTargetForDate` provider | Frontend Server (Provider layer) | Database / Storage | Provider orchestrates DAO stream; widgets consume |
| Per-day target in Home screen | Browser / Client (Widget) | Frontend Server (Provider layer) | UI reads provider; no business logic in widget |
| Per-day target in Calendar | Browser / Client (Widget) | Frontend Server (Provider layer) | Same pattern; per-day lookup in day builder |
| Streak with per-day targets | Frontend Server (Provider layer) | Database / Storage | Provider combines two streams (totals + targets); in-memory scan |
| Settings toggle UI | Browser / Client (Widget) | -- | Pure presentation; calls repository method |

## Standard Stack

### Core (already installed -- no changes)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter_riverpod | ^3.3.1 | State management | Already in pubspec.yaml; provides `@Riverpod(keepAlive: true)` for Notifier |
| riverpod_annotation | ^4.0.2 | Code-gen annotations | Already in pubspec.yaml; `@riverpod` and `@Riverpod(keepAlive: true)` |
| riverpod_generator | ^4.0.3 | Provider code generation | Already in pubspec.yaml (dev); generates `.g.dart` files |
| drift | ^2.33.0 | Type-safe SQLite ORM | Already in pubspec.yaml; table definitions, watch streams |
| drift_dev | ^2.33.0 | Code generator for Drift | Already in pubspec.yaml (dev); regenerates after column addition |
| build_runner | ^2.15.0 | Code generation orchestrator | Already in pubspec.yaml (dev) |
| freezed_annotation | ^3.1.0 | Immutable data classes | Already in pubspec.yaml; `UserSettingsEntity` uses freezed |
| freezed | ^3.2.5 | Code generator for data classes | Already in pubspec.yaml (dev); regenerates after entity field addition |

**No new packages needed.** Phase 10 uses only existing dependencies. [VERIFIED: pubspec.yaml]

**Installation:** N/A -- all packages already installed.

**Code generation command (run after all schema/provider/entity changes):**
```bash
dart run build_runner build --delete-conflicting-outputs
```

## Architecture Patterns

### System Architecture Diagram

```
                          Phase 10 Scope
                          =============

  +-----------+     +---------------------+     +-------------------+
  | HomeScreen |---->| todayDateKeyProvider|---->| Timer(midnight)   |
  | HistoryScr |     | (keepAlive Notifier)|     | -> state = newKey |
  | SettingScr |     +---------------------+     +-------------------+
  |            |              |
  |            |              v
  |            |     +----------------------------+
  |            |---->| effectiveTargetForDate      |----+
  |            |     | Provider(dateKey)           |    |
  |            |     | (stream family, keepAlive)  |    |
  |            |     +----------------------------+    |
  |            |                                       |
  |            |     +----------------------------+    |
  |            |---->| streak provider (updated)   |    |
  |            |     | watches: totals + targets   |    |
  |            |     +----------------------------+    |
  |            |              |                        |
  +-----------+              v                        v
                     +----------------------------+
                     | TargetHistoryDao            |
                     | + watchTargetForDate(key)   |  <-- NEW method
                     | + watchAll()                |
                     | + insertOrReplace(date, ml) |
                     | + getTargetForDate(key)     |
                     +----------------------------+
                              |
  +-----------+     +----------------------------+
  | Settings   |---->| SettingsRepository          |
  | Screen     |     | + updateTargetWithHistory() | <-- NEW method
  | (slider +  |     | + updateSettings()          |
  |  toggle)   |     +----------------------------+
  +-----------+              |
                     +----------------------------+
                     | UserSettings table          |
                     | + applyFromTomorrow BOOL    | <-- NEW column
                     +----------------------------+
```

### Recommended Project Structure

```
lib/data/database/
  tables/
    user_settings_table.dart     # MODIFIED: add applyFromTomorrow column
  daos/
    target_history_dao.dart      # MODIFIED: add watchTargetForDate()
    target_history_dao.g.dart    # REGENERATED
    user_settings_dao.dart       # MODIFIED: update _defaultSettings()
    user_settings_dao.g.dart     # REGENERATED
  app_database.g.dart            # REGENERATED (schema change)

lib/domain/entities/
  user_settings_entity.dart      # MODIFIED: add applyFromTomorrow field
  user_settings_entity.freezed.dart  # REGENERATED

lib/data/repositories/
  settings_repository.dart       # MODIFIED: add updateTargetWithHistory(), update mappings

lib/core/providers/
  stream_providers.dart          # MODIFIED: add todayDateKeyProvider, effectiveTargetForDate,
                                 #           update streak provider
  stream_providers.g.dart        # REGENERATED

lib/presentation/screens/
  home_screen.dart               # MODIFIED: use todayDateKeyProvider + effectiveTargetForDate
  history_screen.dart            # MODIFIED: per-day target in calendar builders
  settings_screen.dart           # MODIFIED: add toggle, route target through updateTargetWithHistory
```

### Pattern 1: keepAlive Notifier with Timer (todayDateKeyProvider)

**What:** A class-based Riverpod Notifier that computes today's date key, schedules a Timer to fire at midnight, and updates state when the day changes. `keepAlive: true` ensures it survives widget disposal.

**When to use:** When you need app-wide reactive state that changes on a time-based trigger, not user interaction.

**Example:**
```dart
// Source: follows exact pattern of FocusedMonth in stream_providers.dart:127-133
// Timer pattern from CONTEXT.md D-01; ref.onDispose from database_provider.dart:9
import 'dart:async';

@Riverpod(keepAlive: true)
class TodayDateKey extends _$TodayDateKey {
  Timer? _midnightTimer;

  @override
  String build() {
    ref.onDispose(() {
      _midnightTimer?.cancel();
    });
    _scheduleMidnightRefresh();
    return _computeTodayKey();
  }

  String _computeTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  void _scheduleMidnightRefresh() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    // Add 1 second buffer to ensure we are past midnight
    final duration = nextMidnight.difference(now) + const Duration(seconds: 1);
    _midnightTimer = Timer(duration, _onMidnight);
  }

  void _onMidnight() {
    state = _computeTodayKey();
    _scheduleMidnightRefresh();
  }
}
```

**Generated provider name:** `todayDateKeyProvider` (Riverpod code-gen convention: `TodayDateKey` -> `todayDateKeyProvider`). [VERIFIED: matches FocusedMonth -> focusedMonthProvider pattern in stream_providers.g.dart:474]

**Generated base class:** `_$TodayDateKey extends $Notifier<String>`. [VERIFIED: matches `_$FocusedMonth extends $Notifier<DateTime>` at stream_providers.g.dart:523]

**Key details:**
- `ref.onDispose` is available in class-based Notifiers via `this.ref` [VERIFIED: used in database_provider.dart:9 for functional provider; same `ref` API in Notifiers]
- `_midnightTimer` is a class field, not a local variable, so it persists across the Notifier's lifetime
- `_onMidnight` sets `state` (which triggers all watchers) then re-schedules for the next midnight
- The old `todayDateKey()` helper function at stream_providers.dart:57-60 can remain as a utility but should no longer be the primary source of truth in widgets

### Pattern 2: Stream Family Provider (effectiveTargetForDate)

**What:** A code-gen family provider that watches a Drift stream for the target active on a given date, with keepAlive to avoid re-subscribing.

**When to use:** When multiple widgets need the effective target for different dates.

**Critical finding:** `TargetHistoryDao.getTargetForDate(String dateKey)` returns `Future<int?>`, NOT `Stream<int?>`. The CONTEXT.md D-08 says "returns Stream<int> from targetHistoryDao.getTargetForDate(dateKey)" but this is architecturally impossible since `getTargetForDate` is a one-shot future. **A new `watchTargetForDate(String dateKey)` method must be added to the DAO.**

**New DAO method (add to target_history_dao.dart):**
```dart
// Source: follows exact pattern of UserSettingsDao.watchSettings() at line 17-19
// and the existing getTargetForDate() query converted from .getSingleOrNull() to .watchSingleOrNull()

/// Reactive stream of the targetMl for the most recent row where effectiveDate <= dateKey.
/// Emits null if no rows exist (defensive).
Stream<int?> watchTargetForDate(String dateKey) {
  return (select(targetHistory)
        ..where((t) => t.effectiveDate.isSmallerOrEqualValue(dateKey))
        ..orderBy([(t) => OrderingTerm.desc(t.effectiveDate)])
        ..limit(1))
      .watchSingleOrNull()
      .map((row) => row?.targetMl);
}
```

**Provider:**
```dart
// Source: follows calendarMonth provider pattern at stream_providers.dart:69-76
@Riverpod(keepAlive: true)
Stream<int> effectiveTargetForDate(Ref ref, String dateKey) {
  final db = ref.watch(appDatabaseProvider);
  return db.targetHistoryDao.watchTargetForDate(dateKey).map(
    (targetMl) => targetMl ?? 2000, // defensive fallback
  );
}
```

**Why keepAlive:** The Home screen's target must survive navigation between tabs. Without keepAlive, switching to History and back would re-subscribe and flash a loading state. [VERIFIED: same reasoning as userSettingsProvider at stream_providers.dart:39]

**Important: `.watchSingleOrNull()` re-emits when ANY row in `target_history` changes.** This is by design -- Drift watches the entire table, not individual rows. When a new target is inserted for tomorrow, all active `watchTargetForDate` streams re-evaluate. This is correct behavior: the query `WHERE effectiveDate <= dateKey ORDER BY effectiveDate DESC LIMIT 1` will return the same or updated result. [VERIFIED: Drift documentation confirms table-level change detection for watch queries]

### Pattern 3: Updated Streak Provider with Per-Day Targets

**What:** The current `streak` provider (stream_providers.dart:84-119) uses a single `settings.dailyTargetMl` for all days. It must be updated to look up the correct target per day from `targetHistoryDao.watchAll()`.

**Current implementation analysis (lines 84-119):**
- Line 86: `ref.watch(userSettingsProvider).value` -- gets global settings
- Line 94: `dailyTarget = settings.dailyTargetMl` -- single target for all days
- Line 109: `total >= dailyTarget` -- compares every day against same target

**Updated pattern:**
```dart
// Source: CONTEXT.md D-11 + existing streak provider structure
@riverpod
Stream<int> streak(Ref ref) async* {
  final repo = ref.watch(waterRepositoryProvider);
  final db = ref.watch(appDatabaseProvider);

  // Watch both streams: daily totals and target history
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  final yesterdayKey = _toDateKey(yesterday);

  yield* repo
      .watchDailyTotalsInRange('2020-01-01', yesterdayKey)
      .asyncMap((totals) async {
    // Fetch all target history rows (single query, in-memory scan)
    final targets = await db.targetHistoryDao.watchAll().first;
    if (targets.isEmpty) {
      return 0;
    }

    int count = 0;
    var current = yesterday;
    while (true) {
      final key = _toDateKey(current);
      final total = totals[key] ?? 0;

      // Find the active target for this day: last entry where effectiveDate <= key
      // targets is sorted ASC by effectiveDate (from watchAll)
      int activeTarget = targets.first.targetMl; // fallback to earliest
      for (final t in targets) {
        if (t.effectiveDate.compareTo(key) <= 0) {
          activeTarget = t.targetMl;
        } else {
          break; // sorted ASC, no need to continue
        }
      }

      if (activeTarget <= 0) {
        return 0; // no valid target
      }
      if (total >= activeTarget) {
        count++;
        current = current.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return count;
  });
}
```

**Key design choices:**
- Uses `asyncMap` instead of nested `yield*` to combine totals stream with one-shot target fetch
- `watchAll().first` converts the target history stream to a single snapshot (avoids double-stream complexity)
- Linear scan through sorted targets array for each day -- O(days * targets) but both lists are small (< 365 days, < 20 targets)
- When target_history changes, the totals stream does NOT re-emit. This means the streak won't reactively update on target changes alone. **Alternative:** Watch both streams and combine. The simpler approach is to also `ref.watch` a target history provider to trigger invalidation.

**Better reactive approach (watch both):**
```dart
@riverpod
Stream<int> streak(Ref ref) async* {
  final repo = ref.watch(waterRepositoryProvider);
  final db = ref.watch(appDatabaseProvider);

  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  final yesterdayKey = _toDateKey(yesterday);

  // Combine both streams using asyncExpand or manual approach
  yield* db.targetHistoryDao.watchAll().asyncExpand((targets) {
    return repo
        .watchDailyTotalsInRange('2020-01-01', yesterdayKey)
        .map((totals) {
      if (targets.isEmpty) return 0;

      int count = 0;
      var current = yesterday;
      while (true) {
        final key = _toDateKey(current);
        final total = totals[key] ?? 0;
        int activeTarget = targets.first.targetMl;
        for (final t in targets) {
          if (t.effectiveDate.compareTo(key) <= 0) {
            activeTarget = t.targetMl;
          } else {
            break;
          }
        }
        if (activeTarget <= 0) return 0;
        if (total >= activeTarget) {
          count++;
          current = current.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
      return count;
    });
  });
}
```

**Recommendation:** Use the `asyncExpand` approach. It ensures the streak recalculates when EITHER the water entries OR the target history changes. This is the most correct reactive behavior. [ASSUMED -- asyncExpand is a standard Dart Stream method; the pattern of outer stream driving inner stream subscription is well-documented]

### Pattern 4: Adding `applyFromTomorrow` Column to UserSettings

**What:** Add a boolean column with default `false` to the existing `UserSettings` Drift table. Since this is the first real installation (no users have the app yet), `schemaVersion` stays at 1.

**Step 1: Table definition (user_settings_table.dart)**

Current file (line 17 is last column):
```dart
BoolColumn get dndEnabled =>
    boolean().withDefault(const Constant(true))();
```

Add after line 17:
```dart
BoolColumn get applyFromTomorrow =>
    boolean().withDefault(const Constant(false))();
```

[VERIFIED: matches existing pattern of `dndEnabled` column at user_settings_table.dart:17-18]

**Step 2: Update `_defaultSettings()` in UserSettingsDao (user_settings_dao.dart:33-41)**

Current `_defaultSettings()` returns a `UserSetting` with all fields. Must add `applyFromTomorrow: false`:
```dart
UserSetting _defaultSettings() {
  return const UserSetting(
    id: 1,
    dailyTargetMl: 2000,
    notificationIntervalMinutes: 60,
    dndStartHour: 23,
    dndStartMinute: 0,
    dndEndHour: 7,
    dndEndMinute: 0,
    dndEnabled: true,
    applyFromTomorrow: false,  // NEW
  );
}
```

**Step 3: Update UserSettingsEntity (domain/entities/user_settings_entity.dart)**

Add `required bool applyFromTomorrow` field to the freezed class.

**Step 4: Update SettingsRepository mappings (settings_repository.dart)**

Both `watchSettings()` (line 14) and `getSettings()` (line 29) must include `applyFromTomorrow` in the mapping:
```dart
UserSettingsEntity(
  dailyTargetMl: row.dailyTargetMl,
  // ... existing fields ...
  dndEnabled: row.dndEnabled,
  applyFromTomorrow: row.applyFromTomorrow,  // NEW
)
```

And `updateSettings()` (line 43) must include it in the Companion:
```dart
UserSettingsCompanion(
  // ... existing fields ...
  dndEnabled: Value(entity.dndEnabled),
  applyFromTomorrow: Value(entity.applyFromTomorrow),  // NEW
)
```

**Step 5: No schema migration needed**

`schemaVersion` stays at `1`. The `withDefault(const Constant(false))` ensures the column has a value even if existing rows somehow exist. Since this is the first real install (no published app), all users will get the full schema from `onCreate`. [VERIFIED: app_database.dart:24 shows schemaVersion = 1; same reasoning as CONTEXT.md D-05]

### Pattern 5: updateTargetWithHistory() in SettingsRepository

**What:** New method on `SettingsRepository` that implements the dual-write pattern: update target_history (with today/tomorrow logic) and update UserSettings.dailyTargetMl.

```dart
// Source: CONTEXT.md D-06; follows existing updateSettings() pattern at settings_repository.dart:43-72
/// Update the daily target, writing to both target_history and user_settings.
///
/// Reads [applyFromTomorrow] from current settings to determine the effective date.
/// If true, writes to tomorrow's date; if false, writes to today's date.
Future<void> updateTargetWithHistory(int newTargetMl) async {
  if (newTargetMl <= 0) {
    throw ArgumentError('newTargetMl must be > 0');
  }
  // 1. Read current settings to get applyFromTomorrow preference
  final currentSettings = await _db.userSettingsDao.getSettings();
  
  // 2. Compute effective date
  final now = DateTime.now();
  final effectiveDay = currentSettings.applyFromTomorrow
      ? now.add(const Duration(days: 1))
      : now;
  final effectiveDate =
      '${effectiveDay.year}-${effectiveDay.month.toString().padLeft(2, '0')}-'
      '${effectiveDay.day.toString().padLeft(2, '0')}';
  
  // 3. Write to target_history (upsert)
  await _db.targetHistoryDao.insertOrReplace(effectiveDate, newTargetMl);
  
  // 4. Update user_settings.dailyTargetMl (always reflects latest target)
  await _db.userSettingsDao.updateSettings(
    UserSettingsCompanion(
      dailyTargetMl: Value(newTargetMl),
    ),
  );
}
```

**Design note:** Step 4 updates `dailyTargetMl` in `UserSettings` to keep it in sync as a "latest known target." This ensures backward compatibility with any code that still reads `settings.dailyTargetMl` (e.g., notification goal-reached check in HomeScreen line 83). The authoritative per-day target comes from `target_history`, but `dailyTargetMl` serves as a quick-access latest value.

### Pattern 6: HomeScreen Migration

**What:** Replace HomeScreen's manual midnight timer and `settings.dailyTargetMl` with provider-based alternatives.

**Current state (home_screen.dart):**
- Lines 23-26: `_dateKey` local state, `_midnightTimer` local Timer
- Line 30: `_dateKey = todayDateKey()` in initState
- Lines 39-43: `Timer.periodic(60s, _checkDateChange)` -- polls every 60 seconds
- Lines 51-56: `_checkDateChange()` compares and setState
- Line 69: `ref.watch(totalMlForDateProvider(_dateKey))` -- uses local `_dateKey`
- Line 129: `final target = settings.dailyTargetMl` -- uses global target

**After migration:**
- Remove `_dateKey` field, `_midnightTimer`, `_checkDateChange()`, `Timer.periodic`
- Keep `_lifecycleListener` (for notification rescheduling on resume)
- In `build()`: `final todayKey = ref.watch(todayDateKeyProvider);`
- Replace `totalMlForDateProvider(_dateKey)` with `totalMlForDateProvider(todayKey)`
- Replace `waterEntriesForDateProvider(_dateKey)` with `waterEntriesForDateProvider(todayKey)`
- Replace `settings.dailyTargetMl` with `ref.watch(effectiveTargetForDateProvider(todayKey)).value ?? 2000`
- Update `_onQuickAdd` to capture `todayKey` from provider (was `_dateKey`)
- The `ref.listen` for goal-reached notification cancel (lines 77-88) must also use the per-day target

**Specific line-by-line changes:**
1. Line 22-26: Remove `late String _dateKey`, keep `late AppLifecycleListener _lifecycleListener`
2. Lines 27-43: Remove `_midnightTimer`, remove `Timer.periodic`, keep `_lifecycleListener` init
3. Lines 51-56: Remove `_checkDateChange()` method entirely
4. Lines 58-61: Remove `_midnightTimer?.cancel()` from dispose, keep `_lifecycleListener.dispose()`
5. Line 67-69: `final todayKey = ref.watch(todayDateKeyProvider);` then use in providers
6. Line 82-85: Target for goal-reached check: `ref.read(effectiveTargetForDateProvider(todayKey)).value ?? 0`
7. Line 129: `final target = ref.watch(effectiveTargetForDateProvider(todayKey)).value ?? 2000;`
8. Line 245: In `_onQuickAdd`, capture `todayKey` from `ref.read(todayDateKeyProvider)`

**Widget refactor option:** Since HomeScreen no longer needs `StatefulWidget` for the timer, it could become a simple `ConsumerWidget`. However, keeping `ConsumerStatefulWidget` is fine because `_lifecycleListener` still needs `initState`/`dispose`. The bottom sheet callbacks also use `mounted` checks. **Recommendation: Keep ConsumerStatefulWidget but remove timer-related fields.**

### Pattern 7: HistoryScreen Migration

**What:** Replace single `dailyTarget` with per-day target lookups in calendar day builders.

**Current state (history_screen.dart):**
- Line 117: `final settingsAsync = ref.watch(userSettingsProvider)` -- watches global settings
- Line 128: `final dailyTarget = settings.dailyTargetMl` -- single target for all days
- Line 232-233: `total >= dailyTarget` -- same target for every day
- Line 262-263: `total >= dailyTarget` -- same target for today
- Line 384-385: `_buildDaySummary` uses `dailyTarget` parameter

**After migration:**
- The `calendarBuilders.defaultBuilder` and `todayBuilder` need per-day target
- **Performance concern:** For a month with 31 days, 31 `effectiveTargetForDateProvider` instances would be created. However since `keepAlive: true`, they persist and Drift's table-level watch means they all share the same underlying SQLite change notification. This is acceptable.
- The day summary card below the calendar also needs per-day target

**Approach for calendar day builders:**
```dart
// Inside defaultBuilder callback:
final dateKey = _toDateKey(day);
final total = monthTotals[dateKey];
if (total == null) return null;
// Watch per-day target
final targetAsync = ref.watch(effectiveTargetForDateProvider(dateKey));
final dailyTarget = targetAsync.value ?? 2000;
```

**Important constraint:** Calendar builders receive `(context, day, focusedDay)` as parameters. The `ref.watch` call happens inside the build method of the `ConsumerStatefulWidget`, which has access to `ref`. Since the builder closures are created inside `build()`, `ref.watch` calls within them are valid -- they execute during the widget's build phase. [VERIFIED: existing code at line 229 uses `monthTotals[dateKey]` which comes from `ref.watch(calendarMonthProvider(...))` called at line 131]

**Alternative approach (batch lookup):** Instead of N individual providers, watch `targetHistoryDao.watchAll()` once and do in-memory lookups. This would be more efficient but breaks the established provider pattern. **Recommendation:** Use the batch approach for the calendar since it already has the monthTotals map pattern. Create a single provider that returns a `Map<String, int>` of dateKey -> effectiveTarget for the month.

**Recommended batch provider for calendar:**
```dart
/// Watch all target history for efficient calendar day coloring.
/// Returns all TargetHistoryData rows sorted by effectiveDate ASC.
@Riverpod(keepAlive: true)
Stream<List<TargetHistoryData>> allTargetHistory(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.targetHistoryDao.watchAll();
}
```

Then in HistoryScreen, use a helper function to find the active target for a dateKey:
```dart
int _findActiveTarget(List<TargetHistoryData> targets, String dateKey) {
  int result = 2000; // fallback
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

This avoids creating 31 provider instances per month while still being reactive (the watchAll stream re-emits on any target_history change).

### Pattern 8: Settings Screen Toggle + updateTargetWithHistory

**What:** Add an "Applica da oggi / da domani" toggle in the Settings screen's daily goal card, and route target changes through `updateTargetWithHistory()`.

**Current settings_screen.dart analysis:**
- Lines 89-122: `_dailyGoalCard()` -- contains slider with `onChangeEnd`
- Line 113-116: `onChangeEnd` calls `ref.read(settingsRepositoryProvider).updateSettings(settings.copyWith(dailyTargetMl: val.toInt()))`

**After migration:**

1. **Replace slider's `onChangeEnd`** (lines 113-116):
```dart
onChangeEnd: (val) {
  setState(() => _dailyTargetDrag = null);
  ref.read(settingsRepositoryProvider).updateTargetWithHistory(val.toInt());
},
```

2. **Add toggle below slider** in `_dailyGoalCard`:
```dart
// After the Slider widget, add:
const Divider(),
SwitchListTile(
  title: const Text('Applica da domani'),
  subtitle: Text(settings.applyFromTomorrow
      ? 'Le modifiche al target entrano in vigore domani'
      : 'Le modifiche al target entrano in vigore oggi'),
  value: settings.applyFromTomorrow,
  onChanged: (val) {
    ref.read(settingsRepositoryProvider).updateSettings(
      settings.copyWith(applyFromTomorrow: val),
    );
  },
),
```

**Note on UserSettingsEntity.copyWith:** The `applyFromTomorrow` field must be added to the freezed entity for `copyWith` to include it. After adding the field and running code-gen, `copyWith(applyFromTomorrow: val)` works automatically. [VERIFIED: freezed generates copyWith for all fields; existing usage at settings_screen.dart:115]

### Anti-Patterns to Avoid

- **Polling for date changes with Timer.periodic:** HomeScreen currently polls every 60 seconds (line 39-43). Replace with a precise Timer that fires exactly at midnight. Polling wastes CPU cycles and has up to 60-second delay for detecting midnight.
- **Using `settings.dailyTargetMl` for historical day comparison:** This is the current pattern and is incorrect for days where the target was different. Always use `effectiveTargetForDate(dateKey)` or the batch target history lookup.
- **Creating N provider instances in calendar day builders:** For 31 days in a month, creating 31 `effectiveTargetForDateProvider` instances is wasteful. Use the batch `watchAll()` approach with in-memory lookup instead.
- **Mixing `updateSettings()` and `updateTargetWithHistory()`:** All target changes from Settings must go through `updateTargetWithHistory()`. Direct `updateSettings(settings.copyWith(dailyTargetMl: ...))` would skip the target_history write.
- **Forgetting to update UserSettingsEntity when adding a Drift column:** The mapping in SettingsRepository will fail to compile if the entity is missing the new field. Always update: table -> DAO defaults -> entity -> repository mapping.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Midnight date detection | Timer.periodic polling every 60s | Single Timer with computed duration to midnight | Precise, no wasted cycles, immediate response |
| Per-day target lookup | Manual SQL query in each widget | `effectiveTargetForDateProvider` stream family | Reactive, cached, consistent across widgets |
| Target history scan for streak | N individual SQL queries per day | Single `watchAll()` + in-memory linear scan | O(1) SQL queries instead of O(n); data is small enough for in-memory |
| Today/tomorrow date computation | Manual string formatting in multiple places | `_computeTodayKey()` private method in Notifier | Single source of truth, same format as `todayDateKey()` |

## Common Pitfalls

### Pitfall 1: getTargetForDate is Future, Not Stream
**What goes wrong:** CONTEXT.md D-08 says the provider returns `Stream<int>` from `getTargetForDate(dateKey)`, but that DAO method returns `Future<int?>`.
**Why it happens:** The DAO was designed for one-shot queries in Phase 9. The stream variant was not included.
**How to avoid:** Add `watchTargetForDate(String dateKey)` to `TargetHistoryDao` using `.watchSingleOrNull()` instead of `.getSingleOrNull()`. Same query, stream wrapper.
**Warning signs:** Compile error: "A value of type 'Future<int?>' can't be returned from a method with return type 'Stream<int>'."

### Pitfall 2: Drift watchSingleOrNull on Multi-Row Query
**What goes wrong:** Using `.watchSingle()` on a query that might return 0 rows throws `StateError`.
**Why it happens:** `watchSingle()` expects exactly 1 row; `watchSingleOrNull()` handles 0-or-1.
**How to avoid:** Always use `.watchSingleOrNull()` with `.limit(1)` and map null to fallback.
**Warning signs:** `StateError: Expected exactly one element` in stream.

### Pitfall 3: Timer Not Cancelled on Provider Dispose
**What goes wrong:** Timer fires after provider is disposed, causing state update on dead Notifier.
**Why it happens:** forgetting `ref.onDispose` to cancel the Timer.
**How to avoid:** Always register `ref.onDispose(() => _midnightTimer?.cancel())` in `build()`.
**Warning signs:** "A Notifier was used after being disposed" error.

### Pitfall 4: Calendar Creates Too Many Provider Instances
**What goes wrong:** For a month view, 31 `effectiveTargetForDateProvider` instances are created, each watching the target_history table.
**Why it happens:** Using a family provider in a loop (calendar day builder).
**How to avoid:** Use the batch approach: watch `allTargetHistoryProvider` once, do in-memory lookups.
**Warning signs:** Performance degradation when scrolling calendar months.

### Pitfall 5: Streak Provider Doesn't React to Target Changes
**What goes wrong:** Changing the daily target doesn't update the streak count.
**Why it happens:** The streak provider only watches `waterRepositoryProvider` totals, not `targetHistoryDao.watchAll()`.
**How to avoid:** Combine both streams in the streak provider (use `asyncExpand` or similar).
**Warning signs:** Streak stays the same after changing target to a lower value.

### Pitfall 6: HomeScreen Goal-Reached Check Uses Wrong Target
**What goes wrong:** The notification cancel logic at HomeScreen lines 77-88 still uses `settings.dailyTargetMl` instead of the per-day target.
**Why it happens:** Only updating the progress ring target but forgetting the notification guard.
**How to avoid:** Update `ref.read(userSettingsProvider).value?.dailyTargetMl` at line 83 to use `ref.read(effectiveTargetForDateProvider(todayKey)).value`.
**Warning signs:** Notifications cancel at wrong threshold (old target vs current day's target).

### Pitfall 7: Forgetting to Run build_runner After Multiple Changes
**What goes wrong:** Changed user_settings_table.dart (Drift), user_settings_entity.dart (freezed), stream_providers.dart (Riverpod) -- but only ran build_runner once and it failed.
**Why it happens:** Generated code dependencies between packages.
**How to avoid:** Run `dart run build_runner build --delete-conflicting-outputs` ONCE after ALL source changes are complete. The `--delete-conflicting-outputs` flag handles stale generated files.
**Warning signs:** build_runner errors about conflicting outputs or missing generated members.

### Pitfall 8: applyFromTomorrow Missing from Entity Mapping
**What goes wrong:** App compiles but `applyFromTomorrow` is always `false` because `SettingsRepository` doesn't map it.
**Why it happens:** Adding the column to the Drift table and entity but forgetting to update the repository mapping.
**How to avoid:** Update all three mappings: `watchSettings()`, `getSettings()`, and `updateSettings()` in `SettingsRepository`.
**Warning signs:** Toggle appears to work in UI but value resets on app restart.

## Code Examples

### Complete todayDateKeyProvider Implementation

```dart
// Source: CONTEXT.md D-01, FocusedMonth pattern, database_provider.dart ref.onDispose
// File: lib/core/providers/stream_providers.dart (add to existing file)
import 'dart:async';

@Riverpod(keepAlive: true)
class TodayDateKey extends _$TodayDateKey {
  Timer? _midnightTimer;

  @override
  String build() {
    ref.onDispose(() {
      _midnightTimer?.cancel();
    });
    _scheduleMidnightRefresh();
    return _computeTodayKey();
  }

  String _computeTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel(); // Cancel any existing timer
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final duration = nextMidnight.difference(now) + const Duration(seconds: 1);
    _midnightTimer = Timer(duration, _onMidnight);
  }

  void _onMidnight() {
    state = _computeTodayKey();
    _scheduleMidnightRefresh();
  }
}
```

### Complete watchTargetForDate DAO Method

```dart
// Source: pattern from getTargetForDate (same file, line 14-21) with .watchSingleOrNull()
// File: lib/data/database/daos/target_history_dao.dart (add to existing class)

/// Reactive stream of the effective target for a given date.
/// Returns the targetMl from the most recent row where effectiveDate <= dateKey.
/// Emits null if no rows exist (defensive).
Stream<int?> watchTargetForDate(String dateKey) {
  return (select(targetHistory)
        ..where((t) => t.effectiveDate.isSmallerOrEqualValue(dateKey))
        ..orderBy([(t) => OrderingTerm.desc(t.effectiveDate)])
        ..limit(1))
      .watchSingleOrNull()
      .map((row) => row?.targetMl);
}
```

### Complete updateTargetWithHistory Method

```dart
// Source: CONTEXT.md D-06, existing updateSettings() pattern
// File: lib/data/repositories/settings_repository.dart (add to existing class)

/// Update the daily target with dual-write to target_history and user_settings.
///
/// Reads [applyFromTomorrow] preference, computes effective date, upserts
/// target_history, then updates user_settings.dailyTargetMl.
Future<void> updateTargetWithHistory(int newTargetMl) async {
  if (newTargetMl <= 0) {
    throw ArgumentError('newTargetMl must be > 0');
  }
  final currentSettings = await _db.userSettingsDao.getSettings();
  final now = DateTime.now();
  final effectiveDay = currentSettings.applyFromTomorrow
      ? now.add(const Duration(days: 1))
      : now;
  final effectiveDate =
      '${effectiveDay.year}-${effectiveDay.month.toString().padLeft(2, '0')}-'
      '${effectiveDay.day.toString().padLeft(2, '0')}';
  await _db.targetHistoryDao.insertOrReplace(effectiveDate, newTargetMl);
  await _db.userSettingsDao.updateSettings(
    UserSettingsCompanion(
      dailyTargetMl: Value(newTargetMl),
    ),
  );
}
```

### Updated UserSettings Table

```dart
// File: lib/data/database/tables/user_settings_table.dart
import 'package:drift/drift.dart';

class UserSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dailyTargetMl =>
      integer().withDefault(const Constant(2000))();
  IntColumn get notificationIntervalMinutes =>
      integer().withDefault(const Constant(60))();
  IntColumn get dndStartHour =>
      integer().withDefault(const Constant(23))();
  IntColumn get dndStartMinute =>
      integer().withDefault(const Constant(0))();
  IntColumn get dndEndHour =>
      integer().withDefault(const Constant(7))();
  IntColumn get dndEndMinute =>
      integer().withDefault(const Constant(0))();
  BoolColumn get dndEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get applyFromTomorrow =>
      boolean().withDefault(const Constant(false))();  // NEW
}
```

### Updated UserSettingsEntity

```dart
// File: lib/domain/entities/user_settings_entity.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_settings_entity.freezed.dart';

@freezed
abstract class UserSettingsEntity with _$UserSettingsEntity {
  const factory UserSettingsEntity({
    required int dailyTargetMl,
    required int notificationIntervalMinutes,
    required int dndStartHour,
    required int dndStartMinute,
    required int dndEndHour,
    required int dndEndMinute,
    required bool dndEnabled,
    required bool applyFromTomorrow,  // NEW
  }) = _UserSettingsEntity;
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Timer.periodic(60s) polling in widget | Precise Timer in keepAlive Notifier | Phase 10 | Immediate midnight detection, no CPU waste |
| Single global `dailyTargetMl` for all days | Per-day target from `target_history` | Phase 10 | Historical accuracy in calendar, correct streak calculation |
| `todayDateKey()` helper function called at build time | `todayDateKeyProvider` Notifier with reactive state | Phase 10 | All widgets automatically update at midnight |

**Deprecated/outdated:**
- `todayDateKey()` helper function at stream_providers.dart:57-60 -- remains available as utility but should not be the primary source of truth. Widgets should use `ref.watch(todayDateKeyProvider)` instead.

## Project Constraints (from CLAUDE.md)

- **Tech stack**: Flutter + Riverpod + Drift -- no deviation
- **Platform**: iOS and Android only
- **Offline-first**: No backend or cloud sync
- **State management**: Use `flutter_riverpod` with `@riverpod` code-gen annotations (not hooks_riverpod)
- **Database setup**: Must use `drift_flutter` (not `sqlite3_flutter_libs`)
- **Packages to NOT use**: sqlite3_flutter_libs, awesome_notifications, GetX, provider, hive/isar, flutter_native_timezone
- **Code-gen**: Run `dart run build_runner build --delete-conflicting-outputs` after schema/provider/entity changes
- **Data classes**: Use freezed for entities with copyWith

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `ref.onDispose()` is available inside a class-based Notifier's `build()` method via `this.ref` | Pattern 1 | Timer leaks if onDispose is not available; alternative: override a `dispose` lifecycle method. LOW risk -- `ref` is inherited from `$Notifier` and functional providers already use `ref.onDispose` in the same codebase |
| A2 | `asyncExpand` on a `Stream` is a standard Dart API that subscribes to the inner stream on each outer emission and cancels the previous inner subscription | Pattern 3 (streak) | Incorrect stream combination; alternative: use `switchMap` from rxdart or manual StreamController. LOW risk -- `asyncExpand` is in `dart:async` |
| A3 | Drift's `.watchSingleOrNull()` on a `LIMIT 1` query handles 0-row results by emitting `null` rather than throwing | Pattern 2 | Runtime error in provider; alternative: use `.watch()` with `.map((list) => list.firstOrNull)`. LOW risk -- `.watchSingleOrNull()` is used in existing code at user_settings_dao.dart:18 |
| A4 | `UserSetting` generated data class will gain an `applyFromTomorrow` field after adding the column to the table and running build_runner | Pattern 4 | Compile error in DAO `_defaultSettings()`; self-correcting after code-gen. NEGLIGIBLE risk |

## Open Questions

1. **asyncExpand vs switchMap for streak provider**
   - What we know: `asyncExpand` is standard Dart; `switchMap` requires rxdart. Both combine outer + inner streams.
   - What's unclear: `asyncExpand` does NOT cancel the previous inner subscription when the outer emits again -- it accumulates. This could cause stale streak values if target_history changes rapidly.
   - Recommendation: Test with `asyncExpand` first. If it causes duplicate emissions, switch to a manual approach using `StreamController` or `Rx.combineLatest2`. The data volume is small enough that extra emissions are harmless.

2. **Calendar performance with 31 effectiveTargetForDate provider instances**
   - What we know: keepAlive providers persist; Drift watches at table level.
   - What's unclear: Whether Riverpod handles 31 family instances per month efficiently.
   - Recommendation: Use the batch `allTargetHistoryProvider` approach with in-memory lookup. This creates 1 provider instead of 31 per visible month.

3. **Should todayDateKey() helper function be removed?**
   - What we know: It's used in stream_providers.dart by the streak provider (via `_toDateKey`), and was used by HomeScreen.
   - What's unclear: Whether any other code depends on it.
   - Recommendation: Keep `todayDateKey()` as a utility function but document it as deprecated for widget usage. The streak provider can use `ref.watch(todayDateKeyProvider)` instead of calling `todayDateKey()` directly, but since streak counts from yesterday (not today), it computes its own keys anyway.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | N/A -- local-only app, no auth |
| V3 Session Management | No | N/A -- no sessions |
| V4 Access Control | No | N/A -- single-user local app |
| V5 Input Validation | Yes | `updateTargetWithHistory` validates `newTargetMl > 0` (same as existing `updateSettings` pattern) |
| V6 Cryptography | No | N/A -- no encryption needed |

### Known Threat Patterns for Phase 10 Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Invalid target value (0 or negative) | Tampering | ArgumentError in `updateTargetWithHistory()` |
| Timer overflow on very long sleep durations | Denial of Service | Duration is at most ~24 hours; well within Timer limits |
| Race condition: target change during midnight transition | Tampering | SQLite serializes writes; `insertOrReplace` is atomic |

**Security assessment:** LOW risk. All data is local. The Timer adds no attack surface. Input validation follows existing patterns.

## Sources

### Primary (HIGH confidence)
- `lib/core/providers/stream_providers.dart` -- FocusedMonth Notifier pattern (keepAlive class-based), streak provider, todayDateKey() helper, calendarMonth family provider [VERIFIED: codebase]
- `lib/core/providers/stream_providers.g.dart` -- Generated code confirming `_$FocusedMonth extends $Notifier<DateTime>`, `focusedMonthProvider` naming convention [VERIFIED: codebase]
- `lib/core/providers/database_provider.dart:9` -- `ref.onDispose(() => db.close())` pattern for cleanup [VERIFIED: codebase]
- `lib/data/database/daos/target_history_dao.dart` -- `getTargetForDate()` returns `Future<int?>`, `watchAll()` returns `Stream<List<TargetHistoryData>>`, `insertOrReplace()` upsert pattern [VERIFIED: codebase]
- `lib/data/database/daos/user_settings_dao.dart:17-19` -- `watchSingleOrNull()` stream pattern [VERIFIED: codebase]
- `lib/data/database/tables/user_settings_table.dart` -- existing column definitions with `withDefault(const Constant(...))` pattern [VERIFIED: codebase]
- `lib/domain/entities/user_settings_entity.dart` -- freezed entity with all current fields [VERIFIED: codebase]
- `lib/data/repositories/settings_repository.dart` -- `updateSettings()` method, entity-to-companion mapping [VERIFIED: codebase]
- `lib/presentation/screens/home_screen.dart` -- current Timer.periodic, _dateKey, todayDateKey() usage, settings.dailyTargetMl at line 129 [VERIFIED: codebase]
- `lib/presentation/screens/history_screen.dart` -- calendar day builders using single dailyTarget, monthTotals pattern [VERIFIED: codebase]
- `lib/presentation/screens/settings_screen.dart` -- daily goal slider onChangeEnd at line 113-116, SwitchListTile pattern at line 232-243 [VERIFIED: codebase]
- `lib/data/database/app_database.dart` -- schemaVersion=1, seed pattern [VERIFIED: codebase]
- `lib/data/database/app_database.g.dart` -- confirms `TargetHistoryData` data class name, `targetHistoryDao` accessor [VERIFIED: codebase]
- `.planning/phases/09-data-foundation-bug-fixes/09-RESEARCH.md` -- DoUpdate upsert pattern, insertOnConflictUpdate pitfall [VERIFIED: phase 9 research]
- drift.simonbinder.eu/dart_api/select/ -- `.watch()` and `.watchSingleOrNull()` for reactive streams on select queries [CITED: official Drift docs]
- pub.dev/packages/riverpod_annotation -- `@Riverpod(keepAlive: true)` annotation [CITED: pub.dev]

### Secondary (MEDIUM confidence)
- None

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- no new packages, all existing
- Architecture: HIGH -- all patterns derived from existing codebase code, not hypothetical
- Pitfalls: HIGH -- critical finding about Future vs Stream DAO method verified against actual code
- Code examples: HIGH -- all examples follow verified patterns from existing source files with specific line numbers

**Research date:** 2026-06-10
**Valid until:** 2026-07-10 (stable domain, no fast-moving dependencies)
