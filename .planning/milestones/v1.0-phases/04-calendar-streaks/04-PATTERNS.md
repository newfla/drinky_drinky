# Phase 4: Calendar & Streaks - Pattern Map

**Mapped:** 2026-06-05
**Files analyzed:** 5
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/data/database/daos/water_entry_dao.dart` | DAO | CRUD | self (existing file) | exact |
| `lib/data/repositories/water_repository.dart` | repository | streaming | self (existing file) | exact |
| `lib/core/providers/stream_providers.dart` | provider | streaming | self (existing file) | exact |
| `lib/presentation/screens/history_screen.dart` | screen | request-response | `lib/presentation/screens/home_screen.dart` | role-match |
| `pubspec.yaml` | config | N/A | self | exact |

## Pattern Assignments

### `lib/data/database/daos/water_entry_dao.dart` (DAO, add getEarliestDateKey)

**Analog:** self -- follow existing `deleteLastEntry` query pattern

**Query pattern** (lines 35-44):
```dart
/// Delete the most recent entry for [dateKey] (for undo). Returns number of rows deleted.
Future<int> deleteLastEntry(String dateKey) async {
  final lastEntry = await (select(waterEntries)
        ..where((t) => t.dateKey.equals(dateKey))
        ..orderBy([(t) => OrderingTerm.desc(t.loggedAt)])
        ..limit(1))
      .getSingleOrNull();
  if (lastEntry == null) return 0;
  return (delete(waterEntries)..where((t) => t.id.equals(lastEntry.id)))
      .go();
}
```

**New method should follow:** Same `select` + `orderBy` + `limit(1)` + `getSingleOrNull()` chain, but with `OrderingTerm.asc(t.dateKey)` and no `where` clause.

---

### `lib/data/repositories/water_repository.dart` (repository, add watchDailyTotalsInRange + getEarliestDateKey)

**Analog:** self -- follow existing `watchTotalForDate` stream pattern

**Imports pattern** (lines 1-2):
```dart
import '../database/app_database.dart';
import '../../domain/entities/water_entry_entity.dart';
```

**Stream-mapping pattern** (lines 10-21 -- `watchEntriesForDate`):
```dart
Stream<List<WaterEntryEntity>> watchEntriesForDate(String dateKey) {
  return _db.waterEntryDao.watchEntriesForDate(dateKey).map(
        (rows) => rows
            .map((r) => WaterEntryEntity(
                  id: r.id,
                  amountMl: r.amountMl,
                  loggedAt: r.loggedAt,
                  dateKey: r.dateKey,
                ))
            .toList(),
      );
}
```

**Pass-through pattern** (lines 56-57 -- `deleteLastEntry`):
```dart
Future<int> deleteLastEntry(String dateKey) =>
    _db.waterEntryDao.deleteLastEntry(dateKey);
```

**New `watchDailyTotalsInRange` should follow:** Same `_db.waterEntryDao.watchEntriesInRange(start, end).map(...)` pattern. New `getEarliestDateKey` should follow the pass-through pattern.

---

### `lib/core/providers/stream_providers.dart` (providers, add calendarMonthProvider + streakProvider + focusedMonthProvider)

**Analog:** self -- follow existing provider patterns

**Imports pattern** (lines 1-6):
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/water_entry_entity.dart';
import '../../domain/entities/user_settings_entity.dart';
import '../../domain/entities/drink_preset_entity.dart';
import 'repository_providers.dart';

part 'stream_providers.g.dart';
```

**Family stream provider pattern** (lines 14-19 -- `waterEntriesForDate`):
```dart
@riverpod
Stream<List<WaterEntryEntity>> waterEntriesForDate(
    Ref ref, String dateKey) {
  final repo = ref.watch(waterRepositoryProvider);
  return repo.watchEntriesForDate(dateKey);
}
```

**keepAlive stream provider pattern** (lines 33-37 -- `userSettings`):
```dart
@Riverpod(keepAlive: true)
Stream<UserSettingsEntity> userSettings(Ref ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watchSettings();
}
```

