# Architecture: Flutter gen-l10n Integration with Riverpod + NotificationService + GoRouter

**Domain:** Internationalization (i18n/l10n) for an existing Flutter app
**Researched:** 2026-06-15
**Confidence:** HIGH (verified via Flutter SDK source + official docs + Context7)

---

## 1. Infrastructure Setup

### 1.1 l10n.yaml Configuration

Create `l10n.yaml` at project root:

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
synthetic-package: false
output-dir: lib/l10n/generated
nullable-getter: false
format: true
preferred-supported-locales: [en]
```

**Key decisions:**

| Option | Value | Why |
|--------|-------|-----|
| `synthetic-package` | `false` | The synthetic package approach (`package:flutter_gen`) was removed after Flutter 3.32. On Flutter 3.44.1, `synthetic-package: true` will not resolve. Setting `false` generates files into `lib/l10n/generated/` with explicit imports. |
| `output-dir` | `lib/l10n/generated` | Separates generated code from hand-written ARB files |
| `nullable-getter` | `false` | `AppLocalizations.of(context)` returns non-nullable `AppLocalizations` instead of `AppLocalizations?`. Eliminates `!` operators on every call site. Safe because `supportedLocales` + fallback guarantees a match |
| `preferred-supported-locales` | `[en]` | English is the first element in `supportedLocales`, which makes it the fallback when no locale matches |
| `template-arb-file` | `app_en.arb` | English as template ensures all keys exist in the fallback language; translators fill in the other ARB files |

### 1.2 pubspec.yaml Additions

```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  # intl: ^0.20.2  # Already present

flutter:
  generate: true   # Required for gen-l10n to run on `flutter pub get`
```

No new third-party packages required. `flutter_localizations` ships with the Flutter SDK. `intl` is already in the dependency graph.

### 1.3 ARB File Structure

```
lib/l10n/
  app_en.arb      # Template (English) -- all keys defined here with @metadata
  app_it.arb      # Italian translations (keys + values only, no @metadata)
  app_fr.arb      # French translations
  app_es.arb      # Spanish translations
  generated/      # Output from gen-l10n
    app_localizations.dart
    app_localizations_en.dart
    app_localizations_it.dart
    app_localizations_fr.dart
    app_localizations_es.dart
```

### 1.4 Generated Code Structure

`flutter gen-l10n` generates these key pieces:

1. **`AppLocalizations`** -- abstract base class with `of(BuildContext)`, `delegate`, `localizationsDelegates`, `supportedLocales`, and all string getter/method signatures
2. **`AppLocalizationsEn`**, **`AppLocalizationsIt`**, etc. -- concrete subclasses with translated strings
3. **`_AppLocalizationsDelegate`** -- `LocalizationsDelegate<AppLocalizations>` that calls `lookupAppLocalizations(locale)` in its `load()` method
4. **`lookupAppLocalizations(Locale locale)`** -- **top-level public function** that takes a `Locale` and returns the correct `AppLocalizations` subclass instance without any `BuildContext`

**Verification:** The `lookupAppLocalizations` name was confirmed in the Flutter SDK source at `gen_l10n.dart` line 495: the function name is `lookup` + className (`lookupAppLocalizations` with the default class name). The `gen_l10n_templates.dart` file (lines 247-257) shows this as a top-level, non-private function in the generated output.

---

## 2. MaterialApp.router Integration

### Current Code (main.dart, line 38)

```dart
MaterialApp.router(
  title: 'Drinky Drinky',
  theme: ...,
  darkTheme: ...,
  themeMode: ThemeMode.system,
  routerConfig: router,
);
```

### Modified Code

```dart
import 'package:drinky_drinky/l10n/generated/app_localizations.dart';

