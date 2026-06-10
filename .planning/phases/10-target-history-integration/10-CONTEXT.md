# Phase 10: Target History Integration - Context

**Gathered:** 2026-06-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 10 wires the `TargetHistoryDao` (built in Phase 9) into the provider layer, home screen, calendar, and settings — and fixes BUG-02 (midnight reset). Delivers:
1. `todayDateKeyProvider` — a keepAlive Notifier with a midnight Timer that keeps `dateKey` fresh without app restart
2. `updateTargetWithHistory()` — the dual-write method (UserSettings + target_history) with "apply from today/tomorrow" logic
3. `applyFromTomorrow` column on UserSettings (Drift, no migration needed — first real install) + toggle UI in Settings
4. `effectiveTargetForDateProvider(dateKey)` — family provider for per-day target lookup
5. Home screen and calendar wired to per-day target (not global `settings.dailyTargetMl`)
6. Streak provider updated to use per-day target via full target_history fetch

This phase does NOT deliver: the hydration calculator, onboarding flow, or CALC-01/02/03/04 (Phase 11).

</domain>

<decisions>
## Implementation Decisions

### BUG-02: Midnight Reset

- **D-01:** Create a `todayDateKeyProvider` as a keepAlive `Notifier<String>`. On `build()`, it computes seconds until next midnight, sets a `Timer` that fires at midnight + a few ms, updates `state` with the new date string, then re-schedules the next midnight Timer. The Notifier disposes the Timer on dispose.
- **D-02:** All widgets that previously called `todayDateKey()` directly replace it with `ref.watch(todayDateKeyProvider)`. Affected: `HomeScreen` (for `totalMlForDateProvider` and `waterEntriesForDateProvider`) and the `streak` provider in `stream_providers.dart`.
- **D-03:** `HistoryScreen` calendar does NOT need the midnight reset — users navigate to months explicitly. Only today's-date consumers need the update.

### TARGET-02: "Applica target da oggi / da domani" Setting

- **D-04:** The "today / tomorrow" choice is a **persistent toggle** in the Settings screen (not a per-change dialog). Presented as a SegmentedButton or labeled Switch inside the existing target section.
- **D-05:** The preference is stored as a new column `applyFromTomorrow` (Drift boolean, `withDefault(const Constant(false))`) on the `UserSettings` table. No schema migration is needed — `schemaVersion` stays at `1` (first real installation). Default `false` = "apply from today".
- **D-06:** `updateTargetWithHistory(int newTargetMl)` lives in `SettingsRepository`. It: (1) reads `applyFromTomorrow` from current settings; (2) computes `effectiveDate` as today or tomorrow accordingly; (3) calls `db.targetHistoryDao.insertOrReplace(effectiveDate, newTargetMl)`; (4) calls `db.userSettingsDao.updateSettings(companion with dailyTargetMl)` — both in the same async sequence (no transaction needed since SQLite serializes writes).
- **D-07:** If the user changes target multiple times "from tomorrow" on the same day, `insertOrReplace` upserts — only the last value for that `effectiveDate` survives. No per-change rows.

### TARGET-03/04: Per-Day Target for Home + Calendar

- **D-08:** Add a family provider `effectiveTargetForDate(String dateKey)` that returns `Stream<int>` from `targetHistoryDao.getTargetForDate(dateKey)`. Falls back to 2000 if `null` (should not happen after seed, but defensive).
- **D-09:** `HomeScreen` replaces `settings.dailyTargetMl` with `ref.watch(effectiveTargetForDateProvider(todayKey))` for the progress ring and goal text. `todayKey` comes from `ref.watch(todayDateKeyProvider)`.
- **D-10:** `HistoryScreen` calendar (day builder) uses `effectiveTargetForDateProvider(dateKey)` for each day it colors green/red. The `calendarMonthProvider` already provides totals per dateKey; the per-day target provider provides the threshold.
- **D-11:** The `streak` provider is updated to: (a) also watch `targetHistoryDao.watchAll()` for all target changes; (b) for each day in the history range, look up the active target by finding the most recent `effectiveDate <= dayKey` in the fetched list; (c) this is a single in-memory scan, not N SQL queries.

### Claude's Discretion

- Exact naming of the `todayDateKeyProvider` class vs function (`@riverpod` annotated class vs `NotifierProvider`)
- Whether `effectiveTargetForDateProvider` is a `@riverpod` annotated function or a manual `StreamProvider.family`
- Positioning of the "Applica da oggi / da domani" toggle within the existing Settings screen layout
- Timer re-schedule strategy when the device clock changes (assume standard behavior is fine)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 9 artifacts (foundation)
- `lib/data/database/daos/target_history_dao.dart` — TargetHistoryDao: getTargetForDate, watchAll, insertOrReplace (DoUpdate upsert)
- `lib/data/database/tables/target_history_table.dart` — TargetHistory table: id, effectiveDate UNIQUE, targetMl
- `lib/data/database/app_database.dart` — schema schemaVersion=1, tables, daos, onCreate seed pattern
- `.planning/phases/09-data-foundation-bug-fixes/09-CONTEXT.md` — Phase 9 decisions (especially D-05 through D-08 on DAO design)
- `.planning/phases/09-data-foundation-bug-fixes/09-RESEARCH.md` — Upsert pattern (DoUpdate), uniqueKeys, Drift API corrections

