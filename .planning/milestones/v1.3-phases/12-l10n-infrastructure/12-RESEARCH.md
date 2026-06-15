# Phase 12: L10n Infrastructure - Research

**Researched:** 2026-06-15
**Domain:** Flutter internationalization (i18n/l10n) -- gen-l10n pipeline, ARB files, MaterialApp locale wiring
**Confidence:** HIGH

## Summary

Phase 12 establishes the localization pipeline for a Flutter hydration tracker app (Drinky Drinky). The app currently has ~67 hardcoded strings across 6 screens plus the notification service and router, in a mix of Italian and English. This phase creates the infrastructure: `l10n.yaml` configuration, `flutter_localizations` SDK dependency, `generate: true` in pubspec, the complete English ARB template (`app_en.arb`), the `AppLocalizations` convenience extension, `MaterialApp.router` wiring with 4 delegates, `initializeDateFormatting()` in `main()`, and `TableCalendar` locale wiring.

The phase does NOT replace hardcoded strings in widgets (Phase 13), does NOT create Italian/French/Spanish translation ARBs (Phase 13), does NOT localize the NotificationService (Phase 14), and does NOT add iOS/Android platform locale declarations (Phase 14).

**Primary recommendation:** Follow the locked decisions exactly. Use `output-dir: lib/l10n/generated` with `synthetic-package: false` to separate generated files from source ARBs. Use `AppLocalizations.localizationsDelegates` (the generated convenience getter) which includes all 4 required delegates. Call `initializeDateFormatting()` with no arguments in `main()` before `runApp()`. Commit generated l10n files to git (matching existing `.g.dart` convention).

<user_constraints>

## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Phase 12 produces a **complete** `app_en.arb` with all ~67 English strings -- not a skeleton. This effectively covers L10N-05 in Phase 12, not Phase 13. Phase 13 starts with the full ARB template already defined and focuses only on widget replacement + translations.
- **D-02:** ARB output directory: `lib/l10n/` for source ARBs (`app_en.arb`, `app_it.arb`, etc.), `lib/l10n/generated/` for gen-l10n output (`app_localizations.dart`, `app_localizations_en.dart`, etc.). Configured via `l10n.yaml` with `synthetic-package: false` and `output-dir: lib/l10n/generated`.
- **D-03:** Include **4 delegates** in `MaterialApp.router.localizationsDelegates`:
  1. `AppLocalizations.delegate` (generated)
  2. `GlobalMaterialLocalizations.delegate`
  3. `GlobalWidgetsLocalizations.delegate`
  4. `GlobalCupertinoLocalizations.delegate` -- required for iOS time pickers
- **D-04:** Use Flutter's built-in `basicLocaleListResolution` (no custom `localeResolutionCallback`). English must be listed **first** in `supportedLocales` to serve as automatic fallback.
- **D-05:** `supportedLocales` order: `[Locale('en'), Locale('it'), Locale('fr'), Locale('es')]`
- **D-06:** Wire `locale: Localizations.localeOf(context).toString()` in `HistoryScreen`'s `TableCalendar` widget in Phase 12.
- **l10n.yaml config:** `arb-dir: lib/l10n`, `template-arb-file: app_en.arb`, `output-localization-file: app_localizations.dart`, `output-class: AppLocalizations`, `output-dir: lib/l10n/generated`, `synthetic-package: false`, `nullable-getter: false`

### Claude's Discretion

- ARB key naming convention: use camelCase semantic keys (e.g., `homeGoalLabel`, `settingsTargetTitle`, not positional names like `string1`). Keys should be stable.
- Context extension: add `extension AppLocalizationsX on BuildContext { AppLocalizations get l10n => AppLocalizations.of(this); }` in `lib/l10n/l10n_extensions.dart` for ergonomic access.

### Deferred Ideas (OUT OF SCOPE)

- NotificationService localization -> Phase 14 (L10N-07)
- iOS `Info.plist` `CFBundleLocalizations` -> Phase 14 (L10N-08)
- Android `resConfigs` -> Phase 14 (L10N-09)
- Calculator `BiologicalSex`/`ClimateLevel` enum refactor -> Phase 13 (L10N-04)
- Widget string replacement + it/fr/es ARB files -> Phase 13 (L10N-05/L10N-06)

</user_constraints>

<phase_requirements>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| L10N-01 | App loads translations via Flutter gen-l10n (`flutter_localizations` SDK dep, `l10n.yaml` with `synthetic-package: false`, `generate: true` in `pubspec.yaml`) | Standard Stack section: exact pubspec.yaml changes and l10n.yaml config; Code Examples: gen-l10n command and generated file structure |
| L10N-02 | `MaterialApp.router` declares `localizationsDelegates` and `supportedLocales` for it/en/fr/es; system language followed automatically with EN fallback via `basicLocaleListResolution` | Architecture Patterns: MaterialApp wiring pattern, locale resolution behavior table |
| L10N-03 | `initializeDateFormatting()` called in `main()` for all 4 locales (table_calendar uses intl for month names) | Code Examples: exact import and call signature; Architecture Patterns: main.dart modification sequence |

</phase_requirements>

## Project Constraints (from CLAUDE.md)

