---
phase: 13-string-extraction-translation
reviewed: 2026-06-15T00:00:00Z
depth: deep
files_reviewed: 14
files_reviewed_list:
  - lib/domain/entities/hydration_enums.dart
  - lib/core/router/app_router.dart
  - lib/presentation/screens/home_screen.dart
  - lib/presentation/screens/settings_screen.dart
  - lib/presentation/screens/history_screen.dart
  - lib/presentation/screens/hydration_calculator_screen.dart
  - lib/presentation/screens/permission_screen.dart
  - lib/presentation/widgets/preset_edit_dialog.dart
  - lib/l10n/app_en.arb
  - lib/l10n/app_it.arb
  - lib/l10n/app_fr.arb
  - lib/l10n/app_es.arb
  - lib/l10n/generated/app_localizations_it.dart
  - lib/l10n/generated/app_localizations_fr.dart
findings:
  critical: 1
  warning: 4
  info: 0
  total: 5
status: issues_found
---

# Phase 13: Code Review Report

**Reviewed:** 2026-06-15
**Depth:** deep
**Files Reviewed:** 14
**Status:** issues_found

## Summary

This phase extracted all hardcoded strings into ARB keys, added Italian/French/Spanish
translations (79 keys each), refactored the hydration calculator to use a typed
`BiologicalSex` enum for sex selection, and threaded `context.l10n` into every screen.

The ARB key set is perfectly consistent across all four locale files (EN/IT/FR/ES).
The ICU plural patterns for `dayStreak` are correct: `=0` maps to `zero:` and `=1` maps
to `one:` in `Intl.pluralLogic`, and all four generated files include both named arguments.
The French `one` CLDR category (which covers 0 and 1) is correctly overridden by the
explicit `zero:` argument. All import statements are present. `context.l10n` is used only
in widget builder callbacks (never in the GoRouter redirect callback where localizations
would not be available).

Two correctness defects were found: one BLOCKER and one defect that is technically
a quality problem with observable user-facing side effects. Three additional warnings
were found for incomplete internationalization.

---

## Critical Issues

### CR-01: "Goal reached!" text never appears when user overshoots the daily target

**File:** `lib/presentation/screens/home_screen.dart:141`

**Issue:** The center text of the progress ring uses `totalMl == target` (strict equality)
to decide between `goalReached` and `currentIntake(...)`. The `isGoalMet` flag on line 116,
correctly defined as `totalMl >= target`, is used for the ring color and text color but
is not used for the text content.

Result: when a user logs any amount beyond their exact target (a common occurrence — e.g.
drinking a 250 ml glass when 200 ml remained), `totalMl` overshoots `target`. The equality
check is `false`, so the ring displays the localized ratio string (e.g. `"2.10 / 2.00 L"`)
instead of `"Goal reached!"`. The ring turns green and the text turns green, but the message
is wrong. The overshoot case is the majority of goal-reached events.

**Fix:**
```dart
// line 141 — replace == with isGoalMet (already defined on line 116)
center: Text(
  isGoalMet
      ? context.l10n.goalReached
      : context.l10n.currentIntake(
          _formatLiters(context, totalMl),
          _formatLiters(context, target),
        ),
  style: theme.textTheme.headlineMedium?.copyWith(
    color: isGoalMet ? goalMetColor : null,
  ),
),
```

---

## Warnings

### WR-01: `ClimateLevel` enum is declared but never used — enum refactor is incomplete

**File:** `lib/domain/entities/hydration_enums.dart:8`

**Issue:** The file comment on `ClimateLevel` says "must match `_climateMultipliers` order",
acknowledging that it was intended to back the climate slider. However the calculator still
uses a raw `double _climateValue` (line 26) and an index-based `_climateMultipliers` list
(line 35). `ClimateLevel` has zero references outside its declaration file.

The `BiologicalSex` enum was fully integrated (used as the `SegmentedButton` type parameter
and as keys in the `_sexFactors` map). `ClimateLevel` was not wired up at all. The enum
comment warns against using display strings as map keys (the problem `BiologicalSex` solves),
but `ClimateLevel` is never used as a key — the slider index is used instead. This leaves
dead code in the domain layer and the climate calculation still has an implicit index-order
coupling that the enum was meant to eliminate.

