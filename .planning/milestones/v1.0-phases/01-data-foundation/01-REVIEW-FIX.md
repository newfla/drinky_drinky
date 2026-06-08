---
phase: 01-data-foundation
fixed_at: 2026-06-03T16:15:00Z
review_path: .planning/phases/01-data-foundation/01-REVIEW.md
iteration: 1
findings_in_scope: 11
fixed: 10
skipped: 1
status: partial
---

# Phase 01: Code Review Fix Report

**Fixed at:** 2026-06-03T16:15:00Z
**Source review:** .planning/phases/01-data-foundation/01-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 11 (5 Critical, 6 Warning; WR-04 is a tracking item only)
- Fixed: 10
- Skipped: 1

## Fixed Issues

### CR-01: `deleteLastEntry` deletes across all dates — cross-day data loss

**Files modified:** `lib/data/database/daos/water_entry_dao.dart`, `lib/data/repositories/water_repository.dart`, `test/data/database/daos/water_entry_dao_test.dart`
**Commit:** 7f0df60
**Applied fix:** Added `String dateKey` parameter to `WaterEntryDao.deleteLastEntry()` and filtered the query with `.where((t) => t.dateKey.equals(dateKey))` before ordering by `loggedAt` DESC. Updated `WaterRepository.deleteLastEntry()` to accept and forward the parameter. Updated the test call site to pass `'2026-06-03'`.

---

### CR-02: `_todayDateKey()` is captured once at provider construction — stale date after midnight

**Files modified:** `lib/core/providers/stream_providers.dart`, `lib/core/providers/stream_providers.g.dart`
**Commit:** f8c6d01 + 92b0eea (generated file)
**Applied fix:** Replaced `todayWaterEntries` and `todayTotalMl` keepAlive providers (which captured the date once at construction) with `waterEntriesForDate(Ref ref, String dateKey)` and `totalMlForDate(Ref ref, String dateKey)` family providers (auto-dispose). Callers pass `todayDateKey()` at widget build time so the date is always current. Renamed `_todayDateKey()` to `todayDateKey()` (public) for widget use. Regenerated `stream_providers.g.dart` to match.
**Status:** fixed: requires human verification (logic: callers must be updated to pass `todayDateKey()` as screens are implemented)

---

### CR-03: `dateKey` validation regex accepts semantically invalid dates

**Files modified:** `lib/data/repositories/water_repository.dart`
**Commit:** 8a23b47
**Applied fix:** After the existing regex check, added `DateTime.tryParse(dateKey)` and a round-trip comparison to reject dates like `'2026-00-00'` or `'2026-13-99'` that pass format validation but represent impossible calendar dates.

---

### CR-04: `SettingsRepository.updateSettings` has no input validation

**Files modified:** `lib/data/repositories/settings_repository.dart`
**Commit:** 3556b56
**Applied fix:** Added guard block at the top of `updateSettings()` that throws `ArgumentError` for: `dailyTargetMl <= 0`, `notificationIntervalMinutes <= 0`, and any DND hour value outside 0-23 or minute value outside 0-59. Database write is only reached if all checks pass.

---

### CR-05: `DrinkPresetDao.updatePreset` accepts zero or negative `amountMl`

**Files modified:** `lib/data/database/daos/drink_preset_dao.dart`, `lib/data/repositories/settings_repository.dart`
**Commit:** 4534f6f
**Applied fix:** Added `if (amountMl <= 0) throw ArgumentError.value(...)` guard at the top of `DrinkPresetDao.updatePreset()`. Also addressed WR-07 in the same commit (see below).

---

### WR-01: `UserSettingsDao.getSettings()` / `watchSettings()` throws `StateError` when settings row is absent

**Files modified:** `lib/data/database/daos/user_settings_dao.dart`
**Commit:** 0027fc6
**Applied fix:** Changed `watchSingle()` to `watchSingleOrNull().map((row) => row ?? _defaultSettings())` and `getSingle()` to `getSingleOrNull()` with a null fallback. Added private `_defaultSettings()` method returning a `UserSetting` with the same column defaults as the table definition (target=2000ml, interval=60min, DND 23:00-07:00, enabled=true).

---

### WR-02: `watchEntriesInRange` has no ordering — result order is non-deterministic

**Files modified:** `lib/data/database/daos/water_entry_dao.dart`
**Commit:** 4c2644a
**Applied fix:** Added `..orderBy([(t) => OrderingTerm.asc(t.dateKey), (t) => OrderingTerm.asc(t.loggedAt)])` to the `watchEntriesInRange` query, matching the approach used by `watchEntriesForDate`.

---

### WR-03: `DailyProgress` entity is dead code

**Files modified:** `lib/domain/entities/daily_progress.dart` (deleted), `lib/domain/entities/daily_progress.freezed.dart` (deleted)
**Commit:** 94c55de
**Applied fix:** Removed both the source file and the Freezed-generated file. No external references to either file existed in the codebase. If a combined daily snapshot entity is needed in future, it should be re-introduced with a concrete use case.

---

### WR-05: `appRouter` is a bare global final — incompatible with testing and state isolation

**Files modified:** `lib/core/router/app_router.dart`, `lib/main.dart`, `lib/core/router/app_router.g.dart` (generated)
**Commit:** 94d07af + 92b0eea (generated file)
**Applied fix:** Replaced `final appRouter = GoRouter(...)` with a `@Riverpod(keepAlive: true) GoRouter appRouter(Ref ref)` provider that registers `ref.onDispose(router.dispose)`. Updated `DrinkyDrinkyApp` from `StatelessWidget` to `ConsumerWidget` that reads `appRouterProvider`. Generated `app_router.g.dart` via build_runner.

---

### WR-07: `updatePreset` returns `void`, discarding row-count

**Files modified:** `lib/data/database/daos/drink_preset_dao.dart`, `lib/data/repositories/settings_repository.dart`
**Commit:** 4534f6f (combined with CR-05)
**Applied fix:** Changed return type of `DrinkPresetDao.updatePreset()` and `SettingsRepository.updatePreset()` from `Future<void>` to `Future<int>`. The Drift `.write()` call already returned the row count; the `void` wrapper was discarding it. Callers can now detect a 0 result (unknown id) instead of silently ignoring it.

---

## Skipped Issues

### WR-06: `path_provider` explicit import in `app_database.dart`

**File:** `lib/data/database/app_database.dart:3`
**Reason:** The import is legitimately required. `drift_flutter` does NOT re-export `getApplicationSupportDirectory` — it is used internally in `drift_flutter/src/native.dart` but not exported. The `app_database.dart` file passes `getApplicationSupportDirectory` as the `databaseDirectory` callback to `DriftNativeOptions`, which requires the symbol to be in scope. Removing the import would cause a compile error. The reviewer's concern about import shadowing is theoretical and does not apply in the current API.

---

_Fixed: 2026-06-03T16:15:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
