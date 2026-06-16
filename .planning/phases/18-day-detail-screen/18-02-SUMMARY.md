---
phase: 18-day-detail-screen
plan: "02"
subsystem: navigation
tags: [flutter, go_router, riverpod, navigation, history-screen]
dependency_graph:
  requires:
    - DayDetailScreen (lib/presentation/screens/day_detail_screen.dart) -- Plan 01
    - GoRouter (lib/core/router/app_router.dart)
    - calendarMonthProvider (core/providers/stream_providers.dart)
    - focusedMonthProvider (core/providers/stream_providers.dart)
  provides:
    - GoRoute /day/:dateKey (lib/core/router/app_router.dart)
    - HistoryScreen ConsumerWidget with push navigation (lib/presentation/screens/history_screen.dart)
  affects:
    - lib/core/router/app_router.dart (new route added)
    - lib/presentation/screens/history_screen.dart (converted, dead code removed)
tech_stack:
  added: []
  patterns:
    - GoRoute top-level (outside StatefulShellRoute) for NavigationBar-free screen
    - context.push with data guard (monthTotals check before navigation)
    - ConsumerWidget replacing ConsumerStatefulWidget (no local mutable state needed)
    - File-private top-level function for _buildDayCell (no 'this' reference)
key_files:
  created: []
  modified:
    - lib/core/router/app_router.dart
    - lib/presentation/screens/history_screen.dart
decisions:
  - HistoryScreen converted to ConsumerWidget since _selectedDay was the only instance state and it is removed
  - _buildDayCell moved to file-private top-level function (not instance method) since it uses only BuildContext and DateTime parameters
  - redirect guard exemption for /day/ added to prevent infinite redirect loop for day detail pushes
  - Navigation guard checks monthTotals[dateKey] != null && > 0 to avoid pushing DayDetailScreen for days with no data
metrics:
  duration: "8 minutes"
  completed: "2026-06-16"
  tasks_completed: 1
  files_changed: 2
---

# Phase 18 Plan 02: GoRouter Route and HistoryScreen Navigation Summary

**One-liner:** GoRoute /day/:dateKey wired as top-level route (no NavigationBar), HistoryScreen converted to ConsumerWidget with context.push navigation replacing inline day summary.

## What Was Built

### Task 1: Add GoRouter route and rewire HistoryScreen navigation

Two files modified.

**lib/core/router/app_router.dart:**
- Added import for `day_detail_screen.dart`
- Added redirect guard exemption: `if (state.matchedLocation.startsWith('/day/')) return null;`
- Added `GoRoute(path: '/day/:dateKey', ...)` as a top-level route between the `/calculator` route and `StatefulShellRoute.indexedStack`, so DayDetailScreen renders without the bottom NavigationBar

**lib/presentation/screens/history_screen.dart:**
- Added `import 'package:go_router/go_router.dart';`
- Converted `HistoryScreen` from `ConsumerStatefulWidget` to `ConsumerWidget`
- Removed `_HistoryScreenState` class, `_selectedDay` field, `selectedDayPredicate` parameter, `AnimatedSwitcher` block, and `_buildDaySummary()` method
- Moved `_buildDayCell` from instance method to file-private top-level function (same level as `_toDateKey` and `_findActiveTarget`)
- Updated `onDaySelected` callback: keeps future-day guard and `focusedMonthProvider` update; adds `context.push('/day/$dateKey')` only when `monthTotals[dateKey] != null && monthTotals[dateKey]! > 0`
- Removed the `SizedBox(height: 16)` and `AnimatedSwitcher` block that hosted the old inline day summary; the `SizedBox(height: 24)` at the end remains as bottom padding after MonthlyBarChart

`flutter analyze` passes with no issues on both files.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None - navigation is wired to real GoRouter route using real `monthTotals` data from `calendarMonthProvider`. DayDetailScreen was built in Plan 01 with real provider data.

## Threat Flags

No new unplanned threat surface introduced. Trust boundaries covered by plan's threat model (T-18-03: dateKey from path parameter accepted as local-only; T-18-04: redirect guard exemption is correct since /day/ is post-onboarding only).

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 1: GoRouter route + HistoryScreen navigation | 629d3e6 | feat(18-02): add GoRouter /day/:dateKey route and rewire HistoryScreen navigation |

## Self-Check

### Files modified

- [x] `lib/core/router/app_router.dart` - contains GoRoute /day/:dateKey - FOUND
- [x] `lib/core/router/app_router.dart` - contains startsWith('/day/') redirect guard - FOUND
- [x] `lib/core/router/app_router.dart` - imports day_detail_screen.dart - FOUND
- [x] `lib/presentation/screens/history_screen.dart` - ConsumerWidget - FOUND
- [x] `lib/presentation/screens/history_screen.dart` - no _selectedDay - CONFIRMED (0 occurrences)
- [x] `lib/presentation/screens/history_screen.dart` - no _buildDaySummary - CONFIRMED (0 occurrences)
- [x] `lib/presentation/screens/history_screen.dart` - no AnimatedSwitcher - CONFIRMED (0 occurrences)
- [x] `lib/presentation/screens/history_screen.dart` - no selectedDayPredicate - CONFIRMED (0 occurrences)
- [x] `lib/presentation/screens/history_screen.dart` - context.push('/day/...) present - FOUND
- [x] `lib/presentation/screens/history_screen.dart` - go_router import present - FOUND

### Commits verified

- [x] 629d3e6 - Task 1 commit exists

## Self-Check: PASSED
