# Architecture: v1.1 Feature Integration

**Project:** Drinky Drinky
**Researched:** 2026-06-08
**Overall confidence:** HIGH
**Flutter SDK:** 3.44.1 (via FVM)

## Correction: Presets Are in Drift, Not SharedPreferences

The milestone context states "SharedPreferences: stores daily target, DND settings, 4 preset amounts (preset0..preset3)." This is incorrect based on the actual codebase. Presets are stored in the Drift `DrinkPresets` table (rows with `id`, `amountMl`, `sortOrder`), not SharedPreferences. Settings (daily target, DND, interval) are also in the Drift `UserSettings` table. SharedPreferences is used only for the `drinky_permissionScreenShown` flag.

This correction matters for the 4-to-3 preset migration strategy below.

---

## Feature 1: Material You (DynamicColorBuilder)

### The Problem

`lib/main.dart` line 37 hardcodes the theme:
```dart
theme: ThemeData(
  colorSchemeSeed: Colors.blue,
  useMaterial3: true,
),
```

This ignores the device's wallpaper-derived color scheme on Android 12+ and accent color on other platforms.

### Integration Point

`DynamicColorBuilder` from the `dynamic_color` package (v1.8.1) wraps `MaterialApp`. It does NOT replace `ThemeData` -- it provides platform-derived `ColorScheme` values that feed INTO `ThemeData`.

### Where It Goes in the Widget Tree

DynamicColorBuilder wraps `MaterialApp.router` inside the `DrinkyDrinkyApp.build()` method. The ProviderScope stays outside (above) it because ProviderScope has no rendering concern.

**Before:**
```
ProviderScope
  DrinkyDrinkyApp (ConsumerWidget)
    MaterialApp.router(theme: hardcoded)
```

**After:**
```
ProviderScope
  DrinkyDrinkyApp (ConsumerWidget)
    DynamicColorBuilder(builder: (lightDynamic, darkDynamic) =>
      MaterialApp.router(
        theme: ThemeData(colorScheme: lightDynamic ?? fallback),
        darkTheme: ThemeData(colorScheme: darkDynamic ?? darkFallback),
      )
    )
```

### Exact Code Change

```dart
// lib/main.dart - DrinkyDrinkyApp.build()
@override
Widget build(BuildContext context, WidgetRef ref) {
  final router = ref.watch(appRouterProvider);
  return DynamicColorBuilder(
    builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
      return MaterialApp.router(
        title: 'Drinky Drinky',
        theme: ThemeData(
          colorScheme: lightDynamic ?? ColorScheme.fromSeed(
            seedColor: Colors.blue,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: darkDynamic ?? ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        routerConfig: router,
      );
    },
  );
}
```

### Key Details

- `lightDynamic` and `darkDynamic` are nullable. On devices without dynamic color (older Android, iOS without accent), they are null. The fallback uses `ColorScheme.fromSeed(seedColor: Colors.blue)` to match the current hardcoded behavior.
- `useMaterial3: true` is already set. Keep it.
- `colorSchemeSeed: Colors.blue` must be replaced with `colorScheme:` -- you cannot use both `colorScheme` and `colorSchemeSeed` simultaneously (ThemeData asserts against it).
- Adding `darkTheme` enables automatic light/dark switching based on platform brightness. If the user does not want dark mode, omit `darkTheme` and only use `theme`.

### Files Changed

| File | Change |
|------|--------|
| `pubspec.yaml` | Add `dynamic_color: ^1.8.1` to dependencies |
| `lib/main.dart` | Wrap MaterialApp.router in DynamicColorBuilder; replace `colorSchemeSeed` with `colorScheme` |

### No Other Files Affected

All screens already use `Theme.of(context).colorScheme` and `Theme.of(context).textTheme` to read colors. The existing code in HomeScreen (line 119: `final colorScheme = theme.colorScheme;`), HistoryScreen, and SettingsScreen will automatically pick up the new dynamic colors without any changes. This is the benefit of M3 tokenized theming.

The two hardcoded color references that will NOT change (intentionally):
- `Colors.green.shade600` in home_screen.dart (goal-met ring and text) -- semantic, not theme-derived
- `Colors.orange.shade700` in history_screen.dart (streak fire icon) -- semantic, not theme-derived
- `Colors.red.shade600` in history_screen.dart (missed-goal day) -- semantic, not theme-derived

### Confidence: HIGH

Source: pub.dev/packages/dynamic_color (v1.8.1 confirmed), GitHub example `complete_example.dart` confirms the fallback pattern.

---

## Feature 2: FAB + Bottom Sheet (Quick-Add Redesign)

### The Problem

HomeScreen currently has 4 `FilledButton` widgets in a horizontal `Row` (lines 147-162). The v1.1 redesign replaces this with a FloatingActionButton that opens a modal bottom sheet containing 3 preset buttons plus a custom amount text field.

