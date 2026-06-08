# Phase 1: Data Foundation - Research

**Researched:** 2026-06-03
**Domain:** Flutter project scaffold, Drift database, Riverpod providers, Freezed entities, GoRouter setup
**Confidence:** HIGH

## Summary

Phase 1 is the technical foundation for the entire Drinky Drinky app. It creates the Flutter project, configures Drift with the irreversible `store_date_time_values_as_text: true` setting, defines three database tables (water_entries, user_settings, drink_presets), implements DAOs and repositories that expose reactive streams, wires everything through Riverpod providers, and defines Freezed domain entities. No UI screens are built -- only the data layer and navigation skeleton.

The critical ordering constraint is that `build.yaml` with the Drift datetime-as-text option MUST exist before any table definitions are written and code generation runs. This is irreversible after data is written. The second critical concern is the `date_key` TEXT column on water_entries, which stores the local date (YYYY-MM-DD) for correct daily aggregation across timezones.

**Primary recommendation:** Execute in strict order: (1) flutter create, (2) build.yaml with Drift text mode, (3) pubspec.yaml dependencies, (4) folder structure, (5) Drift tables + AppDatabase, (6) DAOs, (7) Freezed domain entities, (8) repositories, (9) Riverpod providers, (10) GoRouter skeleton, (11) unit tests.

<user_constraints>

## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Bundle ID: `com.bizzarri.drinkydrinky` -- app name: `Drinky Drinky`
- **D-02:** Minimum iOS: 16.0
- **D-03:** Minimum Android: API 26 / Android 8.0
- **D-04:** Scaffold command: `flutter create --org com.bizzarri --project-name drinky_drinky --platforms ios,android`
- **D-05:** Daily target default: 2000 ml
- **D-06:** Quick-add preset defaults: 200 ml / 300 ml / 400 ml / 500 ml
- **D-07:** Notification interval default: 60 minutes
- **D-08:** DND window default: 23:00 - 07:00 (enabled by default)
- **D-09:** Riverpod code generation (`@riverpod` annotations + `build_runner`)
- **D-10:** Freezed for domain model classes
- **D-11:** GoRouter for navigation
- **D-12:** Layer-first folder organization: `lib/data/`, `lib/domain/`, `lib/presentation/`, `lib/core/`
- **D-13:** `store_date_time_values_as_text: true` in `build.yaml` (IRREVERSIBLE)
- **D-14:** `date_key` TEXT column (YYYY-MM-DD local timezone) on water_entries
- **D-15:** Three tables: water_entries, user_settings (single-row id=1), drink_presets
- **D-16:** Unit tests for all DAOs using Drift in-memory database

### Claude's Discretion
None specified -- all decisions are locked.

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope.

</user_constraints>

## Project Constraints (from CLAUDE.md)

- Tech stack: Flutter + Riverpod + Drift -- no deviation
- Platform: iOS and Android only (no web/desktop for v1)
- Offline-first: No backend or cloud sync in v1
- GSD workflow enforcement: use GSD commands for changes

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| SQLite schema + tables | Database / Storage | -- | Drift owns all persistence via type-safe table definitions |
| Data access (CRUD) | Database / Storage | -- | DAOs encapsulate all SQL queries |
| Domain model mapping | Data Layer (Repositories) | -- | Repositories transform Drift rows to Freezed domain entities |
| Reactive data streams | Data Layer (Repositories) | -- | Drift .watch() wrapped in repository methods |
| Provider wiring | Application / Core | -- | Riverpod providers expose repositories and streams to future UI |
| Navigation structure | Frontend (Router) | -- | GoRouter defines route topology; screens populated in Phase 2+ |
| Seed data | Database / Storage | -- | Migration onCreate callback seeds defaults |

## Standard Stack

### Core (Phase 1 only -- packages needed for this phase)

| Library | Version | Purpose | Verified Via |
|---------|---------|---------|--------------|
| drift | ^2.33.0 | Type-safe SQLite ORM with reactive streams | [VERIFIED: pub.dev fetch -- v2.33.0 published 30 days ago] |
| drift_flutter | ^0.3.0 | Flutter database setup, replaces sqlite3_flutter_libs | [VERIFIED: pub.dev fetch -- v0.3.0 published 3 months ago] |
| drift_dev | ^2.33.0 | Code generator for Drift (dev dependency) | [VERIFIED: pub.dev fetch] |
| flutter_riverpod | ^3.3.1 | Widget-level state management | [VERIFIED: pub.dev fetch -- v3.3.1 is latest stable] |
| riverpod_annotation | ^4.0.2 | @riverpod code-gen annotations | [VERIFIED: pub.dev fetch] |
| riverpod_generator | ^4.0.3 | Provider code generation (dev dependency) | [VERIFIED: pub.dev fetch] |
| freezed | ^3.2.5 | Immutable data class generation (dev dependency) | [VERIFIED: pub.dev fetch -- v3.2.5 published 3 months ago] |
| freezed_annotation | ^3.1.0 | Freezed annotations (runtime dependency) | [VERIFIED: pub.dev fetch] |
| json_annotation | ^4.12.0 | JSON serialization annotations | [VERIFIED: pub.dev fetch] |
| build_runner | ^2.15.0 | Code generation orchestrator (dev dependency) | [VERIFIED: pub.dev fetch] |
| go_router | ^17.3.0 | Declarative routing for Flutter | [VERIFIED: pub.dev fetch -- v17.3.0 published June 2026, requires Flutter 3.38/Dart 3.10] |
| path_provider | ^2.1.5 | App directory paths for database file | [VERIFIED: pub.dev fetch] |

