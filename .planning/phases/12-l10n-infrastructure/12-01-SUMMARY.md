---
phase: 12-l10n-infrastructure
plan: 01
subsystem: infra
tags: [flutter, l10n, gen-l10n, intl, table_calendar, MaterialApp, localization]

# Dependency graph
requires:
  - phase: 11-hydration-calculator
    provides: complete v1.2 codebase with all screens implemented
provides:
  - l10n.yaml with gen-l10n configuration (synthetic-package: false, nullable-getter: false)
  - flutter_localizations SDK dependency in pubspec.yaml
  - generate: true flag in pubspec.yaml flutter section
  - lib/l10n/l10n_extensions.dart — context.l10n ergonomic accessor via AppLocalizationsX
  - main.dart wired with initializeDateFormatting() + AppLocalizations delegates/supportedLocales
  - TableCalendar locale parameter wired in history_screen.dart
affects:
  - 12-02: generates app_en.arb and runs flutter gen-l10n against this config
  - 13-string-extraction: uses context.l10n extension established here
  - 14-notification-l10n: depends on AppLocalizations pipeline established here

# Tech tracking
tech-stack:
  added:
    - flutter_localizations (Flutter SDK package, sdk: flutter)
  patterns:
    - gen-l10n with synthetic-package: false and output-dir: lib/l10n/generated/
    - AppLocalizationsX on BuildContext extension for context.l10n ergonomic access
    - initializeDateFormatting() called before runApp() for intl date locale data

key-files:
  created:
    - l10n.yaml
    - lib/l10n/l10n_extensions.dart
  modified:
    - pubspec.yaml
    - lib/main.dart
    - lib/presentation/screens/history_screen.dart

key-decisions:
  - "Use synthetic-package: false (required on Flutter 3.44.1 — old flutter_gen path removed after 3.32)"
  - "output-dir: lib/l10n/generated/ to separate generated code from hand-authored ARB files"
  - "nullable-getter: false eliminates ! operators on every AppLocalizations.of(context) call"
  - "preferred-supported-locales: [en] ensures English is first in supportedLocales for correct fallback"
  - "Use AppLocalizations.localizationsDelegates generated convenience getter (includes all 4 delegates)"
  - "initializeDateFormatting() called with no args — loads all locale data for table_calendar intl usage"
  - "TableCalendar locale wired in Phase 12 as infrastructure (not deferred to Phase 13 string extraction)"

patterns-established:
  - "Pattern: AppLocalizationsX extension on BuildContext — context.l10n instead of AppLocalizations.of(context)"
  - "Pattern: import from package:drinky_drinky/l10n/generated/app_localizations.dart (not flutter_gen)"

requirements-completed: [L10N-01, L10N-02, L10N-03]

# Metrics
duration: 1min
completed: 2026-06-15
---

# Phase 12 Plan 01: L10n Infrastructure Summary

**Flutter gen-l10n pipeline configured with flutter_localizations SDK dep, l10n.yaml (synthetic-package: false), MaterialApp.router wired with localizationsDelegates/supportedLocales, initializeDateFormatting() in main(), and TableCalendar locale parameter.**

## Performance

- **Duration:** 1 min
- **Started:** 2026-06-15T13:08:37Z
- **Completed:** 2026-06-15T13:09:45Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Configured gen-l10n pipeline: l10n.yaml with synthetic-package: false, nullable-getter: false, output-dir: lib/l10n/generated — correct for Flutter 3.44.1
- Added flutter_localizations SDK dependency and generate: true flag to pubspec.yaml (both required since Flutter 3.32)
- Created lib/l10n/l10n_extensions.dart with AppLocalizationsX extension providing context.l10n ergonomic access
- Wired MaterialApp.router with AppLocalizations.localizationsDelegates (all 4 delegates including Cupertino) and AppLocalizations.supportedLocales
- Called initializeDateFormatting() in main() before timezone init — required for table_calendar to render month/day names in non-English locales
- Added locale: Localizations.localeOf(context).toString() to TableCalendar in history_screen.dart

## Task Commits

Each task was committed atomically:

1. **Task 1: Configure l10n pipeline and pubspec dependencies** - `c8e4796` (chore)
2. **Task 2: Wire MaterialApp.router, initializeDateFormatting, and TableCalendar locale** - `a00d8b0` (feat)

**Plan metadata:** (docs commit below)

## Files Created/Modified

- `l10n.yaml` — gen-l10n configuration: arb-dir, template-arb-file, output-localization-file, output-class, output-dir, synthetic-package, nullable-getter, preferred-supported-locales
- `lib/l10n/l10n_extensions.dart` — AppLocalizationsX on BuildContext providing context.l10n accessor
- `pubspec.yaml` — Added flutter_localizations SDK dep and generate: true under flutter: section
- `lib/main.dart` — Added intl date_symbol_data_local import, AppLocalizations import, initializeDateFormatting() call, localizationsDelegates, supportedLocales
- `lib/presentation/screens/history_screen.dart` — Added locale: Localizations.localeOf(context).toString() as first param on TableCalendar

## Decisions Made

- Used AppLocalizations.localizationsDelegates convenience getter (generated, includes all 4 delegates including GlobalCupertinoLocalizations for iOS time pickers per D-03)
- Kept title: 'Drinky Drinky' as non-localized brand name per open question resolution in RESEARCH.md
- Import path uses package:drinky_drinky/l10n/generated/app_localizations.dart (not package:flutter_gen — removed after Flutter 3.32)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. Note: The codebase will not compile until Plan 02 creates app_en.arb and runs flutter gen-l10n — this is expected and documented in the plan. The generated file lib/l10n/generated/app_localizations.dart is referenced but does not exist yet.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None. This plan creates infrastructure files only. The AppLocalizations class referenced in imports does not exist yet (generated in Plan 02) — this is an intentional pipeline dependency, not a stub.

## Next Phase Readiness

- Plan 02 can proceed immediately: create app_en.arb with all ~67 English strings and run flutter gen-l10n to produce lib/l10n/generated/app_localizations.dart
- After Plan 02, flutter analyze will pass and the app will compile
- The context.l10n extension is ready for Phase 13 string replacement work

---
*Phase: 12-l10n-infrastructure*
*Completed: 2026-06-15*

## Self-Check: PASSED

Files exist:
- FOUND: l10n.yaml
- FOUND: lib/l10n/l10n_extensions.dart

Commits exist:
- FOUND: c8e4796 (Task 1)
- FOUND: a00d8b0 (Task 2)

Acceptance criteria:
- pubspec.yaml has flutter_localizations: PASS
- pubspec.yaml has generate: true: PASS
- l10n.yaml exists with synthetic-package: false: PASS
- l10n.yaml has nullable-getter: false: PASS
- lib/l10n/l10n_extensions.dart exists with AppLocalizationsX: PASS
- main.dart has initializeDateFormatting: PASS
- main.dart has AppLocalizations.localizationsDelegates: PASS
- main.dart has AppLocalizations.supportedLocales: PASS
- history_screen.dart has Localizations.localeOf(context).toString(): PASS
