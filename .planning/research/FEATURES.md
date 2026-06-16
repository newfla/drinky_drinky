# Feature Landscape: Bar Chart UX for Mobile Hydration Tracker

**Domain:** Bar chart visualizations in a mobile health/hydration tracking app (FL Chart on Flutter)
**Researched:** 2026-06-16
**Overall confidence:** HIGH (fl_chart API verified via Context7; UX patterns drawn from Apple HIG principles, Material Design data-viz guidance, and competitive analysis of health-tracking apps)

---

## Table Stakes

Features users expect from bar charts in a health/hydration tracking context. Missing any = charts feel broken or decorative rather than useful.

### Monthly Bar Chart (under the calendar)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| One bar per day of the visible month | Core data representation; maps 1:1 to calendar days above | Low | fl_chart `BarChartGroupData.x` = day-of-month (1..31); `toY` = total ml. Data already available from `calendarMonthProvider` |
| Goal reference line (horizontal dashed line at target ml) | Without a reference, raw ml numbers are meaningless -- user cannot tell if 1500 ml was good or bad | Low | fl_chart `ExtraLinesData` with `HorizontalLine(y: targetMl)`. Use dashed style via `dashArray`. Per-day target complicates this -- use current month's dominant target or show no line if multiple targets apply |
| Green/red bar coloring matching calendar decoration | Consistency with existing green (goal met) / red (goal missed) calendar dots; otherwise the two visualizations tell conflicting stories | Low | Reuse exact same green/red logic from `_buildDayCell`: compare day total to `_findActiveTarget()`. Days with no data = no bar (absent from map) |
| X-axis day labels (subset -- not all 31) | Labeling every day creates overlap on mobile screens; showing none removes orientation | Low | Show labels at days 1, 5, 10, 15, 20, 25, and last day of month. Or every 7th day. `getTitlesWidget` callback controls this |
| Y-axis ml labels | User needs scale context to interpret bar heights | Low | Show 2-3 labels: 0, mid-point, and max (rounded to nearest 500 ml). Use `reservedSize` to prevent overlap with chart area |
| Sync with calendar page changes | When user swipes to a different month on the calendar, the bar chart below must update to match | Low | Both already watch `focusedMonthProvider` -- chart widget watches same `calendarMonthProvider(year, month)` family provider |
| Empty state when no entries exist for the month | A blank chart with axes but no bars is confusing; user needs a clear "no data" message | Low | Check if `monthTotals` map is empty; if so, show a centered text placeholder instead of an empty chart frame |
| Implicit animation on data change | Bars should animate smoothly when switching months or when new data arrives; abrupt redraws feel broken | Low | fl_chart provides built-in implicit animation via `duration` and `curve` parameters on `BarChart()`. Default 150ms is fine |
| Bars for future days are absent | Showing zero-height bars for days that have not happened yet implies the user failed those days | Low | Only generate `BarChartGroupData` for days <= today (for current month) or all days (for past months) |
| Touch-to-see-value tooltip | Tapping a bar should show the exact ml value -- users expect to be able to read precise numbers, not just compare heights | Low | fl_chart `BarTouchData(handleBuiltInTouches: true)` with `BarTouchTooltipData`. Format tooltip as "1,250 ml" using `intl.NumberFormat` |
| Dark mode support | App already supports dark mode via Material You; charts that ignore theme look broken | Med | Use `Theme.of(context).colorScheme` for grid lines, text colors, tooltip backgrounds. Green/red already have dark-mode variants in `_buildDayCell` |

