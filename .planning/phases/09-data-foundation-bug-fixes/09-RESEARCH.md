# Phase 9: Data Foundation & Bug Fixes - Research

**Researched:** 2026-06-10
**Domain:** Drift schema extension (new table + DAO), confirmation testing for existing bug fixes
**Confidence:** HIGH

## Summary

Phase 9 adds a `TargetHistory` table to the existing Drift initial schema, delivers a complete `TargetHistoryDao` with three methods (read, watch, upsert), seeds a default row on first launch, and adds confirmation tests for two already-implemented bug fixes (BUG-01, BUG-03). No new packages are needed -- all work uses the existing Drift + Flutter test infrastructure.

The most important technical finding is that `insertOnConflictUpdate()` will NOT work for the `target_history` upsert because it only detects PRIMARY KEY conflicts, and our table has an auto-increment `id` primary key with a separate UNIQUE constraint on `effectiveDate`. The DAO must use `insert(..., onConflict: DoUpdate(..., target: [targetHistory.effectiveDate]))` instead. This is confirmed by the official Drift documentation.

**Primary recommendation:** Follow the exact table/DAO/registration pattern established by the existing `DrinkPresets`/`DrinkPresetDao`, use `text().unique()` for the `effectiveDate` column (simplest syntax for a single-column constraint), and use `DoUpdate` with explicit `target` for the upsert method.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** BUG-01 is already implemented -- Phase 9 only adds confirmation tests
- **D-02:** BUG-03 is already implemented -- Phase 9 only adds confirmation tests
- **D-03:** Add confirmation tests for both bugs using in-memory Drift (same pattern as existing 11 DAO tests)
- **D-04:** `TargetHistory` table added to initial schema; `schemaVersion` stays at 1; no migration
- **D-05:** Seed initial row in `onCreate`: effectiveDate = today (YYYY-MM-DD), targetMl = 2000
- **D-06:** UNIQUE constraint on `effectiveDate`; upsert via `insertOnConflictUpdate` for same-day changes
- **D-07:** Complete DAO with `getTargetForDate(String)`, `watchAll()`, `insertOrReplace(String, int)`
- **D-08:** Repository-level `updateTargetWithHistory()` belongs in Phase 10, not Phase 9

### Claude's Discretion
- Choice between `text().unique()` vs `uniqueKeys` override for the UNIQUE constraint
- Exact internal implementation of DAO methods (query builder style)
- Test file organization (new file vs appending to existing)

### Deferred Ideas (OUT OF SCOPE)
- `updateTargetWithHistory()` repository method -- Phase 10
- Provider wiring (`effectiveTargetForDateProvider`) -- Phase 10
- UI integration -- Phase 10
- `TargetHistoryRepository` wrapper class -- Phase 10 decides
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BUG-01 | `deleteLastEntry` adds WHERE dateKey filter to prevent cross-day deletion | Already implemented at `water_entry_dao.dart:35-44`; confirmation test pattern verified from existing test file |
| BUG-03 | `dateKey` validates format (regex) and semantics (DateTime.tryParse + round-trip) | Already implemented at `water_repository.dart:34-47`; test needs to call `insertEntry` with invalid dateKeys and expect `ArgumentError` |
| TARGET-01 | New `target_history` table in initial Drift schema with seed row on first launch | Full Drift table/DAO/registration pattern documented below; seed in `onCreate`; UNIQUE constraint + upsert API verified |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| target_history table definition | Database / Storage | -- | Pure schema definition |
| TargetHistoryDao (read/write/watch) | Database / Storage | -- | Data access layer, no business logic |
| Seed row on first launch | Database / Storage | -- | Drift `onCreate` callback |
| BUG-01 confirmation test | Database / Storage | -- | Tests DAO behavior directly |
| BUG-03 confirmation test | API / Backend (Repository) | -- | Tests repository-level validation |

## Standard Stack

### Core (already installed -- no changes)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| drift | ^2.33.0 | Type-safe SQLite ORM | Already in pubspec.yaml; provides table definitions, query builders, code-gen |
| drift_dev | ^2.33.0 | Code generator for Drift | Already in pubspec.yaml (dev dependency); regenerates `.g.dart` files |
| build_runner | ^2.15.0 | Code generation orchestrator | Already in pubspec.yaml (dev dependency); runs `dart run build_runner build` |
| flutter_test | SDK | Testing framework | Already in pubspec.yaml (dev dependency); provides `test()`, `setUp()`, `tearDown()` |

