---
phase: 17-monthly-bar-chart
reviewed: 2026-06-16T00:00:00Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - lib/presentation/widgets/monthly_bar_chart.dart
  - lib/presentation/screens/history_screen.dart
  - pubspec.yaml
findings:
  critical: 1
  warning: 3
  info: 2
  total: 6
status: issues_found
---

# Phase 17: Code Review Report

**Reviewed:** 2026-06-16
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

Two source files were reviewed: the new `MonthlyBarChart` widget and the updated `HistoryScreen`. `pubspec.yaml` was clean — `fl_chart ^1.2.0` is correctly declared as a runtime dependency.

The most significant defect is in `MonthlyBarChart`: the chart picks a single target value for the entire month (the one effective at month-end) and applies it uniformly to color all bars. For any user who changed their daily target mid-month, every bar prior to that change is colored against the wrong target. This is a correctness bug that produces incorrect visual feedback — the primary purpose of the chart.

A second notable issue in `HistoryScreen` is that the calendar month data stream's error state is silently swallowed and displayed as an empty calendar, giving the user no feedback that something went wrong.

Three helper functions (`_toDateKey`, `_findActiveTarget`) are duplicated identically across `monthly_bar_chart.dart`, `history_screen.dart`, and `stream_providers.dart` — a maintenance hazard.

---

## Critical Issues

### CR-01: Bar chart colors all bars against the month-end target, ignoring mid-month target changes

**File:** `lib/presentation/widgets/monthly_bar_chart.dart:91-92`

**Issue:** The chart computes `targetMl` once using `endDateKey` (the last day of the displayed month) and then applies it to every bar in the month. If the user changed their daily target on, say, the 15th, bars for days 1–14 are still compared against the new target and colored incorrectly. A bar that was genuinely "met" under the old target will show red, and vice versa. This directly contradicts the "green when goal met, red when not" contract documented on the widget.

The fix is to call `_findActiveTarget` per day inside the loop, identical to how `history_screen.dart` colors individual calendar cells (lines 193–209 there already do this correctly):

```dart
// BEFORE (line 91-92, single target for entire month):
final endDateKey = _toDateKey(DateTime(year, month, daysInMonth));
final targetMl = _findActiveTarget(targets, endDateKey);

// AFTER: remove both lines above; compute per-day inside the loop:
for (int day = 1; day <= lastValidDay; day++) {
  final dateKey = _toDateKey(DateTime(year, month, day));
  final total = monthTotals[dateKey] ?? 0;
  final toY = total.toDouble();

  final targetMl = _findActiveTarget(targets, dateKey); // per-day

  if (toY > actualMaxValue) actualMaxValue = toY;
  // ... rest of loop unchanged
}

// For the target line, use month-end target (acceptable — line represents
// the "current" target for context, not a per-day value):
final endDateKey = _toDateKey(DateTime(year, month, daysInMonth));
final lineTargetMl = _findActiveTarget(targets, endDateKey);
```

Note: The horizontal reference line showing the target (`extraLinesData`) can reasonably keep using the month-end target as a visual reference, but bar coloring must be per-day.

Also note: the `maxY` computation on line 143 uses `targetMl.toDouble()` — after extracting it from the loop this needs to account for the maximum target encountered across all days, or simply use the month-end target for the axis ceiling (acceptable).

---

## Warnings

### WR-01: calendarMonthProvider error state silently renders as empty calendar

**File:** `lib/presentation/screens/history_screen.dart:97-99`

**Issue:** The `calendarMonthProvider` stream result is accessed via `.value` with a fallback to an empty map. When the stream is in `AsyncValue.error`, `.value` returns `null` and the calendar renders as if there is simply no data this month — no spinner, no error message. The user has no way to know data failed to load.

```dart
// CURRENT (line 97-99): silently discards error state
final monthTotals =
    ref.watch(calendarMonthProvider(focused.year, focused.month)).value ??
        <String, int>{};
```

**Fix:** Handle all three states explicitly. The most practical approach given the surrounding `targetsAsync.when` pattern is to use `when` or at minimum check for error:

```dart
final monthAsync = ref.watch(calendarMonthProvider(focused.year, focused.month));

// Option A: show spinner/error inline (replace references to monthTotals below):
if (monthAsync.isLoading) {
  return const Center(child: CircularProgressIndicator());
}
if (monthAsync.hasError) {
  return Center(child: Text(context.l10n.errorLoadingData));
}
final monthTotals = monthAsync.value ?? <String, int>{};
```

If a full-screen replacement is too disruptive for UX, at minimum add an error banner, but silently swallowing the error state should not ship.

---

### WR-02: Future-day tap rejection uses DateTime comparison instead of date comparison

**File:** `lib/presentation/screens/history_screen.dart:171`

**Issue:** `selectedDay.isAfter(DateTime.now())` compares full `DateTime` values including time-of-day components. `selectedDay` comes from `TableCalendar` which provides dates at midnight (`2026-06-16 00:00:00.000`), while `DateTime.now()` includes the current time (e.g., `2026-06-16 14:32:11.123`). For every tap on today's date, `selectedDay` (`00:00:00`) is **before** `DateTime.now()` (`14:32:11`), so the guard is not triggered — that works by accident. However, at exactly midnight, a tap on "today" (which TableCalendar provides as `2026-06-17 00:00:00`) could race with `DateTime.now()` returning `2026-06-17 00:00:00.001` and permit it. This is a marginal edge case but the intent is clearly to block future *dates*, not future *moments*.

**Fix:**
```dart
// BEFORE:
if (selectedDay.isAfter(DateTime.now())) return;

// AFTER: strip time components from both sides
final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
final selected = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
if (selected.isAfter(today)) return;
```

---

### WR-03: Duplicated helper functions across three files

**Files:**
- `lib/presentation/widgets/monthly_bar_chart.dart:12-31`
- `lib/presentation/screens/history_screen.dart:13-32`
- `lib/core/providers/stream_providers.dart:15-17` (`_toDateKey` only)

**Issue:** `_toDateKey` is copied verbatim in all three files. `_findActiveTarget` is copied verbatim in both `monthly_bar_chart.dart` and `history_screen.dart`. The comment on line 9 of `monthly_bar_chart.dart` even acknowledges the duplication. Three copies of a pure function with no tests means a bug in one copy (e.g., forgetting `padLeft` for a field) would silently produce wrong date keys in only some contexts.

**Fix:** Extract both helpers to a shared utility file and import from there:

```dart
// lib/core/utils/date_key.dart
String toDateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

// lib/core/utils/target_lookup.dart  (or same file)
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

### IN-01: maxY computation uses a single targetMl after CR-01 fix — needs update

**File:** `lib/presentation/widgets/monthly_bar_chart.dart:143`

**Issue:** Line 143 computes `max(actualMaxValue, targetMl.toDouble()) * 1.1`. After fixing CR-01 (per-day target lookup), `targetMl` will no longer exist as a single variable at this scope. The axis ceiling should use the maximum target encountered across all days in the loop, or the month-end target, to ensure bars never exceed the chart bounds.

This is flagged as Info because it is a follow-on consequence of CR-01, not an independent defect, but it must not be overlooked during the fix.

**Fix:** Inside the loop, also track `maxTargetSeen`:
```dart
double maxTargetSeen = 0;
for (int day = 1; day <= lastValidDay; day++) {
  final targetMl = _findActiveTarget(targets, dateKey);
  if (targetMl.toDouble() > maxTargetSeen) maxTargetSeen = targetMl.toDouble();
  // ...
}
final computedMax = max(actualMaxValue, maxTargetSeen) * 1.1;
```

---

### IN-02: riverpod_lint / custom_lint excluded due to version conflict

**File:** `pubspec.yaml:66-68`

**Issue:** The comment states `riverpod_lint` and `custom_lint` are excluded due to an analyzer version conflict between `drift_dev 2.33.0` (`analyzer >=10.0.0`) and `custom_lint` (`analyzer ^8.0.0`). Without `riverpod_lint`, common Riverpod mistakes (missing `ProviderScope`, `ref` escaping `build`) are not caught at analysis time. This is a known workaround, not introduced by this phase, but it is worth tracking.

**Fix:** No immediate action required. Monitor `custom_lint` releases for compatibility with `analyzer >=10.0.0`. Consider filing an issue on the `custom_lint` repository if not already tracked.

---

_Reviewed: 2026-06-16_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
