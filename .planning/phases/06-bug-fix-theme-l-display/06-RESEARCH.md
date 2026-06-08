# Phase 6: Bug Fix + Theme + L-Display - Research

**Researched:** 2026-06-08
**Domain:** Flutter Material 3 theming, locale-aware number formatting, SnackBar behavior
**Confidence:** HIGH

## Summary

Phase 6 delivers three independent changes to the existing Drinky Drinky codebase: (1) a one-line SnackBar bug fix, (2) locale-aware liter display on the home screen progress ring, and (3) Material You dynamic theming with dark mode support and brightness-adaptive semantic colors. No new screens, no navigation changes, no database changes, no provider changes. The changes touch exactly 4 files: `pubspec.yaml`, `lib/main.dart`, `lib/presentation/screens/home_screen.dart`, and `lib/presentation/screens/history_screen.dart`.

The technical risk is low. The SnackBar fix is a single property addition (`persist: false`). The DynamicColorBuilder integration follows a canonical pattern from Google's own `dynamic_color` package with well-defined fallback behavior. The L-display conversion uses `intl.NumberFormat.decimalPatternDigits` for locale-aware formatting. The main pitfall to watch is the `colorScheme` vs `colorSchemeSeed` assertion -- adding `colorScheme:` from DynamicColorBuilder while keeping the existing `colorSchemeSeed: Colors.blue` crashes the app on launch.

**Primary recommendation:** Implement all three changes in a single plan since they touch overlapping files and are all small, low-risk edits. The only new runtime dependency is `dynamic_color ^1.8.1`. The `intl` package is already a transitive dependency and should be promoted to a direct dependency.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** `DynamicColorBuilder` wraps `MaterialApp.router` inside `DrinkyDrinkyApp.build()`, below `ProviderScope`. This is the only widget-tree change needed.
- **D-02:** Replace `colorSchemeSeed: Colors.blue` with `colorScheme: lightDynamic ?? ColorScheme.fromSeed(seedColor: Colors.blue)`. Cannot use both `colorScheme` and `colorSchemeSeed` simultaneously (Flutter assertion error).
- **D-03:** Add `darkTheme: ThemeData(colorScheme: darkDynamic ?? ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark))` to `MaterialApp.router`.
- **D-04:** `themeMode: ThemeMode.system` -- dark mode follows the device setting; no manual toggle.
- **D-05:** Fallback seed color is `Colors.blue` -- unchanged from v1.0, applies on Android <12 and all iOS devices.
- **D-06:** Semantic colors adapt by brightness: Light mode: `Colors.green.shade600`, `Colors.red.shade600`, `Colors.orange.shade700` (current values); Dark mode: `Colors.green.shade400`, `Colors.red.shade400`, `Colors.orange.shade400`. Pattern: `Theme.of(context).brightness == Brightness.dark ? Colors.green.shade400 : Colors.green.shade600`.
- **D-07:** Affected locations: `home_screen.dart` (ring color, label color when goal met -- 2 occurrences) and `history_screen.dart` (calendar day fill + text colors -- 3 occurrences).
- **D-08:** Use `intl.NumberFormat` for locale-aware decimal formatting.
- **D-09:** Ring center text format: `'{current} / {goal} L'` -- unit appears once at the end. Both values converted from ml to liters (`amountMl / 1000`).
- **D-10:** When goal is reached (`totalMl >= target`), keep the current text `'Goal reached!'` -- no change to this branch.
- **D-11:** L-display is home screen only. Settings slider stays in ml. Individual entry items in the timeline stay in ml. SnackBar text stays in ml.
- **D-12:** Add `persist: false` to the `SnackBar(...)` constructor in `home_screen.dart`. This is the complete fix for the Flutter 3.38 breaking change.
- **D-13:** The existing `clearSnackBars()` call before `showSnackBar()`, the `capturedKey` pattern, and the `mounted` check are all correct and should remain unchanged.