**No new packages needed.** Phase 9 uses only existing dependencies. [VERIFIED: pubspec.yaml]

## Architecture Patterns

### System Architecture Diagram

```
                          Phase 9 Scope
                          =============

  +---------+     +-------------------+     +------------------+
  | onCreate |---->| m.createAll()     |---->| All tables       |
  | (Drift)  |     |                   |     | (incl. new       |
  |          |     | Seed settings     |     |  target_history) |
  |          |     | Seed presets      |     +------------------+
  |          |     | Seed target_hist  |
  +---------+     +-------------------+

  +-----------------+     +--------------------+     +-----------+
  | TargetHistoryDao|---->| target_history     |---->| SQLite    |
  |                 |     | table              |     |           |
  | getTargetFor    |     | (id, effectiveDate,|     |           |
  |   Date(dateKey) |     |  targetMl)         |     |           |
  | watchAll()      |     |                    |     |           |
  | insertOrReplace |     | UNIQUE on          |     |           |
  |   (date, ml)    |     |   effectiveDate    |     |           |
  +-----------------+     +--------------------+     +-----------+

  +------------------+     +-----+
  | Confirmation     |---->| In- |
  | Tests            |     |memory|
  | BUG-01: cross-day|     | DB  |
  | BUG-03: invalid  |     |     |
  |   dateKey        |     +-----+
  +------------------+
```

### Recommended Project Structure

```
lib/data/database/
  tables/
    target_history_table.dart     # NEW: table definition
  daos/
    target_history_dao.dart       # NEW: DAO with 3 methods
    target_history_dao.g.dart     # GENERATED: DAO mixin
  app_database.dart               # MODIFIED: register table + DAO + seed
  app_database.g.dart             # REGENERATED: by build_runner

test/data/database/daos/
  target_history_dao_test.dart    # NEW: DAO tests
  water_entry_dao_test.dart       # MODIFIED: add BUG-01 confirmation test
test/data/repositories/
  water_repository_test.dart      # NEW: BUG-03 confirmation test
```

### Pattern 1: Table Definition with UNIQUE Column

**What:** Define a Drift table with a single-column UNIQUE constraint using the simpler `.unique()` column method (not `uniqueKeys` override, which is for multi-column constraints). [CITED: drift.simonbinder.eu/docs/getting-started/advanced_dart_tables/]

**When to use:** Single-column uniqueness, which is our case (`effectiveDate`).

**Example:**
```dart
// Source: verified against drift.simonbinder.eu/docs/getting-started/advanced_dart_tables/
// Pattern follows existing water_entries_table.dart and drink_presets_table.dart
import 'package:drift/drift.dart';

class TargetHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get effectiveDate => text().unique()();  // YYYY-MM-DD, UNIQUE constraint
  IntColumn get targetMl => integer()();
}
```

**Why `text().unique()` instead of `uniqueKeys` override:**
- `uniqueKeys` returns `List<Set<Column>>` -- designed for multi-column constraints [CITED: drift.simonbinder.eu/docs/getting-started/advanced_dart_tables/]
- `text().unique()` is the standard Drift pattern for single-column UNIQUE constraints [CITED: drift.simonbinder.eu/docs/getting-started/advanced_dart_tables/]
- Both produce the same SQL UNIQUE constraint; `.unique()` is simpler

**Generated naming convention (from existing codebase patterns):**
- Table class: `TargetHistory` -> generated `$TargetHistoryTable`
- Data class: `TargetHistoryData` (Drift auto-names)
- Companion: `TargetHistoryCompanion`
- Table accessor on DB: `targetHistory` (camelCase of class name)

### Pattern 2: DAO Registration

**What:** Define a `@DriftAccessor` DAO and register it alongside the table in `@DriftDatabase`. [VERIFIED: existing codebase pattern in water_entry_dao.dart, app_database.dart]