MaterialApp.router(
  title: 'Drinky Drinky',
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  // No localeResolutionCallback needed -- see Section 5
  theme: ...,
  darkTheme: ...,
  themeMode: ThemeMode.system,
  routerConfig: router,
);
```

**What changes:**
- Add 2 properties: `localizationsDelegates` and `supportedLocales`
- Add 1 import

**What does NOT change:**
- `DynamicColorBuilder` wrapping stays the same
- `ProviderScope` stays the same
- `routerConfig` stays the same
- No new Riverpod providers needed

**Why `AppLocalizations.localizationsDelegates` (the generated convenience list):**
It includes `AppLocalizations.delegate` + `GlobalMaterialLocalizations.delegate` + `GlobalCupertinoLocalizations.delegate` + `GlobalWidgetsLocalizations.delegate`. Complete -- no manual assembly needed.

**Why `AppLocalizations.supportedLocales` (the generated convenience list):**
Derived from ARB files present in `lib/l10n/`. Adding a new ARB file automatically adds a locale. No manual sync.

---

## 3. NotificationService -- Localized Strings Without BuildContext

### The Problem

`NotificationService` is a singleton accessed via `NotificationService.instance`. It schedules notifications in `scheduleWindow()`, which runs from 5 call sites:

| Call Site | Has BuildContext? |
|-----------|-------------------|
| `HomeScreen._rescheduleNotifications()` (onResume) | Yes, but not passed |
| `SettingsScreen` interval slider onChangeEnd | Yes, but not passed |
| `SettingsScreen` DND toggle onChanged | Yes, but not passed |
| `SettingsScreen._pickDndTime` | Yes, but not passed |
| `PermissionScreen._onEnableReminders` | Yes, but not passed |

None of these callers pass BuildContext to `scheduleWindow()`. The current hardcoded strings are:
```dart
static const String _notifTitle = 'Drinky Drinky';
static const String _notifBody = 'Time to drink water!';
```

### The Solution: `lookupAppLocalizations` + `platformDispatcher.locale`

The generated `lookupAppLocalizations(Locale)` function creates an `AppLocalizations` instance for any locale **without BuildContext**. Combined with `WidgetsBinding.instance.platformDispatcher.locale` (available after `WidgetsFlutterBinding.ensureInitialized()`), NotificationService can resolve localized strings internally.

**Implementation:**

```dart
import 'package:flutter/widgets.dart';
import '../../l10n/generated/app_localizations.dart';

class NotificationService {
  // ... existing code ...

  /// Returns the AppLocalizations instance for the current system locale,
  /// falling back to English if the system locale is not supported.
  AppLocalizations _localizations() {
    final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final resolved = basicLocaleListResolution(
      [systemLocale],
      AppLocalizations.supportedLocales,
    );
    return lookupAppLocalizations(resolved);
  }

