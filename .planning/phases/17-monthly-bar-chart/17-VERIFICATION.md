---
phase: 17-monthly-bar-chart
verified: 2026-06-16T12:00:00Z
status: human_needed
score: 5/5 must-haves verified
overrides_applied: 0
human_verification:
  - test: "Visual rendering of bar chart in HistoryScreen"
    expected: "Bar chart appears below the calendar with one bar per day, green bars where target met, red bars where target not met, no bars for future days, dashed target line visible"
    why_human: "fl_chart rendering, color correctness, and layout pixel-accuracy cannot be verified without a running device or emulator"
  - test: "Tap-to-tooltip interaction (CHART-04)"
    expected: "Tapping a bar shows a tooltip with the exact ml value and date label"
    why_human: "Touch interaction and tooltip visibility require a running app"
  - test: "Month-switch updates chart (CHART-06)"
    expected: "Swiping the calendar to a different month causes the chart to update immediately to show that month's data"
    why_human: "Reactive rebuild on focusedMonthProvider change requires observing live app state"
  - test: "Empty-state month (CHART-05)"
    expected: "Navigating to a month with no logged data shows 'No data this month' text instead of chart bars"
    why_human: "Requires a test device with controlled data state; cannot simulate monthTotals.isEmpty without running the app"
  - test: "Dark mode color adaptation"
    expected: "Bars use green.shade400 / red.shade400 in dark mode and green.shade600 / red.shade600 in light mode"
    why_human: "Theme switching requires visual inspection on device"
---

# Phase 17: Monthly Bar Chart — Verification Report

**Phase Goal:** Users can see their daily hydration totals for any month as a bar chart directly below the calendar
**Verified:** 2026-06-16
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | User sees a bar chart below the calendar on the History screen showing one bar per day with ml totals for the displayed month (CHART-01) | VERIFIED | `MonthlyBarChart` inserted at line 257 of `history_screen.dart`, between `TableCalendar` (line 156) and `AnimatedSwitcher` (line 268). `BarChart` with `barGroups` built from `monthTotals` (one `BarChartGroupData` per day 1..lastValidDay). |
| 2 | When viewing the current month, bars appear only for today and past days — no bars for future days (CHART-02) | VERIFIED | `isCurrentMonth = year == now.year && month == now.month`; `lastValidDay = isCurrentMonth ? now.day : daysInMonth`; loop runs `for (int day = 1; day <= lastValidDay; day++)` — future days never enter `barGroups`. |
| 3 | A dashed horizontal line marks the current daily target on the chart (CHART-03) | VERIFIED | `ExtraLinesData(horizontalLines: [HorizontalLine(y: targetMl.toDouble(), strokeWidth: 1.5, dashArray: [8, 4])])` — present and wired to `targetMl` computed from `_findActiveTarget`. |
| 4 | Tapping a bar shows a tooltip with the exact ml value for that day (CHART-04) | VERIFIED (code path) | `BarTouchData(handleBuiltInTouches: true, touchTooltipData: BarTouchTooltipData(getTooltipItem: ...))` returns `BarTooltipItem` containing `'${rod.toY.toInt()} ml'`. `showingTooltipIndicators` is absent (correct per pitfall). Rendering requires human check. |
| 5 | When the user switches months the chart updates; months with no data show an empty-state message instead of the chart (CHART-05 + CHART-06) | VERIFIED (code path) | CHART-06: `MonthlyBarChart` receives `year: focused.year, month: focused.month` where `focused` comes from `focusedMonthProvider` (watched at line 86). `onPageChanged` writes to `focusedMonthProvider.notifier`, triggering rebuild. CHART-05: `if (monthTotals.isEmpty)` at line 67 returns a `Card` with `Text('No data this month')` before any chart rendering. |

