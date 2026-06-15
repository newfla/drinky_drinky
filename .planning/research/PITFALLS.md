# Pitfalls Research: Drinky Drinky v1.3 -- Retrofitting Flutter l10n

**Domain:** Flutter hydration tracker / water reminder app (offline-first, iOS + Android)
**Stack:** Flutter 3.44.1 + Riverpod 3.x + Drift 2.33.0 + GoRouter + SharedPreferences
**Researched:** 2026-06-15
**Scope:** Pitfalls specific to ADDING ARB-based l10n (it/en/fr/es) to an existing Flutter app with ~400-600 hardcoded strings, a singleton NotificationService, and six screens. Covers: missed strings, context availability, ARB codegen, plural rules, RTL, testing, and platform declarations.
**Overall confidence:** HIGH -- based on official Flutter docs (Context7), direct codebase analysis, and CLDR plural rule data.

---

## Critical Pitfalls

### Pitfall 1: NotificationService Singleton Has No BuildContext (CRITICAL)

**What goes wrong:** The `NotificationService` is a pure-Dart singleton (`NotificationService._()`) that has no `BuildContext`. The notification title and body are hardcoded as `static const` strings:
```dart
static const String _notifTitle = 'Drinky Drinky';
static const String _notifBody = 'Time to drink water!';
```
These strings cannot be localized via `AppLocalizations.of(context)` because there is no `context` available inside the singleton. The `scheduleWindow()` method (line 148) passes `_notifTitle` and `_notifBody` to `_plugin.zonedSchedule()`, which stores them at schedule time, not display time. This means the notification text is baked in when scheduled, not when displayed.

**Why it happens:** The singleton pattern was chosen explicitly (PROJECT.md Key Decision: "notifications are imperative side effects, not reactive streams"). This is the correct architecture decision, but it creates a tension with l10n: localized strings require `BuildContext` to resolve the current locale, and the singleton does not have one.

**Consequences:**
- If notification strings are not localized, users see English text regardless of device language
- If notification strings are localized using the locale at schedule time, and the user changes device language mid-week, all 64 pre-scheduled notifications display in the OLD language until the next reschedule
- If you try to pass `BuildContext` to the singleton, you risk holding a reference to a disposed context

**Prevention:**
1. **Pass resolved strings, not context:** Modify `scheduleWindow()` to accept localized title and body as parameters:
   ```dart
   Future<void> scheduleWindow(
     UserSettingsEntity settings, {
     required String title,
     required String body,
   }) async { ... }
   ```
2. **Resolve at call site:** Every caller of `scheduleWindow()` already has a `BuildContext` (or a `WidgetRef` that can access one):
   - `home_screen.dart` line 37 (`_rescheduleNotifications` -- has `context` via `ConsumerState`)
   - `home_screen.dart` line 67 (`cancelAll` -- no change needed, cancelling does not need strings)
   - `settings_screen.dart` line 246 (interval change -- has `context`)
   - `settings_screen.dart` line 266 (DND toggle -- has `context`)
   - `settings_screen.dart` line 334 (DND time change -- has `context`)
   - `permission_screen.dart` line 108 (first schedule -- has `context`)
3. **Accept stale-language risk:** Notifications are rescheduled on every app resume (`AppLifecycleListener.onResume`), so the language staleness window is short. Document this as an acceptable trade-off.
4. **Do NOT make NotificationService locale-aware.** Do not store the locale in the singleton or import `flutter_localizations`. Keep the singleton pure-Dart.

**Detection:** Schedule notifications, then change the device language without opening the app. If the notifications show the old language, the fix is working as designed (stale until next reschedule). If they show untranslated keys like `notif_body`, the l10n integration is broken.

**Confidence:** HIGH -- direct code analysis of `notification_service.dart` lines 24-25 and all 6 call sites.

**Phase:** Must be addressed in the notification strings translation task (v1.3).

---

### Pitfall 2: Missed Strings Outside Widget Code (CRITICAL)

**What goes wrong:** Developers audit `.dart` files in `lib/presentation/` for hardcoded strings but miss strings in non-widget locations. In this codebase, there are translatable strings in at least these non-obvious places:

1. **Semantics labels in `history_screen.dart`** (lines 364-370):
   ```dart
   semanticLabel = '${_monthName(day.month)} ${day.day}: goal met';
   semanticLabel = '${_monthName(day.month)} ${day.day}: goal not met';
   ```
   These are accessibility strings spoken by screen readers. They MUST be localized.

2. **Month name array in `history_screen.dart`** (lines 17-32):
   ```dart
   const names = ['', 'January', 'February', ...];
   ```
   This is a manual month list used for semantics and the day summary card (line 406). After l10n, this should use `DateFormat.MMMM(locale).format(date)` from the `intl` package (already a dependency).

3. **Day summary card content** (lines 407-410):
   ```dart
   contentLabel = '$dateLabel -- $total of $dailyTarget ml';
   contentLabel = '$dateLabel -- No entries';
   ```

4. **NotificationService** strings (covered in Pitfall 1).

5. **Android notification channel name** (`notification_service.dart` line 23):
   ```dart
   static const String _channelName = 'Hydration Reminders';
   ```
   The channel name is visible in Android Settings > App > Notifications. It should be localized, but **cannot** use `AppLocalizations.of(context)` because `initialize()` runs in `main()` before `MaterialApp` exists. See Pitfall 3.

6. **`_sexFactors` map keys used as both data keys AND display labels** (`hydration_calculator_screen.dart` lines 28-30):
   ```dart
   static const _sexFactors = {
     'Maschio': 35.0,
     'Femmina': 31.0,
     'Altro': 33.0,
   };
   ```
   The key `'Maschio'` is stored in `_selectedSex` and then used as BOTH a map lookup key (`_sexFactors[_selectedSex!]!`) AND a display value in `ButtonSegment(value: 'Maschio', label: Text('Maschio'))`. After l10n, the display label changes per locale, but the map key must remain stable.