  Future<void> scheduleWindow(UserSettingsEntity settings) async {
    await cancelAll();
    if (!_initialized) return;
    if (!(await permissionGranted())) return;

    // Resolve localized strings once per scheduling call
    final l10n = _localizations();

    // ... scheduling loop ...
    await _plugin.zonedSchedule(
      // ...
      title: l10n.notificationTitle,
      body: l10n.notificationBody,
      // ...
    );
  }
}
```

**Remove the hardcoded constants:**
```dart
// DELETE:
// static const String _notifTitle = 'Drinky Drinky';
// static const String _notifBody = 'Time to drink water!';
```

### Why This Approach (Not Parameter Injection)

The alternative approach is to change `scheduleWindow`'s signature to accept `title` and `body` parameters and have each call site pass `AppLocalizations.of(context).notificationTitle`. This was rejected:

| Criterion | `lookupAppLocalizations` (chosen) | Parameter injection |
|-----------|-----------------------------------|---------------------|
| Call sites to change | 0 | 5 |
| `scheduleWindow` signature | Unchanged | Breaking change |
| Locale consistency | Uses exact same `basicLocaleListResolution` as Flutter framework | Depends on caller passing correct values |
| Works without BuildContext | Yes (uses `platformDispatcher.locale`) | No -- requires every caller to have and pass context |
| Testability | Can mock `platformDispatcher` | Must pass strings in tests |

### Why This Works

| Concern | Answer |
|---------|--------|
| Is `WidgetsBinding.instance` available when `scheduleWindow` runs? | YES -- `WidgetsFlutterBinding.ensureInitialized()` runs in `main()` before `NotificationService.instance.initialize()`. All `scheduleWindow` calls happen after initialization. |
| Does `platformDispatcher.locale` reflect the real system locale? | YES -- it reads the OS preferred locale, updated in real time |
| What if the system locale is not supported? | `basicLocaleListResolution` returns `supportedLocales[0]` (English) |
| Are all 64 scheduled notifications in one language? | YES -- resolved once per `scheduleWindow` call. If the user changes system language, notifications reschedule on next `HomeScreen.onResume` |
| Do we need a new Riverpod provider? | NO -- singleton pattern preserved, `lookupAppLocalizations` is a pure function call |

### Why NOT Other Approaches

| Approach | Why Not |
|----------|---------|
| Pass `BuildContext` to `scheduleWindow` | 5+ call sites change; `BuildContext` across async gaps is fragile |
| Store locale in SharedPreferences | Sync problem: stale after system language change until app writes new value |
| Make NotificationService a Riverpod provider | PROJECT.md explicitly validates "NotificationService as singleton (not Riverpod)" as a good decision |
| Use `Intl.defaultLocale` | Fragile -- depends on initialization order; `platformDispatcher.locale` is authoritative |

### Edge Case: Language Change While Notifications Are Scheduled

1. Already-scheduled notifications keep their original language text (pre-baked into OS notification queue)
2. On next app resume, `HomeScreen.onResume` calls `scheduleWindow()`, which re-resolves `_localizations()` with the new system locale
3. All 64 slots reschedule with updated text
4. Acceptable: notifications update within one app-resume cycle

---

## 4. GoRouter -- L10n Impact Assessment

### Does l10n Affect Routing?

**NO.** GoRouter is unaffected by localization:

| Aspect | Impact |
|--------|--------|
| Route paths (`/`, `/history`, `/settings`, `/permission`, `/calculator`) | None -- paths are internal identifiers, not user-visible |
| Redirect logic | None -- redirects check SharedPreferences booleans, not locale |
| Navigation transitions | None |
| Deep linking | None (app does not use deep linking) |

### Strings in app_router.dart That Need Localization

The `NavigationBar` labels in `StatefulShellRoute.indexedStack` builder are hardcoded:

```dart
NavigationDestination(label: 'Home'),
NavigationDestination(label: 'History'),
NavigationDestination(label: 'Settings'),
```

These ARE user-visible and DO need localization. The builder callback receives a `BuildContext`, so standard `AppLocalizations.of(context)` works:

```dart
NavigationDestination(
  icon: Icon(Icons.water_drop_outlined),
  selectedIcon: Icon(Icons.water_drop),
  label: AppLocalizations.of(context).tabHome,
),
```

**This is a UI string change, not an architectural change.** The routing structure itself is untouched.

---

## 5. Locale Resolution Order

### Flutter's Default Algorithm (`basicLocaleListResolution`)

1. **Exact match** -- language + country + script (e.g., `fr_CA` matches `Locale('fr', 'CA')`)
2. **Language match** -- language code only (e.g., `fr_CA` matches `Locale('fr')` when no `fr_CA` exists)
3. **Fallback** -- `supportedLocales[0]` (first element in the list)

### For Drinky Drinky

Given `supportedLocales: [Locale('en'), Locale('it'), Locale('fr'), Locale('es')]`:

| Device Language | Resolved Locale | Reason |
|-----------------|-----------------|--------|
| `it` (Italian) | `it` | Language match |
| `it_CH` (Italian Switzerland) | `it` | Language match |
| `en_US` | `en` | Language match |
| `en_GB` | `en` | Language match |
| `fr_FR` | `fr` | Language match |
| `fr_CA` | `fr` | Language match |
| `es_MX` | `es` | Language match |
| `de_DE` (German) | `en` | No match -> fallback |
| `ja_JP` (Japanese) | `en` | No match -> fallback |
| `pt_BR` (Portuguese) | `en` | No match -> fallback |

### No Custom `localeResolutionCallback` Needed

The default algorithm is exactly right:
- System locale -> supported locale -> English fallback
- No per-user locale override (app follows system language)
- No complex script/country logic (all 4 target languages use simple language codes)

**Do NOT add `localeResolutionCallback` or `localeListResolutionCallback`.** Default behavior is correct and less code.

### Consistency Between Widget Tree and NotificationService

Both use the same resolution:
- **Widget tree:** Flutter framework calls `basicLocaleListResolution` internally
- **NotificationService:** `_localizations()` calls `basicLocaleListResolution` explicitly with the same `AppLocalizations.supportedLocales` list

Same locale everywhere.

---

## 6. iOS Info.plist Requirement

iOS requires supported locales in `Info.plist`. Without this, iOS may not report the correct locale to the app.

Add to `ios/Runner/Info.plist`:

```xml
<key>CFBundleLocalizations</key>
<array>
  <string>en</string>
  <string>it</string>
  <string>fr</string>
  <string>es</string>
