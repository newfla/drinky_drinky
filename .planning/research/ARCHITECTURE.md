# Architecture Research: Drinky Drinky v1.2

**Domain:** Bug fixes and feature depth for a Flutter hydration tracker
**Researched:** 2026-06-10
**Overall confidence:** HIGH (all recommendations derived from existing codebase patterns + verified Drift/GoRouter docs)

---

## Target History Integration

### New Table & DAO

**New Drift table: `TargetHistory`**

File: `lib/data/database/tables/target_history_table.dart`

```dart
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_target_history_effective_date', columns: {#effectiveDate})
class TargetHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get effectiveDate => text()(); // 'YYYY-MM-DD'
  IntColumn get targetMl => integer()();
}
```

**Rationale for TEXT over DateTime:** Matches the existing `dateKey` pattern in `WaterEntries`. String comparison (`<=`) works correctly for ISO-8601 date strings in SQLite, which is exactly how the query "MAX(effectiveDate) <= X" will work.

**New DAO: `TargetHistoryDao`** -- separate from `UserSettingsDao`

File: `lib/data/database/daos/target_history_dao.dart`

Why a separate DAO instead of adding methods to `UserSettingsDao`:
1. `UserSettingsDao` operates on the single-row `UserSettings` table. Target history is a multi-row append-only log -- different access patterns.
2. Keeps `UserSettingsDao` unchanged, reducing regression risk to settings functionality.
3. The `TargetHistory` table has no foreign key relationship to `UserSettings`.

DAO methods needed:

```dart
@DriftAccessor(tables: [TargetHistory])
class TargetHistoryDao extends DatabaseAccessor<AppDatabase>
    with _$TargetHistoryDaoMixin {
  TargetHistoryDao(super.attachedDatabase);

  /// Insert a new target history record.
  Future<int> insertTarget(TargetHistoryCompanion entry) =>
      into(targetHistory).insert(entry);

  /// Get the effective target for a given date.
  /// Returns the targetMl from the row with MAX(effectiveDate) <= dateKey.
  /// Returns null if no target history exists (fallback to UserSettings.dailyTargetMl).
  Future<int?> getTargetForDate(String dateKey) async {
    final query = select(targetHistory)
      ..where((t) => t.effectiveDate.isSmallerOrEqualValue(dateKey))
      ..orderBy([(t) => OrderingTerm.desc(t.effectiveDate)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row?.targetMl;
  }

  /// Watch the effective target for a given date (reactive).
  /// Used by HomeScreen for today's target.
  Stream<int?> watchTargetForDate(String dateKey) {
    final query = select(targetHistory)
      ..where((t) => t.effectiveDate.isSmallerOrEqualValue(dateKey))
      ..orderBy([(t) => OrderingTerm.desc(t.effectiveDate)])
      ..limit(1);
    return query.watchSingleOrNull().map((row) => row?.targetMl);
  }

  /// Get targets effective up to endDateKey (for calendar and streak).
  /// Returns all rows where effectiveDate <= endDateKey, ordered DESC.
  /// The caller walks backwards to resolve per-day targets.
  Future<List<TargetHistoryData>> getTargetsUpTo(String endDateKey) async {
    return (select(targetHistory)
          ..where((t) => t.effectiveDate.isSmallerOrEqualValue(endDateKey))
          ..orderBy([(t) => OrderingTerm.desc(t.effectiveDate)]))
        .get();
  }
}
```

**Database registration and migration:**

In `app_database.dart`:
- Add `TargetHistory` to the `tables` list
- Add `TargetHistoryDao` to the `daos` list
- Bump `schemaVersion` from `1` to `2`
- Add migration in `onUpgrade`:

```dart
@override
int get schemaVersion => 2;

@override
MigrationStrategy get migration {
  return MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      // ... existing seed logic ...
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createTable(targetHistory);
        // Seed initial target_history row from current UserSettings.dailyTargetMl
        final currentSettings = await (select(userSettings)
              ..where((t) => t.id.equals(1)))
            .getSingleOrNull();
        final currentTarget = currentSettings?.dailyTargetMl ?? 2000;
        final today = DateTime.now();
        final todayKey = '${today.year}-'
            '${today.month.toString().padLeft(2, '0')}-'
            '${today.day.toString().padLeft(2, '0')}';
        await into(targetHistory).insert(
          TargetHistoryCompanion.insert(
            effectiveDate: todayKey,
            targetMl: currentTarget,
          ),
        );
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
```