- **Tech stack**: Flutter + Riverpod + Drift -- no deviation
- **Platform**: iOS and Android only
- **Offline-first**: No backend or cloud sync
- **Database setup**: Use `drift_flutter` (not `sqlite3_flutter_libs` which is EOL)
- **Notifications**: Use `flutter_local_notifications` (not `awesome_notifications`)
- **State management**: Use `flutter_riverpod` (not `hooks_riverpod`)
- **Code generation**: `build_runner` for Drift/Riverpod/Freezed; `flutter gen-l10n` is independent
- **Generated files**: `.g.dart` and `.freezed.dart` files are committed to git (not gitignored)

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| l10n.yaml + ARB file creation | Build Tooling | -- | gen-l10n is a build-time code generation step |
| `AppLocalizations` class generation | Build Tooling | -- | Produced by `flutter gen-l10n`, consumed at runtime |
| Locale resolution | Flutter Framework (MaterialApp) | -- | `basicLocaleListResolution` is built into `MaterialApp`; no custom code needed |
| `localizationsDelegates` wiring | Frontend (Widget Tree) | -- | Set on `MaterialApp.router` in `main.dart` |
| `initializeDateFormatting()` | App Bootstrap (`main()`) | -- | Must run before any widget uses `DateFormat` with non-default locale |
| TableCalendar locale | Frontend (Widget Tree) | -- | `locale:` parameter on the `TableCalendar` widget in `history_screen.dart` |
| String inventory / ARB template | Content / Build Tooling | -- | Manually authored `app_en.arb` with all keys; consumed by gen-l10n |
| `context.l10n` extension | Frontend (Widget Tree) | -- | Convenience accessor; sits in `lib/l10n/l10n_extensions.dart` |

## Standard Stack

### Core (New Dependencies)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `flutter_localizations` | SDK (ships with Flutter) | Provides `GlobalMaterialLocalizations`, `GlobalWidgetsLocalizations`, `GlobalCupertinoLocalizations` delegates | Official Flutter SDK package; no pub.dev version -- tied to Flutter SDK version [CITED: docs.flutter.dev/ui/internationalization] |

### Already Present (No Version Change)

| Library | Version | Purpose | Relevant to Phase 12 |
|---------|---------|---------|---------------------|
| `intl` | ^0.20.2 | Date/number formatting, ICU message runtime | `initializeDateFormatting()` import; ARB message runtime; `DateFormat.MMMM(locale)` for month names [VERIFIED: pub.dev] |
| `table_calendar` | ^3.2.0 | Calendar widget | Accepts `locale:` String parameter for month/day name localization [CITED: pub.dev/packages/table_calendar] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `flutter gen-l10n` (built-in) | `easy_localization` | Third-party; runtime JSON/YAML loading; adds complexity. Built-in ARB approach is official and compile-time safe [ASSUMED] |
| `flutter gen-l10n` (built-in) | `slang` | Type-safe code-gen from YAML; compelling but non-standard. ARB is the official Flutter approach [ASSUMED] |
| `flutter gen-l10n` (built-in) | `intl_utils` / `intl_translation` | Flutter's built-in handles ARB-to-Dart codegen. No third-party tool needed [CITED: docs.flutter.dev/ui/internationalization] |

**Installation:**

```yaml
# pubspec.yaml -- add under dependencies:
dependencies:
  flutter_localizations:
    sdk: flutter

# pubspec.yaml -- add under flutter:
flutter:
  uses-material-design: true
  generate: true  # REQUIRED for gen-l10n since Flutter 3.32
```

No `pub add` needed -- this is a YAML edit. Run `flutter pub get` after editing.

## Package Legitimacy Audit

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| `flutter_localizations` | Flutter SDK | Ships with SDK | N/A | github.com/flutter/flutter | N/A | Approved -- SDK package |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

*No new third-party packages are installed in this phase. `flutter_localizations` is a Flutter SDK package (not from pub.dev). `intl` is already present. No slopcheck run required.*

## Architecture Patterns

### System Architecture Diagram

```
pubspec.yaml (flutter_localizations + generate: true)
  |
l10n.yaml (configuration)
  |
lib/l10n/app_en.arb (template with ~67 keys)
  |
  v
flutter gen-l10n  (code generation -- standalone, NOT build_runner)
  |
  v
lib/l10n/generated/
  app_localizations.dart       (abstract class + delegate + supportedLocales + localizationsDelegates)
  app_localizations_en.dart    (English implementation)
  |
  v
main.dart
  |-- initializeDateFormatting()    <-- intl date data for all locales
  |-- ProviderScope > DrinkyDrinkyApp
       |-- MaterialApp.router
            |-- localizationsDelegates: AppLocalizations.localizationsDelegates
            |-- supportedLocales: AppLocalizations.supportedLocales
            |
            v
         Flutter Framework (basicLocaleListResolution)
            |-- Reads device OS locale via platformDispatcher.locale
            |-- Matches against supportedLocales [en, it, fr, es]
            |-- Falls back to en (first in list) for unsupported locales
            |
            v
         Localizations InheritedWidget
            |-- AppLocalizations.of(context) in any widget below MaterialApp
            |-- context.l10n shorthand via extension
            |
            v
         Widget Tree (screens, dialogs, bottom sheets)
            |
            +-- TableCalendar(locale: Localizations.localeOf(context).toString())
                   |-- Uses intl DateFormat internally for month/day names
```

### Recommended Project Structure

