# Project Research Summary

**Project:** Drinky Drinky — v1.1 Polish & UX
**Domain:** Flutter hydration tracker — UX refinement milestone
**Researched:** 2026-06-08
**Confidence:** HIGH

## Executive Summary

v1.1 is a focused polish milestone delivering five independent improvements to an already-working app: a SnackBar auto-dismiss bug fix, liter-based progress display, a FAB + modal bottom sheet replacing the inline quick-add buttons, Material You dynamic theming, and a proper app icon. None of the five features require schema migrations, new data models, or provider changes. The research consensus is that all five are appropriate for a single milestone; no features should be deferred.

The recommended approach is a 3-phase build order that sequences risk carefully: fix the existing bug and wire up theme infrastructure first (small, low-risk), then redesign the quick-add UX (the only substantial new widget), then generate the app icon (fully independent, requires a design asset). The single new runtime dependency is `dynamic_color ^1.8.1`, published by Google's Material team and confirmed compatible with Flutter 3.44.1.

The primary risk area is `home_screen.dart`, which is touched by four of the five features. Sequencing Phase 1 (small changes: SnackBar fix, L-display, DynamicColorBuilder) before Phase 2 (structural: remove Row, add FAB, create AddDrinkSheet) avoids merge conflicts and ensures Phase 2 starts from a clean baseline. An open question on dark mode scope should be resolved before Phase 1 begins.

## Key Findings

### Stack Additions for v1.1

Only one new runtime dependency is needed. The base stack is unchanged.

| Package | Version | Purpose | Why |
|---------|---------|---------|-----|
| dynamic_color | ^1.8.1 | Material You wallpaper-derived ColorScheme on Android 12+ | Published by material.io (verified publisher). Returns null on unsupported platforms, enabling clean fallback. |

`flutter_launcher_icons ^0.14.4` is added as a dev dependency (already listed in CLAUDE.md, not yet in pubspec.yaml). No other packages are needed: `showModalBottomSheet` is built into Flutter, `toStringAsFixed(2)` is Dart core, and the SnackBar fix is a one-line property change.

**Do not add:** `intl` (overkill for a single formatting call), `modal_bottom_sheet` (built-in covers all needs), or `google_fonts` (not in scope for v1.1).

### Expected Features

**Table stakes (must ship in v1.1):**
- Liter display ("1.75 L / 2.00 L") — pure formatting change, no data model impact
- SnackBar auto-dismiss fix — existing feature that is currently broken on Flutter 3.44.1
- App icon (water glass) — default Flutter icon signals an unfinished product

**Differentiators (should ship in v1.1):**
- Material You dynamic color — app feels native on Android 12+ devices; falls back cleanly on older Android and iOS
- FAB + modal bottom sheet — cleaner home screen with custom ml input; replaces 4 inline buttons with a single action point

**Defer to v2+:**
- Custom drink icons or colors in the bottom sheet — over-engineering for 3 presets
- Animated FAB (morphing, hero) — distraction with accessibility concerns
- History screen liter formatting — the home screen change is the high-visibility improvement; history can follow separately

### Architecture Approach

All five features have well-defined integration points with minimal overlap at the data and provider layers. The Riverpod provider graph, Drift DAOs, and repository layer are entirely untouched. Changes are concentrated in `lib/main.dart` (theme), `lib/presentation/screens/home_screen.dart` (4 of 5 features), `lib/presentation/screens/settings_screen.dart` (1-line preset filter), and one new file `lib/presentation/widgets/add_drink_sheet.dart`.

**Key architectural decisions confirmed by research:**

1. **Preset storage is Drift, not SharedPreferences.** Presets live in the `DrinkPresets` table. The 4-to-3 reduction is a display-only change: pass `presets.take(3).toList()` at the UI layer in both HomeScreen and SettingsScreen. No Drift migration needed.

2. **FAB belongs on the inner HomeScreen Scaffold**, not the outer router Scaffold from `StatefulShellRoute`. This ensures the FAB appears only on the Home tab.

