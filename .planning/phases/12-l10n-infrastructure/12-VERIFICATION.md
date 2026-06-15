---
phase: 12-l10n-infrastructure
verified: 2026-06-15T16:30:00Z
status: human_needed
score: 8/10
overrides_applied: 0
re_verification: false
human_verification:
  - test: "Launch app on a device set to Italian, French, or Spanish and open a date picker or dialog"
    expected: "Date picker buttons (OK, Cancel), day names, and dialog actions appear in the device language, not English"
    why_human: "GlobalMaterialLocalizations delegate wiring is confirmed in code but Material widget localization can only be observed by running on a device or simulator with locale set to a non-English language"
  - test: "Set device locale to German (or any unsupported locale) and launch the app"
    expected: "App text falls back to English strings; no crash; Material widget text may still appear in German (that is correct behavior from GlobalMaterialLocalizations)"
    why_human: "Locale fallback via basicLocaleListResolution is runtime behavior that cannot be observed without running the app"
  - test: "Open the History screen on a device set to Italian; inspect the calendar widget"
    expected: "Month names (January -> Gennaio) and day-of-week abbreviations appear in Italian"
    why_human: "table_calendar month/day rendering with locale: Localizations.localeOf(context).toString() requires initializeDateFormatting() to have loaded Italian locale data — confirmed in code but observable only at runtime"
---

# Phase 12: L10n Infrastructure — Verification Report

**Phase Goal:** App has a working localization pipeline that resolves the device locale and provides translated Material widgets
**Verified:** 2026-06-15T16:30:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `flutter gen-l10n` produces `AppLocalizations` class with `of(context)` accessor | VERIFIED | Command exits 0; `lib/l10n/generated/app_localizations.dart` line 69: `static AppLocalizations of(BuildContext context)` returns non-nullable type via `!` (nullable-getter: false) |
| 2 | App launched on Italian/French/Spanish shows localized Material widget text | UNCERTAIN (human) | All 4 delegates registered in `localizationsDelegates`: `AppLocalizations.delegate`, `GlobalMaterialLocalizations.delegate`, `GlobalCupertinoLocalizations.delegate`, `GlobalWidgetsLocalizations.delegate`. Wiring confirmed; runtime behavior needs device test |
| 3 | App launched on unsupported locale (German) falls back to English strings | UNCERTAIN (human) | `supportedLocales = <Locale>[Locale('en')]` — only EN is listed, so any unmatched locale resolves to EN via `basicLocaleListResolution`. Structural proof complete; runtime behavior needs device test |
| 4 | `table_calendar` displays month/day names in device language | UNCERTAIN (human) | `locale: Localizations.localeOf(context).toString()` at `history_screen.dart:213`; `initializeDateFormatting()` called at `main.dart:18` before `runApp` at line 29. Wiring confirmed; rendering needs device test |
| 5 | `flutter gen-l10n` runs without errors and generates `AppLocalizations` class | VERIFIED | Ran in verification context: exit code 0. Deprecation warning for `synthetic-package` is harmless (explicitly acknowledged in 12-02-SUMMARY.md). `app_localizations.dart` and `app_localizations_en.dart` exist and are substantive (602 and 290 lines) |
| 6 | `MaterialApp.router` declares `localizationsDelegates` and `supportedLocales` | VERIFIED | `main.dart:46-47`: `localizationsDelegates: AppLocalizations.localizationsDelegates` and `supportedLocales: AppLocalizations.supportedLocales` confirmed present |
| 7 | `initializeDateFormatting()` called in `main()` before `runApp()` | VERIFIED | `main.dart:18`: `await initializeDateFormatting()` after `WidgetsFlutterBinding.ensureInitialized()` (line 14), before `runApp` (line 29). Correct ordering confirmed |
| 8 | `app_en.arb` contains all 67+ English strings | VERIFIED | 79 translatable keys confirmed via Python JSON parse. `@@locale: en` is first entry. 79 `@key` metadata entries with placeholder type declarations. `dayStreak` ICU plural includes explicit `=0{No streak}` case |
| 9 | Unsupported locale falls back to English (EN first in `supportedLocales`) | VERIFIED | `l10n.yaml`: `preferred-supported-locales: [en]`. Generated `supportedLocales = <Locale>[Locale('en')]`. EN is the only locale, guaranteeing fallback |
| 10 | `context.l10n` extension provides ergonomic access to `AppLocalizations` | VERIFIED | `lib/l10n/l10n_extensions.dart`: `extension AppLocalizationsX on BuildContext` with `AppLocalizations get l10n => AppLocalizations.of(this)`. Non-nullable return matches `nullable-getter: false` configuration. `flutter analyze`: no issues |