**Prevention:**
1. **Grep comprehensively.** Search for ALL string literals in `lib/`, not just `Text(` widgets:
   ```bash
   grep -rn "'" lib/ --include="*.dart" | grep -v ".g.dart" | grep -v ".freezed.dart" | grep -v "import " | grep -v "//"
   ```
2. **Replace `_monthName()` with `DateFormat.MMMM(locale).format()`** -- the `intl` package is already a dependency and handles all four target locales correctly.
3. **Separate data keys from display labels** for the calculator:
   ```dart
   enum Sex { male, female, other }
   static const _sexFactors = {Sex.male: 35.0, Sex.female: 31.0, Sex.other: 33.0};
   // Display: AppLocalizations.of(context).sexMale, etc.
   ```
4. **Use `untranslated-messages-file` in `l10n.yaml`** to generate a file listing any ARB keys present in the template but missing in translation files. This catches missed translations, not missed extractions.
5. **Create a string audit checklist** covering: Text widgets, SnackBar content, AppBar titles, dialog titles/content, tooltip strings, semanticLabel, hintText, labelText, errorText, suffixText, and notification strings.

**Detection:** Run the app in French. If any Italian or English strings appear, they were missed.

**Confidence:** HIGH -- direct codebase analysis identified all 6 categories above.

**Phase:** String extraction task (v1.3, first phase).

---

### Pitfall 3: AppLocalizations.of(context) Returns Null Before MaterialApp (CRITICAL)

**What goes wrong:** `AppLocalizations.of(context)` works only BELOW the `MaterialApp` widget in the widget tree. If called above it (e.g., in `main()`, in root-level `build()`, or in code that runs before `MaterialApp` is built), it returns `null`. With `nullable-getter: true` (the default), the `!` operator crashes. With `nullable-getter: false`, the framework itself throws.

In this codebase, the specific danger points are:

1. **`main()` function** (line 21): `NotificationService.instance.initialize()` runs before `MaterialApp`. The notification channel name is set here. You CANNOT use `AppLocalizations` at this point because there is no widget tree at all.

2. **`DrinkyDrinkyApp.build()`** (line 34): This is the `ConsumerWidget` that CREATES the `MaterialApp`. Calling `AppLocalizations.of(context)` inside this `build` method fails because the `localizationsDelegates` have not been installed yet -- they ARE the `MaterialApp`.

3. **MaterialApp `title` property** (line 39): `title: 'Drinky Drinky'` is set inside `MaterialApp.router()`. This is fine as a non-localized app name, but if you try to localize it via `AppLocalizations.of(context)`, it fails because the context is from ABOVE the MaterialApp. Use `onGenerateTitle` instead:
   ```dart
   onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
   ```

**Prevention:**
1. **Use `nullable-getter: false` in `l10n.yaml`** to get compile-time safety (non-nullable return type). This way, calling `AppLocalizations.of(context)` from a context without localization delegates produces a clear framework error instead of a silent null.
2. **Never pass `AppLocalizations` to code that runs before `MaterialApp`.** For `NotificationService.initialize()`, keep the channel name as a hardcoded English string (it is only visible in Android system settings and is set once at startup).
3. **For `MaterialApp.title`, use `onGenerateTitle`** which provides a context BELOW the MaterialApp.
4. **Audit every call to `AppLocalizations.of(context)`** to ensure the context is from a widget BELOW `MaterialApp` in the tree. In this app, all screens are rendered via GoRouter routes, which are all below `MaterialApp`, so screen-level usage is safe.

**Detection:** If the app crashes on startup with "Null check operator used on a null value" after adding l10n, you are calling `AppLocalizations.of(context)` from above `MaterialApp`.

**Confidence:** HIGH -- verified via Flutter official docs (Context7) and direct analysis of `main.dart`.

**Phase:** Infrastructure setup task (v1.3, first task).

---

### Pitfall 4: Hydration Calculator Uses Italian Strings as Map Keys (CRITICAL)

**What goes wrong:** The `_sexFactors` map uses Italian display strings as keys (`'Maschio'`, `'Femmina'`, `'Altro'`). The `_selectedSex` state variable holds these Italian strings. The `_computeRecommendation()` method looks up `_sexFactors[_selectedSex!]!`. After l10n, if the ButtonSegment `value` is changed to a localized string (e.g., `'Male'` in English), `_sexFactors['Male']` returns `null`, and the `!` crashes.

Similarly, `_climateLabels` (line 34) contains Italian strings (`'Freddo'`, `'Mite'`, `'Caldo'`, `'Molto caldo'`, `'Afoso'`) used as display labels. These are safer because they are looked up by index, not by string key. But they still need localization.

**Why it happens:** The original code was Italian-only, so using display strings as map keys worked fine. This is a classic l10n anti-pattern: conflating data identifiers with user-visible text.

**Consequences:** App crashes when the device language is not Italian. The hydration calculator is unusable.

**Prevention:**
1. **Refactor to enum-based keys BEFORE adding l10n:**
   ```dart
   enum Sex { male, female, other }
   static const _sexFactors = {Sex.male: 35.0, Sex.female: 31.0, Sex.other: 33.0};
   ```
2. **Localize display labels separately:**
   ```dart
   String _sexLabel(BuildContext context, Sex sex) {
     final l10n = AppLocalizations.of(context);
     return switch (sex) {
       Sex.male => l10n.sexMale,
       Sex.female => l10n.sexFemale,
       Sex.other => l10n.sexOther,
     };
   }
   ```
