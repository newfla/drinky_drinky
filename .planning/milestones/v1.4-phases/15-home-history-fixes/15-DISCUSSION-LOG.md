# Phase 15: Home & History Fixes - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-15
**Phase:** 15-home-history-fixes
**Areas discussed:** Home placeholder layout, History reactivity strategy

---

## Home placeholder layout

| Option | Description | Selected |
|--------|-------------|----------|
| horizontal: 32 | Matches the history screen empty state — creates breathing room and visual consistency across empty states in the app | ✓ |
| horizontal: 16 | Matches the timeline section header just above — keeps padding consistent within the home screen itself | |
| You decide | Let Claude pick whatever matches the rest of the home screen's visual rhythm | |

**User's choice:** horizontal: 32

---

| Option | Description | Selected |
|--------|-------------|----------|
| Both centered | textAlign: TextAlign.center on both noDrinksLogged and noDrinksLoggedHint | ✓ |
| Hint line only | Center just the secondary hint text; primary line stays left-aligned | |

**User's choice:** Both centered
**Notes:** Consistent with the history screen pattern where the hint text is centered. Applying to both texts ensures no awkward left-alignment if the primary line wraps.

---

## History reactivity strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Stream provider | Add watchEarliestDateKey() Drift query → WaterRepository → new @riverpod stream provider. Replaces all 3 local state vars with reactive AsyncValue. | ✓ |
| Minimal listen | Keep local state, add ref.listen to waterEntriesForDateProvider(todayKey) in build(). Re-call getEarliestDateKey() and setState when entries appear. | |

**User's choice:** Stream provider (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Full state replacement | Replace all 3 local vars (_firstDay, _noEntries, _loading) with the stream provider's AsyncValue. Only _selectedDay remains local. | ✓ |
| Minimal replacement | Keep _selectedDay and _firstDay as local state; only replace initState Future with reactive provider listen. | |

**User's choice:** Full state replacement
**Notes:** Makes HistoryScreen consistent with HomeScreen's provider-first pattern. Eliminates the entire class of "stale local state" bugs for this screen.

---

## Claude's Discretion

- Provider `keepAlive` setting for `earliestDateKeyProvider` — left to planner
- Exact loading indicator widget choice for `AsyncValue.loading()` state

## Deferred Ideas

None — discussion stayed within phase scope.