**Critical migration detail:** The seed step in `onUpgrade` copies the current `dailyTargetMl` from `UserSettings` into the first `target_history` row. This ensures existing users do not lose their target and the "get target for date" query works immediately for today. Without this seed, `getTargetForDate(today)` returns null for all existing users.

### Provider Graph Changes

**Current provider graph:**
```
appDatabaseProvider (keepAlive)
  -> waterRepositoryProvider (keepAlive)
       -> waterEntriesForDateProvider(dateKey)
       -> totalMlForDateProvider(dateKey)
       -> calendarMonthProvider(year, month)
       -> streakProvider
  -> settingsRepositoryProvider (keepAlive)
       -> userSettingsProvider (keepAlive, stream)
       -> drinkPresetsProvider (keepAlive, stream)
```

**New providers needed:**

File: `lib/core/providers/stream_providers.dart` (add to existing file)

```dart
/// Watch the effective target for a given dateKey.
/// Falls back to UserSettings.dailyTargetMl if no target_history row exists.
@riverpod
Stream<int> effectiveTargetForDate(Ref ref, String dateKey) async* {
  final repo = ref.watch(settingsRepositoryProvider);
  yield* repo.watchEffectiveTarget(dateKey);
}
```

**Key design decision: `UserSettings.dailyTargetMl` remains the source of truth for the "current" target.** When the user changes the target (via slider or calculator), it updates `UserSettings.dailyTargetMl` AND inserts a `target_history` row. This means:

1. `userSettingsProvider` continues to work unchanged for notifications, settings display, etc.
2. `effectiveTargetForDateProvider(dateKey)` is used only where historical accuracy matters (HomeScreen progress ring, calendar green/red).
3. The streak provider needs updating to use per-day targets.

**No breaking changes to existing providers.** `userSettingsProvider` keeps emitting. New consumers opt-in to the historical target via `effectiveTargetForDateProvider`.

**Provider changes needed:**

| Provider | Change | Reason |
|----------|--------|--------|
| `userSettingsProvider` | NONE | Still emits current settings; notifications still use it |
| `totalMlForDateProvider` | NONE | Still returns ml consumed; does not need target |
| `effectiveTargetForDateProvider` | NEW (family) | Resolves "what was the target on day X?" |
| `calendarMonthTargetsProvider` | NEW (family) | Returns Map<dateKey, targetMl> for an entire month |
| `streakProvider` | MODIFY | Must compare each day's total against that day's effective target, not the current global target |
| `calendarMonthProvider` | NONE (but consumer changes) | Still returns `Map<dateKey, totalMl>`; the target comparison happens in the widget |

**Streak provider modification (the most complex change):**

Currently `streakProvider` reads `settings.dailyTargetMl` once and compares all days against it. For v1.2, it must resolve the effective target per day.

Recommended approach: one-shot query in streak provider. The streak provider already fetches all daily totals from `2020-01-01` to yesterday. Add a parallel fetch of all `target_history` rows, then for each day in the backward walk, resolve the effective target via the sorted history list.

```dart
@riverpod
Stream<int> streak(Ref ref) async* {
  final waterRepo = ref.watch(waterRepositoryProvider);
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  final settings = ref.watch(userSettingsProvider).value;
  if (settings == null) { yield 0; return; }

  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  final yesterdayKey = _toDateKey(yesterday);

  // Fetch all target history rows (sorted DESC by effectiveDate)
  final targetHistory = await settingsRepo.getTargetHistory(yesterdayKey);

  yield* waterRepo
      .watchDailyTotalsInRange('2020-01-01', yesterdayKey)
      .map((totals) {
    int count = 0;
    var current = yesterday;
    while (true) {
      final key = _toDateKey(current);
      final total = totals[key] ?? 0;
      final target = _resolveTarget(key, targetHistory, settings.dailyTargetMl);
      if (target > 0 && total >= target) {
        count++;
        current = current.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return count;
  });
}

/// Pure function: find the effective target for [dateKey] from a DESC-sorted
/// list of target history records. Falls back to [fallback] if no record applies.
int _resolveTarget(String dateKey, List<TargetHistoryData> history, int fallback) {
  for (final record in history) {
    if (record.effectiveDate.compareTo(dateKey) <= 0) {
      return record.targetMl;
    }
  }
  return fallback;
}
```