**Example:**
```dart
// target_history_dao.dart — follows exact pattern of drink_preset_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/target_history_table.dart';

part 'target_history_dao.g.dart';

@DriftAccessor(tables: [TargetHistory])
class TargetHistoryDao extends DatabaseAccessor<AppDatabase>
    with _$TargetHistoryDaoMixin {
  TargetHistoryDao(super.attachedDatabase);

  // Methods go here (see Pattern 3, 4, 5)
}
```

**Registration in app_database.dart:**
```dart
// Add import
import 'tables/target_history_table.dart';
import 'daos/target_history_dao.dart';

@DriftDatabase(
  tables: [WaterEntries, UserSettings, DrinkPresets, TargetHistory],  // ADD
  daos: [WaterEntryDao, UserSettingsDao, DrinkPresetDao, TargetHistoryDao],  // ADD
)
class AppDatabase extends _$AppDatabase {
  // ...
}
```

**After registration, run code-gen:**
```bash
dart run build_runner build --delete-conflicting-outputs
```

**What gets regenerated:** [VERIFIED: existing codebase]
- `app_database.g.dart` -- adds `$TargetHistoryTable`, `TargetHistoryData`, `TargetHistoryCompanion`, `_$TargetHistoryDaoMixin`, and the `targetHistory` accessor on `_$AppDatabase`
- `target_history_dao.g.dart` -- new file with `_$TargetHistoryDaoMixin`

### Pattern 3: getTargetForDate Query (WHERE <= ORDER BY DESC LIMIT 1)

**What:** Find the most recent target on or before a given date. Returns `null` if no rows exist. [VERIFIED: query pattern from existing DAO methods in water_entry_dao.dart]

**Drift Dart syntax:**
```dart
/// Returns the targetMl for the most recent row where effectiveDate <= dateKey.
/// Returns null if no rows exist (defensive — should not happen after onCreate seed).
Future<int?> getTargetForDate(String dateKey) async {
  final row = await (select(targetHistory)
        ..where((t) => t.effectiveDate.isSmallerOrEqualValue(dateKey))
        ..orderBy([(t) => OrderingTerm.desc(t.effectiveDate)])
        ..limit(1))
      .getSingleOrNull();
  return row?.targetMl;
}
```

**Key API details:** [VERIFIED: existing codebase usage in water_entry_dao.dart]
- `isSmallerOrEqualValue(String)` -- Drift column extension for `<=` comparison on text columns. Already used in `WaterEntryDao.watchEntriesInRange()` at line 53.
- `OrderingTerm.desc(column)` -- descending sort. Already used in `WaterEntryDao.deleteLastEntry()` at line 38.
- `getSingleOrNull()` -- returns `Future<TargetHistoryData?>`. Already used in `WaterEntryDao.deleteLastEntry()` at line 40.
- `limit(1)` -- Already used in `WaterEntryDao.deleteLastEntry()` at line 39.

### Pattern 4: watchAll Stream

**What:** Reactive stream of all target history rows, ordered by effectiveDate ascending.

```dart
/// Reactive stream of all history rows, ordered by effectiveDate ASC.
Stream<List<TargetHistoryData>> watchAll() {
  return (select(targetHistory)
        ..orderBy([(t) => OrderingTerm.asc(t.effectiveDate)]))
      .watch();
}
```

### Pattern 5: Upsert with DoUpdate + target (CRITICAL)

**What:** Insert a new row, or update `targetMl` if a row with the same `effectiveDate` already exists.

**CRITICAL FINDING:** `insertOnConflictUpdate()` will NOT work here. It only detects PRIMARY KEY conflicts. Our primary key is `id` (auto-increment), and the UNIQUE constraint is on `effectiveDate`. We must use the general `insert()` with `DoUpdate` and an explicit `target` parameter. [CITED: pub.dev/documentation/drift/latest/drift/InsertStatement/insertOnConflictUpdate.html] [CITED: drift.simonbinder.eu/dart_api/writes/]

**Correct Drift Dart syntax:**
```dart
/// Upsert: insert a new row or update targetMl if effectiveDate already exists.
Future<void> insertOrReplace(String effectiveDate, int targetMl) {
  return into(targetHistory).insert(
    TargetHistoryCompanion.insert(
      effectiveDate: effectiveDate,
      targetMl: targetMl,
    ),
    onConflict: DoUpdate(
      (old) => TargetHistoryCompanion.custom(
        targetMl: Constant(targetMl),
      ),
      target: [targetHistory.effectiveDate],
    ),
  );
}
```

