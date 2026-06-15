# Phase 11: Hydration Calculator - Research

**Researched:** 2026-06-15
**Domain:** Flutter UI screen (form with local computation), GoRouter redirect chaining, SharedPreferences flags
**Confidence:** HIGH

## Summary

Phase 11 adds a single new screen (`HydrationCalculatorScreen`) with a pure-local formula, no new database tables, no new packages, and no network calls. The technical surface area is small: a form with three inputs (SegmentedButton, TextFormField, Slider), a live-computed recommendation display, and two navigation integration points (first-launch redirect gate + Settings tile).

The most nuanced implementation detail is extending the existing GoRouter redirect guard to support a two-step onboarding flow (`/permission` then `/calculator`) using a second SharedPreferences boolean key. GoRouter's redirect function is called on every navigation event and supports chaining (up to `redirectLimit: 5` by default), so sequential guard checks within a single `redirect` callback work without modification to the router architecture.

No new packages are required. All widgets (SegmentedButton, Slider, TextFormField, FilledButton, TextButton) are built-in Flutter Material 3 components. The only external integration point is calling the already-implemented `updateTargetWithHistory()` from `SettingsRepository`.

**Primary recommendation:** Implement as a single `ConsumerStatefulWidget` with local `setState` for ephemeral form state (sex, weight, climate) -- no Riverpod providers needed since inputs must never be persisted. Use `emptySelectionAllowed: true` on `SegmentedButton` to start with no sex preselection.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Add `drinky_calculatorShown` as a new SharedPreferences key. Extend the GoRouter `redirect` guard: if `drinky_permissionScreenShown` is true AND `drinky_calculatorShown` is false, redirect to `/calculator`. Sequence: `/permission` -> `/calculator` -> `/`. The calculator screen sets `drinky_calculatorShown = true` on any exit path (both "Usa come target" and "Salta").
- **D-02:** `/calculator` is a top-level GoRoute at the same level as `/permission` -- outside the `StatefulShellRoute`. No bottom NavigationBar is visible when the calculator is shown during onboarding.
- **D-03:** When opened from Settings: `context.push('/calculator')`. GoRouter push preserves the Settings stack; back button returns to Settings. On "Usa come target" in Settings context: call `updateTargetWithHistory()` then `context.pop()`.
- **D-04:** Formula: `result_ml = round(weight_kg * sex_factor * climate_multiplier / 50) * 50`. Sex factors: Maschio = 35, Femmina = 31, Altro = 33. Climate multipliers: Freddo = 1.0, Mite = 1.05, Caldo = 1.1, Molto caldo = 1.2, Afoso = 1.3.
- **D-05:** Clamp result after rounding: min 1000ml, max 4000ml.
- **D-06:** Sex input: Material 3 `SegmentedButton<String>` with 3 segments. One segment always selected (no deselect); default selection is Claude's discretion.
- **D-07:** Climate input: `Slider` with `divisions: 4`, `min: 0`, `max: 4`. Integer value 0-4 maps to [Freddo, Mite, Caldo, Molto caldo, Afoso].
- **D-08:** Live calculation -- recommendation updates automatically on input change. No explicit "Calcola" button. "Usa come target" enabled only when all inputs valid: sex selected, weight valid positive integer 1-300 kg.
- **D-09:** On "Usa come target" (first-launch): call `updateTargetWithHistory(recommendedMl)`, set `drinky_calculatorShown = true`, show SnackBar, then `context.go('/')`.
- **D-10:** First-launch dismiss ("Salta"): TextButton. Sets `drinky_calculatorShown = true` and navigates to `/` without calling `updateTargetWithHistory()`.
- **D-11:** Settings context dismiss: standard AppBar back button only -- no "Salta" button. On "Usa come target" in Settings: call `updateTargetWithHistory(recommendedMl)`, show SnackBar, then `context.pop()`.