**Fix:** Either wire `ClimateLevel` into the calculator, or remove it from the file:

```dart
// Option A: remove dead enum from hydration_enums.dart
// (file becomes BiologicalSex only)

// Option B: use it in the calculator
static const _climateMultipliers = {
  ClimateLevel.cold:     1.0,
  ClimateLevel.mild:     1.05,
  ClimateLevel.warm:     1.1,
  ClimateLevel.veryWarm: 1.2,
  ClimateLevel.humid:    1.3,
};

// slider value maps to enum index
ClimateLevel get _climateLevel =>
    ClimateLevel.values[_climateValue.round()];

// in _computeRecommendation:
final climateMultiplier = _climateMultipliers[_climateLevel]!;
```

---

### WR-02: `_formatMl` hardcodes `" ml"` suffix instead of using `context.l10n.mlUnit`

**File:** `lib/presentation/screens/hydration_calculator_screen.dart:74`

**Issue:** The method builds the recommendation display string by appending the literal
string `" ml"`:

```dart
return '${NumberFormat.decimalPattern(locale).format(ml)} ml';
```

The `mlUnit` key (`"ml"`) exists in all four ARB files and is already used correctly
elsewhere (e.g. in `preset_edit_dialog.dart` as `suffixText: context.l10n.mlUnit`).
This bypasses the translation system for the unit label, leaving `" ml"` hardcoded in
the calculator's recommendation display and in the `targetUpdated` SnackBar message
(which calls `_formatMl`).

**Fix:**
```dart
String _formatMl(BuildContext context, int ml) {
  final locale = Localizations.localeOf(context).toString();
  return '${NumberFormat.decimalPattern(locale).format(ml)} ${context.l10n.mlUnit}';
}
```

---

### WR-03: Day summary date uses English-only `"Month day, year"` ordering for all locales

**File:** `lib/presentation/screens/history_screen.dart:384`

**Issue:** The date label for the day summary card is constructed as:

```dart
final dateLabel =
    '${DateFormat.MMMM(locale).format(day)} ${day.day}, ${day.year}';
```

While the month name is localized (e.g. `"giugno"` in Italian), the ordering
`{MonthName} {day}, {year}` is an English-specific convention.
Italian convention is `{day} {MonthName} {year}` (e.g. `"15 giugno 2026"`).
Spanish convention is `{day} de {MonthName} de {year}` (e.g. `"15 de junio de 2026"`).
French convention is `{day} {MonthName} {year}` (e.g. `"15 juin 2026"`).

The comma after the day number is also English-only.

**Fix:** Use `DateFormat.yMMMMd` which produces locale-aware ordering automatically:

```dart
final dateLabel = DateFormat.yMMMMd(locale).format(day);
```

This produces the correct output for all four supported locales without manual
concatenation.

---

### WR-04: `_formatTime` hardcodes `"AM"/"PM"` strings in the 12-hour branch

**File:** `lib/presentation/screens/settings_screen.dart:345`

**Issue:** The `_formatTime` method outputs:

```dart
final period = hour >= 12 ? 'PM' : 'AM';
return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
```

`AM` and `PM` are English-only. While Spanish, French, and Italian users typically
use 24-hour clocks (and `alwaysUse24HourFormat` will return `true` for them on most
devices), users in those locales who have configured a 12-hour format on their device
will see English `AM`/`PM` markers. This is inconsistent with the rest of the app's
locale-aware approach.

**Fix:** Use `MaterialLocalizations` for AM/PM strings, which are localized by
`GlobalMaterialLocalizations`:

```dart
String _formatTime(BuildContext context, int hour, int minute) {
  final use24h = MediaQuery.alwaysUse24HourFormatOf(context);
  if (use24h) {
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  } else {
    final localizations = MaterialLocalizations.of(context);
    final period = hour >= 12
        ? localizations.postMeridiemAbbreviation
        : localizations.anteMeridiemAbbreviation;
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}
```

---

_Reviewed: 2026-06-15_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: deep_