</array>
```

One-time change. Without it, Italian/French/Spanish iOS users may see English fallback.

---

## 7. Component Boundaries

### New Components

| Component | Path | Responsibility |
|-----------|------|----------------|
| l10n config | `l10n.yaml` (project root) | gen-l10n configuration |
| ARB files (4) | `lib/l10n/app_{en,it,fr,es}.arb` | Source of truth for translatable strings |
| Generated l10n classes | `lib/l10n/generated/` | Type-safe string accessors, delegate, `lookupAppLocalizations` |
| Convenience extension | `lib/l10n/l10n_extension.dart` | `context.l10n` shorthand |

### Modified Components

| Component | Change |
|-----------|--------|
| `pubspec.yaml` | Add `flutter_localizations` dep + `flutter: generate: true` |
| `main.dart` | Add `localizationsDelegates` + `supportedLocales` to `MaterialApp.router` |
| `notification_service.dart` | Add `_localizations()` helper; replace hardcoded constants with `lookupAppLocalizations` call |
| `app_router.dart` | Localize `NavigationDestination.label` strings |
| `home_screen.dart` | Replace ~8 hardcoded strings |
| `settings_screen.dart` | Replace ~12 hardcoded strings |
| `history_screen.dart` | Replace ~6 strings + `_monthName()` with `DateFormat.MMMM(locale)` |
| `hydration_calculator_screen.dart` | Replace ~15 hardcoded Italian strings; decouple `_sexFactors` keys from display labels |
| `permission_screen.dart` | Replace ~5 hardcoded strings |
| `preset_edit_dialog.dart` | Replace ~5 hardcoded strings |
| `ios/Runner/Info.plist` | Add `CFBundleLocalizations` array |

### Unmodified Components

| Component | Why No Change |
|-----------|---------------|
| Drift database/DAOs | Data layer -- no user-facing strings |
| Repositories | Data access -- no UI strings |
| Entities/models (freezed) | Data structures |
| Riverpod providers | Stream/state -- no rendering |
| GoRouter route structure | Paths are internal identifiers |

---

## 8. Data Flow Diagrams

### Widget String Resolution

```
Device OS (system locale)
  -> Flutter Framework (basicLocaleListResolution)
    -> MaterialApp.router (resolves to supported Locale)
      -> Localizations InheritedWidget (loads AppLocalizations via delegate)
        -> AppLocalizations.of(context) in any widget
          -> Generated getter returns locale-specific string
```

### Notification String Resolution

```
Device OS (system locale)
  -> WidgetsBinding.instance.platformDispatcher.locale
    -> basicLocaleListResolution([systemLocale], AppLocalizations.supportedLocales)
      -> lookupAppLocalizations(resolvedLocale)
        -> AppLocalizations instance (e.g., AppLocalizationsIt)
          -> l10n.notificationTitle / l10n.notificationBody
            -> flutter_local_notifications.zonedSchedule(title: ..., body: ...)
```

---

## 9. Build Order and Dependencies

```
1. pubspec.yaml changes (flutter_localizations, generate: true)
     |
2. l10n.yaml creation
     |
3. ARB files creation (app_en.arb first -- template, then stubs for it/fr/es)
     |
4. flutter gen-l10n (generates AppLocalizations + lookupAppLocalizations)
     |
5. l10n_extension.dart (context.l10n convenience)
     |
6. main.dart changes (localizationsDelegates, supportedLocales)
     |   -- App boots with l10n infrastructure; still shows hardcoded strings
     |
7. NotificationService modification (lookupAppLocalizations, _localizations())
     |   -- Notifications use localized strings; zero call-site changes
     |
8. Screen-by-screen string extraction (any order among screens)
     |   -- Each screen: replace hardcoded strings with context.l10n.key
     |
9. iOS Info.plist update (CFBundleLocalizations)
     |