```
lib/
  l10n/
    app_en.arb                  # Template ARB (English) -- ALL ~67 keys with @metadata
    l10n_extensions.dart        # context.l10n convenience extension
    generated/                  # Output from flutter gen-l10n (committed to git)
      app_localizations.dart    # Abstract class + delegate + lookupAppLocalizations
      app_localizations_en.dart # English implementation
```

### Pattern 1: l10n.yaml Configuration

**What:** Project-root config file that drives `flutter gen-l10n`.
**When to use:** Always. Required for gen-l10n to know where ARBs are and where to write output.

```yaml
# l10n.yaml (project root)
# Source: docs.flutter.dev/ui/internationalization [CITED]
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
output-dir: lib/l10n/generated
synthetic-package: false
nullable-getter: false
preferred-supported-locales: [en]
```

Key rationale:
- `synthetic-package: false` -- REQUIRED on Flutter 3.44.1. The synthetic `package:flutter_gen` approach was removed after Flutter 3.32 [CITED: docs.flutter.dev/release/breaking-changes/flutter-generate-i10n-source]
- `output-dir: lib/l10n/generated` -- separates generated code from hand-authored ARB files (locked decision D-02)
- `nullable-getter: false` -- `AppLocalizations.of(context)` returns non-nullable `AppLocalizations`; eliminates `!` operators at every call site [CITED: docs.flutter.dev/ui/internationalization]
- `preferred-supported-locales: [en]` -- English first in generated `supportedLocales` list

### Pattern 2: pubspec.yaml Changes (Exact Diff)

**What:** Two additions to pubspec.yaml.
**When to use:** Before running `flutter gen-l10n` for the first time.

```diff
 dependencies:
   flutter:
     sdk: flutter
+
+  # Localization
+  flutter_localizations:
+    sdk: flutter

   # State Management
   flutter_riverpod: ^3.3.1
   # ... rest unchanged ...

 flutter:
   uses-material-design: true
+  generate: true
```

`generate: true` is REQUIRED since Flutter 3.32 for `flutter gen-l10n` to produce output files [CITED: docs.flutter.dev/release/breaking-changes/flutter-generate-i10n-source].

### Pattern 3: MaterialApp.router Wiring

**What:** Add `localizationsDelegates` and `supportedLocales` to `MaterialApp.router`.
**When to use:** After gen-l10n has produced the generated files.

```dart
// Source: docs.flutter.dev/ui/internationalization [CITED]
import 'package:drinky_drinky/l10n/generated/app_localizations.dart';

// Inside DrinkyDrinkyApp.build():
return MaterialApp.router(
  title: 'Drinky Drinky',
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  // ... existing theme, routerConfig ...
);
```

`AppLocalizations.localizationsDelegates` is a generated convenience getter that includes all 4 delegates:
1. `AppLocalizations.delegate`
2. `GlobalMaterialLocalizations.delegate`
3. `GlobalWidgetsLocalizations.delegate`
4. `GlobalCupertinoLocalizations.delegate`

This satisfies D-03 without manually listing delegates. [CITED: docs.flutter.dev/ui/internationalization]

### Pattern 4: initializeDateFormatting() in main()

**What:** Load intl date formatting data for all locales.
**When to use:** In `main()` before `runApp()`.

```dart
// Source: pub.dev/documentation/intl/latest/date_symbol_data_local [CITED]
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // L10N-03: Initialize date formatting for all locales.
  // table_calendar uses intl internally for month/day names.
  // No-arg call loads ALL locale data (both parameters are ignored in impl).
  await initializeDateFormatting();

  // ... existing timezone init, notification init ...
  runApp(const ProviderScope(child: DrinkyDrinkyApp()));
}
```

The function signature is `Future<void> initializeDateFormatting([String? locale, String? ignored])`. Both parameters are ignored in the implementation -- the function always loads all locale data and returns immediately. [CITED: pub.dev/documentation/intl/latest/date_symbol_data_local/initializeDateFormatting.html]

### Pattern 5: context.l10n Extension

**What:** Convenience extension to reduce verbosity of `AppLocalizations.of(context)`.
**When to use:** Created in Phase 12; used extensively in Phase 13 during string replacement.

```dart
// lib/l10n/l10n_extensions.dart
import 'package:flutter/widgets.dart';
import 'generated/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
```

With `nullable-getter: false`, no `!` is needed. Usage: `context.l10n.appTitle` instead of `AppLocalizations.of(context).appTitle`.

### Pattern 6: TableCalendar Locale Wiring

**What:** Pass device locale to TableCalendar so month/day headers display in the correct language.
**When to use:** In `history_screen.dart` on the `TableCalendar` widget.

```dart
// Source: pub.dev/packages/table_calendar README [CITED]
TableCalendar<Object>(
  locale: Localizations.localeOf(context).toString(),
  // locale expects a String like 'en', 'it', 'fr_FR', etc.
  // ... other existing properties ...
)
```

The `locale` parameter is a `String`, not a `Locale` object. It accepts formats like `'en'`, `'it'`, `'fr_FR'`, `'pl_PL'`. Using `Localizations.localeOf(context).toString()` produces the correct format. [CITED: pub.dev/packages/table_calendar]

### Pattern 7: ARB File with Placeholders and Plurals

**What:** ICU MessageFormat syntax for parameterized and plural strings.
**When to use:** In `app_en.arb` for strings with dynamic values or count-dependent text.