### Claude's Discretion
- AppBar title (suggestion: "Calcolatore idratazione")
- Whether sex SegmentedButton has a preselected default or starts unselected
- Weight TextFormField: keyboard type, inputFormatters, validation message text
- Exact positioning of privacy disclaimer text
- SnackBar wording for target confirmation
- Whether recommendation is shown as large text or Card widget

### Deferred Ideas (OUT OF SCOPE)
- Saving calculator inputs across sessions (privacy constraint)
- fl_chart BMI or hydration trend visualization
- Metric/imperial toggle (kg vs lbs)
- Animated result display (counter animation)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CALC-01 | Calculator screen with sex/weight/climate inputs, local formula, privacy disclaimer | SegmentedButton API verified (emptySelectionAllowed, ButtonSegment), Slider divisions/labels, TextFormField with FilteringTextInputFormatter.digitsOnly, formula constants from D-04/D-05 |
| CALC-02 | Calculator shown automatically on first launch (after permission, before home) | GoRouter redirect chaining verified -- single redirect callback with sequential SharedPreferences checks, redirectLimit default 5 is sufficient |
| CALC-03 | Calculator accessible from Settings via dedicated tile | context.push('/calculator') pattern verified in GoRouter; Settings ListTile addition follows existing card/section pattern |
| CALC-04 | "Usa come target" button writes recommendation to target_history; inputs never persisted | updateTargetWithHistory() method verified in SettingsRepository (line 83-99); ConsumerStatefulWidget with local setState ensures inputs are ephemeral |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- **Tech stack**: Flutter + Riverpod + Drift -- no deviation
- **Platform**: iOS and Android only
- **Offline-first**: No backend or cloud sync
- **Packages to NOT use**: sqlite3_flutter_libs, awesome_notifications, GetX, provider, hive/isar, flutter_native_timezone
- **Database setup**: drift_flutter (not sqlite3_flutter_libs)
- **State management**: flutter_riverpod (not hooks_riverpod)
- **Code generation**: `dart run build_runner build --delete-conflicting-outputs`

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Hydration formula computation | Client (Widget) | -- | Pure local math with no persistence; state is ephemeral within the widget |
| First-launch routing gate | Client (Router) | -- | GoRouter redirect + SharedPreferences; no server involvement |
| Target persistence ("Usa come target") | Database (Drift) | Client (Repository) | updateTargetWithHistory() dual-writes to target_history + user_settings via SettingsRepository |
| Calculator UI form | Client (Widget) | -- | Material 3 built-in widgets, ConsumerStatefulWidget with setState |
| Settings entry point | Client (Widget) | Client (Router) | ListTile onTap triggers context.push('/calculator') |

## Standard Stack

### Core (already installed -- no new packages)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter_riverpod | ^3.3.1 | Provider access for SettingsRepository | Already in pubspec; ConsumerStatefulWidget gives ref access |
| go_router | ^17.3.0 | Navigation and redirect guards | Already handles /permission redirect; extends to /calculator |
| shared_preferences | ^2.5.5 | drinky_calculatorShown boolean flag | Already used for drinky_permissionScreenShown; same pattern |
| intl | ^0.20.2 | NumberFormat for recommendation display | Already used in home_screen for liter formatting |

### Supporting (built-in Flutter -- no install needed)

| Widget | Source | Purpose | When to Use |
|--------|--------|---------|-------------|
| SegmentedButton<String> | material.dart | Sex selection (M/F/Altro) | When presenting 2-5 mutually exclusive options |
| Slider | material.dart | Climate level selection (0-4) | When selecting from a continuous or discrete range |
| TextFormField | material.dart | Weight input (kg) | When collecting validated text/numeric input |
| FilteringTextInputFormatter | services.dart | Restrict weight input to digits only | Prevents non-numeric input at the keyboard level |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| SegmentedButton | DropdownButton | SegmentedButton shows all options at once; better for 3 options |
| SegmentedButton | Radio buttons | SegmentedButton is more compact and Material 3 native |
| Local setState | Riverpod StateNotifier | Overkill for ephemeral form state that must NOT be persisted |
| TextFormField | TextField | TextFormField integrates with Form for validation; richer API |