### Claude's Discretion

- Exact `intl.NumberFormat` API call -- pick whichever format produces exactly 2 decimal places with the device locale's decimal separator.
- Whether to extract a `_semanticColor(BuildContext, Color light, Color dark)` helper or inline the brightness check -- either is fine.

### Deferred Ideas (OUT OF SCOPE)

None -- discussion stayed within phase scope.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| HOME-01 | User sees goal and current intake on the home screen expressed in liters with locale-aware decimal formatting | `intl.NumberFormat.decimalPatternDigits(locale:, decimalDigits: 2)` provides locale-aware decimal separator; `Localizations.localeOf(context).toString()` for device locale detection |
| HOME-02 | SnackBar undo notification auto-dismisses after 5 seconds and does not persist indefinitely | `persist: false` on SnackBar constructor restores auto-dismiss per Flutter 3.38 breaking change docs |
| THEME-01 | App uses Material You dynamic color on Android 12+, derived from the device wallpaper | `dynamic_color ^1.8.1` package provides `DynamicColorBuilder` widget; `lightDynamic`/`darkDynamic` nullable params |
| THEME-02 | App falls back to a static blue seed palette on Android <12; iOS retains the existing static palette unchanged | `ColorScheme.fromSeed(seedColor: Colors.blue)` as fallback when dynamic params are null |
| THEME-03 | App supports system dark mode; all screens adapt correctly, including semantic colors | `darkTheme:` parameter on MaterialApp + `ThemeMode.system` + brightness-conditional semantic color shades |

</phase_requirements>

## Project Constraints (from CLAUDE.md)

- **Tech stack**: Flutter + Riverpod + Drift -- no deviation
- **Platform**: iOS and Android only
- **Offline-first**: No backend or cloud sync
- **Packages to NOT use**: sqlite3_flutter_libs, awesome_notifications, get/GetX, provider, hive/isar, flutter_native_timezone
- **intl ^0.20.2**: Listed in CLAUDE.md recommended stack for "Date/time formatting" and "locale-aware formatting"
- **dynamic_color**: Not in CLAUDE.md but confirmed in CONTEXT.md as the only new dependency; published by material.io (Google verified publisher)

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Material You dynamic theming | Frontend (main.dart) | -- | Theme configuration is app-level widget tree setup; DynamicColorBuilder wraps MaterialApp |
| Dark mode support | Frontend (main.dart) | -- | `darkTheme` and `themeMode` are MaterialApp properties |
| Semantic color adaptation | Frontend (screens) | -- | Brightness check happens at widget build time using `Theme.of(context)` |
| L-display formatting | Frontend (home_screen) | -- | Pure presentation-layer string formatting; no data model impact |
| SnackBar fix | Frontend (home_screen) | -- | One property addition to an existing SnackBar widget |

## Standard Stack

### Core (New Dependencies for Phase 6)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| dynamic_color | ^1.8.1 | Material You wallpaper-derived ColorScheme on Android 12+ | Published by material.io (Google verified publisher); returns null on unsupported platforms for clean fallback [CITED: pub.dev/packages/dynamic_color] |
| intl | ^0.20.2 | Locale-aware number formatting via `NumberFormat.decimalPatternDigits` | Official Dart team package (dart.dev publisher); already a transitive dependency via table_calendar; needs promotion to direct dependency [CITED: pub.dev/packages/intl] |

### Already Installed (No Changes)

| Library | Version | Purpose | Relevance |
|---------|---------|---------|-----------|
| flutter_riverpod | ^3.3.1 | State management | No changes needed; providers untouched |
| percent_indicator | ^4.2.5 | Circular progress ring | Center text format changes but widget API unchanged |
| table_calendar | ^3.2.0 | Calendar view | Semantic color changes in day cell builder, not calendar API |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `intl.NumberFormat` | `toStringAsFixed(2)` | `toStringAsFixed` always uses `.` as decimal separator; does not respect locale (e.g., Italian uses `,`). User decision D-08 requires locale-aware formatting. |
| `Localizations.localeOf(context)` | `Platform.localeName` | `Localizations.localeOf(context)` respects Flutter's locale resolution and app-level overrides; `Platform.localeName` reads raw OS locale which may differ from what Flutter resolves |
| `DynamicColorBuilder` (widget) | `DynamicColorPlugin.getCorePalette()` (low-level) | DynamicColorBuilder is the recommended high-level API; the plugin is for custom palette manipulation which is unnecessary here |