### Dev/Quality

| Library | Version | Purpose | Verified Via |
|---------|---------|---------|--------------|
| riverpod_lint | ^3.1.3 | Static analysis for Riverpod | [VERIFIED: pub.dev fetch] |
| custom_lint | ^0.8.1 | Custom lint runner (required by riverpod_lint) | [VERIFIED: pub.dev fetch] |
| flutter_lints | ^6.0.0 | Official Flutter lint rules | [VERIFIED: pub.dev fetch] |

### NOT Needed in Phase 1

These packages from STACK.md are deferred to later phases:

| Library | Phase | Reason |
|---------|-------|--------|
| flutter_local_notifications | Phase 5 | No notifications in Phase 1 |
| timezone | Phase 5 | Needed for notification scheduling |
| flutter_timezone | Phase 5 | Needed for device timezone detection |
| permission_handler | Phase 5 | No permissions requested in Phase 1 |
| table_calendar | Phase 4 | Calendar UI component |
| percent_indicator | Phase 2 | Progress ring UI component |
| intl | Phase 2 | Date formatting for UI |
| shared_preferences | Not needed | User decided to put all settings in Drift (D-15) |
| google_fonts | Phase 2 | Typography for UI |

**Installation (Phase 1 pubspec.yaml):**

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^3.3.1
  riverpod_annotation: ^4.0.2

  # Database
  drift: ^2.33.0
  drift_flutter: ^0.3.0
  path_provider: ^2.1.5

  # Navigation
  go_router: ^17.3.0

  # Data Classes
  freezed_annotation: ^3.1.0
  json_annotation: ^4.12.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

  # Code Generation
  build_runner: ^2.15.0
  drift_dev: ^2.33.0
  riverpod_generator: ^4.0.3
  freezed: ^3.2.5

  # Lint
  riverpod_lint: ^3.1.3
  custom_lint: ^0.8.1
```

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## Package Legitimacy Audit

> slopcheck is a Python tool and not applicable to Flutter/Dart packages. All packages below were verified via pub.dev direct fetch (official Dart package registry). All are from verified publishers or the Flutter team.

| Package | Registry | Age | Publisher | Disposition |
|---------|----------|-----|-----------|-------------|
| drift | pub.dev | 5+ yrs | simonbinder.eu (verified) | Approved |
| drift_flutter | pub.dev | 1+ yr | simonbinder.eu (verified) | Approved |
| drift_dev | pub.dev | 5+ yrs | simonbinder.eu (verified) | Approved |
| flutter_riverpod | pub.dev | 4+ yrs | dash-overflow.net (verified) | Approved |
| riverpod_annotation | pub.dev | 2+ yrs | dash-overflow.net (verified) | Approved |
| riverpod_generator | pub.dev | 2+ yrs | dash-overflow.net (verified) | Approved |
| freezed | pub.dev | 5+ yrs | dash-overflow.net (verified) | Approved |
| freezed_annotation | pub.dev | 5+ yrs | dash-overflow.net (verified) | Approved |
| json_annotation | pub.dev | 6+ yrs | google.dev (verified) | Approved |
| build_runner | pub.dev | 7+ yrs | tools.dart.dev (verified) | Approved |
| go_router | pub.dev | 3+ yrs | flutter.dev (verified) | Approved |
| path_provider | pub.dev | 7+ yrs | flutter.dev (verified) | Approved |
| riverpod_lint | pub.dev | 2+ yrs | dash-overflow.net (verified) | Approved |
| custom_lint | pub.dev | 2+ yrs | dash-overflow.net (verified) | Approved |
| flutter_lints | pub.dev | 4+ yrs | flutter.dev (verified) | Approved |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
                    +-----------------+
                    |   main.dart     |
                    | ProviderScope   |
                    | MaterialApp     |
                    |  .router(       |
                    |   goRouter)     |
                    +--------+--------+
                             |
                    +--------v--------+
                    |    GoRouter     |
                    | / -> HomeScreen |  (Screens are empty
                    | /history        |   placeholders in Phase 1)
                    | /settings       |
                    +--------+--------+
                             |
            +----------------+----------------+
            |                                 |
   +--------v--------+              +--------v--------+
   | Riverpod        |              | Riverpod        |
   | Providers       |              | Providers       |
   | (core/          |              | (core/          |
   |  providers/)    |              |  providers/)    |
   | - appDatabase   |              | - drinkPresets  |
   | - waterRepo     |              | - userSettings  |
   | - settingsRepo  |              |                 |
   +--------+--------+              +--------+--------+
            |                                 |
   +--------v---------------------------------v--------+
   |              REPOSITORIES                         |
   | WaterRepository     SettingsRepository            |
   | - watchTodayProgress()  - watchSettings()         |
   | - insertEntry()         - updateSettings()        |
   | - deleteLastEntry()     - watchPresets()           |
   |   (Drift rows -> Freezed domain entities)         |
   +--------+-----------------------------------------+
            |
   +--------v--------+
   |     DAOs         |
   | WaterEntryDao    |
   | UserSettingsDao  |
   | DrinkPresetDao   |
   | (.watch() streams|
   |  + CRUD ops)     |
   +--------+--------+
            |
   +--------v--------+
   |  AppDatabase     |
   |  (Drift)         |
   |  schemaVersion=1 |
   |  3 tables        |
   |  SQLite file     |
   +------------------+
```

