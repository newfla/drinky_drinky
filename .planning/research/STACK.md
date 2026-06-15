# Stack Research: Drinky Drinky v1.3 (Multilingual Support)

**Project:** Drinky Drinky (Hydration Tracker)
**Researched:** 2026-06-15
**Scope:** L10n infrastructure additions for Italian/English/French/Spanish with EN fallback.
**Overall confidence:** HIGH

## New Dependencies Required

### 1. flutter_localizations (SDK package) -- REQUIRED

| Field | Value |
|-------|-------|
| Package | `flutter_localizations` |
| Source | Flutter SDK (not pub.dev) |
| Purpose | Provides `GlobalMaterialLocalizations.delegate`, `GlobalWidgetsLocalizations.delegate`, `GlobalCupertinoLocalizations.delegate` -- these translate Material/Cupertino widget strings (button labels, date pickers, back button tooltips, etc.) into all supported locales |
| Why needed | Without this, Material widgets remain in English regardless of device locale. It also provides the Cupertino delegates needed if any Cupertino-style widgets are used on iOS |

**pubspec.yaml addition:**

```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
```

**Confidence:** HIGH -- verified via Flutter official docs (Context7, docs.flutter.dev/ui/internationalization) and Flutter pubspec.yaml reference.

### 2. intl (already present) -- NO CHANGE

| Field | Value |
|-------|-------|
| Package | `intl` |
| Current version | `^0.20.2` |
| Action | **Keep as-is.** No version change needed. |
| Compatibility | `flutter_localizations` from the Flutter 3.44.1 SDK depends on exactly `intl: 0.20.2`, which satisfies the existing `^0.20.2` constraint. No conflict. |
| Used for | ARB codegen runtime (generated `AppLocalizations` class imports `intl`), plus existing `NumberFormat.decimalPatternDigits` usage in `home_screen.dart` and `hydration_calculator_screen.dart` |

**Confidence:** HIGH -- verified that Flutter stable's `flutter_localizations/pubspec.yaml` pins `intl: 0.20.2`.

## No Other New Packages Required

| Considered | Why Not Needed |
|------------|----------------|
| `intl_utils` / `intl_translation` | Flutter's built-in `flutter gen-l10n` handles ARB-to-Dart codegen. No third-party tool needed. |
| `easy_localization` | Third-party l10n wrapper; adds runtime JSON/YAML loading and complexity. Flutter's built-in ARB approach is the official, compile-time-safe solution. |
| `slang` | Alternative l10n with type-safe code-gen from YAML. Compelling but non-standard; ARB is the official Flutter approach and integrates with `flutter gen-l10n` out of the box. |
| `locale_plus` | Device locale detection beyond what Flutter provides. Not needed -- `WidgetsBinding.instance.platformDispatcher.locale` and `supportedLocales` resolution handle the four target locales. |

## pubspec.yaml Changes Required

### Dependencies section

Add one line:

```yaml
dependencies:
  # ... existing deps ...

  # Localization (l10n)
  flutter_localizations:
    sdk: flutter
```

### Flutter section

Add `generate: true`:

```yaml
flutter:
  uses-material-design: true
  generate: true  # <-- ADD THIS LINE
```

**Why `generate: true` is mandatory:** As of Flutter 3.32.0 (this project is on 3.44.1), `generate: true` is **required** in pubspec.yaml for `flutter gen-l10n` to work. This was a breaking change -- previously it was optional. Without this flag, `flutter pub get` and `flutter gen-l10n` will not generate localization source files.

**Confidence:** HIGH -- verified via Flutter breaking changes page (docs.flutter.dev/release/breaking-changes/flutter-generate-i10n-source).

## l10n.yaml Configuration File (New File)