3. **DynamicColorBuilder wraps `MaterialApp.router`** inside `DrinkyDrinkyApp.build()`. ProviderScope stays above it. `colorSchemeSeed: Colors.blue` must be fully replaced with `colorScheme: lightDynamic ?? ColorScheme.fromSeed(seedColor: Colors.blue)` — ThemeData asserts if both are present simultaneously.

4. **AddDrinkSheet is a plain StatefulWidget** (not ConsumerWidget). It receives presets and an `onAdd` callback from HomeScreen. This keeps the sheet testable and decoupled from Riverpod.

5. **L-display uses `(ml / 1000).toStringAsFixed(2)`** for "1.75 L". Individual drink amounts in the timeline and SnackBar stay in ml (more natural for 200-500 ml increments).

### Critical Pitfalls

Ranked by severity:

1. **SnackBar `persist` breaking change (Flutter 3.38+)** — SnackBars with a `SnackBarAction` no longer auto-dismiss. Fix: `persist: false` on the SnackBar constructor. Do NOT change ScaffoldMessenger lifecycle or the `clearSnackBars()` call — those are already correct.

2. **ThemeData `colorScheme` vs `colorSchemeSeed` assertion** — Adding `colorScheme:` from DynamicColorBuilder while leaving `colorSchemeSeed: Colors.blue` causes an immediate crash on launch. Remove `colorSchemeSeed` entirely.

3. **Bottom sheet keyboard overlap** — The custom amount TextField will be hidden by the soft keyboard unless `isScrollControlled: true` is set AND the sheet content is wrapped in `Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom))`.