**Score:** 5/5 truths verified (code path verification complete; visual/interactive verification human-gated)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `pubspec.yaml` | fl_chart dependency | VERIFIED | Line 35: `fl_chart: ^1.2.0` |
| `lib/presentation/widgets/monthly_bar_chart.dart` | MonthlyBarChart StatelessWidget, min 80 lines | VERIFIED | 279 lines; `class MonthlyBarChart extends StatelessWidget` confirmed; all constructor params (`monthTotals`, `year`, `month`, `targets`) present |
| `lib/presentation/screens/history_screen.dart` | MonthlyBarChart embedded | VERIFIED | Import at line 9; constructor call at lines 257-262 with all required props |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `history_screen.dart` | `monthly_bar_chart.dart` | `import` + `MonthlyBarChart(...)` in Column | WIRED | Import confirmed at line 9; constructor call at line 257 passing `monthTotals`, `year: focused.year`, `month: focused.month`, `targets` |
| `monthly_bar_chart.dart` | `fl_chart` | `BarChart(` widget with `BarChartData` | WIRED | `import 'package:fl_chart/fl_chart.dart'` at line 3; `BarChart(` at line 157 with full `BarChartData` |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|--------------|--------|--------------------|--------|
| `monthly_bar_chart.dart` | `monthTotals` (Map<String, int>) | `calendarMonthProvider(focused.year, focused.month).value` — Drift stream backed by SQLite | Yes — Drift stream query, not a static return | FLOWING |
| `monthly_bar_chart.dart` | `targets` (List<TargetHistoryEntry>) | `allTargetHistoryProvider` — Drift stream | Yes — Drift stream query | FLOWING |
| `monthly_bar_chart.dart` | `year`, `month` | `focusedMonthProvider` — Riverpod state, updated by `onPageChanged` | Yes — reactive to user calendar interaction | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| `monthly_bar_chart.dart` compiles without errors | `/Users/flavio.bizzarri/fvm/versions/3.44.1/bin/flutter analyze lib/presentation/widgets/monthly_bar_chart.dart lib/presentation/screens/history_screen.dart` | "No issues found!" | PASS |
| fl_chart dependency present in pubspec | `grep fl_chart pubspec.yaml` | `fl_chart: ^1.2.0` | PASS |
| File is substantive (>80 lines) | `wc -l monthly_bar_chart.dart` | 279 lines | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| CHART-01 | 17-01-PLAN.md | Bar chart with daily ml totals below calendar | SATISFIED | `barGroups` built from `monthTotals` keyed by day; `MonthlyBarChart` embedded in `HistoryScreen` Column after `TableCalendar` |
| CHART-02 | 17-01-PLAN.md | Current month bars only for today and past days | SATISFIED | `lastValidDay = isCurrentMonth ? now.day : daysInMonth` gates the bar-building loop |
| CHART-03 | 17-01-PLAN.md | Dashed horizontal line marks daily target | SATISFIED | `ExtraLinesData` with `HorizontalLine(dashArray: [8, 4])` at `targetMl.toDouble()` |
| CHART-04 | 17-01-PLAN.md | Tap tooltip shows exact ml value | SATISFIED (code) | `BarTouchData(handleBuiltInTouches: true)` with `getTooltipItem` returning `${rod.toY.toInt()} ml`; visual confirmation human-gated |
| CHART-05 | 17-01-PLAN.md | Empty state for months with no data | SATISFIED (code) | `if (monthTotals.isEmpty)` guard returns Card with `Text('No data this month')` |
| CHART-06 | 17-01-PLAN.md | Chart updates when user switches months | SATISFIED (code) | `MonthlyBarChart` receives `focused.year` / `focused.month`; `focusedMonthProvider` updated by `onPageChanged`; Riverpod rebuild chain verified |

All six CHART-01..CHART-06 requirements claimed in the PLAN are accounted for. CHART-07..CHART-11 are out of scope for Phase 17 (mapped to Phase 18 in REQUIREMENTS.md).

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | None found | — | — |

No TBD / FIXME / XXX / TODO / HACK / placeholder strings found in either modified file. No empty return stubs (`return null`, `return {}`, `return []`) that would indicate hollow implementation. `return Colors.transparent` for zero-intake bars is intentional per D-04 (no visible bar for zero) and data still flows through the loop.

### Human Verification Required

#### 1. Visual rendering — bar chart position and appearance

**Test:** Run `flutter run`, navigate to the History tab. Confirm the bar chart Card appears between the calendar and the day summary area.
**Expected:** Chart Card visible with bars sized proportionally, green for days meeting target, red for days below target, no bars rendered for future days in the current month, dashed horizontal line crossing the chart at the daily target level.
**Why human:** fl_chart rendering, pixel layout, and color accuracy cannot be asserted by static analysis.

#### 2. Tap-to-tooltip (CHART-04)

**Test:** On the History screen, tap any bar in the monthly chart.
**Expected:** A tooltip appears above the tapped bar showing the day/month label and the exact ml value (e.g., "16/06\n1800 ml").
**Why human:** Touch gesture dispatch and fl_chart tooltip overlay require a running app.

#### 3. Month switching updates chart (CHART-06)

**Test:** Swipe the calendar to a previous or future month.
**Expected:** The bar chart immediately updates to display data for the newly focused month. The chart height and bar pattern visibly change (or show empty state if no data).
**Why human:** Reactive rebuild on `focusedMonthProvider` change must be observed live; static grep confirms the data path is wired but cannot verify the rebuild fires correctly at runtime.

#### 4. Empty-state message (CHART-05)

**Test:** Navigate to any month before the user's first logged water entry.
**Expected:** The chart Card shows "No data this month" centered text instead of any bars or chart axes.
**Why human:** Requires a device with controlled data state where `monthTotals` is genuinely empty for a given month.

#### 5. Dark mode color adaptation

**Test:** Enable system dark mode and open the History screen.
**Expected:** Bars use `Colors.green.shade400` (brighter green) and `Colors.red.shade400` (brighter red). Disable dark mode — bars switch to `Colors.green.shade600` and `Colors.red.shade600` (deeper shades).
**Why human:** Theme color adaptation requires visual inspection; shade values are code-confirmed correct but perceptual accuracy needs human judgment.

### Gaps Summary

No code-level gaps found. All five ROADMAP success criteria are implemented with substantive, wired, data-flowing code. Five human-verification items remain (visual rendering, touch interaction, reactive month-switch, empty-state trigger, dark mode colors) which are inherent to a UI phase and cannot be resolved by static analysis.

---

_Verified: 2026-06-16T12:00:00Z_
_Verifier: Claude (gsd-verifier)_
