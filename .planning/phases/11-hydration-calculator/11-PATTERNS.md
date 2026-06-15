# Phase 11: Hydration Calculator - Pattern Map

**Mapped:** 2026-06-15
**Files analyzed:** 3 (1 new, 2 modified)
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/presentation/screens/hydration_calculator_screen.dart` | screen (NEW) | request-response | `lib/presentation/screens/permission_screen.dart` | exact |
| `lib/core/router/app_router.dart` | config (MODIFY) | request-response | self (existing redirect pattern) | exact |
| `lib/presentation/screens/settings_screen.dart` | screen (MODIFY) | CRUD | self (existing section/card pattern) | exact |

## Pattern Assignments

### `lib/presentation/screens/hydration_calculator_screen.dart` (screen, NEW)

**Analog:** `lib/presentation/screens/permission_screen.dart`

**Imports pattern** (lines 1-7):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers/repository_providers.dart';
```

**ConsumerStatefulWidget pattern** (lines 15-23):
```dart
class PermissionScreen extends ConsumerStatefulWidget {
  const PermissionScreen({super.key});

  @override
  ConsumerState<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends ConsumerState<PermissionScreen> {
  bool _isLoading = false;
```

**Async handler with mounted checks** (lines 76-113):
```dart
Future<void> _onEnableReminders() async {
  setState(() => _isLoading = true);

  // ... async work ...

  if (!mounted) return;

  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('drinky_permissionScreenShown', true);

  if (!mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Text('...'),
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
    ),
  );

  if (!mounted) return;
  context.go('/');
}
```

**Skip/dismiss handler** (lines 116-122):
```dart
Future<void> _onSkip() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('drinky_permissionScreenShown', true);

  if (!mounted) return;
  context.go('/');
}
```

**UI layout pattern** (lines 26-73):
```dart
// Scaffold > SafeArea > Padding > Column with:
// - Icon header
// - Title text (headlineSmall)
// - Body text (bodyLarge, onSurfaceVariant)
// - FilledButton (primary action, full width)
// - TextButton (skip/dismiss action)
```

---

### `lib/core/router/app_router.dart` (config, MODIFY)

**Analog:** self

**Redirect guard pattern** (lines 23-31):
```dart
redirect: (BuildContext context, GoRouterState state) async {
  // Prevent redirect loop: if already on /permission, do not redirect again.
  if (state.matchedLocation == '/permission') return null;

  final prefs = await SharedPreferences.getInstance();
  final shown = prefs.getBool('drinky_permissionScreenShown') ?? false;
  if (!shown) return '/permission';
  return null;
},
```

**Top-level GoRoute pattern** (lines 35-38):
```dart
GoRoute(
  path: '/permission',
  builder: (context, state) => const PermissionScreen(),
),
```

Phase 11 adds: (1) `if (state.matchedLocation == '/calculator') return null;` loop guard, (2) second SharedPreferences check after the permission check, (3) new `/calculator` GoRoute at lines 39-41 (same level as `/permission`).

---

### `lib/presentation/screens/settings_screen.dart` (screen, MODIFY)

**Analog:** self

**Section label + Card pattern** (lines 66-76):
```dart
_sectionLabel(context, 'DAILY GOAL'),
_dailyGoalCard(context, settings),
_sectionLabel(context, 'QUICK-ADD PRESETS'),
_presetsCard(context, presets),
_sectionLabel(context, 'NOTIFICATIONS'),
_notificationsCard(context, settings),
```

**Section label widget** (lines 79-86):
```dart
Widget _sectionLabel(BuildContext context, String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelSmall,
    ),
  );
}
```

**Card with ListTile pattern** (lines 139-151):
```dart
Card(
  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  child: Column(
    children: [
      ListTile(
        title: Text('...'),
        subtitle: Text('...'),
        trailing: const Icon(Icons.edit),
        onTap: () => ...,
      ),
    ],
  ),
);
```

Phase 11 adds: `_sectionLabel(context, 'HYDRATION')` + Card with ListTile for "Ricalcola raccomandazione idratazione" with `onTap: () => context.push('/calculator')`. Requires adding `import 'package:go_router/go_router.dart';` to imports.

---

## Shared Patterns

### SharedPreferences Flag Convention
**Source:** `lib/presentation/screens/permission_screen.dart` lines 84-85, `lib/core/router/app_router.dart` line 28
**Apply to:** calculator screen (new flag `drinky_calculatorShown`), router redirect
```dart
// Namespaced key: drinky_<featureName>
final prefs = await SharedPreferences.getInstance();
await prefs.setBool('drinky_calculatorShown', true);
```

### SettingsRepository Access
**Source:** `lib/presentation/screens/settings_screen.dart` line 114
**Apply to:** calculator screen "Usa come target" handler
```dart
ref.read(settingsRepositoryProvider).updateTargetWithHistory(val.toInt());
```

### SnackBar Pattern
**Source:** `lib/presentation/screens/permission_screen.dart` lines 90-102
**Apply to:** calculator screen after target update
```dart
final messenger = ScaffoldMessenger.of(context);
messenger.clearSnackBars();
messenger.showSnackBar(
  SnackBar(
    content: Text('...'),
    duration: const Duration(seconds: 4),
    behavior: SnackBarBehavior.floating,
  ),
);
```

### Mounted Check After Await
**Source:** `lib/presentation/screens/permission_screen.dart` lines 81, 87, 112
**Apply to:** calculator screen async handlers
```dart
if (!mounted) return;
```

## No Analog Found

No files without analogs. All three files have exact matches in the existing codebase.

## Metadata

**Analog search scope:** `lib/presentation/screens/`, `lib/core/router/`
**Files scanned:** 3 analogs read
**Pattern extraction date:** 2026-06-15
