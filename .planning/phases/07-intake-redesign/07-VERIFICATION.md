---
phase: 07-intake-redesign
verified: 2026-06-08T15:30:00Z
status: passed
score: 10/10 must-haves verified
overrides_applied: 0
human_verification:
  - test: "Tap the FAB on a real device (iOS or Android); confirm the modal bottom sheet appears with a drag handle and exactly 3 preset buttons"
    expected: "Sheet slides up with drag handle, 3 FilledButtons labeled '+150 ml', '+250 ml', '+500 ml'; sheet opens within ~200ms of FAB tap"
    why_human: "showModalBottomSheet animation, showDragHandle rendering, and correct preset labels cannot be asserted with grep"
  - test: "Tap a preset button in the sheet; confirm (a) sheet closes before the SnackBar appears, (b) the SnackBar reads '+N ml added' and has an UNDO action"
    expected: "Sheet dismisses fully first, then SnackBar slides in from bottom. No SnackBar visible while sheet is still open."
    why_human: "Sequential close-then-snackbar order (D-01/D-02/D-03) and SnackBar content require visual inspection"
  - test: "In the sheet, type a valid amount (e.g. 250) and tap Add; confirm entry is logged, sheet closes, SnackBar appears"
    expected: "Sheet closes, '+250 ml added' SnackBar with UNDO appears, timeline updates with the entry"
    why_human: "End-to-end interaction through numeric keyboard requires a device"
  - test: "In the sheet, try the submit button with empty field, '0', and '10000'; confirm the Add button is disabled in each case"
    expected: "Add button is greyed out / non-interactive for all three inputs"
    why_human: "Button disabled state depends on runtime validation logic triggered by TextEditingController; cannot be exercised without rendering"
  - test: "Verify keyboard does not obscure the Add button on a small device (e.g. iPhone SE or equivalent small Android)"
    expected: "Add button remains visible and tappable when the numeric keyboard is open; sheet scrolls or expands if needed"
    why_human: "isScrollControlled behavior and keyboard inset handling require a physical small-screen device — Pitfall 4 from RESEARCH.md"
  - test: "Open Settings and count preset editing slots; confirm exactly 3 slots are visible"
    expected: "Three ListTile rows (Preset 1 / Preset 2 / Preset 3); no fourth row"
    why_human: "Visual confirmation that .take(3) rendering is correct; a stub with an empty list would also produce 0 items and not crash"
  - test: "Fresh-install the app (or clear app data) and confirm the 3 default presets seed correctly (150, 250, 500 ml)"
    expected: "Settings preset card shows 150 ml / 250 ml / 500 ml on first launch"
    why_human: "Seed data executes only on onCreate; requires a clean-install or DB wipe to verify on device"
---

# Phase 7: Intake Redesign — Verification Report

**Phase Goal:** Users add water intake through a single FAB that opens a modal bottom sheet with 3 configurable presets and a custom ml input, replacing the previous inline quick-add buttons
**Verified:** 2026-06-08T15:30:00Z
**Status:** HUMAN_NEEDED
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|---------|
| 1 | Home screen no longer shows inline quick-add buttons | VERIFIED | `_buildContent` signature takes no `presets` param; no `Row` of `FilledButton`s in method body; `Quick-Add Row` comment absent (grep returns 0 matches) |
| 2 | A FloatingActionButton is visible on the home screen | VERIFIED | `floatingActionButton: FloatingActionButton(tooltip: 'Add water', ...)` on inner HomeScreen `Scaffold` at line 92 — correct placement per D-10 |
| 3 | Tapping the FAB opens a modal bottom sheet with a drag handle | VERIFIED | `showModalBottomSheet(showDragHandle: true, useSafeArea: true, ...)` at lines 96-104; `_IntakeBottomSheet` passed as builder |
| 4 | The bottom sheet shows exactly 3 preset buttons matching the user's first 3 presets by sortOrder | VERIFIED | FAB `onPressed` passes `presets.take(3).toList()` (line 101); `_IntakeBottomSheet.build()` maps `widget.presets` to `Expanded(FilledButton(...))` — count bounded by the caller's `.take(3)` |
| 5 | Tapping a preset button closes the sheet, then shows a SnackBar with undo | VERIFIED | Preset `onPressed` at line 319: `Navigator.pop(context)` first, then `widget.onAdd(preset.amountMl)`, which calls `_onQuickAdd` on the parent; `_onQuickAdd` shows SnackBar with `SnackBarAction(label: 'UNDO')` |
| 6 | The bottom sheet has a custom ml text field with numeric keyboard | VERIFIED | `TextField(controller: _controller, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: 'Custom amount', suffixText: 'ml'))` at lines 329-337 |
| 7 | Typing a valid amount (1-9999) and tapping Add closes the sheet, then shows a SnackBar with undo | VERIFIED | Submit `FilledButton.onPressed` at lines 343-347: `Navigator.pop(context)` then `widget.onAdd(parsed)` — same close-then-callback sequence as presets |
| 8 | The Add button is disabled when the text field is empty, zero, or outside 1-9999 | VERIFIED | `final parsed = int.tryParse(_controller.text); final isValid = parsed != null && parsed >= 1 && parsed <= 9999;` — `onPressed: isValid ? () {...} : null` disables button when `isValid` is false |
| 9 | Settings screen shows exactly 3 preset editing slots | VERIFIED | `presets.take(3).map((preset) {...})` at line 129 of `settings_screen.dart` |
| 10 | New installs seed 3 presets (150/250/500 ml) instead of 4 | VERIFIED | `app_database.dart` lines 46-50: exactly 3 `DrinkPresetsCompanion.insert` calls with `amountMl: 150/250/500`; old values 200/300/400 and `sortOrder: 3` are absent |