**Installation:** No new packages to install. All dependencies are already in `pubspec.yaml`.

## Architecture Patterns

### System Architecture Diagram

```
User launches app
        |
        v
  GoRouter redirect
        |
        +-- permissionShown == false? --> /permission (existing)
        |                                      |
        |                           [user completes permission]
        |                                      |
        |                            sets drinky_permissionScreenShown = true
        |                                      |
        |                              context.go('/') -- triggers redirect again
        |                                      |
        +-- calculatorShown == false? --> /calculator (NEW)
        |                                      |
        |                    +----------------------------------+
        |                    |                                  |
        |              "Usa come target"                    "Salta"
        |                    |                                  |
        |         updateTargetWithHistory(ml)          (no target change)
        |                    |                                  |
        |         set drinky_calculatorShown = true    set drinky_calculatorShown = true
        |                    |                                  |
        |              context.go('/')                   context.go('/')
        |                    |                                  |
        +-- both true? ---> / (HomeScreen)
                                    
                                    
Settings flow (separate entry):
  SettingsScreen
        |
  ListTile "Ricalcola raccomandazione idratazione"
        |
  context.push('/calculator')
        |
  /calculator screen (with back button)
        |
        +-- "Usa come target" --> updateTargetWithHistory(ml) + SnackBar + context.pop()
        +-- Back button -------> context.pop()
```

### Recommended File Structure

```
lib/
  presentation/
    screens/
      hydration_calculator_screen.dart    # NEW: full calculator screen
      settings_screen.dart                # MODIFIED: add HYDRATION section + ListTile
  core/
    router/
      app_router.dart                     # MODIFIED: add /calculator route + redirect guard
```

No new providers, repositories, entities, or database tables needed.

### Pattern 1: ConsumerStatefulWidget with Ephemeral State

**What:** Calculator form state (sex, weight, climate) lives entirely in widget-local `setState`. No Riverpod providers for form inputs.
**When to use:** When state is ephemeral, must not be persisted, and has no consumers outside the widget.
**Example:**
```dart
// Source: Verified pattern from existing permission_screen.dart and home_screen.dart
class HydrationCalculatorScreen extends ConsumerStatefulWidget {
  const HydrationCalculatorScreen({super.key});

  @override
  ConsumerState<HydrationCalculatorScreen> createState() =>
      _HydrationCalculatorScreenState();
}

class _HydrationCalculatorScreenState
    extends ConsumerState<HydrationCalculatorScreen> {
  String? _selectedSex;      // null = not yet selected
  final _weightController = TextEditingController();
  double _climateValue = 1;  // default: Mite (index 1)

  // Formula computation -- pure function, no side effects
  int? _computeRecommendation() {
    if (_selectedSex == null) return null;
    final weight = int.tryParse(_weightController.text);
    if (weight == null || weight < 1 || weight > 300) return null;

    final sexFactor = switch (_selectedSex!) {
      'Maschio' => 35.0,
      'Femmina' => 31.0,
      'Altro'   => 33.0,
      _         => 33.0,
    };
    final climateMultiplier = [1.0, 1.05, 1.1, 1.2, 1.3][_climateValue.round()];
    final raw = weight * sexFactor * climateMultiplier;
    final rounded = (raw / 50).round() * 50;
    return rounded.clamp(1000, 4000);
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }
}
```

### Pattern 2: GoRouter Redirect Guard Extension

**What:** Extend the existing single redirect callback with a second SharedPreferences check.
**When to use:** Adding sequential onboarding steps to an existing guard.
**Example:**
```dart
// Source: Verified from existing app_router.dart (lines 23-31) + GoRouter docs
redirect: (BuildContext context, GoRouterState state) async {
  // Prevent redirect loops
  if (state.matchedLocation == '/permission') return null;
  if (state.matchedLocation == '/calculator') return null;

  final prefs = await SharedPreferences.getInstance();

  // Step 1: permission screen first
  final permissionShown = prefs.getBool('drinky_permissionScreenShown') ?? false;
  if (!permissionShown) return '/permission';

  // Step 2: calculator screen second (only after permission is done)
  final calculatorShown = prefs.getBool('drinky_calculatorShown') ?? false;
  if (!calculatorShown) return '/calculator';

  return null;
},
```

