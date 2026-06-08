---
phase: 01-data-foundation
reviewed: 2026-06-03T00:00:00Z
depth: standard
files_reviewed: 25
files_reviewed_list:
  - build.yaml
  - lib/data/database/app_database.dart
  - lib/data/database/tables/water_entries_table.dart
  - lib/data/database/tables/user_settings_table.dart
  - lib/data/database/tables/drink_presets_table.dart
  - lib/data/database/daos/water_entry_dao.dart
  - lib/data/database/daos/user_settings_dao.dart
  - lib/data/database/daos/drink_preset_dao.dart
  - lib/domain/entities/water_entry_entity.dart
  - lib/domain/entities/daily_progress.dart
  - lib/domain/entities/user_settings_entity.dart
  - lib/domain/entities/drink_preset_entity.dart
  - lib/data/repositories/water_repository.dart
  - lib/data/repositories/settings_repository.dart
  - lib/core/providers/database_provider.dart
  - lib/core/providers/repository_providers.dart
  - lib/core/providers/stream_providers.dart
  - lib/core/router/app_router.dart
  - lib/presentation/screens/home_screen.dart
  - lib/presentation/screens/history_screen.dart
  - lib/presentation/screens/settings_screen.dart
  - lib/main.dart
  - pubspec.yaml
  - test/data/database/daos/water_entry_dao_test.dart
  - test/data/database/daos/user_settings_dao_test.dart
  - test/data/database/daos/drink_preset_dao_test.dart
findings:
  critical: 5
  warning: 7
  info: 4
  total: 16
status: issues_found
---

# Phase 01: Code Review Report

**Reviewed:** 2026-06-03T00:00:00Z
**Depth:** standard
**Files Reviewed:** 25
**Status:** issues_found

## Summary

This phase establishes the Drift database layer, domain entities, repository layer, Riverpod providers, and basic routing scaffold. The architecture is clean and the layering (table -> DAO -> repository -> provider) is correctly structured. However, there are five critical issues: the `deleteLastEntry` DAO method operates globally across all dates (not today), creating a cross-day data-loss bug; the `_todayDateKey()` helper is called at provider construction time meaning the date never updates after midnight; input validation is absent in `SettingsRepository.updateSettings` allowing impossible values to be persisted; `updatePreset` accepts zero or negative amounts with no guard; and the `dateKey` regex is syntactically valid but semantically invalid (allows month 99, day 00, etc.). Additionally, `riverpod_lint`/`custom_lint` were intentionally excluded from `pubspec.yaml` due to a version conflict — this is a build-time correctness gap that should be tracked. Seven warnings cover lesser logic holes, missing error handling on settings missing row, and test gaps. Four info items address code quality.

## Critical Issues

### CR-01: `deleteLastEntry` deletes across all dates — cross-day data loss

**File:** `lib/data/database/daos/water_entry_dao.dart:35-43`
**Issue:** `deleteLastEntry` finds the row with the highest `loggedAt` across the entire `water_entries` table, with no `dateKey` filter. If a user opens the app early in the morning after midnight without their device refreshing, the "undo" action will delete an entry from the previous calendar day, not today's last entry. At scale this is silent data loss — the deleted row is from the wrong day, the stream for today does not react, and there is no indication anything went wrong.

**Fix:**
```dart
Future<int> deleteLastEntry(String dateKey) async {
  final lastEntry = await (select(waterEntries)
        ..where((t) => t.dateKey.equals(dateKey))
        ..orderBy([(t) => OrderingTerm.desc(t.loggedAt)])
        ..limit(1))
      .getSingleOrNull();
  if (lastEntry == null) return 0;
  return (delete(waterEntries)..where((t) => t.id.equals(lastEntry.id))).go();
}
```
`WaterRepository.deleteLastEntry` must be updated to accept and pass `dateKey` from its call site.

---

### CR-02: `_todayDateKey()` is captured once at provider construction — stale date after midnight

**File:** `lib/core/providers/stream_providers.dart:38-41`
**Issue:** `_todayDateKey()` is a plain function called during the body of `todayWaterEntries` and `todayTotalMl` providers. Because these providers are `keepAlive: true`, they are constructed once at app start and never rebuilt. After midnight the date string computed at startup becomes stale: the streams still query the previous day's `dateKey` forever, so all entries logged after midnight appear in both the old day's live stream and never in the new day's stream.

**Fix:** Riverpod streams must re-subscribe when the date changes. Options in order of preference:

1. Remove `keepAlive: true` from `todayWaterEntries` and `todayTotalMl` (they should rebuild daily), and drive invalidation via a date-aware `AutoDisposeProvider` or by listening to a `DateChangeNotifier`.
2. Replace `_todayDateKey()` with a parameter so callers supply the date (turning the providers into family providers keyed by date string), and the UI always passes today's date recomputed from `DateTime.now()`.

```dart
// Option 2 sketch
@riverpod
Stream<List<WaterEntryEntity>> waterEntriesForDate(Ref ref, String dateKey) {
  return ref.watch(waterRepositoryProvider).watchEntriesForDate(dateKey);
}
```

The calling widget then passes `_todayDateKey()` computed at build time, which naturally refreshes on each rebuild.

---

### CR-03: `dateKey` validation regex accepts semantically invalid dates

**File:** `lib/data/repositories/water_repository.dart:32-35`
**Issue:** The regex `^\d{4}-\d{2}-\d{2}$` validates format only, not content. Callers can pass `'2026-00-00'`, `'2026-13-99'`, or `'9999-99-99'` and the validation passes silently. These strings are then stored in SQLite and become permanent noise in the `dateKey` index. Since `watchEntriesInRange` uses lexicographic comparisons on the dateKey column, corrupted date strings can cause incorrect range query results without any error being surfaced.

**Fix:** Parse the string with `DateTime.tryParse` after the regex check, and reject if null or if the round-trip does not match:
```dart
if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateKey)) {
  throw ArgumentError.value(dateKey, 'dateKey', 'Must match YYYY-MM-DD format');
}
final parsed = DateTime.tryParse(dateKey);
if (parsed == null ||
    '${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}' != dateKey) {
  throw ArgumentError.value(dateKey, 'dateKey', 'Not a valid calendar date');
}
```

---

### CR-04: `SettingsRepository.updateSettings` has no input validation — invalid settings are silently persisted

**File:** `lib/data/repositories/settings_repository.dart:41-54`
**Issue:** `updateSettings` blindly passes any `UserSettingsEntity` values to the database. Callers can persist:
- `dailyTargetMl: 0` or negative — dividing total by target for progress percentage will then produce NaN/Infinity or a divide-by-zero crash in the UI.
- `notificationIntervalMinutes: 0` — scheduling a notification every 0 minutes will spin an infinite loop or throw in `flutter_local_notifications`.
- `dndStartHour: 25` or `dndStartMinute: 61` — hour/minute values outside valid clock ranges, causing incorrect DND window logic.
- `dndStartHour == dndEndHour && dndStartMinute == dndEndMinute` — a zero-length DND window that notifications will never correctly skip.

**Fix:** Add a validation step before the database write:
```dart
Future<void> updateSettings(UserSettingsEntity entity) {
  if (entity.dailyTargetMl <= 0) {
    throw ArgumentError('dailyTargetMl must be > 0');
  }
  if (entity.notificationIntervalMinutes <= 0) {
    throw ArgumentError('notificationIntervalMinutes must be > 0');
  }
  if (entity.dndStartHour < 0 || entity.dndStartHour > 23 ||
      entity.dndEndHour < 0 || entity.dndEndHour > 23 ||
      entity.dndStartMinute < 0 || entity.dndStartMinute > 59 ||
      entity.dndEndMinute < 0 || entity.dndEndMinute > 59) {
    throw ArgumentError('DND hour/minute values out of valid range');
  }
  return _db.userSettingsDao.updateSettings( /* ... */ );
}
```

---

### CR-05: `DrinkPresetDao.updatePreset` accepts zero or negative `amountMl` — invalid preset silently stored

**File:** `lib/data/database/daos/drink_preset_dao.dart:20-23`
**Issue:** `updatePreset(int id, int amountMl)` applies no guard on `amountMl`. A preset with `amountMl <= 0` is meaningless (you cannot log 0 ml or -200 ml) and would appear as a tappable quick-add button in the UI. The `DrinkPresets` table has no `CHECK` constraint, so SQLite will store it without complaint. Parallel validation exists in `WaterRepository.insertEntry` (CR comment T-01-01) but was not applied here.

**Fix:** Guard at the DAO level (or at least at the `SettingsRepository.updatePreset` level):
```dart
Future<void> updatePreset(int id, int amountMl) {
  if (amountMl <= 0) {
    throw ArgumentError.value(amountMl, 'amountMl', 'Must be greater than 0');
  }
  return (update(drinkPresets)..where((t) => t.id.equals(id)))
      .write(DrinkPresetsCompanion(amountMl: Value(amountMl)));
}
```
A `CHECK (amount_ml > 0)` constraint on the table definition would provide a defense-in-depth backstop.

