# Project Research Summary

**Project:** Drinky Drinky v1.3 -- Multilingual Support
**Domain:** Flutter l10n retrofit (adding ARB-based internationalization to existing app)
**Researched:** 2026-06-15
**Confidence:** HIGH

## Executive Summary

Adding multilingual support (English, Italian, French, Spanish) to Drinky Drinky is a well-documented Flutter pattern with no novel technical challenges. The project uses Flutter's built-in `gen-l10n` ARB pipeline -- no third-party l10n packages needed. The only new dependency is `flutter_localizations` (SDK package). The infrastructure is minimal: one `l10n.yaml` config file, four ARB files (~75-85 string keys), and three lines added to `pubspec.yaml`.

The primary complexity is not infrastructure but string extraction. The codebase has a mixed Italian/English baseline (~67 unique strings across 6 screens + 1 dialog + 1 service), and the hydration calculator uses Italian display strings as computation map keys -- a pattern that will crash when localized. This calculator refactor is the single highest-risk task and must happen before or during string extraction.

The NotificationService singleton presents an architectural tension: it has no `BuildContext` but needs localized strings. The recommended approach uses `lookupAppLocalizations()` (a generated top-level function) with `platformDispatcher.locale` to resolve strings without touching the singleton's API or requiring call-site changes. iOS requires `CFBundleLocalizations` in Info.plist or locale detection silently fails.

## Key Findings

### Recommended Stack

No new pub.dev packages. One SDK dependency addition.

**Core additions:**
- `flutter_localizations` (SDK package): provides Material/Cupertino widget translations (date pickers, dialogs, buttons)
- `l10n.yaml` config: drives `flutter gen-l10n` with `synthetic-package: false` (required on Flutter 3.44.1), `nullable-getter: false`
- `pubspec.yaml`: add `generate: true` under `flutter:` (required since Flutter 3.32 for gen-l10n to function)

**No change needed:** `intl ^0.20.2` already present, compatible with SDK's pin. `build_runner` unaffected -- gen-l10n is an independent codegen system.

### Expected Features

**Must have (table stakes):**
- All UI strings translated across 4 locales (en/it/fr/es)
- System locale auto-detection with English fallback
- Notification title/body localized
- Plural forms for streak counter (ICU syntax)
- Calendar month/day names locale-aware (via `intl` + `initializeDateFormatting()`)
- Material widget localization (time picker, dialogs)

**Should have (differentiators):**
- Non-nullable `AppLocalizations.of(context)` getter (cleaner code)
- `context.l10n` extension shorthand
- Notification channel name localized on Android

**Defer (anti-features):**
- In-app language picker (follow system locale)
- Country-variant locales (en_US vs en_GB)
- RTL support (none of the 4 languages need it)
- Translation management platform (4 languages, ~80 keys, single dev)

### Architecture Approach

L10n integrates at three levels: (1) `MaterialApp.router` gets `localizationsDelegates` and `supportedLocales` from generated code, (2) all screens use `AppLocalizations.of(context)` (via `context.l10n` extension) for widget-tree strings, (3) `NotificationService` uses `lookupAppLocalizations(locale)` to resolve strings without `BuildContext`. No Riverpod providers, no routing changes, no database changes needed. The data layer, repositories, and providers are completely unaffected.

**Major components (new/modified):**
1. `lib/l10n/` -- ARB source files + generated `AppLocalizations` classes
2. `lib/l10n/l10n_extension.dart` -- `context.l10n` convenience extension
3. `notification_service.dart` -- `_localizations()` helper using `lookupAppLocalizations` + `platformDispatcher.locale`
4. `hydration_calculator_screen.dart` -- enum-based refactor to decouple computation keys from display labels
5. `ios/Runner/Info.plist` -- `CFBundleLocalizations` array
6. `android/app/build.gradle.kts` -- `resConfigs` for locale filtering

### Critical Pitfalls

1. **Calculator Italian strings as map keys** -- `_sexFactors['Maschio']` crashes when display label changes to `'Male'`. Refactor to enum keys BEFORE string extraction.
2. **NotificationService has no BuildContext** -- use `lookupAppLocalizations()` + `platformDispatcher.locale` internally; do NOT pass context or change the API signature.
3. **`AppLocalizations.of(context)` above MaterialApp** -- crashes at startup. Use `onGenerateTitle` for app title; keep notification channel name hardcoded at init time.
4. **iOS Info.plist missing `CFBundleLocalizations`** -- without it, iOS ignores the app's supported locales and defaults to English.
5. **`initializeDateFormatting()` not called** -- `DateFormat` with non-English locale throws `LocaleDataException`. Must add to `main()` before `runApp()`.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Infrastructure + Calculator Refactor
**Rationale:** Everything else depends on l10n infrastructure existing. Calculator refactor is a prerequisite for safe string extraction (Pitfall 4).
**Delivers:** Working gen-l10n pipeline, `context.l10n` extension, calculator using enum keys, `initializeDateFormatting()` in main
**Addresses:** l10n.yaml, pubspec.yaml changes, flutter_localizations dep, MaterialApp wiring, BiologicalSex enum, climate label decoupling
**Avoids:** Pitfalls 3 (context above MaterialApp), 4 (Italian map keys), 7 (synthetic-package), 8 (output-dir clash), 14 (missing flutter_localizations), 16 (initializeDateFormatting)