### Pattern 3: SegmentedButton with Empty Selection

**What:** Material 3 SegmentedButton that starts with no selection.
**When to use:** When a choice is required but no default makes sense.
**Example:**
```dart
// Source: Flutter API docs (api.flutter.dev/flutter/material/SegmentedButton-class.html)
// emptySelectionAllowed verified as a real property with default: false
SegmentedButton<String>(
  emptySelectionAllowed: true,   // allows starting with no selection
  segments: const [
    ButtonSegment(value: 'Maschio', label: Text('Maschio')),
    ButtonSegment(value: 'Femmina', label: Text('Femmina')),
    ButtonSegment(value: 'Altro', label: Text('Altro')),
  ],
  selected: _selectedSex != null ? {_selectedSex!} : {},
  onSelectionChanged: (Set<String> selection) {
    setState(() => _selectedSex = selection.firstOrNull);
  },
),
```

### Pattern 4: Detecting Onboarding vs Settings Context

**What:** The calculator screen behaves differently based on how it was opened (first-launch vs Settings).
**When to use:** When the same screen serves two navigation contexts with different exit behaviors.
**Example:**
```dart
// Source: GoRouter canPop() API -- determines if there's a route to pop back to
// During onboarding (context.go('/calculator')): canPop() returns false
// From Settings (context.push('/calculator')): canPop() returns true
final isOnboarding = !GoRouter.of(context).canPop();

// AppBar: no back button during onboarding
AppBar(
  title: const Text('Calcolatore idratazione'),
  automaticallyImplyLeading: !isOnboarding,  // hides back button during onboarding
)

// On "Usa come target":
if (isOnboarding) {
  // Set flag + go to home
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('drinky_calculatorShown', true);
  context.go('/');
} else {
  // Settings context: pop back
  context.pop();
}
```

### Anti-Patterns to Avoid

- **Persisting calculator inputs:** Sex, weight, and climate MUST NEVER be written to SharedPreferences, Drift, or any storage. Privacy by design (CALC-04).
- **Creating a Riverpod provider for form state:** The inputs are ephemeral widget-local state. A provider would survive widget disposal, risk accidental persistence, and add unnecessary complexity.
- **Using context.go('/') from Settings:** This would destroy the navigation stack. Settings context must use `context.pop()` to return to the Settings tab.
- **Forgetting to set drinky_calculatorShown on all exit paths:** Both "Usa come target" AND "Salta" must set the flag. Missing it causes an infinite redirect loop on next launch.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Number formatting with thousands separator | Manual string manipulation | `NumberFormat.decimalPattern(locale)` from `intl` | Handles locale-specific separators (space for Italian/French, comma for English) |
| Digit-only input filtering | Manual onChanged validation | `FilteringTextInputFormatter.digitsOnly` | Prevents non-numeric characters at the keyboard level; cleaner than post-hoc filtering |
| Onboarding context detection | Boolean constructor parameter | `GoRouter.of(context).canPop()` | Automatically correct based on navigation state; no need to pass context through constructors |
| Target write + history | Direct DAO calls | `settingsRepository.updateTargetWithHistory(ml)` | Already handles dual-write to user_settings + target_history with applyFromTomorrow logic |

**Key insight:** This phase has zero new infrastructure -- every integration point (router, SharedPreferences, SettingsRepository, theme system) already exists and has been validated in prior phases. The only new code is the screen widget itself and minor additions to two existing files.

## Common Pitfalls

### Pitfall 1: Redirect Loop on /calculator

**What goes wrong:** If the redirect callback redirects to `/calculator` but does not check `state.matchedLocation == '/calculator'`, GoRouter will redirect `/calculator` back to `/calculator` infinitely (up to redirectLimit).
**Why it happens:** The existing code only checks `state.matchedLocation == '/permission'`. Adding the calculator check without adding the loop guard causes infinite redirect.
**How to avoid:** Add `if (state.matchedLocation == '/calculator') return null;` before the SharedPreferences checks.
**Warning signs:** App shows blank screen or crashes on first launch after update.

