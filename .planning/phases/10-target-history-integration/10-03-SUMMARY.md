---
phase: 10-target-history-integration
plan: "03"
subsystem: ui-screens
tags: [flutter, riverpod, home-screen, history-screen, settings-screen, per-day-target, midnight-reset]
dependency_graph:
  requires:
    - phase: 10-01
      provides: updateTargetWithHistory, applyFromTomorrow column
    - phase: 10-02
      provides: todayDateKeyProvider, effectiveTargetForDateProvider, allTargetHistoryProvider
  provides:
    - HomeScreen wired to todayDateKeyProvider (BUG-02 fixed)
    - HomeScreen progress ring using effectiveTargetForDateProvider (TARGET-03)
    - HistoryScreen calendar using per-day target via _findActiveTarget (TARGET-04)
    - SettingsScreen applyFromTomorrow toggle (TARGET-02)
    - SettingsScreen slider routing through updateTargetWithHistory (TARGET-02)
  affects: [home_screen, history_screen, settings_screen]
tech_stack:
  added: []
  patterns:
    - ref.watch(todayDateKeyProvider)-for-reactive-midnight-date-key
    - effectiveTargetForDateProvider-family-for-per-day-target-in-progress-ring
    - allTargetHistoryProvider-batch-lookup-with-linear-scan-helper
    - updateTargetWithHistory-dual-write-routing-from-ui
key_files:
  created: []
  modified:
    - lib/presentation/screens/home_screen.dart
    - lib/presentation/screens/history_screen.dart
    - lib/presentation/screens/settings_screen.dart
decisions:
  - "Removed dart:async import from HomeScreen — Timer no longer needed after moving midnight logic to TodayDateKey provider"
  - "Used TargetHistoryEntry (domain entity) not TargetHistoryData (Drift DataClass) for _findActiveTarget parameter — consistent with Plan 02 pattern where riverpod_generator requires non-generated types"
  - "_findActiveTarget uses linear scan with early break (ASC sort guarantee from TargetHistoryDao.watchAll) — O(n) but n is small (max one row per target change)"
  - "SwitchListTile for applyFromTomorrow uses updateSettings (not updateTargetWithHistory) since toggling the preference does not change the target value"
  - "effectiveTargetForDateProvider fallback is 2000 ml — same as TodayDateKey and allTargetHistoryProvider helper defaults"
metrics:
  duration: "5 minutes"
  completed: "2026-06-10"
  tasks_completed: 2
  tasks_total: 2
  files_changed: 3
---

# Phase 10 Plan 03: UI Screen Wiring for Target History Integration Summary

**One-liner:** Wired HomeScreen to todayDateKeyProvider and effectiveTargetForDateProvider (BUG-02 fixed, TARGET-03), HistoryScreen to allTargetHistoryProvider with _findActiveTarget helper (TARGET-04), and SettingsScreen with applyFromTomorrow toggle and updateTargetWithHistory routing (TARGET-02) — all three screens now use per-day targets.

## What Was Built

### Task 1: HomeScreen migration

- Removed `Timer.periodic` midnight polling, `_dateKey` field, `_midnightTimer` field, `_checkDateChange()` method, and `dart:async` import
- Removed `_checkDateChange()` call from `AppLifecycleListener.onResume` (date changes now handled reactively by `todayDateKeyProvider`)
- Added `final todayKey = ref.watch(todayDateKeyProvider)` at top of `build()` — reactive midnight reset (BUG-02 fix)
- `totalMlForDateProvider` and `waterEntriesForDateProvider` now receive `todayKey` from the provider
- `ref.listen` for goal-reached notification cancel now uses `effectiveTargetForDateProvider(todayKey)` instead of `userSettingsProvider.dailyTargetMl`
- `_buildContent` signature extended to accept `int target` as 5th parameter; target computed via `ref.watch(effectiveTargetForDateProvider(todayKey)).value ?? 2000` in the data callback
- `_onQuickAdd` captures key via `ref.read(todayDateKeyProvider)` instead of `_dateKey` field

### Task 2: HistoryScreen and SettingsScreen

**HistoryScreen:**
- Added import for `target_history_entry.dart` (domain entity `TargetHistoryEntry`)
- Added file-level `_findActiveTarget(List<TargetHistoryEntry> targets, String dateKey)` helper with linear ASC scan and 2000 ml fallback
- Replaced `ref.watch(userSettingsProvider)` with `ref.watch(allTargetHistoryProvider)` in `build()`
- `defaultBuilder`: computes `dailyTarget = _findActiveTarget(targets, dateKey)` per day before green/red check
- `todayBuilder`: computes `dailyTarget = _findActiveTarget(targets, dateKey)` per day before goal check
- `_buildDaySummary`: signature changed from `int dailyTarget` to `List<TargetHistoryEntry> targets`; computes target internally via `_findActiveTarget`

**SettingsScreen:**
- `_dailyGoalCard` slider `onChangeEnd` now calls `updateTargetWithHistory(val.toInt())` instead of `updateSettings(settings.copyWith(dailyTargetMl: ...))`
- Added `const Divider()` after the slider
- Added `SwitchListTile` with title `'Applica da domani'`, conditional subtitle, `value: settings.applyFromTomorrow`, and `onChanged` calling `updateSettings(settings.copyWith(applyFromTomorrow: val))`

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 1 | ace86df | feat(10-03): migrate HomeScreen to todayDateKeyProvider and per-day target |
| Task 2 | 70e197a | feat(10-03): wire HistoryScreen to per-day targets and add applyFromTomorrow toggle |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Used TargetHistoryEntry instead of TargetHistoryData for _findActiveTarget**
- **Found during:** Task 2 implementation review
- **Issue:** Plan Task 2 action incorrectly specifies importing `app_database.dart` for `TargetHistoryData`. However, `allTargetHistoryProvider` returns `Stream<List<TargetHistoryEntry>>` (the domain entity defined in Plan 02 to fix riverpod_generator's inability to resolve Drift-generated types). Using `TargetHistoryData` would not match the provider's return type.
- **Fix:** Used `TargetHistoryEntry` from `domain/entities/target_history_entry.dart` as the parameter type for `_findActiveTarget`. The struct has the same fields (`id`, `effectiveDate`, `targetMl`) that the helper needs.
- **Files modified:** `lib/presentation/screens/history_screen.dart`
- **Impact:** None — correct type, correct behavior. The plan's intent was clear; only the implementation detail (type name) was wrong in the plan text.

## Known Stubs

None.

## Threat Flags

None — all changes are read-only wiring of existing providers to existing UI components. The `updateTargetWithHistory` write path was introduced in Plan 01 (T-10-05 mitigated by ArgumentError validation). The `applyFromTomorrow` toggle write path uses `updateSettings` which already validates all fields.

## Self-Check: PASSED

- [x] `lib/presentation/screens/home_screen.dart` exists — contains `todayDateKeyProvider`, `effectiveTargetForDateProvider`, no `Timer.periodic`, no `_midnightTimer`, no `_dateKey`
- [x] `lib/presentation/screens/history_screen.dart` exists — contains `_findActiveTarget`, `allTargetHistoryProvider`, no `settings.dailyTargetMl` for calendar coloring
- [x] `lib/presentation/screens/settings_screen.dart` exists — contains `updateTargetWithHistory`, `applyFromTomorrow`, `'Applica da domani'`
- [x] Commit ace86df exists — Task 1 (HomeScreen migration)
- [x] Commit 70e197a exists — Task 2 (HistoryScreen + SettingsScreen)
- [x] `dart analyze` on all 3 screens — no issues found