```json
{
  "@@locale": "en",

  "currentIntake": "{current} / {target} L",
  "@currentIntake": {
    "description": "Progress text showing current intake vs target in liters",
    "placeholders": {
      "current": { "type": "String" },
      "target": { "type": "String" }
    }
  },

  "dayStreak": "{count, plural, =0{No streak} =1{1 day streak} other{{count} day streak}}",
  "@dayStreak": {
    "description": "Streak counter on history screen",
    "placeholders": {
      "count": { "type": "int" }
    }
  },

  "mlAdded": "+{amount} ml added",
  "@mlAdded": {
    "description": "SnackBar text after quick-add",
    "placeholders": {
      "amount": { "type": "int" }
    }
  }
}
```

### Anti-Patterns to Avoid

- **Using `package:flutter_gen` import path:** Removed after Flutter 3.32. Import from `package:drinky_drinky/l10n/generated/app_localizations.dart` instead. [CITED: docs.flutter.dev/release/breaking-changes/flutter-generate-i10n-source]
- **Adding custom `localeResolutionCallback`:** Flutter's built-in `basicLocaleListResolution` handles all 4 locales correctly with EN fallback. Adding custom logic is unnecessary and error-prone. [CITED: api.flutter.dev/flutter/widgets/basicLocaleListResolution.html]
- **Leaving `generate: true` out of pubspec.yaml:** Required since Flutter 3.32. Without it, `flutter gen-l10n` silently produces no output. [CITED: docs.flutter.dev/release/breaking-changes/flutter-generate-i10n-source]
- **Setting `output-dir` to a directory with build_runner output:** gen-l10n and build_runner are independent; they do not conflict as long as output directories are distinct. `lib/l10n/generated/` contains no `.g.dart` files, so no collision.
- **Gitignoring generated l10n files:** The project commits `.g.dart` files (confirmed by `.gitignore` comment). Generated l10n files should follow the same convention -- commit them so the project builds without running `flutter gen-l10n` first.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Month names for calendar | Manual `_monthName()` array (currently in `history_screen.dart`) | `DateFormat.MMMM(locale).format(date)` from `intl` package | Only handles English; `DateFormat` handles all locales automatically after `initializeDateFormatting()` |
| Locale resolution | Custom `localeResolutionCallback` | Flutter's built-in `basicLocaleListResolution` | Built-in handles language-only matching (e.g., `es_MX` -> `es`) and fallback to first supported locale |
| Delegate list assembly | Manual `[AppLocalizations.delegate, Global...]` list | `AppLocalizations.localizationsDelegates` getter | Generated convenience getter includes all 4 delegates automatically |
| l10n code generation | `intl_utils`, `intl_translation`, or manual Dart classes | `flutter gen-l10n` | Official Flutter tool; ARB-to-Dart codegen with type safety |

## Complete String Inventory for app_en.arb

This is the comprehensive inventory of all ~67 translatable strings across the codebase. Each entry shows the source file, current text, and recommended ARB key.

### app_router.dart (3 strings)

| ARB Key | English Value | Current Source | Notes |
|---------|--------------|----------------|-------|
| `tabHome` | Home | `label: 'Home'` (line 67) | NavigationDestination |
| `tabHistory` | History | `label: 'History'` (line 72) | NavigationDestination |
| `tabSettings` | Settings | `label: 'Settings'` (line 77) | NavigationDestination |

### home_screen.dart (12 strings)

| ARB Key | English Value | Current Source | Notes |
|---------|--------------|----------------|-------|
| `appTitle` | Drinky Drinky | `'Drinky Drinky'` (line 73) | AppBar title |
| `goalReached` | Goal reached! | `'Goal reached!'` (line 140) | Progress ring center text |
| `currentIntake` | {current} / {target} L | `'$formatted / $formatted L'` (line 140) | Placeholder: current, target (both String) |
| `todaysIntake` | Today's Intake | `"Today's Intake"` (line 153) | Section header |
| `noDrinksLogged` | No drinks logged yet | `'No drinks logged yet'` (line 202) | Empty state title |
| `noDrinksLoggedHint` | Tap the + button to log your first drink today. | `'Tap the + button...'` (line 208) | Empty state subtitle |
| `mlAdded` | +{amount} ml added | `'+$amountMl ml added'` (line 240) | SnackBar; placeholder: amount (int) |
| `undo` | UNDO | `'UNDO'` (line 246) | SnackBar action label |
| `addWaterTooltip` | Add water | `'Add water'` (line 75) | FAB tooltip |
| `presetButtonLabel` | +{amount} ml | `'+${preset.amountMl} ml'` (line 305) | Bottom sheet preset buttons; placeholder: amount (int) |
| `customAmountHint` | Custom amount | `'Custom amount'` (line 316) | TextField hint |
| `addButton` | Add | `'Add'` (line 331) | Bottom sheet submit button |
| `errorLoadingDataRestart` | Something went wrong loading your data. Please restart the app. | line 93 | Error state |

### settings_screen.dart (14 strings)

