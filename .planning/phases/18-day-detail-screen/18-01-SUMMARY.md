---
phase: 18-day-detail-screen
plan: "01"
subsystem: presentation
tags: [flutter, fl_chart, riverpod, l10n, bar-chart, day-detail]
dependency_graph:
  requires:
    - waterEntriesForDateProvider (stream_providers.dart)
    - allTargetHistoryProvider (stream_providers.dart)
    - WaterEntryEntity (domain/entities/water_entry_entity.dart)
    - TargetHistoryEntry (domain/entities/target_history_entry.dart)
    - AppLocalizations L10N (lib/l10n/generated/)
  provides:
    - DayDetailScreen (lib/presentation/screens/day_detail_screen.dart)
    - dayDetailTotal L10N key (all 4 locales)
    - dayDetailNoEntries L10N key (all 4 locales)
  affects:
    - lib/l10n/generated/ (regenerated Dart L10N files)
tech_stack:
  added: []
  patterns:
    - fl_chart BarChart with ValueKey, explicit maxY, grouped barRods
    - ConsumerWidget watching two AsyncValue providers with nested .when()
    - DateFormat.yMMMMd(locale) for locale-aware AppBar title
    - _findActiveTarget local helper duplicated per Phase 17 strategy
key_files:
  created:
    - lib/presentation/screens/day_detail_screen.dart
  modified:
    - lib/l10n/app_en.arb
    - lib/l10n/app_it.arb
    - lib/l10n/app_fr.arb
    - lib/l10n/app_es.arb
    - lib/l10n/generated/app_localizations.dart
    - lib/l10n/generated/app_localizations_en.dart
    - lib/l10n/generated/app_localizations_it.dart
    - lib/l10n/generated/app_localizations_fr.dart
    - lib/l10n/generated/app_localizations_es.dart
decisions:
  - DayDetailScreen uses ConsumerWidget (not ConsumerStatefulWidget) since no local mutable state is needed
  - _toDateKey helper omitted from DayDetailScreen (dateKey is received as parameter, not computed from DateTime) to avoid unused_element lint warning
  - Bar chart groups entries by minutes-since-midnight (entry.loggedAt.hour * 60 + entry.loggedAt.minute); same-minute entries produce multiple barRods in one BarChartGroupData
  - maxY = max(actualMaxMl * 1.1, 100.0) following WR-02 mandatory explicit ceiling pattern
  - Bar color uses colorScheme.primary (not green/red) since bars represent individual additions, not daily completion
metrics:
  duration: "4 minutes"
  completed: "2026-06-16"
  tasks_completed: 2
  files_changed: 10
---

# Phase 18 Plan 01: Day Detail Screen Summary

**One-liner:** DayDetailScreen ConsumerWidget with per-entry fl_chart BarChart (HH:mm x-axis, ml y-axis), total/target text display, empty state, and 4-locale L10N strings.

## What Was Built

### Task 1: L10N strings for Day Detail screen
Added 2 new L10N keys to all 4 ARB files and regenerated Dart L10N code.

- `dayDetailTotal` -- "{total} ml / {target} ml target" (en) with placeholders `total` and `target` (type: num). Italian: "obiettivo", French: "objectif", Spanish: "objetivo".
- `dayDetailNoEntries` -- "No entries for this day" (en). Italian: "Nessun dato per questo giorno", French: "Aucune entree pour ce jour", Spanish: "Sin registros para este dia".

`flutter gen-l10n` completed without errors. Generated Dart files expose both getters.

### Task 2: DayDetailScreen widget
Created `lib/presentation/screens/day_detail_screen.dart` as a `ConsumerWidget` (304 lines).

Key implementation details:
- Constructor: `const DayDetailScreen({super.key, required this.dateKey})`
- Watches `waterEntriesForDateProvider(dateKey)` and `allTargetHistoryProvider` with nested `AsyncValue.when`
- AppBar title: `DateFormat.yMMMMd(locale).format(DateTime.parse(dateKey))` per D-06
- Empty state (CHART-10): Card with `context.l10n.dayDetailNoEntries` when `entries.isEmpty`
- Total text (CHART-09): `context.l10n.dayDetailTotal(totalMl, targetMl)` above chart
- Bar chart (CHART-08): groups entries by `entry.loggedAt.hour * 60 + entry.loggedAt.minute`; same-minute entries produce multiple `barRods` in one `BarChartGroupData`
- `ValueKey('day-$dateKey')` on BarChart per WR-01
- `maxY = max(actualMaxMl * 1.1, 100.0)` per WR-02
- Bar color: `colorScheme.primary` (theme-aware, not green/red per D-08 and CONTEXT)
- `flutter analyze` passes with no issues

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed unused `_toDateKey` helper**
- **Found during:** Task 2 (flutter analyze)
- **Issue:** Plan specified duplicating `_toDateKey` per Phase 17 strategy, but `DayDetailScreen` receives `dateKey` as a constructor parameter (String), so there is no DateTime-to-dateKey conversion needed. The unused function triggered `unused_element` lint warning.
- **Fix:** Removed `_toDateKey` from `day_detail_screen.dart`. The `_findActiveTarget` helper (which is used) was retained.
- **Files modified:** lib/presentation/screens/day_detail_screen.dart
- **Commit:** b2eb5c5

## Known Stubs

None - all data flows are wired to real providers. The screen renders real water entry data from `waterEntriesForDateProvider` and real target history from `allTargetHistoryProvider`.

## Threat Flags

No new unplanned threat surface introduced. All trust boundaries were covered by the plan's threat model (T-18-01: dateKey tampering accepted as local-only; T-18-02: data disclosure accepted as local SQLite).

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 1: L10N strings | 300efb1 | feat(18-01): add dayDetailTotal and dayDetailNoEntries L10N strings to all 4 ARB files |
| Task 2: DayDetailScreen | b2eb5c5 | feat(18-01): create DayDetailScreen with per-entry bar chart and empty state |

## Self-Check

### Files created
- [x] `lib/presentation/screens/day_detail_screen.dart` - FOUND (304 lines, min 80 required)
- [x] `lib/l10n/app_en.arb` - contains `dayDetailTotal` - FOUND
- [x] `lib/l10n/app_it.arb` - contains `dayDetailTotal` - FOUND
- [x] `lib/l10n/app_fr.arb` - contains `dayDetailTotal` - FOUND
- [x] `lib/l10n/app_es.arb` - contains `dayDetailTotal` - FOUND

### Commits verified
- [x] 300efb1 - Task 1 commit exists
- [x] b2eb5c5 - Task 2 commit exists

## Self-Check: PASSED
