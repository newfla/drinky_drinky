# Phase 11: Hydration Calculator - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-15
**Phase:** 11-hydration-calculator
**Areas discussed:** First-launch routing, Formula, Input widget style, Post-"Usa come target" flow

---

## First-launch routing

| Option | Description | Selected |
|--------|-------------|----------|
| New SharedPrefs key + second redirect | Add `drinky_calculatorShown` key + second guard in GoRouter redirect. Both keys must be true to reach home. | ✓ |
| PermissionScreen navigates to /calculator | Both PermissionScreen buttons navigate to `/calculator` instead of `/`. No second redirect needed. | |
| You decide | Pick whichever fits the existing router architecture best. | |

**User's choice:** New SharedPrefs key + second redirect
**Notes:** -

---

| Option | Description | Selected |
|--------|-------------|----------|
| Top-level GoRoute at /calculator (outside bottom nav shell) | Same as /permission — no bottom NavigationBar during onboarding. Consistent with existing pattern. | ✓ |
| Nested under StatefulShellRoute (with bottom nav visible) | Would show bottom nav during first-launch onboarding. | |

**User's choice:** Top-level GoRoute at /calculator (outside bottom nav shell)
**Notes:** -

---

| Option | Description | Selected |
|--------|-------------|----------|
| context.push('/calculator') from Settings tile | GoRouter push — back button returns to Settings. | ✓ |
| context.go('/calculator') from Settings tile | GoRouter go — replaces the stack. | |
| Modal route / showModalBottomSheet or showDialog | Show calculator as a modal over Settings. | |

**User's choice:** context.push('/calculator') from Settings tile
**Notes:** -

---

## Formula

| Option | Description | Selected |
|--------|-------------|----------|
| Weight × sex_factor (ml/kg), then climate multiplier | Male=35, Female=31, Other=33 ml/kg × climate multiplier, rounded to nearest 50ml. | ✓ |
| EFSA total water intake (TWI) — fixed base by sex + climate bump | EFSA recommends 2500ml men / 2000ml women; adjust for climate. Less weight-personalized. | |
| You define it | User provides exact formula values. | |

**User's choice:** Weight × sex_factor (ml/kg), then climate multiplier
**Notes:** Specific values confirmed in next question.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Those look fine — use them as-is | Male=35ml/kg, Female=31ml/kg, Other=33ml/kg. Freddo×1.0, Mite×1.05, Caldo×1.1, Molto caldo×1.2, Afoso×1.3. Result rounded to nearest 50ml. | ✓ |
| Adjust the sex factors | Different ml/kg values. | |
| Adjust the climate multipliers | Different multipliers for 5 climate levels. | |

**User's choice:** Those look fine — use them as-is
**Notes:** -

---

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — clamp to 1000ml–4000ml | Prevents absurd results. Floor 1000ml, ceiling 4000ml. Applied after rounding. | ✓ |
| No clamping — show raw result | Formula result shown as-is; weight validation is enough. | |

**User's choice:** Yes — clamp to 1000ml–4000ml
**Notes:** -

---

## Input widget style

| Option | Description | Selected |
|--------|-------------|----------|
| SegmentedButton with 3 segments | Material 3 SegmentedButton — Maschio / Femmina / Altro. | ✓ |
| RadioListTile (one per row) | Three radio tiles stacked vertically. | |
| DropdownButton | Single dropdown hiding options behind a tap. | |

**User's choice:** SegmentedButton with 3 segments
**Notes:** -

---

| Option | Description | Selected |
|--------|-------------|----------|
| DropdownButton / DropdownMenu | Standard Material dropdown for 5 climate options. | |
| Wrap of ChoiceChip | 5 chips wrapping across 2 rows. | |
| Slider with 5 labeled steps | Discrete Slider with divisions=4 and labels at each stop. | ✓ |

**User's choice:** Slider with 5 labeled steps
**Notes:** Shows the gradient from cold to humid intuitively.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Live calculation — result updates as inputs change | Recommendation updates instantly; "Usa come target" enabled when all inputs valid. | ✓ |
| Explicit 'Calcola' button | User fills form then taps button. Two-step flow. | |

**User's choice:** Live calculation — result updates as inputs change
**Notes:** -

---

## Post-"Usa come target" flow

| Option | Description | Selected |
|--------|-------------|----------|
| SnackBar confirmation + navigate to home screen | Call updateTargetWithHistory, show SnackBar, context.go('/'). | ✓ |
| SnackBar confirmation + stay on calculator | Same call + SnackBar but stay on calculator screen. | |
| Dialog confirmation first, then navigate to home | AlertDialog before applying, then navigate. | |

**User's choice:** SnackBar confirmation + navigate to home screen
**Notes:** User sees updated progress ring immediately on home.

---

| Option | Description | Selected |
|--------|-------------|----------|
| TextButton 'Salta' below 'Usa come target' | Sets drinky_calculatorShown=true, navigates to / without changing target. | ✓ |
| AppBar back arrow / close icon only | Implicit dismissal via AppBar. | |
| No explicit skip — 'Usa come target' is required | Forces input; not recommended. | |

**User's choice:** TextButton 'Salta' below 'Usa come target'
**Notes:** First-launch only.

---

| Option | Description | Selected |
|--------|-------------|----------|
| AppBar back button only — no 'Salta' | Standard push navigation back to Settings. 'Usa come target' calls updateTargetWithHistory + context.pop(). | ✓ |
| Both back button and explicit 'Annulla' button | Redundant but very explicit. | |

**User's choice:** AppBar back button only — no 'Salta'
**Notes:** Settings context — no need for Salta, back button serves as cancel.

---

## Claude's Discretion

- AppBar title for the calculator screen
- Whether sex SegmentedButton has a preselected default or starts unselected
- Weight TextFormField keyboard type, input range validation message text
- Exact positioning of the privacy disclaimer text
- SnackBar wording for target confirmation
- Whether recommendation is shown as large text or a Card widget

## Deferred Ideas

- Saving calculator inputs across sessions (sex/weight/climate) — privacy constraint, CALC-04 out of scope
- fl_chart-based hydration trend visualization on calculator screen
- Metric/imperial toggle (kg vs lbs) — ml/kg for v1
- Animated result display (counter animation from 0 to recommendation)