### Pitfall 2: Missing drinky_calculatorShown on "Salta" Path

**What goes wrong:** If "Salta" navigates to home without setting `drinky_calculatorShown = true`, the user gets sent back to the calculator on every app launch.
**Why it happens:** Developer focuses on the "Usa come target" happy path and forgets the skip path.
**How to avoid:** Both exit paths ("Usa come target" AND "Salta") must set the flag before navigating.
**Warning signs:** User reports being stuck in a calculator loop.

### Pitfall 3: SegmentedButton with emptySelectionAllowed but Missing Null Check

**What goes wrong:** If `emptySelectionAllowed: true` is set but the code assumes `selection.first` always exists, it throws a StateError on the empty set.
**Why it happens:** `Set.first` throws on empty sets. Need `selection.firstOrNull` (Dart 3.x) or a guard.
**How to avoid:** Use `selection.firstOrNull` and keep `_selectedSex` as `String?`.
**Warning signs:** Crash when tapping to deselect (if deselect is possible) or on initial render.

### Pitfall 4: context.go vs context.push from Settings

**What goes wrong:** Using `context.go('/calculator')` from Settings destroys the navigation stack. The user cannot press back to return to Settings.
**Why it happens:** `go()` replaces the entire navigation stack; `push()` adds on top.
**How to avoid:** Settings tile uses `context.push('/calculator')`. Calculator exit from Settings uses `context.pop()`.
**Warning signs:** User taps calculator in Settings, then back button goes to Home instead of Settings.

### Pitfall 5: Forgetting to Import go_router in Calculator Screen

**What goes wrong:** `context.go()`, `context.push()`, and `context.pop()` are GoRouter extension methods. Without `import 'package:go_router/go_router.dart'`, they are not available.
**Why it happens:** These look like they might be built-in BuildContext methods but they are not.
**How to avoid:** Add `import 'package:go_router/go_router.dart';` at the top of the calculator screen file.
**Warning signs:** Compile error "The method 'go' is not defined for the type 'BuildContext'".

### Pitfall 6: Async Gap in "Usa come target" Handler

**What goes wrong:** After `await updateTargetWithHistory()`, the widget may have been disposed. Calling `context.go('/')` or showing a SnackBar on a disposed widget causes a framework error.
**Why it happens:** Async operations can complete after the widget tree has changed.
**How to avoid:** Check `if (!mounted) return;` after every await, before using `context` or `ScaffoldMessenger`. Existing pattern from `permission_screen.dart` lines 87, 100, 112.
**Warning signs:** "setState() called after dispose()" or "Looking up a deactivated widget" in debug console.

### Pitfall 7: Weight Input Edge Cases

**What goes wrong:** User enters "0", "000", or leading zeros like "007". `int.tryParse("007")` returns 7, which is valid but the display shows "007" in the field.
**Why it happens:** `FilteringTextInputFormatter.digitsOnly` allows any sequence of digits.
**How to avoid:** Validate parsed value (1-300 range), not the raw string. The clamping is on the parsed int, not the string. Leading zeros are harmless -- the parsed value is correct.
**Warning signs:** None critical -- this is cosmetic. Document that "007" is parsed as 7, which is a valid weight.

## Code Examples

### Complete Formula Function

```dart
// Source: CONTEXT.md D-04, D-05 (locked decisions)
int? computeRecommendation({
  required String? sex,
  required String? weightText,
  required int climateIndex,
}) {
  if (sex == null) return null;
  final weight = int.tryParse(weightText ?? '');
  if (weight == null || weight < 1 || weight > 300) return null;

  final sexFactor = switch (sex) {
    'Maschio' => 35.0,
    'Femmina' => 31.0,
    'Altro'   => 33.0,
    _         => 33.0,
  };
  final climateMultiplier = const [1.0, 1.05, 1.1, 1.2, 1.3][climateIndex];
  final raw = weight * sexFactor * climateMultiplier;
  final rounded = (raw / 50).round() * 50;
  return rounded.clamp(1000, 4000);
}
```