**Installation:**
```bash
fvm flutter pub add dynamic_color intl
```

**Version verification:**
- `dynamic_color: 1.8.1` -- confirmed on pub.dev, published by material.io, 10 months old [CITED: pub.dev/packages/dynamic_color]
- `intl: 0.20.2` -- confirmed on pub.dev, published by dart.dev, 16 months old, already resolved in pubspec.lock as transitive dep [CITED: pub.dev/packages/intl]

## Package Legitimacy Audit

> slopcheck was unavailable at research time. All packages are tagged `[ASSUMED]` and the planner must gate each install behind a `checkpoint:human-verify` task.

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| dynamic_color | pub.dev | ~3 years | N/A (pub.dev) | github.com/material-foundation/flutter-packages | N/A | Approved -- verified publisher material.io (Google) [ASSUMED] |
| intl | pub.dev | ~10 years | N/A (pub.dev) | github.com/dart-lang/i18n | N/A | Approved -- verified publisher dart.dev (Dart team) [ASSUMED] |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

*slopcheck was unavailable at research time. Both packages are from verified Google/Dart publishers, but per protocol they remain `[ASSUMED]` until the planner confirms.*

## Architecture Patterns

### System Architecture Diagram

```
Device Wallpaper (Android 12+)
         |
         v
  DynamicColorBuilder (extracts ColorScheme)
         |
    lightDynamic / darkDynamic (nullable)
         |
         v
  MaterialApp.router
    theme:     ThemeData(colorScheme: lightDynamic ?? seed fallback)
    darkTheme: ThemeData(colorScheme: darkDynamic ?? dark seed fallback)
    themeMode: ThemeMode.system
         |
         v
  All Screens (inherit via Theme.of(context))
    |         |              |
    v         v              v
  HomeScreen  HistoryScreen  SettingsScreen
  - Ring color: colorScheme.primary (normal) / semantic green (goal met)
  - Ring text: intl.NumberFormat -> L display
  - SnackBar: persist: false
  - Semantic colors: brightness-conditional
```

### Recommended File Changes

```
lib/
  main.dart                         # DynamicColorBuilder wraps MaterialApp.router
  presentation/
    screens/
      home_screen.dart              # SnackBar fix, L-display, semantic colors (2 occ.)
      history_screen.dart           # Semantic colors (3 occ. + streak icon)
pubspec.yaml                        # Add dynamic_color, promote intl
```

### Pattern 1: DynamicColorBuilder Integration

**What:** Wrap MaterialApp.router in DynamicColorBuilder to receive platform-derived ColorScheme values with null fallback.
**When to use:** Any Flutter app wanting Material You dynamic color support.
**Example:**
```dart
// Source: github.com/material-foundation/flutter-packages/dynamic_color/example
import 'package:dynamic_color/dynamic_color.dart';

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
        themeMode: ThemeMode.system,
        routerConfig: router,
      );
    },
  );
}
```

### Pattern 2: Brightness-Adaptive Semantic Colors

**What:** Select between light and dark shade variants based on the active theme brightness.
**When to use:** Any hardcoded Material Colors that need to remain legible on both light and dark surfaces.
**Example:**
```dart
// Source: CONTEXT.md D-06 (user decision)
// Option A: inline check
final goalColor = Theme.of(context).brightness == Brightness.dark
    ? Colors.green.shade400
    : Colors.green.shade600;

// Option B: helper function (Claude's discretion)
Color _semanticColor(BuildContext context, Color light, Color dark) {
  return Theme.of(context).brightness == Brightness.dark ? dark : light;
}
// Usage:
final goalColor = _semanticColor(context, Colors.green.shade600, Colors.green.shade400);
```