**Score:** 10/10 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/presentation/screens/home_screen.dart` | FAB, `_IntakeBottomSheet` widget, updated `_buildContent` without Row, updated empty/error copy | VERIFIED | 357 lines; contains `_IntakeBottomSheet` class (5 grep matches), `floatingActionButton` property, `showModalBottomSheet`, 2x `Navigator.pop`; empty state copy "Tap the + button"; error state "Please restart the app." |
| `lib/presentation/screens/settings_screen.dart` | Preset card limited to 3 slots via `.take(3)` | VERIFIED | `.take(3)` present at line 129 in `_presetsCard` |
| `lib/data/database/app_database.dart` | 3-preset seed data (150/250/500 ml) | VERIFIED | Exactly 3 seed rows; old 200/300/400/sortOrder:3 absent |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `home_screen.dart` FAB `onPressed` | `showModalBottomSheet` | Direct call in `onPressed` lambda, line 96 | WIRED | `showModalBottomSheet(context: context, showDragHandle: true, useSafeArea: true, builder: (_) => _IntakeBottomSheet(...))` |
| `_IntakeBottomSheet.onAdd` callback | `home_screen.dart _onQuickAdd` | `onAdd: _onQuickAdd` passed in FAB `onPressed`, lines 102-103 | WIRED | Sheet calls `widget.onAdd(preset.amountMl)` / `widget.onAdd(parsed)`; parent wires `onAdd` to `_onQuickAdd` |
| `settings_screen.dart _presetsCard` | `drinkPresetsProvider` | `ref.watch(drinkPresetsProvider)` at line 41; result passed to `_presetsCard` | WIRED | `presetsAsync.value ?? []` used in `build()` data branch; passed as `presets` param with `.take(3)` at line 129 |

---

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|-------------------|--------|
| `home_screen.dart` — preset buttons in `_IntakeBottomSheet` | `widget.presets` | `drinkPresetsProvider` → `settingsRepository.watchPresets()` → `DrinkPresetDao.watchAllPresets()` → Drift SQLite SELECT ordered by `sortOrder` | Yes — `(select(drinkPresets)..orderBy([...asc(t.sortOrder)])).watch()` | FLOWING |
| `home_screen.dart` — `_onQuickAdd` insert + SnackBar | `amountMl` (int) | Passed from sheet callback; written to DB via `repo.insertEntry(amountMl, ...)` | Yes — actual Drift insert | FLOWING |
| `settings_screen.dart` — preset slots | `presets` (List) | Same `drinkPresetsProvider` stream as home screen | Yes — same DB stream | FLOWING |

---

### Behavioral Spot-Checks

Flutter-specific UI code cannot be exercised without a running app. Static analysis was used as a proxy.

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| No analysis issues in modified files | `flutter analyze home_screen.dart settings_screen.dart app_database.dart` | "No issues found! (ran in 2.1s)" | PASS |
| All 3 commit hashes exist | `git show --oneline 9410140 d206ffa 36a3128` | All 3 commits resolve to expected diffs | PASS |

---

### Probe Execution

No probe scripts declared for this phase. Step 7c: SKIPPED (no `scripts/*/tests/probe-*.sh` present for UI-only phase).

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|---------|
| INTAKE-01 | 07-01-PLAN.md | Home screen quick-add buttons removed; FAB opens add-intake interface | SATISFIED | `floatingActionButton` present; quick-add Row absent from `_buildContent` |
| INTAKE-02 | 07-01-PLAN.md | Modal bottom sheet displays 3 configurable preset buttons | SATISFIED | Sheet passes `presets.take(3).toList()` to `_IntakeBottomSheet`; preset `FilledButton`s rendered from `widget.presets.map(...)` |
| INTAKE-03 | 07-01-PLAN.md | Sheet includes custom ml text field; submitting adds entry and closes sheet | SATISFIED | `TextField` with `TextInputType.number`; `FilledButton` disabled guard; `Navigator.pop` + `widget.onAdd(parsed)` on submit |
| INTAKE-04 | 07-01-PLAN.md | Settings preset editing reduced to 3 slots; 4th slot retired | SATISFIED | `presets.take(3).map(...)` at settings_screen.dart line 129 |

All 4 requirements INTAKE-01 through INTAKE-04 are satisfied.

---

### Anti-Patterns Found

Scanned files: `home_screen.dart`, `settings_screen.dart`, `app_database.dart`, `drink_preset_dao_test.dart`

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | — | — | None found |

No `TBD`, `FIXME`, `XXX`, `TODO`, `HACK`, `PLACEHOLDER`, debt markers, empty handlers, or stub returns detected in any modified file.

---

### Human Verification Required

The following items require device-level or visual testing. All automated truths are VERIFIED; the phase goal is structurally sound in the codebase. These checks guard against runtime rendering and interaction issues that grep cannot surface.

#### 1. Modal bottom sheet opens with drag handle and 3 preset buttons

**Test:** Tap the FAB on a running iOS or Android device. Observe the bottom sheet.
**Expected:** Sheet slides up, shows a drag handle at the top, then 3 `FilledButton`s labeled '+150 ml', '+250 ml', '+500 ml'.
**Why human:** `showDragHandle: true` and sheet animation are runtime behaviors; preset labels depend on seeded DB values.

#### 2. Close-then-SnackBar order for preset taps (D-01/D-03)

**Test:** Tap a preset button in the sheet; watch the transition.
**Expected:** Sheet fully dismisses before the SnackBar appears. SnackBar reads '+N ml added' with an UNDO action.
**Why human:** Sequential animation timing (sheet close → SnackBar appear) requires visual inspection on a device.

#### 3. Custom amount add flow (D-02/D-03)

**Test:** Open the sheet, type a valid amount (e.g. 500) in the text field, tap Add.
**Expected:** Sheet closes, '+500 ml added' SnackBar appears, timeline list gains a new entry.
**Why human:** TextField interaction, submit flow, and timeline update require a running app.

#### 4. Add button disabled for invalid inputs (D-11)

**Test:** In the sheet, try: empty field / '0' / '10000' / '-1'.
**Expected:** Add button is visually disabled (greyed out, not tappable) for all invalid inputs.
**Why human:** Material 3 disabled button appearance and `onPressed: null` effect require visual confirmation.

#### 5. Keyboard does not cover Add button on small screens (Pitfall 4 from RESEARCH.md)

**Test:** Open the sheet on a small device (iPhone SE or equivalent) and tap the custom amount field.
**Expected:** After the keyboard opens, the Add button remains visible and tappable. No content clipping.
**Why human:** `isScrollControlled: false` (default) may clip content on small screens when the keyboard is open. This is a known risk documented in RESEARCH.md Pitfall 4.

#### 6. Settings screen shows exactly 3 preset slots

**Test:** Navigate to Settings; inspect the QUICK-ADD PRESETS card.
**Expected:** Exactly 3 ListTile rows (Preset 1, Preset 2, Preset 3). No 4th row visible.
**Why human:** Visual count of rendered ListTile widgets requires a running app.

#### 7. Fresh-install seed data (D-04)

**Test:** Uninstall + reinstall (or clear app data); open Settings.
**Expected:** Preset 1 = 150 ml, Preset 2 = 250 ml, Preset 3 = 500 ml on first launch.
**Why human:** `onCreate` seed only runs on first database creation; cannot be observed without an actual install.

---

## Gaps Summary

No automated gaps. All 10 must-haves are VERIFIED in the codebase. All 4 requirement IDs (INTAKE-01 through INTAKE-04) are satisfied. No anti-patterns or debt markers found. Status is `human_needed` because 7 interaction/rendering behaviors (items 1-7 above) require device-level verification and cannot be asserted statically.

The one architectural risk flagged by RESEARCH.md (Pitfall 4: keyboard covering the Add button on small screens) has not been mitigated in code — `isScrollControlled` is not set (defaults to `false`). Human test item 5 is the gate for this risk.

---

_Verified: 2026-06-08T15:30:00Z_
_Verifier: Claude (gsd-verifier)_