**Why this works:**
- `target: [targetHistory.effectiveDate]` tells SQLite to detect conflicts on the UNIQUE `effectiveDate` column, not the auto-increment `id`
- `DoUpdate` callback receives the old row and returns a Companion with only the columns to update
- `TargetHistoryCompanion.custom()` is used inside `DoUpdate` for providing SQL-level expressions; `Constant(targetMl)` wraps the Dart value as a SQL constant [CITED: drift.simonbinder.eu/dart_api/writes/]
- Columns NOT in the Companion remain unchanged (so `id` and `effectiveDate` keep their existing values)

**WRONG approach (from CONTEXT.md D-06 -- needs correction):**
```dart
// WRONG: insertOnConflictUpdate uses PRIMARY KEY (id), not UNIQUE (effectiveDate)
// A second insert for the same date would create a DUPLICATE row because
// the auto-increment id is always new -> no PK conflict detected.
await into(targetHistory).insertOnConflictUpdate(companion);
```

### Pattern 6: Seed Row in onCreate

**What:** After `m.createAll()`, insert the default target history row so that `getTargetForDate()` always finds a row.

```dart
// In app_database.dart, inside MigrationStrategy.onCreate:
@override
MigrationStrategy get migration {
  return MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      // Existing seeds...
      await into(userSettings).insert(UserSettingsCompanion.insert());
      await batch((batch) {
        batch.insertAll(drinkPresets, [/* existing presets */]);
      });
      // NEW: Seed target_history with default target for today
      final now = DateTime.now();
      final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await into(targetHistory).insert(
        TargetHistoryCompanion.insert(
          effectiveDate: todayKey,
          targetMl: 2000,
        ),
      );
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
```

**Key details:**
- The date formatting matches the `todayDateKey()` helper pattern from `stream_providers.dart:57-60` [VERIFIED: codebase]
- We inline the formatting rather than importing `todayDateKey()` because `app_database.dart` should not depend on the providers layer (it would create a circular dependency)
- `targetMl: 2000` matches `UserSettings.dailyTargetMl` default of `Constant(2000)` [VERIFIED: user_settings_table.dart:6]
- No UNIQUE conflict is possible in `onCreate` since the table was just created empty

### Pattern 7: Test Setup (In-Memory Database)

**What:** All existing tests use the same setup pattern. [VERIFIED: 3 existing test files]

```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drinky_drinky/data/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  // Tests go here
}
```

**Important:** The `DatabaseConnection` wrapper with `closeStreamsSynchronously: true` is used in ALL existing tests. This ensures streams close immediately during teardown. [VERIFIED: water_entry_dao_test.dart:12-15, user_settings_dao_test.dart:12-15, drink_preset_dao_test.dart:12-15]

### Anti-Patterns to Avoid

- **Using `insertOnConflictUpdate` with non-PK UNIQUE constraints:** Will silently create duplicate rows because it only checks the primary key for conflicts. Always use `DoUpdate` with explicit `target` when the conflict column is not the primary key. [CITED: pub.dev/documentation/drift/latest/drift/InsertStatement/insertOnConflictUpdate.html]
- **Importing provider-layer code in app_database.dart:** Would create circular dependency (database -> providers -> database). Inline the date formatting in `onCreate`.
- **Using `uniqueKeys` for a single-column constraint:** Unnecessary complexity. `text().unique()` is the standard pattern for single columns. [CITED: drift.simonbinder.eu/docs/getting-started/advanced_dart_tables/]
- **Forgetting to run build_runner after adding a new table/DAO:** The `part` directive in the DAO file references a `.g.dart` file that does not exist until code-gen runs.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| UNIQUE constraint on column | Manual check-then-insert | `text().unique()` column modifier | Race conditions; Drift generates proper SQL UNIQUE constraint |
| Upsert with UNIQUE column | SELECT + conditional INSERT/UPDATE | `DoUpdate` with `target` parameter | Atomic operation at SQL level; no race between check and write |
| Date formatting for dateKey | Custom formatter in each location | Inline `YYYY-MM-DD` pattern (same as `todayDateKey()`) | Consistency with existing codebase pattern |
| In-memory test database | Mock/fake database | `NativeDatabase.memory()` with full `AppDatabase` | Tests real SQL behavior; existing pattern in all 3 test files |