### Pattern 3: Locale-Aware Liter Formatting

**What:** Format milliliter integers as liter decimals using the device locale's decimal separator.
**When to use:** Displaying ml values as liters with locale-appropriate formatting.
**Example:**
```dart
// Source: pub.dev/documentation/intl/latest/intl/NumberFormat-class.html
import 'package:intl/intl.dart';

String _formatLiters(BuildContext context, int ml) {
  final locale = Localizations.localeOf(context).toString();
  final formatter = NumberFormat.decimalPatternDigits(
    locale: locale,
    decimalDigits: 2,
  );
  return formatter.format(ml / 1000);
}
// Usage in ring center text:
// '${_formatLiters(context, totalMl)} / ${_formatLiters(context, target)} L'
// Italian device: '1,75 / 2,00 L'
// US device: '1.75 / 2.00 L'
```

### Anti-Patterns to Avoid

- **Using both `colorScheme` and `colorSchemeSeed`:** ThemeData asserts if both are present. Always use one or the other. When migrating to DynamicColorBuilder, remove `colorSchemeSeed` entirely and use `colorScheme` with the null-coalescing fallback. [CITED: Flutter ThemeData source code assertion]
- **Using `toStringAsFixed(2)` for locale-aware display:** It always uses `.` as the decimal separator regardless of locale. Use `intl.NumberFormat` instead when locale-awareness is required. [ASSUMED]
- **Using `Intl.getCurrentLocale()` without initialization:** In Flutter, `Intl.defaultLocale` is not automatically set to the device locale. Use `Localizations.localeOf(context).toString()` inside a widget `build` method to get the correctly resolved locale. [ASSUMED]
- **Relying on transitive dependencies without promoting them:** `intl` is currently transitive via `table_calendar`. If `table_calendar` drops `intl` in a future version, the app build breaks. Promote to a direct dependency. [ASSUMED]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Material You palette extraction | Custom platform channel to read Android wallpaper colors | `dynamic_color` ^1.8.1 `DynamicColorBuilder` | Handles platform detection, null fallback, both light/dark schemes; maintained by Google Material team |
| Locale-aware number formatting | Manual decimal separator detection with `Platform.localeName` and string replacement | `intl` `NumberFormat.decimalPatternDigits` | Handles thousands separators, decimal separators, digit grouping for all locales correctly |
| Dark/light theme switching | Manual `MediaQuery.platformBrightness` listener with state management | `ThemeMode.system` on `MaterialApp` | Flutter framework handles brightness changes automatically with animated transitions |

**Key insight:** All three changes in this phase use existing Flutter/Dart infrastructure. There is zero custom logic to invent -- only correct wiring of existing APIs.

## Common Pitfalls

### Pitfall 1: colorScheme vs colorSchemeSeed Assertion Crash

**What goes wrong:** App crashes on launch with assertion error "You cannot provide both colorScheme and colorSchemeSeed."
**Why it happens:** The existing `main.dart` uses `colorSchemeSeed: Colors.blue`. Adding `colorScheme:` from DynamicColorBuilder without removing `colorSchemeSeed` triggers ThemeData's built-in assertion.
**How to avoid:** Replace `colorSchemeSeed: Colors.blue` entirely with `colorScheme: lightDynamic ?? ColorScheme.fromSeed(seedColor: Colors.blue)`. Never have both properties present.
**Warning signs:** Immediate crash on launch in debug mode. Assertion text is clear and identifies the conflict.

### Pitfall 2: SnackBar persist Default Changed in Flutter 3.38