3. **Localize climate labels the same way:**
   ```dart
   List<String> _climateLabels(BuildContext context) {
     final l10n = AppLocalizations.of(context);
     return [l10n.climateCold, l10n.climateMild, l10n.climateWarm, l10n.climateVeryWarm, l10n.climateHumid];
   }
   ```
4. **This refactor MUST happen before or during the string extraction phase**, not after. If you extract strings first and try to use localized strings as map keys, you introduce the crash.

**Detection:** Switch to English. Open the calculator. Select a sex option. If the app crashes, the map key was not decoupled from the display label.

**Confidence:** HIGH -- direct code analysis of `hydration_calculator_screen.dart` lines 27-34, 56.

**Phase:** String extraction task (v1.3). Must be done as a prerequisite refactor.

---

## High-Severity Pitfalls

### Pitfall 5: iOS Info.plist Missing CFBundleLocalizations

**What goes wrong:** The iOS `Info.plist` currently has no `CFBundleLocalizations` key. Without it, iOS does not know the app supports Italian, French, or Spanish. This causes two problems:
1. The App Store listing does not show the supported languages
2. iOS may not offer the app's supported locales to the Flutter framework via `Localizations.localeOf(context)` -- it defaults to English

The current `project.pbxproj` only declares `knownRegions = (en, Base)`. The locales `it`, `fr`, `es` are missing.

**Why it happens:** The Flutter project template only includes English. Adding locales to the Dart side (`supportedLocales` in `MaterialApp`) is necessary but NOT sufficient for iOS. The native iOS side must also declare them.

**Consequences:** On iOS, the app may always display in English even when the device language is Italian, French, or Spanish. Flutter's locale resolution depends on the platform reporting the device locale, and iOS filters available locales through the app's declared capabilities.

**Prevention:**
1. **Add locales via Xcode:** Open `ios/Runner.xcodeproj` in Xcode. Under Project > Info > Localizations, add Italian, French, and Spanish. Xcode will create empty `.strings` files and update `project.pbxproj` to include `it`, `fr`, `es` in `knownRegions`.
2. **Or add `CFBundleLocalizations` manually to `Info.plist`:**
   ```xml
   <key>CFBundleLocalizations</key>
   <array>
     <string>en</string>
     <string>it</string>
     <string>fr</string>
     <string>es</string>
   </array>
   ```
3. **Do BOTH:** The Xcode project settings and Info.plist should agree. The Xcode approach is safer because it also sets up the native localization infrastructure.
4. **Test on a real iOS device** with the device language set to Italian, then French, then Spanish. If `Localizations.localeOf(context).languageCode` still returns `en`, the native declaration is missing.

**Detection:** Set iOS device to Italian. Launch app. If strings appear in English, check `Info.plist` for `CFBundleLocalizations`.

**Confidence:** HIGH -- verified via Flutter official internationalization docs (Context7) and direct inspection of `Info.plist` (no `CFBundleLocalizations` key present).

**Phase:** Platform configuration task (v1.3).

---

### Pitfall 6: Android resConfigs Not Set (Locale Filtering)

**What goes wrong:** Android's build system includes all locale resources from all dependencies by default. Without `resConfigs`, the APK contains locale data for 80+ languages from Material/Cupertino dependencies. This has two effects:
1. **App bloat:** The APK is larger than necessary with unused locale resources
2. **Android system locale list:** The app appears to support languages it does not actually support, because the system detects resource folders for those languages

**Why it happens:** The `build.gradle.kts` has no `resConfigs` declaration (verified: only `minSdk`, `targetSdk`, `versionCode`, `versionName` in `defaultConfig`).

**Consequences:** Minor for a 4-language app, but can confuse the Android locale resolution algorithm. If the device is set to German (unsupported), Android might match to a resource from a dependency rather than falling back to English as intended.

**Prevention:**
Add to `android/app/build.gradle.kts` inside `defaultConfig`:
```kotlin
defaultConfig {
    // ... existing config ...
    resourceConfigurations.addAll(listOf("en", "it", "fr", "es"))
}
```

**Detection:** Build the APK. Check `res/` folder for unexpected locale directories.

**Confidence:** MEDIUM -- this is a best practice rather than a must-fix. Flutter's l10n resolution handles fallback correctly regardless. But it prevents spurious locale matches.

**Phase:** Platform configuration task (v1.3).

---

### Pitfall 7: `synthetic-package` Default Changed -- Import Path Confusion

**What goes wrong:** Flutter 3.32+ changed the default for `synthetic-package` from `true` to `false`. With `synthetic-package: true` (old default), generated files went to a virtual `package:flutter_gen/gen_l10n/` package. With `synthetic-package: false` (new default, which is what Flutter 3.44.1 uses), generated files go into the source directory (default: same as `arb-dir`).

If the developer follows old tutorials or Stack Overflow answers that use `import 'package:flutter_gen/gen_l10n/app_localizations.dart'`, the import fails because no synthetic package is created.

**Why it happens:** The breaking change landed in Flutter 3.28 and was finalized in 3.32. Since this project uses Flutter 3.44.1, the old synthetic-package behavior is unavailable. Old documentation and tutorials still reference the old import path.

**Consequences:** Compilation error: `Target of URI doesn't exist: 'package:flutter_gen/gen_l10n/app_localizations.dart'`.

**Prevention:**
1. **Create `l10n.yaml` with explicit configuration:**
   ```yaml
   arb-dir: lib/l10n
   template-arb-file: app_en.arb
   output-localization-file: app_localizations.dart
   synthetic-package: false
   nullable-getter: false
   ```
2. **Import from the source path, not the synthetic package:**
   ```dart
   import 'package:drinky_drinky/l10n/app_localizations.dart';
   // NOT: import 'package:flutter_gen/gen_l10n/app_localizations.dart';
   ```