### Integration Points

**A. Remove the quick-add Row**

Delete lines 146-162 (the `Padding` wrapping the `Row` of `FilledButton` widgets and the `SizedBox(height: 24)` spacer above it).

**B. Add FAB to the Scaffold**

The FAB goes on the `Scaffold` in `_HomeScreenState.build()` (line 89). The Scaffold is already returned directly from the `build` method, so adding `floatingActionButton:` is straightforward.

However, there is a subtlety: the HomeScreen's `Scaffold` is INSIDE the router's outer `Scaffold` (which holds the NavigationBar). The FAB belongs on the inner HomeScreen Scaffold because it should only appear on the Home tab, not on History or Settings.

```dart
return Scaffold(
  appBar: AppBar(title: const Text('Drinky Drinky')),
  floatingActionButton: FloatingActionButton(
    onPressed: () => _showAddDrinkSheet(context, presets),
    child: const Icon(Icons.add),
  ),
  body: settingsAsync.when(/* ... */),
);
```

**C. Bottom Sheet Widget**

Create a new file `lib/presentation/widgets/add_drink_sheet.dart`. The sheet is a `StatefulWidget` (not Consumer -- it receives data via constructor parameters and a callback for submission). Alternatively, it can be a `ConsumerWidget` if it needs to call providers directly.

Recommended approach: pass the 3 presets and a callback `onAdd(int amountMl)` as parameters. The HomeScreen calls `_onQuickAdd(amountMl)` from the callback. This keeps the sheet pure and testable.

```dart
void _showAddDrinkSheet(BuildContext context, List<DrinkPresetEntity> presets) {
  showModalBottomSheet(
    context: context,
    builder: (sheetContext) => AddDrinkSheet(
      presets: presets.take(3).toList(), // first 3 only
      onAdd: (amountMl) {
        Navigator.of(sheetContext).pop();
        _onQuickAdd(amountMl);
      },
    ),
  );
}
```

**D. Sheet Layout**

```
[Preset 1: +200 ml]  [Preset 2: +300 ml]  [Preset 3: +400 ml]
[TextField: Enter custom amount (ml)]  [Add button]
```

The custom TextField validates input (same rules as preset edit: 50-2000 ml) and calls the same `onAdd` callback.

**E. Data Flow**

The data flow does NOT change. The sheet submits to `_onQuickAdd(amountMl)` which calls `repo.insertEntry(amountMl, DateTime.now(), capturedKey)` exactly as before. The Riverpod provider graph (`waterRepositoryProvider` -> `totalMlForDateProvider` -> UI) is untouched.

### FAB Visibility Concern

The FAB must NOT show while `settingsAsync` is loading or errored. Move the FAB inside the `settingsAsync.when(data:)` branch, or conditionally set `floatingActionButton` to null when data is not available. Recommended:

```dart
floatingActionButton: settingsAsync.hasValue
    ? FloatingActionButton(
        onPressed: () => _showAddDrinkSheet(context, presets),
        child: const Icon(Icons.add),
      )
    : null,
```

But `presets` is not in scope at the Scaffold level -- it is computed inside `settingsAsync.when(data:)`. The cleanest solution: keep the FAB on the Scaffold and check `presetsAsync.hasValue` separately, since `presetsAsync` is already watched at line 69.

### Files Changed

| File | Change |
|------|--------|
| `lib/presentation/screens/home_screen.dart` | Remove quick-add Row, add FAB, add `_showAddDrinkSheet` method |
| `lib/presentation/widgets/add_drink_sheet.dart` | **NEW** -- bottom sheet with 3 presets + custom field |

### Files NOT Changed

- No provider changes
- No repository changes
- No database changes
- No router changes

### Confidence: HIGH

Standard Flutter pattern; no external dependencies needed.

---

## Feature 3: 4-to-3 Presets

### The Problem

The database seeds 4 presets (200/300/400/500 ml, sortOrder 0-3). The v1.1 design uses only 3 in the bottom sheet. The question is whether to delete preset 4 from the database or simply stop displaying it.

### Recommended Approach: Display-Only Change, No Database Migration

Do NOT delete the 4th preset row from the database. Reasons:
1. Deleting requires a Drift schema migration (schemaVersion 1 -> 2), adding complexity for no user-facing benefit.
2. Existing users may have customized all 4 presets. Deleting one loses their data.
3. The preset row costs negligible storage.

Instead, the UI layer simply takes the first 3 presets:
- `AddDrinkSheet` receives `presets.take(3).toList()` (already shown above).
- `SettingsScreen._presetsCard` filters to `presets.take(3).toList()` to only show 3 editable presets.

### SettingsRepository