### Day Detail Chart (push navigation screen)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| One bar per individual intake entry | Core purpose of this screen -- show when and how much the user drank throughout the day | Low | Each `WaterEntryEntity` becomes a `BarChartGroupData`. x = index or time-derived position, toY = amountMl |
| X-axis time labels (HH:mm) | User wants to see when they drank, not just how much | Med | Extract hour:minute from `WaterEntryEntity.loggedAt`. Label every bar or every Nth bar depending on density. Use `DateFormat.Hm()` for locale-aware formatting |
| Y-axis ml labels | Same reasoning as monthly chart -- scale context | Low | Same approach: 0 to max entry, 2-3 labels |
| Total summary text | User wants the day's total prominently displayed, not just individual bars | Low | Sum all entries; display as "Total: X.XX L" or "Total: X,XXX ml" above or below the chart |
| Touch-to-see-value tooltip with time and amount | Tapping a bar should show both the amount and the exact time | Low | `getTooltipItem` callback formats as "250 ml\n14:30" |
| Empty state for days with no entries | User navigates to a day with no data -- should see a clear message, not a broken chart | Low | Check entries list; if empty, show "No entries for this day" text |
| Back navigation to history screen | Standard mobile navigation -- user pushed in, must be able to go back | Low | Standard `Navigator.pop()` or GoRouter equivalent. AppBar back button |

---

## Differentiators

Features that go beyond minimum expectations and add genuine value. Not expected, but make the chart transition from "decorative" to "genuinely useful."

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Goal target background bar** (backDrawRodData) | Show a faded bar at the target height behind each day's actual bar. Instantly communicates "how close was I" without needing a reference line. Used by Apple Health, Fitbit, WaterMinder | Med | fl_chart `backDrawRodData: BackgroundBarChartRodData(toY: targetMl, color: grey.withOpacity(0.15))`. Per-day targets mean each bar may have a different background height -- query from `allTargetHistoryProvider` |
| **Tap bar to navigate to day detail** (monthly chart) | Connecting the monthly overview to the day detail via tap eliminates a two-step navigation (select day on calendar, then tap something). Chart becomes interactive, not just visual | Med | `touchCallback` on `BarTouchData` detects `FlTouchEvent is FlTapUpEvent`, extracts `groupIndex` to determine which day was tapped, then pushes day detail route |
| **Day total text above each bar** (monthly chart) | For months with few entries, showing the total above each bar eliminates the need to tap every bar for its value | Med | fl_chart `BarChartRodLabel(show: true)` or a custom positioned text. Risk: overlapping labels in dense months. Consider showing only when bar count is low (< 10 bars) or only for the tapped bar |
| **Color gradient on bars** (progress feel) | A gradient from light-to-dark blue (below target) or green (above target) adds visual richness without information overload | Low | fl_chart `gradient` parameter on `BarChartRodData`. Use `LinearGradient` from bottom-to-top |
| **Rounded bar tops** | Rounded caps look more polished than flat-top rectangles; matches the soft visual language of the existing circular progress indicator | Low | `borderRadius: BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4))` |
| **Today's bar highlighted** (monthly chart) | On the current month view, today's bar should be visually distinct (border, different shade, or a small indicator) so the user's eye is drawn to "how am I doing right now" | Low | Conditionally apply a `borderSide` or different color to today's bar group |
| **Semantic accessibility labels** | VoiceOver/TalkBack should describe each bar: "June 15, 1250 milliliters, 83% of goal" | Med | fl_chart does not provide built-in semantics. Wrap the `BarChart` widget in a `Semantics` widget with a custom label summarizing the chart data, or use `ExcludeSemantics` on the chart and place an invisible `ListView` of semantic descriptions behind it |
| **Chart height adapts to context** | Monthly chart: shorter (embedded below calendar in a scroll). Day detail: taller (main content). Using `AspectRatio` or fixed height prevents layout issues | Low | Monthly: `SizedBox(height: 180)`. Day detail: `AspectRatio(aspectRatio: 1.5)` |

---

## Anti-Features

