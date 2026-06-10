---
phase: 10-target-history-integration
reviewed: 2026-06-10T00:00:00Z
depth: deep
files_reviewed: 10
files_reviewed_list:
  - lib/data/database/tables/user_settings_table.dart
  - lib/data/database/daos/target_history_dao.dart
  - lib/data/database/daos/user_settings_dao.dart
  - lib/domain/entities/user_settings_entity.dart
  - lib/domain/entities/target_history_entry.dart
  - lib/data/repositories/settings_repository.dart
  - lib/core/providers/stream_providers.dart
  - lib/presentation/screens/home_screen.dart
  - lib/presentation/screens/history_screen.dart
  - lib/presentation/screens/settings_screen.dart
findings:
  critical: 4
  warning: 4
  info: 1
  total: 9
status: issues_found
---

# Phase 10: Code Review Report

**Reviewed:** 2026-06-10
**Depth:** deep
**Files Reviewed:** 10
**Status:** issues_found

## Summary

Phase 10 introduces per-day target history, wires it into the home/history screens,
and replaces a manual midnight polling loop with a timer-based `TodayDateKey` notifier.
The overall architecture is sound, but four correctness bugs were found that will
cause wrong behavior at runtime:

1. The database schema never migrates the existing `user_settings` table to add
   `apply_from_tomorrow`, so any user who already has the app installed will crash or
   see corrupted settings.
2. The streak loop has no upper-bound guard; it iterates backwards forever when
   a user's entire history matches the target, hanging the UI thread.
3. `updateTargetWithHistory` reads `applyFromTomorrow` from the DB but then
   unconditionally overwrites `dailyTargetMl` in `user_settings` — the effective date
   written to `target_history` and the date the home screen *actually* uses can
   disagree by a full day.
4. The midnight timer's `_onMidnight` callback mutates Riverpod state outside the
   provider's build cycle, which is safe today but will break if `TodayDateKey` is
   ever disposed and re-created while the timer is still in flight.

---

## Critical Issues

### CR-01: Missing schema migration for `apply_from_tomorrow` column — existing users crash

**File:** `lib/data/database/app_database.dart:36`
**Issue:** `schemaVersion` is still `1`. The `applyFromTomorrow` column added to
`UserSettings` is only created by `onCreate`, which only runs on a *fresh install*.
Any user who already has the app installed will open a database that lacks the
`apply_from_tomorrow` column. Every query touching that column — including
`watchSettings()` and `getSettings()` — will throw a `SqliteException: table
user_settings has no column named apply_from_tomorrow` at runtime, crashing the app
or producing silent data corruption depending on Drift's error handling path.

**Fix:** Increment `schemaVersion` to `2` and add an `onUpgrade` migration:

```dart
@override
int get schemaVersion => 2;

@override
MigrationStrategy get migration {
  return MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(userSettings, userSettings.applyFromTomorrow);
      }
    },
    onCreate: (Migrator m) async {
      // ... existing onCreate body unchanged ...
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
```

---

### CR-02: Infinite loop in streak provider when every historical day meets target

**File:** `lib/core/providers/stream_providers.dart:110`
**Issue:** The `while (true)` loop in `streak()` iterates backwards one day at a time
and only terminates via `break` when a day fails the goal check. When a user's entire
recorded history (from `2020-01-01` to yesterday) is goal-met, the loop never breaks.
`watchDailyTotalsInRange` only covers `'2020-01-01'` to `yesterdayKey`, so once the
loop walks past `2020-01-01`, `totals[key]` returns `null` → `0`, which is always
`< activeTarget`, so the `break` fires — *unless* `activeTarget` happens to be `0`.
Separately, the `activeTarget <= 0` guard on line 125 `return 0` causes the `.map`
lambda to **return from inside a closure that returns `int`**, which is a type error
at compile time (the surrounding `.map` callback returns `int`, not `void`).
The `return 0` will actually become the return value of the `.map` transform for that
single element, meaning the streak provider emits `0` whenever `activeTarget <= 0`
rather than propagating it correctly. More concretely, if the initial seed row has
`targetMl = 0` (even transiently), the streak is silently zeroed.

**Fix:** Add an explicit lower-bound guard so the loop terminates at the start of
the tracked range, and replace the `return 0` with a conditional `break`:

```dart
.map((totals) {
  int count = 0;
  var current = yesterday;
  final lowerBound = DateTime(2020, 1, 1);

  while (!current.isBefore(lowerBound)) {
    final key = _toDateKey(current);
    final total = totals[key] ?? 0;

    // Find the active target for this day
    int activeTarget = targets.first.targetMl;
    for (final t in targets) {
      if (t.effectiveDate.compareTo(key) <= 0) {
        activeTarget = t.targetMl;
      } else {
        break;
      }
    }

    if (activeTarget <= 0) break; // guard: malformed data, stop counting

    if (total >= activeTarget) {
      count++;
      current = current.subtract(const Duration(days: 1));
    } else {
      break;
    }
  }
  return count;
});
```

