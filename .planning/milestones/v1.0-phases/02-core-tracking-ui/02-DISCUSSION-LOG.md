# Phase 2: Core Tracking UI - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-04
**Phase:** 2-core-tracking-ui
**Areas discussed:** Midnight reset behavior, Logging past 100% of goal, History & Settings stubs

---

## Midnight Reset Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-reset at midnight | Timer or AppLifecycleListener fires at midnight, re-evaluates todayDateKey(), ring resets | ✓ |
| Reset on next foreground/launch | Simpler: no timer. Widget rebuilds with new date key when user returns to app | |
| You decide | Leave to researcher/planner — pick the simpler approach | |

**User's choice:** Auto-reset at midnight

| Option | Description | Selected |
|--------|-------------|----------|
| Reset quietly (no animation) | Ring jumps to 0% instantly at midnight | ✓ |
| Fade out / fade in | Subtle crossfade from old day to new | |
| You decide | Leave animation detail to implementation | |

**User's choice:** Reset quietly — no animation

---

## Logging Past 100% of Goal

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — keep logging, ring stays green at 100% | Entry recorded, ring stays green/filled, center text overflows (e.g. "2200 / 2000 ml") | ✓ |
| Yes — keep logging, ring overflows past 100% | Arc extends beyond full circle (e.g. 110%) | |
| No — disable buttons after goal reached | Buttons greyed out once 100% hit | |

**User's choice:** Keep logging, ring caps at 100% visually (stays green), center text shows overflow amount

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — always allow undo | Undo works regardless of goal state | |
| Yes — but ring reverts to blue on undo below 100% | Stream-driven revert: ring goes blue if undo drops total below goal | ✓ |

**User's choice:** Undo always works; ring reverts automatically (stream-driven) if total drops below 100%

---

## History & Settings Stubs

| Option | Description | Selected |
|--------|-------------|----------|
| Coming soon label | Centered "Coming soon" text + screen title in AppBar | ✓ |
| Blank screen with AppBar title only | Just AppBar, nothing in body | |
| You decide | Anything that doesn't crash | |

**User's choice:** "Coming soon" centered text with AppBar title

| Option | Description | Selected |
|--------|-------------|----------|
| No — always start on Home | GoRouter initialLocation = '/'. No persistence. | ✓ |
| Yes — remember last tab | SharedPreferences stores last tab index | |

**User's choice:** Always start on Home tab — no tab persistence between launches

---

## Claude's Discretion

- SnackBar clearing between rapid taps (standard Material pattern preferred)
- Combining multiple Riverpod streams on HomeScreen (async coordination)
- Exact timer mechanism for midnight reset (Timer.periodic vs AppLifecycleListener)

## Deferred Ideas

None — discussion stayed within phase scope.