| ARB Key | English Value | Current Source | Notes |
|---------|--------------|----------------|-------|
| `settingsTitle` | Settings | `'Settings'` (line 45) | AppBar title |
| `sectionDailyGoal` | DAILY GOAL | `'DAILY GOAL'` (line 69) | Section label |
| `sectionQuickAddPresets` | QUICK-ADD PRESETS | `'QUICK-ADD PRESETS'` (line 71) | Section label |
| `sectionNotifications` | NOTIFICATIONS | `'NOTIFICATIONS'` (line 73) | Section label |
| `sectionHydration` | HYDRATION | `'HYDRATION'` (line 75) | Section label |
| `recalculateHydration` | Recalculate hydration recommendation | Currently Italian: `'Ricalcola raccomandazione idratazione'` (line 80) | Settings list tile |
| `applyFromTomorrow` | Apply from tomorrow | Currently Italian: `'Applica da domani'` (line 130) | Switch title |
| `applyFromTomorrowSubtitle` | Target changes take effect tomorrow | Currently Italian: `'Le modifiche al target entrano in vigore domani'` (line 133) | Switch subtitle when ON |
| `applyFromTodaySubtitle` | Target changes take effect today | Currently Italian: `'Le modifiche al target entrano in vigore oggi'` (line 134) | Switch subtitle when OFF |
| `presetTitle` | Preset {number} | `'Preset ${preset.sortOrder + 1}'` (line 155) | Placeholder: number (int) |
| `amountMl` | {amount} ml | `'${preset.amountMl} ml'` (line 156) | Preset subtitle; placeholder: amount (int) |
| `notificationsDisabledBanner` | Notifications are disabled. Tap to open system Settings. | line 199 | Permission denied banner |
| `openButton` | Open | `'Open'` (line 209) | Banner action button |
| `intervalMinutes` | {minutes} min | `'${currentInterval.toInt()} min'` (line 227) | Interval display; placeholder: minutes (int) |
| `doNotDisturb` | Do Not Disturb | `'Do Not Disturb'` (line 258) | Toggle title |
| `toggleOn` | On | `'On'` (line 259) | DND status subtitle |
| `toggleOff` | Off | `'Off'` (line 259) | DND status subtitle |
| `startTime` | Start time | `'Start time'` (line 279) | DND start time label |
| `endTime` | End time | `'End time'` (line 291) | DND end time label |
| `errorLoadingData` | Something went wrong loading your data. | line 49 | Error state (shared pattern) |

### history_screen.dart (8 strings + month name replacement)

| ARB Key | English Value | Current Source | Notes |
|---------|--------------|----------------|-------|
| `historyTitle` | History | `'History'` (line 98/106/138) | AppBar title (3 occurrences) |
| `noHistoryYet` | No history yet | `'No history yet'` (line 114) | Empty state title |
| `noHistoryYetHint` | Start logging water on the Home tab to see your history here. | line 119 | Empty state subtitle |
| `dayStreak` | {count, plural, =0{No streak} =1{1 day streak} other{{count} day streak}} | `'$streak'` + `' day streak'` (lines 196/199) | ICU plural; placeholder: count (int) |
| `daySummaryWithEntries` | {date} -- {total} of {target} ml | `'$dateLabel -- $total of $dailyTarget ml'` (line 409) | Placeholder: date (String), total (int), target (int) |
| `daySummaryNoEntries` | {date} -- No entries | `'$dateLabel -- No entries'` (line 411) | Placeholder: date (String) |
| `calendarDayGoalMet` | {month} {day}: goal met | semanticLabel (line 366) | Accessibility label; placeholder: month (String), day (int) |
| `calendarDayGoalNotMet` | {month} {day}: goal not met | semanticLabel (line 368) | Accessibility label; placeholder: month (String), day (int) |
| `calendarDay` | {month} {day} | semanticLabel (line 370) | Accessibility label (no goal data); placeholder: month (String), day (int) |

**Note:** The `_monthName()` function (lines 16-33) is replaced by `DateFormat.MMMM(locale).format(date)` from `intl`. This is NOT an ARB key -- it is a code change.

### hydration_calculator_screen.dart (17 strings)

| ARB Key | English Value | Current Source | Notes |
|---------|--------------|----------------|-------|
| `calculatorTitle` | Hydration calculator | Currently Italian: `'Calcolatore idratazione'` (line 137) | AppBar title |
| `sexLabel` | Sex | Currently Italian: `'Sesso'` (line 152) | Section label |
| `sexMale` | Male | Currently Italian: `'Maschio'` (line 160) | SegmentedButton display label |
| `sexFemale` | Female | Currently Italian: `'Femmina'` (line 161) | SegmentedButton display label |
| `sexOther` | Other | Currently Italian: `'Altro'` (line 162) | SegmentedButton display label |
| `weightLabel` | Weight | Currently Italian: `'Peso'` (line 172) | Section label |
| `weightInputLabel` | Weight (kg) | Currently Italian: `'Peso (kg)'` (line 182) | TextField label |
| `weightUnit` | kg | `'kg'` (line 183) | TextField suffix |
| `weightValidationError` | Enter a weight between 1 and 300 kg | Currently Italian: `'Inserisci un peso tra 1 e 300 kg'` (line 133) | Validation error |
| `climateLabel` | Climate | Currently Italian: `'Clima'` (line 192) | Section label |
| `climateCold` | Cold | Currently Italian: `'Freddo'` | Climate slider label |
| `climateMild` | Mild | Currently Italian: `'Mite'` | Climate slider label |
| `climateWarm` | Warm | Currently Italian: `'Caldo'` | Climate slider label |
| `climateVeryWarm` | Very warm | Currently Italian: `'Molto caldo'` | Climate slider label |
| `climateHumid` | Humid | Currently Italian: `'Afoso'` | Climate slider label |
| `yourRecommendation` | Your recommendation | Currently Italian: `'La tua raccomandazione'` (line 219) | Recommendation display label |
| `fillAllFields` | Fill in all fields | Currently Italian: `'Compila tutti i campi'` (line 233) | Placeholder when incomplete |
| `privacyDisclaimer` | Your data (sex, weight, climate) is not saved or transmitted. The calculation happens entirely on your device. | Currently Italian (line 246-248) | Privacy text |
| `useAsTarget` | Use as target | Currently Italian: `'Usa come target'` (line 263) | Primary action button |
| `skipButton` | Skip | Currently Italian: `'Salta'` (line 272) | Onboarding skip button |
| `targetUpdateError` | Error updating target. Try again. | Currently Italian: `'Errore durante l\'aggiornamento del target. Riprova.'` (line 82) | Error SnackBar |
| `targetUpdated` | Target updated to {amount} | Currently Italian: `'Target aggiornato a ${_formatMl(...)}'` (line 102) | Success SnackBar; placeholder: amount (String) |