**todayDateKey helper** (lines 51-54):
```dart
String todayDateKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}
```

**New providers should follow:** `calendarMonthProvider` follows the family pattern (like `waterEntriesForDate` but with `int year, int month` params). `streakProvider` follows the non-family `@riverpod` pattern. `focusedMonthProvider` follows the `@Riverpod(keepAlive: true)` class Notifier pattern (no existing example in codebase but consistent with code-gen convention -- see RESEARCH.md Pattern 2).

---

### `lib/presentation/screens/history_screen.dart` (screen, replace stub)

**Analog:** `lib/presentation/screens/home_screen.dart`

**Imports pattern** (lines 1-11):
```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/providers/stream_providers.dart';
import '../../domain/entities/drink_preset_entity.dart';
import '../../domain/entities/user_settings_entity.dart';
import '../../domain/entities/water_entry_entity.dart';
```

**ConsumerStatefulWidget declaration** (lines 13-18):
```dart
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}
```

**initState pattern** (lines 21-37):
```dart
late String _dateKey;

@override
void initState() {
  super.initState();
  _dateKey = todayDateKey();
  // ... lifecycle setup
}
```

**Async provider consumption in build** (lines 55-77):
```dart
@override
Widget build(BuildContext context) {
  final settingsAsync = ref.watch(userSettingsProvider);
  final totalAsync = ref.watch(totalMlForDateProvider(_dateKey));

  return Scaffold(
    appBar: AppBar(title: const Text('Drinky Drinky')),
    body: settingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(
        child: Text('Something went wrong loading your data.'),
      ),
      data: (settings) {
        final totalMl = totalAsync.value ?? 0;
        // ...
      },
    ),
  );
}
```

**New HistoryScreen should follow:** Same `ConsumerStatefulWidget` structure. Use `initState` for `getEarliestDateKey()` future with `setState`. Use `ref.watch()` for providers in `build`. Use `settingsAsync.when()` for loading/error/data states.

---

## Shared Patterns

### dateKey Format
**Source:** `lib/core/providers/stream_providers.dart` lines 51-54
**Apply to:** All new providers and repository methods
```dart
String todayDateKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}
```

### Async State Access (.value nullable pattern)
**Source:** `lib/presentation/screens/home_screen.dart` lines 69-70
**Apply to:** history_screen.dart when reading calendarMonthProvider and streakProvider
```dart
final totalMl = totalAsync.value ?? 0;
final entries = (entriesAsync.value ?? <WaterEntryEntity>[]).reversed.toList();
```

### Loading/Error/Data Pattern
**Source:** `lib/presentation/screens/home_screen.dart` lines 63-77
**Apply to:** history_screen.dart
```dart
settingsAsync.when(
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (e, _) => const Center(
    child: Text('Something went wrong loading your data.'),
  ),
  data: (settings) { /* ... */ },
),
```

### Riverpod Provider Declaration
**Source:** `lib/core/providers/stream_providers.dart`
**Apply to:** All new providers
- Auto-dispose family: `@riverpod` on function with params (line 14)
- keepAlive stream: `@Riverpod(keepAlive: true)` (line 33)
- Always include `part '*.g.dart';`

### Color with Alpha
**Source:** `lib/presentation/screens/home_screen.dart` line 109
**Apply to:** history_screen.dart day cell decoration
```dart
colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
```
Use `withValues(alpha:)` not `withOpacity()`.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| N/A | -- | -- | All files have exact or role-match analogs in the existing codebase |

Note: The `@Riverpod(keepAlive: true) class FocusedMonth extends _$FocusedMonth` Notifier pattern has no existing example in the codebase (all current keepAlive providers are function-based). Use RESEARCH.md Pattern 2 for this.

## Metadata

**Analog search scope:** `lib/` directory
**Files scanned:** 32 Dart source files
**Pattern extraction date:** 2026-06-05
