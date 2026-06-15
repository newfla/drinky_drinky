# Feature Landscape: Flutter l10n (Multilingual Support)

**Domain:** Flutter hydration tracker -- multilingual support (it/en/fr/es, EN fallback)
**Researched:** 2026-06-15
**Overall confidence:** HIGH (Flutter ARB-based l10n is mature, well-documented, and verified via Context7 + official docs)

---

## Table Stakes

Features users expect from a properly localized app. Missing any = broken UX for non-Italian speakers.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| All visible UI strings translated (it/en/fr/es) | Core multilingual requirement | Medium | ~75-85 distinct string keys across 5 screens + 1 dialog + 1 bottom sheet |
| Notification title/body translated | Users see notifications in system language | Medium | **Critical challenge:** NotificationService is a singleton, not in widget tree; requires `delegate.load()` pattern |
| System locale auto-detection | Standard mobile behavior | Low | Flutter's `supportedLocales` + default locale resolution handle this automatically |
| English fallback for unsupported locales | Prevents empty/broken strings | Low | Put `Locale('en')` first in `supportedLocales` list; Flutter falls back to first entry |
| Plural forms for streak counter | "1 day streak" vs "2 days streak" / "1 giorno di fila" vs "2 giorni di fila" | Low | ICU plural syntax in ARB; `=1{...} other{...}` |
| Parameterized strings with arguments | "Target: 2,000 ml", "+250 ml added" | Low | ARB placeholder syntax with `{value}` |
| Calendar/date formatting locale-aware | Month names, date order in table_calendar and day summary | Low | Already using `intl` package; `DateFormat` is locale-aware when `initializeDateFormatting()` is called |
| Material widget localization | Date pickers, buttons, dialog text in correct language | Low | `GlobalMaterialLocalizations.delegate` via `flutter_localizations` SDK package |
| Accessibility labels translated | Semantic labels on calendar day cells | Low | Replace hardcoded `_monthName()` helper with `DateFormat.MMMM()` + localized goal status strings |

## Differentiators

Features that go beyond minimum l10n but add polish. Not expected, but valued.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Non-nullable AppLocalizations getter | Eliminates `!` on every `AppLocalizations.of(context)` call; cleaner code | Low | Set `nullable-getter: false` in l10n.yaml |
| Number formatting locale-aware (decimal separators) | Italian: "2.000,50" vs English: "2,000.50" | Already done | `NumberFormat.decimalPatternDigits(locale: locale)` already used in home_screen.dart `_formatLiters()` |
| Climate labels translated in calculator | "Freddo/Mite/Caldo" -> "Cold/Mild/Hot" | Low | Currently hardcoded Italian in `_climateLabels` array |
| Sex options translated in calculator | "Maschio/Femmina/Altro" -> "Male/Female/Other" | Low-Med | **Requires decoupling display text from map keys** -- currently `_sexFactors` uses Italian labels as keys |
| Notification channel name translated | Android notification settings show localized channel name | Low | Channel name set at init time; re-create channel with localized name |
| Locale-aware notification rescheduling on language change | Notifications update to new language on next schedule cycle | Low | Already happens naturally: `scheduleWindow()` is called on app resume |

## Anti-Features