### Existing provider and repository layer
- `lib/core/providers/stream_providers.dart` — Current providers: `waterEntriesForDate`, `totalMlForDate`, `userSettings`, `drinkPresets`, `calendarMonth`, `streak`, `FocusedMonth`. `todayDateKey()` helper at bottom. `streak` is the one that needs updating.
- `lib/core/providers/repository_providers.dart` — `waterRepositoryProvider`, `settingsRepositoryProvider` — pattern for adding `targetHistoryDaoProvider`
- `lib/data/repositories/settings_repository.dart` — `updateSettings()` method — `updateTargetWithHistory()` is a new method on this class
- `lib/data/database/daos/user_settings_dao.dart` — existing UserSettings DAO pattern

### UI screens that need wiring
- `lib/presentation/screens/home_screen.dart` — uses `totalMlForDateProvider(_dateKey)` + `userSettingsProvider` for target; needs migration to per-day target
- `lib/presentation/screens/settings_screen.dart` — existing target slider; needs the "Applica da" toggle + calls to `updateTargetWithHistory()` instead of bare `updateSettings()`
- `lib/presentation/screens/history_screen.dart` — calendar uses `calendarMonthProvider` + `settings.dailyTargetMl`; needs per-day target

### Requirements
- `.planning/REQUIREMENTS.md` — BUG-02, TARGET-02, TARGET-03, TARGET-04 in scope for Phase 10

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `todayDateKey()` in `lib/core/providers/stream_providers.dart` — the format string logic; copy into the Notifier's `_computeTodayKey()` private method (don't import from providers layer into the Notifier itself to avoid circular deps)
- `_toDateKey(DateTime d)` in `stream_providers.dart` — already exists; use in the streak update for per-day key formatting
- `settingsRepositoryProvider` in `repository_providers.dart` — pattern for exposing `targetHistoryDaoProvider`
- `@Riverpod(keepAlive: true)` annotation — already on `userSettings`, `drinkPresets`; use same annotation for `todayDateKeyProvider` and `effectiveTargetForDateProvider`

### Established Patterns
- **Riverpod code-gen:** All new providers use `@riverpod` / `@Riverpod(keepAlive: true)` annotation. Run `dart run build_runner build --delete-conflicting-outputs` after adding.
- **Stream family provider:** `calendarMonth(Ref ref, int year, int month)` — same shape for `effectiveTargetForDate(Ref ref, String dateKey)`
- **DAO access:** DAOs are accessed through `ref.watch(appDatabaseProvider).{daoName}` — no separate repository wrapper needed for Phase 10; DAO can be exposed directly via a provider.
- **UserSettings update pattern:** `ref.read(settingsRepositoryProvider).updateSettings(settings.copyWith(...))` — the settings slider calls this directly; Phase 10 routes target changes through `updateTargetWithHistory()` instead.

### Integration Points
- `HomeScreen` — replace `settings.dailyTargetMl` with `ref.watch(effectiveTargetForDateProvider(todayKey)).value ?? 2000`; use `ref.watch(todayDateKeyProvider)` for `todayKey`
- `SettingsScreen` — the target slider's `onChangeEnd` callback currently calls `updateSettings(settings.copyWith(dailyTargetMl: val.toInt()))` — replace with `updateTargetWithHistory(val.toInt())`
- `HistoryScreen` — the day builder uses `dailyTarget` from `settings`; replace with `effectiveTargetForDate(dateKey)` per day

</code_context>

<specifics>
## Specific Ideas

- `todayDateKeyProvider` Notifier: compute `secondsUntilMidnight = midnight.difference(DateTime.now()).inSeconds + 1`, then `Timer(Duration(seconds: secondsUntilMidnight), _onMidnight)`. `_onMidnight` sets `state = _computeTodayKey()` and re-calls itself (or re-schedules with a new Timer).
- `streak` update: fetch `targetHistory = await targetHistoryDao.watchAll().first`; sort by `effectiveDate`; for each day in the streak scan, binary-search or linear-scan backward through `targetHistory` to find the last entry `<= dayKey`.
- The `applyFromTomorrow` column default: `withDefault(const Constant(false))` in the Drift table definition — same pattern as `dailyTargetMl` uses `withDefault(const Constant(2000))`.
- `effectiveTargetForDate` fallback: if `getTargetForDate` returns `null`, yield `2000` (matches the seed). Add a comment: "should never be null after seed, but defensive fallback".

</specifics>

<deferred>
## Deferred Ideas

- `updateTargetWithHistory()` called from calculator "Usa come target" button → Phase 11
- Provider wiring for calculator screen → Phase 11
- UI polish for the "Applica da" toggle (animations, accessibility labels) → Phase 11 or later
- Calendar heat-map or color intensity based on intake percentage → future milestone

</deferred>

---

*Phase: 10-target-history-integration*
*Context gathered: 2026-06-10*
