---
phase: 07-intake-redesign
plan: 01
subsystem: ui
tags: [flutter, material3, fab, bottom-sheet, presets]

# Dependency graph
requires:
  - phase: 06-bug-fix-theme-l-display
    provides: Clean home_screen.dart baseline with dynamic color theming
provides:
  - FAB-based intake entry replacing inline quick-add buttons
  - Modal bottom sheet with 3 preset buttons and custom ml input
  - 3-preset seed data (150/250/500 ml) for new installs
  - Presentation-layer .take(3) filter on presets in settings and sheet
affects: [08-app-icon]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "StatefulWidget for bottom sheet with TextEditingController lifecycle"
    - "Callback pattern: sheet passes amountMl back to parent via onAdd callback (D-09)"
    - "Presentation-layer filtering with .take(3) instead of DAO changes (D-06)"

key-files:
  created: []
  modified:
    - lib/presentation/screens/home_screen.dart
    - lib/presentation/screens/settings_screen.dart
    - lib/data/database/app_database.dart
    - test/data/database/daos/drink_preset_dao_test.dart

key-decisions:
  - "Sheet widget receives presets and onAdd callback; no direct provider access (D-09)"
  - "Navigator.pop before onAdd ensures sheet closes before SnackBar appears (D-01/D-02)"
  - "Custom input range 1-9999 with disabled submit button; no error label (D-11)"

patterns-established:
  - "Bottom sheet callback pattern: parent widget owns DB writes, sheet is stateless"
  - "Presentation-layer filtering: .take(3) hides 4th preset without migration"

requirements-completed: [INTAKE-01, INTAKE-02, INTAKE-03, INTAKE-04]

# Metrics
duration: 3min
completed: 2026-06-08
---

# Phase 7 Plan 01: Intake Redesign Summary

**FAB replaces inline quick-add buttons; modal bottom sheet provides 3 configurable presets and custom ml input with 1-9999 validation**

## Performance

- **Duration:** 3 min
- **Started:** 2026-06-08T14:50:53Z
- **Completed:** 2026-06-08T14:54:10Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Replaced home screen inline quick-add Row with a FloatingActionButton that opens a modal bottom sheet
- Bottom sheet contains 3 preset buttons (matching user's first 3 presets by sortOrder) and a custom ml TextField with 1-9999 validation
- Reduced preset seed data from 4 (200/300/400/500) to 3 (150/250/500) for new installs
- Settings screen shows exactly 3 preset editing slots via .take(3) presentation-layer filter
- Updated empty state copy to reference FAB and error state to include restart instruction

## Task Commits

Each task was committed atomically:

1. **Task 1: Replace quick-add Row with FAB and modal bottom sheet** - `9410140` (feat)
2. **Task 2: Reduce presets to 3 in settings screen and seed data** - `d206ffa` (feat)
3. **Task 2 fix: Update seed test to match new 3-preset values** - `36a3128` (fix)

## Files Created/Modified
- `lib/presentation/screens/home_screen.dart` - Added FAB, _IntakeBottomSheet widget; removed quick-add Row; updated copy
- `lib/presentation/screens/settings_screen.dart` - Added .take(3) to presets in _presetsCard
- `lib/data/database/app_database.dart` - Changed seed from 4 presets (200/300/400/500) to 3 (150/250/500)
- `test/data/database/daos/drink_preset_dao_test.dart` - Updated test expectations for new seed values

## Decisions Made
- Sheet widget receives presets list and onAdd callback; does not access providers directly (per D-09)
- Navigator.pop called before onAdd callback to ensure sheet closes before SnackBar appears (per D-01/D-02/D-03)
- Custom input validated with int.tryParse and range 1-9999; submit button disabled when invalid; no error label shown (per D-11)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated seed test to match new preset values**
- **Found during:** Task 2 (verification)
- **Issue:** drink_preset_dao_test.dart expected 4 presets with old amounts (200/300/400/500); test failed after seed change
- **Fix:** Updated test to expect 3 presets with new amounts (150/250/500); changed updatePreset test value from 150 to 200 to avoid collision with new seed
- **Files modified:** test/data/database/daos/drink_preset_dao_test.dart
- **Verification:** All 12 tests pass
- **Committed in:** 36a3128

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Necessary test update to match intentional seed data change. No scope creep.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Home screen now uses FAB-based intake flow; ready for Phase 8 (app icon)
- All INTAKE requirements (INTAKE-01 through INTAKE-04) are complete
- flutter analyze clean; all 12 tests passing

---
*Phase: 07-intake-redesign*
*Completed: 2026-06-08*