### Consumer Updates (HomeScreen, CalendarScreen)

**HomeScreen changes:**

File: `lib/presentation/screens/home_screen.dart`

Current: `ref.watch(userSettingsProvider)` provides `settings.dailyTargetMl` for the progress ring.

Change: Add a watch on `effectiveTargetForDateProvider(_dateKey)` for the progress ring target. The settings provider is still watched for other settings (notification interval, DND, etc.).

```dart
// In build():
final settingsAsync = ref.watch(userSettingsProvider);
final effectiveTargetAsync = ref.watch(effectiveTargetForDateProvider(_dateKey));
// effectiveTargetAsync.value replaces settings.dailyTargetMl in:
//   - Progress ring percentage calculation
//   - Center text (X / Y L)
//   - Goal-reached notification cancel logic
```

The goal-reached notification cancel logic also needs to use the effective target:

```dart
ref.listen<AsyncValue<int>>(
  totalMlForDateProvider(_dateKey),
  (previous, next) {
    final prev = previous?.value ?? 0;
    final curr = next.value ?? 0;
    final target = ref.read(effectiveTargetForDateProvider(_dateKey)).value ?? 0;
    if (target > 0 && prev < target && curr >= target) {
      NotificationService.instance.cancelAll();
    }
  },
);
```

**CalendarScreen (HistoryScreen) changes:**

File: `lib/presentation/screens/history_screen.dart`

Current: `settings.dailyTargetMl` is used as a single int for all days in the calendar builders.

Change: Add a new family provider that returns per-day targets for a month:

```dart
/// Watch per-day targets for a calendar month.
/// Returns Map<dateKey, targetMl> where every day in the month has an entry.
@riverpod
Future<Map<String, int>> calendarMonthTargets(Ref ref, int year, int month) async {
  final repo = ref.watch(settingsRepositoryProvider);
  final firstDay = DateTime(year, month, 1);
  final lastDay = DateTime(year, month + 1, 0);
  final startKey = _toDateKey(firstDay);
  final endKey = _toDateKey(lastDay);
  return repo.getTargetsForRange(startKey, endKey);
}
```

In the widget, replace the single `dailyTarget` with per-day lookup:

```dart
// Watch per-month targets
final monthTargetsAsync = ref.watch(calendarMonthTargetsProvider(focused.year, focused.month));
final monthTargets = monthTargetsAsync.value ?? <String, int>{};

// In calendarBuilders, replace:
//   total >= dailyTarget
// with:
//   final dayTarget = monthTargets[dateKey] ?? settings.dailyTargetMl;
//   total >= dayTarget
```

Day summary card also uses per-day target:
```dart
final dayTarget = monthTargets[dateKey] ?? settings.dailyTargetMl;
'$dateLabel -- $total of $dayTarget ml'
```

### Repository Layer

File: `lib/data/repositories/settings_repository.dart`

Add methods to `SettingsRepository` (not a new repository -- keeps the dependency graph simple):

