# Phase 10: Target History Integration - Pattern Map

**Mapped:** 2026-06-10
**Files analyzed:** 9 modified files
**Analogs found:** 9 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/data/database/tables/user_settings_table.dart` | model | CRUD | self (add column) | exact |
| `lib/data/database/daos/target_history_dao.dart` | model | streaming | `lib/data/database/daos/user_settings_dao.dart` | exact |
| `lib/data/database/daos/user_settings_dao.dart` | model | CRUD | self (add default field) | exact |
| `lib/domain/entities/user_settings_entity.dart` | model | transform | self (add field) | exact |
| `lib/data/repositories/settings_repository.dart` | service | CRUD | self (add method + mapping) | exact |
| `lib/core/providers/stream_providers.dart` | provider | streaming | self (`FocusedMonth`, `calendarMonth`, `streak`) | exact |
| `lib/core/providers/repository_providers.dart` | provider | request-response | self (add DAO provider) | exact |
| `lib/presentation/screens/home_screen.dart` | component | streaming | self (replace timer + target source) | exact |
| `lib/presentation/screens/settings_screen.dart` | component | request-response | self (add toggle + reroute callback) | exact |
| `lib/presentation/screens/history_screen.dart` | component | streaming | self (per-day target in builders) | exact |

## Pattern Assignments

### `lib/data/database/tables/user_settings_table.dart` (model, CRUD)

**Analog:** self -- add column following existing column pattern

**Column definition pattern** (lines 17-18):
```dart
BoolColumn get dndEnabled =>
    boolean().withDefault(const Constant(true))();
```
New column copies this exact shape:
```dart
BoolColumn get applyFromTomorrow =>
    boolean().withDefault(const Constant(false))();
```

---

### `lib/data/database/daos/target_history_dao.dart` (model, streaming)

**Analog:** `lib/data/database/daos/user_settings_dao.dart` lines 16-19

**watchSingleOrNull stream pattern:**
```dart
Stream<UserSetting> watchSettings() {
  return (select(userSettings)..where((t) => t.id.equals(1)))
      .watchSingleOrNull()
      .map((row) => row ?? _defaultSettings());
}
```

**Existing getTargetForDate query to convert** (target_history_dao.dart lines 14-21):
```dart
Future<int?> getTargetForDate(String dateKey) async {
  final row = await (select(targetHistory)
        ..where((t) => t.effectiveDate.isSmallerOrEqualValue(dateKey))
        ..orderBy([(t) => OrderingTerm.desc(t.effectiveDate)])
        ..limit(1))
      .getSingleOrNull();
  return row?.targetMl;
}
```
New `watchTargetForDate` replaces `.getSingleOrNull()` with `.watchSingleOrNull()` and drops `async`.

---

### `lib/data/database/daos/user_settings_dao.dart` (model, CRUD)

**Analog:** self -- add `applyFromTomorrow: false` to `_defaultSettings()`

**Default settings pattern** (lines 33-44):
```dart
UserSetting _defaultSettings() {
  return const UserSetting(
    id: 1,
    dailyTargetMl: 2000,
    notificationIntervalMinutes: 60,
    dndStartHour: 23,
    dndStartMinute: 0,
    dndEndHour: 7,
    dndEndMinute: 0,
    dndEnabled: true,
  );
}
```
Add `applyFromTomorrow: false` after `dndEnabled`.

---

### `lib/domain/entities/user_settings_entity.dart` (model, transform)

**Analog:** self -- add field to freezed class

**Freezed field pattern** (lines 1-16):
```dart
@freezed
abstract class UserSettingsEntity with _$UserSettingsEntity {
  const factory UserSettingsEntity({
    required int dailyTargetMl,
    // ... existing fields ...
    required bool dndEnabled,
  }) = _UserSettingsEntity;
}
```
Add `required bool applyFromTomorrow` after `dndEnabled`.

---

### `lib/data/repositories/settings_repository.dart` (service, CRUD)

**Analog:** self -- existing `updateSettings()` at lines 43-72, mapping at lines 12-24

**Entity mapping pattern** (lines 13-23 in watchSettings):
```dart
(row) => UserSettingsEntity(
  dailyTargetMl: row.dailyTargetMl,
  notificationIntervalMinutes: row.notificationIntervalMinutes,
  dndStartHour: row.dndStartHour,
  dndStartMinute: row.dndStartMinute,
  dndEndHour: row.dndEndHour,
  dndEndMinute: row.dndEndMinute,
  dndEnabled: row.dndEnabled,
),
```
Add `applyFromTomorrow: row.applyFromTomorrow` to both `watchSettings()` and `getSettings()`.

**Companion mapping pattern** (lines 61-70 in updateSettings):
```dart
UserSettingsCompanion(
  dailyTargetMl: Value(entity.dailyTargetMl),
  // ...
  dndEnabled: Value(entity.dndEnabled),
)
```
Add `applyFromTomorrow: Value(entity.applyFromTomorrow)`.

**New method `updateTargetWithHistory`** follows the validation + DAO call pattern of `updateSettings()`. Uses `_db.targetHistoryDao.insertOrReplace()` then `_db.userSettingsDao.updateSettings()`.

---

### `lib/core/providers/stream_providers.dart` (provider, streaming)

**Analog:** self -- three patterns from this file

**keepAlive class Notifier pattern** (lines 126-133, `FocusedMonth`):
```dart
@Riverpod(keepAlive: true)
class FocusedMonth extends _$FocusedMonth {
  @override
  DateTime build() => DateTime.now();