3. **Add `generate: true` to `pubspec.yaml`** under the `flutter:` key. This is now REQUIRED for l10n generation:
   ```yaml
   flutter:
     uses-material-design: true
     generate: true
   ```
4. **Ignore tutorials dated before 2025** that reference `package:flutter_gen`.

**Detection:** Run `flutter gen-l10n`. If it succeeds but the import path is wrong, the app will not compile.

**Confidence:** HIGH -- verified via Flutter official breaking change docs (https://docs.flutter.dev/release/breaking-changes/flutter-generate-i10n-source).

**Phase:** Infrastructure setup task (v1.3, first task).

---

### Pitfall 8: `output-dir` Clash with build_runner

**What goes wrong:** If `output-dir` in `l10n.yaml` is set to a directory that `build_runner` also writes to (e.g., `lib/` root, or a directory with `.g.dart` files), `build_runner` may delete or conflict with gen-l10n output files. Conversely, `flutter gen-l10n` may overwrite build_runner output.

This project uses `build_runner` for Drift (`*.g.dart`), Riverpod (`*.g.dart`), and Freezed (`*.freezed.dart`). The code-gen output lives alongside source files.

**Why it happens:** `flutter gen-l10n` and `build_runner` are two independent code generation systems. They do not coordinate. `build_runner` has a `deleteConflictingOutputs` option that can nuke files it does not recognize.

**Consequences:** Generated l10n files disappear after running `build_runner build`, or vice versa. Compilation fails with missing `AppLocalizations` class.

**Prevention:**
1. **Put ARB files and generated output in a dedicated directory** that does not contain any build_runner-managed files:
   ```yaml
   # l10n.yaml
   arb-dir: lib/l10n
   output-dir: lib/l10n
   synthetic-package: false
   ```
   The `lib/l10n/` directory should contain ONLY `.arb` files and gen-l10n output. No Drift tables, no Riverpod providers, no Freezed models.
2. **Do NOT use `output-dir: lib/`** or any directory that contains `.dart` files managed by build_runner.
3. **Run in the correct order:** `flutter gen-l10n` first, then `dart run build_runner build`. Or better, use `flutter gen-l10n` independently (it does not need build_runner).
4. **Note:** `flutter gen-l10n` is NOT a build_runner builder. It is a standalone Flutter tool. It runs separately from `dart run build_runner build`. They do not conflict as long as their output directories are distinct.

**Detection:** Run `flutter gen-l10n`, verify files exist in `lib/l10n/`. Run `dart run build_runner build --delete-conflicting-outputs`. Verify l10n files still exist.

**Confidence:** HIGH -- verified via Flutter docs. The key insight is that gen-l10n and build_runner are independent systems.

**Phase:** Infrastructure setup task (v1.3).

---

### Pitfall 9: `const Text()` Widgets Break After l10n

**What goes wrong:** Many Text widgets in the codebase are declared as `const`:
```dart
appBar: AppBar(title: const Text('Settings')),
child: const Text('Enable Reminders'),
child: const Text('Usa come target'),
```
After l10n, these become:
```dart
appBar: AppBar(title: Text(AppLocalizations.of(context)!.settingsTitle)),
```
The `const` keyword must be removed because `AppLocalizations.of(context)` is a runtime call. If a parent widget is also `const`, it must lose `const` too. This can cascade: a `const InputDecoration(hintText: 'Custom amount')` becomes non-const, which may affect the parent `TextField`, etc.

**Why it happens:** `const` requires compile-time constants. Localized strings are runtime values.

**Consequences:**
1. **Compilation errors** if `const` is left in place
2. **Lint warnings** from `flutter_lints` about unnecessary `const` removal
3. **Performance:** Removing `const` from leaf widgets has negligible performance impact. The real cost is developer time removing `const` throughout the tree.

**Prevention:**
1. **Accept the const removal.** It is unavoidable and has no meaningful performance impact for this app's scale.
2. **Do NOT try to preserve const** by pre-resolving strings in `initState` or `didChangeDependencies`. This creates stale-string bugs when the locale changes at runtime.
3. **Use find-and-replace systematically:** Search for `const Text('` across all screens. Each one needs l10n treatment.
4. **Count:** The codebase has approximately 15-20 `const Text(...)` widgets that need const removal. This is a manageable manual task.

**Detection:** `flutter analyze` will flag every `const` violation. Fix them all before moving on.

**Confidence:** HIGH -- direct codebase grep identified all instances.

**Phase:** String extraction task (v1.3). Tedious but straightforward.

---

### Pitfall 10: French Plural Rules Differ from Italian/Spanish/English

**What goes wrong:** French treats 0 and 1 as the SAME plural category (`one`), while Italian, Spanish, and English treat only 1 as singular. This means ARB plural messages must be defined carefully:

| Count | English | Italian | French | Spanish |
|-------|---------|---------|--------|---------|
| 0 | "0 days" (other) | "0 giorni" (other) | "0 jour" (one!) | "0 dias" (other) |
| 1 | "1 day" (one) | "1 giorno" (one) | "1 jour" (one) | "1 dia" (one) |
| 2 | "2 days" (other) | "2 giorni" (other) | "2 jours" (other) | "2 dias" (other) |

Additionally, Italian and French have a `many` category for certain large numbers, though this is unlikely to matter for a hydration app (users will not drink 1,000,000 ml of water).

**Why it happens:** CLDR (Unicode Common Locale Data Repository) defines different plural rules per language. The `intl` package and Flutter's gen-l10n respect these rules. If the ARB file for French does not include the `one` category handling 0 correctly, the output is grammatically wrong.

**Consequences:** The streak display says `"0 day streak"` in French (correct per CLDR) but looks odd if the English-speaking developer expected `"0 days"`. If you use a select/plural ICU message format, you must test the `0` case in French specifically.

**Prevention:**
1. **Use ICU plural syntax in ARB files** for any string that includes a count:
   ```json
   "dayStreak": "{count, plural, =0{Nessuna serie} one{{count} giorno di serie} other{{count} giorni di serie}}",
   ```
2. **In the French ARB**, remember that `one` covers both 0 and 1:
   ```json
   "dayStreak": "{count, plural, one{{count} jour de suite} other{{count} jours de suite}}",
   ```
   Here, `one` will match for count=0 ("0 jour de suite") and count=1 ("1 jour de suite"). If you want a special zero case in French, use `=0` explicitly:
   ```json
   "dayStreak": "{count, plural, =0{Aucune serie} one{{count} jour de suite} other{{count} jours de suite}}",
   ```
3. **Test plural strings with counts 0, 1, 2, and 21** in all four locales.
4. **In this app, the affected strings are:**
   - Streak count: `"$streak day streak"` (history_screen.dart line 199)
   - Any future "X entries" or "X ml" strings that use plural forms

**Detection:** Set device to French. Log zero entries. Check if "0 jour" vs "0 jours" is grammatically correct. (Both are acceptable in French -- "0 jour" is prescriptively correct per CLDR, even though "0 jours" is common colloquially.)

**Confidence:** HIGH -- CLDR plural rules verified via unicode.org.

**Phase:** Translation task (v1.3). Translator must be aware of French `one` = {0,1}.

---

### Pitfall 11: table_calendar Locale Not Wired to App Locale

**What goes wrong:** `table_calendar` renders day-of-week headers and month names using the `intl` package. It accepts an optional `locale` parameter. If omitted, it uses the default `intl` locale. After adding l10n, the app's locale changes dynamically, but if `table_calendar`'s `locale` property is not set, the calendar headers remain in the default locale.

Additionally, `table_calendar` requires `initializeDateFormatting()` to be called before using non-default locales. This is documented in the table_calendar README and must be called in `main()`.

**Why it happens:** `table_calendar` does not automatically inherit the `Locale` from `MaterialApp`. It uses the `intl` package's default locale unless overridden via its `locale` parameter.

**Consequences:** The app shows localized UI strings (translated via gen-l10n), but the calendar month names and day-of-week headers remain in English. This is a jarring inconsistency.

**Prevention:**
1. **Pass the locale to `TableCalendar`:**
   ```dart
   TableCalendar(
     locale: Localizations.localeOf(context).toString(),
     // ... other properties
   ),
   ```
2. **Call `initializeDateFormatting()` in `main()`:**
   ```dart
   import 'package:intl/date_symbol_data_local.dart';

   Future<void> main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await initializeDateFormatting(); // loads ALL locale data
     // ... rest of main()
   }
   ```
   Note: `initializeDateFormatting()` with no arguments loads ALL locale data. For a smaller footprint, you could call `initializeDateFormatting('it')`, `initializeDateFormatting('fr')`, etc., but loading all is simpler and the size difference is negligible for a mobile app.
3. **Remove the manual `_monthName()` function** (history_screen.dart lines 16-33) and replace with `DateFormat.MMMM(locale).format(date)`. This eliminates a second source of month names that would not be localized.

**Detection:** Set device to French. Open calendar. If month names are in English but app bar says "Historique", the `locale` parameter is not set.

**Confidence:** HIGH -- verified via table_calendar Context7 docs (README shows locale configuration).

**Phase:** UI wiring task (v1.3). Must be done when localizing the history screen.

---

### Pitfall 12: Dynamic String Concatenation Creates Untranslatable Strings

**What goes wrong:** Several screens use Dart string interpolation to build sentences:
```dart
// home_screen.dart line 140
'${_formatLiters(context, totalMl)} / ${_formatLiters(context, target)} L'

// home_screen.dart line 240
'+$amountMl ml added'

// settings_screen.dart line 155
'Preset ${preset.sortOrder + 1}'

// history_screen.dart line 409
'$dateLabel -- $total of $dailyTarget ml'

// hydration_calculator_screen.dart line 102
'Target aggiornato a ${_formatMl(context, recommendedMl)}'
```
These concatenated strings cannot be extracted to ARB as-is. Each one needs to become an ARB message with placeholders:
```json
"progressText": "{current} / {target} L",
"mlAdded": "+{amount} ml added",
"presetNumber": "Preset {number}",
"daySummary": "{date} -- {total} of {target} ml"
```

**Why it happens:** String interpolation is natural in Dart. It works fine in a single language. But different languages have different word orders, so `"$total of $dailyTarget ml"` cannot be translated to French by just translating "of" -- the entire sentence structure may differ.

**Consequences:** If strings are not properly parameterized in ARB, translators either cannot translate them, or the translations produce grammatically incorrect sentences.

**Prevention:**
1. **Identify ALL interpolated strings** before writing ARB files. Grep for `'$` and `"$` in presentation code.
2. **Convert each to an ARB message with named placeholders:**
   ```json
   {
     "progressDisplay": "{current} / {target} L",
     "@progressDisplay": {
       "placeholders": {
         "current": {"type": "String"},
         "target": {"type": "String"}
       }
     }
   }
   ```
3. **Use `NumberFormat` with locale** for number formatting inside placeholders. Do NOT hardcode comma vs period.
4. **Special case -- "Goal reached!"** (home_screen.dart line 140): The ternary `totalMl == target ? 'Goal reached!' : '...'` should become two separate ARB keys, not a parameterized string with a conditional.

**Detection:** Review ARB files. Any message without `{placeholders}` that corresponds to an interpolated string in the Dart code is a bug.

**Confidence:** HIGH -- direct codebase grep identified all interpolated strings.

**Phase:** String extraction task (v1.3).

---

## Moderate Pitfalls

### Pitfall 13: SnackBar Strings Captured Before Locale Context Available

**What goes wrong:** Several SnackBar messages are created in async callbacks. The pattern:
```dart
void _onQuickAdd(int amountMl) async {
  await repo.insertEntry(amountMl, DateTime.now(), capturedKey);
  if (!mounted) return;
  messenger.showSnackBar(
    SnackBar(content: Text('+$amountMl ml added')),
  );
}
```
After l10n, this becomes:
```dart
SnackBar(content: Text(AppLocalizations.of(context)!.mlAdded(amountMl))),
```
The `context` is still valid here (protected by `if (!mounted) return`), so this is safe. BUT if the developer pre-resolves the string BEFORE the async gap to "be safe":
```dart
final msg = AppLocalizations.of(context)!.mlAdded(amountMl); // Before async
await repo.insertEntry(...);
if (!mounted) return;
messenger.showSnackBar(SnackBar(content: Text(msg))); // Uses stale msg
```
The string is resolved with the locale at resolution time, which is fine. But if the locale changes during the async gap (unlikely but possible if the user changes language in system settings while the app is processing), the string would be stale.

**Prevention:**
1. **Resolve localized strings AFTER `if (!mounted) return`, not before.** This is already the correct pattern for `ScaffoldMessenger.of(context)` calls.
2. **The existing code pattern is safe.** Do not pre-resolve strings before async gaps.

**Detection:** Code review. Search for `AppLocalizations.of(context)` calls that appear before `await` statements in async methods.

**Confidence:** MEDIUM -- this is a coding pattern risk, not a current bug.

**Phase:** String extraction task (v1.3). Code review checkpoint.

---

### Pitfall 14: Missing `flutter_localizations` SDK Dependency

**What goes wrong:** The `pubspec.yaml` does not currently include `flutter_localizations` as a dependency. Without it, `GlobalMaterialLocalizations.delegate`, `GlobalWidgetsLocalizations.delegate`, and `GlobalCupertinoLocalizations.delegate` are not available. These delegates are REQUIRED for Material and Cupertino widgets to display in the correct locale (date pickers, time pickers, dialogs).

The app uses `showTimePicker()` in `settings_screen.dart` (line 321). Without `GlobalMaterialLocalizations`, the time picker always displays in English regardless of the app locale.

**Why it happens:** `flutter_localizations` is an SDK package (not from pub.dev) that must be explicitly added. It is not included in the default Flutter project template.

**Consequences:**
- Material widgets (TimePicker, DatePicker, AlertDialog buttons) display in English only
- The localizationsDelegates list is incomplete
- `AppLocalizations.of(context)` may work (because gen-l10n creates its own delegate), but Material/Cupertino components are not localized

**Prevention:**
Add to `pubspec.yaml`:
```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
```
Then add delegates to `MaterialApp.router`:
```dart
localizationsDelegates: AppLocalizations.localizationsDelegates,
supportedLocales: AppLocalizations.supportedLocales,
```
The generated `AppLocalizations.localizationsDelegates` getter includes `GlobalMaterialLocalizations.delegate`, `GlobalWidgetsLocalizations.delegate`, and `GlobalCupertinoLocalizations.delegate` automatically.

**Detection:** Open the time picker in Settings after adding l10n. If it shows English labels on an Italian device, the Material localization delegate is missing.

**Confidence:** HIGH -- direct inspection of `pubspec.yaml` confirms no `flutter_localizations` dependency.

**Phase:** Infrastructure setup task (v1.3, first task).

---

### Pitfall 15: Widget Tests Break After Adding l10n

**What goes wrong:** Existing widget tests use `MaterialApp` without `localizationsDelegates`. After l10n, every widget that calls `AppLocalizations.of(context)` requires the delegates to be present. Tests that do not provide them crash with null errors.

The existing test files:
- `test/widget_test.dart` -- likely wraps widgets in a basic `MaterialApp`
- `test/data/repositories/water_repository_test.dart` -- pure-Dart, no widget context (safe)
- `test/data/database/daos/*.dart` -- pure-Dart, no widget context (safe)

Only `widget_test.dart` is at risk.

**Why it happens:** Widget tests create their own widget tree. If the test's `MaterialApp` does not include `localizationsDelegates` and `supportedLocales`, `AppLocalizations.of(context)` returns null.

**Consequences:** All widget tests fail after l10n is added.

**Prevention:**
1. **Create a test helper that wraps widgets with l10n:**
   ```dart
   Widget buildTestApp(Widget child, {Locale locale = const Locale('en')}) {
     return MaterialApp(
       localizationsDelegates: AppLocalizations.localizationsDelegates,
       supportedLocales: AppLocalizations.supportedLocales,
       locale: locale,
       home: child,
     );
   }
   ```
2. **Use this helper in all widget tests.** It allows testing specific locales:
   ```dart
   testWidgets('Home screen shows Italian strings', (tester) async {
     await tester.pumpWidget(buildTestApp(const HomeScreen(), locale: const Locale('it')));
     expect(find.text('Obiettivo raggiunto!'), findsOneWidget);
   });
   ```
3. **Test ALL four locales** (en, it, fr, es) for at least one screen to verify the full l10n pipeline works end-to-end.
4. **Do not test by matching exact translated strings** unless the test is specifically a localization test. For functional tests, use `find.byType` or `find.byKey` instead of `find.text`.

**Detection:** Run `flutter test` after adding l10n. If widget tests fail with null errors, the test setup needs l10n delegates.

**Confidence:** HIGH -- standard Flutter testing pattern documented in official docs.

**Phase:** Testing task (v1.3). Must update existing tests and add l10n-specific tests.

---

### Pitfall 16: Forgetting `initializeDateFormatting()` Causes intl Crashes

**What goes wrong:** The `intl` package's `DateFormat` and `NumberFormat` classes require locale data to be initialized before use with non-default locales. The home screen already uses `NumberFormat.decimalPatternDigits(locale: locale)` (line 219), which works because the default `en_US` locale data is always available. But once the locale is `it`, `fr`, or `es`, `NumberFormat` and `DateFormat` need their locale data loaded.

Currently, `initializeDateFormatting()` is NOT called anywhere in `main()` (verified by grep). The `intl` package is used only with the default locale (which works without initialization). After l10n, non-English locales will fail.

**Why it happens:** The `intl` package loads locale data lazily for some features, but `DateFormat` with a non-default locale requires explicit initialization.

**Consequences:** `DateFormat.MMMM('fr').format(date)` throws `LocaleDataException: Locale data has not been initialized`. This would crash the calendar screen when displaying month names in French.

**Prevention:**
1. **Call `initializeDateFormatting()` in `main()` before `runApp()`:**
   ```dart
   import 'package:intl/date_symbol_data_local.dart';

   Future<void> main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await initializeDateFormatting();
     // ... timezone init, notification init ...
     runApp(const ProviderScope(child: DrinkyDrinkyApp()));
   }
   ```
2. **Call it once with no arguments** to load all locale data. The `intl` package is already a dependency at version 0.20.2.
3. **Do NOT call it per-locale** (e.g., `initializeDateFormatting('fr')`) unless APK size is critical. For a 4-locale app, loading all is fine.

**Detection:** Set device to French. Open the calendar. If it crashes with `LocaleDataException`, initialization was missed.

**Confidence:** HIGH -- verified via table_calendar Context7 docs and intl package behavior.

**Phase:** Infrastructure setup task (v1.3, in `main()` modifications).

---

### Pitfall 17: Mixed Italian/English Strings in Current Codebase

**What goes wrong:** The current codebase has BOTH Italian and English hardcoded strings. Some screens are predominantly English (home_screen, history_screen, permission_screen, preset_edit_dialog), while the hydration calculator is predominantly Italian. The settings screen is a mix of both. This creates a confusing baseline for string extraction:

**English strings:** `'Settings'`, `'History'`, `'Do Not Disturb'`, `'Enable Reminders'`, `'Skip for now'`, `'Add'`, `'Cancel'`, `'Confirm'`, `'Goal reached!'`, `'No drinks logged yet'`, `'day streak'`

**Italian strings:** `'Maschio'`, `'Femmina'`, `'Sesso'`, `'Peso'`, `'Clima'`, `'Calcolatore idratazione'`, `'Usa come target'`, `'Salta'`, `'Applica da domani'`, `'Ricalcola raccomandazione idratazione'`, `'Compila tutti i campi'`, `'La tua raccomandazione'`

**Mixed (same screen):** `settings_screen.dart` has `'Settings'` (English) and `'Applica da domani'` (Italian) side by side.

**Why it happens:** The app evolved organically. The calculator was written in Italian. Other screens were written in English. Nobody enforced a single source language.

**Consequences:**
- When creating the template ARB file (typically `app_en.arb`), the developer must decide: is the template language English or Italian?
- If the template is English (`app_en.arb`), ALL Italian strings must be translated to English for the template, then back to Italian for `app_it.arb`. This is double-work and error-prone.
- If the template is Italian, the English ARB becomes a translation rather than the source.

**Prevention:**
1. **Use English as the template language** (`app_en.arb`). English is the fallback locale declared in the project spec.
2. **First pass: extract ALL strings** (both Italian and English) into English ARB keys.
3. **For currently-Italian strings:** The developer must decide the English equivalent. E.g., `'Calcolatore idratazione'` -> ARB key `hydrationCalculatorTitle`, English value `"Hydration calculator"`.
4. **For currently-English strings:** Use the existing English text directly. E.g., `'Settings'` -> ARB key `settingsTitle`, English value `"Settings"`.
5. **Create ALL four ARB files** (en, it, fr, es) during extraction, not after. This prevents the "I'll do translations later" trap where the Italian ARB is forgotten because the developer thinks the Italian strings are "already there" in the source code.

**Detection:** After extraction, run the app in Italian. If some strings appear in English, the Italian ARB is missing entries.

**Confidence:** HIGH -- direct codebase analysis of all 6 screens.

**Phase:** String extraction task (v1.3). This is the primary complexity driver for this milestone.

---

## Minor Pitfalls

### Pitfall 18: RTL Layout Breakage (Even Without RTL Languages)

**What goes wrong:** Adding `GlobalWidgetsLocalizations.delegate` and `GlobalMaterialLocalizations.delegate` to `MaterialApp` can subtly change the text direction handling in the widget tree, even when all supported languages are LTR. Specifically:
- `Alignment.centerLeft` behaves differently when `Directionality` is explicitly set vs inherited
- `EdgeInsets.symmetric(horizontal: ...)` is safe, but `EdgeInsets.only(left: ...)` could misbehave if a future RTL locale is added
- Row children with `Expanded` + `Text` may wrap differently

For this app's four target languages (en, it, fr, es), ALL are LTR. There should be zero RTL impact.

**Why it happens:** Adding localization delegates makes `Directionality` resolution more explicit. In a non-localized app, Flutter uses `LTR` by default. In a localized app, it uses the locale's directionality. For LTR locales, the result is the same.

**Consequences:** For en/it/fr/es: NONE. This is a non-issue for this milestone.

**Prevention:**
1. **Do nothing.** All four target locales are LTR.
2. **If Arabic or Hebrew support is added later** (out of scope for v1.3), audit all `EdgeInsets.only(left/right)` and `Alignment.centerLeft/centerRight` usages. Replace with `EdgeInsetsDirectional.start/end` and `AlignmentDirectional.centerStart/centerEnd`.
3. **Current codebase uses `EdgeInsets.symmetric` consistently** (verified by grep), which is RTL-safe.

**Detection:** Not needed for v1.3. All target locales are LTR.

**Confidence:** HIGH -- all four target locales are LTR. Verified that the codebase uses symmetric padding.

**Phase:** None for v1.3. Document for future.

---

### Pitfall 19: Hot Reload Does Not Update Generated l10n Files

**What goes wrong:** After modifying `.arb` files, hot reload does not regenerate the localization classes. The developer adds a new string to `app_en.arb`, hot-reloads, and gets a compile error because `AppLocalizations` does not have the new getter.

**Why it happens:** `flutter gen-l10n` is a separate build step, not part of the hot reload cycle. Unlike build_runner's `watch` mode, gen-l10n does not have a file watcher. (Note: `flutter run` with `generate: true` in `pubspec.yaml` DOES run gen-l10n automatically during `flutter run`, but only on cold start, not on hot reload.)

**Prevention:**
1. **After editing ARB files, run `flutter gen-l10n` manually** or restart the app (`flutter run` again).
2. **Use `flutter run` with `--dart-define` or just accept the cold restart.**
3. **Do NOT expect hot reload to pick up ARB changes.** This is by design.
4. **Tip:** Edit all strings in one batch, run gen-l10n once, then hot-reload the Dart code changes.

**Detection:** If `AppLocalizations.of(context)!.newKey` causes a compile error after adding `newKey` to the ARB, you forgot to run gen-l10n.

**Confidence:** HIGH -- documented Flutter behavior.

**Phase:** Development workflow (v1.3). Inform developers.

---

### Pitfall 20: `intl` Version Constraint Conflict

**What goes wrong:** The current `pubspec.yaml` has `intl: ^0.20.2`. The `flutter_localizations` SDK package also depends on `intl`. If `flutter_localizations` pins a different `intl` version range, `pub get` fails with a dependency conflict.

**Why it happens:** `flutter_localizations` is an SDK package that ships with the Flutter SDK. Its `intl` dependency is pinned to the Flutter SDK's bundled version. If the project specifies a different `intl` version, they may conflict.

**Prevention:**
1. **Use `intl: any` when also depending on `flutter_localizations`:**
   ```yaml
   dependencies:
     flutter_localizations:
       sdk: flutter
     intl: any  # Use whatever version flutter_localizations needs
   ```
   This is the official recommendation from Flutter docs.
2. **Or remove the explicit `intl` dependency** and let it be transitively resolved through `flutter_localizations`.
3. **The current `intl: ^0.20.2` should be compatible** with Flutter 3.44.1's bundled version, but using `any` is safer.

**Detection:** Run `flutter pub get` after adding `flutter_localizations`. If it fails with a version conflict on `intl`, change to `intl: any`.

**Confidence:** MEDIUM -- depends on the specific Flutter SDK version's intl pin. Likely compatible, but `any` is the safe choice.

**Phase:** Infrastructure setup task (v1.3).

---

## Phase-Specific Warnings Summary

| Phase Topic | Pitfall | Severity | Mitigation |
|-------------|---------|----------|------------|
| Infrastructure setup | #3 (context before MaterialApp), #7 (synthetic-package), #8 (output-dir), #14 (flutter_localizations), #16 (initializeDateFormatting), #20 (intl version) | CRITICAL/HIGH | Create l10n.yaml correctly; add flutter_localizations; add initializeDateFormatting to main(); use nullable-getter: false |
| String extraction | #2 (missed strings), #4 (calculator map keys), #9 (const removal), #12 (interpolation), #17 (mixed languages) | CRITICAL/HIGH | Comprehensive grep; refactor calculator to enums; convert interpolation to ARB placeholders; use English template |
| Notification l10n | #1 (singleton no context) | CRITICAL | Pass resolved strings to scheduleWindow(); keep singleton pure-Dart |
| Translation | #10 (French plurals) | HIGH | Use ICU plural syntax; test 0/1/2 in all locales; brief translator on French 0=singular |
| UI wiring | #11 (table_calendar locale), #13 (SnackBar context) | HIGH/MEDIUM | Pass locale to TableCalendar; resolve strings after mounted check |
| Platform config | #5 (iOS Info.plist), #6 (Android resConfigs) | HIGH/MEDIUM | Add CFBundleLocalizations; add resConfigs; test on both platforms |
| Testing | #15 (widget test breakage) | HIGH | Create l10n test helper; wrap all widget tests; test all 4 locales |
| Development workflow | #19 (hot reload), #18 (RTL) | LOW | Run gen-l10n after ARB edits; no RTL action for v1.3 |

---

## Sources

- Flutter internationalization docs (Context7, flutter.dev): https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization (HIGH confidence)
- Flutter breaking change -- synthetic-package (Context7): https://docs.flutter.dev/release/breaking-changes/flutter-generate-i10n-source (HIGH confidence)
- table_calendar README -- locale configuration (Context7, GitHub): https://github.com/aleksanderwozniak/table_calendar (HIGH confidence)
- CLDR Language Plural Rules (unicode.org): https://www.unicode.org/cldr/charts/latest/supplemental/language_plural_rules.html (HIGH confidence)
- Direct codebase analysis: `notification_service.dart`, `main.dart`, `home_screen.dart`, `settings_screen.dart`, `history_screen.dart`, `hydration_calculator_screen.dart`, `permission_screen.dart`, `preset_edit_dialog.dart`, `pubspec.yaml`, `Info.plist`, `build.gradle.kts`, `project.pbxproj` (HIGH confidence)