Create `l10n.yaml` in the project root (same directory as `pubspec.yaml`):

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
synthetic-package: false
nullable-getter: false
preferred-supported-locales: [en]
```

### Option-by-option rationale

| Option | Value | Why |
|--------|-------|-----|
| `arb-dir` | `lib/l10n` | Standard location. Keeps ARB files and generated Dart files together in one directory. |
| `template-arb-file` | `app_en.arb` | English is the fallback language. The template file defines ALL message keys; other locale files translate them. EN as template means any missing translation falls back to English. |
| `output-localization-file` | `app_localizations.dart` | Default name. Generated into `lib/l10n/` (because `synthetic-package: false`). |
| `output-class` | `AppLocalizations` | Default class name. Used as `AppLocalizations.of(context).messageKey`. |
| `synthetic-package` | `false` | **Critical.** The synthetic `package:flutter_gen` approach was deprecated in Flutter 3.28 and removed after 3.32. Since this project is on Flutter 3.44.1, `synthetic-package: true` (the old default) will not work. Setting `false` generates files directly into `lib/l10n/`, imported as `import 'package:drinky_drinky/l10n/app_localizations.dart';`. |
| `nullable-getter` | `false` | With `false`, `AppLocalizations.of(context)` returns `AppLocalizations` (non-nullable) instead of `AppLocalizations?`. Eliminates the `!` null assertion operator at every call site. Safe because the app always has `MaterialApp` with delegates initialized before any widget accesses localized strings. |
| `preferred-supported-locales` | `[en]` | English is the fallback locale. If the device locale does not match any of the four supported locales, the app uses English. |

## ARB File Structure

Create four files in `lib/l10n/`:

| File | Locale | Role |
|------|--------|------|
| `app_en.arb` | English | **Template file.** Contains ALL message keys with `@` metadata (descriptions, placeholders). Fallback locale. |
| `app_it.arb` | Italian | Translations only (no `@` metadata needed, though allowed). |
| `app_fr.arb` | French | Translations only. |
| `app_es.arb` | Spanish | Translations only. |

### Template ARB example (app_en.arb)

```json
{
  "@@locale": "en",
  "appTitle": "Drinky Drinky",
  "@appTitle": {
    "description": "App title shown in AppBar and system task switcher"
  },
  "dailyGoal": "Daily Goal",
  "@dailyGoal": {
    "description": "Label for daily water target"
  },
  "currentIntake": "{current} / {target} L",
  "@currentIntake": {
    "description": "Progress text showing current intake vs target in liters",
    "placeholders": {
      "current": { "type": "String" },
      "target": { "type": "String" }
    }
  },
  "notificationTitle": "Drinky Drinky",
  "@notificationTitle": {
    "description": "Title for hydration reminder notification"
  },
  "notificationBody": "Time to drink water!",
  "@notificationBody": {
    "description": "Body text for hydration reminder notification"
  }
}
```

### Translation ARB example (app_it.arb)

```json
{
  "@@locale": "it",
  "appTitle": "Drinky Drinky",
  "dailyGoal": "Obiettivo giornaliero",
  "currentIntake": "{current} / {target} L",
  "notificationTitle": "Drinky Drinky",
  "notificationBody": "E' ora di bere acqua!"
}
```

## Code Generation Command

```bash
flutter gen-l10n
```

This is a standalone command -- it does NOT go through `build_runner`. It reads `l10n.yaml`, processes ARB files, and generates:

- `lib/l10n/app_localizations.dart` -- abstract `AppLocalizations` class with `.of(context)`, `.delegate`, `.supportedLocales`, `.localizationsDelegates`
- `lib/l10n/app_localizations_en.dart` -- English implementation
- `lib/l10n/app_localizations_it.dart` -- Italian implementation
- `lib/l10n/app_localizations_fr.dart` -- French implementation
- `lib/l10n/app_localizations_es.dart` -- Spanish implementation

**Alternative:** `flutter pub get` also triggers gen-l10n automatically when `generate: true` is set. And `flutter run` triggers it before building. But running `flutter gen-l10n` explicitly is useful during development when adding/changing ARB keys.

**Note:** This is independent of `dart run build_runner build` (used for Drift, Riverpod, Freezed). The two codegen systems do not interfere with each other.

## MaterialApp Integration

### Current main.dart (relevant excerpt)

```dart
return MaterialApp.router(
  title: 'Drinky Drinky',
  // ... themes ...
  routerConfig: router,
);
```

### Required changes to main.dart

```dart
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

// ...

