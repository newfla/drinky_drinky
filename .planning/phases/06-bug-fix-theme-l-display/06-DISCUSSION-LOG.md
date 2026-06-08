# Phase 6: Bug Fix + Theme + L-Display - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-08
**Phase:** 6-Bug Fix + Theme + L-Display
**Areas discussed:** Fallback seed color, Dark mode semantic colors, L-display ring format

---

## Fallback Seed Color

| Option | Description | Selected |
|--------|-------------|----------|
| Keep blue (current) | `ColorScheme.fromSeed(seedColor: Colors.blue)` — neutral, unchanged from v1.0 | ✓ |
| Switch to teal/cyan | `ColorScheme.fromSeed(seedColor: Colors.teal)` — matches water theme | |
| You decide | Pick whatever fits the water theme best | |

**User's choice:** Keep blue (current)
**Notes:** No theme change for non-dynamic-color devices; v1.0 users see the same palette on iOS and Android <12.

---

## Dark Mode Semantic Colors

| Option | Description | Selected |
|--------|-------------|----------|
| Adapt shades for dark mode | Light: shade600/shade700. Dark: shade400 for all three semantic colors | ✓ |
| Keep same shades in both modes | Colors.green.shade600 / red.shade600 / orange.shade700 in both modes | |
| You decide | Choose whatever looks best | |

**User's choice:** Adapt shades for dark mode
**Notes:** Three semantic colors affected — green (goal met), red (goal missed), orange (partial/streak). Light stays at current shade values; dark mode uses shade400 variants for legibility.

---

## L-Display Ring Format

| Option | Description | Selected |
|--------|-------------|----------|
| Both in L: '1,75 L / 2,00 L' | Both values with unit | |
| Unit once: '1,75 / 2,00 L' | Unit only at the end | ✓ |
| Two lines | Splits current and goal onto two lines | |

**User's choice:** Unit once: `'1,75 / 2,00 L'`
**Notes:** More compact. Unit appears once at the end. Locale-aware decimal separator via `intl.NumberFormat`.

---

## Goal Reached Text

| Option | Description | Selected |
|--------|-------------|----------|
| Keep 'Goal reached!' text | Current behavior | ✓ |
| Show L value + checkmark: '2,00 L ✓' | Consistent with L format | |
| Show L value only: '2,00 L' | Same format as in-progress | |

**User's choice:** Keep `'Goal reached!'` text
**Notes:** Celebratory message retained unchanged.

---

## Claude's Discretion

- Exact `intl.NumberFormat` API variant (locale-aware, 2 decimal places)
- Whether to extract a brightness-check helper or inline it

## Deferred Ideas

None.