4. **Wrong Navigator context closes the screen** — Use `sheetContext` from the builder callback (not the parent screen's context) when calling `Navigator.of(context).pop()`. Using the parent context pops HomeScreen instead of the sheet.

5. **FAB overlaps timeline list content** — Add `padding: const EdgeInsets.only(bottom: 80)` to the timeline ListView (FAB height 56 + margin 24).

6. **Dark mode hardcoded color contrast** — Adding `darkTheme` activates dark mode. Hardcoded `Colors.green.shade600`, `Colors.red.shade600`, and `Colors.orange.shade700` may lose contrast on dark surfaces. Mitigation: suppress dark mode with `themeMode: ThemeMode.light` for v1.1 (see open questions).

7. **iOS icon transparency rejection** — Source PNG must not have an alpha channel for iOS. Use a solid-background image for `image_path`; transparent foreground is OK for `adaptive_icon_foreground` (Android only).

## Implications for Roadmap

### Phase 1: Bug Fix + Theme Infrastructure
**Rationale:** Smallest, lowest-risk changes first. SnackBar fix corrects broken existing behavior. DynamicColorBuilder and L-display are both isolated. Bundling avoids churning home_screen.dart across multiple commits.
**Delivers:** Working UNDO SnackBar, liter-based progress display, Material You theming on Android 12+.
**Features:** SnackBar fix, L-display, Material You dynamic color.
**Avoids:** Pitfall 1 (persist: false), Pitfall 2 (colorSchemeSeed removal), Pitfall 6 (dark mode — resolve via open question first).
**Files changed:** `pubspec.yaml`, `lib/main.dart`, `lib/presentation/screens/home_screen.dart` (2 small edits).

### Phase 2: Quick-Add Redesign
**Rationale:** Largest structural change, isolated so it can be tested against the Phase 1 baseline. The 4-to-3 preset filter is coupled here because the sheet shows 3 presets.
**Delivers:** FAB on home screen, modal bottom sheet with 3 presets + custom ml input, 4-to-3 preset display reduction.
**Features:** FAB + modal bottom sheet, 4-to-3 preset filter.
**Avoids:** Pitfall 3 (isScrollControlled + viewInsets), Pitfall 4 (sheetContext for pop), Pitfall 5 (ListView bottom padding).
**Files changed:** `lib/presentation/screens/home_screen.dart` (remove Row, add FAB), `lib/presentation/screens/settings_screen.dart` (take(3)), `lib/presentation/widgets/add_drink_sheet.dart` (NEW).

### Phase 3: App Icon
**Rationale:** Fully independent — no Dart code changes, no runtime behavior. Placed last because it requires a design asset that may not be ready in parallel with code work.
**Delivers:** Proper water glass app icon on iOS and Android (adaptive icon on Android 8+).
**Features:** App icon via flutter_launcher_icons.
**Avoids:** Pitfall 7 (iOS transparency — opaque PNG for iOS source).
**Files changed:** `pubspec.yaml` (dev dep + config block), `assets/icon/` (NEW source images), generated platform assets.

### Phase Ordering Rationale

- Phase 1 before Phase 2: Ensures the FAB/sheet implementation starts from a home_screen.dart baseline that already has SnackBar fix and L-display in place. Avoids merge conflicts from simultaneous edits to the same file.
- Phase 3 last: Requires a design asset. Code work should not block on icon design.
- All phases are independent enough to complete within a single milestone without branching risk.

### Research Flags

All features follow well-documented Flutter patterns. No phase requires additional pre-implementation research.

- **Phase 1:** Standard patterns — DynamicColorBuilder canonical example from official Google repo; SnackBar fix from official breaking-changes docs.
- **Phase 2:** Standard patterns — showModalBottomSheet with isScrollControlled thoroughly documented; FAB is a basic Scaffold property.
- **Phase 3:** Standard patterns — flutter_launcher_icons is config-only tooling.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All package versions verified via pub.dev direct fetch. dynamic_color 1.8.1 confirmed from material.io publisher. |
| Features | HIGH | Official Flutter API docs and breaking-changes docs consulted directly. |
| Architecture | HIGH | Integration points identified against actual codebase files. Drift vs SharedPreferences discrepancy resolved by reading actual code. |
| Pitfalls | HIGH | Critical pitfalls sourced from official Flutter breaking-changes documentation and ThemeData source assertions. |

**Overall confidence:** HIGH

### Gaps to Address

1. **Dark mode scope (open question — resolve before Phase 1):**
   - Option A: Ship dark mode in v1.1 — `themeMode: ThemeMode.system`, add brightness-conditional variants for 3 hardcoded semantic colors (green/red/orange). Low extra effort.
   - Option B: Suppress dark mode — `themeMode: ThemeMode.light`. Simpler, avoids semantic color contrast issue. Users on dark mode get light theme.
   - Recommendation: Option B for v1.1 given European market focus; defer Option A to v1.2.

2. **L-display locale handling (out of scope for v1.1):** `toStringAsFixed` always uses `.` as decimal separator. European locales use `,` (e.g., "1,75 L"). For v1.1, `.` is acceptable and avoids an `intl` dependency. Flag for v1.2 if localization is added.

3. **Icon design asset dependency:** Phase 3 requires a 1024x1024 PNG before the generator can run. Commission/create the asset in parallel with Phase 1-2 code work.

## Sources

### Primary (HIGH confidence)
- https://docs.flutter.dev/release/breaking-changes/snackbar-with-action-behavior-update — SnackBar persist breaking change
- https://pub.dev/packages/dynamic_color — version 1.8.1, publisher material.io verified
- https://github.com/material-foundation/flutter-packages/tree/main/packages/dynamic_color/example — complete_example.dart canonical pattern
- https://api.flutter.dev/flutter/material/showModalBottomSheet.html — isScrollControlled, viewInsets pattern
- https://dart.dev/libraries/dart-core — toStringAsFixed behavior
- https://pub.dev/packages/flutter_launcher_icons — version 0.14.4
- Flutter ThemeData source code — colorScheme/colorSchemeSeed assertion

### Secondary (MEDIUM confidence)
- Apple Human Interface Guidelines — icon transparency prohibition (enforced by App Store Connect)

---
*Research completed: 2026-06-08*
*Ready for roadmap: yes*
