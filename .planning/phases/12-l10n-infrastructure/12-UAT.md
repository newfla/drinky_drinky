---
status: complete
phase: 12-l10n-infrastructure
source: [12-01-SUMMARY.md, 12-02-SUMMARY.md]
started: 2026-06-15T15:30:00Z
updated: 2026-06-15T15:30:00Z
---

## Current Test

[testing complete]

## Tests

### 1. App builds and runs without errors
expected: Run `flutter run` (or build for simulator/device). The app starts without compilation errors. No red screen, no "AppLocalizations not found" crash. The l10n pipeline wiring should be transparent — the app behaves exactly as before Phase 12 from a user perspective (strings are still hardcoded; Phase 13 replaces them).
result: pass

### 2. Time picker buttons localized (iOS)
expected: On an iOS device/simulator set to Italian, open Settings → Do Not Disturb → tap "Start time". The time picker's OK and Cancel buttons should appear in Italian ("OK" stays "OK", but "Cancel" → "Annulla"). This confirms GlobalCupertinoLocalizations.delegate is active.
result: pass
note: initially failed (supportedLocales=[en] only); fixed by adding stub it/fr/es ARBs (commit 2d49744)

### 3. English fallback for unsupported locale
expected: Set device/simulator locale to German (Deutsch). Launch the app. It should not crash and should display the same UI as English (no missing strings, no "???" placeholders). German is not in supportedLocales so basicLocaleListResolution falls back to English automatically.
result: pass

### 4. TableCalendar shows localized month/day names
expected: Set device/simulator locale to Italian. Open the History tab. The calendar should display month names in Italian (e.g., "giugno" for June) and day-of-week abbreviations in Italian (lun, mar, mer, gio, ven, sab, dom). This confirms initializeDateFormatting() + TableCalendar locale parameter are working.
result: pass
note: initially failed (supportedLocales=[en] only); fixed by adding stub it/fr/es ARBs (commit 2d49744)

### 5. TableCalendar shows localized month/day names in French
expected: Set device/simulator locale to French. Open the History tab. The calendar should display month names in French (e.g., "juin" for June) and day abbreviations in French (lun., mar., mer., etc.).
result: pass
note: initially failed (supportedLocales=[en] only); fixed by adding stub it/fr/es ARBs (commit 2d49744)

## Summary

total: 5
passed: 5
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "iOS time picker Cancel button shows 'Annulla' when device locale is Italian"
  status: failed
  reason: "User reported: mostra in inglese"
  severity: major
  test: 2
  root_cause: "AppLocalizations.supportedLocales = [Locale('en')] only — stub app_it/fr/es.arb files were missing, so basicLocaleListResolution always fell back to English. Fixed by adding stub ARBs and re-running flutter gen-l10n (commit 2d49744)."
  artifacts:
    - path: "lib/l10n/generated/app_localizations.dart"
      issue: "supportedLocales contained only Locale('en')"
  missing:
    - "lib/l10n/app_it.arb"
    - "lib/l10n/app_fr.arb"
    - "lib/l10n/app_es.arb"
  debug_session: ""
- truth: "TableCalendar displays month and day names in Italian when device locale is Italian"
  status: failed
  reason: "User reported: no sono visualizzati in inglese"
  severity: major
  test: 4
  root_cause: "AppLocalizations.supportedLocales = [Locale('en')] only — stub app_it/fr/es.arb files were missing, so basicLocaleListResolution always fell back to English. Fixed by adding stub ARBs and re-running flutter gen-l10n (commit 2d49744)."
  artifacts:
    - path: "lib/l10n/generated/app_localizations.dart"
      issue: "supportedLocales contained only Locale('en')"
  missing:
    - "lib/l10n/app_it.arb"
    - "lib/l10n/app_fr.arb"
    - "lib/l10n/app_es.arb"
  debug_session: ""
- truth: "TableCalendar displays month and day names in French when device locale is French"
  status: failed
  reason: "User reported: rimane in inglese"
  severity: major
  test: 5
  root_cause: "AppLocalizations.supportedLocales = [Locale('en')] only — stub app_it/fr/es.arb files were missing, so basicLocaleListResolution always fell back to English. Fixed by adding stub ARBs and re-running flutter gen-l10n (commit 2d49744)."
  artifacts:
    - path: "lib/l10n/generated/app_localizations.dart"
      issue: "supportedLocales contained only Locale('en')"
  missing:
    - "lib/l10n/app_it.arb"
    - "lib/l10n/app_fr.arb"
    - "lib/l10n/app_es.arb"
  debug_session: ""