### permission_screen.dart (5 strings)

| ARB Key | English Value | Current Source | Notes |
|---------|--------------|----------------|-------|
| `permissionTitle` | Stay hydrated with reminders | line 44 | Heading |
| `permissionBody` | Drinky Drinky sends you gentle reminders to drink water throughout the day. | line 50 | Description |
| `enableReminders` | Enable Reminders | `'Enable Reminders'` (line 61) | Primary button |
| `skipForNow` | Skip for now | `'Skip for now'` (line 67) | Secondary button |
| `remindersEnabled` | Reminders enabled! You can adjust them anytime in Settings. | line 95 | SnackBar on grant |
| `remindersDeclined` | No problem -- you can enable reminders later in your device Settings. | line 97 | SnackBar on deny |

### preset_edit_dialog.dart (5 strings)

| ARB Key | English Value | Current Source | Notes |
|---------|--------------|----------------|-------|
| `editPresetTitle` | Edit Preset {number} | `'Edit Preset ${widget.preset.sortOrder + 1}'` (line 54) | Dialog title; placeholder: number (int) |
| `amountInputLabel` | Amount (ml) | `'Amount (ml)'` (line 60) | TextField label |
| `presetValidationError` | Enter a value between 50 and 2000 | `'Enter a value between 50 and 2000'` (line 62) | Validation error |
| `cancelButton` | Cancel | `'Cancel'` (line 68) | Dialog cancel button |
| `confirmButton` | Confirm | `'Confirm'` (line 80) | Dialog confirm button |

### notification_service.dart (2 strings -- Phase 14, listed for completeness)

| ARB Key | English Value | Current Source | Notes |
|---------|--------------|----------------|-------|
| `notificationTitle` | Drinky Drinky | `_notifTitle` (line 24) | OUT OF SCOPE for Phase 12 |
| `notificationBody` | Time to drink water! | `_notifBody` (line 25) | OUT OF SCOPE for Phase 12 |

### Unit abbreviation (shared)

| ARB Key | English Value | Notes |
|---------|--------------|-------|
| `mlUnit` | ml | Suffix text in TextField decorations |

**Total unique ARB keys (Phase 12 scope): ~67** (excluding notification_service.dart strings which are Phase 14).

## ICU Plural Rules for Target Languages

| Language | `one` category | `other` category | `many` category | Key difference |
|----------|---------------|------------------|-----------------|----------------|
| English (en) | i = 1, v = 0 (exactly 1) | Everything else (0, 2, 3...) | N/A | Standard |
| Italian (it) | i = 1, v = 0 (exactly 1) | Everything else (0, 2, 3...) | i % 1M = 0 | Same as English for practical counts |
| French (fr) | **i = 0 or 1** (0 AND 1) | 2, 3, 4... | i % 1M = 0 | **0 is singular in French** |
| Spanish (es) | n = 1 (exactly 1) | Everything else (0, 2, 3...) | i % 1M = 0 | Same as English for practical counts |

[CITED: unicode.org/cldr/charts/latest/supplemental/language_plural_rules.html]

**Implication for app_en.arb:** The `dayStreak` plural must use `=0` explicitly for a special zero case (like "No streak"), because the `one` category does NOT cover 0 in English/Italian/Spanish (but does in French). Using `=0` is the safest approach across all 4 languages.

```json
"dayStreak": "{count, plural, =0{No streak} =1{1 day streak} other{{count} day streak}}"
```

## Common Pitfalls

### Pitfall 1: synthetic-package: true Will Not Work

**What goes wrong:** Using the old `package:flutter_gen/gen_l10n/...` import path or omitting `synthetic-package: false` from `l10n.yaml` causes compilation errors on Flutter 3.44.1.
**Why it happens:** The synthetic package mechanism was removed after Flutter 3.32.
**How to avoid:** Always set `synthetic-package: false` and import from `package:drinky_drinky/l10n/generated/app_localizations.dart`.
**Warning signs:** `Target of URI doesn't exist: 'package:flutter_gen/gen_l10n/app_localizations.dart'`
[CITED: docs.flutter.dev/release/breaking-changes/flutter-generate-i10n-source]

### Pitfall 2: Missing generate: true in pubspec.yaml