**What goes wrong:** SnackBars with a `SnackBarAction` persist indefinitely instead of auto-dismissing after `duration`.
**Why it happens:** Flutter 3.38 changed the default behavior for accessibility -- action SnackBars now default to `persist: true`. The `duration` property is silently ignored.
**How to avoid:** Add `persist: false` to any SnackBar that has an action but should still auto-dismiss.
**Warning signs:** Tap a quick-add button. If the SnackBar stays on screen longer than 5 seconds without user interaction, `persist` is defaulting to true.

### Pitfall 3: Locale Not Resolved Outside Widget Tree

**What goes wrong:** `NumberFormat.decimalPatternDigits(locale: Intl.getCurrentLocale())` uses `en_US` as default instead of the device locale, because `Intl.defaultLocale` is not automatically set in Flutter.
**Why it happens:** The `intl` package's `Intl.defaultLocale` must be explicitly set. Flutter does NOT auto-configure it from the device locale.
**How to avoid:** Use `Localizations.localeOf(context).toString()` inside a widget `build` method to get the resolved locale, and pass it to `NumberFormat`. This works because `MaterialApp` sets up the localizations delegate chain.
**Warning signs:** Italian device shows `1.75` instead of `1,75`. Test on a non-English locale device or simulator.

### Pitfall 4: Semantic Colors Invisible on Dark Surfaces

**What goes wrong:** `Colors.green.shade600`, `Colors.red.shade600`, and `Colors.orange.shade700` are chosen for light backgrounds. On dark surfaces they lose contrast and look washed out.
**Why it happens:** These colors have insufficient luminance contrast against dark backgrounds (Material dark surface is ~#1C1B1F).
**How to avoid:** Use brightness-conditional variants: `shade400` for dark mode, `shade600`/`shade700` for light mode (per D-06). The `shade400` variants are lighter and maintain legibility on dark surfaces.
**Warning signs:** Enable dark mode on device. Check if green/red/orange indicators are clearly visible against the dark background.

### Pitfall 5: intl as Transitive Dependency is Fragile

**What goes wrong:** App imports `package:intl/intl.dart` but `intl` is not listed in `pubspec.yaml` direct dependencies. A future `table_calendar` update could drop `intl`, breaking the build.
**Why it happens:** `intl 0.20.2` is currently pulled in transitively via `table_calendar 3.2.0`. Dart allows importing transitive deps but this is considered bad practice.
**How to avoid:** Add `intl: ^0.20.2` to `pubspec.yaml` `dependencies:` section explicitly. CLAUDE.md already lists it as a recommended package.
**Warning signs:** `dart analyze` may warn about importing a package not listed in dependencies.

## Code Examples

Verified patterns from official sources:

### SnackBar Fix (HOME-02)
```dart
// Source: docs.flutter.dev/release/breaking-changes/snackbar-with-action-behavior-update
messenger.showSnackBar(
  SnackBar(
    content: Text('+$amountMl ml added'),
    duration: const Duration(seconds: 5),
    persist: false,  // Restores auto-dismiss (Flutter 3.38+ fix)
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

### L-Display Formatting (HOME-01)
```dart
// Source: pub.dev/documentation/intl/latest/intl/NumberFormat-class.html
import 'package:intl/intl.dart';

// Inside _buildContent or as a method on _HomeScreenState:
String _formatLiters(BuildContext context, int ml) {
  final locale = Localizations.localeOf(context).toString();
  final formatter = NumberFormat.decimalPatternDigits(
    locale: locale,
    decimalDigits: 2,
  );
  return formatter.format(ml / 1000);
}

// Ring center text replacement (line ~139):
center: Text(
  isGoalMet && totalMl == target
      ? 'Goal reached!'
      : '${_formatLiters(context, totalMl)} / ${_formatLiters(context, target)} L',
  style: theme.textTheme.headlineMedium?.copyWith(
    color: isGoalMet ? goalMetColor : null,
  ),
),
```

### DynamicColorBuilder + Dark Theme (THEME-01, THEME-02, THEME-03)
```dart
// Source: github.com/material-foundation/flutter-packages/dynamic_color/example
import 'package:dynamic_color/dynamic_color.dart';

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
        themeMode: ThemeMode.system,
        routerConfig: router,
      );
    },
  );
}
```

### Brightness-Adaptive Semantic Color (THEME-03)
```dart
// Source: CONTEXT.md D-06 (user decision)
// In home_screen.dart _buildContent:
final brightness = Theme.of(context).brightness;
final goalMetColor = brightness == Brightness.dark
    ? Colors.green.shade400
    : Colors.green.shade600;

