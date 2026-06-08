---
phase: 02-core-tracking-ui
plan: 02
subsystem: ui
tags: [flutter, riverpod, drift, percent_indicator, material3, circular-progress, snackbar, midnight-reset]

# Dependency graph
requires:
  - phase: 02-01
    provides: StatefulShellRoute navigation shell with NavigationBar; percent_indicator 4.2.5 installed
  - phase: 01-data-foundation
    provides: stream providers (waterEntriesForDateProvider, totalMlForDateProvider, userSettingsProvider, drinkPresetsProvider), WaterRepository (insertEntry, deleteLastEntry), domain entities

provides:
  - Full HomeScreen: animated CircularPercentIndicator progress ring, 4 FilledButton quick-add presets, floating SnackBar with UNDO action, chronological intake timeline, midnight auto-reset
  - ConsumerStatefulWidget pattern established for Riverpod + lifecycle listener co-existence
  - Date-key capture pattern before async gap (T-02-03 mitigation)

affects: [03-settings, 04-calendar-streaks, 05-notifications]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - ConsumerStatefulWidget with AppLifecycleListener + Timer.periodic for midnight reset detection
    - Multi-stream AsyncValue coordination: settingsAsync.when() as primary gate, .value ?? default for non-critical streams (avoids nested when() chains)
    - capturedKey pattern: capture _dateKey into local var before async gap to prevent race condition on date rollover
    - clearSnackBars() before showSnackBar() to prevent SnackBar queue buildup on rapid taps
    - withValues(alpha: 0.3) instead of deprecated withOpacity for Flutter 3.44.1

key-files:
  created: []
  modified:
    - lib/presentation/screens/home_screen.dart

key-decisions:
  - "valueOrNull does not exist in Riverpod 3.2.1 — use .value (nullable T?) instead"
  - "withValues(alpha: 0.3) used instead of withOpacity (deprecated in Flutter 3.44.1)"
  - "Multi-stream loading: settingsAsync.when() as primary guard, totalAsync.value/entriesAsync.value/presetsAsync.value with ?? defaults for non-critical streams"
  - "Newest-first sort order comes from waterEntriesForDateProvider which uses Drift's orderBy DESC on loggedAt"

patterns-established:
  - "Pattern: ConsumerStatefulWidget with AppLifecycleListener + Timer.periodic for midnight date-key reset"
  - "Pattern: Capture state fields into local vars before await to prevent use-after-async-gap bugs"
  - "Pattern: settingsAsync.when() as single outer gate with .value fallbacks for other streams"

requirements-completed: [HOME-01, HOME-02, HOME-03, HOME-04]

# Metrics
duration: 2min
completed: 2026-06-04
---

# Phase 2 Plan 2: HomeScreen Summary

**ConsumerStatefulWidget HomeScreen with CircularPercentIndicator progress ring (primary/green color toggle), 4 FilledButton quick-add presets, floating 5s SnackBar with UNDO, newest-first intake timeline, and AppLifecycleListener + Timer.periodic midnight reset**

## Performance

- **Duration:** 2 min
- **Started:** 2026-06-04T15:13:49Z
- **Completed:** 2026-06-04T15:15:32Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Rewrote home_screen.dart from 17-line StatelessWidget placeholder to 229-line ConsumerStatefulWidget implementing all four HOME requirements (HOME-01 through HOME-04) and all five locked decisions (D-01 through D-05)
- Implemented CircularPercentIndicator with clamped percentage (0.0..1.0), animated color transition from colorScheme.primary to Colors.green.shade600 at 100%, center text switching between "N / target ml" and "Goal reached!"
- Established capturedKey pattern (capture _dateKey before await in _onQuickAdd) to prevent midnight race condition T-02-03
- dart analyze reports no issues; full lib/ analysis clean

## Task Commits

Each task was committed atomically:

1. **Task 1: Build complete HomeScreen with progress ring, quick-add buttons, SnackBar undo, timeline, midnight reset** - `b11dc1b` (feat)

**Plan metadata:** (docs commit — see below)

## Files Created/Modified

- `lib/presentation/screens/home_screen.dart` — complete rewrite from StatelessWidget to ConsumerStatefulWidget; 229 lines; imports dart:async, flutter_riverpod, percent_indicator; all HOME requirements implemented

## Decisions Made

- Used `.value` (nullable getter) instead of `.valueOrNull` — the latter does not exist in flutter_riverpod 3.3.1 / riverpod 3.2.1; `.value` returns `T?` and is the correct API for fallback patterns
- Used `withValues(alpha: 0.3)` instead of `withOpacity(0.3)` — withOpacity is deprecated in Flutter 3.44.1; withValues is the current API
- Used `settingsAsync.when()` as the single outer loading gate, with `.value ?? default` for totalAsync, entriesAsync, presetsAsync — avoids nested when() chains and flash loading states for non-critical streams

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Replaced non-existent valueOrNull with .value**
- **Found during:** Task 1 (dart analyze after initial write)
- **Issue:** Plan specified `.valueOrNull` which does not exist in the installed riverpod 3.2.1. Analyzer reported `undefined_getter` on three lines.
- **Fix:** Replaced `totalAsync.valueOrNull`, `entriesAsync.valueOrNull`, `presetsAsync.valueOrNull` with `totalAsync.value`, `entriesAsync.value`, `presetsAsync.value` (each returns `T?`, semantically equivalent)
- **Files modified:** lib/presentation/screens/home_screen.dart
- **Verification:** dart analyze reports no issues
- **Committed in:** b11dc1b (part of Task 1 commit)

**2. [Rule 1 - Bug] Fixed unnecessary_underscores lint in separatorBuilder**
- **Found during:** Task 1 (dart analyze info-level warning)
- **Issue:** `separatorBuilder: (_, __) =>` uses double-underscore which triggers `unnecessary_underscores` lint
- **Fix:** Changed `(_, __)` to `(_, _)` (single wildcard for second unused param)
- **Files modified:** lib/presentation/screens/home_screen.dart
- **Verification:** dart analyze reports no issues
- **Committed in:** b11dc1b (part of Task 1 commit)

---

**Total deviations:** 2 auto-fixed (2 Rule 1 bugs — API mismatch and lint)
**Impact on plan:** Both fixes required for correctness; no behavior or scope change. API name `.valueOrNull` vs `.value` is purely a Riverpod version difference; semantics are identical.

## Issues Encountered

- `withOpacity` deprecation: plan flagged this as "check during implementation." Flutter 3.44.1 has deprecated it. Used `withValues(alpha: 0.3)` as directed by the plan's own guidance.

## Known Stubs

None — home_screen.dart is fully wired. It consumes real Drift streams via Riverpod providers, calls real WaterRepository methods, and renders actual runtime data. No hardcoded values, no placeholder text beyond the intentional empty-state copy, no stub data sources.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes introduced. All surface is within the trust boundaries documented in the plan's threat_model (T-02-02 through T-02-05).

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- HomeScreen fully implements the core tracking loop: log water → see progress → undo if needed → review history
- All four HOME requirements met and locked decisions D-01 through D-05 implemented
- Phase 3 (Settings) can now build the SettingsScreen — `userSettingsProvider` and `settingsRepositoryProvider` are already consumed by HomeScreen; consistent provider usage is established
- Phase 4 (Calendar & Streaks) can rely on `waterEntriesForDateProvider(dateKey)` pattern; the date-keyed provider pattern is proven and in use
- dart analyze: no issues across all of lib/

---
*Phase: 02-core-tracking-ui*
*Completed: 2026-06-04*
