# Phase 13: String Extraction & Translation - Research

**Researched:** 2026-06-15
**Domain:** Flutter ARB-based l10n — enum refactor, widget string replacement, it/fr/es translation content
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- D-01: Italian translations use **tu informale** (not Lei).
- D-02: French translations use **tu** (not vous).
- D-03: Spanish translations use **tú** (not usted).
- D-04: "streak" translates as:
  - Italian: `=0{Nessuna serie} =1{1 giorno consecutivo} other{{count} giorni consecutivi}`
  - French: `=0{Aucune série} =1{1 jour consécutif} other{{count} jours consécutifs}`
  - Spanish: `=0{Sin racha} =1{1 día consecutivo} other{{count} días consecutivos}`
  - Same `=0{...} =1{...} other{...}` ICU pattern for all 3 languages.
- D-05: Two plans — Plan 1: enum refactor + widget replacement (EN fallback). Plan 2: fill it/fr/es ARB files + re-run flutter gen-l10n.

### Claude's Discretion
- `BiologicalSex` and `ClimateLevel` enum placement: new file `lib/domain/entities/hydration_enums.dart` (Claude's recommended choice — see Section 1 below).
- All other translation choices (section headers, error messages, button labels) follow standard Italian/French/Spanish usage.

### Deferred Ideas (OUT OF SCOPE)
- NotificationService localization → Phase 14 (L10N-07)
- iOS `Info.plist` CFBundleLocalizations → Phase 14 (L10N-08)
- Android `resConfigs` → Phase 14 (L10N-09)
- Human review of machine translations → v1.4+ (L10N-FUTURE-01)
</user_constraints>

---

## Summary

Phase 12 already delivered the complete l10n pipeline: `app_en.arb` (79 keys), `context.l10n` extension, `flutter gen-l10n` wired, `AppLocalizations` generated for all 4 locales. The generated `app_localizations_it.dart` (and es/fr equivalents) currently serve the English fallback strings verbatim because the translation ARB stubs (`app_it.arb`, `app_fr.arb`, `app_es.arb`) contain only `@@locale`.

Phase 13 has three distinct tasks:

1. **Enum refactor** (L10N-04): `hydration_calculator_screen.dart` currently uses Italian string literals (`'Maschio'`, `'Femmina'`, `'Altro'`) as both display labels and map keys in `_sexFactors`. On any non-Italian device locale, the map lookup crashes. Refactor to `BiologicalSex` / `ClimateLevel` enums before touching any display strings.

2. **Widget replacement** (L10N-05): 7 source files have hardcoded strings. All existing strings match keys already defined in `app_en.arb`. The generated `AppLocalizations` class is already live. Widget replacement is mechanical: remove `const`, add `context.l10n.keyName` (or parameterized `.methodName(args)`).

3. **Translation content** (L10N-06): Fill `app_it.arb`, `app_fr.arb`, `app_es.arb` with all 79 keys. Section 3 of this document contains the ready-to-paste translation content for all three locales.

**Primary recommendation:** Implement in dependency order — enum refactor first, widget replacement second, translation ARB fill third. Never swap steps 1 and 2 (replacing display strings before decoupling them from the map causes the crash).

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| ARB translation content | — (static files) | — | No runtime tier; static JSON consumed by gen-l10n at build time |
| Enum refactor (BiologicalSex/ClimateLevel) | Domain layer | — | Enums are domain concepts, not UI concepts; placed in `lib/domain/entities/` |
| Widget string replacement | Presentation layer | — | `context.l10n` calls live where `BuildContext` is available: in `build()` methods |
| `_monthName()` replacement | Presentation layer | intl package | `DateFormat.MMMM(locale).format(date)` is a presentation-time operation using the locale from `Localizations.localeOf(context)` |
| Semantic labels | Presentation layer | — | `Semantics.label` set inside `_buildDayCell()` in `history_screen.dart` |

---

## Section 1: Enum Refactor Analysis (L10N-04)

### Current Code Structure (verified by reading source)

**File:** `lib/presentation/screens/hydration_calculator_screen.dart`

Lines 22–34:
```dart
String? _selectedSex;          // holds Italian display string: 'Maschio' | 'Femmina' | 'Altro'
double _climateValue = 1;      // holds slider index: 0.0–4.0

static const _sexFactors = {
  'Maschio': 35.0,
  'Femmina': 31.0,
  'Altro': 33.0,
};

static const _climateMultipliers = [1.0, 1.05, 1.1, 1.2, 1.3];
static const _climateLabels = ['Freddo', 'Mite', 'Caldo', 'Molto caldo', 'Afoso'];
```

**Crash path confirmed:** Line 56: `final sexFactor = _sexFactors[_selectedSex!]!;`
When device locale is English, the `SegmentedButton` value changes to the localized label (`'Male'` etc.), but `_sexFactors['Male']` returns `null`. The `!` throws `Null check operator used on a null value`.

**`_climateLabels` is index-based** (slider value → array index) so it does not crash, but the Italian strings still appear in the Slider's `semanticFormatterCallback` and the display `Text` widget. No crash, but wrong language.

### Where to Place the Enums

**Decision (Claude's discretion):** Create `lib/domain/entities/hydration_enums.dart`.

**Rationale:**
- The domain layer already holds all entities (`user_settings_entity.dart`, `drink_preset_entity.dart`, `water_entry_entity.dart`, `target_history_entry.dart`). These are all in `lib/domain/entities/`.
- `BiologicalSex` and `ClimateLevel` are domain concepts (input factors for a hydration calculation), not UI concepts. They belong in the domain layer.
- Placing them in the screen file (`hydration_calculator_screen.dart`) would make them private to that file, preventing future reuse if the calculation logic is ever extracted to a service.
- No Freezed needed: plain Dart enums are sufficient. No `.g.dart` generation required.
- No `build_runner` rebuild needed after adding the file.

**New file:** `lib/domain/entities/hydration_enums.dart`
```dart
/// Biological sex options for the hydration recommendation calculator.
/// These are stable identifiers used as map keys — never use display strings as keys.
enum BiologicalSex { male, female, other }

/// Climate level options for the hydration recommendation calculator.
/// Index 0=Cold, 1=Mild, 2=Warm, 3=VeryWarm, 4=Humid — matches _climateMultipliers order.
enum ClimateLevel { cold, mild, warm, veryWarm, humid }
```

### Refactor Approach

**Step 1: Add `hydration_enums.dart`** with the two enums above.

**Step 2: Refactor `hydration_calculator_screen.dart`** — change state, map, and computation:

```dart
// State (was: String? _selectedSex)
BiologicalSex? _selectedSex;

// Map (was: Map<String, double> _sexFactors)
static const _sexFactors = {
  BiologicalSex.male: 35.0,
  BiologicalSex.female: 31.0,
  BiologicalSex.other: 33.0,
};

// Multipliers remain index-based (unchanged)
static const _climateMultipliers = [1.0, 1.05, 1.1, 1.2, 1.3];
// ClimateLevel enum values correspond by index to ClimateLevel.values
```

**Step 3: Refactor `_computeRecommendation()`** — no logic change, just type change:

```dart
int? _computeRecommendation() {
  if (_selectedSex == null) return null;
  final weight = int.tryParse(_weightController.text);
  if (weight == null || weight <= 0 || weight > 300) return null;
  final sexFactor = _sexFactors[_selectedSex!]!;     // BiologicalSex key, never null
  final climateMultiplier = _climateMultipliers[_climateValue.round()];
  final raw = weight * sexFactor * climateMultiplier;
  final rounded = (raw / 50).round() * 50;
  return rounded.clamp(1000, 4000);
}
```

**Step 4: Replace display widgets** — change `SegmentedButton<String>` to `SegmentedButton<BiologicalSex>` and add a helper for climate labels:

```dart
// SegmentedButton typed to BiologicalSex enum
SegmentedButton<BiologicalSex>(
  emptySelectionAllowed: true,
  multiSelectionEnabled: false,
  segments: [
    ButtonSegment(value: BiologicalSex.male,   label: Text(context.l10n.sexMale)),
    ButtonSegment(value: BiologicalSex.female, label: Text(context.l10n.sexFemale)),
    ButtonSegment(value: BiologicalSex.other,  label: Text(context.l10n.sexOther)),
  ],
  selected: _selectedSex != null ? {_selectedSex!} : {},
  onSelectionChanged: (sel) => setState(() => _selectedSex = sel.firstOrNull),
),

// Climate display helper (replaces _climateLabels array)
List<String> _climateDisplayLabels(BuildContext context) => [
  context.l10n.climateCold,
  context.l10n.climateMild,
  context.l10n.climateWarm,
  context.l10n.climateVeryWarm,
  context.l10n.climateHumid,
];
```

**Critical safety rule:** `_climateLabels` is removed entirely. Replace every use of `_climateLabels[x]` with `_climateDisplayLabels(context)[x]`. The `semanticFormatterCallback` on the Slider also needs this — it receives a `double v` and must call `_climateDisplayLabels(context)[v.round()]`. Since `semanticFormatterCallback` in Flutter's `Slider` receives only a `double value` and must return a `String`, and it is a callback that does NOT receive `BuildContext`, capture the labels list before the Slider widget build:

```dart
final climateLabels = _climateDisplayLabels(context);
// Then inside Slider:
semanticFormatterCallback: (v) => climateLabels[v.round()],
```

**Import to add to calculator screen:**
```dart
import '../../domain/entities/hydration_enums.dart';
import '../../l10n/l10n_extensions.dart';
import '../../l10n/generated/app_localizations.dart';
```

### What Must NOT Change

- `_climateMultipliers` stays as a constant list indexed by `_climateValue.round()`. The calculation is index-based, not enum-based — this is fine because the multiplier ordering is immutable.
- `_climateValue` stays as `double` (slider value). `ClimateLevel` enum is not needed for the slider state itself; it is only useful if the calculator is refactored to a domain service later.
- The computation formula is unchanged.

---

## Section 2: Widget Replacement Checklist (L10N-05)

### Import Pattern (all 7 files)

All screens already extend `ConsumerWidget` or `ConsumerStatefulWidget`. Add these imports if not already present:

```dart
import 'package:drinky_drinky/l10n/l10n_extensions.dart';
// AppLocalizations is not needed directly if only using context.l10n
```

The `l10n_extensions.dart` already imports `app_localizations.dart`, so `context.l10n.keyName` works without an additional import of `app_localizations.dart` in the screen file.

### 2.1 `lib/core/router/app_router.dart`

**Context availability:** `NavigationDestination.label` is a `String`, set in the builder closure of `StatefulShellRoute.indexedStack`. The builder receives `BuildContext context`, so `context.l10n` is available.

**const removal:** The `NavigationDestination` widgets use `const` — remove `const` from each `NavigationDestination`.

| Current string | ARB key | Dart call |
|----------------|---------|-----------|
| `'Home'` (label) | `tabHome` | `context.l10n.tabHome` |
| `'History'` (label) | `tabHistory` | `context.l10n.tabHistory` |
| `'Settings'` (label) | `tabSettings` | `context.l10n.tabSettings` |

**Result:**
```dart
// Before
const NavigationDestination(
  icon: Icon(Icons.water_drop_outlined),
  selectedIcon: Icon(Icons.water_drop),
  label: 'Home',
),

// After
NavigationDestination(
  icon: const Icon(Icons.water_drop_outlined),
  selectedIcon: const Icon(Icons.water_drop),
  label: context.l10n.tabHome,
),
```

**Note:** The `Icon` widgets remain `const`. Only the `NavigationDestination` wrapper loses `const`.

**Missing key check:** The `const destinations:` list at the `NavigationBar` level must drop `const` too. The `const` on `destinations:` prevents runtime evaluation of `context.l10n`.

### 2.2 `lib/presentation/screens/home_screen.dart`

**Context availability:** `HomeScreen` is `ConsumerStatefulWidget`. `context` is available in `build()` and all helper methods that receive `BuildContext context`. The `_IntakeBottomSheet` is a separate `StatefulWidget` — its `build()` also receives `BuildContext context`.

**`_onQuickAdd` async pattern (safe):** The `context.l10n.mlAdded(amountMl)` call is after `if (!mounted) return;` — correct pattern. Do NOT pre-capture the localized string before the `await`.

| Current string / expression | ARB key | Dart call | File location |
|-----------------------------|---------|-----------|---------------|
| `'Drinky Drinky'` (AppBar) | `appTitle` | `context.l10n.appTitle` | `build()` line 73 |
| `'Add water'` (FAB tooltip) | `addWaterTooltip` | `context.l10n.addWaterTooltip` | `build()` line 75 |
| `'Something went wrong loading your data. Please restart the app.'` | `errorLoadingDataRestart` | `context.l10n.errorLoadingDataRestart` | `build()` error branch |
| `totalMl == target ? 'Goal reached!'` | `goalReached` | `context.l10n.goalReached` | `_buildContent()` line 140 |
| `'${_formatLiters(context, totalMl)} / ${_formatLiters(context, target)} L'` | `currentIntake` | `context.l10n.currentIntake(_formatLiters(context, totalMl), _formatLiters(context, target))` | `_buildContent()` line 140 |
| `"Today's Intake"` | `todaysIntake` | `context.l10n.todaysIntake` | `_buildContent()` line 153 |
| `'+${entry.amountMl} ml'` (list tile trailing) | `presetButtonLabel` | `context.l10n.presetButtonLabel(entry.amountMl)` | ListView `itemBuilder` line 185 |
| `'No drinks logged yet'` | `noDrinksLogged` | `context.l10n.noDrinksLogged` | `_buildEmptyState()` line 201 |
| `'Tap the + button to log your first drink today.'` | `noDrinksLoggedHint` | `context.l10n.noDrinksLoggedHint` | `_buildEmptyState()` line 207 |
| `'+$amountMl ml added'` (SnackBar) | `mlAdded` | `context.l10n.mlAdded(amountMl)` | `_onQuickAdd()` line 240 |
| `'UNDO'` (SnackBar action) | `undo` | `context.l10n.undo` | `_onQuickAdd()` line 244 |
| `'+${preset.amountMl} ml'` (bottom sheet button) | `presetButtonLabel` | `context.l10n.presetButtonLabel(preset.amountMl)` | `_IntakeBottomSheet.build()` line 305 |
| `'Custom amount'` (hint) | `customAmountHint` | `context.l10n.customAmountHint` | `_IntakeBottomSheet.build()` line 316 |
| `'Add'` (button) | `addButton` | `context.l10n.addButton` | `_IntakeBottomSheet.build()` line 329 |

**const removal required:**
- `const Text('Something went wrong...')` in error branch
- `const InputDecoration(hintText: 'Custom amount', suffixText: 'ml')` — remove `const`; `suffixText: context.l10n.mlUnit`
- `const Text('Add')` in `FilledButton`

**Note on trailing entry label:** The `'+${entry.amountMl} ml'` on line 185 (list tile trailing) is technically the `presetButtonLabel` pattern but it is a water entry display (not a preset button). The ARB key `presetButtonLabel` with value `"+{amount} ml"` is the correct match. Use it here too.

**Gap check:** No strings in `home_screen.dart` are missing from `app_en.arb`. All 14 strings map to existing keys.

### 2.3 `lib/presentation/screens/settings_screen.dart`

**Context availability:** `SettingsScreen` is `ConsumerStatefulWidget`. All `_buildBody`, `_dailyGoalCard`, `_presetsCard`, `_notificationsCard` helpers receive `BuildContext context`.

**`showTimePicker`:** Already receives `context: context` — the time picker dialog itself is localized through `GlobalMaterialLocalizations.delegate` (already wired in Phase 12). No string replacement needed for the picker itself.

| Current string / expression | ARB key | Dart call |
|-----------------------------|---------|-----------|
| `'Settings'` (AppBar) | `settingsTitle` | `context.l10n.settingsTitle` |
| `'Something went wrong loading your data.'` (error) | `errorLoadingData` | `context.l10n.errorLoadingData` |
| `'DAILY GOAL'` (section) | `sectionDailyGoal` | `context.l10n.sectionDailyGoal` |
| `'QUICK-ADD PRESETS'` (section) | `sectionQuickAddPresets` | `context.l10n.sectionQuickAddPresets` |
| `'NOTIFICATIONS'` (section) | `sectionNotifications` | `context.l10n.sectionNotifications` |
| `'HYDRATION'` (section) | `sectionHydration` | `context.l10n.sectionHydration` |
| `'${currentTarget.toInt()} ml'` (slider label) | `amountMl` | `context.l10n.amountMl(currentTarget.toInt())` |
| `'Applica da domani'` (switch title) | `applyFromTomorrow` | `context.l10n.applyFromTomorrow` |
| `'Le modifiche al target entrano in vigore domani'` | `applyFromTomorrowSubtitle` | `context.l10n.applyFromTomorrowSubtitle` |
| `'Le modifiche al target entrano in vigore oggi'` | `applyFromTodaySubtitle` | `context.l10n.applyFromTodaySubtitle` |
| `'Preset ${preset.sortOrder + 1}'` | `presetTitle` | `context.l10n.presetTitle(preset.sortOrder + 1)` |
| `'${preset.amountMl} ml'` (subtitle) | `amountMl` | `context.l10n.amountMl(preset.amountMl)` |
| `'Ricalcola raccomandazione idratazione'` | `recalculateHydration` | `context.l10n.recalculateHydration` |
| `'Notifications are disabled. Tap to open system Settings.'` | `notificationsDisabledBanner` | `context.l10n.notificationsDisabledBanner` |
| `'Open'` (button) | `openButton` | `context.l10n.openButton` |
| `'${currentInterval.toInt()} min'` (slider label) | `intervalMinutes` | `context.l10n.intervalMinutes(currentInterval.toInt())` |
| `'Do Not Disturb'` (switch title) | `doNotDisturb` | `context.l10n.doNotDisturb` |
| `settings.dndEnabled ? 'On' : 'Off'` | `toggleOn` / `toggleOff` | `settings.dndEnabled ? context.l10n.toggleOn : context.l10n.toggleOff` |
| `'Start time'` | `startTime` | `context.l10n.startTime` |
| `'End time'` | `endTime` | `context.l10n.endTime` |

**const removal required:**
- `const Text('Settings')` in AppBar
- `const Text('Applica da domani')` in `SwitchListTile.title`
- `const Text('Ricalcola raccomandazione idratazione')` in `ListTile.title`
- `const Text('Do Not Disturb')` in `SwitchListTile.title`
- `const Text('Start time')` and `const Text('End time')` in `ListTile.title`

**Gap check:** The `_sectionLabel` helper takes a `String text` — change callers to pass `context.l10n.sectionDailyGoal` etc. The helper signature and body do not change.

### 2.4 `lib/presentation/screens/history_screen.dart`

**Context availability:** `HistoryScreen` is `ConsumerStatefulWidget`. `_buildDayCell()` and `_buildDaySummary()` receive `BuildContext context`. The semantic labels in `_buildDayCell()` are set before the `return Semantics(...)`.

**`_monthName()` removal:** The global `String _monthName(int month)` function (lines 16–33) must be deleted. Replace its 3 call sites:

| Call site | Replacement |
|-----------|-------------|
| `_monthName(day.month)` in `_buildDayCell()` semantic label (line 367–371) | `DateFormat.MMMM(Localizations.localeOf(context).toString()).format(day)` |
| `_monthName(day.month)` in `_buildDaySummary()` dateLabel (line 407) | `DateFormat.MMMM(Localizations.localeOf(context).toString()).format(day)` |

**Required import:** `import 'package:intl/intl.dart';` (already present in the file).

**Note on `initializeDateFormatting()`:** Phase 12 was responsible for calling `initializeDateFormatting()` in `main()`. Verify it is present before implementing this replacement. If it is missing, add it in Plan 1, Wave 0.

| Current string / expression | ARB key | Dart call |
|-----------------------------|---------|-----------|
| `'History'` (AppBar — 3 instances: loading, empty, data) | `historyTitle` | `context.l10n.historyTitle` |
| `'Something went wrong loading your data.'` (error) | `errorLoadingData` | `context.l10n.errorLoadingData` |
| `'No history yet'` | `noHistoryYet` | `context.l10n.noHistoryYet` |
| `'Start logging water on the Home tab to see your history here.'` | `noHistoryYetHint` | `context.l10n.noHistoryYetHint` |
| `'$streak'` + `' day streak'` (two separate Text widgets) | `dayStreak` | Merge into single `Text(context.l10n.dayStreak(streak))` — see note |
| Semantic: `'${_monthName(...)} ${day.day}: goal met'` | `calendarDayGoalMet` | `context.l10n.calendarDayGoalMet(DateFormat.MMMM(locale).format(day), day.day)` |
| Semantic: `'${_monthName(...)} ${day.day}: goal not met'` | `calendarDayGoalNotMet` | `context.l10n.calendarDayGoalNotMet(DateFormat.MMMM(locale).format(day), day.day)` |
| Semantic: `'${_monthName(...)} ${day.day}'` | `calendarDay` | `context.l10n.calendarDay(DateFormat.MMMM(locale).format(day), day.day)` |
| `'$dateLabel -- $total of $dailyTarget ml'` | `daySummaryWithEntries` | `context.l10n.daySummaryWithEntries(dateLabel, total!, dailyTarget)` |
| `'$dateLabel -- No entries'` | `daySummaryNoEntries` | `context.l10n.daySummaryNoEntries(dateLabel)` |

**Streak display refactor:** Currently the streak is displayed as two separate `Text` widgets — `Text('$streak')` and `Text(' day streak')`. Merge them into a single `Text(context.l10n.dayStreak(streak))`. The `Row` that contains them should keep only one `Text` widget. The fire icon and spacing remain.

**`dateLabel` construction:** Currently `'${_monthName(day.month)} ${day.day}, ${day.year}'` — replace with:
```dart
final locale = Localizations.localeOf(context).toString();
final dateLabel = '${DateFormat.MMMM(locale).format(day)} ${day.day}, ${day.year}';
```
The `daySummaryWithEntries` and `daySummaryNoEntries` ARB keys accept `date` as a pre-formatted `String`, so pass `dateLabel` directly.

**const removal required:**
- `const Text('History')` in all 3 AppBar instances
- `const Center(child: CircularProgressIndicator())` — safe to remain const (no l10n inside)
- `const SizedBox.shrink(key: ValueKey('empty'))` — safe to remain const

### 2.5 `lib/presentation/screens/permission_screen.dart`

**Context availability:** `PermissionScreen` is `ConsumerStatefulWidget`. The SnackBar in `_onEnableReminders()` is shown after `if (!mounted) return;` — correct.

| Current string / expression | ARB key | Dart call |
|-----------------------------|---------|-----------|
| `'Stay hydrated with reminders'` | `permissionTitle` | `context.l10n.permissionTitle` |
| `'Drinky Drinky sends you gentle reminders to drink water throughout the day.'` | `permissionBody` | `context.l10n.permissionBody` |
| `'Enable Reminders'` (button) | `enableReminders` | `context.l10n.enableReminders` |
| `'Skip for now'` (button) | `skipForNow` | `context.l10n.skipForNow` |
| `granted ? 'Reminders enabled!...' : 'No problem...'` | `remindersEnabled` / `remindersDeclined` | `granted ? context.l10n.remindersEnabled : context.l10n.remindersDeclined` |

**const removal required:**
- `const Text('Enable Reminders')` in `FilledButton`
- `const Text('Skip for now')` in `TextButton`

**No gaps:** All 5 surface-level strings map to existing ARB keys.

### 2.6 `lib/presentation/widgets/preset_edit_dialog.dart`

**Context availability:** `_PresetEditDialog` is a `StatefulWidget`. Its `build()` receives `BuildContext context`. The dialog is shown via `showDialog` — the `dialogContext` in the builder IS below MaterialApp.

**Important:** `showPresetEditDialog` passes `dialogContext` (not `context`) to `_PresetEditDialog`. The `_PresetEditDialog.build()` uses its own `BuildContext context` parameter — `context.l10n` works correctly inside `build()`.

| Current string / expression | ARB key | Dart call |
|-----------------------------|---------|-----------|
| `'Edit Preset ${widget.preset.sortOrder + 1}'` (dialog title) | `editPresetTitle` | `context.l10n.editPresetTitle(widget.preset.sortOrder + 1)` |
| `'Amount (ml)'` (field label) | `amountInputLabel` | `context.l10n.amountInputLabel` |
| `'ml'` (suffix) | `mlUnit` | `context.l10n.mlUnit` |
| `'Enter a value between 50 and 2000'` (error) | `presetValidationError` | `context.l10n.presetValidationError` |
| `'Cancel'` (button) | `cancelButton` | `context.l10n.cancelButton` |
| `'Confirm'` (button) | `confirmButton` | `context.l10n.confirmButton` |

**const removal required:**
- `const Text('Cancel')` in `TextButton`
- `const Text('Confirm')` in `FilledButton`

### 2.7 `lib/presentation/screens/hydration_calculator_screen.dart`

After the enum refactor (Section 1), perform widget string replacement:

| Current string / expression | ARB key | Dart call |
|-----------------------------|---------|-----------|
| `'Calcolatore idratazione'` (AppBar) | `calculatorTitle` | `context.l10n.calculatorTitle` |
| `'Sesso'` (section label) | `sexLabel` | `context.l10n.sexLabel` |
| `'Maschio'` (segment value → after refactor: `BiologicalSex.male`) | `sexMale` | `context.l10n.sexMale` (in `ButtonSegment.label`) |
| `'Femmina'` (segment → `BiologicalSex.female`) | `sexFemale` | `context.l10n.sexFemale` |
| `'Altro'` (segment → `BiologicalSex.other`) | `sexOther` | `context.l10n.sexOther` |
| `'Peso'` (section label) | `weightLabel` | `context.l10n.weightLabel` |
| `'Peso (kg)'` (field label) | `weightInputLabel` | `context.l10n.weightInputLabel` |
| `'kg'` (suffix) | `weightUnit` | `context.l10n.weightUnit` |
| `'Inserisci un peso tra 1 e 300 kg'` (validation) | `weightValidationError` | `context.l10n.weightValidationError` |
| `'Clima'` (section label) | `climateLabel` | `context.l10n.climateLabel` |
| `_climateLabels[_climateValue.round()]` (slider display) | (see enum refactor) | `_climateDisplayLabels(context)[_climateValue.round()]` |
| `_climateLabels[v.round()]` (semantic callback) | (see enum refactor) | pre-captured `climateLabels[v.round()]` |
| `'La tua raccomandazione'` | `yourRecommendation` | `context.l10n.yourRecommendation` |
| `'Compila tutti i campi'` | `fillAllFields` | `context.l10n.fillAllFields` |
| `"I tuoi dati (sesso, peso, clima)..."` (privacy) | `privacyDisclaimer` | `context.l10n.privacyDisclaimer` |
| `'Usa come target'` (button) | `useAsTarget` | `context.l10n.useAsTarget` |
| `'Salta'` (button, onboarding) | `skipButton` | `context.l10n.skipButton` |
| `'Errore durante l\'aggiornamento del target. Riprova.'` (SnackBar error) | `targetUpdateError` | `context.l10n.targetUpdateError` |
| `'Target aggiornato a ${_formatMl(context, recommendedMl)}'` (SnackBar success) | `targetUpdated` | `context.l10n.targetUpdated(_formatMl(context, recommendedMl))` |

**const removal required:**
- `const Text('Calcolatore idratazione')` in AppBar title
- `const Text('Usa come target')` in `FilledButton`
- `const Text('Salta')` in `TextButton`

**SnackBar async safety:** `_onUseAsTarget` is async. The error SnackBar is shown after `if (!mounted) return;`. The success SnackBar is also after `if (!mounted) return;`. Both `context.l10n.targetUpdateError` and `context.l10n.targetUpdated(...)` can be resolved directly in those lines — no pre-capture needed.

### 2.8 String Gap Analysis

**Strings in source files NOT in app_en.arb:**

After cross-referencing all 7 source files against the 79 ARB keys, the following items are confirmed gaps or exclusions:

| Item | Location | Status | Reason |
|------|----------|--------|--------|
| Time formatting strings (`'PM'`, `'AM'`) | `settings_screen.dart _formatTime()` | Exclude | System-level formatting; correct approach is to use `MediaQuery.alwaysUse24HourFormatOf(context)` and number formatting. These are not user-facing translated strings — they are format placeholders. |
| `'drinky_permissionScreenShown'` / `'drinky_calculatorShown'` | Various `SharedPreferences` keys | Exclude | These are not user-visible strings; they are storage keys. |
| `'Month'` in `availableCalendarFormats: const {CalendarFormat.month: 'Month'}` | `history_screen.dart` | Exclude per Phase 12 (D-06) | `table_calendar` uses its own locale-aware format labels when `locale` is set. The map key `'Month'` is never shown when `availableCalendarFormats` has only one entry and `formatButtonVisible: false`. |
| `'+${entry.amountMl} ml'` (list tile trailing) | `home_screen.dart` line 185 | Covered | Use `presetButtonLabel` ARB key — value is `"+{amount} ml"` which matches exactly. |

**No missing ARB keys found.** All user-visible strings in the 7 source files map to existing keys in `app_en.arb`.

---

## Section 3: Complete Translation Content (L10N-06)

All 79 keys × 3 languages. Ready to paste into ARB files.

**Rules applied:**
- D-01/02/03: tu/tu/tú informal throughout
- D-04: `dayStreak` ICU plural as specified
- `daySummaryNoEntries`: French uses "Aucune entrée" (informal), Italian "Nessun dato", Spanish "Sin datos"
- Section labels (`sectionDailyGoal`, etc.) are kept in uppercase as they appear as visual section headers
- `appTitle`, `mlUnit`, `weightUnit` are language-invariant (brand name / universal units)
- `amountMl`, `intervalMinutes`, `presetButtonLabel` — only the numeric placeholder changes; `ml` and `min` are internationally understood in wellness apps but translated per locale convention

### 3.1 app_it.arb (Italian)

```json
{
  "@@locale": "it",

  "tabHome": "Home",
  "tabHistory": "Cronologia",
  "tabSettings": "Impostazioni",

  "appTitle": "Drinky Drinky",

  "goalReached": "Obiettivo raggiunto!",

  "currentIntake": "{current} / {target} L",

  "todaysIntake": "Assunzione di oggi",

  "noDrinksLogged": "Nessuna bevanda registrata",
  "noDrinksLoggedHint": "Tocca il pulsante + per registrare la tua prima bevanda di oggi.",

  "mlAdded": "+{amount} ml aggiunti",

  "undo": "ANNULLA",

  "addWaterTooltip": "Aggiungi acqua",

  "presetButtonLabel": "+{amount} ml",

  "customAmountHint": "Quantità personalizzata",

  "addButton": "Aggiungi",

  "errorLoadingDataRestart": "Qualcosa è andato storto durante il caricamento dei dati. Riavvia l'app.",

  "settingsTitle": "Impostazioni",

  "sectionDailyGoal": "OBIETTIVO GIORNALIERO",
  "sectionQuickAddPresets": "PRESET DI AGGIUNTA RAPIDA",
  "sectionNotifications": "NOTIFICHE",
  "sectionHydration": "IDRATAZIONE",

  "recalculateHydration": "Ricalcola la raccomandazione di idratazione",

  "applyFromTomorrow": "Applica da domani",
  "applyFromTomorrowSubtitle": "Le modifiche all'obiettivo entreranno in vigore domani",
  "applyFromTodaySubtitle": "Le modifiche all'obiettivo entreranno in vigore oggi",

  "presetTitle": "Preset {number}",
  "amountMl": "{amount} ml",

  "notificationsDisabledBanner": "Le notifiche sono disabilitate. Tocca per aprire le impostazioni di sistema.",
  "openButton": "Apri",

  "intervalMinutes": "{minutes} min",

  "doNotDisturb": "Non disturbare",
  "toggleOn": "Attivo",
  "toggleOff": "Non attivo",

  "startTime": "Ora di inizio",
  "endTime": "Ora di fine",

  "errorLoadingData": "Qualcosa è andato storto durante il caricamento dei dati.",

  "historyTitle": "Cronologia",

  "noHistoryYet": "Nessuna cronologia",
  "noHistoryYetHint": "Inizia a registrare l'acqua nella scheda Home per vedere la tua cronologia qui.",

  "dayStreak": "{count, plural, =0{Nessuna serie} =1{1 giorno consecutivo} other{{count} giorni consecutivi}}",

  "daySummaryWithEntries": "{date} -- {total} di {target} ml",
  "daySummaryNoEntries": "{date} -- Nessun dato",

  "calendarDayGoalMet": "{month} {day}: obiettivo raggiunto",
  "calendarDayGoalNotMet": "{month} {day}: obiettivo non raggiunto",
  "calendarDay": "{month} {day}",

  "calculatorTitle": "Calcolatore di idratazione",

  "sexLabel": "Sesso",
  "sexMale": "Maschio",
  "sexFemale": "Femmina",
  "sexOther": "Altro",

  "weightLabel": "Peso",
  "weightInputLabel": "Peso (kg)",
  "weightUnit": "kg",
  "weightValidationError": "Inserisci un peso tra 1 e 300 kg",

  "climateLabel": "Clima",
  "climateCold": "Freddo",
  "climateMild": "Mite",
  "climateWarm": "Caldo",
  "climateVeryWarm": "Molto caldo",
  "climateHumid": "Afoso",

  "yourRecommendation": "La tua raccomandazione",
  "fillAllFields": "Compila tutti i campi",
  "privacyDisclaimer": "I tuoi dati (sesso, peso, clima) non vengono salvati né trasmessi. Il calcolo avviene interamente sul tuo dispositivo.",
  "useAsTarget": "Usa come obiettivo",
  "skipButton": "Salta",
  "targetUpdateError": "Errore durante l'aggiornamento dell'obiettivo. Riprova.",
  "targetUpdated": "Obiettivo aggiornato a {amount}",

  "permissionTitle": "Rimani idratato con i promemoria",
  "permissionBody": "Drinky Drinky ti invia gentili promemoria per bere acqua durante la giornata.",
  "enableReminders": "Abilita promemoria",
  "skipForNow": "Salta per ora",
  "remindersEnabled": "Promemoria abilitati! Puoi regolarli in qualsiasi momento nelle Impostazioni.",
  "remindersDeclined": "Nessun problema -- puoi abilitare i promemoria in seguito nelle impostazioni del dispositivo.",

  "editPresetTitle": "Modifica preset {number}",
  "amountInputLabel": "Quantità (ml)",
  "presetValidationError": "Inserisci un valore tra 50 e 2000",
  "cancelButton": "Annulla",
  "confirmButton": "Conferma",

  "mlUnit": "ml"
}
```

### 3.2 app_fr.arb (French)

**French plural note:** `dayStreak` uses `=0{...} =1{...} other{...}` explicit selectors. The `=0` and `=1` forms override CLDR's category rules (which would treat 0 and 1 as `one` in French). This matches the established pattern in `app_en.arb` and the D-04 decision.

```json
{
  "@@locale": "fr",

  "tabHome": "Accueil",
  "tabHistory": "Historique",
  "tabSettings": "Paramètres",

  "appTitle": "Drinky Drinky",

  "goalReached": "Objectif atteint !",

  "currentIntake": "{current} / {target} L",

  "todaysIntake": "Consommation du jour",

  "noDrinksLogged": "Aucune boisson enregistrée",
  "noDrinksLoggedHint": "Appuie sur le bouton + pour enregistrer ta première boisson aujourd'hui.",

  "mlAdded": "+{amount} ml ajoutés",

  "undo": "ANNULER",

  "addWaterTooltip": "Ajouter de l'eau",

  "presetButtonLabel": "+{amount} ml",

  "customAmountHint": "Quantité personnalisée",

  "addButton": "Ajouter",

  "errorLoadingDataRestart": "Une erreur s'est produite lors du chargement des données. Redémarre l'application.",

  "settingsTitle": "Paramètres",

  "sectionDailyGoal": "OBJECTIF QUOTIDIEN",
  "sectionQuickAddPresets": "AJOUTS RAPIDES",
  "sectionNotifications": "NOTIFICATIONS",
  "sectionHydration": "HYDRATATION",

  "recalculateHydration": "Recalculer la recommandation d'hydratation",

  "applyFromTomorrow": "Appliquer à partir de demain",
  "applyFromTomorrowSubtitle": "Les modifications de l'objectif prendront effet demain",
  "applyFromTodaySubtitle": "Les modifications de l'objectif prendront effet aujourd'hui",

  "presetTitle": "Préréglage {number}",
  "amountMl": "{amount} ml",

  "notificationsDisabledBanner": "Les notifications sont désactivées. Appuie pour ouvrir les paramètres système.",
  "openButton": "Ouvrir",

  "intervalMinutes": "{minutes} min",

  "doNotDisturb": "Ne pas déranger",
  "toggleOn": "Activé",
  "toggleOff": "Désactivé",

  "startTime": "Heure de début",
  "endTime": "Heure de fin",

  "errorLoadingData": "Une erreur s'est produite lors du chargement des données.",

  "historyTitle": "Historique",

  "noHistoryYet": "Aucun historique",
  "noHistoryYetHint": "Commence à enregistrer de l'eau dans l'onglet Accueil pour voir ton historique ici.",

  "dayStreak": "{count, plural, =0{Aucune série} =1{1 jour consécutif} other{{count} jours consécutifs}}",

  "daySummaryWithEntries": "{date} -- {total} sur {target} ml",
  "daySummaryNoEntries": "{date} -- Aucune entrée",

  "calendarDayGoalMet": "{month} {day} : objectif atteint",
  "calendarDayGoalNotMet": "{month} {day} : objectif non atteint",
  "calendarDay": "{month} {day}",

  "calculatorTitle": "Calculateur d'hydratation",

  "sexLabel": "Sexe",
  "sexMale": "Homme",
  "sexFemale": "Femme",
  "sexOther": "Autre",

  "weightLabel": "Poids",
  "weightInputLabel": "Poids (kg)",
  "weightUnit": "kg",
  "weightValidationError": "Saisis un poids entre 1 et 300 kg",

  "climateLabel": "Climat",
  "climateCold": "Froid",
  "climateMild": "Doux",
  "climateWarm": "Chaud",
  "climateVeryWarm": "Très chaud",
  "climateHumid": "Humide",

  "yourRecommendation": "Ta recommandation",
  "fillAllFields": "Remplis tous les champs",
  "privacyDisclaimer": "Tes données (sexe, poids, climat) ne sont ni sauvegardées ni transmises. Le calcul s'effectue entièrement sur ton appareil.",
  "useAsTarget": "Utiliser comme objectif",
  "skipButton": "Ignorer",
  "targetUpdateError": "Erreur lors de la mise à jour de l'objectif. Réessaie.",
  "targetUpdated": "Objectif mis à jour à {amount}",

  "permissionTitle": "Reste hydraté avec des rappels",
  "permissionBody": "Drinky Drinky t'envoie de doux rappels pour boire de l'eau tout au long de la journée.",
  "enableReminders": "Activer les rappels",
  "skipForNow": "Ignorer pour l'instant",
  "remindersEnabled": "Rappels activés ! Tu peux les régler à tout moment dans les Paramètres.",
  "remindersDeclined": "Pas de problème -- tu pourras activer les rappels plus tard dans les paramètres de ton appareil.",

  "editPresetTitle": "Modifier le préréglage {number}",
  "amountInputLabel": "Quantité (ml)",
  "presetValidationError": "Saisis une valeur entre 50 et 2000",
  "cancelButton": "Annuler",
  "confirmButton": "Confirmer",

  "mlUnit": "ml"
}
```

### 3.3 app_es.arb (Spanish)

```json
{
  "@@locale": "es",

  "tabHome": "Inicio",
  "tabHistory": "Historial",
  "tabSettings": "Ajustes",

  "appTitle": "Drinky Drinky",

  "goalReached": "¡Meta alcanzada!",

  "currentIntake": "{current} / {target} L",

  "todaysIntake": "Consumo de hoy",

  "noDrinksLogged": "Sin bebidas registradas",
  "noDrinksLoggedHint": "Pulsa el botón + para registrar tu primera bebida de hoy.",

  "mlAdded": "+{amount} ml añadidos",

  "undo": "DESHACER",

  "addWaterTooltip": "Añadir agua",

  "presetButtonLabel": "+{amount} ml",

  "customAmountHint": "Cantidad personalizada",

  "addButton": "Añadir",

  "errorLoadingDataRestart": "Algo ha ido mal al cargar los datos. Reinicia la app.",

  "settingsTitle": "Ajustes",

  "sectionDailyGoal": "META DIARIA",
  "sectionQuickAddPresets": "AÑADIR RÁPIDO",
  "sectionNotifications": "NOTIFICACIONES",
  "sectionHydration": "HIDRATACIÓN",

  "recalculateHydration": "Recalcular la recomendación de hidratación",

  "applyFromTomorrow": "Aplicar desde mañana",
  "applyFromTomorrowSubtitle": "Los cambios de meta entrarán en vigor mañana",
  "applyFromTodaySubtitle": "Los cambios de meta entrarán en vigor hoy",

  "presetTitle": "Preajuste {number}",
  "amountMl": "{amount} ml",

  "notificationsDisabledBanner": "Las notificaciones están desactivadas. Pulsa para abrir los ajustes del sistema.",
  "openButton": "Abrir",

  "intervalMinutes": "{minutes} min",

  "doNotDisturb": "No molestar",
  "toggleOn": "Activo",
  "toggleOff": "Inactivo",

  "startTime": "Hora de inicio",
  "endTime": "Hora de fin",

  "errorLoadingData": "Algo ha ido mal al cargar los datos.",

  "historyTitle": "Historial",

  "noHistoryYet": "Sin historial",
  "noHistoryYetHint": "Empieza a registrar agua en la pestaña Inicio para ver tu historial aquí.",

  "dayStreak": "{count, plural, =0{Sin racha} =1{1 día consecutivo} other{{count} días consecutivos}}",

  "daySummaryWithEntries": "{date} -- {total} de {target} ml",
  "daySummaryNoEntries": "{date} -- Sin registros",

  "calendarDayGoalMet": "{month} {day}: meta alcanzada",
  "calendarDayGoalNotMet": "{month} {day}: meta no alcanzada",
  "calendarDay": "{month} {day}",

  "calculatorTitle": "Calculadora de hidratación",

  "sexLabel": "Sexo",
  "sexMale": "Hombre",
  "sexFemale": "Mujer",
  "sexOther": "Otro",

  "weightLabel": "Peso",
  "weightInputLabel": "Peso (kg)",
  "weightUnit": "kg",
  "weightValidationError": "Introduce un peso entre 1 y 300 kg",

  "climateLabel": "Clima",
  "climateCold": "Frío",
  "climateMild": "Templado",
  "climateWarm": "Cálido",
  "climateVeryWarm": "Muy cálido",
  "climateHumid": "Húmedo",

  "yourRecommendation": "Tu recomendación",
  "fillAllFields": "Rellena todos los campos",
  "privacyDisclaimer": "Tus datos (sexo, peso, clima) no se guardan ni se transmiten. El cálculo se realiza íntegramente en tu dispositivo.",
  "useAsTarget": "Usar como meta",
  "skipButton": "Omitir",
  "targetUpdateError": "Error al actualizar la meta. Inténtalo de nuevo.",
  "targetUpdated": "Meta actualizada a {amount}",

  "permissionTitle": "Mantente hidratado con recordatorios",
  "permissionBody": "Drinky Drinky te envía suaves recordatorios para beber agua a lo largo del día.",
  "enableReminders": "Activar recordatorios",
  "skipForNow": "Omitir por ahora",
  "remindersEnabled": "¡Recordatorios activados! Puedes ajustarlos en cualquier momento en Ajustes.",
  "remindersDeclined": "Sin problema -- puedes activar los recordatorios más tarde en los ajustes de tu dispositivo.",

  "editPresetTitle": "Editar preajuste {number}",
  "amountInputLabel": "Cantidad (ml)",
  "presetValidationError": "Introduce un valor entre 50 y 2000",
  "cancelButton": "Cancelar",
  "confirmButton": "Confirmar",

  "mlUnit": "ml"
}
```

### 3.4 Translation Notes

**Keys that are language-invariant (same value in all locales):**
- `appTitle`: "Drinky Drinky" — brand name
- `mlUnit`: "ml" — internationally standardized unit
- `weightUnit`: "kg" — internationally standardized unit
- `currentIntake`: "{current} / {target} L" — pure numeric format, no words
- `presetButtonLabel`: "+{amount} ml" — no words
- `amountMl`: "{amount} ml" — no words
- `intervalMinutes`: "{minutes} min" — "min" is internationally understood
- `calendarDay`: "{month} {day}" — pure format string

**Keys with idiomatic translation choices:**
- `tabHistory`: IT="Cronologia" (not "Storia" which is narrative history), FR="Historique", ES="Historial"
- `undo`: Capitalized as it is a SnackBar action button — IT="ANNULLA", FR="ANNULER", ES="DESHACER"
- `sectionDailyGoal`: All caps as section labels — preserved in all locales
- `dayStreak`: Uses D-04 decisions exactly
- `daySummaryNoEntries`: IT="Nessun dato", FR="Aucune entrée", ES="Sin registros" — idiomatic "no data / no entries / no records"
- `useAsTarget`: IT="Usa come obiettivo" (not "target" — uses Italian word for goal), FR="Utiliser comme objectif", ES="Usar como meta"
- `skipButton`: IT="Salta", FR="Ignorer", ES="Omitir"
- `sexMale`/`sexFemale`: IT=Maschio/Femmina (biological sex terminology), FR=Homme/Femme, ES=Hombre/Mujer

---

## Section 4: Pitfalls and Special Cases

### Pitfall A: `supportedLocales` order in generated code

**Observed:** `app_localizations.dart` (generated) has `supportedLocales` as `[en, es, fr, it]` (alphabetical order from gen-l10n). Phase 12 specified English must be FIRST as the fallback. The generated `AppLocalizations.supportedLocales` list may not match the intent.

**Fix:** Pass `AppLocalizations.localizationsDelegates` and `AppLocalizations.supportedLocales` directly to `MaterialApp.router`. If the generated order differs from `[en, it, fr, es]`, Flutter's locale resolution still falls back correctly to the FIRST supported locale — which IS `en` in the generated list. No code change needed; the fallback works.

**Verification:** After filling translation ARBs and re-running `flutter gen-l10n`, check that `AppLocalizations.supportedLocales` still lists `en` first (or adjust `supportedLocales:` in `MaterialApp.router` to be explicit: `const [Locale('en'), Locale('it'), Locale('fr'), Locale('es')]`).

### Pitfall B: `const` removal cascade in `_IntakeBottomSheet`

`_IntakeBottomSheet` is a private `StatefulWidget` (not Consumer). Its `build()` receives `BuildContext context`, and `context.l10n` works because the bottom sheet is shown via `showModalBottomSheet` which places it below the `MaterialApp` in the widget tree. No action needed — `context.l10n` works here exactly like in screen widgets.

### Pitfall C: `SegmentedButton` type change breaks `_computeRecommendation`

When changing `_selectedSex` from `String?` to `BiologicalSex?`, the `_computeRecommendation()` null check `if (_selectedSex == null) return null;` remains valid (null is still null). The map lookup `_sexFactors[_selectedSex!]!` now uses a `BiologicalSex` key — always a valid key — so the `!` is safe.

### Pitfall D: `Slider.semanticFormatterCallback` cannot receive `BuildContext`

The Slider's `semanticFormatterCallback` signature is `String Function(double value)`. It does not receive `BuildContext`. Solution: pre-capture the climate labels list in `build()` before constructing the Slider widget:

```dart
// In build():
final climateLabels = _climateDisplayLabels(context);  // capture before Slider widget

// In Slider:
semanticFormatterCallback: (v) => climateLabels[v.round()],
```

This is safe because `build()` is called every time the widget rebuilds, so `climateLabels` always reflects the current locale.

### Pitfall E: `initializeDateFormatting()` prerequisite for `DateFormat.MMMM()`

`DateFormat.MMMM('it').format(date)` throws `LocaleDataException` if `initializeDateFormatting()` was not called in `main()`. Verify this call exists before implementing the `_monthName()` replacement:

```bash
grep -n "initializeDateFormatting" lib/main.dart
```

If missing, add as Wave 0 task in Plan 1.

### Pitfall F: Three `AppBar(title: const Text('History'))` instances

`history_screen.dart` has `AppBar(title: const Text('History'))` in three separate `Scaffold` returns (loading state, empty state, main data state). All three must be changed. Missing any one leaves a hardcoded English string visible during loading or empty state.

### Pitfall G: `_IntakeBottomSheet` uses a separate `StatefulWidget` (not Consumer)

`_IntakeBottomSheet` extends `StatefulWidget`, not `ConsumerStatefulWidget`. This is fine — `context.l10n` does not require Riverpod. `context` is `BuildContext`, and the extension `AppLocalizationsX on BuildContext` works on any `BuildContext` that is below `MaterialApp`.

### Pitfall H: French typographic spaces before `:` and `!`

French typography inserts a non-breaking space before `!`, `?`, `:`, and `;`. However, for a mobile app UI targeting casual users, standard ASCII spacing is acceptable and avoids font/encoding issues. The translations above use standard ASCII. If a designer requests typographic correctness, the space before `!` and `:` can be added with a Unicode non-breaking space (` `), but this is out of scope for Phase 13.

### Pitfall I: After filling ARB files, re-run `flutter gen-l10n`

The 3 translation ARB stubs currently contain only `@@locale`. After writing the full translations, `flutter gen-l10n` MUST be re-run to regenerate `app_localizations_it.dart`, `app_localizations_fr.dart`, and `app_localizations_es.dart`. Until then, the app still shows English for all locales.

```bash
/Users/flavio.bizzarri/fvm/versions/3.44.1/bin/flutter gen-l10n
```

### Pitfall J: `dayStreak` streak display refactor is a structural widget change

The current streak display is two `Text` widgets in a `Row`:
```dart
Text('$streak', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
const SizedBox(width: 4),
Text(' day streak', style: theme.textTheme.bodyLarge?.copyWith(...)),
```

After replacement, this becomes ONE `Text` widget:
```dart
Text(context.l10n.dayStreak(streak), style: theme.textTheme.bodyLarge?.copyWith(...)),
```

The `titleLarge` bold style for the number is lost. Decision: use a single `bodyLarge` style for the full string — the translation handles "1 giorno consecutivo" as a complete phrase that cannot be split. If the designer wants the number bold, use `RichText` with `TextSpan`, but that adds significant complexity. For Phase 13, use a single `Text` with `bodyLarge` for the full ICU-formatted string. The fire icon and spacing remain.

**Alternative (if bold number is required):** Keep two separate display elements — display `Text('$streak')` in `titleLarge` bold, and `Text(streak == 1 ? context.l10n.dayStreak(1).replaceFirst('1 ', '') : ...)`. This is fragile and locale-dependent. Recommended: single Text widget with consistent style.

---

## Package Legitimacy Audit

> Phase 13 installs NO new packages. All required packages were installed in Phase 12 (`flutter_localizations`, `intl`). The `hydration_enums.dart` file uses only the Dart standard library.

**No packages to audit.**

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Month name localization | `_monthName()` array with hardcoded English | `DateFormat.MMMM(locale).format(date)` from `intl` | `intl` handles 80+ locales, CLDR-compliant, already a dependency |
| ICU plural rules | Custom "if count == 1 else" logic | ARB `{count, plural, =0{} =1{} other{}}` syntax + gen-l10n | gen-l10n generates correct CLDR-aware plural logic for each locale automatically |
| Locale detection | Manual platform channel | `Localizations.localeOf(context)` | Flutter provides this for free via the localization delegates already wired in Phase 12 |

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| flutter gen-l10n | Plan 2 ARB compilation | ✓ | Flutter 3.44.1 (built-in) | — |
| intl package | `DateFormat.MMMM()` | ✓ | ^0.20.2 (in pubspec.yaml) | — |
| dart:core | Enum declaration | ✓ | Dart 3.x | — |

---

## Security Domain

> `security_enforcement: true`, ASVS level 1.

### Applicable ASVS Categories

| ASVS Category | Applies | Notes |
|---------------|---------|-------|
| V2 Authentication | No | Phase 13 is UI string replacement; no auth changes |
| V3 Session Management | No | No session data involved |
| V4 Access Control | No | No permissions or access control changes |
| V5 Input Validation | Partial | Calculator weight field validation string changes from Italian to localized — validation LOGIC unchanged (1–300 kg) |
| V6 Cryptography | No | No cryptographic operations |
| V10 Malicious Code | No | No external package installs |

### Threat Patterns Relevant to l10n

| Pattern | Risk | Mitigation |
|---------|------|------------|
| ARB injection via translation strings | LOW — ARB strings are static files checked into git, not user input | No user-controlled content enters ARB at runtime |
| `context.l10n` called above MaterialApp | HIGH if violated | All call sites are in screen widgets below MaterialApp — verified by code reading |
| `const` removal creating performance regressions | None for this app scale | Accepted; localized strings cannot be compile-time constants |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `initializeDateFormatting()` was called in `main()` as part of Phase 12 | Section 2.4, Pitfall E | `DateFormat.MMMM()` throws `LocaleDataException` on Italian/French/Spanish device; calendar month names crash |
| A2 | The informal tu/tú/tu tone chosen (D-01/02/03) is appropriate for the target user demographic | Section 3 — all translations | If a formal app is desired, all 2nd-person verb forms and possessive pronouns must be updated in 3 ARB files |
| A3 | "ml" and "min" are acceptable untranslated unit abbreviations in IT/FR/ES wellness apps | Section 3 | If locale-specific units are required (e.g. "mL" in FR), update `mlUnit` and `intervalMinutes` ARB values |

---

## Open Questions

1. **`initializeDateFormatting()` in `main.dart`**
   - What we know: Phase 12 CONTEXT.md lists it as a Phase 12 task. PITFALLS.md confirms it is required.
   - What's unclear: Whether Phase 12 actually added it (implementation not confirmed in this research session).
   - Recommendation: Plan 1, Wave 0 — grep `main.dart` for `initializeDateFormatting`; add it if missing.

2. **Streak card widget structure after merge**
   - What we know: Current two-Text layout cannot be preserved with a single ICU plural string.
   - What's unclear: Designer preference for number styling.
   - Recommendation: Use single `Text(context.l10n.dayStreak(streak))` with `bodyLarge` style. Document the style unification as a deliberate Phase 13 decision.

---

## Sources

### Primary (HIGH confidence)
- Direct code reading: `lib/presentation/screens/hydration_calculator_screen.dart` — current structure of `_sexFactors`, `_climateLabels`, `_selectedSex` state
- Direct code reading: `lib/l10n/app_en.arb` — all 79 keys verified by parsing
- Direct code reading: `lib/l10n/generated/app_localizations.dart` — confirmed method signatures for all parameterized keys
- Direct code reading: `lib/l10n/generated/app_localizations_it.dart` — confirmed current generated code produces English fallback
- Direct code reading: all 7 source files — confirmed every hardcoded string maps to an existing ARB key
- `.planning/phases/13-string-extraction-translation/13-CONTEXT.md` — locked decisions D-01 through D-05
- `.planning/research/PITFALLS.md` — Pitfall 4 (calculator crash), Pitfall 9 (const removal), Pitfall 10 (French plurals), Pitfall 12 (string interpolation)
- `.planning/research/FEATURES.md` — complete string inventory table

### Secondary (MEDIUM confidence)
- CLDR plural rules for IT/FR/ES: explicit `=0` and `=1` selectors override CLDR category system, confirmed safe for all 3 target locales per prior research
- French informal `tu` convention in wellness/health mobile apps — standard practice for apps targeting younger demographics

### Tertiary (LOW confidence — review before publishing)
- Translation quality: Translations are Claude-generated, not reviewed by native speakers. Marked as [ASSUMED] for quality. Functional Italian/French/Spanish, but professional polish may require human review (deferred to L10N-FUTURE-01).

---

## Metadata

**Confidence breakdown:**
- Enum refactor analysis: HIGH — direct code reading of exact lines; no assumptions
- Widget replacement mapping: HIGH — all 79 ARB keys cross-referenced against 7 source files; no gaps found
- Translation content: MEDIUM — Claude-generated; grammatically correct and idiomatic; not native-speaker reviewed
- Pitfalls: HIGH — all based on direct code analysis or prior verified research

**Research date:** 2026-06-15
**Valid until:** 2026-08-15 (ARB format and Flutter gen-l10n are stable; translations valid until human review)
