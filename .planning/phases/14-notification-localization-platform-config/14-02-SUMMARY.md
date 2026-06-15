---
phase: 14-notification-localization-platform-config
plan: 02
subsystem: infra
tags: [ios, android, plist, gradle, l10n, locale-detection]

# Dependency graph
requires:
  - phase: 12-l10n-infrastructure
    provides: l10n infrastructure with supportedLocales (en, it, fr, es)
provides:
  - iOS CFBundleLocalizations declaring 4 supported locales
  - Android resourceConfigurations stripping unneeded locale resources from APK
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Platform locale declaration must mirror supportedLocales in MaterialApp"

key-files:
  created: []
  modified:
    - ios/Runner/Info.plist
    - android/app/build.gradle.kts

key-decisions:
  - "CFBundleLocalizations includes en explicitly alongside it/fr/es for unambiguous locale set"
  - "resourceConfigurations uses Kotlin DSL += setOf() syntax per D-05"

patterns-established:
  - "iOS Info.plist keys kept in alphabetical order per Apple convention"
  - "Android defaultConfig resourceConfigurations limits APK locale resources to app-supported set"

requirements-completed: [L10N-08, L10N-09]

# Metrics
duration: 1min
completed: 2026-06-15
---

# Phase 14 Plan 02: Platform Config Summary

**iOS CFBundleLocalizations and Android resourceConfigurations declaring en/it/fr/es as supported locales**

## Performance

- **Duration:** 1 min
- **Started:** 2026-06-15T15:44:55Z
- **Completed:** 2026-06-15T15:45:39Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- iOS Info.plist now declares CFBundleLocalizations with en, it, fr, es so the OS correctly passes the preferred locale to the Flutter engine
- Android build.gradle.kts now includes resourceConfigurations to strip unneeded locale resources from the APK, reducing bundle size

## Task Commits

Each task was committed atomically:

1. **Task 1: Add CFBundleLocalizations to Info.plist** - `3c624d7` (feat)
2. **Task 2: Add resourceConfigurations to build.gradle.kts** - `bed78e5` (feat)

## Files Created/Modified
- `ios/Runner/Info.plist` - Added CFBundleLocalizations array with en, it, fr, es
- `android/app/build.gradle.kts` - Added resourceConfigurations += setOf("en", "it", "fr", "es") inside defaultConfig

## Decisions Made
None - followed plan as specified. Both edits matched the locked decisions D-04 and D-05 from 14-CONTEXT.md.

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- iOS and Android platform configs are complete for the 4 supported locales
- Combined with 14-01 (notification localization), Phase 14 delivers full notification l10n and platform locale support
- All v1.3 localization requirements should now be complete

## Self-Check: PASSED

- All 2 modified files verified present
- Both commit hashes (3c624d7, bed78e5) found in git log
- CFBundleLocalizations count: 1 (expected 1)
- resourceConfigurations count: 1 (expected 1)

---
*Phase: 14-notification-localization-platform-config*
*Completed: 2026-06-15*