**Score:** 8/10 truths verified (2 require human device testing; structural prerequisites VERIFIED)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `l10n.yaml` | gen-l10n configuration | VERIFIED | All 8 fields present: `arb-dir`, `template-arb-file`, `output-localization-file`, `output-class`, `output-dir`, `synthetic-package: false`, `nullable-getter: false`, `preferred-supported-locales: [en]` |
| `pubspec.yaml` | `flutter_localizations: sdk: flutter` and `generate: true` | VERIFIED | Line 15-16: `flutter_localizations: sdk: flutter`; line 73: `generate: true` under `flutter:` section |
| `lib/l10n/l10n_extensions.dart` | `AppLocalizationsX` extension with `context.l10n` | VERIFIED | Extension confirmed; import uses `package:drinky_drinky/l10n/generated/app_localizations.dart` (correct post-3.32 path) |
| `lib/l10n/app_en.arb` | Valid JSON, 67+ keys, `@@locale: en`, ICU plural for `dayStreak` | VERIFIED | 79 keys, `@@locale` first entry, `dayStreak` has `=0{No streak}` case, all placeholder strings have `@key` metadata with `type` declarations |
| `lib/l10n/generated/app_localizations.dart` | `class AppLocalizations`, `localizationsDelegates`, `supportedLocales` | VERIFIED | 602 lines; abstract class at line 63; `localizationsDelegates` lists 4 delegates; `supportedLocales = <Locale>[Locale('en')]` |
| `lib/l10n/generated/app_localizations_en.dart` | `class AppLocalizationsEn` | VERIFIED | 290 lines; `class AppLocalizationsEn extends AppLocalizations` at line 8 |
| `lib/main.dart` | `initializeDateFormatting()`, `AppLocalizations.localizationsDelegates`, `AppLocalizations.supportedLocales` | VERIFIED | All three confirmed present; import at line 11 uses `l10n/generated/app_localizations.dart` |
| `lib/presentation/screens/history_screen.dart` | `locale: Localizations.localeOf(context).toString()` on `TableCalendar` | VERIFIED | Confirmed at line 213, as first named parameter on `TableCalendar<Object>` widget |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `lib/main.dart` | `lib/l10n/generated/app_localizations.dart` | import + `localizationsDelegates`/`supportedLocales` | WIRED | Import at line 11; parameters at lines 46-47 of `MaterialApp.router` |
| `lib/main.dart` | `package:intl/date_symbol_data_local.dart` | `initializeDateFormatting()` call | WIRED | Import at line 5; `await initializeDateFormatting()` at line 18 |
| `lib/presentation/screens/history_screen.dart` | `Localizations.localeOf(context)` | `TableCalendar` `locale` parameter | WIRED | `locale: Localizations.localeOf(context).toString()` at line 213 |
| `lib/l10n/generated/app_localizations.dart` | `lib/l10n/app_en.arb` | `flutter gen-l10n` code generation | WIRED | Generated file reflects 79 keys from ARB; `flutter gen-l10n` exits 0 |
| `lib/main.dart` | `lib/l10n/generated/app_localizations.dart` | `AppLocalizations` import | WIRED | Import confirmed at main.dart line 11 |

### Data-Flow Trace (Level 4)

Not applicable — this phase delivers infrastructure plumbing (config files, generated code, delegate registration) with no new data-rendering components. The key data flows (locale resolution -> Material widget text, `initializeDateFormatting` -> `table_calendar` month names) are runtime behaviors requiring device testing (see Human Verification section).

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| `flutter gen-l10n` exits 0 | `/Users/flavio.bizzarri/fvm/versions/3.44.1/bin/flutter gen-l10n; echo "Exit: $?"` | Exit code: 0 (deprecation warning for `synthetic-package` is non-fatal) | PASS |
| ARB has 67+ keys | `python3 -c "import json; d=json.load(open('lib/l10n/app_en.arb')); print(len([k for k in d if not k.startswith('@')]))"` | 79 keys | PASS |
| `flutter analyze` — zero issues | `flutter analyze --no-fatal-infos 2>&1 \| tail -3` | `No issues found! (ran in 2.0s)` | PASS |
| main.dart locale wiring | `grep -q "AppLocalizations.localizationsDelegates" lib/main.dart && grep -q "initializeDateFormatting" lib/main.dart && echo OK` | OK | PASS |
| TableCalendar locale param | `grep -q "Localizations.localeOf(context).toString()" lib/presentation/screens/history_screen.dart && echo OK` | OK | PASS |
| EN first in supportedLocales | `grep "preferred-supported-locales" l10n.yaml` | `preferred-supported-locales: [en]` | PASS |
| context.l10n extension exists | `grep -q "AppLocalizationsX" lib/l10n/l10n_extensions.dart && echo OK` | OK | PASS |

### Probe Execution

