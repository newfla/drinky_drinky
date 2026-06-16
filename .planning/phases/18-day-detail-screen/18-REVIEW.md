---
phase: 18-day-detail-screen
reviewed: 2026-06-16T00:00:00Z
depth: standard
files_reviewed: 12
files_reviewed_list:
  - lib/presentation/screens/day_detail_screen.dart
  - lib/l10n/app_en.arb
  - lib/l10n/app_it.arb
  - lib/l10n/app_fr.arb
  - lib/l10n/app_es.arb
  - lib/l10n/generated/app_localizations.dart
  - lib/l10n/generated/app_localizations_en.dart
  - lib/l10n/generated/app_localizations_es.dart
  - lib/l10n/generated/app_localizations_fr.dart
  - lib/l10n/generated/app_localizations_it.dart
  - lib/core/router/app_router.dart
  - lib/presentation/screens/history_screen.dart
findings:
  critical: 1
  warning: 3
  info: 2
  total: 6
status: issues_found
---

# Phase 18: Code Review Report

**Reviewed:** 2026-06-16
**Depth:** standard
**Files Reviewed:** 12
**Status:** issues_found

## Summary

Phase 18 added `DayDetailScreen` — a per-entry bar chart screen reachable via the `/day/:dateKey` top-level GoRouter route, plus two new l10n keys (`dayDetailTotal`, `dayDetailNoEntries`) across four locales. The chart logic, provider wiring, and router plumbing are structurally correct. The `_findActiveTarget` helper is accurate given the confirmed ASC sort order of `allTargetHistoryProvider`. The fl_chart `group.x` type is `int`, matching the `Map<int, WaterEntryEntity>` lookup in the tooltip callback — no type mismatch.

Two defects are notable: (1) `DateTime.parse(dateKey)` in `build()` is uncaught and will throw a `FormatException` crash if the URL path parameter is malformed (e.g., a deep link or a test URL), and (2) the French `dayDetailNoEntries` string is missing the required accent ("entree" instead of "entrée"), producing a grammatically incorrect string visible to all French users. Three quality warnings cover logic duplication of `_findActiveTarget` across two files, a missing accent in the Spanish `dayDetailNoEntries` ("dia" instead of "día"), and the fact that the empty-state guard in `HistoryScreen.onDaySelected` (line 233) silently discards the navigation tap when `total == null` — making days with no data in the current month indistinguishable from unresponsive UI.

---

## Critical Issues

### CR-01: Uncaught `FormatException` from `DateTime.parse` crashes the screen on invalid `dateKey`

**File:** `lib/presentation/screens/day_detail_screen.dart:49`

**Issue:** `DateTime.parse(dateKey)` is called unconditionally inside `build()` using the raw GoRouter path parameter. If the URL is malformed (e.g., a bad deep link like `/day/not-a-date`, a test navigation, or a future code path passing an unexpected value), Dart throws an uncaught `FormatException` that propagates out of `build()` and crashes the widget tree. The `HistoryScreen` always passes well-formed dateKeys today, but the router accepts any string in the `:dateKey` segment with no validation, making the crash path reachable from outside the app.

**Fix:**
```dart
// In build(), replace the bare DateTime.parse call with a guarded variant:
final DateTime? parsedDate = _tryParseDate(dateKey);
if (parsedDate == null) {
  return Scaffold(
    appBar: AppBar(title: Text(dateKey)),
    body: Center(child: Text(context.l10n.errorLoadingData)),
  );
}
final appBarTitle = DateFormat.yMMMMd(locale).format(parsedDate);

// Add a top-level helper (or inline):
DateTime? _tryParseDate(String key) {
  try {
    return DateTime.parse(key);
  } on FormatException {
    return null;
  }
}
```

---

## Warnings

### WR-01: French `dayDetailNoEntries` is missing the required accent ("entree" instead of "entrée")

**File:** `lib/l10n/app_fr.arb:122` and `lib/l10n/generated/app_localizations_fr.dart:305`

**Issue:** The French translation for `dayDetailNoEntries` reads `"Aucune entree pour ce jour"`. The correct French word is `"entrée"` (with accent grave and acute). This is incorrect grammar, visible to all French-locale users on the Day Detail empty state. The same key in the same file correctly uses `"entrée"` at line 71 (`daySummaryNoEntries`), confirming this is a typo rather than a style choice.