### Recommended Project Structure (D-12: Layer-first)

```
lib/
├── core/
│   ├── providers/
│   │   ├── database_provider.dart       # AppDatabase singleton provider
│   │   ├── repository_providers.dart    # WaterRepository, SettingsRepository providers
│   │   └── stream_providers.dart        # StreamProviders wrapping repo streams
│   └── router/
│       └── app_router.dart              # GoRouter config with 3 routes
├── data/
│   ├── database/
│   │   ├── app_database.dart            # @DriftDatabase class
│   │   ├── app_database.g.dart          # Generated
│   │   ├── tables/
│   │   │   ├── water_entries_table.dart
│   │   │   ├── user_settings_table.dart
│   │   │   └── drink_presets_table.dart
│   │   └── daos/
│   │       ├── water_entry_dao.dart
│   │       ├── water_entry_dao.g.dart   # Generated
│   │       ├── user_settings_dao.dart
│   │       ├── user_settings_dao.g.dart # Generated
│   │       ├── drink_preset_dao.dart
│   │       └── drink_preset_dao.g.dart  # Generated
│   └── repositories/
│       ├── water_repository.dart
│       └── settings_repository.dart
├── domain/
│   └── entities/
│       ├── water_entry.dart             # Freezed
│       ├── water_entry.freezed.dart     # Generated
│       ├── daily_progress.dart          # Freezed
│       ├── daily_progress.freezed.dart  # Generated
│       ├── user_settings_entity.dart    # Freezed
│       ├── user_settings_entity.freezed.dart # Generated
│       ├── drink_preset_entity.dart     # Freezed
│       └── drink_preset_entity.freezed.dart  # Generated
├── presentation/
│   └── screens/
│       ├── home_screen.dart             # Placeholder
│       ├── history_screen.dart          # Placeholder
│       └── settings_screen.dart         # Placeholder
└── main.dart
```

### Pattern 1: build.yaml -- Drift DateTime as Text (MUST BE FIRST)

**What:** Configure Drift to store DateTime values as ISO-8601 text strings instead of Unix timestamps.
**When to use:** Before any table definitions or code generation.
**Critical:** This is irreversible after data is written.

```yaml
# build.yaml (project root)
# Source: https://drift.simonbinder.eu/generation_options/
targets:
  $default:
    builders:
      drift_dev:
        options:
          store_date_time_values_as_text: true
```

### Pattern 2: Drift Table Definition

**What:** Define type-safe SQLite tables as Dart classes.
**Source:** [CITED: drift.simonbinder.eu/dart_api/tables/]

```dart
// lib/data/database/tables/water_entries_table.dart
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_water_entries_date_key', columns: {#dateKey})
class WaterEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get amountMl => integer()();
  DateTimeColumn get loggedAt => dateTime()();
  TextColumn get dateKey => text()(); // 'YYYY-MM-DD' local date
}
```

```dart
// lib/data/database/tables/user_settings_table.dart
import 'package:drift/drift.dart';

class UserSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dailyTargetMl => integer().withDefault(const Constant(2000))();
  IntColumn get notificationIntervalMinutes => integer().withDefault(const Constant(60))();
  IntColumn get dndStartHour => integer().withDefault(const Constant(23))();
  IntColumn get dndStartMinute => integer().withDefault(const Constant(0))();
  IntColumn get dndEndHour => integer().withDefault(const Constant(7))();
  IntColumn get dndEndMinute => integer().withDefault(const Constant(0))();
  BoolColumn get dndEnabled => boolean().withDefault(const Constant(true))();
}
```

```dart
// lib/data/database/tables/drink_presets_table.dart
import 'package:drift/drift.dart';

class DrinkPresets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get amountMl => integer()();
  IntColumn get sortOrder => integer()();
}
```

### Pattern 3: AppDatabase with Migration Seeding

**What:** Single database class with schema v1 migration that seeds defaults.
**Source:** [CITED: drift.simonbinder.eu/setup/, drift.simonbinder.eu/migrations/]

```dart
// lib/data/database/app_database.dart
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'tables/water_entries_table.dart';
import 'tables/user_settings_table.dart';
import 'tables/drink_presets_table.dart';
import 'daos/water_entry_dao.dart';
import 'daos/user_settings_dao.dart';
import 'daos/drink_preset_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [WaterEntries, UserSettings, DrinkPresets],
  daos: [WaterEntryDao, UserSettingsDao, DrinkPresetDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'drinky_drinky',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Seed default settings (single row, id=1)
        await into(userSettings).insert(
          UserSettingsCompanion.insert(),
          // All columns have defaults, so empty insert works
        );
        // Seed default drink presets
        await batch((batch) {
          batch.insertAll(drinkPresets, [
            DrinkPresetsCompanion.insert(amountMl: 200, sortOrder: 0),
            DrinkPresetsCompanion.insert(amountMl: 300, sortOrder: 1),
            DrinkPresetsCompanion.insert(amountMl: 400, sortOrder: 2),
            DrinkPresetsCompanion.insert(amountMl: 500, sortOrder: 3),
          ]);
        });
      },
      beforeOpen: (details) async {
        // Enable foreign keys
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}
```