### Phase 2: String Extraction + ARB Files
**Rationale:** With infrastructure in place, systematically extract all ~67 strings to ARB. Template (English) first, then translations.
**Delivers:** Complete `app_en.arb` template with all keys + metadata, `app_it.arb`, `app_fr.arb`, `app_es.arb` with translations, all screens using `context.l10n.*`
**Addresses:** All table-stakes features (translated UI, plurals, parameterized strings, `_monthName()` replacement, table_calendar locale)
**Avoids:** Pitfalls 2 (missed strings), 9 (const removal), 12 (string concatenation), 17 (mixed Italian/English baseline)

### Phase 3: NotificationService + Platform Config
**Rationale:** Notification l10n is isolated from UI work. Platform config (iOS/Android) can be done in parallel.
**Delivers:** Localized notification title/body, iOS CFBundleLocalizations, Android resConfigs, localized notification channel name
**Addresses:** Notification l10n, platform declarations
**Avoids:** Pitfalls 1 (singleton no context), 5 (iOS Info.plist), 6 (Android resConfigs)

### Phase 4: Testing + Verification
**Rationale:** After all strings are extracted and platforms configured, verify end-to-end across all 4 locales.
**Delivers:** Updated widget tests with l10n helper, locale-specific test cases, manual verification checklist
**Addresses:** Test infrastructure, French plural edge cases
**Avoids:** Pitfalls 10 (French plurals), 15 (widget test breakage)

### Phase Ordering Rationale

- Phase 1 before Phase 2: cannot extract strings without gen-l10n infrastructure; calculator refactor prevents crashes during extraction
- Phase 2 before Phase 3: notification strings are defined in ARB files created in Phase 2
- Phase 3 before Phase 4: platform config affects locale detection behavior tested in Phase 4
- Phases 2 and 3 could partially overlap since notification l10n is independent of screen string extraction

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 2:** Large scope (~67 strings across 7 files). Needs a file-by-file extraction plan to avoid missed strings. The mixed Italian/English baseline adds complexity.

Phases with standard patterns (skip research-phase):
- **Phase 1:** Well-documented Flutter pattern; l10n.yaml config is mechanical
- **Phase 3:** `lookupAppLocalizations` pattern verified in Flutter SDK source; Info.plist change is one-time
- **Phase 4:** Standard Flutter testing patterns

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Only 1 new SDK dep; all versions verified on pub.dev; no conflicts |
| Features | HIGH | ~67 strings inventoried file-by-file; ARB patterns well-documented |
| Architecture | HIGH | `lookupAppLocalizations` verified in Flutter SDK source code; data flow diagrams complete |
| Pitfalls | HIGH | 20 pitfalls identified via direct codebase analysis + official docs |

**Overall confidence:** HIGH

### Gaps to Address

- **Translation quality:** Research assumes human-written translations for all 4 locales. Who writes the Italian, French, and Spanish translations is not addressed. Plan for this during Phase 2.
- **Notification channel name timing:** Channel is created in `initialize()` before MaterialApp exists. The `lookupAppLocalizations` approach works here too, but channel re-creation on language change needs manual testing on Android.
- **`output-dir` discrepancy:** STACK.md omits `output-dir`, FEATURES.md uses `output-dir: lib/l10n/generated`, ARCHITECTURE.md uses `output-dir: lib/l10n/generated`. Recommend using `output-dir` to separate generated from source ARB files. Settle this in Phase 1.

## Sources

### Primary (HIGH confidence)
- Flutter internationalization docs (Context7, docs.flutter.dev) -- ARB syntax, gen-l10n, MaterialApp wiring, locale resolution
- Flutter SDK source (`gen_l10n.dart`, `gen_l10n_templates.dart`) -- verified `lookupAppLocalizations` generation
- Flutter breaking changes: synthetic-package removal (docs.flutter.dev)
- pub.dev package pages (intl, flutter_localizations) -- version verification
- Direct codebase analysis -- all screens, services, config files inspected

### Secondary (MEDIUM confidence)
- CLDR plural rules (unicode.org) -- French 0/1 singular rule
- table_calendar Context7 docs -- locale property behavior
- Android notification channel re-creation behavior -- documented but edge cases need testing

---
*Research completed: 2026-06-15*
*Ready for roadmap: yes*