```dart
/// Insert a target history record. Called when user changes target.
Future<void> insertTargetHistory(String effectiveDate, int targetMl) =>
    _db.targetHistoryDao.insertTarget(
      TargetHistoryCompanion.insert(
        effectiveDate: effectiveDate,
        targetMl: targetMl,
      ),
    );

/// Watch effective target for a date (stream). Falls back to 2000ml default.
Stream<int> watchEffectiveTarget(String dateKey) {
  return _db.targetHistoryDao.watchTargetForDate(dateKey).map(
    (target) => target ?? 2000,
  );
}

/// Get target history for streak calculation (one-shot).
Future<List<TargetHistoryData>> getTargetHistory(String upToDateKey) =>
    _db.targetHistoryDao.getTargetsUpTo(upToDateKey);

/// Get per-day targets for a date range. Returns Map<dateKey, targetMl>.
Future<Map<String, int>> getTargetsForRange(String startKey, String endKey) async {
  final history = await _db.targetHistoryDao.getTargetsUpTo(endKey);
  final settings = await _db.userSettingsDao.getSettings();
  final fallback = settings.dailyTargetMl;

  final result = <String, int>{};
  var current = DateTime.parse(startKey);
  final end = DateTime.parse(endKey);

  while (!current.isAfter(end)) {
    final key = _toDateKey(current);
    // Find first history entry where effectiveDate <= key (list is DESC sorted)
    final effective = history
        .where((h) => h.effectiveDate.compareTo(key) <= 0)
        .firstOrNull;
    result[key] = effective?.targetMl ?? fallback;
    current = current.add(const Duration(days: 1));
  }
  return result;
}

/// Update the daily target and record it in target history.
/// Combines UserSettings update + target_history insert in one call.
Future<void> updateTargetWithHistory(
  UserSettingsEntity currentSettings,
  int newTargetMl,
  String effectiveDate,
) async {
  await updateSettings(currentSettings.copyWith(dailyTargetMl: newTargetMl));
  await insertTargetHistory(effectiveDate, newTargetMl);
}
```

A `_toDateKey` helper is needed in the repository (duplicate the 3-line function from stream_providers.dart, or extract to a shared utility).

### "Apply from today / tomorrow" (TARGET-02)

When the user changes the target in SettingsScreen:

1. `UserSettings.dailyTargetMl` is updated immediately (existing behavior).
2. A `target_history` row is inserted with `effectiveDate` = today (if "apply from today") or tomorrow (if "apply from tomorrow").
3. UI: Add a `SegmentedButton` or toggle underneath the daily goal slider in SettingsScreen. Default to "from today" since that matches the current behavior.

The "from tomorrow" case means the progress ring still shows today's old target, but tomorrow will use the new one. This is intuitive for end-of-day changes.

**SettingsScreen slider `onChangeEnd` must call `updateTargetWithHistory` instead of plain `updateSettings`** so every target change is recorded in history.

---

## HydrationCalculatorScreen

### Navigation Integration (GoRouter)

**Route: `/calculator` as a top-level route (outside StatefulShellRoute)**

File: `lib/core/router/app_router.dart`

Why top-level: The calculator should appear without the bottom NavigationBar during onboarding (first launch). When accessed from SettingsScreen, it can be pushed as a standard page transition. Top-level route handles both cases cleanly.

```dart
// Add to the routes list, alongside /permission:
GoRoute(
  path: '/calculator',
  builder: (context, state) => const HydrationCalculatorScreen(),
),
```

**First-launch redirect (CALC-02):**

Use the GoRouter redirect -- this is where the existing onboarding guard (`drinky_permissionScreenShown`) already lives. Adding the calculator check to the same location keeps all onboarding logic in one place.

The redirect flow is sequential and idempotent. On first launch:
1. User hits `/` -> redirect sends to `/permission`
2. User completes permission screen -> `context.go('/')` -> redirect checks permission (done), checks onboarding (not done) -> redirect sends to `/calculator`
3. User completes calculator -> `context.go('/')` -> both checks pass -> user lands on Home

```dart
redirect: (BuildContext context, GoRouterState state) async {
  if (state.matchedLocation == '/permission') return null;
  if (state.matchedLocation == '/calculator') return null;

  final prefs = await SharedPreferences.getInstance();
  final permShown = prefs.getBool('drinky_permissionScreenShown') ?? false;
  if (!permShown) return '/permission';

  final onboardingDone = prefs.getBool('drinky_onboardingComplete') ?? false;
  if (!onboardingDone) return '/calculator';

  return null;
},
```

**From SettingsScreen (CALC-03):**

Add a ListTile in `_buildBody` under the "DAILY GOAL" section:

```dart
ListTile(
  title: const Text('Hydration Calculator'),
  subtitle: const Text('Get a personalized recommendation'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () => context.push('/calculator'),
),
```

