# Phase 4: Calendar & Streaks - Context

**Gathered:** 2026-06-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 4 replaces the "Coming soon" stub in `HistoryScreen` with a fully functional history view. Two components:

1. **Monthly calendar** (HIST-01) — `TableCalendar` widget showing each past day color-coded: green (goal met), red (goal missed), no color (no data or future). Month navigation is available.
2. **Streak counter** (HIST-02) — a `StreakCard` above the calendar showing the current consecutive-days-met count (counted from yesterday backward, today excluded as incomplete).

All UI visual decisions are locked in `04-UI-SPEC.md`. This CONTEXT.md covers data layer and provider architecture decisions only.

No notification scheduling. No settings changes. No new packages beyond `table_calendar ^3.2.0` (must be added to `pubspec.yaml`).

</domain>

<decisions>
## Implementation Decisions

### Data Layer (D-01 – D-05)

- **D-01:** Add `WaterRepository.watchDailyTotalsInRange(String startDateKey, String endDateKey)` → `Stream<Map<String, int>>`. Internally calls the existing `WaterEntryDao.watchEntriesInRange(start, end)` and groups the resulting entry list by `dateKey`, summing `amountMl`. Returns a map keyed by `dateKey` (e.g., `{"2026-06-01": 1800, "2026-06-03": 2400}`). Days with zero entries do not appear in the map (absence = no data).

- **D-02:** Single method for both calendar and streak. The caller (provider) decides how wide a range to request — the repository method is the same for both use cases.

- **D-03:** Calendar queries one month at a time (e.g., `"2026-06-01"` to `"2026-06-30"`). The calendarMonth family provider passes `(firstDayOfMonth, lastDayOfMonth)` to this method.

- **D-04:** Streak uses a separate, broader call: `watchDailyTotalsInRange(veryEarlyDate, yesterday)`. The streak provider receives the full history map and walks backward from `yesterday` until it finds a day where `totalMl < dailyTargetMl` (or no entry). Returns the count of consecutive goal-met days.

- **D-05:** Add `WaterEntryDao.getEarliestDateKey()` → `Future<String?>`. Used to initialize `firstDay` for the `TableCalendar`. Returns `null` if no entries exist (new user). `WaterRepository` exposes this as a pass-through.

### Provider Architecture (D-06 – D-09)

- **D-06:** Two separate Riverpod providers:
  1. `calendarMonthProvider(int year, int month)` — family, `AsyncValue<Map<String, int>>`
  2. `streakProvider` — non-family, `AsyncValue<int>`

- **D-07:** `calendarMonthProvider` is a `@riverpod` family. When the user navigates months, the widget passes new `(year, month)` args. Riverpod caches each month separately — navigating back to a previously visited month does not re-query.

- **D-08:** `streakProvider` calls `watchDailyTotalsInRange(DateTime(2020, 1, 1).toDateKey(), yesterday.toDateKey())`, walks backward from yesterday, and returns an `int` streak count. Computed entirely in Dart inside the provider body. `DateTime(2020, 1, 1)` is the `veryEarlyDate` fallback (safe lower bound — no user will have pre-2020 entries).

- **D-09:** Focused month stored in `focusedMonthProvider` (Riverpod, `keepAlive: true`). Initialized to the current month. Survives tab switches — if the user goes to Home and back to History, they return to the same month.

### Month Navigation (D-10 – D-12)

- **D-10:** Block future months — `lastDay` parameter of `TableCalendar` set to the last day of the current month (e.g., `DateTime(now.year, now.month + 1, 0)`).

- **D-11:** `firstDay` = date from `getEarliestDateKey()`. While this async query is loading, `HistoryScreen` shows a loading spinner (full-screen `CircularProgressIndicator`). Once resolved, `firstDay` is set. If null (no entries yet), fall back to `DateTime(2020, 1, 1)`.