10. Translation completion (fill in app_it/fr/es.arb values)
```

Steps 1-6 form the infrastructure. Steps 7-8 can proceed in parallel. Step 9 can happen any time. Step 10 is incremental -- English serves as fallback for missing translations.

---

## 10. Patterns to Follow

### Pattern 1: `context.l10n` Shorthand

```dart
// lib/l10n/l10n_extension.dart
import 'generated/app_localizations.dart';
import 'package:flutter/widgets.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

// Usage:
Text(context.l10n.dailyGoal)
```

With `nullable-getter: false`, no `!` needed.

### Pattern 2: Parameterized Strings (ICU MessageFormat)

```json
{
  "intakeAdded": "+{amount} ml added",
  "@intakeAdded": {
    "placeholders": { "amount": { "type": "int" } }
  }
}
```

```dart
context.l10n.intakeAdded(250)  // "+250 ml added"
```

### Pattern 3: Plural Strings

```json
{
  "dayStreak": "{count, plural, =0{No streak} =1{1 day streak} other{{count} day streak}}",
  "@dayStreak": {
    "placeholders": { "count": { "type": "int" } }
  }
}
```

### Pattern 4: Locale-Aware Date Formatting (Replace `_monthName`)

`history_screen.dart` has a hand-rolled English-only `_monthName()` function. Replace with `intl.DateFormat`:

```dart
// Before (English only, hardcoded):
String _monthName(int month) { ... }

// After (locale-aware, uses intl already in deps):
final locale = Localizations.localeOf(context).toString();
final monthName = DateFormat.MMMM(locale).format(DateTime(2000, month));
```

### Pattern 5: table_calendar Locale

```dart
TableCalendar(
  locale: Localizations.localeOf(context).languageCode,
  // ...
)
```

`table_calendar` uses `intl` internally; passing locale ensures month/day headers display correctly.

### Pattern 6: Decouple Computation Keys from Display Labels

`HydrationCalculatorScreen._sexFactors` uses Italian keys (`'Maschio'`, `'Femmina'`, `'Altro'`) that also serve as `SegmentedButton` values. When display strings change with locale, the lookup breaks.

```dart
// Fix: locale-independent keys for computation
static const _sexFactors = {'male': 35.0, 'female': 31.0, 'other': 33.0};

