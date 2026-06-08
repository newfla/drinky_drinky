# Feature Landscape: v1.1 Polish & UX

**Domain:** Flutter hydration tracker -- UX refinement milestone
**Researched:** 2026-06-08
**Confidence:** HIGH (verified via official Flutter API docs, pub.dev, dynamic_color GitHub repo, Dart core library docs, Flutter breaking changes docs)

## Table Stakes

Features users expect in a polished hydration app. Missing = app feels unfinished.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Liter display (X.XX L / Y.YY L) | Users worldwide think in liters, not ml | Low | Pure formatting, no data model change |
| SnackBar undo reliability | Existing feature -- must actually work | Low | Flutter 3.38+ breaking change, one-line fix |
| App icon (water glass) | Default Flutter icon = amateur look | Low | Config-only via flutter_launcher_icons |

## Differentiators

Features that elevate the app beyond "basic tracker."

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Material You dynamic color | App feels native to user's Android device | Medium | Requires new dependency, theme refactor |
| FAB + modal bottom sheet intake | Cleaner home screen, custom ml input, room for future drink types | Medium | Replaces inline buttons, new widget |

## Anti-Features

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Dark mode toggle in v1.1 | Scope creep; Material You gives you dark theme "for free" via DynamicColorBuilder but requires testing both themes thoroughly | Accept platform brightness only -- `themeMode: ThemeMode.system` |
| Custom drink icons/colors in bottom sheet | Over-engineering for 3-4 presets | Plain text labels with ml amounts |
| Animated FAB (morphing, hero) | Distraction, accessibility issues | Standard FAB with water_drop icon |

---

## Feature 1: Material You Dynamic Color

**Category:** Differentiator
**Confidence:** HIGH (verified via dynamic_color 1.8.1 official repo + Flutter docs)

### What It Does

On Android 12+ (API 31+), the OS extracts a palette from the user's wallpaper. The `dynamic_color` package (by material.io) exposes this palette as `ColorScheme` objects. On older Android, iOS, and all other platforms, the palette is `null` and you fall back to a static seed color.

### Package

`dynamic_color: ^1.8.1` -- published by material.io (verified publisher). Latest release 2025-08-01.

### Standard Pattern: DynamicColorBuilder

`DynamicColorBuilder` is a stateful widget whose builder callback receives two nullable `ColorScheme` arguments:

```dart
import 'package:dynamic_color/dynamic_color.dart';

// Brand fallback seed -- used on iOS, Android < 12, and any platform
// that does not provide dynamic colors.
const _brandSeed = Colors.blue;

class DrinkyDrinkyApp extends ConsumerWidget {
  const DrinkyDrinkyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // --- Light theme ---
        final lightScheme = lightDynamic ?? ColorScheme.fromSeed(
          seedColor: _brandSeed,
        );

        // --- Dark theme ---
        final darkScheme = darkDynamic ?? ColorScheme.fromSeed(
          seedColor: _brandSeed,
          brightness: Brightness.dark,
        );

        return MaterialApp.router(
          title: 'Drinky Drinky',
          theme: ThemeData(
            colorScheme: lightScheme,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: darkScheme,
            useMaterial3: true,
          ),
          themeMode: ThemeMode.system, // follow platform brightness
          routerConfig: router,
        );
      },
    );
  }
}
```

### How Fallback Works

| Platform | lightDynamic | darkDynamic | Behavior |
|----------|-------------|-------------|----------|
| Android 12+ (API 31+) | `ColorScheme` from wallpaper | `ColorScheme` from wallpaper | Full dynamic theming |
| Android < 12 | `null` | `null` | Falls back to `ColorScheme.fromSeed(seedColor: Colors.blue)` |
| iOS | `null` | `null` | Falls back to `ColorScheme.fromSeed(seedColor: Colors.blue)` |

The null-coalescing pattern (`lightDynamic ?? ColorScheme.fromSeed(...)`) is the canonical approach from the official example.

### Integration with Existing App

The current `main.dart` uses `ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true)`. The migration is:

1. Add `dynamic_color: ^1.8.1` to pubspec.yaml
2. Wrap `MaterialApp.router` inside `DynamicColorBuilder`
3. Replace `colorSchemeSeed` with explicit `colorScheme` from the builder
4. Add `darkTheme` and `themeMode: ThemeMode.system`

### Gotchas

- **Do NOT use `colorSchemeSeed` and `colorScheme` simultaneously** -- `ThemeData` will throw an assertion error. When using `DynamicColorBuilder`, always use `colorScheme:`, never `colorSchemeSeed:`.
- **Harmonization** is optional. The package provides `color.harmonizeWith(colorScheme.primary)` for custom colors (e.g., the green "goal reached" color). Consider harmonizing the hardcoded `Colors.green.shade600` with the dynamic primary.
- **Testing**: The package provides `DynamicColorTestingUtils` for injecting mock palettes in widget tests.