**Key insight:** The constructor accepts an optional `QueryExecutor` -- this is how in-memory testing works. Production code uses `_openConnection()` via the default; tests pass `NativeDatabase.memory()`.

### Pattern 4: DAO with @DriftAccessor

**What:** Modular query classes grouped by feature domain.
**Source:** [CITED: drift.simonbinder.eu/dart_api/daos/]

```dart
// lib/data/database/daos/water_entry_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/water_entries_table.dart';

part 'water_entry_dao.g.dart';

@DriftAccessor(tables: [WaterEntries])
class WaterEntryDao extends DatabaseAccessor<AppDatabase>
    with _$WaterEntryDaoMixin {
  WaterEntryDao(super.attachedDatabase);

  // Insert a new water entry
  Future<int> insertEntry(WaterEntriesCompanion entry) {
    return into(waterEntries).insert(entry);
  }

  // Watch all entries for a specific date_key
  Stream<List<WaterEntry>> watchEntriesForDate(String dateKey) {
    return (select(waterEntries)
          ..where((t) => t.dateKey.equals(dateKey))
          ..orderBy([(t) => OrderingTerm.asc(t.loggedAt)]))
        .watch();
  }

  // Get total ml for a date_key
  Stream<int> watchTotalForDate(String dateKey) {
    final totalMl = waterEntries.amountMl.sum();
    final query = selectOnly(waterEntries)
      ..addColumns([totalMl])
      ..where(waterEntries.dateKey.equals(dateKey));
    return query.watchSingle().map((row) => row.read(totalMl) ?? 0);
  }

  // Delete the most recent entry (for undo)
  Future<int> deleteLastEntry() async {
    final lastEntry = await (select(waterEntries)
          ..orderBy([(t) => OrderingTerm.desc(t.loggedAt)])
          ..limit(1))
        .getSingleOrNull();
    if (lastEntry == null) return 0;
    return (delete(waterEntries)
          ..where((t) => t.id.equals(lastEntry.id)))
        .go();
  }

  // Get entries for a date range (for calendar view)
  Stream<List<WaterEntry>> watchEntriesInRange(
      String startDateKey, String endDateKey) {
    return (select(waterEntries)
          ..where((t) =>
              t.dateKey.isBiggerOrEqualValue(startDateKey) &
              t.dateKey.isSmallerOrEqualValue(endDateKey)))
        .watch();
  }
}
```

```dart
// lib/data/database/daos/user_settings_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/user_settings_table.dart';

part 'user_settings_dao.g.dart';

@DriftAccessor(tables: [UserSettings])
class UserSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$UserSettingsDaoMixin {
  UserSettingsDao(super.attachedDatabase);

  // Watch the single settings row (id=1)
  Stream<UserSetting> watchSettings() {
    return (select(userSettings)..where((t) => t.id.equals(1)))
        .watchSingle();
  }

  // Get settings once
  Future<UserSetting> getSettings() {
    return (select(userSettings)..where((t) => t.id.equals(1)))
        .getSingle();
  }

  // Update settings (upsert pattern for single-row table)
  Future<void> updateSettings(UserSettingsCompanion settings) {
    return (update(userSettings)..where((t) => t.id.equals(1)))
        .write(settings);
  }
}
```

```dart
// lib/data/database/daos/drink_preset_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/drink_presets_table.dart';

part 'drink_preset_dao.g.dart';

@DriftAccessor(tables: [DrinkPresets])
class DrinkPresetDao extends DatabaseAccessor<AppDatabase>
    with _$DrinkPresetDaoMixin {
  DrinkPresetDao(super.attachedDatabase);

  // Watch all presets ordered by sortOrder
  Stream<List<DrinkPreset>> watchAllPresets() {
    return (select(drinkPresets)
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  // Update a preset's amount
  Future<void> updatePreset(int id, int amountMl) {
    return (update(drinkPresets)..where((t) => t.id.equals(id)))
        .write(DrinkPresetsCompanion(amountMl: Value(amountMl)));
  }
}
```

### Pattern 5: Freezed Domain Entities

**What:** Immutable domain models decoupled from Drift-generated row types.
**Source:** [CITED: pub.dev/packages/freezed]

```dart
// lib/domain/entities/water_entry.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'water_entry.freezed.dart';

@freezed
abstract class WaterEntryEntity with _$WaterEntryEntity {
  const factory WaterEntryEntity({
    required int id,
    required int amountMl,
    required DateTime loggedAt,
    required String dateKey,
  }) = _WaterEntryEntity;
}
```

