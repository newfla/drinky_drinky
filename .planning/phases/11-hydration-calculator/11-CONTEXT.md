# Phase 11: Hydration Calculator - Context

**Gathered:** 2026-06-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 11 delivers the Hydration Calculator — a new screen where the user inputs sex, weight (kg), and climate level (5 options) to receive a personalized daily hydration recommendation (ml). The calculation is entirely local (no network). The screen appears automatically on first launch (after the permission screen, before home), and is re-accessible from Settings. A "Usa come target" button writes the recommendation to `target_history` via the already-implemented `updateTargetWithHistory()` from Phase 10.

Delivers:
1. `HydrationCalculatorScreen` — full-screen form with SegmentedButton (sex), Slider (climate), TextFormField (weight), live recommendation display, privacy disclaimer, "Usa come target" button
2. First-launch routing gate: new `drinky_calculatorShown` SharedPreferences key + second redirect in GoRouter
3. `/calculator` top-level GoRoute (outside bottom nav shell) — consistent with `/permission`
4. Settings tile "Ricalcola raccomandazione idratazione" → `context.push('/calculator')`
5. Local formula: weight × sex_factor × climate_multiplier, rounded to nearest 50ml, clamped to 1000–4000ml

Does NOT deliver: persistence of calculator inputs (sex/weight/climate are never saved — privacy by design), any network calls, changes to the formula after shipping.

</domain>

<decisions>
## Implementation Decisions

### First-launch Routing

- **D-01:** Add `drinky_calculatorShown` as a new SharedPreferences key. Extend the GoRouter `redirect` guard: if `drinky_permissionScreenShown` is true AND `drinky_calculatorShown` is false, redirect to `/calculator`. Sequence: `/permission` → `/calculator` → `/`. The calculator screen sets `drinky_calculatorShown = true` on any exit path (both "Usa come target" and "Salta").
- **D-02:** `/calculator` is a **top-level GoRoute** at the same level as `/permission` — outside the `StatefulShellRoute`. No bottom NavigationBar is visible when the calculator is shown during onboarding. Same architectural pattern as the existing permission screen.
- **D-03:** When opened from Settings (CALC-03): `context.push('/calculator')`. GoRouter push preserves the Settings stack; back button returns to Settings. On "Usa come target" in Settings context: call `updateTargetWithHistory()` then `context.pop()` to return to Settings.

### Formula

- **D-04:** Formula: `result_ml = round(weight_kg × sex_factor × climate_multiplier / 50) × 50`
  - Sex factors: Maschio = 35 ml/kg, Femmina = 31 ml/kg, Altro = 33 ml/kg
  - Climate multipliers: Freddo = 1.0, Mite = 1.05, Caldo = 1.1, Molto caldo = 1.2, Afoso = 1.3
- **D-05:** Clamp result after rounding: min 1000ml, max 4000ml. Prevents unreasonable results from edge-case inputs.

### Input Widgets

- **D-06:** Sex input: Material 3 `SegmentedButton<String>` with 3 segments — `Maschio`, `Femmina`, `Altro`. One segment is always selected (no deselect); default selection is left to Claude's discretion (no preselection, or Maschio as default).
- **D-07:** Climate input: `Slider` with `divisions: 4`, `min: 0`, `max: 4`. Integer value 0–4 maps to [Freddo, Mite, Caldo, Molto caldo, Afoso]. Display the label text corresponding to the current integer value below or on the slider.
- **D-08:** Live calculation — the recommendation (and "Usa come target" button state) update automatically whenever sex, weight, or climate changes. No explicit "Calcola" button. "Usa come target" is enabled only when all inputs are valid: sex selected, weight is a valid positive integer (1–300 kg range).

### Post-"Usa come target" Flow

- **D-09:** On "Usa come target" (first-launch context): call `updateTargetWithHistory(recommendedMl)`, set `drinky_calculatorShown = true`, show a SnackBar with the new target value (e.g., `'Target aggiornato a 2 350 ml'`), then `context.go('/')` to home. User sees the updated progress ring immediately.
- **D-10:** First-launch dismiss ("Salta"): `TextButton` labeled "Salta" placed below the "Usa come target" button. Tapping it sets `drinky_calculatorShown = true` and navigates to `/` without calling `updateTargetWithHistory()`. Target remains unchanged.
- **D-11:** Settings context dismiss: standard AppBar back button only — no "Salta" button. On "Usa come target" in Settings context: call `updateTargetWithHistory(recommendedMl)`, show SnackBar, then `context.pop()` to return to Settings. No `drinky_calculatorShown` flag logic needed (already set).

### Claude's Discretion