---

### CR-03: `updateTargetWithHistory` writes `dailyTargetMl` to `user_settings` immediately regardless of `applyFromTomorrow` flag

**File:** `lib/data/repositories/settings_repository.dart:96-98`
**Issue:** Line 98 always writes `dailyTargetMl: Value(newTargetMl)` to
`user_settings` regardless of whether `applyFromTomorrow` is `true`.

When `applyFromTomorrow = true`, the intent is that today's effective target stays at
the *old* value and the new value takes effect tomorrow. The code correctly inserts a
`target_history` row for tomorrow's date, but `user_settings.dailyTargetMl` is
immediately set to `newTargetMl`. Any code still using
`settings.dailyTargetMl` directly (notifications, future providers) will see the new
value today. More importantly, the home screen reads
`effectiveTargetForDateProvider(todayKey)`, which queries `target_history` — so the
home screen will be correct. But `user_settings.dailyTargetMl` is now out of sync
with the active target for today, which will confuse any consumer that reads settings
directly and will make the slider in `SettingsScreen` jump to the new value
immediately even though "apply from tomorrow" was selected. The semantic contract
(`applyFromTomorrow = true` → current day is unaffected) is broken at the
`user_settings` layer.

**Fix:** Only write `dailyTargetMl` to settings when the effective date is today:

```dart
Future<void> updateTargetWithHistory(int newTargetMl) async {
  if (newTargetMl <= 0) throw ArgumentError('newTargetMl must be > 0');
  final currentSettings = await _db.userSettingsDao.getSettings();
  final now = DateTime.now();
  final DateTime effectiveDateTime = currentSettings.applyFromTomorrow
      ? now.add(const Duration(days: 1))
      : now;
  final effectiveDate = '${effectiveDateTime.year.toString().padLeft(4, '0')}-'
      '${effectiveDateTime.month.toString().padLeft(2, '0')}-'
      '${effectiveDateTime.day.toString().padLeft(2, '0')}';
  await _db.targetHistoryDao.insertOrReplace(effectiveDate, newTargetMl);
  // Only advance the settings snapshot when the change takes effect today.
  if (!currentSettings.applyFromTomorrow) {
    await _db.userSettingsDao.updateSettings(
      UserSettingsCompanion(dailyTargetMl: Value(newTargetMl)),
    );
  }
}
```

---

### CR-04: `_toDateKey` in `stream_providers.dart` does not zero-pad the year

**File:** `lib/core/providers/stream_providers.dart:16`
**Issue:** `_toDateKey` pads month and day to two digits but does **not** pad the
year:

```dart
String _toDateKey(DateTime d) {
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
```

Dart's `DateTime.year` for years < 1000 will produce a string shorter than 4 digits
(e.g., year 999 → `"999-01-01"`), which is lexicographically smaller than the DB
seed value `"2020-01-01"`. This affects both `calendarMonth` (line 78-79) and the
`streak` provider (line 95-96). On the other hand, `settings_repository.dart` line
93-95 and `app_database.dart` line 58 **do** pad the year with `padLeft(4, '0')`.
This inconsistency means that if any date arithmetic ever produces a pre-year-1000
date (malformed or edge-case data), the format mismatch will produce wrong streak
counts or wrong calendar coloring silently. The format must be consistent across the
entire codebase.

**Fix:** Apply year padding in `_toDateKey`:

```dart
String _toDateKey(DateTime d) {
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
```

Apply the same fix to `_toDateKey` in `history_screen.dart` (line 12) and
`todayDateKey()` in `stream_providers.dart` (line 63), which have the same missing
year padding.

---

## Warnings

### WR-01: `TodayDateKey._onMidnight` updates Riverpod state after potential disposal

**File:** `lib/core/providers/stream_providers.dart:181`
**Issue:** `_onMidnight` is a plain method reference (`_midnightTimer = Timer(duration, _onMidnight)`).
If the provider is disposed between when the timer fires and when `_onMidnight`
executes, the `state = _computeTodayKey()` assignment will throw a
`StateError: Tried to use TodayDateKey after it was disposed`. The
`ref.onDispose(() => _midnightTimer?.cancel())` guard is correct, but `Timer.cancel`
and the callback fire on the same microtask queue — there is a narrow race window
where disposal runs and the timer callback was already queued. Because this provider
is `keepAlive: true`, disposal is unlikely in practice today, but the guard is
incomplete.

**Fix:** Add a mounted check inside the callback:

```dart
void _onMidnight() {
  // Guard: if the provider was disposed while the timer was in flight, do nothing.
  if (_midnightTimer == null) return; // cancelled == disposed
  state = _computeTodayKey();
  _scheduleMidnightRefresh();
}

@override
void dispose() {
  _midnightTimer?.cancel();
  _midnightTimer = null; // sentinel: prevents _onMidnight acting after dispose
  super.dispose(); // if generated code has a super.dispose()
}
```