Note: `push` (not `go`) is correct for the settings path -- it preserves the back stack so the user returns to Settings.

### "Use as target" Flow (CALC-04)

When the user taps "Use as target" on the calculator:

1. Read the computed recommendation (an int, e.g., 2500).
2. Read current settings via `ref.read(userSettingsProvider).value`.
3. Call `ref.read(settingsRepositoryProvider).updateTargetWithHistory(currentSettings, recommended, todayKey)` -- updates both `UserSettings` and `target_history`.
4. Set `drinky_onboardingComplete = true` in SharedPreferences.
5. Navigate: If arrived via redirect (onboarding), use `context.go('/')`. If arrived via push (from settings), use `Navigator.pop(context)` or `context.pop()`.

To distinguish onboarding vs settings navigation: pass an `extra` parameter in the GoRouter state, or check whether the `drinky_onboardingComplete` flag was already set before navigating.

Simpler approach: always set the flag and always use `context.go('/')`. If the user came from settings, `go('/')` replaces the stack and lands on Home (acceptable because the user just changed their target, and seeing the Home progress ring with the new target is the right UX).

**"Skip" / dismiss behavior on the calculator:**

- During onboarding: set `drinky_onboardingComplete = true` and `context.go('/')`. The default target (2000ml) remains.
- From settings: just pop. No flag change needed (it was already true).

### Stateless Design (no persistence of calculator inputs)

The calculator screen is fully stateless from a persistence perspective:
- Sex, weight, and climate level are held in local widget state only.
- No database table for calculator inputs.
- No Riverpod provider for calculator state.
- The only side effect is "Use as target" which writes to `UserSettings` + `target_history`.
- The privacy disclaimer is a static text widget ("This calculation is performed locally on your device. No personal data is stored or transmitted.").

**Screen structure:**

File: `lib/presentation/screens/hydration_calculator_screen.dart`

```
HydrationCalculatorScreen (ConsumerStatefulWidget)
  - State: sex (enum Male/Female), weightKg (double), climateLevel (int 1-5)
  - Computed: recommendedMl (pure function of state)
  - UI: SegmentedButton for sex, Slider for weight (40-150kg),
         Slider for climate (1=temperate..5=very hot)
  - Display: "Recommended: X ml/day"
  - Buttons: "Use as target" (FilledButton), "Skip" (TextButton)
  - Static privacy disclaimer text
```

**Calculation function (pure, testable):**

File: `lib/domain/calculator.dart`

```dart
enum Sex { male, female }

int calculateRecommendedIntake(Sex sex, double weightKg, int climateLevel) {
  final basePerKg = sex == Sex.male ? 35.0 : 31.0;
  final base = (weightKg * basePerKg).round();
  // Climate: +0%/+5%/+10%/+15%/+20% for levels 1-5
  final climateMultiplier = 1.0 + (climateLevel - 1) * 0.05;
  final raw = (base * climateMultiplier).round();
  // Round to nearest 50ml for a clean number
  return ((raw + 25) ~/ 50) * 50;
}
```

Place as a top-level function, trivially unit-testable.

---

## Bug Fix Touch Points

### BUG-01: deleteLastEntry

**Status: Already fixed in the DAO.**

The current `WaterEntryDao.deleteLastEntry(String dateKey)` (lines 35-44 of `water_entry_dao.dart`) correctly scopes the subquery to the given dateKey:

```dart
final lastEntry = await (select(waterEntries)
      ..where((t) => t.dateKey.equals(dateKey))
      ..orderBy([(t) => OrderingTerm.desc(t.loggedAt)])
      ..limit(1))
    .getSingleOrNull();
if (lastEntry == null) return 0;
return (delete(waterEntries)..where((t) => t.id.equals(lastEntry.id))).go();
```

The DELETE uses the primary key (`WHERE id = lastEntry.id`) which is inherently safe. The dateKey filter is on the SELECT that finds which entry to delete.

**Action required:** Add a cross-date isolation test to prove the fix is effective. The existing test (`water_entry_dao_test.dart` line 59-81) tests same-date deletion but does not verify that entries from other dates are untouched.