## Common Pitfalls

### Pitfall 1: insertOnConflictUpdate Ignores UNIQUE Columns
**What goes wrong:** Using `insertOnConflictUpdate()` on a table with auto-increment PK and UNIQUE on another column silently creates duplicate rows for the same `effectiveDate`.
**Why it happens:** `insertOnConflictUpdate()` only uses the PRIMARY KEY as the conflict target. Since auto-increment IDs are always new, no conflict is ever detected.
**How to avoid:** Use `insert(..., onConflict: DoUpdate(..., target: [targetHistory.effectiveDate]))`.
**Warning signs:** Multiple rows with the same `effectiveDate` in the table; `getTargetForDate()` returns stale/wrong value.

### Pitfall 2: Missing Seed Row Causes Null Returns
**What goes wrong:** `getTargetForDate()` returns `null` on first launch if `onCreate` does not seed a row.
**Why it happens:** The query `WHERE effectiveDate <= :dateKey` finds nothing in an empty table.
**How to avoid:** Seed in `onCreate` immediately after `m.createAll()`, with today's date and default target (2000 ml).
**Warning signs:** Null check failures in downstream providers (Phase 10+); progress ring shows 0/null.

### Pitfall 3: Forgetting to Register Table AND DAO in @DriftDatabase
**What goes wrong:** Build runner succeeds but the table/DAO is not accessible on the `AppDatabase` instance.
**Why it happens:** Table defined in its own file but not added to `@DriftDatabase(tables: [...])` and/or DAO not added to `daos: [...]`.
**How to avoid:** Always add BOTH the table class to `tables:` AND the DAO class to `daos:` in the annotation. Then run `dart run build_runner build --delete-conflicting-outputs`.
**Warning signs:** Compile error: `targetHistory` / `targetHistoryDao` not found on `AppDatabase`.

### Pitfall 4: build_runner Conflicts with Stale Generated Files
**What goes wrong:** `build_runner build` fails with "conflicting outputs" error.
**Why it happens:** Old `.g.dart` files from a previous schema conflict with new table/DAO additions.
**How to avoid:** Always use `--delete-conflicting-outputs` flag: `dart run build_runner build --delete-conflicting-outputs`.
**Warning signs:** Build errors mentioning conflicting outputs or unresolved references in `.g.dart` files.

### Pitfall 5: Test Accesses DAO Before onCreate Seed Runs
**What goes wrong:** Test expects seed data but queries return empty results.
**Why it happens:** In the test setup, `AppDatabase(NativeDatabase.memory())` triggers `onCreate` which runs `m.createAll()` and seeds. But if the test queries synchronously before `setUp` completes, seeds may not be there.
**How to avoid:** All existing tests use `await` in `setUp` implicitly (the `DatabaseConnection` handles this). The first `await` on a DAO method in the test will wait for `onCreate` to complete. No explicit wait needed.
**Warning signs:** Tests pass individually but fail when run together.

## Code Examples

### Complete TargetHistoryDao Implementation

```dart
// Source: synthesized from verified Drift docs + existing codebase patterns
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/target_history_table.dart';

part 'target_history_dao.g.dart';

@DriftAccessor(tables: [TargetHistory])
class TargetHistoryDao extends DatabaseAccessor<AppDatabase>
    with _$TargetHistoryDaoMixin {
  TargetHistoryDao(super.attachedDatabase);

  /// Returns the targetMl for the most recent row where effectiveDate <= dateKey.
  /// Returns null if no rows exist (defensive).
  Future<int?> getTargetForDate(String dateKey) async {
    final row = await (select(targetHistory)
          ..where((t) => t.effectiveDate.isSmallerOrEqualValue(dateKey))
          ..orderBy([(t) => OrderingTerm.desc(t.effectiveDate)])
          ..limit(1))
        .getSingleOrNull();
    return row?.targetMl;
  }

  /// Reactive stream of all history rows, ordered by effectiveDate ASC.
  Stream<List<TargetHistoryData>> watchAll() {
    return (select(targetHistory)
          ..orderBy([(t) => OrderingTerm.asc(t.effectiveDate)]))
        .watch();
  }

  /// Upsert: insert a new row or update targetMl if effectiveDate already exists.
  Future<void> insertOrReplace(String effectiveDate, int targetMl) {
    return into(targetHistory).insert(
      TargetHistoryCompanion.insert(
        effectiveDate: effectiveDate,
        targetMl: targetMl,
      ),
      onConflict: DoUpdate(
        (old) => TargetHistoryCompanion.custom(
          targetMl: Constant(targetMl),
        ),
        target: [targetHistory.effectiveDate],
      ),
    );
  }
}
```