// In history_screen.dart _buildDayCell:
final brightness = Theme.of(context).brightness;
Color? fillColor;
Color? textColor;

if (metGoal == true) {
  final green = brightness == Brightness.dark
      ? Colors.green.shade400
      : Colors.green.shade600;
  fillColor = green.withValues(alpha: 0.15);
  textColor = green;
} else if (metGoal == false) {
  final red = brightness == Brightness.dark
      ? Colors.red.shade400
      : Colors.red.shade600;
  fillColor = red.withValues(alpha: 0.15);
  textColor = red;
}

// Streak icon (history_screen.dart):
final streakColor = brightness == Brightness.dark
    ? Colors.orange.shade400
    : Colors.orange.shade700;
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `colorSchemeSeed: Colors.blue` | `colorScheme: dynamic ?? ColorScheme.fromSeed(...)` | Flutter 3.x + dynamic_color | Must remove `colorSchemeSeed` when using `colorScheme` |
| SnackBar with action auto-dismisses | SnackBar with action persists by default | Flutter 3.38 (May 2025) | Must add `persist: false` explicitly for auto-dismiss |
| `toStringAsFixed(2)` | `NumberFormat.decimalPatternDigits(decimalDigits: 2)` | Always available | Locale-aware decimal separator (`,` vs `.`) |