---

### WR-02: Streak provider re-subscribes the inner water stream on every `watchAll()` emission

**File:** `lib/core/providers/stream_providers.dart:100`
**Issue:** `asyncExpand` creates a new subscription to
`watchDailyTotalsInRange('2020-01-01', yesterdayKey)` **every time** `watchAll()`
emits. If `target_history` changes (e.g., the user saves a new target), the inner
stream is cancelled and re-subscribed. This is correct behavior from `asyncExpand`'s
contract, but it means the outer stream emits the previous inner value, cancels it,
subscribes a new inner stream, then emits again — producing a momentary intermediate
value (the stale streak count from the prior subscription) visible to the UI. In
practice this manifests as the streak card flickering to the old value, then
updating, on every target save. `switchMap` semantics (cancel old, subscribe new) are
what is wanted here; Dart streams do not have a `switchMap` combinator in the stdlib,
but `rxdart`'s `switchMap` or a manual `StreamController` with explicit cancel logic
would eliminate the flicker.

**Fix (no new dependency):** Replace `asyncExpand` with a manual switch via
`StreamController`:

```dart
// In streak provider:
final controller = StreamController<int>();
StreamSubscription<int>? innerSub;
final outerSub = db.targetHistoryDao.watchAll().listen((targets) {
  innerSub?.cancel();
  if (targets.isEmpty) {
    controller.add(0);
    return;
  }
  innerSub = repo
      .watchDailyTotalsInRange('2020-01-01', yesterdayKey)
      .map((totals) { /* ... same logic ... */ })
      .listen(controller.add, onError: controller.addError);
});
ref.onDispose(() {
  outerSub.cancel();
  innerSub?.cancel();
  controller.close();
});
return controller.stream;
```

---

### WR-03: `_findActiveTarget` in `history_screen.dart` silently returns 2000 when `targets` is empty — but `allTargetHistoryProvider` can emit an empty list before seed resolves

**File:** `lib/presentation/screens/history_screen.dart:40-49`
**Issue:** `_findActiveTarget` returns the hardcoded fallback `2000` when the
`targets` list is empty. This is correct as a fallback, but the `HistoryScreen` only
reaches the `data:` branch of `targetsAsync.when` after `allTargetHistoryProvider`
has emitted. On first launch the seed insert in `onCreate` is synchronous within the
transaction, so the first emission should contain the seed row. However, if a
migration or data-clear removes all `target_history` rows (possible after CR-01 is
exploited), every historical day will be evaluated against the 2000 ml fallback,
silently miscategorizing history. There is no user-visible error; the calendar simply
shows incorrect green/red colouring. The fallback value 2000 should match the
constant used elsewhere — it does here, but it is a magic number duplicated in at
least four places (`stream_providers.dart:200`, `history_screen.dart:41`,
`streak` loop initial `targets.first.targetMl` fallback path).

**Fix:** Extract the fallback to a shared constant:

```dart
// In a shared constants file, e.g. lib/core/constants.dart:
const int kDefaultDailyTargetMl = 2000;
```

Replace all four hardcoded `2000` occurrences with `kDefaultDailyTargetMl`.

---

### WR-04: `applyFromTomorrow` toggle UI text is in Italian, inconsistent with the rest of the app

**File:** `lib/presentation/screens/settings_screen.dart:119-124`
**Issue:** The `SwitchListTile` for `applyFromTomorrow` uses Italian strings:
`'Applica da domani'` and `'Le modifiche al target entrano in vigore domani/oggi'`.
Every other string in the app is in English. This is a localisation inconsistency
that will confuse English-speaking users and indicates the strings were not yet
translated.

**Fix:** Replace with English equivalents:

```dart
title: const Text('Apply from tomorrow'),
subtitle: Text(
  settings.applyFromTomorrow
      ? 'Target changes take effect tomorrow'
      : 'Target changes take effect today',
),
```

---

## Info

### IN-01: `_toDateKey` is duplicated across three files

**File:** `lib/core/providers/stream_providers.dart:15`, `lib/presentation/screens/history_screen.dart:11`
**Issue:** The `_toDateKey` helper is defined twice as a private top-level function
(stream_providers.dart and history_screen.dart) and a third time inline in
`todayDateKey()` (stream_providers.dart:63) and in `settings_repository.dart:93-95`
and `app_database.dart:57-58`. Five separate implementations of the same
date-formatting logic. Any future fix (e.g., the year-padding issue in CR-04) must be
applied to all five independently.

**Fix:** Extract to a single shared utility, e.g.
`lib/core/utils/date_key.dart`:

```dart
/// Format a DateTime as a YYYY-MM-DD date key.
String toDateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
```

Import it everywhere and delete the local copies.

---

_Reviewed: 2026-06-10_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: deep_
