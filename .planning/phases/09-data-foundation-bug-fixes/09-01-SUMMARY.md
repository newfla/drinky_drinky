---
phase: 09-data-foundation-bug-fixes
plan: 01
subsystem: database
tags: [drift, sqlite, target-history, dao, upsert, seed]

# Dependency graph
requires:
  - phase: 04-data-persistence
    provides: Drift schema with WaterEntries, UserSettings, DrinkPresets tables and DAOs
provides:
  - TargetHistory table in initial Drift schema (id, effectiveDate UNIQUE, targetMl)
  - TargetHistoryDao with getTargetForDate, watchAll, insertOrReplace methods
  - Seed row in onCreate (today's date, 2000 ml default)
affects: [10-target-history-integration, 11-hydration-calculator]

# Tech tracking
tech-stack:
  added: []
  patterns: [DoUpdate with explicit target for non-PK UNIQUE upsert, text().unique() for single-column constraint]

key-files:
  created:
    - lib/data/database/tables/target_history_table.dart
    - lib/data/database/daos/target_history_dao.dart
    - lib/data/database/daos/target_history_dao.g.dart
  modified:
    - lib/data/database/app_database.dart
    - lib/data/database/app_database.g.dart

key-decisions:
  - "Used text().unique() for effectiveDate UNIQUE constraint (simpler than uniqueKeys override for single-column)"
  - "Used DoUpdate with target: [targetHistory.effectiveDate] for upsert (insertOnConflictUpdate only detects PK conflicts)"
  - "Inlined todayKey date formatting in onCreate to avoid circular dependency on providers layer"

patterns-established:
  - "DoUpdate upsert pattern: use explicit target parameter when UNIQUE column differs from PK"
  - "Seed row pattern: compute todayKey inline in onCreate using DateTime.now() formatted as YYYY-MM-DD"

requirements-completed: [TARGET-01]

# Metrics
duration: 3min
completed: 2026-06-10
---

# Phase 9 Plan 01: Target History Table & DAO Summary

**Drift target_history table with UNIQUE effectiveDate, DAO with getTargetForDate/watchAll/insertOrReplace, and seed row in onCreate**

## Performance

- **Duration:** 3 min
- **Started:** 2026-06-10T10:24:41Z
- **Completed:** 2026-06-10T10:27:45Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- TargetHistory table added to initial Drift schema with id (autoIncrement), effectiveDate (text, UNIQUE), targetMl (integer)
- TargetHistoryDao delivers 3 methods: getTargetForDate (WHERE <= ORDER BY DESC LIMIT 1), watchAll (stream ASC), insertOrReplace (DoUpdate with target on effectiveDate)
- Seed row inserted in onCreate with today's date and 2000 ml default, matching UserSettings.dailyTargetMl
- Code-gen completed with zero dart analyze issues

## Task Commits

Each task was committed atomically:

1. **Task 1: Define TargetHistory table and DAO** - `1a5791d` (feat)
2. **Task 2: Register table, add seed, run code-gen** - `bc537e9` (feat)

## Files Created/Modified
- `lib/data/database/tables/target_history_table.dart` - TargetHistory table with 3 columns (id, effectiveDate UNIQUE, targetMl)
- `lib/data/database/daos/target_history_dao.dart` - DAO with getTargetForDate, watchAll, insertOrReplace
- `lib/data/database/daos/target_history_dao.g.dart` - Generated DAO mixin
- `lib/data/database/app_database.dart` - Registered TargetHistory table + DAO, added seed row in onCreate
- `lib/data/database/app_database.g.dart` - Regenerated schema with $TargetHistoryTable, TargetHistoryData, TargetHistoryCompanion

## Decisions Made
- Used `text().unique()` column modifier for effectiveDate (simpler than `uniqueKeys` override for single-column constraint)
- Used `DoUpdate` with `target: [targetHistory.effectiveDate]` for upsert instead of `insertOnConflictUpdate` (which only detects PK conflicts on auto-increment id)
- Inlined `todayKey` date formatting in `onCreate` rather than importing `todayDateKey()` from providers layer (avoids circular dependency database -> providers)
- schemaVersion kept at 1 (first real installation, no migration needed)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- TargetHistory table and DAO are ready for Phase 10 to wire up `updateTargetWithHistory()` repository method
- Phase 10 can build `effectiveTargetForDateProvider` using `TargetHistoryDao.getTargetForDate()`
- Phase 11 hydration calculator can consume target history through providers

---
*Phase: 09-data-foundation-bug-fixes*
*Completed: 2026-06-10*