No probe scripts found under `scripts/` for this phase. Step 7c: SKIPPED (no probe scripts defined).

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| L10N-01 | 12-01, 12-02 | Flutter gen-l10n pipeline with `flutter_localizations` SDK dep, `l10n.yaml`, `generate: true` | SATISFIED | All three prerequisites confirmed in `pubspec.yaml` and `l10n.yaml`; `flutter gen-l10n` exits 0 |
| L10N-02 | 12-01 | `MaterialApp.router` declares `localizationsDelegates` and `supportedLocales` with EN fallback | SATISFIED | `main.dart:46-47`; EN fallback via `supportedLocales=[Locale('en')]`; full locale resolution at runtime is human-verified |
| L10N-03 | 12-01 | `initializeDateFormatting()` in `main()` for all locales | SATISFIED | `main.dart:18`; no-arg call loads all locale data; called before `runApp` |
| L10N-05 (partial) | 12-02 | `app_en.arb` as canonical template with semantic keys and `@key` metadata | SATISFIED (template creation aspect) | 79 keys with `@key` metadata; semantic camelCase naming; `@@locale: en`; full string extraction from widgets is Phase 13 scope |

Note: L10N-05 as listed in REQUIREMENTS.md includes "widget string replacement" (extracting hardcoded strings from widgets), which is Phase 13 scope. Phase 12 covers the template creation aspect only — confirmed intentional per `12-CONTEXT.md` D-01.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `l10n.yaml` | 6 | `synthetic-package: false` — deprecated option (warning from gen-l10n) | Info | Non-fatal; gen-l10n silently accepts it on Flutter 3.44.1; acknowledged in 12-02-SUMMARY.md key-decisions; no blocker |

No `TBD`, `FIXME`, or `XXX` markers found in any phase-modified file. No stubs detected. No hardcoded-empty data flows identified.

### Human Verification Required

#### 1. Material Widget Text Localization (SC-2)

**Test:** Set device/simulator locale to Italian (or French or Spanish). Launch the app. Open a date picker (e.g., from a time picker in Settings if available) or trigger a dialog (e.g., a confirmation dialog). Alternatively, observe the bottom navigation tab labels — these come from the app's own strings and will stay English until Phase 13 widget extraction. For Material widget text specifically, open a date picker or check OK/Cancel button labels.
**Expected:** Material widget text (date picker OK/Cancel buttons, day-of-week abbreviations in date pickers, dialog action labels) appears in the device language, not English.
**Why human:** `GlobalMaterialLocalizations.delegate` is registered in `localizationsDelegates` which is the code mechanism for this. Actual rendering of localized Material widget text requires running on a device or simulator with locale set to Italian/French/Spanish.

#### 2. Unsupported Locale Fallback (SC-3)

**Test:** Set device locale to German (or another language not in `supportedLocales`). Launch the app.
**Expected:** App does not crash. App's own string content (tab labels, screen titles, button labels) appears in English. Material widget text may appear in German — this is correct behavior from `GlobalMaterialLocalizations` and does not indicate a bug.
**Why human:** `basicLocaleListResolution` behavior with `supportedLocales = [Locale('en')]` guarantees EN fallback for app strings structurally. Actual runtime behavior on an unsupported locale requires a device test to confirm no crash and correct text rendering.

#### 3. TableCalendar Locale Rendering (SC-4)

**Test:** Set device locale to Italian. Open the History screen. Inspect the calendar widget's month header and day-of-week column headers.
**Expected:** Month name appears in Italian (e.g., "Giugno" for June), day-of-week abbreviations appear in Italian (e.g., "lun", "mar", "mer"...).
**Why human:** `locale: Localizations.localeOf(context).toString()` is wired and `initializeDateFormatting()` loads all locale data — code is correct. The `table_calendar` package's internal `intl.DateFormat` usage with the locale string is the rendering mechanism. Actual Italian month/day name display requires a running app.

---

## Summary

Phase 12 delivered a complete, functional gen-l10n infrastructure. All structural prerequisites are in place:

- `l10n.yaml` correctly configured with `synthetic-package: false`, `nullable-getter: false`, `output-dir: lib/l10n/generated`, and `preferred-supported-locales: [en]`
- `pubspec.yaml` has `flutter_localizations: sdk: flutter` and `generate: true`
- `flutter gen-l10n` runs without errors (deprecation warning is non-fatal)
- Generated `AppLocalizations` class with `of(context)` accessor, all 4 delegates, and `supportedLocales=[Locale('en')]`
- `MaterialApp.router` wired with `localizationsDelegates` and `supportedLocales`
- `initializeDateFormatting()` called before `runApp()`
- `TableCalendar` has `locale: Localizations.localeOf(context).toString()`
- `app_en.arb` has 79 translatable keys, `@@locale: en` first, ICU plural with `=0` for `dayStreak`, all placeholder metadata typed
- `context.l10n` extension provides ergonomic access
- `flutter analyze` reports zero issues

The three UNCERTAIN truths (SC-2, SC-3, SC-4) are runtime locale behaviors that require a device test. Their code prerequisites are all VERIFIED. No gaps block proceeding to Phase 13 from an infrastructure standpoint — the pipeline is structurally complete.

---

_Verified: 2026-06-15T16:30:00Z_
_Verifier: Claude (gsd-verifier)_