### BUG-01 Confirmation Test

```dart
// Source: follows existing test pattern in water_entry_dao_test.dart
test('deleteLastEntry does not delete entries from other dates (BUG-01)', () async {
  // Insert entry for yesterday
  await db.waterEntryDao.insertEntry(
    WaterEntriesCompanion.insert(
      amountMl: 500,
      loggedAt: DateTime(2026, 6, 2, 20, 0),
      dateKey: '2026-06-02',
    ),
  );
  // Insert entry for today
  await db.waterEntryDao.insertEntry(
    WaterEntriesCompanion.insert(
      amountMl: 250,
      loggedAt: DateTime(2026, 6, 3, 8, 0),
      dateKey: '2026-06-03',
    ),
  );

  // Delete last entry for today
  await db.waterEntryDao.deleteLastEntry('2026-06-03');

  // Yesterday's entry must still exist
  final yesterdayEntries =
      await db.waterEntryDao.watchEntriesForDate('2026-06-02').first;
  expect(yesterdayEntries, hasLength(1));
  expect(yesterdayEntries.first.amountMl, 500);

  // Today should be empty
  final todayEntries =
      await db.waterEntryDao.watchEntriesForDate('2026-06-03').first;
  expect(todayEntries, isEmpty);
});
```

### BUG-03 Confirmation Test

