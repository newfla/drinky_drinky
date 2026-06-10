---
phase: 10-target-history-integration
plan: "02"
subsystem: providers
tags: [riverpod, drift, stream-provider, timer, midnight-reset, streak, target-history]
dependency_graph:
  requires:
    - phase: 10-01
      provides: watchTargetForDate stream, watchAll TargetHistoryDao method, applyFromTomorrow column
  provides:
    - todayDateKeyProvider (keepAlive Notifier with midnight Timer, BUG-02 fix)
    - effectiveTargetForDateProvider (stream family, per-day target lookup)
    - allTargetHistoryProvider (stream of all TargetHistoryEntry rows for batch use)
    - updated streak provider using per-day targets via asyncExpand
  affects: [home-screen, history-screen, calendar-screen, plan-03]
tech_stack:
  added: []
  patterns:
    - keepAlive-Notifier-with-Timer-for-midnight-reset
    - asyncExpand-outer-stream-inner-stream-for-combined-reactive-streams
    - TargetHistoryEntry-domain-entity-wrapping-Drift-DataClass-for-riverpod-generator-compat
key_files:
  created:
    - lib/domain/entities/target_history_entry.dart
  modified:
    - lib/core/providers/stream_providers.dart
    - lib/core/providers/stream_providers.g.dart
key_decisions:
  - "TargetHistoryEntry plain Dart entity created (no freezed/code-gen) because riverpod_generator cannot resolve types from .g.dart files in provider return signatures"
  - "allTargetHistory maps TargetHistoryData to TargetHistoryEntry at the provider boundary -- only the domain type appears in the generated code"
  - "streak provider uses db.targetHistoryDao.watchAll() directly (not allTargetHistoryProvider) because TargetHistoryData is used in the body (inferred type), not the function signature"
  - "asyncExpand outer stream = target_history rows; inner stream = daily totals range -- correct reactive dependency chain for D-11"
  - "TodayDateKey schedules a single Timer per day with +1 second buffer past midnight to avoid DST edge cases"
patterns-established:
  - "Provider return types must use source (non-generated) Dart types for riverpod_generator compat -- wrap Drift DataClass types in domain entities at the provider boundary"
  - "keepAlive Notifier pattern with ref.onDispose cleanup for long-lived stateful providers (follow FocusedMonth and TodayDateKey)"
requirements-completed: [BUG-02, TARGET-03, TARGET-04]
duration: 15min
completed: 2026-06-10
---

# Phase 10 Plan 02: Provider Layer for Target History Integration Summary

**Riverpod provider layer for per-day target tracking: TodayDateKey keepAlive Notifier with midnight Timer (BUG-02 fix), effectiveTargetForDate stream family, allTargetHistory batch stream, and streak rewritten to use per-day targets via asyncExpand.**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-06-10T12:30:00Z
- **Completed:** 2026-06-10T12:45:00Z
- **Tasks:** 2
- **Files modified:** 3 (+ 1 created)

## Accomplishments

- Added `TodayDateKey` keepAlive Notifier with midnight Timer and `ref.onDispose` cleanup — fixes BUG-02 (date key not updating after midnight without app restart)
- Added `effectiveTargetForDateProvider` stream family returning `Stream<int>` via `watchTargetForDate(dateKey)` with defensive 2000 ml fallback
- Added `allTargetHistoryProvider` streaming `Stream<List<TargetHistoryEntry>>` for batch calendar/streak lookups without per-day DB queries
- Rewrote streak provider to use `asyncExpand` over target history outer stream and daily totals inner stream — each day evaluated against its own effective target, not a single global target
- Created `TargetHistoryEntry` plain Dart entity as domain-layer wrapper for `TargetHistoryData` (needed for riverpod_generator type resolution)
- Code-gen passes (21 outputs), `dart analyze` clean, 23 tests pass

## Task Commits

Each task was committed atomically:

1. **Task 1: Add todayDateKeyProvider and effectiveTargetForDate provider** - `779fb6d` (feat)
2. **Task 2: Update streak provider for per-day targets and run code-gen** - `4218c7e` (feat)

## Files Created/Modified