- **D-12:** `HistoryScreen` is a `ConsumerStatefulWidget`. The `State` initiates the `getEarliestDateKey()` future in `initState` and uses `setState` when it resolves to trigger rebuild. The `focusedMonthProvider` is a `Riverpod` `StateProvider` or `NotifierProvider` (planner's choice of provider type) so it persists across tab switches.

### Claude's Discretion

- Exact Riverpod provider type for `focusedMonthProvider` (`StateProvider<DateTime>` vs `NotifierProvider`).
- Whether `calendarMonthProvider` and `streakProvider` are `keepAlive: true` or auto-dispose (auto-dispose is fine since each is cheap to recompute).
- AppBar title: `"History"` (matches nav bar label, same pattern as `"Settings"`).
- Error state copy for stream failures: match the `04-UI-SPEC.md` string `"Something went wrong loading your data."`.
- The exact `dateKey` helper extension (`toDateKey()`) — if one doesn't exist, create a small local function `String _toDateKey(DateTime d)` inline rather than a shared utility.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` — HIST-01 and HIST-02 (the 2 requirements this phase must satisfy)
- `.planning/ROADMAP.md` — Phase 4 section: goal, success criteria (3 SC), mode

### UI Design Contract
- `.planning/phases/04-calendar-streaks/04-UI-SPEC.md` — ALL visual decisions locked here. Color tokens, spacing scale (8-point), typography (4 sizes, 3 weights — 400/500/600 justified), StreakCard layout, TableCalendar builder specs, green/red semantic colors, today-border ring, empty state copy, error state copy. Planner and executor MUST read this before writing any widget code.

### Existing Code — Data Layer
- `lib/data/database/daos/water_entry_dao.dart` — Has `watchEntriesInRange(startDateKey, endDateKey)` (used by new WaterRepository method). Needs new `getEarliestDateKey()` method added.
- `lib/data/repositories/water_repository.dart` — Add `watchDailyTotalsInRange()` and expose `getEarliestDateKey()` here. Existing `watchTotalForDate()` pattern shows the stream-mapping convention to follow.
- `lib/core/providers/stream_providers.dart` — Existing `@riverpod` providers to match in style. New `calendarMonthProvider` and `streakProvider` go here (or a new `history_providers.dart` — planner's choice).

### Existing Code — Screen
- `lib/presentation/screens/history_screen.dart` — Current stub (`StatelessWidget`). Replace with `ConsumerStatefulWidget`. Already wired to the router at `/history` shell branch.
- `lib/presentation/screens/home_screen.dart` — Reference for `ConsumerStatefulWidget` pattern with Riverpod `.value` (nullable) error handling.
- `lib/presentation/screens/settings_screen.dart` — Reference for Card + ListTile layout patterns.

### Stack Reference
- `CLAUDE.md` — Tech Stack table. `table_calendar ^3.2.0` is listed in Recommended Stack (UI Components) but is NOT currently in `pubspec.yaml`. **Planner must include `flutter pub add table_calendar` or manual pubspec edit + `flutter pub get` as an explicit task.**

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `WaterEntryDao.watchEntriesInRange(startDateKey, endDateKey)` — reactive stream for a date range; basis for `watchDailyTotalsInRange`.
- `userSettingsProvider` (stream, keepAlive) — provides `dailyTargetMl` needed by both the calendar (pass/fail comparison) and the streak provider.
- `waterRepositoryProvider` and `settingsRepositoryProvider` — existing DI via Riverpod.
- `ConsumerStatefulWidget` + `AppLifecycleListener` pattern from `home_screen.dart` — reference for local state + lifecycle management.

### Established Patterns
- `dateKey` format: `YYYY-MM-DD` string in local device time — all queries use this format.
- Riverpod code-gen: `@riverpod` annotation, `ref.watch()` in build, `ref.read()` in callbacks.
- `.value` (nullable `T?`) for async provider state — `withOpacity` → `withValues(alpha:)` for deprecated API.
- Layer-first folders: new providers in `lib/core/providers/`, new screen at `lib/presentation/screens/history_screen.dart`.

### Integration Points
- `HistoryScreen` already registered in GoRouter shell branch (`/history`). No router changes needed.
- The `NavigationBar` shell provides scaffold — `HistoryScreen` provides its own `Scaffold` body only.
- `table_calendar` `calendarBuilders` hooks (`defaultBuilder`, `markerBuilder`) are where the green/red/today decorations are applied — these will call into the `calendarMonthProvider` data.

</code_context>

<specifics>
## Specific Ideas

- `calendarMonthProvider(year, month)` family: pass `(DateTime.now().year, DateTime.now().month)` as initial args from the widget.
- `focusedMonthProvider`: initialized to `DateTime.now()`. When user swipes to previous/next month in `TableCalendar.onPageChanged`, the widget calls `ref.read(focusedMonthProvider.notifier).state = newMonth` (or equivalent for NotifierProvider).
- Streak walk-backward algorithm: start from `yesterday = DateTime.now().subtract(Duration(days: 1))`. Walk backward one day at a time: if that day's dateKey is in the map AND `map[dateKey]! >= dailyTargetMl`, increment streak; otherwise stop. Return streak count.
- For `getEarliestDateKey()` in the DAO: `(select(waterEntries)..orderBy([(t) => OrderingTerm.asc(t.dateKey)])..limit(1)).getSingleOrNull()?.dateKey`.
- Loading state for `getEarliestDateKey`: use a `FutureProvider` (`earliestDateKeyProvider`) or `StatefulWidget.initState` + `setState` — planner's choice.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 4-calendar-streaks*
*Context gathered: 2026-06-05*