```dart
// lib/domain/entities/daily_progress.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'water_entry.dart';

part 'daily_progress.freezed.dart';

@freezed
abstract class DailyProgress with _$DailyProgress {
  const factory DailyProgress({
    required int totalMl,
    required int targetMl,
    required List<WaterEntryEntity> entries,
    required String dateKey,
  }) = _DailyProgress;
}
```

```dart
// lib/domain/entities/user_settings_entity.dart
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
  }) = _UserSettingsEntity;
}
```

```dart
// lib/domain/entities/drink_preset_entity.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'drink_preset_entity.freezed.dart';

@freezed
abstract class DrinkPresetEntity with _$DrinkPresetEntity {
  const factory DrinkPresetEntity({
    required int id,
    required int amountMl,
    required int sortOrder,
  }) = _DrinkPresetEntity;
}
```

**Note on Freezed 3.x syntax:** The `@freezed` annotation now goes on `abstract class` with `_$ClassName` mixin. The old `class` (non-abstract) syntax is deprecated. [CITED: pub.dev/packages/freezed]

### Pattern 6: Repository (Stream Gateway)

**What:** Transform Drift rows into Freezed domain entities and expose reactive streams.
**Source:** [CITED: .planning/research/ARCHITECTURE.md]

```dart
// lib/data/repositories/water_repository.dart
import '../database/app_database.dart';
import '../../domain/entities/water_entry.dart';
import '../../domain/entities/daily_progress.dart';

class WaterRepository {
  final AppDatabase _db;
  WaterRepository(this._db);

  Stream<List<WaterEntryEntity>> watchEntriesForDate(String dateKey) {
    return _db.waterEntryDao.watchEntriesForDate(dateKey).map(
      (rows) => rows
          .map((r) => WaterEntryEntity(
                id: r.id,
                amountMl: r.amountMl,
                loggedAt: r.loggedAt,
                dateKey: r.dateKey,
              ))
          .toList(),
    );
  }

  Future<void> insertEntry(int amountMl, DateTime loggedAt, String dateKey) {
    return _db.waterEntryDao.insertEntry(
      WaterEntriesCompanion.insert(
        amountMl: amountMl,
        loggedAt: loggedAt,
        dateKey: dateKey,
      ),
    );
  }

  Future<int> deleteLastEntry() => _db.waterEntryDao.deleteLastEntry();

  Stream<int> watchTotalForDate(String dateKey) {
    return _db.waterEntryDao.watchTotalForDate(dateKey);
  }
}
```

### Pattern 7: Riverpod Providers (Code-Gen)

**What:** Wire database, repositories, and streams into the Riverpod provider graph.
**Source:** [CITED: riverpod.dev/docs/concepts/about_code_generation]

```dart
// lib/core/providers/database_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/database/app_database.dart';

part 'database_provider.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
}
```

```dart
// lib/core/providers/repository_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/water_repository.dart';
import '../../data/repositories/settings_repository.dart';
import 'database_provider.dart';

part 'repository_providers.g.dart';

@Riverpod(keepAlive: true)
WaterRepository waterRepository(Ref ref) {
  return WaterRepository(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) {
  return SettingsRepository(ref.watch(appDatabaseProvider));
}
```

```dart
// lib/core/providers/stream_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/water_entry.dart';
import '../../domain/entities/user_settings_entity.dart';
import '../../domain/entities/drink_preset_entity.dart';
import 'repository_providers.dart';

part 'stream_providers.g.dart';

// keepAlive: true to avoid state loss on navigation (Pitfall 7)
@Riverpod(keepAlive: true)
Stream<List<WaterEntryEntity>> todayWaterEntries(Ref ref) {
  final repo = ref.watch(waterRepositoryProvider);
  final today = _todayDateKey();
  return repo.watchEntriesForDate(today);
}

@Riverpod(keepAlive: true)
Stream<int> todayTotalMl(Ref ref) {
  final repo = ref.watch(waterRepositoryProvider);
  return repo.watchTotalForDate(_todayDateKey());
}

@Riverpod(keepAlive: true)
Stream<UserSettingsEntity> userSettings(Ref ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watchSettings();
}

@Riverpod(keepAlive: true)
Stream<List<DrinkPresetEntity>> drinkPresets(Ref ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watchPresets();
}

String _todayDateKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}
```

**Key insight on keepAlive:** Core data providers use `@Riverpod(keepAlive: true)` to prevent autoDispose from killing state during navigation. This directly addresses Pitfall 7 from PITFALLS.md. [CITED: .planning/research/PITFALLS.md pitfall 7]

### Pattern 8: GoRouter Minimal Setup

**What:** Define 3 routes as skeleton for subsequent phases.
**Source:** [CITED: pub.dev/packages/go_router -- GoRouter class documentation]

```dart
// lib/core/router/app_router.dart
import 'package:go_router/go_router.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/history_screen.dart';
import '../../presentation/screens/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
```

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: DrinkyDrinkyApp(),
    ),
  );
}

