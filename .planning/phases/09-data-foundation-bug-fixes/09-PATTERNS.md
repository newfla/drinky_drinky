# Phase 9: Data Foundation & Bug Fixes - Pattern Map

**Mapped:** 2026-06-10
**Files analyzed:** 6
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/data/database/tables/target_history_table.dart` | model | CRUD | `lib/data/database/tables/water_entries_table.dart` | exact |
| `lib/data/database/daos/target_history_dao.dart` | service | CRUD | `lib/data/database/daos/water_entry_dao.dart` | exact |
| `lib/data/database/app_database.dart` | config | CRUD | itself (modify in place) | exact |
| `test/data/database/daos/target_history_dao_test.dart` | test | CRUD | `test/data/database/daos/water_entry_dao_test.dart` | exact |
| `test/data/database/daos/water_entry_dao_test.dart` | test | CRUD | itself (add BUG-01 test) | exact |
| `test/data/repositories/water_repository_test.dart` | test | request-response | `test/data/database/daos/water_entry_dao_test.dart` | role-match |

## Pattern Assignments

### `lib/data/database/tables/target_history_table.dart` (model, CRUD)

**Analog:** `lib/data/database/tables/water_entries_table.dart`

**Complete file pattern** (lines 1-9):
```dart
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_water_entries_date_key', columns: {#dateKey})
class WaterEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get amountMl => integer()();
  DateTimeColumn get loggedAt => dateTime()();
  TextColumn get dateKey => text()(); // 'YYYY-MM-DD' local date
}
```

**Adapt:** Replace `@TableIndex` with none (or add index on effectiveDate if desired). Use `text().unique()()` for `effectiveDate` column instead of plain `text()()`. Table name: `TargetHistory` (singular, per CONTEXT.md).

---

### `lib/data/database/daos/target_history_dao.dart` (service, CRUD)

**Analog:** `lib/data/database/daos/water_entry_dao.dart`

**Imports + class declaration pattern** (lines 1-10):
```dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/water_entries_table.dart';

part 'water_entry_dao.g.dart';