Features to explicitly NOT build. Each represents a trap that adds complexity without proportional value for a personal hydration tracker.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **Pinch-to-zoom on monthly chart** | 31 bars on a phone screen are already at useful density; zooming into a subset of days adds interaction complexity without insight. No health app does this for monthly views | Keep bars at fixed width; rely on tap-to-tooltip for precise values |
| **Horizontal scrolling monthly chart** | Defeats the purpose of "at a glance" monthly overview; user loses spatial orientation of which day is which | Show all days of the month at once; bars can be thin (4-6px width). Months with 28-31 days always fit in screen width |
| **Weekly/custom date range selector** | Scope is monthly (synced with calendar above) and daily (detail screen). A custom range picker adds UI complexity for a utility app | Monthly view is the calendar-month. For trends across months, that is a v2 feature (fl_chart line charts) |
| **Animated bar-by-bar sequential entrance** | Staggered animations (bar 1 grows, then bar 2, then bar 3...) are visually busy and slow for 31 bars. They delay information delivery | Use fl_chart's implicit swap animation (all bars animate simultaneously when data changes). Duration: 150-300ms |
| **3D or skeuomorphic bar styling** | Does not match Material 3 design language; harder to read accurately; accessibility concerns | Flat bars with optional subtle gradient. Material You color tokens |
| **Cumulative/stacked bars on monthly chart** | Each day is independent in a hydration tracker -- there is nothing to stack. Stacking intake types (water vs coffee) is v2 scope at best | One bar per day, one color (green/red based on goal), one value (total ml) |
| **Export chart as image** | Niche feature for a personal tracker; adds platform-specific screenshot/share complexity | If users want to share, they can use OS screenshot |
| **Real-time bar growth animation on home screen** | The home screen already has the circular progress indicator for "right now" feedback. Adding a live-updating bar there would be redundant and distracting | Keep charts on the history screen only; home screen = circular progress ring |

---

## Feature Dependencies

```
calendarMonthProvider (existing) --> Monthly bar chart data source
  |
  +--> Bar chart syncs on focusedMonthProvider changes (existing)

allTargetHistoryProvider (existing) --> Per-day target for green/red coloring + goal line
  |
  +--> _findActiveTarget() logic (existing) reused for bar color decisions

waterEntriesForDate provider (existing) --> Day detail chart data source
  |
  +--> Needs dateKey parameter from selected/tapped day

Monthly bar chart tap interaction --> Day detail screen (NEW navigation route)
  |
  +--> GoRouter route addition required
  +--> Receives dateKey as parameter

Day detail screen --> waterEntriesForDate(dateKey) provider
  |
  +--> Individual entries with loggedAt timestamps for x-axis

Dark mode colors --> Theme.of(context) (existing infrastructure)
  |
  +--> Green/red dark-mode variants already defined in history_screen.dart

Localization --> l10n strings (existing infrastructure)
  |
  +--> New ARB keys needed: chart axis labels, tooltips, empty states, screen title
```

### Dependency on Existing History Screen

The monthly bar chart must integrate into the existing `HistoryScreen` widget, which currently contains:
1. A `SingleChildScrollView` with `Column` children
2. A streak card at the top
3. A `TableCalendar` widget
4. An `AnimatedSwitcher` day summary card at the bottom

The bar chart should be inserted between the calendar and the day summary card (position 3.5). This means:
- It lives inside the same `SingleChildScrollView` and must not be independently scrollable
- It watches the same `focusedMonthProvider` as the calendar
- It watches the same `calendarMonthProvider(year, month)` family provider
- It reuses the same green/red color logic and dark-mode handling

The day detail screen is a new push route, independent of the history screen layout.

---

## MVP Recommendation

### Phase 1: Monthly Bar Chart (embed in history screen)

Prioritize these table-stakes features:
1. One bar per day, green/red coloring, synced with calendar month
2. Goal reference line (horizontal dashed)
3. X-axis day labels (subset), Y-axis ml labels
4. Touch tooltip showing exact ml value
5. Empty state for months with no data
6. Future days absent from chart
7. Implicit animation on month change
8. Dark mode support

Plus these high-value, low-complexity differentiators:
- Rounded bar tops (trivial)
- Today's bar highlighted (trivial)

### Phase 2: Day Detail Screen (push navigation)

Prioritize:
1. New GoRouter route accepting dateKey parameter
2. Bar chart with one bar per intake entry, x-axis = time, y-axis = ml
3. Total summary text
4. Touch tooltip with time and amount
5. Empty state
6. Back navigation

