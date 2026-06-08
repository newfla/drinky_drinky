# Phase 3: Settings - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-05
**Phase:** 3-settings
**Areas discussed:** Screen layout, Daily target input, Preset editing, Save behavior

---

## Screen Layout

| Option | Description | Selected |
|--------|-------------|----------|
| Grouped sections with headers | ListView with section headers. Standard Material settings. | |
| Flat list | Single scrollable list, no dividers. Simpler. | |
| Cards per group | Each section in its own elevated Card. | ✓ |

**User's choice:** Cards per group

### Follow-up: Number of cards

| Option | Description | Selected |
|--------|-------------|----------|
| 3 cards: Goal / Presets / Notifications | Daily Goal + Quick-Add Presets + Notifications | ✓ |
| 4 cards: Goal / Presets / Reminders / DND | Split Notifications into two cards | |
| 2 cards: Goal+Presets / Notifications | Merge Goal and Presets | |

**User's choice:** 3 cards (Daily Goal / Quick-Add Presets / Notifications)

### Follow-up: Section titles

| Option | Description | Selected |
|--------|-------------|----------|
| Visible section title above each card | Small caps label above each Card (e.g. "DAILY GOAL") | ✓ |
| No section titles | Row labels inside card are self-explanatory | |

**User's choice:** Visible section title above each card

### Follow-up: AppBar title

| Option | Description | Selected |
|--------|-------------|----------|
| "Settings" title | Matches tab label and current stub | ✓ |
| Large title style (LargeAppBar) | Collapses on scroll | |

**User's choice:** "Settings" title

### Follow-up: Row style inside cards

| Option | Description | Selected |
|--------|-------------|----------|
| ListTile rows | title + subtitle + trailing. Standard Material 3. | ✓ |
| Custom rows: label + control side by side | Inline label/control layout | |
| Stacked: label above, control below | Best for wide controls | |

**User's choice:** ListTile rows

---

## Daily Target Input

| Option | Description | Selected |
|--------|-------------|----------|
| Tap row → dialog with number field | AlertDialog with TextField | |
| Inline stepper (+/-) | IconButtons flanking current value in ListTile trailing | ✓ |
| Tap row → slider in bottom sheet | Slider in modal bottom sheet | |

**User's choice:** Inline stepper (+/-)

### Follow-up: Step size

| Option | Description | Selected |
|--------|-------------|----------|
| 250 ml per step | Common values reachable | |
| 100 ml per step | More precise | ✓ |
| 500 ml per step | Fast but coarse | |

**User's choice:** 100 ml per step

### Follow-up: Min/max range

| Option | Description | Selected |
|--------|-------------|----------|
| 500 ml – 5000 ml | Covers most users | |
| 500 ml – 10000 ml | Wider range | |
| 1000 ml – 4000 ml | Narrower | |

**User's choice:** 1000 ml – 10 000 ml (custom, typed as "Other")

---

## Preset Editing

| Option | Description | Selected |
|--------|-------------|----------|
| Tap row → dialog with number field | AlertDialog with TextField pre-filled | ✓ |
| Inline stepper (+/-) per preset row | All 4 steppers visible at once | |
| Tap row → bottom sheet with slider | Slider in modal bottom sheet | |

**User's choice:** Tap row → AlertDialog with TextField

### Follow-up: Valid range

| Option | Description | Selected |
|--------|-------------|----------|
| 50 ml – 2000 ml | Small sip to 2L bottle | ✓ |
| 100 ml – 1000 ml | More constrained | |
| No range — any positive integer | Maximum flexibility | |

**User's choice:** 50 ml – 2000 ml

### Follow-up: Row labeling

| Option | Description | Selected |
|--------|-------------|----------|
| Preset 1/2/3/4 with amount as subtitle | title='Preset N', subtitle='200 ml' | ✓ |
| Amount as title ('200 ml') with 'Tap to edit' subtitle | Amount is primary | |
| Mini home screen button preview | Visual chip matching home screen | |

**User's choice:** "Preset 1 / 2 / 3 / 4" with current amount as subtitle

---

## Save Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Live-save on every change | Each stepper/dialog/toggle writes immediately | ✓ |
| Explicit Save button | All changes committed at once | |
| Auto-save on screen exit | Saves when user navigates away | |

**User's choice:** Live-save on every change

### Follow-up: Preset dialog save

| Option | Description | Selected |
|--------|-------------|----------|
| Confirm saves immediately | Consistent with live-save | ✓ |
| Confirm stages change (needs main Save) | Not applicable given live-save | |

**User's choice:** Confirm in dialog saves immediately

### Follow-up: Notification interval control

| Option | Description | Selected |
|--------|-------------|----------|
| Dropdown with preset options | DropdownButton with 30/60/90 min, 2h, 3h, 4h | |
| Inline stepper in 30-min steps | 15 min – 4h | |
| Tap row → dialog with minutes field | Full flexibility | |

**User's choice:** Slider, 5-min steps, range 5 min – 4h (typed as "Other")

### Follow-up: DND time picker

| Option | Description | Selected |
|--------|-------------|----------|
| Tap row → Material showTimePicker() | Standard Material clock picker | ✓ |
| Inline time field (HH:MM) | Text input with validation | |
| Inline wheel pickers | iOS-style inline wheel | |

**User's choice:** Tap time row → showTimePicker()

### Follow-up: DND toggle behavior

| Option | Description | Selected |
|--------|-------------|----------|
| SwitchListTile; time rows greyed when off | Opacity 0.38 + IgnorePointer when disabled | ✓ |
| SwitchListTile; time rows always tappable | Simpler but confusing UX | |
| No toggle — DND always on | Removes disable option | |

**User's choice:** SwitchListTile at top; time rows greyed and non-tappable when off

---

## Claude's Discretion

- Card elevation and padding (use M3 defaults)
- Slider value label placement (above or below the slider)
- Error state color for preset dialog field (M3 `colorScheme.error`)
- 12h vs 24h time format for DND rows (match device system setting via `MediaQuery.alwaysUse24HourFormat`)

## Deferred Ideas

None — discussion stayed within phase scope.