@DriftAccessor(tables: [WaterEntries])
class WaterEntryDao extends DatabaseAccessor<AppDatabase>
    with _$WaterEntryDaoMixin {
  WaterEntryDao(super.attachedDatabase);
```

**Query pattern: select + where + orderBy + limit + getSingleOrNull** (lines 35-40):
```dart
  Future<int> deleteLastEntry(String dateKey) async {
    final lastEntry = await (select(waterEntries)
          ..where((t) => t.dateKey.equals(dateKey))
          ..orderBy([(t) => OrderingTerm.desc(t.loggedAt)])
          ..limit(1))
        .getSingleOrNull();
```

**Query pattern: select + orderBy + watch** (lines 18-23):
```dart
  Stream<List<WaterEntry>> watchEntriesForDate(String dateKey) {
    return (select(waterEntries)
          ..where((t) => t.dateKey.equals(dateKey))
          ..orderBy([(t) => OrderingTerm.asc(t.loggedAt)]))
        .watch();
  }
```

**Query pattern: isSmallerOrEqualValue** (line 52):
```dart
              t.dateKey.isSmallerOrEqualValue(endDateKey))
```

---

### `lib/data/database/app_database.dart` (config, CRUD)

**Analog:** itself

**Table + DAO registration pattern** (lines 14-17):
```dart
@DriftDatabase(
  tables: [WaterEntries, UserSettings, DrinkPresets],
  daos: [WaterEntryDao, UserSettingsDao, DrinkPresetDao],
)
```
Add `TargetHistory` to `tables:` and `TargetHistoryDao` to `daos:`. Add corresponding imports.

**Import pattern** (lines 5-10):
```dart
import 'tables/water_entries_table.dart';
import 'tables/user_settings_table.dart';
import 'tables/drink_presets_table.dart';
import 'daos/water_entry_dao.dart';
import 'daos/user_settings_dao.dart';
import 'daos/drink_preset_dao.dart';
```

**Seed pattern in onCreate** (lines 37-51):
```dart
      onCreate: (Migrator m) async {
        await m.createAll();
        // Seed default settings (single row, id=1).
        await into(userSettings).insert(
          UserSettingsCompanion.insert(),
        );
        // Seed default drink presets (150/250/500ml).
        await batch((batch) {
          batch.insertAll(drinkPresets, [
            DrinkPresetsCompanion.insert(amountMl: 150, sortOrder: 0),
            DrinkPresetsCompanion.insert(amountMl: 250, sortOrder: 1),
            DrinkPresetsCompanion.insert(amountMl: 500, sortOrder: 2),
          ]);
        });
      },
```
Add target_history seed after the batch block using `into(targetHistory).insert(TargetHistoryCompanion.insert(...))`.

---

### `test/data/database/daos/target_history_dao_test.dart` (test, CRUD)

**Analog:** `test/data/database/daos/water_entry_dao_test.dart`

**Test setup pattern** (lines 1-20):
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
```

**Test body pattern** (lines 22-36):
```dart
  group('WaterEntryDao', () {
    test('insert an entry and watch entries for that date returns it', () async {
      await db.waterEntryDao.insertEntry(
        WaterEntriesCompanion.insert(
          amountMl: 250,
          loggedAt: DateTime(2026, 6, 3, 10, 30),
          dateKey: '2026-06-03',
        ),
      );

      final entries =
          await db.waterEntryDao.watchEntriesForDate('2026-06-03').first;
      expect(entries, hasLength(1));
      expect(entries.first.amountMl, 250);
    });
```

---

### `test/data/database/daos/water_entry_dao_test.dart` (test, CRUD — BUG-01 addition)

**Analog:** itself (add new test within existing `group('WaterEntryDao', ...)`)

**Pattern for cross-date isolation test** (lines 116-141):
```dart
    test('entries for different date_keys are isolated', () async {
      await db.waterEntryDao.insertEntry(
        WaterEntriesCompanion.insert(
          amountMl: 250,
          loggedAt: DateTime(2026, 6, 3, 10, 0),
          dateKey: '2026-06-03',
        ),
      );
      await db.waterEntryDao.insertEntry(
        WaterEntriesCompanion.insert(
          amountMl: 400,
          loggedAt: DateTime(2026, 6, 4, 10, 0),
          dateKey: '2026-06-04',
        ),
      );

      final entriesJune3 =
          await db.waterEntryDao.watchEntriesForDate('2026-06-03').first;
      final entriesJune4 =
          await db.waterEntryDao.watchEntriesForDate('2026-06-04').first;

      expect(entriesJune3, hasLength(1));
      expect(entriesJune3.first.amountMl, 250);
      expect(entriesJune4, hasLength(1));
      expect(entriesJune4.first.amountMl, 400);
    });
```

BUG-01 confirmation test follows this same pattern: insert entries on two dates, call `deleteLastEntry` for one date, verify the other date's entry survives.

---

### `test/data/repositories/water_repository_test.dart` (test, request-response — NEW)

**Analog:** `test/data/database/daos/water_entry_dao_test.dart` (setup pattern)

Same `setUp`/`tearDown` pattern as above, plus instantiate `WaterRepository(db)`. The BUG-03 test calls `repo.insertEntry()` with invalid dateKeys and expects `ArgumentError`.

**Additional import needed:**
```dart
import 'package:drinky_drinky/data/repositories/water_repository.dart';
```

## Shared Patterns

### Database Test Setup
**Source:** `test/data/database/daos/water_entry_dao_test.dart` lines 9-19
**Apply to:** All test files (target_history_dao_test.dart, water_repository_test.dart)
```dart
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
```

### Drift Table Definition
**Source:** `lib/data/database/tables/water_entries_table.dart` lines 1-9
**Apply to:** `target_history_table.dart`
- Import `package:drift/drift.dart`
- Class extends `Table`
- `id` column: `integer().autoIncrement()()`
- Text columns: `text()()`

### DAO Declaration
**Source:** `lib/data/database/daos/water_entry_dao.dart` lines 1-10
**Apply to:** `target_history_dao.dart`
- Import drift, app_database, table file
- `part` directive for `.g.dart`
- `@DriftAccessor(tables: [TableName])`
- Extends `DatabaseAccessor<AppDatabase>` with mixin
- Constructor: `DaoName(super.attachedDatabase);`

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| (none) | -- | -- | All files have exact analogs in the existing codebase |

## Metadata

**Analog search scope:** `lib/data/database/`, `test/data/`
**Files scanned:** 9 (3 tables, 3 DAOs, 3 test files)
**Pattern extraction date:** 2026-06-10