- AppBar title for the calculator screen (suggestion: "Calcolatore idratazione")
- Whether sex SegmentedButton has a preselected default or starts unselected (if unselected, "Usa come target" remains disabled until sex is chosen)
- Weight TextFormField: keyboard type `TextInputType.number`, inputFormatters for positive integers, input range validation message text
- Exact positioning of the privacy disclaimer text (below the form, above the buttons)
- SnackBar wording for target confirmation
- Whether the recommendation is shown as a large text display (e.g., "2 350 ml") or a Card widget

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 10 artifacts (target write path — MUST READ)
- `lib/data/repositories/settings_repository.dart` — `updateTargetWithHistory(int newTargetMl)` method: dual-write to UserSettings + target_history via applyFromTomorrow logic. Phase 11 calls this from "Usa come target".
- `.planning/phases/10-target-history-integration/10-CONTEXT.md` — D-06: `updateTargetWithHistory()` spec; D-04/D-05: applyFromTomorrow toggle decisions (Phase 11 inherits the "apply from today" default for the calculator path)

### Router and first-launch patterns (MUST READ)
- `lib/core/router/app_router.dart` — Existing GoRouter with redirect guard using `drinky_permissionScreenShown` SharedPreferences key. Phase 11 extends this guard with `drinky_calculatorShown`. The `/permission` top-level GoRoute is the structural model for `/calculator`.
- `lib/presentation/screens/permission_screen.dart` — Pattern for top-level onboarding screens: ConsumerStatefulWidget, SharedPreferences write on both action paths, `context.go('/')` navigation.

### Requirements
- `.planning/REQUIREMENTS.md` — CALC-01 through CALC-04 in scope for Phase 11. Privacy constraint: sex/weight/climate must never be persisted (CALC-04 out-of-scope note).
- `.planning/PROJECT.md` — "Calculator inputs (sex/weight/climate) must NOT be persisted — privacy by design" in Decisions section

### Existing provider pattern
- `lib/core/providers/stream_providers.dart` — Provider patterns for Riverpod code-gen; `userSettingsProvider` as reference for watch patterns used in SettingsScreen
- `lib/presentation/screens/settings_screen.dart` — Existing tile structure; Phase 11 adds a `ListTile` for "Ricalcola raccomandazione idratazione" that calls `context.push('/calculator')`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `updateTargetWithHistory()` in `lib/data/repositories/settings_repository.dart` — the exact write method Phase 11 calls for "Usa come target"; already tested in Phase 10
- `drinky_permissionScreenShown` SharedPreferences key pattern in `app_router.dart` and `permission_screen.dart` — template for `drinky_calculatorShown`
- `SegmentedButton` — used in Phase 10 settings for `applyFromTomorrow` toggle; same widget for sex selection

### Established Patterns
- **Top-level GoRoute for onboarding screens**: `/permission` is outside `StatefulShellRoute` — no bottom nav. Same architecture for `/calculator`.
- **Riverpod code-gen**: `@riverpod` / `@Riverpod(keepAlive: true)` annotations with `dart run build_runner build --delete-conflicting-outputs`. Calculator screen may not need any new providers if state is local (`ConsumerStatefulWidget` with `setState` is sufficient since inputs are ephemeral and must not be persisted).
- **ConsumerStatefulWidget for interactive screens**: Both PermissionScreen and SettingsScreen use this pattern. Calculator screen follows suit.
- **SharedPreferences for first-launch flags**: Namespaced key `drinky_*` convention already established.

### Integration Points
- `lib/core/router/app_router.dart:23-30` — The redirect guard block: add `drinky_calculatorShown` check here, after the existing permission check.
- `lib/presentation/screens/settings_screen.dart` — Add a `ListTile` in the appropriate section for the "Ricalcola" entry point.
- `lib/core/router/app_router.dart:35` — Add `/calculator` GoRoute alongside `/permission` (before the `StatefulShellRoute`).

</code_context>

<specifics>
## Specific Ideas

- The climate Slider maps integer value (0–4) to climate label text shown adjacent: `['Freddo', 'Mite', 'Caldo', 'Molto caldo', 'Afoso'][sliderValue.round()]`. Display the label below the Slider so the user always knows their current selection.
- The redirect guard order matters: check `drinky_permissionScreenShown` first (if false → `/permission`), then check `drinky_calculatorShown` (if false → `/calculator`). Only when both are true does the user reach home.
- `updateTargetWithHistory()` already handles the `applyFromTomorrow` toggle — the calculator always applies "from today" implicitly (the setting in UserSettings controls this, and the default is `applyFromTomorrow = false` = "today"). No special-casing needed in the calculator.
- Weight field: `TextEditingController` with `TextInputAction.done` and `onChanged` callback that triggers the live calculation. Parse with `int.tryParse()` — null or <=0 disables the "Usa come target" button.

</specifics>

<deferred>
## Deferred Ideas

- Saving calculator inputs across sessions (sex/weight/climate pre-filled on re-open from Settings) — explicitly out of scope by CALC-04 / privacy constraint. Could be added in v2 with explicit user consent.
- fl_chart-based BMI or hydration trend visualization on the calculator screen — future milestone.
- Metric/imperial toggle (kg vs lbs) — ml/kg for v1; fl oz support deferred.
- Animated result display (counter animation from 0 to the recommendation) — nice-to-have, defer to v2 polish.

</deferred>

---

*Phase: 11-hydration-calculator*
*Context gathered: 2026-06-15*