class DrinkyDrinkyApp extends StatelessWidget {
  const DrinkyDrinkyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Drinky Drinky',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
```

### Anti-Patterns to Avoid

- **Watching Drift streams directly in widgets via StreamBuilder:** Bypasses Riverpod caching. Always wrap in StreamProvider. [CITED: .planning/research/ARCHITECTURE.md]
- **God Database Class:** Never put queries in AppDatabase. Use @DriftAccessor DAOs. [CITED: .planning/research/ARCHITECTURE.md]
- **Multiple Database Instances:** SQLite file locking prevents this. Single instance via provider. [CITED: .planning/research/ARCHITECTURE.md]
- **ref.read() in build methods:** Always use ref.watch() in build. ref.read() only in callbacks. [CITED: .planning/research/PITFALLS.md pitfall 6]
- **autoDispose on core providers:** Do not autoDispose database, repository, or core stream providers. [CITED: .planning/research/PITFALLS.md pitfall 7]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Immutable data classes | Manual equality, copyWith, toString | Freezed @freezed | 50+ lines of boilerplate per class; error-prone equality |
| Provider type selection | Manual Provider/StreamProvider/etc | @riverpod code-gen | Generator picks correct type automatically |
| SQLite setup per platform | Manual platform checks + sqlite3 wiring | drift_flutter driftDatabase() | Handles iOS/Android/web SQLite automatically |
| Database file location | Manual path computation | path_provider + driftDatabase() | Correct app directory per platform |
| Date key formatting | Inline date string formatting | Utility function _todayDateKey() | Consistent YYYY-MM-DD format everywhere |

## Common Pitfalls

### Pitfall 1: Missing build.yaml Before First Code Generation
**What goes wrong:** Drift generates code with Unix timestamp storage mode (the default). After data is written, switching to text mode requires a data migration.
**Why it happens:** Developers create tables first, run build_runner, then realize they need ISO-8601 storage.
**How to avoid:** Create build.yaml with `store_date_time_values_as_text: true` BEFORE writing any Drift table class. This is the very first file after `flutter create`.
**Warning signs:** If build.yaml does not exist when `dart run build_runner build` is first run, the default mode is locked in.
**Confidence:** HIGH [CITED: drift.simonbinder.eu/generation_options/]

### Pitfall 2: beforeOpen Runs Every Launch, Not Just on Creation
**What goes wrong:** Seed data (default presets, default settings) is duplicated on every app launch because the developer puts inserts in `beforeOpen` without checking `details.wasCreated`.
**Why it happens:** `beforeOpen` fires on every database open, not just during creation.
**How to avoid:** Put seed inserts inside `MigrationStrategy.onCreate`, or guard with `details.wasCreated` in `beforeOpen`.
**Warning signs:** Duplicate drink presets appearing after app restart.
**Confidence:** HIGH [CITED: drift.simonbinder.eu/migrations/, .planning/research/PITFALLS.md pitfall 15]

### Pitfall 3: Drift Generated Type Name Collisions
**What goes wrong:** The Drift-generated row class for `UserSettings` table is called `UserSetting` (singular). If the Freezed domain entity is also called `UserSettings`, import conflicts arise.
**Why it happens:** Drift auto-generates row classes by singularizing the table name.
**How to avoid:** Name the Freezed domain entity `UserSettingsEntity` (suffix with `Entity`) to distinguish from the Drift-generated `UserSetting` row class. Same for `WaterEntryEntity` vs Drift's `WaterEntry`, and `DrinkPresetEntity` vs `DrinkPreset`.
**Warning signs:** Import ambiguity errors during code generation.
**Confidence:** HIGH [ASSUMED -- standard Dart naming collision prevention]

### Pitfall 4: Forgetting part Directives for Code Generation
**What goes wrong:** build_runner produces no output or cryptic errors because the `part 'filename.g.dart'` or `part 'filename.freezed.dart'` directive is missing.
**Why it happens:** Three different code generators (Drift, Riverpod, Freezed) all need different part file patterns in different files.
**How to avoid:** 
  - Drift tables: `part 'filename.g.dart'` in the database file and each DAO file
  - Freezed entities: `part 'filename.freezed.dart'` (no `.g.dart` unless using JSON)
  - Riverpod providers: `part 'filename.g.dart'` in each provider file
**Warning signs:** build_runner completes with 0 outputs or "no output" warnings.
**Confidence:** HIGH [CITED: pub.dev/packages/freezed, riverpod.dev]

### Pitfall 5: UserSettings Companion Insert Requires Explicit Handling
**What goes wrong:** `UserSettingsCompanion.insert()` may fail if columns without defaults exist, or the developer forgets that `id` auto-increments and tries to specify it.
**Why it happens:** Drift's `.insert()` named constructor requires all non-defaulted, non-autoincrement columns.
**How to avoid:** Ensure ALL columns in UserSettings either autoIncrement (id) or have withDefault(). Then `UserSettingsCompanion.insert()` with no arguments works.
**Warning signs:** Compile errors on seed insert in migration.
**Confidence:** HIGH [CITED: drift.simonbinder.eu/dart_api/writes/]

### Pitfall 6: iOS Minimum Version Not Set in Podfile
**What goes wrong:** iOS build fails because the Podfile still has `platform :ios, '12.0'` (Flutter default) but the user requires iOS 16.0 (D-02).
**Why it happens:** `flutter create` sets a default minimum iOS version that may be lower than required.
**How to avoid:** After `flutter create`, edit `ios/Podfile` to set `platform :ios, '16.0'`. Also update `ios/Runner.xcodeproj/project.pbxproj` IPHONEOS_DEPLOYMENT_TARGET to 16.0.
**Warning signs:** Pod install errors or runtime crashes on older iOS versions.
**Confidence:** HIGH [ASSUMED -- standard Flutter iOS deployment target configuration]

## Code Examples

All verified patterns are included inline in the Architecture Patterns section above. The key code files for Phase 1 are:

1. `build.yaml` -- Pattern 1
2. `lib/data/database/tables/*.dart` -- Pattern 2
3. `lib/data/database/app_database.dart` -- Pattern 3
4. `lib/data/database/daos/*.dart` -- Pattern 4
5. `lib/domain/entities/*.dart` -- Pattern 5
6. `lib/data/repositories/*.dart` -- Pattern 6
7. `lib/core/providers/*.dart` -- Pattern 7
8. `lib/core/router/app_router.dart` + `lib/main.dart` -- Pattern 8

## Testing Approach

### In-Memory Database Testing

**Source:** [CITED: drift.simonbinder.eu/testing/]

Drift supports creating an in-memory SQLite database for fast, isolated unit tests. The AppDatabase constructor accepts an optional `QueryExecutor`, which tests can substitute with `NativeDatabase.memory()`.

```dart
// test/data/database/daos/water_entry_dao_test.dart
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

  group('WaterEntryDao', () {
    test('inserts and watches entries for a date', () async {
      await db.waterEntryDao.insertEntry(
        WaterEntriesCompanion.insert(
          amountMl: 250,
          loggedAt: DateTime(2026, 6, 3, 10, 30),
          dateKey: '2026-06-03',
        ),
      );

      final entries = await db.waterEntryDao
          .watchEntriesForDate('2026-06-03')
          .first;
      expect(entries, hasLength(1));
      expect(entries.first.amountMl, 250);
    });

    test('watchTotalForDate aggregates correctly', () async {
      await db.waterEntryDao.insertEntry(
        WaterEntriesCompanion.insert(
          amountMl: 200,
          loggedAt: DateTime(2026, 6, 3, 8, 0),
          dateKey: '2026-06-03',
        ),
      );
      await db.waterEntryDao.insertEntry(
        WaterEntriesCompanion.insert(
          amountMl: 300,
          loggedAt: DateTime(2026, 6, 3, 9, 0),
          dateKey: '2026-06-03',
        ),
      );

      final total = await db.waterEntryDao
          .watchTotalForDate('2026-06-03')
          .first;
      expect(total, 500);
    });

    test('deleteLastEntry removes most recent entry', () async {
      await db.waterEntryDao.insertEntry(
        WaterEntriesCompanion.insert(
          amountMl: 200,
          loggedAt: DateTime(2026, 6, 3, 8, 0),
          dateKey: '2026-06-03',
        ),
      );
      await db.waterEntryDao.insertEntry(
        WaterEntriesCompanion.insert(
          amountMl: 300,
          loggedAt: DateTime(2026, 6, 3, 9, 0),
          dateKey: '2026-06-03',
        ),
      );

      await db.waterEntryDao.deleteLastEntry();

      final entries = await db.waterEntryDao
          .watchEntriesForDate('2026-06-03')
          .first;
      expect(entries, hasLength(1));
      expect(entries.first.amountMl, 200);
    });
  });

  group('UserSettingsDao', () {
    test('default settings are seeded on creation', () async {
      final settings = await db.userSettingsDao.getSettings();
      expect(settings.dailyTargetMl, 2000);
      expect(settings.notificationIntervalMinutes, 60);
      expect(settings.dndStartHour, 23);
      expect(settings.dndEndHour, 7);
      expect(settings.dndEnabled, true);
    });

    test('updates settings', () async {
      await db.userSettingsDao.updateSettings(
        UserSettingsCompanion(dailyTargetMl: Value(2500)),
      );
      final settings = await db.userSettingsDao.getSettings();
      expect(settings.dailyTargetMl, 2500);
    });
  });

  group('DrinkPresetDao', () {
    test('default presets are seeded on creation', () async {
      final presets = await db.drinkPresetDao.watchAllPresets().first;
      expect(presets, hasLength(4));
      expect(presets.map((p) => p.amountMl), [200, 300, 400, 500]);
    });
  });
}
```

**Important:** The `closeStreamsSynchronously: true` parameter prevents "timer after test" errors in flutter_test. [CITED: drift.simonbinder.eu/testing/]

**Required test dependency:** `drift/native.dart` is needed for `NativeDatabase.memory()`. This import comes from the `drift` package itself -- no additional test packages needed.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| sqlite3_flutter_libs | drift_flutter | 2024 | drift_flutter wraps setup; sqlite3_flutter_libs is EOL |
| Manual provider types | @riverpod code-gen | Riverpod 3.x (2024) | Generator picks correct type; part file is .g.dart |
| freezed class (non-abstract) | freezed abstract class | Freezed 3.x (2025) | Must use `abstract class` with `_$Mixin` pattern |
| GoRouter 12.x-14.x | GoRouter 17.x | 2026 | Requires Flutter 3.38+, Dart 3.10+ |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Drift singularizes table names for generated row classes (e.g., WaterEntries -> WaterEntry) | Pitfall 3 | Naming conflicts between Drift rows and Freezed entities; low risk -- easily fixed by adjusting entity names |
| A2 | iOS Podfile default minimum is lower than 16.0 after flutter create | Pitfall 6 | Build might work without manual change if Flutter now defaults to iOS 16; verify after create |
| A3 | go_router ^17.3.0 is compatible with flutter_riverpod ^3.3.1 | Standard Stack | Version conflict at pub get; resolvable by pinning a compatible version |
| A4 | UserSettingsCompanion.insert() with no arguments works when all columns have defaults or autoIncrement | Pitfall 5 | Compile error on migration seed; verify generated code |
| A5 | Android minSdk 26 is compatible with all Phase 1 packages (drift_flutter, go_router) | Standard Stack | Build failure; resolvable by checking package constraints |

## Open Questions

1. **Android build.gradle configuration for Drift**
   - What we know: drift_flutter handles SQLite setup automatically
   - What's unclear: Whether Android API 26 needs any additional build.gradle changes for drift_flutter (compileSdk, desugaring)
   - Recommendation: After flutter create, verify android/app/build.gradle has `minSdk: 26` and `compileSdk: 36` (matching Phase 5 notification requirements is fine to set now)

2. **Exact iOS deployment target update mechanism**
   - What we know: Podfile and project.pbxproj both need updating
   - What's unclear: Whether flutter create with current Flutter SDK already sets iOS 16+ as default
   - Recommendation: Check after flutter create; update if needed

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | Everything | Not detected | -- | Must be installed |
| Dart SDK | Code generation | Not detected | -- | Comes with Flutter |
| Xcode | iOS build | Not verified | -- | Cannot build iOS without it |
| Android SDK | Android build | Not verified | -- | Cannot build Android without it |

**Missing dependencies with no fallback:**
- Flutter SDK not detected in PATH. Must be installed and in PATH before any Phase 1 work begins. The planner should include a verification step.

**Note:** This machine may have Flutter installed but not in the current shell PATH. The developer's environment likely has it available.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | No auth in offline app |
| V3 Session Management | No | No sessions |
| V4 Access Control | No | Single-user app |
| V5 Input Validation | Yes | Drift type-safe columns enforce INTEGER/TEXT types; validate amountMl > 0 in repository |
| V6 Cryptography | No | No encrypted data in v1 |

### Known Threat Patterns for Drift/SQLite

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SQL injection via raw queries | Tampering | Use Drift type-safe API exclusively; never use customStatement with user input |
| Database file access on rooted device | Information Disclosure | Acceptable risk for v1 hydration data; SQLCipher via drift_flutter if needed later |

**Security assessment:** Phase 1 has minimal security surface. The primary control is using Drift's type-safe API (no raw SQL with user input). Input validation (amountMl > 0, dateKey format) should be enforced at the repository layer.

## Sources

### Primary (HIGH confidence)
- drift.simonbinder.eu/setup/ -- AppDatabase pattern, driftDatabase() usage
- drift.simonbinder.eu/generation_options/ -- build.yaml store_date_time_values_as_text
- drift.simonbinder.eu/migrations/ -- MigrationStrategy, onCreate, beforeOpen
- drift.simonbinder.eu/dart_api/tables/ -- Table definitions, column types, @TableIndex
- drift.simonbinder.eu/dart_api/daos/ -- @DriftAccessor pattern, .watch()
- drift.simonbinder.eu/dart_api/writes/ -- Insert, update, upsert, Companion pattern
- drift.simonbinder.eu/dart_api/select/ -- Select, where, watchSingle, aggregate
- drift.simonbinder.eu/testing/ -- NativeDatabase.memory(), closeStreamsSynchronously
- pub.dev/packages/drift -- v2.33.0 confirmed
- pub.dev/packages/drift_flutter -- v0.3.0 confirmed
- pub.dev/packages/flutter_riverpod -- v3.3.1 confirmed latest stable
- pub.dev/packages/freezed -- v3.2.5 confirmed, abstract class syntax
- pub.dev/packages/go_router -- v17.3.0 confirmed, requires Flutter 3.38+/Dart 3.10+
- riverpod.dev/docs/concepts/about_code_generation -- @riverpod, Stream provider, keepAlive

### Secondary (MEDIUM confidence)
- .planning/research/STACK.md -- Package versions previously verified against pub.dev
- .planning/research/ARCHITECTURE.md -- Layer architecture, data flow patterns
- .planning/research/PITFALLS.md -- 15 documented pitfalls with prevention strategies

### Tertiary (LOW confidence)
- None -- all claims verified or cited

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all versions verified against pub.dev within this session
- Architecture: HIGH -- patterns verified against official Drift, Riverpod, and Freezed documentation
- Pitfalls: HIGH -- documented in official sources and cross-referenced with .planning/research/PITFALLS.md
- Testing: HIGH -- Drift testing pattern verified against drift.simonbinder.eu/testing/

**Research date:** 2026-06-03
**Valid until:** 2026-07-03 (30 days -- stable ecosystem, no breaking changes expected)