**Files to touch:**
- `test/data/database/daos/water_entry_dao_test.dart` -- add cross-date test: insert entries on two dates, delete last entry for date A, verify date B entries are untouched.

### BUG-02: _todayDateKey() midnight refresh

**Status: Partially addressed.**

The current `HomeScreen` has both an `AppLifecycleListener.onResume` and a `Timer.periodic(60s)` calling `_checkDateChange()`. This covers the HomeScreen dateKey.

**Remaining gap:** When the date changes at midnight, `streakProvider` does not automatically re-evaluate because it does not depend on `_dateKey` (it uses `DateTime.now()` internally, but the provider only re-runs when a dependency changes).

**Fix:** In `_checkDateChange()`, after updating `_dateKey`, invalidate the streak provider:

```dart
void _checkDateChange() {
  final newKey = todayDateKey();
  if (newKey != _dateKey && mounted) {
    setState(() => _dateKey = newKey);
    ref.invalidate(streakProvider); // force streak recalculation
  }
}
```

**Files to touch:**
- `lib/presentation/screens/home_screen.dart` -- add `ref.invalidate(streakProvider)` in `_checkDateChange()`

### BUG-03: dateKey validation

**Status: Already implemented in WaterRepository.**

The current `WaterRepository.insertEntry` (lines 33-45 of `water_repository.dart`) has both regex validation AND semantic validation via `DateTime.tryParse()` + round-trip comparison. This correctly rejects `2024-02-30` because Dart rolls over invalid dates (`DateTime.tryParse('2024-02-30')` returns `2024-03-01`, and `'2024-03-01' != '2024-02-30'`).

**Action required:** Extract the validation into a shared utility so the new `insertTargetHistory` path also validates `effectiveDate`.

**Files to touch:**
- `lib/domain/date_key_validator.dart` -- NEW shared validation function
- `lib/data/repositories/water_repository.dart` -- replace inline validation with `validateDateKey(dateKey)` call
- `lib/data/repositories/settings_repository.dart` -- call `validateDateKey(effectiveDate)` in `insertTargetHistory`
- `test/domain/date_key_validator_test.dart` -- NEW unit tests (valid dates, Feb 29 leap/non-leap, month boundaries, roll-over dates like 2024-02-30, malformed strings)

---

## Build Order

Dependencies between components dictate this build order. Each step within a phase depends on the previous; phases can be built sequentially.

### Phase 1: Foundation (data layer, no UI changes)

1. **`date_key_validator.dart`** (BUG-03) -- new shared utility, no dependencies.
   - New: `lib/domain/date_key_validator.dart`
   - New: `test/domain/date_key_validator_test.dart`
   - Modify: `lib/data/repositories/water_repository.dart` (use shared validator)

2. **`target_history_table.dart`** -- new Drift table definition.
   - New: `lib/data/database/tables/target_history_table.dart`

3. **`target_history_dao.dart`** -- new DAO with query methods.
   - New: `lib/data/database/daos/target_history_dao.dart`

4. **`app_database.dart`** -- register table + DAO, bump schema to 2, add migration with seed.
   - Modify: `lib/data/database/app_database.dart`

5. **Run `dart run build_runner build`** -- generates `.g.dart` for new table/DAO.

6. **`settings_repository.dart`** -- add target history methods + `updateTargetWithHistory`.
   - Modify: `lib/data/repositories/settings_repository.dart`

7. **DAO + repository tests** -- test target_history_dao in isolation, test migration seed.
   - New: `test/data/database/daos/target_history_dao_test.dart`
   - Modify: `test/data/database/daos/water_entry_dao_test.dart` (add cross-date test for BUG-01)

### Phase 2: Provider layer + bug fixes

8. **`stream_providers.dart`** -- add `effectiveTargetForDateProvider`, `calendarMonthTargetsProvider`, modify `streakProvider`.
   - Modify: `lib/core/providers/stream_providers.dart`

9. **Run `dart run build_runner build`** -- regenerate provider `.g.dart` files.

10. **BUG-02 fix** -- add `ref.invalidate(streakProvider)` in `_checkDateChange`.
    - Modify: `lib/presentation/screens/home_screen.dart` (minimal, one-line addition)

### Phase 3: Calculator screen

