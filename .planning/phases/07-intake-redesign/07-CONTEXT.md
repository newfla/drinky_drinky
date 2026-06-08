# Phase 7: Intake Redesign - Context

**Gathered:** 2026-06-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 7 delivers the intake redesign across `home_screen.dart`, `settings_screen.dart`, and `app_database.dart`:
1. **FAB on HomeScreen** — remove the inline quick-add `Row` of `FilledButton`s; add a `FloatingActionButton` to the inner HomeScreen Scaffold
2. **Modal bottom sheet** — FAB opens a `showModalBottomSheet` with 3 preset buttons (sortOrder 0–2) and a custom ml `TextField`
3. **Preset reduction** — show only the first 3 presets (sortOrder 0–2) everywhere; update the seed in `app_database.dart` to 3 values (150/250/500 ml) for new installs; no DB migration for existing users
4. **Settings cleanup** — settings screen shows exactly 3 preset editing slots (drop the 4th)

No new screens, no navigation changes, no new DB tables, no migration files.

</domain>

<decisions>
## Implementation Decisions

### Sheet Close Behavior
- **D-01:** After tapping a preset button in the sheet, close the sheet first (`Navigator.pop()`), then show the SnackBar. Sheet and SnackBar are sequential, not simultaneous.
- **D-02:** After submitting a custom ml value, same behavior: sheet closes first, then SnackBar appears.
- **D-03:** Both preset tap and custom submit produce the same close-then-snackbar sequence — no exception for either path.

### 4th Preset Handling
- **D-04:** New seed = 3 presets: 150 ml / 250 ml / 500 ml (sortOrder 0, 1, 2). Change `app_database.dart` `onCreate` seed from 4 rows to 3 rows with these values.
- **D-05:** No Drift migration for existing users. Existing installs keep their 4 DB rows. The UI (sheet + settings) applies `LIMIT 3` / takes first 3 by sortOrder — the 4th preset is silently invisible.
- **D-06:** The `DrinkPresetDao.watchAllPresets()` returns all rows sorted by `sortOrder`. Callers (sheet widget, settings card) take `presets.take(3)` or equivalent at the presentation layer — no DAO change needed.

### Undo from Sheet
- **D-07:** The undo SnackBar format is identical to the current v1.0 format: `'+$amountMl ml added'`, with `SnackBarAction(label: 'Undo')`, `persist: false`, `duration: 5s`. No variation for sheet-originated additions.
- **D-08:** The undo logic (`_onQuickAdd` or equivalent) must capture `ScaffoldMessenger` and the `mounted` check before the `async` gap — same pattern already used in `home_screen.dart`.
- **D-09:** The sheet callback passes `amountMl` back to the HomeScreen widget which owns the insert + undo logic. The sheet itself is stateless with respect to DB writes.

### FAB Placement
- **D-10:** FAB goes on the **inner HomeScreen Scaffold**, not on the outer `StatefulShellRoute` Scaffold. This was flagged in Phase 6 PITFALLS.md to prevent it from floating above the bottom navigation bar on all screens.

### Custom ml Input (Claude's Discretion)
- **D-11:** Valid range: 1–9999 ml. Empty or zero → submit button/action disabled. Non-numeric input → rejected by `TextInputType.number` keyboard. No explicit error label needed — disabled state is sufficient feedback.
- **D-12:** Submit via a `FilledButton` in the sheet (not keyboard action alone) — consistent with the preset buttons' visual weight.

### Claude's Discretion
- Exact Flutter widget: `showModalBottomSheet` with standard drag handle — no custom `DraggableScrollableSheet` needed (content is short)
- Whether to extract the sheet content into a separate `_IntakeBottomSheet` widget or build inline
- TextField `controller` disposal strategy

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope
- `.planning/REQUIREMENTS.md` — INTAKE-01, INTAKE-02, INTAKE-03, INTAKE-04 requirements
- `.planning/ROADMAP.md` — Phase 7 goal, success criteria, dependencies

### Files that change in this phase
- `lib/presentation/screens/home_screen.dart` — remove inline quick-add Row; add FAB; wire sheet callback to existing `_onQuickAdd`-equivalent logic
- `lib/presentation/screens/settings_screen.dart` — show only 3 preset editing slots (drop 4th)
- `lib/data/database/app_database.dart` — change `onCreate` seed from 4 presets (200/300/400/500) to 3 presets (150/250/500)

### Key context from prior phases
- `.planning/phases/06-bug-fix-theme-l-display/06-CONTEXT.md` — D-07 notes FAB must go on inner Scaffold (PITFALLS.md finding)
- `.planning/phases/06-bug-fix-theme-l-display/06-01-SUMMARY.md` — confirms DynamicColorBuilder integration; theme tokens available for sheet styling

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `home_screen.dart` `_onQuickAdd(int amountMl)` — handles DB insert + undo SnackBar + `mounted` guard + `capturedKey` pattern. The sheet callback should funnel into this same method (or its extracted equivalent).
- `lib/presentation/widgets/preset_edit_dialog.dart` — existing dialog for editing a single preset; referenced by settings screen. Not changed in this phase.
- `DrinkPresetDao.watchAllPresets()` — returns `Stream<List<DrinkPreset>>` ordered by sortOrder ASC. No change needed; callers use `.take(3)`.

### Established Patterns
- `ScaffoldMessenger.of(context)` captured before async gap in `_onQuickAdd` — this pattern must be replicated in the sheet callback path.
- `ref.watch(drinkPresetsProvider)` in `HomeScreen.build()` already loads all presets. Sheet can receive the already-loaded list rather than re-watching the provider internally.
- `showModalBottomSheet` is the standard Flutter pattern; no custom sheet package needed.

### Integration Points
- `home_screen.dart` line ~152–165: existing `Row` of `FilledButton`s — this block is removed and replaced by FAB wiring
- `app_database.dart` line ~44–50: `onCreate` seed block — 4 `DrinkPresetsCompanion.insert(...)` calls reduced to 3
- `settings_screen.dart` `_presetsCard()` — currently maps `presets` to a full list; needs `.take(3)` applied

</code_context>

<specifics>
## Specific Ideas

- Preset values for new seed: 150 ml / 250 ml / 500 ml (bicchiere piccolo, bicchiere standard, bottiglietta — scelta utente)
- Sheet close order: `Navigator.pop()` → `showSnackBar()` (sequential, not simultaneous)
- Existing users with 4 DB presets: no migration, 4th is silently hidden via `.take(3)` at UI layer

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 7-Intake Redesign*
*Context gathered: 2026-06-08*