### "Usa come target" Handler (Onboarding Context)

```dart
// Source: CONTEXT.md D-09, permission_screen.dart async pattern (lines 76-113)
Future<void> _onUseAsTarget(int recommendedMl) async {
  final repo = ref.read(settingsRepositoryProvider);
  try {
    await repo.updateTargetWithHistory(recommendedMl);
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Errore durante l\'aggiornamento del target. Riprova.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  if (!mounted) return;

  final isOnboarding = !GoRouter.of(context).canPop();

  if (isOnboarding) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('drinky_calculatorShown', true);
    if (!mounted) return;
  }

  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text('Target aggiornato a $recommendedMl ml'),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );

  if (isOnboarding) {
    context.go('/');
  } else {
    context.pop();
  }
}
```

### Number Formatting for Recommendation Display

```dart
// Source: Existing pattern from home_screen.dart line 219
// Italian locale uses space for thousands separator (e.g., "2 350")
String _formatMl(BuildContext context, int ml) {
  final locale = Localizations.localeOf(context).toString();
  final formatter = NumberFormat.decimalPattern(locale);
  return '${formatter.format(ml)} ml';
}
```

### Settings Tile Integration

```dart
// Source: Existing settings_screen.dart section/card pattern (lines 66-76)
// Add after the NOTIFICATIONS section in _buildBody():
_sectionLabel(context, 'HYDRATION'),
Card(
  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  child: ListTile(
    leading: const Icon(Icons.calculate_outlined),
    title: const Text('Ricalcola raccomandazione idratazione'),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => context.push('/calculator'),
  ),
),
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `SegmentedControl` (Cupertino) | `SegmentedButton` (Material 3) | Flutter 3.7+ | Material 3 native; cross-platform consistent look |
| `GoRouter.redirect` sync only | `GoRouter.redirect` supports async | go_router 6.0+ | Enables SharedPreferences reads in redirect without workarounds |
| Manual `selected` tracking | `emptySelectionAllowed` property | Flutter 3.16+ | Built-in support for starting with no selection |

**Deprecated/outdated:**
- `CupertinoSegmentedControl` for Material apps: Use `SegmentedButton` instead (Material 3 native)

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `GoRouter.of(context).canPop()` reliably distinguishes onboarding (go) from Settings (push) context | Architecture Patterns, Pattern 4 | If canPop() behaves differently than expected, the screen would need a constructor parameter to distinguish contexts. Low risk -- canPop() is a well-documented GoRouter API. |
| A2 | Italian locale (`it_IT`) uses space as thousands separator in `NumberFormat.decimalPattern()` | Code Examples, Number Formatting | If the locale uses a period instead, the display "2.350 ml" is still correct and readable. Very low impact. |
| A3 | `SegmentedButton` allows `selected: {}` (empty Set) when `emptySelectionAllowed: true` without visual glitches | Pattern 3 | If visual issues occur, fallback is to preselect "Maschio" as default (D-06 allows Claude's discretion on this). |

## Open Questions

1. **Number formatting locale behavior**
   - What we know: `NumberFormat.decimalPattern(locale)` formats with locale-appropriate thousands separators. HomeScreen already uses `NumberFormat.decimalPatternDigits` for liter display.
   - What's unclear: Whether the device locale will always resolve to Italian (the app UI is in Italian but locale depends on device settings).
   - Recommendation: Use the device locale via `Localizations.localeOf(context)` -- same pattern as home_screen. The formatting will be correct for whatever locale the device is set to.

2. **canPop() behavior on first navigation after redirect**
   - What we know: `GoRouter.of(context).canPop()` checks if there is a route to pop back to. During onboarding, the redirect uses `context.go('/calculator')` which replaces the stack.
   - What's unclear: Whether `canPop()` returns `false` after a redirect to `/calculator` (since redirects use `go` semantics internally).
   - Recommendation: Test this during implementation. If `canPop()` is unreliable, fall back to a constructor parameter `isOnboarding: true/false` passed from the GoRoute builder, or use a query parameter in the route.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | N/A -- no auth in app |
| V3 Session Management | no | N/A -- no sessions |
| V4 Access Control | no | N/A -- single user, local only |
| V5 Input Validation | yes | `FilteringTextInputFormatter.digitsOnly` at input level + `int.tryParse()` with range check (1-300) at logic level |
| V6 Cryptography | no | N/A -- no crypto operations |
| V7 Error Handling | yes | try/catch around `updateTargetWithHistory()` with user-facing error SnackBar; no stack traces exposed |
| V13 API/Web Service | no | N/A -- no network calls |

### Known Threat Patterns for this phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Weight input injection (non-numeric) | Tampering | `FilteringTextInputFormatter.digitsOnly` blocks non-digit input; `int.tryParse()` + range validation as defense in depth |
| Privacy violation (persisting biometric data) | Information Disclosure | Inputs stored only in widget-local state (setState); no persistence mechanism exists for sex/weight/climate. Privacy disclaimer on screen. |

### Privacy Note

CALC-04 and the project's "privacy by design" constraint require that sex, weight, and climate are NEVER persisted. The implementation ensures this by:
1. Using widget-local `setState` (not SharedPreferences, not Drift, not Riverpod providers)
2. Widget disposal automatically clears all form state
3. No serialization (no toJson, no toMap) of calculator inputs
4. Privacy disclaimer visible on screen

## Sources

### Primary (HIGH confidence)
- `lib/core/router/app_router.dart` -- existing GoRouter redirect pattern with SharedPreferences, verified by code read
- `lib/data/repositories/settings_repository.dart` -- `updateTargetWithHistory()` method signature and implementation, verified by code read (lines 83-99)
- `lib/presentation/screens/permission_screen.dart` -- ConsumerStatefulWidget pattern for onboarding screens with async handlers and mounted checks, verified by code read
- `lib/presentation/screens/settings_screen.dart` -- section/card/tile pattern for Settings integration, verified by code read
- `lib/presentation/screens/home_screen.dart` -- NumberFormat.decimalPatternDigits usage pattern, verified by code read (line 219)
- Flutter API docs (api.flutter.dev) -- SegmentedButton.emptySelectionAllowed property confirmed via WebFetch [CITED: api.flutter.dev/flutter/material/SegmentedButton-class.html]
- Flutter API docs (api.flutter.dev) -- FilteringTextInputFormatter.digitsOnly confirmed via WebFetch [CITED: api.flutter.dev/flutter/services/FilteringTextInputFormatter-class.html]
- GoRouter API docs (pub.dev) -- redirect behavior, redirectLimit default 5, async redirect support confirmed via WebFetch [CITED: pub.dev/documentation/go_router/latest/go_router/GoRouter-class.html]

### Secondary (MEDIUM confidence)
- `pubspec.yaml` -- all required packages already present, versions verified by file read
- `11-CONTEXT.md` -- all locked decisions (D-01 through D-11) read verbatim
- `11-UI-SPEC.md` -- complete UI specification including spacing, typography, color, and copywriting contract

### Tertiary (LOW confidence)
- Italian locale thousands separator behavior with `NumberFormat.decimalPattern()` [ASSUMED] -- needs runtime verification

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- no new packages; all widgets are built-in Flutter Material 3; all integration points verified in existing code
- Architecture: HIGH -- extends existing patterns (GoRouter redirect, ConsumerStatefulWidget, SharedPreferences flags) with minimal changes to two files
- Pitfalls: HIGH -- redirect loop and async gap pitfalls verified against existing code patterns; SegmentedButton API confirmed via official docs

**Research date:** 2026-06-15
**Valid until:** 2026-07-15 (stable -- no fast-moving dependencies; all APIs are mature Flutter Material 3 widgets)