No new method needed. The existing `watchPresets()` returns all presets ordered by `sortOrder`. The UI truncates to 3. The existing `updatePreset(id, amountMl)` works for any preset by ID.

### Settings UI

No new screen needed. The existing `_presetsCard` method in `settings_screen.dart` just needs its `presets` parameter filtered:

```dart
// settings_screen.dart, line 51 -- change from:
final presets = presetsAsync.value ?? <DrinkPresetEntity>[];
// to:
final presets = (presetsAsync.value ?? <DrinkPresetEntity>[]).take(3).toList();
```

### Files Changed

| File | Change |
|------|--------|
| `lib/presentation/screens/home_screen.dart` | Pass `presets.take(3)` to the sheet |
| `lib/presentation/screens/settings_screen.dart` | Filter to `presets.take(3)` in the presets card |

### Files NOT Changed

- No Drift migration
- No DAO changes
- No repository changes
- No entity changes

### Confidence: HIGH

Pure UI-layer filtering. No risk.

---

## Feature 4: L-Display (Liter Formatting)

### The Problem

The CircularPercentIndicator center text (line 139) currently shows `$totalMl / $target ml` (e.g., "1500 / 2000 ml"). The v1.1 design wants to show liters with a decimal (e.g., "1.5 / 2.0 L").

### Integration Point

This is a pure formatting change in `_buildContent` in `home_screen.dart`. No provider, repository, or database changes.

### Implementation

Add a formatting helper:
```dart
String _formatMl(int ml) {
  final liters = ml / 1000.0;
  return '${liters.toStringAsFixed(1)} L';
}
```

Replace line 139:
```dart
// Before:
isGoalMet && totalMl == target ? 'Goal reached!' : '$totalMl / $target ml'
// After:
isGoalMet && totalMl == target ? 'Goal reached!' : '${_formatMl(totalMl)} / ${_formatMl(target)}'
```

Also consider:
- The SnackBar text (line 248): `'+$amountMl ml added'` -- keep ml since individual drink amounts (200-500 ml) read more naturally in ml.
- The timeline trailing text (line 202): `'+${entry.amountMl} ml'` -- keep ml for individual entries.
- The history day summary (history_screen.dart line 380): `'$total of $dailyTarget ml'` -- could convert to L for consistency with home, but this is a separate screen and can be deferred.

### Files Changed

| File | Change |
|------|--------|
| `lib/presentation/screens/home_screen.dart` | Add `_formatMl` helper; change center text format |

### Files NOT Changed

Everything else. This is purely cosmetic.

### Confidence: HIGH

No external dependency. String formatting only.

---

## Feature 5: SnackBar Non-Dismiss Fix

### Root Cause

**This is a Flutter 3.38+ breaking change, not an app bug.**

Since Flutter 3.38, `SnackBar` widgets that have an `action` property set now persist indefinitely by default (they do NOT auto-dismiss after the `duration`). This is intentional for Material 3 accessibility -- action SnackBars should persist so users have time to interact.

The app is on Flutter 3.44.1 (via FVM) and has `SnackBar` with a `SnackBarAction(label: 'UNDO')` at line 247-259 of `home_screen.dart`. The `duration: const Duration(seconds: 5)` is being IGNORED because of the new default behavior.

Source: https://docs.flutter.dev/release/breaking-changes/snackbar-with-action-behavior-update

### The Fix

Add `persist: false` to the SnackBar to restore auto-dismiss behavior:

```dart
messenger.showSnackBar(
  SnackBar(
    content: Text('+$amountMl ml added'),
    duration: const Duration(seconds: 5),
    persist: false,  // <-- THIS IS THE FIX
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.all(8),
    action: SnackBarAction(
      label: 'UNDO',
      onPressed: () async {
        await repo.deleteLastEntry(capturedKey);
      },
    ),
  ),
);
```

### What the Fix Is NOT

- It is NOT a `mounted` check issue (the existing `if (!mounted) return;` guard at line 241 is correct and should stay).
- It is NOT a `ScaffoldMessenger` lifecycle issue (the `messenger.clearSnackBars()` call at line 245 is correct and should stay).
- It is NOT a timer or `_onQuickAdd` issue.
- It is NOT related to the `capturedKey` pattern (that pattern is correct for preventing stale date keys across async gaps).

### Other SnackBars to Check

The `PermissionScreen` (line 92-99) also shows a SnackBar but WITHOUT an action, so it auto-dismisses correctly and does not need `persist: false`.

### Files Changed

| File | Change |
|------|--------|
| `lib/presentation/screens/home_screen.dart` | Add `persist: false` to SnackBar (1 line) |

### Confidence: HIGH

Source: official Flutter breaking change documentation at docs.flutter.dev. Verified that app targets Flutter >= 3.38 (3.44.1 via FVM). The `persist` property was introduced in 3.37.0-0.0.pre, stable in 3.38.