**Fix:**
```json
// app_fr.arb line 122:
"dayDetailNoEntries": "Aucune entrée pour ce jour"
```
```dart
// app_localizations_fr.dart line 305:
String get dayDetailNoEntries => 'Aucune entrée pour ce jour';
```

---

### WR-02: Spanish `dayDetailNoEntries` is missing the required accent ("dia" instead of "día")

**File:** `lib/l10n/app_es.arb:122` and `lib/l10n/generated/app_localizations_es.dart:304`

**Issue:** The Spanish translation reads `"Sin registros para este dia"`. The correct Spanish word is `"día"` (with acute accent). Every other accented word in the Spanish ARB file is correctly spelled. This produces a grammatically incorrect string visible to all Spanish-locale users on the Day Detail empty state.

**Fix:**
```json
// app_es.arb line 122:
"dayDetailNoEntries": "Sin registros para este día"
```
```dart
// app_localizations_es.dart line 304:
String get dayDetailNoEntries => 'Sin registros para este día';
```

---

### WR-03: `_findActiveTarget` is duplicated verbatim between `day_detail_screen.dart` and `history_screen.dart`

**File:** `lib/presentation/screens/day_detail_screen.dart:18-28` and `lib/presentation/screens/history_screen.dart:23-33`

**Issue:** The function `_findActiveTarget` is copy-pasted identically in both files (same signature, same body, same fallback of 2000 ml). This violates DRY: any future bug fix or behaviour change in the algorithm (e.g., changing the fallback default) must be applied in two places. A divergence between the copies would cause different screens to compute different targets for the same day.

**Fix:** Extract the function to a shared location, e.g., a `target_utils.dart` file in `lib/core/utils/` or `lib/domain/`, and import it from both screens:
```dart
// lib/core/utils/target_utils.dart
import '../../domain/entities/target_history_entry.dart';

/// Finds the effective target for a date by scanning a list sorted ASC
/// by effectiveDate. Returns 2000 as fallback if no targets exist.
int findActiveTarget(List<TargetHistoryEntry> targets, String dateKey) {
  int result = 2000;
  for (final t in targets) {
    if (t.effectiveDate.compareTo(dateKey) <= 0) {
      result = t.targetMl;
    } else {
      break;
    }
  }
  return result;
}
```

---

## Info

### IN-01: Silent drop of calendar tap when `monthTotals[dateKey]` is null gives no user feedback

**File:** `lib/presentation/screens/history_screen.dart:232-235`

**Issue:** In `onDaySelected`, tapping a past day that has no entry in `monthTotals` (because the month data hasn't loaded yet, or the day genuinely has no data) silently does nothing. The condition `if (total != null && total > 0)` discards the tap without showing a snackbar or any visual cue. A user tapping a past day with a red or neutral cell gets no response and no explanation, which can appear as a UI bug.

**Fix:** This is an accepted product decision per the phase spec ("navigate only if day has data"), but consider displaying a brief tooltip or `ScaffoldMessenger` snackbar to inform the user why the tap did not navigate, especially for days where `total == null` (loading) vs. `total == 0` (genuinely no data).

---

### IN-02: Y-axis labels display sub-1000-ml values in litre units ("0.25 L"), which is counterintuitive

**File:** `lib/presentation/screens/day_detail_screen.dart:263-270`

**Issue:** The left y-axis converts all values to litres by dividing by 1000 and appending "L". For typical individual drink entries (150–500 ml), this produces labels like "0.15 L", "0.25 L", "0.5 L". The x-axis tooltip already shows values in ml. Displaying the y-axis in a fractional-litre format for values well under 1 L is non-intuitive for a per-entry chart (as opposed to the daily-total monthly chart where L is appropriate). This is a UX inconsistency rather than a crash-risk bug.

**Fix:** Consider showing ml directly on the y-axis for the day-detail chart, since all values are individual drink additions (typically < 1000 ml). Alternatively, use a unit-adaptive label: show ml when `value < 1000`, L otherwise.
```dart
getTitlesWidget: (value, meta) {
  if (value == meta.min || value == meta.max) {
    return const SizedBox.shrink();
  }
  final label = value < 1000
      ? '${value.toInt()} ml'
      : '${(value / 1000).toStringAsFixed(1).replaceAll(RegExp(r'\.?0+$'), '')} L';
  return SideTitleWidget(
    meta: meta,
    child: Text(label, style: const TextStyle(fontSize: 10)),
  );
},
```

---

_Reviewed: 2026-06-16_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