- `lib/domain/entities/target_history_entry.dart` - Plain Dart entity wrapping target_history row fields (id, effectiveDate, targetMl) for use in Riverpod provider return types
- `lib/core/providers/stream_providers.dart` - Added TodayDateKey Notifier, effectiveTargetForDate family, allTargetHistory provider; rewrote streak with asyncExpand and per-day target logic; removed userSettingsProvider dependency from streak
- `lib/core/providers/stream_providers.g.dart` - Regenerated with todayDateKeyProvider, effectiveTargetForDateProvider, allTargetHistoryProvider

## Decisions Made

- `TargetHistoryEntry` plain Dart entity created without freezed/code-gen because `riverpod_generator` cannot resolve types declared in `.g.dart` generated files when they appear in provider return type signatures. The Drift `DataClass` types are wrapped at the provider boundary.
- `streak` uses `db.targetHistoryDao.watchAll()` directly (rather than `allTargetHistoryProvider`) because `TargetHistoryData` appears only in the inferred lambda body type, not the function signature — this is transparent to `riverpod_generator`.
- `TodayDateKey._scheduleMidnightRefresh()` adds a 1-second buffer past midnight to handle clock jitter and avoid firing just before midnight.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Created TargetHistoryEntry domain entity to fix riverpod_generator InvalidTypeException**
- **Found during:** Task 2 (code-gen step)
- **Issue:** `riverpod_generator` threw `InvalidTypeException` when `allTargetHistory` declared `Stream<List<TargetHistoryData>>` as its return type. `TargetHistoryData` is defined in `app_database.g.dart` (a generated file), and the riverpod_generator cannot resolve types from generated files at build time.
- **Fix:** Created `lib/domain/entities/target_history_entry.dart` as a plain Dart class (id, effectiveDate, targetMl). Updated `allTargetHistory` to return `Stream<List<TargetHistoryEntry>>` and map `TargetHistoryData` rows to `TargetHistoryEntry`. Removed unused `app_database.dart` import after confirming analyzer was clean.
- **Files modified:** `lib/domain/entities/target_history_entry.dart` (created), `lib/core/providers/stream_providers.dart`
- **Verification:** `dart run build_runner build` succeeded with 21 outputs; `dart analyze` reports no issues
- **Committed in:** `4218c7e` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - Bug)
**Impact on plan:** The fix is a minimal correctness requirement — the generated code cannot work without resolvable types. The `TargetHistoryEntry` entity is a thin wrapper with no behavior, adding no scope beyond what the plan intended. All plan artifacts are delivered as specified.

## Issues Encountered

- `riverpod_generator` cannot resolve types from Drift-generated `.g.dart` files when used in provider return type signatures. The fix (domain entity wrapper) follows the existing pattern in the codebase where all other providers return domain entity types (`WaterEntryEntity`, `DrinkPresetEntity`, `UserSettingsEntity`).

## Known Stubs

None.

## Threat Flags

None — no new network endpoints, auth paths, or file access patterns introduced. Timer->Notifier boundary already covered by T-10-03 (accept disposition). effectiveTargetForDate read-only stream covered by T-10-04.

## Next Phase Readiness

- All provider building blocks for Plan 03 (UI layer) are in place:
  - `todayDateKeyProvider` replaces the static `todayDateKey()` call in widgets
  - `effectiveTargetForDateProvider` provides per-day target to HomeScreen and HistoryScreen
  - `allTargetHistoryProvider` provides batch target history to CalendarScreen day builder
  - Streak provider correctly evaluates per-day targets
- No blockers. Plan 03 can proceed immediately.

---
*Phase: 10-target-history-integration*
*Completed: 2026-06-10*

## Self-Check: PASSED

- [x] `lib/domain/entities/target_history_entry.dart` exists — contains `TargetHistoryEntry` class with id, effectiveDate, targetMl
- [x] `lib/core/providers/stream_providers.dart` — contains `TodayDateKey extends _$TodayDateKey`, `effectiveTargetForDate`, `allTargetHistory`, updated `streak`
- [x] `lib/core/providers/stream_providers.g.dart` — contains `todayDateKeyProvider`, `effectiveTargetForDateProvider`, `allTargetHistoryProvider`
- [x] `dart analyze` — no issues
- [x] 23 tests pass
- [x] Commit 779fb6d exists — Task 1 (todayDateKeyProvider + effectiveTargetForDate + allTargetHistory providers)
- [x] Commit 4218c7e exists — Task 2 (streak update + TargetHistoryEntry entity + code-gen)