---

## Feature 6: App Icon (flutter_launcher_icons)

### Integration Point

`flutter_launcher_icons` (v0.14.4) is already listed in CLAUDE.md as an approved dev dependency but is NOT in `pubspec.yaml` yet. It is a dev-only tool that runs as a code generator to produce platform-specific icon assets.

### Setup

**Step 1: Add to pubspec.yaml dev_dependencies**
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.14.4
```

**Step 2: Add configuration block to pubspec.yaml**
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"
  # Optional: adaptive icon for Android 8+
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"
```

**Step 3: Place source image**
- Create `assets/icon/` directory
- Place a 1024x1024 PNG source image at `assets/icon/app_icon.png`
- For Android adaptive icons, also place a foreground-only image at `assets/icon/app_icon_foreground.png` (should have transparent background with the icon centered in the safe zone -- inner 66% of the canvas)

**Step 4: Run generator**
```bash
dart run flutter_launcher_icons
```

This generates:
- Android: `android/app/src/main/res/mipmap-*` directories with all density variants
- iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset/` with all required sizes

### Files Changed

| File | Change |
|------|--------|
| `pubspec.yaml` | Add `flutter_launcher_icons: ^0.14.4` to dev_dependencies; add config block |
| `assets/icon/app_icon.png` | **NEW** -- 1024x1024 source image |
| `assets/icon/app_icon_foreground.png` | **NEW** (optional) -- adaptive icon foreground |
| `android/app/src/main/res/mipmap-*/` | **GENERATED** -- all density variants |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/` | **GENERATED** -- all sizes |

### Files NOT Changed

- No Dart source code changes
- No runtime behavior changes

### Confidence: HIGH

flutter_launcher_icons 0.14.4 verified on pub.dev. Standard tooling.

---

## Build Order (Phase Sequencing Recommendation)

### Rationale for Ordering

Features have almost no cross-dependencies -- they touch different parts of the codebase with minimal overlap. The primary ordering factors are:

1. **Risk:** Fix the bug first (SnackBar), then do infrastructure (theme), then UI redesign.
2. **File overlap:** FAB/sheet and L-display both touch `home_screen.dart`. Do them in the same phase or sequentially to avoid merge conflicts.
3. **Independence:** App icon is fully independent and can be done at any point.

### Recommended Phases

**Phase 1: Bug Fix + Theme Infrastructure**
- SnackBar `persist: false` fix (1 line, home_screen.dart)
- DynamicColorBuilder + `dynamic_color` package (main.dart + pubspec.yaml)
- L-display formatting (home_screen.dart)

Rationale: All three are small, low-risk, and independent of each other. The SnackBar fix is a one-liner. DynamicColorBuilder touches only main.dart. L-display is formatting-only. Bundling them avoids churning home_screen.dart across multiple phases.

**Phase 2: Quick-Add Redesign**
- Remove the 4-button quick-add Row
- Add FAB to HomeScreen Scaffold
- Create AddDrinkSheet widget (new file)
- Filter presets to 3 in HomeScreen and SettingsScreen

Rationale: This is the largest change (new widget, UI restructure) and should be isolated so it can be tested independently. The preset filtering (4 -> 3) is coupled to this -- the sheet shows 3 presets, so the settings screen should match.

**Phase 3: App Icon**
- Add flutter_launcher_icons config
- Place source image(s)
- Run generator

Rationale: Fully independent. No Dart code changes. Can be done at any point but placed last because it requires a design asset (the icon image) which may not be ready.

### Alternative: 2-Phase Approach

If speed is preferred over granularity:

**Phase 1:** SnackBar fix + DynamicColorBuilder + L-display + 3-preset filter + app icon config
**Phase 2:** FAB + bottom sheet (the only substantial new code)

### File Change Summary Across All Features

| File | Features Touching It |
|------|---------------------|
| `pubspec.yaml` | Dynamic Color, App Icon |
| `lib/main.dart` | Dynamic Color |
| `lib/presentation/screens/home_screen.dart` | FAB/Sheet, L-Display, SnackBar Fix, Preset Filter |
| `lib/presentation/screens/settings_screen.dart` | Preset Filter |
| `lib/presentation/widgets/add_drink_sheet.dart` | FAB/Sheet (NEW) |
| `assets/icon/app_icon.png` | App Icon (NEW) |

### Critical Observation

`home_screen.dart` is touched by 4 of 6 features. Plan carefully to avoid merge conflicts if phases execute in parallel. The recommended 3-phase approach puts the small home_screen.dart changes (SnackBar fix + L-display) into Phase 1 and the structural change (FAB + sheet + remove Row) into Phase 2, so Phase 2 starts with a clean baseline.
