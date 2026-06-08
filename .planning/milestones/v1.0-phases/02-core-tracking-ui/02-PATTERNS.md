# Phase 2: Core Tracking UI - Pattern Map

**Mapped:** 2026-06-04
**Files analyzed:** 5 (3 modified, 2 optional new)
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/core/router/app_router.dart` | route/config | request-response | itself (current flat routes) | exact |
| `lib/presentation/screens/home_screen.dart` | component | streaming (multi-stream) | `lib/presentation/screens/home_screen.dart` (placeholder structure) + `lib/core/providers/stream_providers.dart` (provider consumption) | role-match |
| `lib/presentation/screens/history_screen.dart` | component | none (static stub) | itself (current placeholder) | exact |
| `lib/presentation/screens/settings_screen.dart` | component | none (static stub) | `lib/presentation/screens/history_screen.dart` | exact |
| `lib/presentation/widgets/` (optional extractions) | component | streaming | `lib/presentation/screens/home_screen.dart` (parent) | role-match |

## Pattern Assignments

### `lib/core/router/app_router.dart` (route/config, request-response)

**Analog:** itself -- migrating from flat routes to StatefulShellRoute

**Imports + provider pattern** (lines 1-7):
```dart
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/history_screen.dart';
import '../../presentation/screens/settings_screen.dart';

part 'app_router.g.dart';
```

**Provider declaration pattern** (lines 12-13):
```dart
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
```

**Disposal pattern** (lines 31-32):
```dart
  ref.onDispose(router.dispose);
  return router;
```

**Key change:** Replace the flat `GoRoute` list (lines 16-29) with `StatefulShellRoute.indexedStack` wrapping three `StatefulShellBranch` entries. Keep `initialLocation: '/'`, `@Riverpod(keepAlive: true)`, and `ref.onDispose(router.dispose)` unchanged.

---

### `lib/presentation/screens/home_screen.dart` (component, streaming)

**Analog:** Current placeholder (structure) + `lib/core/providers/stream_providers.dart` (provider names)

**Current placeholder pattern** (lines 1-17):
```dart
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drinky Drinky'),
      ),
      body: const Center(
        child: Text('Home Screen'),
      ),
    );
  }
}
```

**Must change to:** `ConsumerStatefulWidget` (from `flutter_riverpod`) to support `ref.watch()` and lifecycle listeners.

**Provider consumption pattern** (from `stream_providers.dart` lines 14-44):
```dart
// Provider names to ref.watch():
ref.watch(userSettingsProvider)                      // AsyncValue<UserSettingsEntity>
ref.watch(totalMlForDateProvider(dateKey))           // AsyncValue<int>
ref.watch(waterEntriesForDateProvider(dateKey))      // AsyncValue<List<WaterEntryEntity>>
ref.watch(drinkPresetsProvider)                      // AsyncValue<List<DrinkPresetEntity>>
```

**Repository write pattern** (from `repository_providers.dart` lines 8-11):
```dart
// For insertEntry / deleteLastEntry:
final repo = ref.read(waterRepositoryProvider);
```

**Key imports for rewritten HomeScreen:**
```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../core/providers/stream_providers.dart';
import '../../core/providers/repository_providers.dart';
import '../../domain/entities/water_entry_entity.dart';
import '../../domain/entities/drink_preset_entity.dart';
import '../../domain/entities/user_settings_entity.dart';
```

---

### `lib/presentation/screens/history_screen.dart` (component, static stub)

**Analog:** itself -- minimal change from current placeholder

**Current pattern to preserve** (lines 1-17):
```dart
import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: const Center(
        child: Text('History Screen'),
      ),
    );
  }
}
```

**Key change:** Replace `Text('History Screen')` with `Text('Coming soon')`. Everything else stays the same.

---

### `lib/presentation/screens/settings_screen.dart` (component, static stub)

**Analog:** `lib/presentation/screens/history_screen.dart` -- identical structure

**Key change:** Replace body text with `Text('Coming soon')`. Keep `AppBar(title: const Text('Settings'))`.

---

## Shared Patterns

### Riverpod Provider Declaration
**Source:** `lib/core/providers/stream_providers.dart` (lines 1-7)
**Apply to:** Any new provider files (none expected in Phase 2)
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'stream_providers.g.dart';

@riverpod                          // autoDispose (default)
@Riverpod(keepAlive: true)         // for long-lived providers
```

### Riverpod Provider Consumption (in widgets)
**Source:** Established project convention
**Apply to:** `home_screen.dart`
```dart
// ConsumerStatefulWidget for stateful + ref access
class MyScreen extends ConsumerStatefulWidget {
  const MyScreen({super.key});
  @override
  ConsumerState<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends ConsumerState<MyScreen> {
  @override
  Widget build(BuildContext context) {
    final asyncVal = ref.watch(someProvider);
    return asyncVal.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (data) => /* widget tree */,
    );
  }
}
```

### Repository Access for Writes
**Source:** `lib/core/providers/repository_providers.dart` (lines 8-16)
**Apply to:** `home_screen.dart` (quick-add + undo)
```dart
@Riverpod(keepAlive: true)
WaterRepository waterRepository(Ref ref) {
  return WaterRepository(ref.watch(appDatabaseProvider));
}

// Usage in widget:
final repo = ref.read(waterRepositoryProvider);  // read, not watch, for one-shot writes
```

### Date Key Helper
**Source:** `lib/core/providers/stream_providers.dart` (lines 51-54)
**Apply to:** `home_screen.dart` (midnight reset logic)
```dart
String todayDateKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}
```

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| (none) | -- | -- | All files have analogs in the existing codebase or are modifications of existing files |

Note: The `CircularPercentIndicator` widget and `AppLifecycleListener` patterns have no existing codebase analog, but complete reference code is provided in `02-RESEARCH.md` Patterns 2 and 4. The planner should use those research patterns directly.

## Metadata

**Analog search scope:** `lib/core/`, `lib/presentation/`, `lib/domain/`
**Files scanned:** 7
**Pattern extraction date:** 2026-06-04