11. **`calculator.dart`** -- pure calculation function.
    - New: `lib/domain/calculator.dart`
    - New: `test/domain/calculator_test.dart`

12. **`hydration_calculator_screen.dart`** -- new screen widget.
    - New: `lib/presentation/screens/hydration_calculator_screen.dart`

13. **`app_router.dart`** -- add `/calculator` route and onboarding redirect guard.
    - Modify: `lib/core/router/app_router.dart`

14. **Run `dart run build_runner build`** -- regenerate router `.g.dart` if needed.

### Phase 4: UI integration

15. **HomeScreen** -- use `effectiveTargetForDateProvider(_dateKey)` for progress ring and goal-reached logic.
    - Modify: `lib/presentation/screens/home_screen.dart`

16. **HistoryScreen** -- watch `calendarMonthTargetsProvider` for per-day green/red.
    - Modify: `lib/presentation/screens/history_screen.dart`

17. **SettingsScreen** -- update target slider to call `updateTargetWithHistory`, add today/tomorrow toggle, add calculator access tile.
    - Modify: `lib/presentation/screens/settings_screen.dart`

### Phase 5: Validation

18. **Migration integration test** -- verify schema v1 -> v2 upgrade with seed data.
19. **Manual testing** -- change target, check calendar shows correct green/red per day.
20. **Onboarding flow test** -- fresh install goes through permission -> calculator -> home.

---

## File-Level Change Map

| File | Change Type | Requirements |
|------|------------|-------------|
| `lib/domain/date_key_validator.dart` | NEW | BUG-03 |
| `lib/domain/calculator.dart` | NEW | CALC-01 |
| `lib/data/database/tables/target_history_table.dart` | NEW | TARGET-01 |
| `lib/data/database/daos/target_history_dao.dart` | NEW | TARGET-01 |
| `lib/data/database/app_database.dart` | MODIFY (schema v2, migration, table/DAO registration) | TARGET-01 |
| `lib/data/repositories/settings_repository.dart` | MODIFY (add target history methods, updateTargetWithHistory) | TARGET-01/02/03/04, CALC-04 |
| `lib/data/repositories/water_repository.dart` | MODIFY (use shared dateKey validator) | BUG-03 |
| `lib/core/providers/stream_providers.dart` | MODIFY (new providers, streak update) | TARGET-03/04 |
| `lib/core/router/app_router.dart` | MODIFY (add /calculator route, add onboarding redirect) | CALC-02/03 |
| `lib/presentation/screens/hydration_calculator_screen.dart` | NEW | CALC-01/02/03/04 |
| `lib/presentation/screens/home_screen.dart` | MODIFY (effective target, BUG-02 fix) | TARGET-03, BUG-02 |
| `lib/presentation/screens/history_screen.dart` | MODIFY (per-day targets in calendar) | TARGET-04 |
| `lib/presentation/screens/settings_screen.dart` | MODIFY (today/tomorrow toggle, calculator link, updateTargetWithHistory) | TARGET-02, CALC-03 |
| `test/domain/date_key_validator_test.dart` | NEW | BUG-03 |
| `test/domain/calculator_test.dart` | NEW | CALC-01 |
| `test/data/database/daos/target_history_dao_test.dart` | NEW | TARGET-01 |
| `test/data/database/daos/water_entry_dao_test.dart` | MODIFY (add cross-date test) | BUG-01 |

**Total: 10 modified files, 7 new files.**

---

## Sources

- Drift migration docs (Context7, `/websites/drift_simonbinder_eu`): `m.createTable()` for new tables in `onUpgrade`, `schemaVersion` bumping pattern -- HIGH confidence
- GoRouter changelog (Context7, `/websites/pub_dev_packages_go_router`): ShellRoute redirect support since 14.1.0, StatefulShellRoute redirect since 14.2.0 -- HIGH confidence
- Existing codebase: all file references and code patterns verified against actual source files in `lib/` and `test/` -- HIGH confidence
- Dart `DateTime.tryParse` rollover behavior: `DateTime.tryParse('2024-02-30')` returns `2024-03-01`, making round-trip comparison a valid semantic check -- HIGH confidence
