---
phase: 15-home-history-fixes
plan: 01
status: complete
commit: 9de6567
---

# Plan 15-01 Summary

## What was done

### Task 1 — POLISH-01: Home screen empty-state text centering

Modified `lib/presentation/screens/home_screen.dart` `_buildEmptyState()`:
- Wrapped the existing `Column` with `Padding(EdgeInsets.symmetric(horizontal: 32))`
- Added `textAlign: TextAlign.center` to both `Text` widgets (`noDrinksLogged` and `noDrinksLoggedHint`)
- Widget tree is now: `Center` > `Padding(horizontal: 32)` > `Column` > `Text × 2`

### Task 2 — BUG-04: History screen reactive refactor (4-file vertical slice)

**`lib/data/database/daos/water_entry_dao.dart`**  
Added `watchEarliestDateKey()` using `selectOnly + waterEntries.dateKey.min() + watchSingle()`. SQL MIN on an empty table always returns one NULL row, so `watchSingle()` is correct and the stream emits `null` when no entries exist.

**`lib/data/repositories/water_repository.dart`**  
Added `watchEarliestDateKey()` thin pass-through delegating to `_db.waterEntryDao.watchEarliestDateKey()`.

**`lib/core/providers/stream_providers.dart`**  
Added `@riverpod Stream<String?> earliestDateKey(Ref ref)` — auto-dispose, no keepAlive (StatefulShellRoute keeps the widget alive).

**`lib/presentation/screens/history_screen.dart`**  
Full state replacement (D-04):
- Removed `_firstDay`, `_noEntries`, `_loading` field declarations
- Removed entire `initState` override (was the root cause of BUG-04)
- Removed unused `import '../../core/providers/repository_providers.dart'`
- Added `ref.watch(earliestDateKeyProvider)` at top of `build()`
- Replaced all conditional branches with `earliestAsync.when(loading, error, data)`
- Empty state now fires reactively when stream emits `null`; calendar appears when stream emits a non-null dateKey
- Only `_selectedDay` remains as local widget state

**Code generation**  
Ran `dart run build_runner build` with Flutter 3.44.1. Generated `earliestDateKeyProvider` in `stream_providers.g.dart`.

## Verification

- `flutter analyze` on all 5 modified source files: **No issues found**
- `dart run build_runner build`: **26s, 101 outputs, no errors**
- All acceptance criteria confirmed via grep checks
