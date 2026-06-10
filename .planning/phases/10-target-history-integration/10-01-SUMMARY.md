---
phase: 10-target-history-integration
plan: "01"
subsystem: data-layer
tags: [drift, repository, entity, code-gen, target-history]
dependency_graph:
  requires: [09-01, 09-02]
  provides: [watchTargetForDate-stream, applyFromTomorrow-column, updateTargetWithHistory-method]
  affects: [settings_repository, target_history_dao, user_settings_table, user_settings_entity]
tech_stack:
  added: []
  patterns: [drift-watchSingleOrNull-stream, dual-write-repository-method, freezed-field-extension]
key_files:
  created: []
  modified:
    - lib/data/database/tables/user_settings_table.dart
    - lib/data/database/daos/target_history_dao.dart
    - lib/data/database/daos/user_settings_dao.dart
    - lib/domain/entities/user_settings_entity.dart
    - lib/data/repositories/settings_repository.dart
    - lib/data/database/app_database.g.dart
    - lib/domain/entities/user_settings_entity.freezed.dart
decisions:
  - "applyFromTomorrow stored as Drift BoolColumn with withDefault(Constant(false)) — no schema migration needed (schemaVersion stays 1)"
  - "updateTargetWithHistory uses sequential awaits (no transaction) — SQLite serializes writes, consistent with D-06"
  - "effectiveDate computed inline in repository from DateTime.now() — avoids injecting clock dependency for a utility app"
  - "ArgumentError on newTargetMl <= 0 mitigates T-10-01 tampering threat before any writes"
metrics:
  duration: "2 minutes"
  completed: "2026-06-10"
  tasks_completed: 2
  tasks_total: 2
  files_changed: 7
---

# Phase 10 Plan 01: Data Layer Extension for Target History Summary

**One-liner:** Added `applyFromTomorrow` column to UserSettings, `watchTargetForDate(dateKey)` stream to TargetHistoryDao, and `updateTargetWithHistory(newTargetMl)` dual-write method to SettingsRepository — all propagated through entity and repository mappings with code-gen and clean analyze.

## What Was Built

### Task 1: Schema extension and DAO stream method

- Added `BoolColumn get applyFromTomorrow` to `UserSettings` Drift table with `withDefault(const Constant(false))`, following the same pattern as `dndEnabled`
- Added `Stream<int?> watchTargetForDate(String dateKey)` to `TargetHistoryDao` — mirrors `getTargetForDate` query logic but uses `.watchSingleOrNull()` and `.map((row) => row?.targetMl)` for reactive streaming
- Updated `UserSettingsDao._defaultSettings()` to include `applyFromTomorrow: false` for consistency when the id=1 row is absent

### Task 2: Entity, repository mappings, updateTargetWithHistory, and code-gen

- Added `required bool applyFromTomorrow` field to `UserSettingsEntity` freezed factory constructor
- Updated all three `SettingsRepository` entity mappings to include `applyFromTomorrow`:
  - `watchSettings()` mapping: `applyFromTomorrow: row.applyFromTomorrow`
  - `getSettings()` mapping: `applyFromTomorrow: row.applyFromTomorrow`
  - `updateSettings()` companion: `applyFromTomorrow: Value(entity.applyFromTomorrow)`
- Added `Future<void> updateTargetWithHistory(int newTargetMl)` dual-write method:
  - Validates `newTargetMl > 0` (ArgumentError, T-10-01 mitigation)
  - Reads `currentSettings.applyFromTomorrow` to compute `effectiveDate` (today or tomorrow as YYYY-MM-DD)
  - Calls `targetHistoryDao.insertOrReplace(effectiveDate, newTargetMl)` for upsert
  - Calls `userSettingsDao.updateSettings(UserSettingsCompanion(dailyTargetMl: Value(newTargetMl)))` to keep settings in sync
- Ran `dart run build_runner build --delete-conflicting-outputs` — 85 outputs written, 0 errors
- `dart analyze` — no issues found
- Full test suite: 23 tests pass (7 TargetHistoryDao tests + all others)

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 1 | 2304f60 | feat(10-01): add applyFromTomorrow column and watchTargetForDate stream method |
| Task 2 | 8509497 | feat(10-01): add applyFromTomorrow to entity, repository mappings and updateTargetWithHistory |

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None — `updateTargetWithHistory` introduces a new write path at the Settings UI -> Repository boundary, already identified and mitigated in the plan's threat model as T-10-01 (ArgumentError validation before writes).

## Self-Check: PASSED

- [x] `lib/data/database/tables/user_settings_table.dart` — contains `applyFromTomorrow` column
- [x] `lib/data/database/daos/target_history_dao.dart` — contains `watchTargetForDate` method
- [x] `lib/data/database/daos/user_settings_dao.dart` — `_defaultSettings()` includes `applyFromTomorrow: false`
- [x] `lib/domain/entities/user_settings_entity.dart` — contains `required bool applyFromTomorrow`
- [x] `lib/data/repositories/settings_repository.dart` — all three mappings updated; `updateTargetWithHistory` present
- [x] Commit 2304f60 exists — `git log --oneline | grep 2304f60`
- [x] Commit 8509497 exists — `git log --oneline | grep 8509497`
- [x] `dart analyze` — no issues
- [x] 23 tests pass