  void set(DateTime month) => state = month;
}
```
`TodayDateKey` extends this with Timer + `ref.onDispose`.

**ref.onDispose pattern** (from `database_provider.dart` line 9):
```dart
ref.onDispose(() => db.close());
```

**Stream family provider pattern** (lines 68-76, `calendarMonth`):
```dart
@riverpod
Stream<Map<String, int>> calendarMonth(Ref ref, int year, int month) {
  final repo = ref.watch(waterRepositoryProvider);
  final firstDay = DateTime(year, month, 1);
  final lastDay = DateTime(year, month + 1, 0);
  final startKey = _toDateKey(firstDay);
  final endKey = _toDateKey(lastDay);
  return repo.watchDailyTotalsInRange(startKey, endKey);
}
```
`effectiveTargetForDate` follows this shape: `@Riverpod(keepAlive: true)` function with `String dateKey` parameter, returns stream from DAO.

**Streak provider pattern** (lines 83-119):
```dart
@riverpod
Stream<int> streak(Ref ref) async* {
  final repo = ref.watch(waterRepositoryProvider);
  final settings = ref.watch(userSettingsProvider).value;
  // ...
  yield* repo.watchDailyTotalsInRange(...).map((totals) { ... });
}
```
Updated streak must also watch `targetHistoryDao.watchAll()` and do per-day target lookup via in-memory scan.

**allTargetHistory provider** for batch calendar use follows `drinkPresets` pattern (lines 46-50):
```dart
@Riverpod(keepAlive: true)
Stream<List<DrinkPresetEntity>> drinkPresets(Ref ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watchPresets();
}
```

---

### `lib/core/providers/repository_providers.dart` (provider, request-response)

**Analog:** self -- lines 8-16

**Provider pattern:**
```dart
@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) {
  return SettingsRepository(ref.watch(appDatabaseProvider));
}
```
`targetHistoryDaoProvider` (if needed) follows same shape but returns `ref.watch(appDatabaseProvider).targetHistoryDao` directly.

---

### `lib/presentation/screens/home_screen.dart` (component, streaming)

**Analog:** self -- lines 22-69 (timer/dateKey to remove), line 68 (provider watch to update)

**Current timer pattern to REMOVE** (lines 22-62):
```dart
late String _dateKey;
Timer? _midnightTimer;
// initState: _dateKey = todayDateKey(); _midnightTimer = Timer.periodic(...)
// dispose: _midnightTimer?.cancel();
```

**Provider watch pattern to KEEP** (lines 67-70):
```dart
final settingsAsync = ref.watch(userSettingsProvider);
final totalAsync = ref.watch(totalMlForDateProvider(_dateKey));
final entriesAsync = ref.watch(waterEntriesForDateProvider(_dateKey));
```
Replace `_dateKey` with `ref.watch(todayDateKeyProvider)`. Replace `settings.dailyTargetMl` with `ref.watch(effectiveTargetForDateProvider(todayKey)).value ?? 2000`.

---

### `lib/presentation/screens/settings_screen.dart` (component, request-response)

**Analog:** self -- existing SwitchListTile pattern and slider onChangeEnd

**SwitchListTile pattern** (exists elsewhere in settings for DND toggle):
```dart
SwitchListTile(
  title: const Text('...'),
  subtitle: Text('...'),
  value: settings.fieldName,
  onChanged: (val) {
    ref.read(settingsRepositoryProvider).updateSettings(
      settings.copyWith(fieldName: val),
    );
  },
),
```

**Slider onChangeEnd reroute:** Replace `updateSettings(settings.copyWith(dailyTargetMl: val.toInt()))` with `updateTargetWithHistory(val.toInt())`.

---

## Shared Patterns

### DAO Stream Watch
**Source:** `lib/data/database/daos/user_settings_dao.dart` lines 16-19
**Apply to:** `target_history_dao.dart` (new `watchTargetForDate` method)
```dart
.watchSingleOrNull()
.map((row) => row ?? fallback);
```

### Riverpod keepAlive Provider
**Source:** `lib/core/providers/stream_providers.dart` lines 38-43, 126-133
**Apply to:** `todayDateKeyProvider`, `effectiveTargetForDateProvider`, `allTargetHistoryProvider`
```dart
@Riverpod(keepAlive: true)
```

### ref.onDispose Cleanup
**Source:** `lib/core/providers/database_provider.dart` line 9
**Apply to:** `todayDateKeyProvider` (Timer cancellation)
```dart
ref.onDispose(() => _midnightTimer?.cancel());
```

### Entity-to-Companion Mapping
**Source:** `lib/data/repositories/settings_repository.dart` lines 13-23, 60-70
**Apply to:** All three mappings in settings_repository (watchSettings, getSettings, updateSettings) for new `applyFromTomorrow` field

### Drift Column with Default
**Source:** `lib/data/database/tables/user_settings_table.dart` lines 17-18
**Apply to:** New `applyFromTomorrow` column
```dart
BoolColumn get applyFromTomorrow =>
    boolean().withDefault(const Constant(false))();
```

## No Analog Found

No files lack an analog. All modifications follow existing patterns in the same file or a sibling file.

## Metadata

**Analog search scope:** `lib/core/providers/`, `lib/data/database/`, `lib/data/repositories/`, `lib/domain/entities/`, `lib/presentation/screens/`
**Files scanned:** 10
**Pattern extraction date:** 2026-06-10