return MaterialApp.router(
  title: 'Drinky Drinky',
  // ... themes ...
  routerConfig: router,

  // L10n: add these three properties
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: null, // null = follow system locale (default behavior)
);
```

`AppLocalizations.localizationsDelegates` is a convenience getter generated by `flutter gen-l10n` that includes:
- `AppLocalizations.delegate` (the app's own translations)
- `GlobalMaterialLocalizations.delegate` (Material widget translations)
- `GlobalWidgetsLocalizations.delegate` (text direction, etc.)
- `GlobalCupertinoLocalizations.delegate` (Cupertino widget translations)

`AppLocalizations.supportedLocales` is auto-generated from the ARB files: `[Locale('en'), Locale('es'), Locale('fr'), Locale('it')]`.

## Notification String Localization

### The problem

`NotificationService` is a singleton initialized in `main()` before `MaterialApp` exists. It has no `BuildContext`, so it cannot call `AppLocalizations.of(context)`. Notification strings are currently hardcoded:

```dart
static const String _notifTitle = 'Drinky Drinky';
static const String _notifBody = 'Time to drink water!';
```

### Recommended solution: Pass locale strings at schedule time

The `scheduleWindow` method is always called from widget code that HAS a `BuildContext` (settings_screen, permission_screen, home_screen). The solution is to pass localized title/body as parameters:

```dart
// NotificationService -- change signature:
Future<void> scheduleWindow(
  UserSettingsEntity settings, {
  required String title,
  required String body,
}) async {
  // ... use title/body instead of _notifTitle/_notifBody ...
}
```

At every call site (which has context):

```dart
final l10n = AppLocalizations.of(context);
await NotificationService.instance.scheduleWindow(
  settings,
  title: l10n.notificationTitle,
  body: l10n.notificationBody,
);
```

**Why this approach:** It is the simplest and most correct. The notification text is determined at schedule time based on the current locale. If the user changes their system language, the next time `scheduleWindow` is called (which happens on every settings change and on app launch from home_screen), notifications will use the new locale's text.

**Alternative considered:** Using `lookupAppLocalizations(locale)` directly in NotificationService (calling the generated lookup function without a context). This works but creates a tighter coupling to the generated l10n code and is less idiomatic. The parameter approach is cleaner.

## Locale Resolution Behavior

Flutter's locale resolution (built into `MaterialApp`) automatically:

1. Reads the device's system locale via `platformDispatcher.locale`
2. Matches against `supportedLocales` (en, it, fr, es)
3. If exact match found, uses it
4. If language-only match found (e.g., `es_MX` matches `es`), uses it
5. If no match, uses the first locale in `preferred-supported-locales` (English)

No custom `localeResolutionCallback` is needed. The built-in behavior handles the four-locale setup correctly.

## Version Conflicts Assessment

| Concern | Status | Detail |
|---------|--------|--------|
| `intl ^0.20.2` vs `flutter_localizations` | No conflict | SDK's flutter_localizations pins `intl: 0.20.2`; satisfies `^0.20.2` |
| `flutter gen-l10n` vs `build_runner` | No conflict | Independent codegen systems; do not share build steps |
| `generate: true` vs existing flutter section | No conflict | Additive; does not affect `uses-material-design: true` |
| `synthetic-package: false` on Flutter 3.44.1 | Required | `synthetic-package: true` (old default) is removed post-3.32; must be explicit `false` |

## Generated Files and .gitignore

The generated `app_localizations*.dart` files in `lib/l10n/` should be committed to git (not gitignored). Reasons:

1. With `synthetic-package: false`, they are regular source files in the lib directory
2. Committing them allows the project to build without running `flutter gen-l10n` first
3. This matches how `*.g.dart` files from build_runner are already handled in this project (they are committed)

## Complete pubspec.yaml Diff Summary

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

That is it. Two lines in dependencies, one line in the flutter section.

## Sources

- Flutter official internationalization guide (Context7: github.com/flutter/website, docs.flutter.dev/ui/internationalization) -- HIGH confidence
- Flutter pubspec.yaml reference (Context7: github.com/flutter/website, tools/pubspec) -- HIGH confidence
- Flutter breaking changes: synthetic package removal (docs.flutter.dev/release/breaking-changes/flutter-generate-i10n-source) -- HIGH confidence
- Flutter stable flutter_localizations/pubspec.yaml (github.com/flutter/flutter) -- `intl: 0.20.2` pin verified -- HIGH confidence
- pub.dev intl package page -- version 0.20.2 confirmed as latest -- HIGH confidence
- Existing project codebase: pubspec.yaml, main.dart, notification_service.dart, home_screen.dart -- HIGH confidence
