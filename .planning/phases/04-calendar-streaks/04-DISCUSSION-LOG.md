# Phase 4: Calendar & Streaks - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-05
**Phase:** 4-calendar-streaks
**Areas discussed:** Data layer design, Provider architecture, Month navigation

---

## Data Layer Design

| Option | Description | Selected |
|--------|-------------|----------|
| Repository method (Recommended) | Add WaterRepository.watchDailyTotalsInRange → Stream<Map<String,int>>. Groups and sums entries by dateKey in Dart. | ✓ |
| Provider computation | WaterRepository exposes raw entries; provider converts to Map. | |
| SQL aggregate query | New Drift DAO method with GROUP BY + SUM. | |

**User's choice:** Repository method — `watchDailyTotalsInRange` returns the grouped/summed map directly.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Totals map only (Recommended) | Single method returns Map<String,int>; provider computes streak from the same map. | ✓ |
| Two separate repository methods | One for calendar, one streak-specific. | |
| You decide | Let researcher/planner figure out the shape. | |

**User's choice:** Totals map only — single `watchDailyTotalsInRange` method serves both use cases.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Query by calendar month (Recommended) | Calendar queries one month at a time; streak uses a separate broader call. | ✓ |
| Single large query for everything | Query all history from app start to today in one shot. | |
| You decide | Let the planner pick the query window. | |

**User's choice:** Per-month for calendar. Separate "start to yesterday" call for streak.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Separate streak query — start to yesterday (Recommended) | Streak provider calls watchDailyTotalsInRange(veryEarlyDate, yesterday) and walks backward. | ✓ |
| Derive streak from visible month only | Only count within the displayed month. | |
| You decide | Let the planner decide the streak query bound. | |

**User's choice:** Separate broad query from `veryEarlyDate` (2020-01-01 fallback) to `yesterday`.

---

## Provider Architecture

| Option | Description | Selected |
|--------|-------------|----------|
| Two providers (Recommended) | calendarMonthProvider(year, month) + streakProvider. | ✓ |
| One combined provider | Single historyDataProvider(year, month) returns both. | |
| No providers | Compute in widget directly. | |

**User's choice:** Two providers — clean separation of concerns.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Family provider (Recommended) | @riverpod calendarMonth(ref, int year, int month). Riverpod caches each month. | ✓ |
| Simple provider with setState | Single non-family provider, invalidated on month change. | |
| You decide | Let planner choose parameterization. | |

**User's choice:** Family provider parameterized by `(year, month)`.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Inside streakProvider (Recommended) | streakProvider owns the streak computation — pure Dart, testable. | ✓ |
| In widget build method | Widget computes streak from the full map inline. | |
| You decide | Let planner decide. | |

**User's choice:** Streak computation inside `streakProvider`.

---

## Month Navigation

| Option | Description | Selected |
|--------|-------------|----------|
| Local widget state (Recommended) | DateTime _focusedDay in State. Doesn't survive tab switches. | |
| Riverpod provider | focusedMonthProvider (keepAlive). Survives tab switches. | ✓ |
| You decide | Let planner pick. | |

**User's choice:** Riverpod provider — user prefers the focused month to survive tab switches.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Block future months (Recommended) | lastDay = end of current month. | ✓ |
| Allow future months | No lastDay constraint; future months show no data. | |
| You decide | Let planner decide upper bound. | |

**User's choice:** Block future months.

---

| Option | Description | Selected |
|--------|-------------|----------|
| No hard limit (Recommended) | firstDay = 2020-01-01 fixed. | |
| Limit to 12 months | firstDay = today minus 12 months. | |
| Limit to first entry date | Query earliest water entry; use as firstDay. | ✓ |

**User's choice:** Limit to first entry date — requires `getEarliestDateKey()` DAO/repository method.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Show current month immediately (Recommended) | Render calendar with fallback firstDay; update silently when query resolves. | |
| Show a loading spinner | Block HistoryScreen until earliest-date query resolves. | ✓ |
| You decide | Let planner handle loading state. | |

**User's choice:** Loading spinner — show full-screen loader until `getEarliestDateKey()` resolves.

---

## Claude's Discretion

- Exact Riverpod provider type for `focusedMonthProvider` (`StateProvider` vs `NotifierProvider`)
- `calendarMonthProvider` and `streakProvider` `keepAlive` vs auto-dispose
- AppBar title: `"History"`
- Error state copy: from `04-UI-SPEC.md`
- `_toDateKey(DateTime d)` helper — inline function vs shared extension

## Deferred Ideas

None — discussion stayed within phase scope.
