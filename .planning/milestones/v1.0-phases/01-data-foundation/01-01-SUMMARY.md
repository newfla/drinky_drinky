---
phase: 01-data-foundation
plan: 01
subsystem: database
tags: [drift, riverpod, freezed, go_router, sqlite, flutter]

requires:
  - phase: none
    provides: greenfield project

provides:
  - AppDatabase with 3 tables (water_entries, user_settings, drink_presets) and migration seeding
  - Type-safe DAOs with reactive watch() streams for all tables
  - Freezed domain entities decoupled from Drift row types
  - WaterRepository and SettingsRepository mapping Drift rows to domain entities
  - Riverpod providers with keepAlive wiring DB through repositories to streams
  - GoRouter with 3-route navigation skeleton (/, /history, /settings)
  - ProviderScope + MaterialApp.router app entry point

affects: [02-core-tracking-ui, 03-settings, 04-calendar-streaks, 05-notifications]

tech-stack:
  added: [drift 2.33.0, drift_flutter 0.3.0, flutter_riverpod 3.3.1, riverpod_annotation 4.0.2, riverpod_generator 4.0.4-dev.1, go_router 17.3.0, freezed 3.2.6-dev.1, freezed_annotation 3.1.0, json_annotation 4.12.0, path_provider 2.1.5, build_runner 2.15.0, drift_dev 2.33.0]
  patterns: [layer-first folder structure, DAO pattern with @DriftAccessor, repository pattern (Drift -> Freezed mapping), keepAlive providers for core data, code-gen providers with @Riverpod, dateKey column for local date aggregation]

key-files:
  created:
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
  modified:
    - pubspec.yaml
    - android/app/build.gradle.kts
    - ios/Runner.xcodeproj/project.pbxproj
    - test/widget_test.dart

key-decisions:
  - "Upgraded Flutter from 3.38.1 to 3.44.1 to resolve analyzer version conflict between drift_dev and riverpod_generator"
  - "Excluded riverpod_lint and custom_lint due to analyzer version incompatibility with drift_dev 2.33.0 (custom_lint requires analyzer ^8.0.0, drift_dev requires >=10.0.0)"
  - "Added input validation in WaterRepository per threat model T-01-01 (amountMl > 0) and T-01-02 (dateKey YYYY-MM-DD format)"

patterns-established:
  - "Layer-first folder structure: lib/data/, lib/domain/, lib/presentation/, lib/core/"
  - "DAO pattern: @DriftAccessor classes encapsulate all SQL queries"
  - "Repository pattern: Drift row -> Freezed domain entity mapping at repository boundary"
  - "Provider pattern: @Riverpod(keepAlive: true) for database, repository, and stream providers"
  - "DateKey pattern: YYYY-MM-DD text column for local date aggregation queries"
  - "Migration seeding: default values inserted in MigrationStrategy.onCreate"

requirements-completed: []

duration: 19min
completed: 2026-06-03
---

# Phase 1 Plan 01: Data Foundation Walking Skeleton Summary

**Drift database with 3 tables, reactive DAOs, Freezed domain entities, Riverpod provider graph, and GoRouter navigation skeleton wired end-to-end**

## Performance

- **Duration:** 19 min
- **Started:** 2026-06-03T14:31:59Z
- **Completed:** 2026-06-03T14:51:09Z
- **Tasks:** 3
- **Files modified:** 104

## Accomplishments
- Complete Drift schema with water_entries (indexed by dateKey), user_settings (single-row with all defaults), and drink_presets tables
- DAOs with reactive watch() streams, CRUD operations, and aggregate queries (watchTotalForDate)
- Repositories mapping Drift rows to Freezed domain entities with input validation (amountMl > 0, dateKey format)
- Riverpod provider graph: appDatabase -> repositories -> stream providers, all with keepAlive: true
- GoRouter serving 3 routes with placeholder screens, main.dart with ProviderScope + MaterialApp.router
- flutter analyze passes with 0 errors, build_runner generates all .g.dart and .freezed.dart files

## Task Commits

Each task was committed atomically:

1. **Task 1: Scaffold Flutter project with critical Drift config and all dependencies** - `345a5a0` (chore)
2. **Task 2: Implement Drift schema, DAOs, Freezed entities, and run code generation** - `5bd50d7` (feat)
3. **Task 3: Wire repositories, Riverpod providers, GoRouter, and main.dart** - `416a96e` (feat)

## Files Created/Modified

