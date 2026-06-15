# Phase 15: Home & History Fixes - Context

**Gathered:** 2026-06-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix two visible issues post-v1.3 on existing screens — no new capabilities, no new screens:
1. **POLISH-01**: Home screen placeholder text (`_buildEmptyState`) needs horizontal padding and centered text alignment
2. **BUG-04**: History screen shows "Nessuna cronologia" empty state on fresh install even after the first water intake is added — caused by one-time `initState` Future that never re-evaluates

</domain>

<decisions>
## Implementation Decisions

### POLISH-01 — Home placeholder layout

- **D-01:** Add `Padding(EdgeInsets.symmetric(horizontal: 32))` wrapping the `Column` in `_buildEmptyState` — matches the history screen empty state padding, creates visual consistency across empty states in the app
- **D-02:** Add `textAlign: TextAlign.center` to BOTH text widgets (`noDrinksLogged` and `noDrinksLoggedHint`) inside the empty state — ensures text wraps centered rather than left-aligning

### BUG-04 — History screen reactivity

- **D-03:** Fix approach: **stream provider** (not a minimal listen hack). Add a `watchEarliestDateKey()` Drift stream query to `WaterEntryDao` → expose it via `WaterRepository` → create a `@riverpod Stream<String?> earliestDateKey(Ref ref)` provider in `stream_providers.dart`
- **D-04:** Refactor scope: **full state replacement**. Replace all three local state variables (`_firstDay`, `_noEntries`, `_loading`) in `HistoryScreen` with the new stream provider's `AsyncValue`. Only `_selectedDay` remains as local widget state. The screen becomes primarily declarative — consistent with `HomeScreen`'s provider-first pattern.
- **D-05:** The Drift query for `watchEarliestDateKey()` should be a streaming `SELECT MIN(date_key)` on the `water_entries` table. Returns `null` when the table is empty, which maps to the "no entries" state in the UI.

### Claude's Discretion

- Provider `keepAlive` setting for `earliestDateKeyProvider` — let the planner decide based on whether it should survive tab switches (likely `keepAlive: false` is fine since `StatefulShellRoute` keeps the screen alive anyway)
- Exact `AsyncValue.loading()` UI while the stream initializes (a `CircularProgressIndicator` in the body is the existing pattern used everywhere — match it)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Screens being modified
- `lib/presentation/screens/home_screen.dart` — contains `_buildEmptyState` (POLISH-01 fix target, lines 201-219)
- `lib/presentation/screens/history_screen.dart` — contains `_noEntries`/`_firstDay`/`_loading` local state (BUG-04 fix target, full refactor)

### Reactive infrastructure to extend
- `lib/core/providers/stream_providers.dart` — all stream providers live here; new `earliestDateKeyProvider` goes here
- `lib/data/repositories/water_repository.dart` — `getEarliestDateKey()` exists (Future); add `watchEarliestDateKey()` (Stream) alongside it

### Requirements
- `.planning/REQUIREMENTS.md` §v1.4 — POLISH-01 and BUG-04 exact acceptance text

### Navigation structure (root cause of BUG-04)
- `lib/core/router/app_router.dart` — `StatefulShellRoute.indexedStack` keeps HistoryScreen alive; confirms `initState` runs only once per app session

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- History screen empty state (`history_screen.dart` lines 86-112): uses `Padding(all: 32)` + `textAlign: TextAlign.center` — the pattern to match in home screen
- `waterEntriesForDateProvider(dateKey)` in `stream_providers.dart`: existing stream provider pattern — `earliestDateKeyProvider` should follow the same `@riverpod Stream<T>` annotation and structure
- `WaterEntryDao.getEarliestDateKey()`: existing future query — the streaming variant `watchEarliestDateKey()` should be a simple Drift `watchSingle()` or `watch()` wrapping the same MIN query

### Established Patterns
- All reactive data in the app flows through `@riverpod` stream providers in `stream_providers.dart` — new provider must follow this pattern
- `AsyncValue.when(loading: ..., error: ..., data: ...)` pattern used by every screen — use the same three-branch pattern in the refactored `HistoryScreen.build()`
- History screen already uses `targetsAsync.when(...)` pattern — wrap the outer build in the new `earliestDateKeyAsync.when(...)` the same way

### Integration Points
- `WaterEntryDao` (in `lib/data/database/daos/`) — where `watchEarliestDateKey()` DAO method will be added
- `WaterRepository` — thin pass-through layer; add `watchEarliestDateKey()` delegating to the DAO
- `HistoryScreen._selectedDay` (DateTime?) remains the only local `setState` variable after refactor

</code_context>

<specifics>
## Specific Ideas

- The `_buildEmptyState` fix is a contained 3-line change: add `Padding(horizontal: 32)` wrapper + add `textAlign: TextAlign.center` to both `Text` widgets
- The `earliestDateKeyProvider` should return `Stream<String?>` where null = no entries ever logged — same semantic as the existing `getEarliestDateKey()` Future

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 15-home-history-fixes*
*Context gathered: 2026-06-15*