Features to explicitly NOT build for this milestone.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| In-app language picker | Adds complexity, non-standard UX; 4 locales do not justify a picker | Follow system locale; users change language in device Settings |
| Country-variant locales (en_US vs en_GB, es_ES vs es_MX) | Overkill for 4-language scope; no meaningful string differences for this app | Use language-only locales: `en`, `it`, `fr`, `es` |
| RTL layout support | None of the 4 target languages are RTL | Do not add RTL-specific layout code |
| Translated app name (CFBundleDisplayName / AndroidManifest label) | App name "Drinky Drinky" is a brand name | Keep "Drinky Drinky" in all locales |
| Translation management platform (Crowdin, Lokalise) | 4 languages, ~80 keys, single developer | Manage ARB files directly in repo |
| Dynamic locale switching without app restart | Flutter's built-in locale resolution handles system changes automatically | Let the system handle it |
| Machine translation / auto-translate | Quality is unpredictable for a polished app | Human-written translations for all four locales |
| Per-screen lazy-loaded translations | Unnecessary for 4 locales with ~80 strings | Load all strings at startup (Flutter's default ARB approach) |

---

## Feature Dependencies

```
initializeDateFormatting() -> calendar month names, date formats
     |
l10n.yaml + ARB files -> flutter gen-l10n -> AppLocalizations class
     |
     +-> MaterialApp.localizationsDelegates + supportedLocales
     |       |
     |       +-> All widget-tree strings (AppLocalizations.of(context))
     |       |
     |       +-> table_calendar locale property
     |
     +-> AppLocalizations.delegate.load(locale) [no context needed]
             |
             +-> NotificationService localized strings
```

---

## ARB-Based l10n: How It Works in Practice

### Infrastructure Setup

**1. Add `flutter_localizations` SDK dependency to pubspec.yaml:**

```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: ^0.20.2  # already present
```

**2. Add `generate: true` to pubspec.yaml flutter section:**

```yaml
flutter:
  generate: true
  uses-material-design: true
```

**3. Create `l10n.yaml` in project root:**

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
nullable-getter: false
synthetic-package: false
output-dir: lib/l10n/generated
```

Key options:
- `nullable-getter: false` -- removes the need for `!` on every `AppLocalizations.of(context)` call. Instead of `AppLocalizations.of(context)!.hello`, you write `AppLocalizations.of(context).hello`.
- `synthetic-package: false` -- **required** since Flutter 3.32+. The old `package:flutter_gen` approach is EOL. Files generate directly into your source tree.
- `output-dir` -- keeps generated code separate from ARB source files for clarity.

**Confidence:** HIGH -- verified via Context7 (Flutter docs) and official breaking change docs for synthetic-package removal.

**4. Wire into MaterialApp:**

```dart
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/generated/app_localizations.dart';

MaterialApp.router(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  // ... existing config
);
```

`AppLocalizations.localizationsDelegates` is a generated convenience list that includes:
- `AppLocalizations.delegate` (your app strings)
- `GlobalMaterialLocalizations.delegate` (Material widget strings)
- `GlobalWidgetsLocalizations.delegate` (text direction)
- `GlobalCupertinoLocalizations.delegate` (Cupertino widget strings)

`AppLocalizations.supportedLocales` is auto-generated from your ARB files.

**Confidence:** HIGH -- verified via Context7 (Flutter internationalization docs).

### Pattern 1: Simple String Substitution

**ARB (app_en.arb):**
```json
{
  "@@locale": "en",
  "appTitle": "Drinky Drinky",
  "settingsTitle": "Settings",
  "historyTitle": "History",
  "noHistory": "No history yet",
  "goalReached": "Goal reached!",
  "addWater": "Add water",
  "add": "Add",
  "customAmount": "Custom amount",
  "doNotDisturb": "Do Not Disturb",
  "startTime": "Start time",
  "endTime": "End time",
  "enableReminders": "Enable Reminders",
  "skipForNow": "Skip for now"
}
```

**Dart usage:**
```dart
Text(AppLocalizations.of(context).settingsTitle)
```

**Confidence:** HIGH -- fundamental gen-l10n pattern, verified via Context7.

### Pattern 2: Plurals (Streak Counter)

**ARB (app_en.arb):**
```json
{
  "streakCount": "{count, plural, =0{No streak} =1{1 day streak} other{{count} day streak}}",
  "@streakCount": {
    "description": "Streak counter label on history screen",
    "placeholders": {
      "count": {
        "type": "num"
      }
    }
  }
}
```

**ARB (app_it.arb):**
```json
{
  "streakCount": "{count, plural, =0{Nessuna serie} =1{1 giorno di fila} other{{count} giorni di fila}}"
}
```

**ARB (app_fr.arb):**
```json
{
  "streakCount": "{count, plural, =0{Pas de serie} =1{1 jour consecutif} other{{count} jours consecutifs}}"
}
```

**ARB (app_es.arb):**
```json
{
  "streakCount": "{count, plural, =0{Sin racha} =1{1 dia consecutivo} other{{count} dias consecutivos}}"
}
```

**Dart usage:**
```dart
Text(AppLocalizations.of(context).streakCount(streak))
```

The generated code produces a method `String streakCount(num count)` that handles plural selection per locale using ICU rules. Only `other` is required; `=0`, `=1`, `few`, `many` are optional.

**Important:** Italian, French, Spanish, and English all follow simple `one`/`other` plural rules. No `few` or `many` forms needed for these 4 languages.

**Confidence:** HIGH -- ICU plural syntax verified via Context7 (Flutter internationalization docs).

### Pattern 3: Strings with Arguments (Parameterized)

**ARB (app_en.arb):**
```json
{
  "progressDisplay": "{current} / {target} L",
  "@progressDisplay": {
    "description": "Progress ring text showing current/target in liters",
    "placeholders": {
      "current": { "type": "String" },
      "target": { "type": "String" }
    }
  },
  "mlAdded": "+{amount} ml added",
  "@mlAdded": {
    "description": "SnackBar confirmation after adding water",
    "placeholders": {
      "amount": { "type": "int" }
    }
  },
  "presetLabel": "+{amount} ml",
  "@presetLabel": {
    "description": "Quick-add preset button label",
    "placeholders": {
      "amount": { "type": "int" }
    }
  },
  "presetNumber": "Preset {number}",
  "@presetNumber": {
    "description": "Settings preset row title",
    "placeholders": {
      "number": { "type": "int" }
    }
  },
  "targetUpdated": "Target updated to {value}",
  "@targetUpdated": {
    "description": "SnackBar after calculator applies target",
    "placeholders": {
      "value": { "type": "String" }
    }
  }
}
```

**Dart usage:**
```dart
// Progress ring
Text(AppLocalizations.of(context).progressDisplay(
  _formatLiters(context, totalMl),
  _formatLiters(context, target),
))

// SnackBar
Text(AppLocalizations.of(context).mlAdded(amountMl))
```

**Note on the progress display:** The `current` and `target` parameters are `String` (not `int`) because the liters formatting (`_formatLiters`) already handles locale-aware decimal formatting. Passing pre-formatted strings avoids double-formatting.

**Confidence:** HIGH -- placeholder syntax verified via Context7.

### Pattern 4: Notification Strings Outside Widget Tree

**The problem:** `NotificationService` is a singleton accessed via `NotificationService.instance`. It has no `BuildContext`, so `AppLocalizations.of(context)` is not available. The notification title and body are currently hardcoded as `static const String` fields.

**The solution: `AppLocalizations.delegate.load(locale)`**

The generated `AppLocalizations.delegate` is a `LocalizationsDelegate<AppLocalizations>`. Its `load(Locale locale)` method returns `Future<AppLocalizations>` and can be called anywhere -- no `BuildContext` required.

To get the device locale without context: `WidgetsBinding.instance.platformDispatcher.locale`

**Implementation pattern:**

```dart
import 'dart:ui' show PlatformDispatcher;
import '../l10n/generated/app_localizations.dart';

class NotificationService {
  // ... existing code ...

  /// Get localized strings for the current device locale.
  /// Falls back to English if the device locale is not supported.
  Future<AppLocalizations> _getLocalizations() async {
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;

    // Check if device locale is supported; fall back to English
    final supportedLocale = AppLocalizations.supportedLocales.firstWhere(
      (l) => l.languageCode == deviceLocale.languageCode,
      orElse: () => const Locale('en'),
    );

    return AppLocalizations.delegate.load(supportedLocale);
  }

  Future<void> scheduleWindow(UserSettingsEntity settings) async {
    await cancelAll();
    if (!_initialized) return;
    if (!(await permissionGranted())) return;

    // Load localized strings once for all notifications in this batch
    final l10n = await _getLocalizations();
    final title = l10n.notificationTitle;   // e.g. "Drinky Drinky"
    final body = l10n.notificationBody;     // e.g. "Time to drink water!"

    // ... scheduling loop uses title and body instead of _notifTitle/_notifBody ...
    await _plugin.zonedSchedule(
      id: slotId++,
      scheduledDate: candidate,
      notificationDetails: _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      title: title,
      body: body,
      matchDateTimeComponents: null,
    );
  }
}
```

**Why this works:**
- `delegate.load()` is a pure factory method that instantiates the correct locale subclass of `AppLocalizations`. It does not require the widget tree.
- The locale is read from `PlatformDispatcher` which reflects the device's current system locale.
- Fallback to English is explicit via the `firstWhere` + `orElse` pattern.

**Critical caveat:** Notifications are scheduled with the locale active at scheduling time. If the user changes their device language, previously scheduled notifications retain the OLD language text. This is acceptable because `scheduleWindow()` is called on every app resume, settings change, and permission grant -- so notifications are re-scheduled frequently with the new locale.

**ARB entries for notifications:**
```json
{
  "notificationTitle": "Drinky Drinky",
  "@notificationTitle": {
    "description": "Notification title for hydration reminders"
  },
  "notificationBody": "Time to drink water!",
  "@notificationBody": {
    "description": "Notification body for hydration reminders"
  }
}
```

**Confidence:** HIGH -- `LocalizationsDelegate.load(Locale)` returns `Future<T>` per official API docs (api.flutter.dev). `WidgetsBinding.instance.platformDispatcher.locale` verified via Context7 (Flutter breaking changes docs for window singleton deprecation).

### Pattern 5: Locale Fallback for Unsupported System Locale

**How Flutter resolves locale (built-in, no custom code needed):**

1. User's device locale matches a supported locale exactly (e.g., `it` matches `it`) -- use it
2. Language code matches but country code differs (e.g., `es_AR` matches `es`) -- use the matching language
3. No match at all (e.g., `de`) -- fall back to **first entry** in `supportedLocales`

**Therefore, put English first in the ARB directory:**

```
lib/l10n/
  app_en.arb    <-- template (first = default fallback)
  app_it.arb
  app_fr.arb
  app_es.arb
```

In `l10n.yaml`:
```yaml
template-arb-file: app_en.arb
```

The generated `AppLocalizations.supportedLocales` list is ordered by the ARB files. By making `app_en.arb` the template, English is the first element and becomes the fallback for any unsupported locale.

**No `localeResolutionCallback` needed** for this use case. Flutter's default resolution handles it.

**Confidence:** HIGH -- Flutter docs explicitly state: "If an exact match for the device locale isn't found, then the first supported locale with a matching languageCode is used. If that fails, then the first element of the supportedLocales list is used." Verified via Context7.

---

## Complete String Inventory (Extraction Scope)

### Home Screen (`home_screen.dart`)

| Current String | Type | ARB Key | Notes |
|----------------|------|---------|-------|
| `'Drinky Drinky'` (AppBar) | Simple | `appTitle` | Brand name, same in all locales |
| `'Add water'` (FAB tooltip) | Simple | `addWater` | |
| `'Goal reached!'` | Simple | `goalReached` | |
| `'{current} / {target} L'` | Parameterized | `progressDisplay` | Args are pre-formatted liter strings |
| `"Today's Intake"` | Simple | `todaysIntake` | |
| `'No drinks logged yet'` | Simple | `noDrinksLogged` | |
| `'Tap the + button to log your first drink today.'` | Simple | `noDrinksLoggedHint` | |
| `'+$amountMl ml added'` | Parameterized | `mlAdded` | SnackBar |
| `'UNDO'` | Simple | `undo` | SnackBar action |
| `'+${preset.amountMl} ml'` | Parameterized | `presetLabel` | Preset button text |
| `'Custom amount'` (hint) | Simple | `customAmount` | Bottom sheet TextField |
| `'ml'` (suffix) | Simple | `mlUnit` | Unit suffix |
| `'Add'` (button) | Simple | `add` | Bottom sheet confirm |
| `'Something went wrong...'` | Simple | `errorLoadingDataRestart` | Error state |

### Settings Screen (`settings_screen.dart`)

| Current String | Type | ARB Key | Notes |
|----------------|------|---------|-------|
| `'Settings'` (AppBar) | Simple | `settingsTitle` | |
| `'DAILY GOAL'` | Simple | `dailyGoalSection` | Section label |
| `'QUICK-ADD PRESETS'` | Simple | `presetsSection` | Section label |
| `'NOTIFICATIONS'` | Simple | `notificationsSection` | Section label |
| `'HYDRATION'` | Simple | `hydrationSection` | Section label |
| `'${currentTarget.toInt()} ml'` | Parameterized | `valueMl` | Target slider value |
| `'${currentInterval.toInt()} min'` | Parameterized | `valueMin` | Interval slider value |
| `'Applica da domani'` | Simple | `applyFromTomorrow` | Already Italian! |
| `'Le modifiche al target entrano in vigore domani'` | Simple | `applyFromTomorrowDesc` | |
| `'Le modifiche al target entrano in vigore oggi'` | Simple | `applyFromTodayDesc` | |
| `'Preset ${preset.sortOrder + 1}'` | Parameterized | `presetNumber` | |
| `'${preset.amountMl} ml'` | Parameterized | `valueMl` | Reuse of valueMl |
| `'Ricalcola raccomandazione idratazione'` | Simple | `recalculateHydration` | Already Italian! |
| `'Notifications are disabled...'` | Simple | `notificationsDisabled` | Permission banner |
| `'Open'` | Simple | `openSystemSettings` | Button to system settings |
| `'Do Not Disturb'` | Simple | `doNotDisturb` | |
| `'On'` / `'Off'` | Simple | `on` / `off` | DND status |
| `'Start time'` / `'End time'` | Simple | `startTime` / `endTime` | |
| `'Something went wrong...'` | Simple | `errorLoadingData` | Error state |

### History Screen (`history_screen.dart`)

| Current String | Type | ARB Key | Notes |
|----------------|------|---------|-------|
| `'History'` (AppBar, 3 instances) | Simple | `historyTitle` | |
| `'No history yet'` | Simple | `noHistory` | Empty state |
| `'Start logging water on the Home tab...'` | Simple | `noHistoryBody` | Empty state body |
| `'$streak'` + `' day streak'` | **Plural** | `streakCount` | ICU plural format: `{count, plural, =1{...} other{...}}` |
| `'${_monthName(day.month)} ${day.day}: goal met'` | Parameterized | `calendarDayGoalMet` | Semantic label |
| `'${_monthName(day.month)} ${day.day}: goal not met'` | Parameterized | `calendarDayGoalNotMet` | Semantic label |
| `'$dateLabel -- $total of $dailyTarget ml'` | Parameterized | `daySummary` | Day summary card |
| `'$dateLabel -- No entries'` | Parameterized | `daySummaryEmpty` | Day summary card |
| `_monthName()` helper (English array) | **Remove entirely** | -- | Replace with `DateFormat.MMMM(locale).format(date)` |
| `'Something went wrong...'` | Simple | `errorLoadingData` | Reuse |

### Permission Screen (`permission_screen.dart`)

| Current String | Type | ARB Key | Notes |
|----------------|------|---------|-------|
| `'Stay hydrated with reminders'` | Simple | `permissionTitle` | |
| `'Drinky Drinky sends you gentle reminders...'` | Simple | `permissionBody` | |
| `'Enable Reminders'` | Simple | `enableReminders` | |
| `'Skip for now'` | Simple | `skipForNow` | |
| `'Reminders enabled!...'` | Simple | `remindersEnabledMessage` | SnackBar |
| `'No problem...'` | Simple | `remindersDeniedMessage` | SnackBar |

### Hydration Calculator Screen (`hydration_calculator_screen.dart`)

| Current String | Type | ARB Key | Notes |
|----------------|------|---------|-------|
| `'Calcolatore idratazione'` | Simple | `calculatorTitle` | Already Italian |
| `'Sesso'` | Simple | `sexLabel` | Section label |
| `'Maschio'` / `'Femmina'` / `'Altro'` | Simple | `sexMale` / `sexFemale` / `sexOther` | **CRITICAL: decouple from `_sexFactors` map keys** |
| `'Peso'` | Simple | `weightLabel` | Section label |
| `'Peso (kg)'` | Simple | `weightInputLabel` | TextField label |
| `'kg'` | Simple | `kgUnit` | Suffix |
| `'Inserisci un peso tra 1 e 300 kg'` | Simple | `weightError` | Validation error |
| `'Clima'` | Simple | `climateLabel` | Section label |
| `'Freddo'`/`'Mite'`/`'Caldo'`/`'Molto caldo'`/`'Afoso'` | Simple | `climateCold`/`climateMild`/`climateHot`/`climateVeryHot`/`climateHumid` | 5 climate labels |
| `'La tua raccomandazione'` | Simple | `yourRecommendation` | |
| `'Compila tutti i campi'` | Simple | `fillAllFields` | Incomplete state |
| Privacy disclaimer text | Simple | `privacyDisclaimer` | Multi-sentence |
| `'Usa come target'` | Simple | `useAsTarget` | |
| `'Salta'` | Simple | `skip` | Onboarding only |
| `'Errore durante l\'aggiornamento...'` | Simple | `targetUpdateError` | SnackBar error |
| `'Target aggiornato a ${value}'` | Parameterized | `targetUpdated` | SnackBar success |

### Preset Edit Dialog (`preset_edit_dialog.dart`)

| Current String | Type | ARB Key | Notes |
|----------------|------|---------|-------|
| `'Edit Preset ${widget.preset.sortOrder + 1}'` | Parameterized | `editPreset` | Dialog title |
| `'Amount (ml)'` | Simple | `amountMlLabel` | TextField label |
| `'ml'` | Simple | `mlUnit` | Reuse |
| `'Enter a value between 50 and 2000'` | Simple | `presetAmountError` | Validation |
| `'Cancel'` | Simple | `cancel` | |
| `'Confirm'` | Simple | `confirm` | |

### NotificationService (`notification_service.dart`)

| Current String | Type | ARB Key | Notes |
|----------------|------|---------|-------|
| `'Hydration Reminders'` (channel name) | Simple | `notificationChannelName` | Android notification channel |
| `'Drinky Drinky'` (notification title) | Simple | `notificationTitle` | |
| `'Time to drink water!'` (notification body) | Simple | `notificationBody` | |

**Total estimated string keys: ~75-85**

---

## Critical Implementation Details

### Decoupling Calculator Sex Labels from Logic Keys

**Problem:** The current `_sexFactors` map uses Italian display text as keys:

```dart
static const _sexFactors = {
  'Maschio': 35.0,
  'Femmina': 31.0,
  'Altro': 33.0,
};
```

The `_selectedSex` state variable stores `'Maschio'`, `'Femmina'`, or `'Altro'` -- the SAME strings used for both display and computation. When display strings are localized, the map lookup breaks.

**Solution:** Use locale-independent enum for logic; display strings from ARB:

```dart
// Logic keys (never change, never displayed directly)
enum BiologicalSex { male, female, other }

static const _sexFactors = {
  BiologicalSex.male: 35.0,
  BiologicalSex.female: 31.0,
  BiologicalSex.other: 33.0,
};

BiologicalSex? _selectedSex;

// Display via ARB
SegmentedButton<BiologicalSex>(
  segments: [
    ButtonSegment(
      value: BiologicalSex.male,
      label: Text(AppLocalizations.of(context).sexMale),
    ),
    ButtonSegment(
      value: BiologicalSex.female,
      label: Text(AppLocalizations.of(context).sexFemale),
    ),
    ButtonSegment(
      value: BiologicalSex.other,
      label: Text(AppLocalizations.of(context).sexOther),
    ),
  ],
  selected: _selectedSex != null ? {_selectedSex!} : {},
  onSelectionChanged: (sel) =>
      setState(() => _selectedSex = sel.firstOrNull),
),
```

Same pattern applies to `_climateLabels` -- replace the Italian string array with a method that returns localized labels from AppLocalizations indexed by integer position.

### Replacing `_monthName()` in History Screen

The hardcoded English month name array must be replaced:

```dart
// BEFORE (hardcoded English)
String _monthName(int month) {
  const names = ['', 'January', 'February', ...];
  return names[month];
}

// AFTER (locale-aware via intl)
String _monthName(DateTime date, String locale) {
  return DateFormat.MMMM(locale).format(date);
}
```

This requires passing the locale string (from `Localizations.localeOf(context).toString()`) or using `DateFormat.MMMM()` with the current locale. The `intl` package handles Italian/French/Spanish/English month names automatically after `initializeDateFormatting()` is called.

### table_calendar Locale Property

`TableCalendar` accepts a `locale` property that controls day-of-week headers and month names:

```dart
TableCalendar(
  locale: Localizations.localeOf(context).toString(),
  // ... rest of config
)
```

**Prerequisite:** `initializeDateFormatting()` must be called in `main()` before `runApp()`:

```dart
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();  // ADD THIS -- inits all locale data for intl
  // ... existing timezone init, notification init ...
  runApp(const ProviderScope(child: DrinkyDrinkyApp()));
}
```

**Confidence:** HIGH -- verified via Context7 (table_calendar docs).

### Notification Channel Name Re-creation

Android notification channels are created once and persist. If the user changes language, the channel name shown in Android Settings stays in the old language.

**Solution:** Re-create the channel on every `initialize()` call with the localized name. Android allows re-creating channels with the same ID -- it updates the display name without losing user preferences (importance, sound, etc.):

```dart
Future<void> initialize() async {
  // ... existing init code ...

  if (Platform.isAndroid) {
    final l10n = await _getLocalizations();
    final channel = AndroidNotificationChannel(
      _channelId,
      l10n.notificationChannelName,  // localized
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
  _initialized = true;
}
```

### `const` Removal Impact

Many widgets currently use `const Text('...')` for hardcoded strings. After l10n, these become `Text(AppLocalizations.of(context).someKey)` which is NOT const. This is expected and harmless -- the performance difference is negligible. Do not try to preserve `const` by caching strings.

---

## MVP Recommendation

**Prioritize (must-have for v1.3):**

1. l10n infrastructure (l10n.yaml, ARB files, flutter_localizations dep, MaterialApp wiring, initializeDateFormatting)
2. Template ARB file (app_en.arb) with all ~80 string keys and metadata
3. Translation ARB files (app_it.arb, app_fr.arb, app_es.arb) -- all strings translated
4. All UI screens refactored to use `AppLocalizations.of(context)` instead of hardcoded strings
5. Calculator sex/climate label decoupling from logic keys (enum instead of string keys)
6. `_monthName()` replacement with locale-aware `DateFormat.MMMM()`
7. table_calendar `locale` property wiring
8. Notification strings via `delegate.load()` pattern in NotificationService
9. English fallback (template = en, first in supportedLocales)

**Defer (nice-to-have, include if time permits):**

- Notification channel name localization: Low impact, channel name is rarely seen by users
- Semantic label translations for calendar day cells: Important for accessibility but not blocking

---

## Sources

- Flutter internationalization docs (Context7: /websites/flutter_dev, topic "internationalization l10n gen-l10n ARB") -- ARB syntax, plural format, placeholder syntax, MaterialApp wiring, locale resolution, l10n.yaml options
- Flutter breaking changes: synthetic-package removal (https://docs.flutter.dev/release/breaking-changes/flutter-generate-i10n-source) -- `synthetic-package: false` required since 3.32
- Flutter API: LocalizationsDelegate.load() (https://api.flutter.dev/flutter/widgets/LocalizationsDelegate-class.html) -- `load(Locale) -> Future<T>` for non-context usage
- Flutter window singleton deprecation (Context7: /websites/flutter_dev) -- `WidgetsBinding.instance.platformDispatcher.locale` for device locale without context
- table_calendar docs (Context7: /aleksanderwozniak/table_calendar) -- `locale` property, `initializeDateFormatting()` prerequisite
- Existing codebase: notification_service.dart, home_screen.dart, settings_screen.dart, history_screen.dart, hydration_calculator_screen.dart, permission_screen.dart, preset_edit_dialog.dart