---

## Warnings

### WR-01: `UserSettingsDao.getSettings()` / `watchSettings()` throws `StateError` when settings row is absent

**File:** `lib/data/database/daos/user_settings_dao.dart:13-19`
**Issue:** Both `watchSettings()` and `getSettings()` use `watchSingle()`/`getSingle()`, which throws `StateError: "Expected exactly one element, but found 0"` when the settings row with `id=1` does not exist. The row is seeded in `onCreate`, but `onCreate` only runs once on first install. If the user manually clears app data, clears the SQLite file, or if a migration is applied incorrectly in a future version, the row might be absent and every `watchSettings()` subscription will throw an unhandled `StateError` that crashes the app.

**Fix:** Use `getSingleOrNull()` / `watchSingleOrNull()` and return (or emit) a sensible default, or re-insert the default row if missing:
```dart
Stream<UserSetting> watchSettings() {
  return (select(userSettings)..where((t) => t.id.equals(1)))
      .watchSingleOrNull()
      .map((row) => row ?? _defaultSettings());
}
```

---

### WR-02: `watchEntriesInRange` has no ordering — result order is non-deterministic

**File:** `lib/data/database/daos/water_entry_dao.dart:46-53`
**Issue:** Unlike `watchEntriesForDate`, the range query has no `orderBy` clause. SQLite returns rows in an unspecified order (often insertion order, but this is not guaranteed after deletions or vacuum). Any UI component iterating the list to build a calendar or chart will produce inconsistent rendering across platforms or after database maintenance.

**Fix:**
```dart
Stream<List<WaterEntry>> watchEntriesInRange(
    String startDateKey, String endDateKey) {
  return (select(waterEntries)
        ..where((t) =>
            t.dateKey.isBiggerOrEqualValue(startDateKey) &
            t.dateKey.isSmallerOrEqualValue(endDateKey))
        ..orderBy([
          (t) => OrderingTerm.asc(t.dateKey),
          (t) => OrderingTerm.asc(t.loggedAt),
        ]))
      .watch();
}
```

---

### WR-03: `DailyProgress` entity is defined but never used anywhere in the reviewed codebase

**File:** `lib/domain/entities/daily_progress.dart:1-14`
**Issue:** `DailyProgress` is a Freezed entity that aggregates `totalMl`, `targetMl`, `entries`, and `dateKey`. None of the reviewed providers, repositories, or screens reference it. Instead, `todayTotalMl` and `todayWaterEntries` are separate streams that consumers must combine manually. The entity exists but is a dead abstraction — either it should be used (combining both streams into one) or it should be deleted to avoid confusion about which pattern to follow.

**Fix:** Either expose a combined `Stream<DailyProgress> watchDailyProgress(String dateKey)` method from `WaterRepository` that uses `Rx.combineLatest2` (with `rxdart`) or `StreamZip`, and delete the separate `todayTotalMl` / `todayWaterEntries` stream providers; or delete `DailyProgress` and rely on separate streams.

---

### WR-04: `riverpod_lint` / `custom_lint` intentionally excluded — static analysis gap

**File:** `pubspec.yaml:41-43`
**Issue:** The comment explicitly acknowledges that `riverpod_lint` and `custom_lint` were excluded due to an `analyzer` version conflict between `drift_dev` (needs `>=10.0.0`) and `custom_lint` (needs `^8.0.0`). This means no Riverpod-specific lint rules are active. Common Riverpod mistakes — missing `ProviderScope`, `ref.read` inside a `build` method, accessing `ref` after `dispose` — will not be caught at analysis time. This degrades the safety net for the entire app's state management layer.

**Fix:** Track this as a known debt item. When `custom_lint` releases a version compatible with `analyzer >=10.0.0`, re-add both packages. In the meantime, add a comment to `analysis_options.yaml` documenting which Riverpod rules are missing so reviewers are aware.

---

### WR-05: `appRouter` is a global mutable variable — incompatible with testing and state isolation

**File:** `lib/core/router/app_router.dart:6`
**Issue:** `appRouter` is a module-level `final` variable, not a Riverpod provider. This means tests and widget tests cannot substitute a different router, there is no disposal path for `GoRouter`, and a future need to pass provider-derived state (e.g., auth status) into the router will require a larger refactor. `GoRouter` also holds its own `ChangeNotifier` lifecycle that is never disposed.

**Fix:** Wrap in a keepAlive Riverpod provider so it participates in the provider container lifecycle:
```dart
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [ /* ... */ ],
  );
  ref.onDispose(router.dispose);
  return router;
}
```
Then read it in `DrinkyDrinkyApp` via `ref.watch(appRouterProvider)`.