// SegmentedButton: internal key as value, translated string as label
ButtonSegment(value: 'male', label: Text(context.l10n.sexMale)),
ButtonSegment(value: 'female', label: Text(context.l10n.sexFemale)),
ButtonSegment(value: 'other', label: Text(context.l10n.sexOther)),
```

---

## 11. Anti-Patterns to Avoid

### Anti-Pattern 1: Storing Locale in SharedPreferences

**What:** Persisting the resolved locale and reading it in NotificationService.
**Why bad:** Stale after system language change until app writes new value. `platformDispatcher.locale` is always current.
**Instead:** Read `platformDispatcher.locale` directly.

### Anti-Pattern 2: Creating a Riverpod Provider for Locale

**What:** `@riverpod Locale currentLocale(...)` with NotificationService depending on it.
**Why bad:** NotificationService is deliberately a singleton outside Riverpod (validated decision in PROJECT.md). Adding Riverpod dependency breaks the architectural boundary.
**Instead:** Use `lookupAppLocalizations` directly in the singleton.

### Anti-Pattern 3: Passing BuildContext to scheduleWindow

**What:** Adding `BuildContext context` parameter to `scheduleWindow`.
**Why bad:** 5+ call sites change; `BuildContext` across async gaps is fragile; conceptually wrong for a service that outlives any single widget.
**Instead:** Use `platformDispatcher.locale` which is available after `ensureInitialized()`.

### Anti-Pattern 4: Using `synthetic-package: true`

**What:** Relying on `package:flutter_gen` import path.
**Why bad:** Removed after Flutter 3.32. On 3.44.1 this import will not resolve.
**Instead:** `synthetic-package: false` with explicit `output-dir`.

### Anti-Pattern 5: Leaving `_sexFactors` Keys as Italian Strings

**What:** `{'Maschio': 35.0, ...}` where the key IS the display label.
**Why bad:** Computation breaks when display label changes with locale.
**Instead:** Use locale-independent keys; ARB strings for display only.

### Anti-Pattern 6: Hardcoding "OK", "Cancel", Unit Abbreviations

**What:** Leaving strings like "Cancel", "ml", "kg" outside ARB files.
**Why bad:** Even "Cancel" translates ("Annulla" in Italian, "Annuler" in French). Creates mixed-language UI.
**Instead:** Extract ALL user-visible strings to ARB. If identical across locales, the ARB value is the same.

---

## 12. Complete String Inventory

### notification_service.dart (2 strings)
- `_notifTitle`: "Drinky Drinky"
- `_notifBody`: "Time to drink water!"

### app_router.dart (3 strings)
- NavigationDestination labels: "Home", "History", "Settings"

### home_screen.dart (~11 strings)
- AppBar title: "Drinky Drinky"
- "Goal reached!"
- "{current} / {target} L" (progress text)
- "Today's Intake"
- "No drinks logged yet"
- "Tap the + button to log your first drink today."
- "+{amount} ml added" (SnackBar)
- "UNDO"
- "Add water" (FAB tooltip)
- "+{amount} ml" (preset buttons)
- "Custom amount" (hint text)
- "Add" (button label)

### settings_screen.dart (~14 strings)
- "Settings" (AppBar)
- "DAILY GOAL" / "QUICK-ADD PRESETS" / "NOTIFICATIONS" / "HYDRATION" (section labels)
- "Applica da domani" (Italian)
- "Le modifiche al target entrano in vigore domani" / "...oggi" (Italian)
- "Preset {n}"
- "{amount} ml" (preset subtitle)
- "Notifications are disabled. Tap to open system Settings."
- "Open"
- "{minutes} min"
- "Do Not Disturb" / "On" / "Off"
- "Start time" / "End time"
- "Ricalcola raccomandazione idratazione" (Italian)

### history_screen.dart (~8 strings + month names)
- "History" (AppBar)
- "No history yet"
- "Start logging water on the Home tab to see your history here."
- "{count} day streak"
- Semantic: "{month} {day}: goal met" / "goal not met"
- Day summary: "{date} -- {total} of {target} ml"
- "{date} -- No entries"
- `_monthName()` (13 English month names -- replace with `DateFormat.MMMM`)

### hydration_calculator_screen.dart (~17 strings, currently Italian)
- "Calcolatore idratazione" (AppBar)
- "Sesso" / "Maschio" / "Femmina" / "Altro"
- "Peso" / "Peso (kg)"
- "Inserisci un peso tra 1 e 300 kg" (validation error)
- "Clima"
- Climate labels: "Freddo" / "Mite" / "Caldo" / "Molto caldo" / "Afoso"
- "La tua raccomandazione"
- "Compila tutti i campi"
- Privacy disclaimer (full paragraph)
- "Usa come target"
- "Salta"
- "Errore durante l'aggiornamento del target. Riprova." (error SnackBar)
- "Target aggiornato a {amount}" (success SnackBar)

### permission_screen.dart (~5 strings)
- "Stay hydrated with reminders"
- "Drinky Drinky sends you gentle reminders..."
- "Enable Reminders"
- "Skip for now"
- "Reminders enabled! You can adjust..."
- "No problem -- you can enable reminders later..."

### preset_edit_dialog.dart (~5 strings)
- "Edit Preset {n}"
- "Amount (ml)"
- "Enter a value between 50 and 2000"
- "Cancel"
- "Confirm"

### Shared error states (~2 strings)
- "Something went wrong loading your data."
- "Something went wrong loading your data. Please restart the app."

**Total: ~67 unique translatable strings across all files.**

---

## Sources

- Flutter SDK source: `gen_l10n_templates.dart` -- verified locally at `/Users/flavio.bizzarri/fvm/versions/3.44.1/packages/flutter_tools/lib/src/localizations/gen_l10n_templates.dart`, lines 247-257 (lookupFunction template)
- Flutter SDK source: `gen_l10n.dart` line 495 -- confirms `lookupAppLocalizations` naming convention (`'lookup$className'`)
- Flutter official docs: https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization (via Context7 + WebFetch)
- Flutter API: `basicLocaleListResolution` function (via Context7, `/websites/api_flutter_dev`)
- Flutter breaking change doc: https://docs.flutter.dev/release/breaking-changes/flutter-generate-i10n-source (via Context7)
- Project codebase: all files in `lib/` read directly