Plus:
- Tap-to-navigate from monthly chart bar to day detail (connects the two)

### Defer

- **Goal background bars** (backDrawRodData): Nice but not essential; adds per-day target complexity. Good candidate for a polish pass after core charts work.
- **Semantic accessibility labels**: Important for accessibility but requires careful design of invisible semantic tree. Address in a dedicated accessibility pass.
- **Day total text above bars**: Risk of overlap; punt until chart is working and visually tuned.
- **Color gradient on bars**: Polish item; add after core coloring (green/red) is correct.

---

## What Makes Charts Useful vs Decorative

Based on analysis of successful health-tracking apps (Apple Health, Fitbit, WaterMinder, MyFitnessPal), the line between "useful chart" and "decorative chart" comes down to three properties:

### 1. Context (the goal line)

A bar chart showing "1,500 ml on June 10" is meaningless without knowing the target was 2,000 ml. The single most important feature that makes a hydration chart useful is the **goal reference line**. Without it, the user is looking at abstract heights. With it, every bar instantly communicates "above target" or "below target." The green/red coloring reinforces this, but the line provides the continuous reference.

### 2. Actionability (tap-to-detail)

A chart that you can only look at is a picture. A chart you can tap into to see details becomes a navigation tool. The monthly bar chart should drive exploration: "I see a short red bar on June 8 -- let me tap to see what happened that day." This converts the chart from a passive visualization into an active investigation tool.

### 3. Integration (not an island)

The chart must be woven into the existing screen, not bolted on. It shares the same month as the calendar above. It uses the same colors. It responds to the same interactions (swiping months). If the chart and the calendar tell different stories or respond to different gestures, the user perceives the chart as a gimmick.

---

## Localization Considerations

New ARB string keys needed for chart features:

| Key | English | Purpose |
|-----|---------|---------|
| `chartNoDataMonth` | "No intake data for this month" | Monthly chart empty state |
| `chartNoDataDay` | "No entries for this day" | Day detail empty state |
| `chartTooltipMl` | "{amount} ml" | Tooltip format (parameterized) |
| `chartTooltipTime` | "{time}" | Tooltip time line (parameterized, locale-formatted) |
| `chartDayDetailTitle` | "Daily Detail" | Day detail screen AppBar title |
| `chartTotalLabel` | "Total: {total} ml" | Day detail total summary |
| `chartGoalLine` | "Goal" | Label for the horizontal goal reference line (optional) |

All values should use ICU MessageFormat with placeholders. No new plural forms needed.

---

## Sources

- fl_chart BarTouchData API: https://pub.dev/documentation/fl_chart/latest/fl_chart/BarTouchData/BarTouchData.html (verified via Context7, HIGH confidence)
- fl_chart BarChartRodData API: https://pub.dev/documentation/fl_chart/latest/fl_chart/BarChartRodData/BarChartRodData.html (verified via Context7, HIGH confidence)
- fl_chart ExtraLinesData / HorizontalLine: https://github.com/imanneo/fl_chart/blob/main/repo_files/documentations/base_chart.md (verified via Context7, HIGH confidence)
- fl_chart BackgroundBarChartRodData: https://pub.dev/documentation/fl_chart/latest/fl_chart/BackgroundBarChartRodData-class.html (verified via Context7, HIGH confidence)
- fl_chart implicit animation: https://github.com/imanneo/fl_chart/blob/main/repo_files/documentations/bar_chart.md (verified via Context7, HIGH confidence)
- fl_chart BarTouchTooltipData: https://pub.dev/documentation/fl_chart/latest/fl_chart/BarTouchTooltipData/BarTouchTooltipData.html (verified via Context7, HIGH confidence)
- Existing codebase: `history_screen.dart`, `stream_providers.dart`, `water_entry_dao.dart`, `water_repository.dart` (direct code review)
- Apple HIG chart principles: 44pt minimum touch targets, don't rely solely on color, animate subtly (MEDIUM confidence -- fetched but partial rendering)