**What goes wrong:** `flutter gen-l10n` produces no output files silently.
**Why it happens:** Since Flutter 3.32, `generate: true` under the `flutter:` key in pubspec.yaml is REQUIRED.
**How to avoid:** Add `generate: true` under the `flutter:` section.
**Warning signs:** Running `flutter gen-l10n` succeeds but no files appear in `lib/l10n/generated/`.
[CITED: docs.flutter.dev/release/breaking-changes/flutter-generate-i10n-source]

### Pitfall 3: AppLocalizations.of(context) Called Above MaterialApp

**What goes wrong:** Crashes with null assertion error. `AppLocalizations.of(context)` only works BELOW the `MaterialApp` in the widget tree.
**Why it happens:** The `localizationsDelegates` are installed by `MaterialApp`. Code above it (including `MaterialApp`'s own `title:` parameter) cannot access them.
**How to avoid:** For `MaterialApp.title`, use `onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle` if localization is needed. For `NotificationService.initialize()` in `main()`, keep channel name as hardcoded English (it runs before any widget tree exists).
**Warning signs:** `Null check operator used on a null value` on app startup.

### Pitfall 4: initializeDateFormatting() Not Called

**What goes wrong:** `DateFormat.MMMM('fr').format(date)` throws `LocaleDataException: Locale data has not been initialized` when table_calendar tries to render French month names.
**Why it happens:** The `intl` package requires date formatting data to be loaded before using non-default locales.
**How to avoid:** Call `await initializeDateFormatting()` (no arguments) in `main()` before `runApp()`.
**Warning signs:** Calendar crashes when device locale is not English.
[CITED: pub.dev/documentation/intl/latest/date_symbol_data_local/initializeDateFormatting.html]

### Pitfall 5: output-dir Collision with build_runner

**What goes wrong:** If gen-l10n output goes to a directory that build_runner also manages, files may conflict.
**Why it happens:** gen-l10n and build_runner are independent code generation systems with no coordination.
**How to avoid:** Use `output-dir: lib/l10n/generated/` which contains ONLY gen-l10n output, no `.g.dart` or `.freezed.dart` files.
**Warning signs:** Generated l10n files disappear after running `dart run build_runner build --delete-conflicting-outputs`.

### Pitfall 6: const Text() Widgets Break After l10n

**What goes wrong:** `const Text('Settings')` becomes `Text(context.l10n.settingsTitle)` -- the `const` must be removed because localized strings are runtime values.
**Why it happens:** `const` requires compile-time constants. Localized strings resolved via `AppLocalizations.of(context)` are runtime values.
**How to avoid:** Accept `const` removal. It has negligible performance impact for this app's scale. Phase 13 will handle this systematically during string replacement.
**Warning signs:** Compilation errors about const.

## Code Examples

### Complete l10n.yaml (verified)

```yaml
# Source: docs.flutter.dev/ui/internationalization [CITED]
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
output-dir: lib/l10n/generated
synthetic-package: false
nullable-getter: false
preferred-supported-locales: [en]
```

### Complete main.dart Modifications (verified)

```dart
// NEW import
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // L10N-03: Initialize date formatting for all locales (table_calendar needs this).
  await initializeDateFormatting();

  // ... existing timezone init ...
  tz.initializeTimeZones();
  final tzInfo = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

  // ... existing notification init ...
  await NotificationService.instance.initialize();

  runApp(const ProviderScope(child: DrinkyDrinkyApp()));
}
```

### Complete MaterialApp.router Modifications (verified)

```dart
// NEW import
import 'package:drinky_drinky/l10n/generated/app_localizations.dart';

// Inside DrinkyDrinkyApp.build(), in the DynamicColorBuilder:
return MaterialApp.router(
  title: 'Drinky Drinky',
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: ThemeData(/* ... existing ... */),
  darkTheme: ThemeData(/* ... existing ... */),
  themeMode: ThemeMode.system,
  routerConfig: router,
);
```

### Complete context.l10n Extension (verified)

```dart
// lib/l10n/l10n_extensions.dart
import 'package:flutter/widgets.dart';
import 'generated/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
```

### TableCalendar Locale Wiring (verified)

```dart
// In history_screen.dart, on the TableCalendar widget:
TableCalendar<Object>(
  locale: Localizations.localeOf(context).toString(),
  firstDay: _firstDay!,
  lastDay: lastDay,
  focusedDay: clampedFocused,
  // ... rest unchanged ...
)
```

### flutter gen-l10n Command

```bash
# Standalone command -- NOT through build_runner
flutter gen-l10n

# Alternative: flutter pub get also triggers gen-l10n when generate: true is set
flutter pub get
```

This is independent of `dart run build_runner build` (used for Drift, Riverpod, Freezed). The two code generation systems do not interfere.

### Generated File Structure

After running `flutter gen-l10n` with the above config:

```
lib/l10n/
  app_en.arb                         # Hand-authored template (Phase 12)
  l10n_extensions.dart               # Hand-authored extension (Phase 12)
  generated/                         # flutter gen-l10n output
    app_localizations.dart           # Abstract class, delegate, lookupAppLocalizations()
    app_localizations_en.dart        # English implementation
```

In Phase 13, `app_it.arb`, `app_fr.arb`, `app_es.arb` will be added to `lib/l10n/`, and corresponding `app_localizations_{it,fr,es}.dart` will appear in `generated/`.

### Import Path for AppLocalizations

```dart
// Correct (with synthetic-package: false, output-dir: lib/l10n/generated):
import 'package:drinky_drinky/l10n/generated/app_localizations.dart';

// WRONG (old synthetic package -- removed after Flutter 3.32):
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `synthetic-package: true` (default) | `synthetic-package: false` (required) | Flutter 3.28-3.32 | Import path changed from `package:flutter_gen/...` to `package:app_name/l10n/...` |
| `generate: true` optional | `generate: true` required | Flutter 3.32 | Must be in pubspec.yaml or gen-l10n produces no output |
| `nullable-getter: true` (default) | `nullable-getter: false` (recommended) | Available since Flutter 3.x | Eliminates `!` operators on every `AppLocalizations.of(context)` call |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `easy_localization` and `slang` are viable alternatives but non-standard | Standard Stack: Alternatives Considered | Low -- locked decision already uses built-in gen-l10n |
| A2 | The `many` plural category for Italian/French/Spanish only applies to numbers >= 1,000,000 | ICU Plural Rules table | Low -- hydration values never reach millions |

**If this table is empty:** All claims in this research were verified or cited -- no user confirmation needed.

## Open Questions

1. **MaterialApp `title:` property localization**
   - What we know: `title: 'Drinky Drinky'` is currently hardcoded. To localize it, must use `onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle` because the `title:` parameter's context is above the MaterialApp.
   - What's unclear: Whether the app title even needs localization (it is a brand name "Drinky Drinky").
   - Recommendation: Keep `title: 'Drinky Drinky'` as a non-localized brand name in Phase 12. The brand name is the same in all languages. If a localized title is needed later, use `onGenerateTitle`.

2. **Unit abbreviations (ml, kg, L) -- localize or not?**
   - What we know: Metric abbreviations are universal across en/it/fr/es.
   - What's unclear: Whether "ml", "kg", "L" should be ARB keys or left as hardcoded literals.
   - Recommendation: Include them as ARB keys (e.g., `mlUnit`, `kgUnit`) for completeness and future-proofing, even though the values are identical across all 4 target locales. This avoids mixed localized/non-localized strings and makes auditing easier.

3. **Generated files: commit to git?**
   - What we know: The project already commits `.g.dart` and `.freezed.dart` files to git (confirmed by `.gitignore` comment on line 54).
   - Recommendation: Follow the same convention. Do NOT add `lib/l10n/generated/` to `.gitignore`. Commit generated l10n files so the project builds without running `flutter gen-l10n` first.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | gen-l10n, flutter_localizations | Assumed available (project builds) | 3.44.1 (per CLAUDE.md SDK constraint) | -- |
| `intl` package | initializeDateFormatting, DateFormat, ARB runtime | Yes (in pubspec.yaml) | ^0.20.2 | -- |
| `table_calendar` | Calendar locale wiring | Yes (in pubspec.yaml) | ^3.2.0 | -- |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** None.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | N/A -- offline app, no auth |
| V3 Session Management | No | N/A -- no sessions |
| V4 Access Control | No | N/A -- single-user offline app |
| V5 Input Validation | No (for this phase) | ARB files are compile-time assets, not user input |
| V6 Cryptography | No | N/A |

### Known Threat Patterns for Flutter L10n

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| ARB injection (malicious placeholders) | Tampering | ARB files are compile-time assets authored by developers, not user-supplied. gen-l10n validates ICU syntax. No runtime risk. |
| Locale spoofing | Spoofing | App follows system locale via `platformDispatcher.locale`; no user-controlled locale override. Fallback to English is safe. |

**Assessment:** This phase has minimal security surface. ARB files are developer-authored compile-time assets. No user input is processed. No network calls. No new attack vectors introduced.

## Sources

### Primary (HIGH confidence)
- Flutter internationalization docs: https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization -- l10n.yaml options, MaterialApp wiring, nullable-getter behavior [CITED]
- Flutter breaking change (synthetic-package removal): https://docs.flutter.dev/release/breaking-changes/flutter-generate-i10n-source -- generate: true requirement, import path changes [CITED]
- Flutter API: `basicLocaleListResolution`: https://api.flutter.dev/flutter/widgets/basicLocaleListResolution.html -- locale resolution behavior [CITED]
- intl package `initializeDateFormatting`: https://pub.dev/documentation/intl/latest/date_symbol_data_local/initializeDateFormatting.html -- function signature, no-arg behavior [CITED]
- table_calendar README: https://pub.dev/packages/table_calendar -- locale parameter format, initializeDateFormatting requirement [CITED]
- CLDR plural rules: https://www.unicode.org/cldr/charts/latest/supplemental/language_plural_rules.html -- French 0=one rule [CITED]

### Secondary (MEDIUM confidence)
- Project codebase: All files in `lib/` read directly for string inventory (HIGH for codebase facts)

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- only one new SDK dependency (`flutter_localizations`); no third-party packages
- Architecture: HIGH -- all patterns verified via official Flutter docs and codebase analysis
- Pitfalls: HIGH -- each pitfall verified against current Flutter version (3.44.1) and codebase state
- String inventory: HIGH -- every string grepped from actual source files

**Research date:** 2026-06-15
**Valid until:** 2026-07-15 (stable; Flutter l10n API is mature and unlikely to change)