```dart
// Source: tests water_repository.dart:34-47 validation logic
// NOTE: This test must go in a repository test file since validation is at repository level
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drinky_drinky/data/database/app_database.dart';
import 'package:drinky_drinky/data/repositories/water_repository.dart';

void main() {
  late AppDatabase db;
  late WaterRepository repo;

  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    repo = WaterRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('WaterRepository dateKey validation (BUG-03)', () {
    test('rejects semantically invalid date like 2024-02-30', () {
      expect(
        () => repo.insertEntry(250, DateTime.now(), '2024-02-30'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects malformed dateKey like abcd-ef-gh', () {
      expect(
        () => repo.insertEntry(250, DateTime.now(), 'abcd-ef-gh'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('accepts valid dateKey like 2026-06-03', () async {
      // Should not throw
      await repo.insertEntry(250, DateTime(2026, 6, 3, 10, 0), '2026-06-03');
    });
  });
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `sqlite3_flutter_libs` | `drift_flutter` | 2024 | Already using current approach; drift_flutter 0.3.0 in pubspec |
| `insertOnConflictUpdate` for all upserts | `DoUpdate` with `target` for non-PK UNIQUE | Drift 2.x | Must use `target` parameter when UNIQUE column differs from PK |

**Deprecated/outdated:**
- `sqlite3_flutter_libs` -- EOL, already replaced by `drift_flutter` in this project [VERIFIED: pubspec.yaml]

## Project Constraints (from CLAUDE.md)

- **Tech stack**: Flutter + Riverpod + Drift -- no deviation
- **Platform**: iOS and Android only
- **Offline-first**: No backend or cloud sync
- **Database setup**: Must use `drift_flutter` (not `sqlite3_flutter_libs`)
- **State management**: Use `flutter_riverpod` (not `hooks_riverpod`)
- **Packages to NOT use**: sqlite3_flutter_libs, awesome_notifications, GetX, provider, hive/isar, flutter_native_timezone
- **Code-gen**: Run `dart run build_runner build --delete-conflicting-outputs` after schema changes

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `TargetHistoryCompanion.custom()` is the correct method for providing SQL expressions inside `DoUpdate` callback | Pattern 5 | Compilation error; fix by using alternative Companion constructor |
| A2 | Drift generates data class named `TargetHistoryData` (singular, with "Data" suffix) for table class `TargetHistory` | Pattern 1 | Wrong type name in DAO return types; fix after code-gen by checking actual generated name |

**Note on A2:** Drift naming convention observed in existing codebase: table `WaterEntries` (plural) generates data class `WaterEntry` (singular, no suffix). Table `UserSettings` generates `UserSetting`. Table `DrinkPresets` generates `DrinkPreset`. Since the new table is `TargetHistory` (already singular), the generated data class name could be `TargetHistoryData` (with suffix to avoid collision) or just `TargetHistory` (which would collide with the table class). The actual name will be known after running build_runner. The DAO code should use the generated type, which will be visible in `app_database.g.dart` after code-gen. This is a LOW risk since the compiler will immediately flag any wrong type name.

## Open Questions

1. **Generated data class name for `TargetHistory` table**
   - What we know: Drift strips trailing "s" for plural table names (WaterEntries -> WaterEntry). For singular table names, it may add a "Data" suffix to avoid collision.
   - What's unclear: Exact generated name for a table class already in singular form.
   - Recommendation: Run `build_runner` first, then check `app_database.g.dart` for the generated class name. Use that name in the DAO return types. If it collides, rename the table class to `TargetHistories` to follow the plural convention.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | N/A -- local-only app, no auth |
| V3 Session Management | No | N/A -- no sessions |
| V4 Access Control | No | N/A -- single-user local app |
| V5 Input Validation | Yes | Existing regex + DateTime.tryParse + round-trip validation (BUG-03 already implemented) |
| V6 Cryptography | No | N/A -- no encryption needed for hydration data |

### Known Threat Patterns for Drift/SQLite

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SQL injection via raw queries | Tampering | Drift uses parameterized queries by default; no raw SQL in this phase |
| Invalid dateKey stored in DB | Tampering | Repository-level validation (BUG-03) rejects invalid dates before DAO |
| Integer overflow in targetMl | Tampering | Dart `int` is 64-bit; no realistic overflow risk for ml values |

**Security assessment:** LOW risk phase. All data is local, no network I/O, no user authentication. Input validation is already implemented (BUG-03). The only new write path (`insertOrReplace`) accepts a `String effectiveDate` and `int targetMl` -- both constrained by type system and the UNIQUE constraint prevents duplicate insertion.

## Sources

### Primary (HIGH confidence)
- `lib/data/database/app_database.dart` -- current schema, migration strategy, seed pattern [VERIFIED: codebase]
- `lib/data/database/tables/water_entries_table.dart` -- table definition pattern with @TableIndex [VERIFIED: codebase]
- `lib/data/database/daos/water_entry_dao.dart` -- DAO pattern, query builder syntax (where, orderBy, limit, getSingleOrNull) [VERIFIED: codebase]
- `lib/data/database/daos/drink_preset_dao.dart` -- simpler DAO pattern for reference [VERIFIED: codebase]
- `lib/data/repositories/water_repository.dart:34-47` -- BUG-03 validation implementation [VERIFIED: codebase]
- `lib/core/providers/stream_providers.dart:57-60` -- todayDateKey() helper [VERIFIED: codebase]
- `test/data/database/daos/*.dart` -- 3 test files, all using same NativeDatabase.memory() pattern [VERIFIED: codebase]
- drift.simonbinder.eu/docs/getting-started/advanced_dart_tables/ -- uniqueKeys, .unique() column syntax [CITED: official docs]
- drift.simonbinder.eu/dart_api/writes/ -- insertOnConflictUpdate, DoUpdate, target parameter [CITED: official docs]
- pub.dev/documentation/drift/latest/drift/InsertStatement/insertOnConflictUpdate.html -- PK-only conflict detection confirmed [CITED: official API docs]

### Secondary (MEDIUM confidence)
- None

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- no new packages, all existing
- Architecture: HIGH -- follows exact established patterns from existing 3 tables + 3 DAOs + 3 test files
- Pitfalls: HIGH -- upsert behavior verified against official Drift API documentation
- Code examples: HIGH -- query patterns verified against existing working codebase code

**Research date:** 2026-06-10
**Valid until:** 2026-07-10 (stable domain, no fast-moving dependencies)