---

## Feature 2: FAB + Modal Bottom Sheet for Intake

**Category:** Differentiator
**Confidence:** HIGH (verified via Flutter API docs for showModalBottomSheet, FloatingActionButton)

### What It Does

Replaces the 4 inline `FilledButton` quick-add presets on the home screen with a single `FloatingActionButton`. Tapping the FAB opens a modal bottom sheet containing 3 preset buttons + a `TextField` for custom ml input.

### Standard Pattern: Scaffold.floatingActionButton + showModalBottomSheet

```dart
// In HomeScreen's Scaffold:
Scaffold(
  appBar: AppBar(title: const Text('Drinky Drinky')),
  floatingActionButton: FloatingActionButton.extended(
    onPressed: () => _showIntakeSheet(context),
    icon: const Icon(Icons.water_drop),
    label: const Text('Add'),
  ),
  body: // ... progress ring + timeline (no more inline buttons)
)
```

### Bottom Sheet Pattern

```dart
void _showIntakeSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    // isScrollControlled: true lets the sheet grow for the TextField
    // and avoids keyboard overlap.
    isScrollControlled: true,
    // showDragHandle: true gives Material 3 drag indicator at top.
    showDragHandle: true,
    builder: (sheetContext) {
      return Padding(
        // Pad bottom by viewInsets to shift above keyboard when TextField focused.
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: _IntakeSheet(
          presets: presets,
          onAdd: (int ml) {
            Navigator.pop(sheetContext); // close sheet
            _onQuickAdd(ml);             // call existing intake logic
          },
        ),
      );
    },
  );
}
```

### _IntakeSheet Widget (StatefulWidget for TextField)

```dart
class _IntakeSheet extends StatefulWidget {
  final List<DrinkPresetEntity> presets;
  final ValueChanged<int> onAdd;

  const _IntakeSheet({required this.presets, required this.onAdd});

  @override
  State<_IntakeSheet> createState() => _IntakeSheetState();
}

class _IntakeSheetState extends State<_IntakeSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min, // sheet wraps content
      children: [
        // Preset chips / buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            children: widget.presets.map((preset) {
              return FilledButton.tonal(
                onPressed: () => widget.onAdd(preset.amountMl),
                child: Text('+${preset.amountMl} ml'),
              );
            }).toList(),
          ),
        ),
        const Divider(),
        // Custom ml input
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Custom amount',
                    suffixText: 'ml',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _submitCustom(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _submitCustom,
                child: const Text('Add'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _submitCustom() {
    final ml = int.tryParse(_controller.text.trim());
    if (ml != null && ml > 0) {
      widget.onAdd(ml);
    }
  }
}
```

### Key Design Decisions

1. **`isScrollControlled: true`** -- Required when the sheet contains a `TextField`. Without it, the keyboard will overlap the sheet content instead of pushing it up.
2. **`MediaQuery.viewInsets.bottom` padding** -- Shifts sheet content above the soft keyboard. This is the standard Flutter pattern for keyboard-aware bottom sheets.
3. **`mainAxisSize: MainAxisSize.min`** -- Makes the sheet wrap its content rather than taking full height.
4. **`showDragHandle: true`** -- Material 3 convention for modal bottom sheets.
5. **Sheet closes on add** -- Call `Navigator.pop(context)` before or after the add callback. Calling it first feels snappier.
6. **_IntakeSheet is a plain StatefulWidget**, not a ConsumerWidget -- it does not need `ref`. It receives presets and an `onAdd` callback from the parent, which owns the Riverpod dependency. This keeps the sheet testable and decoupled.

### Gotchas

- **Do NOT use `Navigator.of(context).pop()` with the wrong context.** Use the `sheetContext` from the `builder:` callback, not the parent screen's `context`. Using the parent context will pop the screen, not the sheet.
- **TextField in bottom sheet + keyboard** is a well-known pain point. The `isScrollControlled: true` + `viewInsets.bottom` pattern is mandatory.
- **FAB position with SnackBar**: Flutter's Scaffold automatically positions the FAB above SnackBars. No manual offset needed.

---

## Feature 3: Liter Display (X.XX L / Y.YY L)

**Category:** Table Stakes
**Confidence:** HIGH (verified via Dart core library docs)

### What It Does

Replaces `"$totalMl / $target ml"` with `"1.75 L / 2.00 L"` format in the progress ring center text.

### Idiomatic Dart Pattern

Use `toStringAsFixed(2)` on a `double` obtained by dividing ml by 1000:

```dart
/// Format milliliters as liters with exactly 2 decimal places.
/// Examples: 0 -> "0.00 L", 250 -> "0.25 L", 1750 -> "1.75 L", 2000 -> "2.00 L"
String formatAsLiters(int ml) {
  return '${(ml / 1000).toStringAsFixed(2)} L';
}

// Usage in progress ring center:
Text(
  '${formatAsLiters(totalMl)} / ${formatAsLiters(target)}',
  style: theme.textTheme.headlineMedium,
)
```

### Why toStringAsFixed(2)

- **Dart docs confirm**: `123.456.toStringAsFixed(2) == '123.46'` -- rounds correctly.
- **Zero-padded**: `2000 / 1000 = 2.0` -> `toStringAsFixed(2)` -> `"2.00"`. Always shows exactly 2 decimal places.
- **No locale dependency**: Uses `.` as decimal separator regardless of locale. This is intentional -- "1.75 L" is universally readable and avoids locale-formatting complexity in v1.1.
- **Integer division safety**: `ml / 1000` in Dart produces a `double` because `ml` is `int` and `/` always returns `double` when either operand could be non-integer. No explicit cast needed.

### Alternative Considered and Rejected

Using `intl` package's `NumberFormat`:

```dart
NumberFormat('#0.00').format(ml / 1000)  // locale-aware
```

Rejected because: this app does not need locale-aware decimal separators in v1.1, and `toStringAsFixed` is simpler with zero dependencies. If localization is added later, switch to `NumberFormat`.

---

## Feature 4: SnackBar Auto-Dismiss Bug Fix

**Category:** Table Stakes (bug fix)
**Confidence:** HIGH (verified via official Flutter breaking changes documentation)

### Root Cause: Flutter 3.38+ Breaking Change

**This is NOT an app bug. It is a Flutter platform behavior change.**

Since Flutter 3.38 (landed in 3.37.0-0.0.pre), SnackBars that have an `action` property now persist indefinitely by default -- they do NOT auto-dismiss after their `duration`. This is an intentional Material 3 accessibility change: action SnackBars persist so users have time to interact with the action button.

The app targets Flutter 3.44.1 (via FVM) and has a SnackBar with `SnackBarAction(label: 'UNDO')`. The `duration: const Duration(seconds: 5)` is being **silently ignored** because of this new default behavior.

**Source:** https://docs.flutter.dev/release/breaking-changes/snackbar-with-action-behavior-update

### The `persist` Property

Flutter 3.38 added a `persist` property to `SnackBar`:

| Value | Behavior |
|-------|----------|
| `persist: null` (default) | SnackBar with action does NOT auto-dismiss. SnackBar without action auto-dismisses after `duration`. |
| `persist: false` | SnackBar always auto-dismisses after `duration`, even with an action. |
| `persist: true` | SnackBar never auto-dismisses, even without an action. |

### The Fix: One Line

Add `persist: false` to the SnackBar to restore the pre-3.38 auto-dismiss behavior:

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

- It is NOT a `mounted` check issue (the existing guard is correct).
- It is NOT a `ScaffoldMessenger` lifecycle issue (the `clearSnackBars()` call is correct).
- It is NOT a timer or duration parameter issue.
- It is NOT related to `ConsumerStatefulWidget` rebuild behavior.

The existing `_onQuickAdd` code is otherwise well-structured. The `clearSnackBars()` before `showSnackBar()` correctly prevents queue buildup. The `mounted` check correctly guards against calling `ScaffoldMessenger.of(context)` on a disposed widget. Only the `persist: false` property is missing.

### ScaffoldMessenger API Reference (for context)

| Method | Behavior |
|--------|----------|
| `showSnackBar(snackBar)` | Queues a SnackBar. If one is already showing, it waits in queue. |
| `clearSnackBars()` | Removes all SnackBars in the queue AND animates out the current one. |
| `hideCurrentSnackBar()` | Animates out only the current SnackBar. Queue continues. |
| `removeCurrentSnackBar()` | Immediately removes current SnackBar (no exit animation). |

### SnackBarClosedReason Enum

| Value | Trigger |
|-------|---------|
| `timeout` | Duration timer expired (auto-dismiss) |
| `action` | User tapped the SnackBarAction |
| `swipe` | User swiped the SnackBar away |
| `hide` | `hideCurrentSnackBar()` was called |
| `remove` | `removeCurrentSnackBar()` was called |
| `dismiss` | Dismissed via accessibility semantics |

---

## Feature 5: App Icon via flutter_launcher_icons

**Category:** Table Stakes
**Confidence:** HIGH (verified via pub.dev flutter_launcher_icons 0.14.4 docs)