---

### WR-06: `path_provider` imported in `app_database.dart` but only used in `_openConnection` — import leaks into generated code scope

**File:** `lib/data/database/app_database.dart:3`
**Issue:** `import 'package:path_provider/path_provider.dart'` is present, but `driftDatabase()` from `drift_flutter` already encapsulates `path_provider` calls internally via the `DriftNativeOptions.databaseDirectory` callback. If `drift_flutter` internals change or if the generated `app_database.g.dart` includes its own import, there is a latent risk of import shadowing. More concretely, the `getApplicationSupportDirectory` function reference passed as a callback is a `Future<Directory> Function()` — this is correct usage, but if `drift_flutter` ever changes the expected signature, the compile error will be non-obvious because the import is indirect.

This is minor, but the import is effectively duplicated: `drift_flutter` already re-exports what is needed. Verify that removing this explicit `path_provider` import does not break the build after the next `build_runner` run.

---

### WR-07: No validation that `updatePreset` targets an existing `id` — silent no-op on unknown id

**File:** `lib/data/database/daos/drink_preset_dao.dart:20-23`
**Issue:** `update(drinkPresets).where(t.id.equals(id)).write(...)` returns the count of affected rows, but the return type is `Future<void>` so the count is discarded. If a caller passes a non-existent `id`, the update silently does nothing and the caller believes the preset was updated. This is particularly risky if the UI obtains preset IDs from a stale snapshot.

**Fix:** Return `Future<int>` (count of rows affected) and let the caller decide how to handle a 0 result:
```dart
Future<int> updatePreset(int id, int amountMl) {
  if (amountMl <= 0) throw ArgumentError.value(amountMl, 'amountMl', 'Must be > 0');
  return (update(drinkPresets)..where((t) => t.id.equals(id)))
      .write(DrinkPresetsCompanion(amountMl: Value(amountMl)));
}
```

---

## Info

### IN-01: `deleteLastEntry` returns `int` but `WaterRepository.deleteLastEntry` returns `Future<int>` — semantic meaning not surfaced to callers

**File:** `lib/data/repositories/water_repository.dart:46`
**Issue:** The repository exposes the raw row-count return from the DAO. Callers could check `== 0` to know there was nothing to undo, but this is not documented and the Riverpod provider layer has no handling for it. A dedicated return type or a `bool` would make intent clearer.

---

### IN-02: `DailyProgress.entries` field holds `List<WaterEntryEntity>` inside a Freezed class — deep equality on large lists may be surprising

**File:** `lib/domain/entities/daily_progress.dart:11`
**Issue:** Freezed's generated `==` and `hashCode` use `DeepCollectionEquality` for `List` fields. For a list of many `WaterEntryEntity` items, every comparison walks the entire list. In a hot rebuild path this is acceptable for small lists (typical daily entries), but it should be noted that the Freezed-generated equality is O(n) in the number of entries. No action needed unless profiling shows a problem, but be aware.

---

### IN-03: `amountMl` upper bound is unbounded — no maximum validation in `WaterRepository.insertEntry`

**File:** `lib/data/repositories/water_repository.dart:27-30`
**Issue:** Only `amountMl <= 0` is checked. A value like `2_000_000` (2,000,000 ml = 2,000 litres) would be accepted and stored without error. The progress percentage would instantly overflow to orders of magnitude beyond 100%, and any UI displaying a percentage would render incorrectly. A reasonable upper bound (e.g., `5000` ml per single entry, roughly a large water bottle) should be enforced.

---

### IN-04: Missing test coverage for key edge cases

**File:** `test/data/database/daos/water_entry_dao_test.dart`, `test/data/database/daos/user_settings_dao_test.dart`, `test/data/database/daos/drink_preset_dao_test.dart`
**Issue:** The following scenarios have no test:
- `deleteLastEntry` when the table is empty (the `return 0` path is never exercised by the tests).
- `watchTotalForDate` when there are no entries for the queried date (the `?? 0` null-coalescing in the DAO should return 0 — verify this with an explicit test).
- `updateSettings` where the settings row does not exist (currently cannot be constructed in tests without deleting the seeded row, but worth documenting).
- `updatePreset` with an `id` that does not exist (the silent no-op path, see WR-07).
- `watchEntriesInRange` boundary conditions: dates exactly equal to `startDateKey` and `endDateKey` are included (currently only tested for entries strictly inside the range, not the inclusive boundaries themselves).

---

_Reviewed: 2026-06-03T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