**Deprecated/outdated:**
- `colorSchemeSeed`: Not deprecated but cannot coexist with `colorScheme`. Migration to `colorScheme` is required when using DynamicColorBuilder.
- `sqlite3_flutter_libs`: EOL, replaced by `drift_flutter` (not relevant to Phase 6 but noted for context).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Localizations.localeOf(context).toString()` returns a locale string compatible with `NumberFormat`'s `locale` parameter | Architecture Patterns | If incompatible, formatting would fall back to en_US default; user would see `.` instead of `,` on Italian devices |
| A2 | `NumberFormat.decimalPatternDigits` constructor exists and accepts `locale` + `decimalDigits` params | Standard Stack | If API different, would need to use `NumberFormat('0.00', locale)` pattern syntax instead |
| A3 | `intl` should be promoted from transitive to direct dependency | Common Pitfalls | If left transitive, risk is only if table_calendar drops intl in future; low near-term risk |
| A4 | `Theme.of(context).brightness` correctly reflects the active theme brightness (not device brightness) | Architecture Patterns | If it reflects device brightness instead, dark mode detection would still work but would bypass any future manual theme toggle |

**Note:** A1 and A2 are supported by official pub.dev documentation for the `intl` package but the exact constructor signature was confirmed via WebFetch of the API docs page, not Context7 or slopcheck. A2 is further supported by the UI-SPEC which specifies the same API call.

## Open Questions

1. **`intl` promotion: add to pubspec.yaml or rely on transitive?**
   - What we know: `intl 0.20.2` is currently a transitive dependency via `table_calendar`. CLAUDE.md lists `intl: ^0.20.2` as recommended. CONTEXT.md D-08 says "The `intl` package is already in `pubspec.yaml`" -- but it is NOT (verified by grep).
   - What's unclear: Whether the user expects it to be added as a direct dependency or is fine with the transitive dep.
   - Recommendation: Add `intl: ^0.20.2` as a direct dependency. This follows Dart best practices and matches CLAUDE.md's recommendation. The planner should include this in the `pubspec.yaml` update task alongside `dynamic_color`.

2. **Locale initialization for NumberFormat**
   - What we know: `Localizations.localeOf(context).toString()` is the standard Flutter pattern for getting the resolved locale inside a widget build method.
   - What's unclear: Whether the default `MaterialApp` localizations delegates are sufficient or if `intl` requires explicit locale initialization via `Intl.defaultLocale = ...`.
   - Recommendation: Use `Localizations.localeOf(context).toString()` as the locale parameter. If it returns unexpected results, the fallback is `Platform.localeName` from `dart:io`. Test on an Italian locale simulator.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | All features | Yes | 3.44.1 (via FVM) | -- |
| Dart SDK | intl NumberFormat | Yes | 3.12.1 | -- |
| dynamic_color (pub.dev) | THEME-01 | Not yet installed | Will be ^1.8.1 | -- |
| intl (pub.dev) | HOME-01 | Transitive (0.20.2) | Will promote to direct | -- |
| Android 12+ device/emulator | THEME-01 testing | Yes (emulator) | -- | Test on emulator with API 31+ |
| Dark mode toggle | THEME-03 testing | Yes (device settings) | -- | -- |

**Missing dependencies with no fallback:** None -- all dependencies are available or installable via pub.dev.

**Missing dependencies with fallback:** None.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | N/A -- offline app, no auth |
| V3 Session Management | No | N/A -- no sessions |
| V4 Access Control | No | N/A -- single-user local app |
| V5 Input Validation | No | No new user input in Phase 6 (L-display is output formatting; SnackBar fix is behavior change) |
| V6 Cryptography | No | N/A -- no crypto operations |

### Known Threat Patterns for Flutter Material Theming

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| None applicable | -- | Phase 6 is purely cosmetic/behavioral -- no data handling, no network, no user input changes |

Phase 6 has no security implications. All changes are presentation-layer only: theme configuration, text formatting, and SnackBar behavior.

## Sources

### Primary (HIGH confidence)
- [pub.dev/packages/dynamic_color](https://pub.dev/packages/dynamic_color) -- version 1.8.1, verified publisher material.io, DynamicColorBuilder API confirmed
- [docs.flutter.dev/release/breaking-changes/snackbar-with-action-behavior-update](https://docs.flutter.dev/release/breaking-changes/snackbar-with-action-behavior-update) -- SnackBar persist breaking change, migration guide, code fix confirmed
- [pub.dev/packages/intl](https://pub.dev/packages/intl) -- version 0.20.2, verified publisher dart.dev
- [pub.dev/documentation/intl/latest/intl/NumberFormat-class.html](https://pub.dev/documentation/intl/latest/intl/NumberFormat-class.html) -- NumberFormat constructors including `decimalPatternDigits`
- [github.com/material-foundation/flutter-packages/dynamic_color/example](https://github.com/material-foundation/flutter-packages/blob/main/packages/dynamic_color/example/lib/complete_example.dart) -- canonical DynamicColorBuilder usage pattern
- Actual codebase files: `lib/main.dart`, `lib/presentation/screens/home_screen.dart`, `lib/presentation/screens/history_screen.dart`, `pubspec.yaml`, `pubspec.lock`

### Secondary (MEDIUM confidence)
- [api.flutter.dev platformDispatcher](https://api.flutter.dev/flutter/widgets/WidgetsBinding/platformDispatcher.html) -- locale resolution pattern in Flutter

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- both packages verified on pub.dev with official publishers; versions confirmed
- Architecture: HIGH -- DynamicColorBuilder pattern from official Google example; all integration points verified against actual codebase line numbers
- Pitfalls: HIGH -- SnackBar persist change from official Flutter breaking-changes docs; colorScheme assertion from ThemeData source; locale pitfall from intl docs

**Research date:** 2026-06-08
**Valid until:** 2026-07-08 (30 days -- stable packages, no fast-moving APIs)
