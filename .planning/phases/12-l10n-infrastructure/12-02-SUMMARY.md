---
phase: 12-l10n-infrastructure
plan: 02
subsystem: infra
tags: [flutter, l10n, gen-l10n, arb, localization, AppLocalizations]

# Dependency graph
requires:
  - phase: 12-01
    provides: l10n.yaml config, pubspec.yaml dependencies, l10n_extensions.dart, MaterialApp wiring
provides:
  - lib/l10n/app_en.arb — complete English ARB template with 79 translatable strings and @metadata
  - lib/l10n/generated/app_localizations.dart — abstract AppLocalizations class, delegate, localizationsDelegates, supportedLocales
  - lib/l10n/generated/app_localizations_en.dart — English implementation with all getter methods
affects:
  - 13-string-extraction: starts with full ARB template; focuses on widget replacement + it/fr/es translations
  - 14-notification-l10n: AppLocalizations pipeline complete; Phase 14 adds notification strings

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "ARB format: @@locale first, camelCase semantic keys, @key metadata with type: num for integer placeholders"
    - "ICU plural with explicit =0 case for cross-language safety (en/it/fr/es)"
    - "flutter gen-l10n run standalone (not via build_runner) producing lib/l10n/generated/"

key-files:
  created:
    - lib/l10n/app_en.arb
    - lib/l10n/generated/app_localizations.dart
    - lib/l10n/generated/app_localizations_en.dart

key-decisions:
  - "Placeholder types use num (not int) -- gen-l10n requires num for integer placeholders"
  - "Used -- (double dash) instead of em-dash in ARB string values for cross-platform safety"
  - "79 keys total (exceeds ~67 estimate from RESEARCH.md due to extra settings strings and distinct calendar semantic label keys)"
  - "Generated files committed to git matching .g.dart convention"
  - "synthetic-package deprecation warning acknowledged -- harmless on Flutter 3.44.1, will be cleaned in Phase 13 or later"

requirements-completed: [L10N-01, L10N-02, L10N-03]

# Metrics
duration: 3min
completed: 2026-06-15
---

# Phase 12 Plan 02: Complete ARB Template + flutter gen-l10n Summary

**Complete English ARB template with 79 strings generated via flutter gen-l10n producing a type-safe AppLocalizations class; flutter analyze passes with zero issues.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-06-15T15:12:21Z
- **Completed:** 2026-06-15T15:14:36Z
- **Tasks:** 2
- **Files created:** 3

## Accomplishments

- Created lib/l10n/app_en.arb as valid JSON with @@locale: en as the first entry
- 79 translatable string keys covering all 7 source files: app_router (3), home_screen (13), settings_screen (20), history_screen (9), hydration_calculator_screen (22), permission_screen (6), preset_edit_dialog (5), plus shared mlUnit
- All placeholder keys have @metadata with correct type declarations (num for integers, String for formatted values)
- dayStreak uses ICU plural with explicit =0{No streak} case for cross-language safety (safe across en/it/fr/es per RESEARCH.md)
- Ran flutter gen-l10n producing lib/l10n/generated/app_localizations.dart and app_localizations_en.dart
- flutter analyze passes with zero issues — full project compiles with complete localization pipeline

## Task Commits

Each task was committed atomically:

1. **Task 1: Create complete app_en.arb with all English strings** - `5bb1f35` (feat)
2. **Task 2: Run flutter gen-l10n and verify compilation** - `11131a9` (chore)

**Plan metadata:** (docs commit below)

## Files Created

- `lib/l10n/app_en.arb` — English ARB template: 79 translatable keys, 80 @metadata entries, valid JSON with @@locale: en first
- `lib/l10n/generated/app_localizations.dart` — Abstract AppLocalizations class with delegate, localizationsDelegates, supportedLocales list, lookupAppLocalizations function
- `lib/l10n/generated/app_localizations_en.dart` — English implementation class (AppLocalizationsEn) with all getter methods

## Decisions Made

- Placeholder types use `num` not `int` — gen-l10n expects `num` for integer placeholders; using `int` would produce invalid generated code
- Used `--` (double dash) for `remindersDeclined` string instead of em-dash (from actual source code) for cross-platform ARB safety
- 79 keys instead of ~67 estimate: settings_screen had more strings than RESEARCH.md counted (applyFromTomorrow/Today split keys, section labels), and calendarDay was a distinct key from calendarDayGoalMet/NotMet
- synthetic-package deprecation warning is harmless — Flutter 3.44.1 silently ignores it; the option will be removed from l10n.yaml in a future cleanup

## Deviations from Plan

### Observation (No Fix Required)

**Source files contain Italian/mixed-language strings**

- **Found during:** Task 1 (string inventory)
- **Observation:** settings_screen.dart has Italian UI text ('Applica da domani', 'Ricalcola raccomandazione idratazione', etc.), and hydration_calculator_screen.dart is entirely in Italian. The ARB template correctly uses English values as specified in the plan — these source strings will be replaced in Phase 13 string extraction.
- **Impact:** None — the ARB file is the source of truth for translations. Phase 13 handles widget replacement.

None - plan executed exactly as written with correct English values in the ARB template.

## Issues Encountered

None. flutter gen-l10n ran cleanly (deprecation warning for synthetic-package is harmless). flutter analyze reports zero issues.

## Known Stubs

None. The ARB template is complete with all 79 English strings. Phase 13 will wire these into widgets and add it/fr/es translation files.

## Next Phase Readiness

- Phase 12 is complete: gen-l10n pipeline fully operational
- Phase 13 can proceed: full ARB template defined, context.l10n extension available, AppLocalizations class generated
- Phase 13 work: calculator enum refactor, widget string replacement (`AppLocalizations.of(context)` → `context.l10n`), create app_it.arb / app_fr.arb / app_es.arb translation files

---
*Phase: 12-l10n-infrastructure*
*Completed: 2026-06-15*

## Self-Check: PASSED

Files exist:
- FOUND: lib/l10n/app_en.arb
- FOUND: lib/l10n/generated/app_localizations.dart
- FOUND: lib/l10n/generated/app_localizations_en.dart

Commits exist:
- FOUND: 5bb1f35 (Task 1 - feat ARB)
- FOUND: 11131a9 (Task 2 - chore gen-l10n)

Acceptance criteria:
- app_en.arb valid JSON with 79 keys (>= 67): PASS
- @@locale: en as first entry: PASS
- dayStreak ICU plural with =0 case: PASS
- All placeholder @metadata with type declarations: PASS
- app_localizations.dart contains AppLocalizations class: PASS
- app_localizations.dart contains localizationsDelegates: PASS
- app_localizations.dart contains supportedLocales: PASS
- app_localizations_en.dart contains AppLocalizationsEn class: PASS
- flutter analyze passes with zero issues: PASS
