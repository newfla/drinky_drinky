# Phase 6: Bug Fix + Theme + L-Display - Context

**Gathered:** 2026-06-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 6 delivers three independent changes across `main.dart`, `home_screen.dart`, and `history_screen.dart`:
1. **SnackBar bug fix** — add `persist: false` to the undo SnackBar (one-line fix for Flutter 3.38 breaking change)
2. **L-display** — convert the progress ring center text from ml integers to locale-aware liters using `intl.NumberFormat`
3. **Material You + dark mode** — wrap `MaterialApp.router` in `DynamicColorBuilder`; provide a static blue seed fallback; add `darkTheme`; adapt hardcoded semantic colors for dark surfaces

No new screens, no navigation changes, no database changes, no notification changes.

</domain>

<decisions>
## Implementation Decisions

### Theming (Material You)

- **D-01:** `DynamicColorBuilder` wraps `MaterialApp.router` inside `DrinkyDrinkyApp.build()`, below `ProviderScope`. This is the only widget-tree change needed.
- **D-02:** Replace `colorSchemeSeed: Colors.blue` with `colorScheme: lightDynamic ?? ColorScheme.fromSeed(seedColor: Colors.blue)`. Cannot use both `colorScheme` and `colorSchemeSeed` simultaneously (Flutter assertion error).
- **D-03:** Add `darkTheme: ThemeData(colorScheme: darkDynamic ?? ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark))` to `MaterialApp.router`.
- **D-04:** `themeMode: ThemeMode.system` — dark mode follows the device setting; no manual toggle.
- **D-05:** Fallback seed color is `Colors.blue` — unchanged from v1.0, applies on Android <12 and all iOS devices.

### Dark Mode Semantic Colors

- **D-06:** Semantic colors adapt by brightness:
  - Light mode: `Colors.green.shade600`, `Colors.red.shade600`, `Colors.orange.shade700` (current values)
  - Dark mode: `Colors.green.shade400`, `Colors.red.shade400`, `Colors.orange.shade400`
  - Pattern: `Theme.of(context).brightness == Brightness.dark ? Colors.green.shade400 : Colors.green.shade600` (and equivalents for red/orange)
- **D-07:** Affected locations: `home_screen.dart` (ring color, label color when goal met — 2 occurrences) and `history_screen.dart` (calendar day fill + text colors — 3 occurrences).

### L-Display

- **D-08:** Use `intl.NumberFormat` for locale-aware decimal formatting (e.g. comma separator on Italian devices, period on US). The `intl` package is already in `pubspec.yaml`.
- **D-09:** Ring center text format: `'{current} / {goal} L'` — unit appears once at the end (e.g. `'1,75 / 2,00 L'`). Both values converted from ml to liters (`amountMl / 1000`).
- **D-10:** When goal is reached (`totalMl >= target`), keep the current text `'Goal reached!'` — no change to this branch.
- **D-11:** L-display is home screen only (the progress ring center and any surrounding ml labels on the home screen). The settings slider stays in ml. Individual entry items in the timeline stay in ml (`+150 ml`). The SnackBar text stays in ml (`+150 ml added`).

### SnackBar Fix

- **D-12:** Add `persist: false` to the `SnackBar(...)` constructor in `home_screen.dart`. This is the complete fix for the Flutter 3.38 breaking change that causes SnackBars with `SnackBarAction` to persist indefinitely.
- **D-13:** The existing `clearSnackBars()` call before `showSnackBar()`, the `capturedKey` pattern, and the `mounted` check are all correct and should remain unchanged.

### Claude's Discretion

- Exact `intl.NumberFormat` API call (e.g., `NumberFormat.decimalPatternDigits(locale: Intl.getCurrentLocale(), decimalDigits: 2)` or equivalent) — pick whichever format produces exactly 2 decimal places with the device locale's decimal separator.
- Whether to extract a `_semanticColor(BuildContext, Color light, Color dark)` helper or inline the brightness check — either is fine.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope
- `.planning/REQUIREMENTS.md` — HOME-01, HOME-02, THEME-01, THEME-02, THEME-03 requirements with traceability notes
- `.planning/research/SUMMARY.md` — synthesized research: dynamic_color package, SnackBar root cause, architecture integration points

### Files that change in this phase
- `lib/main.dart` — MaterialApp.router, ThemeData, colorSchemeSeed → DynamicColorBuilder integration
- `lib/presentation/screens/home_screen.dart` — SnackBar persist fix, L-display ring text, semantic color adaptation (2 occurrences)
- `lib/presentation/screens/history_screen.dart` — semantic color adaptation for calendar cells (3 occurrences)
- `pubspec.yaml` — add `dynamic_color: ^1.8.1` runtime dependency

### Key research findings
- `.planning/research/ARCHITECTURE.md` — DynamicColorBuilder placement, file-by-file change list
- `.planning/research/PITFALLS.md` — cannot use colorScheme + colorSchemeSeed simultaneously; FAB Scaffold placement (Phase 7)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/presentation/screens/home_screen.dart` — existing `isGoalMet` bool and `percentage` double are already computed; L-display and color decisions can read these directly without new computation
- `lib/presentation/screens/history_screen.dart` — semantic colors are applied in a single function block near the bottom of the file; easy to make brightness-conditional there

### Established Patterns
- `Theme.of(context).colorScheme` is already used for non-semantic colors throughout all screens — the theme token system is in place
- `ScaffoldMessenger.of(context)` is captured before the `async` gap in `_onQuickAdd` — pattern should remain unchanged

### Integration Points
- `main.dart` `DrinkyDrinkyApp.build()` method at line 35 — `MaterialApp.router` is the insertion point for `DynamicColorBuilder`
- `home_screen.dart` line 247 — `SnackBar(...)` constructor, add `persist: false` here
- `home_screen.dart` line 139 — ring center text `'$totalMl / $target ml'`, replace with L-format string
- `home_screen.dart` lines 134, 141 — two `Colors.green.shade600` occurrences for goal-met state
- `history_screen.dart` lines 168, 328–332 — orange/green/red color assignments for calendar cells

</code_context>

<specifics>
## Specific Ideas

- Ring text example: `'1,75 / 2,00 L'` — the locale comma is produced by `intl.NumberFormat`, not hardcoded
- Dark mode color shades confirmed: `shade400` for all three semantic colors in dark mode
- The `'Goal reached!'` text is kept as-is (not converted to L format)

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 6-Bug Fix + Theme + L-Display*
*Context gathered: 2026-06-08*
