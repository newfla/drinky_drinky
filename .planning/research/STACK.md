# Technology Stack -- v1.1 Polish & UX Update

**Project:** Drinky Drinky (Hydration Tracker)
**Researched:** 2026-06-08
**Scope:** Stack additions/changes for v1.1 features only. Base stack is validated and unchanged.

## New Package Additions

Only **one** new package is needed for all five v1.1 features.

| Package | Version | Purpose | Why |
|---------|---------|---------|-----|
| dynamic_color | ^1.8.1 | Material You wallpaper-based theming on Android 12+ | Published by `material.io` (Google's Material team). Provides `DynamicColorBuilder` widget that extracts the device's wallpaper-derived `ColorScheme` on Android S+. Returns `null` on unsupported platforms (iOS, Android <12), enabling clean fallback to `ColorScheme.fromSeed()`. Apache-2.0 license. |

## No Package Needed -- Feature-by-Feature Analysis

| v1.1 Feature | Package Needed? | Approach |
|--------------|-----------------|----------|
| Material You dynamic color | YES: `dynamic_color ^1.8.1` | Wrap `MaterialApp.router` in `DynamicColorBuilder`; use dynamic `ColorScheme` when available, `ColorScheme.fromSeed(seedColor: Colors.blue)` as fallback |
| Modal bottom sheet (FAB + presets) | NO | `showModalBottomSheet()` is built into Flutter's `material` library. No third-party package required |
| Liter display formatting (2 decimals) | NO | Dart's built-in `toStringAsFixed(2)` on `(totalMl / 1000)` -- e.g., "1.75 L / 2.00 L" |
| SnackBar auto-dismiss fix | NO | One-line fix: add `persist: false` to SnackBar (Flutter 3.38+ breaking change) |
| App icon generation | NO (already approved) | `flutter_launcher_icons ^0.14.4` needs to be added to dev_dependencies and configured |

## pubspec.yaml Changes

### Add to `dependencies`:

```yaml
dependencies:
  # ... existing deps unchanged ...

  # Dynamic Theming (v1.1)
  dynamic_color: ^1.8.1
```

### Add to `dev_dependencies`:

```yaml
dev_dependencies:
  # ... existing deps unchanged ...

  # App Icon Generation (v1.1)
  flutter_launcher_icons: ^0.14.4
```

### New configuration block (root level of pubspec.yaml):

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"
  min_sdk_android: 24
  # Adaptive icon for Android 8+ (API 26+)
  adaptive_icon_background: "#E3F2FD"
  adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"
```

Requires a 1024x1024 PNG source icon at `assets/icon/app_icon.png` and a foreground-only variant for Android adaptive icons.

Run generation with:
```bash
dart run flutter_launcher_icons:generate
```

## Integration Notes

### dynamic_color Integration Pattern

Current `main.dart` theme setup:
```dart
// BEFORE (v1.0)
theme: ThemeData(
  colorSchemeSeed: Colors.blue,
  useMaterial3: true,
),
```

Required change:
```dart
// AFTER (v1.1)
DynamicColorBuilder(
  builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
    return MaterialApp.router(
      title: 'Drinky Drinky',
      theme: ThemeData(
        colorScheme: lightDynamic ?? ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: darkDynamic ?? ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  },
)
```

**Critical:** `colorSchemeSeed` and `colorScheme` cannot be used simultaneously -- ThemeData asserts. Replace `colorSchemeSeed: Colors.blue` with `colorScheme: lightDynamic ?? ColorScheme.fromSeed(seedColor: Colors.blue)`.

Platform behavior:
- **Android 12+ (API 31+):** `lightDynamic` is a full `ColorScheme` derived from wallpaper colors. App adopts user's wallpaper palette automatically.
- **Android <12:** `lightDynamic` is `null`. Falls back to `ColorScheme.fromSeed(seedColor: Colors.blue)` -- same as current behavior.
- **iOS:** `lightDynamic` is `null`. Falls back identically. iOS has no wallpaper-based color API.

### SnackBar Auto-Dismiss Fix (Flutter 3.38 Breaking Change)

**Root cause identified:** Since Flutter 3.38, SnackBars with an `action` property no longer auto-dismiss. The `duration` parameter is ignored when an action is present. This is an intentional Material 3 accessibility change.

Source: https://docs.flutter.dev/release/breaking-changes/snackbar-with-action-behavior-update

**Fix:** Add `persist: false` to the SnackBar to restore the 5-second auto-dismiss:

```dart
SnackBar(
  content: Text('+$amountMl ml added'),
  duration: const Duration(seconds: 5),
  persist: false,  // <-- restores auto-dismiss with action
  behavior: SnackBarBehavior.floating,
  margin: const EdgeInsets.all(8),
  action: SnackBarAction(label: 'UNDO', onPressed: () { ... }),
)
```

The `persist` property was introduced in Flutter 3.37.0-0.0.pre (stable in 3.38). The app uses Flutter 3.44.1 via FVM, so this property is available.

### Liter Display Formatting

Current progress ring center text:
```dart
'$totalMl / $target ml'
```

Change to show liters with 2 decimal places:
```dart
'${(totalMl / 1000).toStringAsFixed(2)} L / ${(target / 1000).toStringAsFixed(2)} L'
// e.g., "1.75 L / 2.00 L" instead of "1750 / 2000 ml"
```

No package needed. Dart's `toStringAsFixed(2)` handles this natively. The `2` gives enough precision for hydration tracking without unnecessary digits.

### Modal Bottom Sheet

Flutter's built-in `showModalBottomSheet()` provides everything needed:
- `isScrollControlled: true` for custom height and keyboard avoidance with TextField
- `showDragHandle: true` for Material 3 drag indicator
- `useSafeArea: true` to respect system UI
- Material 3 styling is automatic when `useMaterial3: true` is set in the theme
- No third-party bottom sheet package is warranted

## Packages to NOT Add for v1.1

| Package | Why Not |
|---------|---------|
| intl | Overkill for a single `toStringAsFixed(2)` call. Add later only if locale-aware number formatting is needed across multiple surfaces |
| modal_bottom_sheet | Flutter's built-in `showModalBottomSheet` covers all v1.1 needs. The `modal_bottom_sheet` package adds iOS-style sheets and nested navigation, neither of which is needed |
| flex_color_scheme | Adds an opinionated theme layer on top of Material 3. `dynamic_color` + `ColorScheme.fromSeed` is the official Google approach and sufficient for this app |
| google_fonts | Already in CLAUDE.md recommendations but not in pubspec. Not needed for v1.1 |

## Dependency Compatibility

| Concern | Status |
|---------|--------|
| dynamic_color + Flutter 3.44.1 | Compatible (tested with 3.44.0 per pub.dev) |
| dynamic_color + Dart >=3.10.0 | Compatible (tested with 3.12.0 per pub.dev) |
| dynamic_color + material_color_utilities | Requires >=0.2.0 <=0.13.0; Flutter SDK bundles a compatible version |
| dynamic_color + Riverpod | No interaction; `DynamicColorBuilder` wraps `MaterialApp`, sits below `ProviderScope` in the widget tree |
| flutter_launcher_icons 0.14.4 | Approved in CLAUDE.md; supports adaptive icons, iOS 18+ dark mode icons |

## Version Confidence Assessment

| Package | Version | Confidence | Verified Via |
|---------|---------|------------|--------------|
| dynamic_color | 1.8.1 | HIGH | pub.dev direct fetch (published Aug 2025, latest as of June 2026), changelog verified, publisher verified as material.io |
| flutter_launcher_icons | 0.14.4 | HIGH | Approved in CLAUDE.md; pub.dev confirms latest (published June 2025) |

## Sources

- pub.dev/packages/dynamic_color (direct fetch, June 2026) -- version 1.8.1 confirmed
- pub.dev/packages/dynamic_color/changelog (direct fetch) -- version history verified
- GitHub material-foundation/flutter-packages/packages/dynamic_color -- README and complete_example.dart
- pub.dev/packages/flutter_launcher_icons (direct fetch) -- version 0.14.4 confirmed
- Flutter breaking changes: https://docs.flutter.dev/release/breaking-changes/snackbar-with-action-behavior-update
- Flutter API docs: ScaffoldMessenger, SnackBar, showModalBottomSheet (direct fetch)
- Dart core library docs: toStringAsFixed -- https://dart.dev/libraries/dart-core