- `build.yaml` - Drift code generation config with store_date_time_values_as_text: true
- `pubspec.yaml` - All Phase 1 dependencies (Drift, Riverpod, GoRouter, Freezed, etc.)
- `android/app/build.gradle.kts` - compileSdk 36, minSdk 26
- `ios/Runner.xcodeproj/project.pbxproj` - IPHONEOS_DEPLOYMENT_TARGET 16.0
- `lib/data/database/tables/*.dart` - 3 Drift table definitions
- `lib/data/database/app_database.dart` - AppDatabase with schema v1 migration seeding
- `lib/data/database/daos/*.dart` - 3 DAOs with watch streams and CRUD
- `lib/domain/entities/*.dart` - 4 Freezed domain entities
- `lib/data/repositories/water_repository.dart` - Drift -> WaterEntryEntity mapping with validation
- `lib/data/repositories/settings_repository.dart` - Drift -> UserSettingsEntity/DrinkPresetEntity mapping
- `lib/core/providers/database_provider.dart` - AppDatabase singleton provider with keepAlive
- `lib/core/providers/repository_providers.dart` - Water and Settings repository providers
- `lib/core/providers/stream_providers.dart` - 4 stream providers for today's data and settings
- `lib/core/router/app_router.dart` - GoRouter with /, /history, /settings routes
- `lib/presentation/screens/*.dart` - 3 placeholder screens
- `lib/main.dart` - ProviderScope + MaterialApp.router entry point

## Decisions Made
- Upgraded Flutter from 3.38.1 to 3.44.1 -- the version specified in CLAUDE.md (>= 3.38.1) was incompatible with drift_dev 2.33.0 and riverpod_generator 4.0.3 due to analyzer version conflicts. Flutter 3.44.1 (Dart 3.12.1) resolves all dependencies.
- Excluded riverpod_lint and custom_lint from dev_dependencies -- no version of custom_lint exists that is compatible with drift_dev's analyzer >=10.0.0 requirement. These are optional lint tools and do not affect runtime or code generation.
- Added input validation in WaterRepository.insertEntry() per the plan's threat model (T-01-01: amountMl > 0, T-01-02: dateKey YYYY-MM-DD regex).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Upgraded Flutter SDK from 3.38.1 to 3.44.1**
- **Found during:** Task 1 (Flutter project scaffold)
- **Issue:** Flutter 3.38.1 (Dart 3.10.0) had analyzer version conflicts: drift_dev requires analyzer >=10.0.0, riverpod_generator requires analyzer ^9.0.0 (stable) or ^12.0.0 (dev), and flutter_test pinned meta 1.17.0 incompatible with analyzer 12.x.
- **Fix:** Installed Flutter 3.44.1 via FVM, which ships Dart 3.12.1 and resolves all dependencies.
- **Files modified:** .fvmrc (auto-generated by FVM)
- **Verification:** flutter pub get succeeds, all packages resolve
- **Committed in:** 345a5a0

**2. [Rule 3 - Blocking] Removed riverpod_lint and custom_lint**
- **Found during:** Task 1 (dependency resolution)
- **Issue:** No version of custom_lint (maxes out at analyzer ^8.0.0) is compatible with drift_dev 2.33.0 (requires analyzer >=10.0.0). This is an ecosystem-wide version conflict.
- **Fix:** Excluded both packages with a comment explaining the conflict. They are optional linting tools and do not affect runtime behavior.
- **Files modified:** pubspec.yaml
- **Verification:** flutter pub get succeeds, flutter analyze passes with 0 errors
- **Committed in:** 345a5a0

**3. [Rule 2 - Missing Critical] Added input validation in WaterRepository**
- **Found during:** Task 3 (repository implementation)
- **Issue:** Plan's threat model specified T-01-01 (validate amountMl > 0) and T-01-02 (validate dateKey YYYY-MM-DD) with "mitigate" disposition.
- **Fix:** Added ArgumentError validation in WaterRepository.insertEntry() for both fields.
- **Files modified:** lib/data/repositories/water_repository.dart
- **Verification:** Validation code present and throws on invalid input
- **Committed in:** 416a96e

---

**Total deviations:** 3 auto-fixed (2 blocking, 1 missing critical)
**Impact on plan:** All auto-fixes necessary for correctness and functionality. No scope creep. The Flutter SDK upgrade and lint exclusion are documented for future reference when versions align.

## Issues Encountered
- Flutter 3.38.1 (November 2025) was the only SDK version available via FVM initially, but its pinned meta 1.17.0 prevented resolving the analyzer dependency tree. Upgrading to Flutter 3.44.1 (June 2026) resolved all conflicts cleanly.
- No Podfile was generated by flutter create since no native plugins were initially included. This is expected and the Podfile will be generated automatically when flutter build ios or pod install runs (drift_flutter and go_router have native dependencies that trigger CocoaPods integration).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- All Drift tables, DAOs, and repositories are ready for Phase 2 (Core Tracking UI) to consume
- Stream providers expose reactive data flows that widgets can ref.watch()
- GoRouter routes are in place for Phase 2 to populate with real screens
- AppDatabase constructor accepts optional QueryExecutor, ready for Plan 02 (DAO unit tests)
- The only concern is that riverpod_lint is unavailable, so Riverpod best practices must be manually enforced

## Self-Check: PASSED

- All 22 created files verified present on disk
- All 3 task commits verified in git log (345a5a0, 5bd50d7, 416a96e)

---
*Phase: 01-data-foundation*
*Completed: 2026-06-03*
