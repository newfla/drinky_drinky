# Phase 6: Bug Fix + Theme + L-Display - Pattern Map

**Mapped:** 2026-06-08
**Files analyzed:** 4
**Analogs found:** 4 / 4 (all modifications to existing files — each file is its own analog)

## File Classification

| Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---------------|------|-----------|----------------|---------------|
| `lib/main.dart` | config | request-response | self (current file) | exact |
| `lib/presentation/screens/home_screen.dart` | component | request-response | self (current file) | exact |
| `lib/presentation/screens/history_screen.dart` | component | request-response | self (current file) | exact |
| `pubspec.yaml` | config | N/A | self (current file) | exact |

## Pattern Assignments

### `lib/main.dart` (config — DynamicColorBuilder wrapping)

**Current build method** (lines 33-43):
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final router = ref.watch(appRouterProvider);
  return MaterialApp.router(
    title: 'Drinky Drinky',
    theme: ThemeData(
      colorSchemeSeed: Colors.blue,
      useMaterial3: true,
    ),
    routerConfig: router,
  );
}
```

**Change:** Wrap `MaterialApp.router` in `DynamicColorBuilder`. Replace `colorSchemeSeed` with `colorScheme`. Add `darkTheme` and `themeMode`. Add `import 'package:dynamic_color/dynamic_color.dart';` at line 1.

---

### `lib/presentation/screens/home_screen.dart` (component — 3 changes)

**SnackBar fix location** (lines 246-259):
```dart
messenger.showSnackBar(
  SnackBar(
    content: Text('+$amountMl ml added'),
    duration: const Duration(seconds: 5),
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

**Change:** Add `persist: false,` after `duration:` line (line 249).

**L-display location** (line 139):
```dart
isGoalMet && totalMl == target ? 'Goal reached!' : '$totalMl / $target ml',
```

**Change:** Replace `'$totalMl / $target ml'` with `'${_formatLiters(context, totalMl)} / ${_formatLiters(context, target)} L'`. Add `_formatLiters` helper method and `import 'package:intl/intl.dart';`.

**Semantic color locations** (lines 133-134 and 141):
```dart
// Line 133-134: ring progress color
progressColor: isGoalMet
    ? Colors.green.shade600
    : colorScheme.primary,

// Line 141: ring text color
color: isGoalMet ? Colors.green.shade600 : null,
```

**Change:** Replace `Colors.green.shade600` with brightness-conditional variant at both locations. Pattern: `Theme.of(context).brightness == Brightness.dark ? Colors.green.shade400 : Colors.green.shade600`.

---

### `lib/presentation/screens/history_screen.dart` (component — semantic colors)

**Semantic color locations** (lines 168, 328-332):

Streak icon color (line 168):
```dart
color: Colors.orange.shade700,
```

Calendar day cell colors (lines 327-333):
```dart
if (metGoal == true) {
  fillColor = Colors.green.shade600.withValues(alpha: 0.15);
  textColor = Colors.green.shade600;
} else if (metGoal == false) {
  fillColor = Colors.red.shade600.withValues(alpha: 0.15);
  textColor = Colors.red.shade600;
}
```

**Change:** Make all 5 color references brightness-conditional. Green: `shade400`/`shade600`. Red: `shade400`/`shade600`. Orange: `shade400`/`shade700`.

---

## Shared Patterns

### Theme Access
**Source:** `lib/presentation/screens/home_screen.dart` lines 118-119
**Apply to:** All screen files
```dart
final theme = Theme.of(context);
final colorScheme = theme.colorScheme;
```

### Brightness Check (new pattern for Phase 6)
**Apply to:** `home_screen.dart` (2 occurrences), `history_screen.dart` (3 occurrences)
```dart
// Inline pattern (from CONTEXT.md D-06):
Theme.of(context).brightness == Brightness.dark
    ? Colors.green.shade400
    : Colors.green.shade600;
```

### Locale-Aware Number Formatting (new pattern for Phase 6)
**Apply to:** `home_screen.dart` only
```dart
import 'package:intl/intl.dart';

String _formatLiters(BuildContext context, int ml) {
  final locale = Localizations.localeOf(context).toString();
  final formatter = NumberFormat.decimalPatternDigits(
    locale: locale,
    decimalDigits: 2,
  );
  return formatter.format(ml / 1000);
}
```

## No Analog Found

No files without analogs. All changes are modifications to existing files with clear insertion points.

## Metadata

**Analog search scope:** `lib/` directory
**Files scanned:** 3 source files + pubspec.yaml
**Pattern extraction date:** 2026-06-08