### Package

Already in the project's CLAUDE.md stack: `flutter_launcher_icons: ^0.14.4`

### pubspec.yaml Configuration

Add to the **root level** of `pubspec.yaml` (not inside `flutter:` or `dependencies:`):

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.14.4

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"
  min_sdk_android: 24
  # Android adaptive icon (Android 8.0+)
  adaptive_icon_background: "#E3F2FD"
  adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"
```

### Source Image Requirements

| Requirement | Value |
|-------------|-------|
| Format | PNG (no transparency for iOS; transparency OK for Android adaptive foreground) |
| Size | 1024x1024 px minimum (generator downscales) |
| iOS constraint | Must NOT have transparency or alpha channel (App Store rejects it) |
| Android adaptive | Foreground image should have ~30% padding (safe zone is 66% of canvas) |

### Adaptive Icon Anatomy (Android 8.0+)

Android adaptive icons have two layers:
- **Background**: Solid color (`#E3F2FD`) or image
- **Foreground**: The actual icon graphic with transparent padding

The system composites these layers and applies device-specific masks (circle, squircle, rounded square). The foreground image's "safe zone" is the inner 66% of the canvas -- keep the water glass motif within this area.

### Generation Command

```bash
dart run flutter_launcher_icons:generate
```

This generates:
- `android/app/src/main/res/mipmap-*/` -- all density variants
- `android/app/src/main/res/mipmap-anydpi-v26/` -- adaptive icon XML
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/` -- all required iOS sizes

### Workflow

1. Create/commission a 1024x1024 water glass icon PNG
2. For Android adaptive: create a separate foreground PNG with transparent background and 30% margin
3. Add config to `pubspec.yaml`
4. Run `dart run flutter_launcher_icons:generate`
5. Verify in both Android and iOS simulators

### Gotcha

- **iOS icons must not have transparency.** If your source PNG has an alpha channel, iOS build will succeed but App Store Connect will reject it. Use a solid background for the iOS variant, or provide a separate `image_path_ios` if needed:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"
  image_path_android: "assets/icon/app_icon_android.png"
  adaptive_icon_background: "#E3F2FD"
  adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"
```

---

## Feature Dependencies

```
(none) -- all 5 features are independent and can be implemented in any order.

Suggested order based on risk/impact:
1. SnackBar bug fix       -- smallest scope, fixes existing broken behavior
2. L-display              -- smallest scope, pure UI formatting
3. App icon               -- config-only, no runtime code
4. FAB + bottom sheet     -- medium scope, replaces existing UI
5. Material You           -- medium scope, wraps entire app theme
```

The FAB + bottom sheet should come before Material You because the theme refactor is easier to test when the final UI structure (FAB instead of inline buttons) is already in place.

## MVP Recommendation

All 5 features are scoped for v1.1. None should be deferred. Total estimated complexity is Medium (no new data models, no new dependencies beyond `dynamic_color`).

Prioritize:
1. SnackBar bug fix -- correctness before polish
2. L-display formatting -- trivial, high-visibility improvement
3. App icon -- independent, can be done in parallel
4. FAB + modal bottom sheet -- main UX change
5. Material You -- final polish that affects everything visually

Defer: Nothing. All 5 are appropriately scoped for a single milestone.

## Sources

- dynamic_color package: https://pub.dev/packages/dynamic_color (v1.8.1, published 2025-08-01)
- dynamic_color GitHub example: https://github.com/material-foundation/flutter-packages/tree/main/packages/dynamic_color/example
- Flutter showModalBottomSheet API: https://api.flutter.dev/flutter/material/showModalBottomSheet.html
- Flutter SnackBar with action behavior update: https://docs.flutter.dev/release/breaking-changes/snackbar-with-action-behavior-update
- Flutter ScaffoldMessenger API: https://api.flutter.dev/flutter/material/ScaffoldMessenger-class.html
- Flutter ScaffoldMessengerState API: https://api.flutter.dev/flutter/material/ScaffoldMessengerState-class.html
- Flutter SnackBar API: https://api.flutter.dev/flutter/material/SnackBar-class.html
- Flutter SnackBarClosedReason: https://api.flutter.dev/flutter/material/SnackBarClosedReason.html
- Flutter ScaffoldMessenger migration: https://docs.flutter.dev/release/breaking-changes/scaffold-messenger
- Dart toStringAsFixed: https://dart.dev/libraries/dart-core (Numbers section)
- flutter_launcher_icons: https://pub.dev/packages/flutter_launcher_icons (v0.14.4)
- Flutter ColorScheme.fromSeed: https://docs.flutter.dev/release/breaking-changes/material-3-migration
