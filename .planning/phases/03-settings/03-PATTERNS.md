# Phase 3: Settings - Pattern Map

**Mapped:** 2026-06-05
**Files analyzed:** 2
**Analogs found:** 1 / 2

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/presentation/screens/settings_screen.dart` | screen | request-response | `lib/presentation/screens/home_screen.dart` | exact |
| `lib/presentation/widgets/preset_edit_dialog.dart` | component | request-response | none | no-analog |

## Pattern Assignments

### `lib/presentation/screens/settings_screen.dart` (screen, request-response)

**Analog:** `lib/presentation/screens/home_screen.dart`

**Imports pattern** (lines 1-11):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/providers/stream_providers.dart';
import '../../domain/entities/drink_preset_entity.dart';
import '../../domain/entities/user_settings_entity.dart';
```

**ConsumerStatefulWidget scaffold** (lines 13-18):
```dart
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}
```

**Provider watching + async state handling** (lines 55-77):
```dart
@override
Widget build(BuildContext context) {
  final settingsAsync = ref.watch(userSettingsProvider);
  final presetsAsync = ref.watch(drinkPresetsProvider);

  return Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: settingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(
        child: Text('Something went wrong loading your data.'),
      ),
      data: (settings) {
        final presets = presetsAsync.value ?? <DrinkPresetEntity>[];
        return _buildBody(context, settings, presets);
      },
    ),
  );
}
```

**Repository write pattern via ref.read** (lines 207-211):
```dart
// In callbacks, always use ref.read, never ref.watch
final repo = ref.read(settingsRepositoryProvider);
// For settings: repo.updateSettings(settings.copyWith(fieldName: newValue));
// For presets: repo.updatePreset(preset.id, newAmountMl);
```

**Color/opacity pattern** (line 109):
```dart
// Use withValues(alpha:) NOT withOpacity() (deprecated in Flutter 3.44.1+)
colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
```

---

### `lib/presentation/widgets/preset_edit_dialog.dart` (component, request-response)

**No analog.** This is a new extracted dialog widget. Use `StatefulBuilder` inside `showDialog` per RESEARCH.md Pattern 2. No existing dialog pattern in the codebase to copy from.

---

## Shared Patterns

### Provider Access (Read vs Watch)
**Source:** `lib/presentation/screens/home_screen.dart` lines 56-59, 209
**Apply to:** `settings_screen.dart`
```dart
// In build(): ref.watch() for reactive data
final settingsAsync = ref.watch(userSettingsProvider);
final presetsAsync = ref.watch(drinkPresetsProvider);

// In callbacks (onChanged, onTap, onChangeEnd): ref.read() for write operations
final repo = ref.read(settingsRepositoryProvider);
```

### Entity Update via copyWith
**Source:** `lib/data/repositories/settings_repository.dart` lines 43-72
**Apply to:** All settings save operations in `settings_screen.dart`
```dart
// updateSettings takes a full UserSettingsEntity — always use copyWith from current
repo.updateSettings(settings.copyWith(dailyTargetMl: newValue));
// updatePreset takes id + amountMl directly
repo.updatePreset(preset.id, newAmountMl);
```

### AsyncValue Handling
**Source:** `lib/presentation/screens/home_screen.dart` lines 63-76
**Apply to:** `settings_screen.dart`
```dart
// Use .when() for primary async data, .value for secondary
settingsAsync.when(
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (e, _) => Center(child: Text('Error loading settings')),
  data: (settings) {
    final presets = presetsAsync.value ?? <DrinkPresetEntity>[];
    // build UI
  },
);
```

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/presentation/widgets/preset_edit_dialog.dart` | component | request-response | No dialog widgets exist in the codebase yet; use `StatefulBuilder` + `showDialog` pattern from RESEARCH.md |

## Metadata

**Analog search scope:** `lib/presentation/`, `lib/core/providers/`, `lib/data/repositories/`
**Files scanned:** 31
**Pattern extraction date:** 2026-06-05
