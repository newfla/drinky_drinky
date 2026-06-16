# Domain Pitfalls

**Domain:** Adding fl_chart BarChart to an existing Flutter + Riverpod + Drift hydration tracker
**Researched:** 2026-06-16
**Confidence:** HIGH (Context7 fl_chart docs, GitHub source code, existing codebase analysis)

## Critical Pitfalls

Mistakes that cause crashes, blank screens, or require rewrites.

### Pitfall 1: maxY Defaults to NaN -- All-Zero and Empty-Month Charts Render Blank or Crash

**What goes wrong:** When all bars in a month have `toY: 0` (new user, month with no logged entries) or `barGroups` is empty, fl_chart's auto-calculated `maxY` resolves to `0` (from the internal `calculateMaxAxisValues()` helper). The chart either renders as a flat line at the bottom or, depending on downstream math (0-based scaling), produces visual artifacts. If `barGroups` is empty and `maxY` is left as the default `double.nan`, the chart renders nothing but still reserves layout space, confusing the user.

**Why it happens:** The existing `calendarMonthProvider` returns a `Map<String, int>` where absent keys mean "no data for that day." When converting to `BarChartGroupData`, developers often skip days with no data (producing fewer than 28-31 bars) or set `toY: 0` for them. fl_chart does not crash on empty groups -- it returns `(0, 0)` from `calculateMaxAxisValues()` -- but the result is a visually meaningless chart.

**Consequences:**
- Blank chart area with axis labels but no visible bars (silent failure)
- If `maxY` is explicitly set to `0`, grid lines and tooltips may produce division-by-zero artifacts
- Users see a chart that looks "broken" on months where they barely used the app

**Prevention:**
- Always generate exactly N `BarChartGroupData` items (where N = number of days in the focused month), with `toY: 0.0` for days with no data. Never skip days.
- Always provide an explicit `maxY` that is at least some sensible minimum (e.g., `max(actualMaxValue, dailyTarget.toDouble())`). This guarantees a meaningful Y axis even when all values are zero.
- Show an empty-state message ("No data this month") instead of a chart when the month has zero total intake. Check `monthTotals.isEmpty` before rendering the chart widget at all.

**Detection:** Test with a fresh database, test with a month where only 1-2 days have data.

---

### Pitfall 2: Implicit Animation Crash on Bar Count Change Between Months

**What goes wrong:** fl_chart uses implicit animations via `lerp()` between old and new `BarChartData`. The `lerpBarChartRodDataList` function interpolates between the old and new lists of `BarChartGroupData`. When the user swipes from a 31-day month to a 28-day month (or vice versa), the bar count changes. fl_chart handles this gracefully in its lerp (it pads or truncates the list during interpolation), but the `x` values shift during the animation, causing day labels on the bottom axis to briefly show incorrect numbers -- day "29" animates into day "1", for example.

**Why it happens:** The lerp implementation interpolates `x` between the old and new group: `(a.x + (b.x - a.x) * t).round()`. If old month has groups x=0..30 and new month has x=0..27, during animation the last 3 groups animate x from 28/29/30 toward lower values, producing transient garbage on the bottom axis.

**Consequences:**
- Visually confusing animation artifacts during month transitions
- Bottom axis labels briefly show wrong day numbers
- Does not crash, but looks unprofessional

**Prevention:**
- Set `duration: Duration.zero` (disable animation) or use a very short duration (50ms) to make lerp artifacts imperceptible.
- Alternatively, use a `ValueKey` on the `BarChart` widget keyed to `'$year-$month'` so Flutter destroys and recreates the widget on month change instead of animating.
- The `ValueKey` approach is simpler and recommended for this use case since month-to-month animation is not expected UX in a calendar chart.

**Detection:** Navigate between February (28 days) and March (31 days) in the calendar while watching for animation glitches.

---

### Pitfall 3: showingTooltipIndicators Index Out of Bounds on Data Change

**What goes wrong:** If `showingTooltipIndicators` is hardcoded with indices (e.g., `[0]` to always show a tooltip), and the bar data changes such that the referenced rod index no longer exists, fl_chart crashes with `RangeError (length): Invalid value: Not in inclusive range 0..N: M`. This is a confirmed bug (GitHub issue #1911).

**Why it happens:** In a Riverpod reactive setup, the chart data rebuilds whenever the Drift stream emits. If the developer uses `showingTooltipIndicators` to pin tooltips on specific bars, the indices can reference rods that no longer exist after a data update.

**Consequences:** Hard crash during paint phase -- `drawTouchTooltip` accesses an invalid array index.

**Prevention:**
- Do not use `showingTooltipIndicators` at all for this use case. Rely on `handleBuiltInTouches: true` for tap-to-show tooltips instead.
- If pinned tooltips are needed, always rebuild `showingTooltipIndicators` in the same pass as the bar data, validating indices against the current rod count.

**Detection:** Rapidly tap through months while tooltips are visible.

---

### Pitfall 4: Drift Stream Resubscription Thrashing When Calendar Month Changes

**What goes wrong:** The existing `calendarMonthProvider(year, month)` is a family provider that creates a new Drift stream subscription per (year, month) pair. When the user swipes the TableCalendar, `onPageChanged` fires with a new `focusedDay`, which updates `focusedMonthProvider`, which triggers the chart to watch a new `calendarMonthProvider(newYear, newMonth)`. If the chart provider also sets up its own family provider watching `calendarMonthProvider`, there is a chain of: page change -> focused month update -> calendar month provider resubscribe -> chart provider resubscribe. This causes a visible loading flash (the `AsyncValue` goes through `loading` briefly) every time the user swipes months.

**Why it happens:** Riverpod autoDispose family providers transition through `loading` state when a new family key is watched for the first time. The calendar provider already handles this for the calendar grid, but a new chart provider layered on top amplifies the effect.

**Consequences:**
- Loading spinner/shimmer flashes on every month swipe
- Two separate loading states (calendar + chart) that resolve at different times
- User perceives the History screen as "slow"

**Prevention:**
- Reuse the existing `calendarMonthProvider` data for the chart instead of creating a separate chart-specific provider. The `Map<String, int>` it returns already contains all daily totals needed for the monthly bar chart.
- Convert the `calendarMonthProvider` output to `BarChartGroupData` in a derived (computed) provider that does NOT make its own DB call. This way there is only one stream subscription and one loading state per month.
- Pattern: `@riverpod monthlyBarChartData(ref, year, month) { final totals = ref.watch(calendarMonthProvider(year, month)); return totals.when(...convert to BarChartGroupData...); }`

**Detection:** Swipe rapidly through 5-6 months and observe whether charts flash or stutter.

---

### Pitfall 5: GoRouter Sub-Route Under StatefulShellBranch Breaks Navigation Stack

**What goes wrong:** Adding a `/history/:dateKey` sub-route under the `/history` branch of `StatefulShellRoute.indexedStack` causes the day detail screen to render inside the history tab's navigation area with the bottom navigation bar still visible. If done incorrectly (as a sibling route instead of child route), GoRouter may not maintain the history tab's navigation stack, causing back-button to jump to home instead of back to the calendar.

**Why it happens:** `StatefulShellRoute.indexedStack` maintains separate navigation stacks per branch. Sub-routes must be declared as children of the branch's `GoRoute`, not as top-level routes. The existing router has `/history` as a leaf route with no children.

**Consequences:**
- Day detail screen either shows with bottom nav bar (if child of branch) or without it (if top-level route) -- developer must choose intentionally
- Back navigation may break if the route is not properly nested
- If declared as top-level route, the history tab loses its selected state

**Prevention:**
- For a full-screen day detail (no bottom nav), add it as a top-level `GoRoute` outside `StatefulShellRoute`: `GoRoute(path: '/day-detail/:dateKey', builder: ...)`. Navigate with `context.push('/day-detail/$dateKey')`.
- For a day detail inside the history tab (with bottom nav), change `/history` from a leaf to a parent with children: `GoRoute(path: '/history', builder: ..., routes: [GoRoute(path: 'day/:dateKey', builder: ...)])`. Navigate with `context.go('/history/day/$dateKey')`.
- Decision should be explicit in the spec. Full-screen push (top-level route) is recommended for charts because it gives more vertical space and a clearer "drill down then back" UX.

**Detection:** Navigate to day detail, then press system back button. Verify you return to history (not home). Verify bottom nav state is correct.

## Moderate Pitfalls

### Pitfall 6: Bottom Axis Label Overlap for 28-31 Day Months

**What goes wrong:** A monthly bar chart has 28-31 bars. With `SideTitles.interval: 1` on the bottom axis, every day shows a label. On a phone screen (360-414dp wide), 31 labels at even 10px each total 310px plus spacing, causing labels to overlap and become unreadable.

**Prevention:**
- Set `interval` to show only every 5th or 7th day (e.g., 1, 5, 10, 15, 20, 25, [28-31]).
- Use `getTitlesWidget` callback to return `SizedBox.shrink()` for non-milestone days.
- Set `reservedSize` appropriately (at least 30) for bottom titles.
- Consider rotating labels 45 degrees via `RotatedBox` in `getTitlesWidget` if all days must be shown.

**Detection:** Test on a 360dp-wide device with a 31-day month.

---

### Pitfall 7: Chart Does Not React to New Water Entry Added on Home Screen

**What goes wrong:** The user adds water on the Home tab, switches to History tab, and the chart still shows old data. This happens if the chart provider is not derived from the same reactive Drift stream as the calendar.

**Why it happens:** If the chart has its own `Future`-based provider (e.g., a one-shot query on tab switch rather than a stream), it will not receive Drift's change notifications. The existing calendar already uses stream-based `calendarMonthProvider`, so the fix is straightforward -- but creating a separate chart provider that uses `Future` instead of `Stream` is a natural mistake.

**Prevention:**
- Derive chart data from `calendarMonthProvider` (stream-based), not from a new one-shot query.
- The existing codebase already learned this lesson with BUG-04 (HistoryScreen reactivity fix in v1.4): stream providers are required for cross-tab reactivity in `StatefulShellRoute.indexedStack`.
- Never use `FutureProvider` for data that can change while the screen is alive in an `indexedStack`.

**Detection:** Add water on Home, switch to History without restarting app. Chart should update.

---

### Pitfall 8: Drift watchEntriesInRange Fetches All Rows, Not Aggregates

**What goes wrong:** The existing `watchDailyTotalsInRange` in `WaterRepository` calls `watchEntriesInRange`, which fetches ALL individual `WaterEntry` rows for the date range, then groups and sums them in Dart. For the monthly bar chart this means fetching potentially hundreds of rows per month when only 28-31 aggregate values are needed.

**Why it happens:** The original query was designed for the calendar feature where individual entries were not needed for aggregation (just row-level access for the streak provider). The in-Dart `groupBy` + `fold` pattern works but is not optimal for a chart that only needs daily totals.

**Consequences:**
- Unnecessary memory allocation for row-level data that is immediately discarded
- Drift must deserialize every row from SQLite before Dart can aggregate
- For power users with many entries per day (e.g., 10-15 entries daily over months), this compounds

**Prevention:**
- For the monthly chart, consider creating a new Drift DAO method that does the aggregation in SQL:
  ```dart
  Stream<List<TypedResult>> watchDailyTotalsAggregated(String startKey, String endKey) {
    final sum = waterEntries.amountMl.sum();
    final query = selectOnly(waterEntries)
      ..addColumns([waterEntries.dateKey, sum])
      ..where(waterEntries.dateKey.isBiggerOrEqualValue(startKey) &
              waterEntries.dateKey.isSmallerOrEqualValue(endKey))
      ..groupBy([waterEntries.dateKey]);
    return query.watch();
  }
  ```
- Alternatively, accept the current approach for v1.5 (it works, just suboptimal) and add a performance note for future optimization. The existing index on `dateKey` makes the query fast regardless.
- For the daily detail chart (entries by hour), the existing `watchEntriesForDate` is already correct -- individual entry rows are needed.

**Detection:** Profile with `flutter run --profile` and check frame times when loading a month with 15+ entries per day.

---

### Pitfall 9: Bar Width Not Adaptive to Month Length

**What goes wrong:** Using a fixed `width` (e.g., `width: 12`) for `BarChartRodData` looks fine for 28-day months but causes bars to overlap or leave excessive gaps for 31-day months (or months with only partial data displayed). The default `BarChartAlignment.spaceEvenly` distributes bars evenly within the available width, but fixed-width bars may visually collide when the chart is narrow.

**Prevention:**
- Calculate bar width dynamically: `final barWidth = max(4.0, (chartWidth - totalPadding) / daysInMonth - spacing);`
- Or use a narrow fixed width (6-8px) that works for the worst case (31 days on a 360dp screen).
- Use `BarChartAlignment.spaceEvenly` (the default) and test with both 28 and 31 day months.
- Wrap the chart in a `LayoutBuilder` to get actual available width for the calculation.

**Detection:** Compare visual appearance of February vs August chart on the narrowest supported device.

---

### Pitfall 10: TableCalendar and BarChart Month Desync

**What goes wrong:** The TableCalendar's `onPageChanged` updates `focusedMonthProvider`, which the chart watches. But `onPageChanged` fires with the `focusedDay` parameter, which is the middle of the new month page. If the user swipes to a new month but the `focusedDay` has a different year-month than expected (e.g., during January-December boundary), the chart may show data for the wrong month.

**Why it happens:** `onPageChanged` provides a `DateTime` that represents the page's focused day. The existing code correctly extracts `.year` and `.month` from it. However, if a developer mistakenly uses `onDaySelected`'s focusedDay (which can lag behind page changes), the chart and calendar can show different months.

**Prevention:**
- Always derive the chart's year/month from `focusedMonthProvider`, which is already updated by `onPageChanged`.
- Never add a separate "chart month" state variable. Single source of truth for the displayed month.
- The existing `focusedMonthProvider` is the correct mechanism. The chart should watch it, not maintain its own month state.

**Detection:** Swipe TableCalendar from December to January (year boundary). Verify chart shows correct month.

---

### Pitfall 11: Daily Detail Chart -- Time-Based X Axis Gaps

**What goes wrong:** The daily detail chart shows individual water entries with time on the X axis. If entries are at 8:00, 12:00, and 22:00, a naive approach using sequential x values (0, 1, 2) misrepresents the time gaps between entries. The chart appears evenly spaced when the actual consumption was clustered in the morning.

**Why it happens:** fl_chart `BarChartGroupData.x` is a positional double, not a time value. Developers often use the index of the entry as `x`, losing temporal information.

**Prevention:**
- Use the hour as the x value for a 24-hour axis: `x: entry.loggedAt.hour` (or fractional: `x: entry.loggedAt.hour + entry.loggedAt.minute / 60.0`).
- If multiple entries share the same hour, stack them (sum the amounts for that hour) rather than creating overlapping bars.
- Set explicit `minX: 0` and `maxX: 24` (or the hour range of the day) to maintain consistent scale. Note: `BarChartData` does not have `minX`/`maxX` properties (unlike `LineChartData`). Instead, the x-axis scale is determined by the `x` values of `barGroups` and the `alignment`. Use hour-based x values and `BarChartAlignment.spaceEvenly` or generate explicit bar groups for all 24 hours with `toY: 0` for empty hours.
- For sparse days (1-2 entries), the chart will look sparse -- this is correct and expected.

**Detection:** Log entries at 8:00, 8:15, and 22:00 on the same day. Verify the chart shows clustering at 8:00 and the gap to 22:00.

## Minor Pitfalls

### Pitfall 12: Missing reservedSize for Left Axis Causes Label Clipping

**What goes wrong:** The left Y axis shows ml values (e.g., "2000", "3000"). The default `reservedSize: 22` is not wide enough for 4-digit numbers, causing labels to be clipped or overflow into the chart area.

**Prevention:**
- Set `reservedSize: 40` (or `48` for safety) on the left `SideTitles` for the monthly chart.
- Use `NumberFormat.compact()` from `intl` for large values (e.g., "2K" instead of "2000") if space is tight.

**Detection:** Set a daily target of 5000ml or higher and check left axis rendering.

---

### Pitfall 13: Color/Theme Not Respecting Material You Dynamic Colors

**What goes wrong:** Hardcoding bar colors (e.g., `Colors.blue`) instead of using `Theme.of(context).colorScheme.primary` makes the chart visually inconsistent with the rest of the app, especially on Android 12+ with dynamic colors.

**Prevention:**
- Use `colorScheme.primary` for normal bars, `colorScheme.primaryContainer` for background bars.
- Use `colorScheme.error` for bars that missed the target (consistent with calendar red).
- Use `colorScheme.tertiary` or similar for the target line.
- Access theme inside the `build` method, not in a static helper that cannot access `BuildContext`.

**Detection:** Change device wallpaper on Android 12+ and verify chart colors update.

---

### Pitfall 14: Target Line Using ExtraLinesData Not Visible

**What goes wrong:** Horizontal `ExtraLinesData` lines are drawn but may be hidden behind bars or outside the visible Y range if `maxY` is auto-calculated and happens to equal the target value.

**Prevention:**
- If showing a target line at `targetMl`, ensure `maxY` is set to at least `targetMl * 1.1` (10% headroom) so the line is not at the very top edge.
- Style the target line with a dashed pattern and contrasting color for visibility.
- Set `extraLinesOnTop: true` (default) so the line renders above bars.

**Detection:** Log exactly the target amount on every day of the month. Verify the target line is visible above the bars.

---

### Pitfall 15: Tooltip Text Not Localized

**What goes wrong:** The default `getTooltipItems` callback returns raw numbers. In this app, values should include "ml" suffix and use locale-aware formatting (e.g., "2.500 ml" in Italian vs "2,500 ml" in English).

**Prevention:**
- Provide a custom `getTooltipItems` callback that uses `NumberFormat.decimalPattern(locale)` from `intl` (already in the dependency graph).
- Append the localized "ml" unit from the ARB files.
- `BuildContext` is not available inside `getTooltipItems`. Pass the locale string and `NumberFormat` instance to the chart builder function from the `build` method.

**Detection:** Switch locale to Italian, tap a bar, verify tooltip shows locale-correct number formatting.

---

### Pitfall 16: AspectRatio Constraint Missing -- Chart Height Unbounded in ScrollView

**What goes wrong:** The BarChart widget requires bounded height. If placed directly inside a `SingleChildScrollView` (like the existing HistoryScreen layout) or a `Column` without height constraints, the chart receives unbounded height from the layout and either throws a rendering error or renders at zero height.

**Why it happens:** The existing HistoryScreen uses `SingleChildScrollView > Column`. Adding a `BarChart` directly inside this Column provides unbounded height constraints to the chart's internal layout.

**Prevention:**
- Wrap the BarChart in either `AspectRatio(aspectRatio: 1.6, child: BarChart(...))` or `SizedBox(height: 200, child: BarChart(...))`.
- The official fl_chart samples consistently use `AspectRatio` for this purpose.
- `AspectRatio` is preferred because it adapts to screen width while maintaining a consistent visual proportion.

**Detection:** Place BarChart inside the existing Column without height constraints. The app either shows a blank area or throws "Vertical viewport was given unbounded height."

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Monthly BarChart widget | Pitfall 1 (all-zero maxY), Pitfall 2 (animation on month change), Pitfall 6 (label overlap), Pitfall 16 (unbounded height) | Set explicit maxY >= target, use ValueKey for month, adaptive label interval, wrap in AspectRatio |
| Drift query for chart | Pitfall 8 (fetches all rows not aggregates), Pitfall 4 (stream thrashing) | Reuse calendarMonthProvider, consider SQL aggregation |
| Calendar + chart sync | Pitfall 10 (month desync), Pitfall 7 (no reactivity) | Single source of truth via focusedMonthProvider, stream-based providers only |
| Day detail screen | Pitfall 5 (GoRouter navigation), Pitfall 11 (time-axis gaps) | Top-level route for full-screen push, hour-based x values |
| Touch/tooltips | Pitfall 3 (index crash), Pitfall 15 (unlocalized text) | Avoid showingTooltipIndicators, custom getTooltipItems with locale |
| Visual polish | Pitfall 9 (bar width), Pitfall 12 (reservedSize), Pitfall 13 (theme colors), Pitfall 14 (target line) | Adaptive width, 40px+ reservedSize, colorScheme colors, maxY headroom |

## Sources

- Context7: fl_chart GitHub docs (`/imanneo/fl_chart`) -- BarChartData, BarChartGroupData, BarTouchData, SideTitles, lerp behavior (HIGH confidence)
- Context7: fl_chart pub.dev docs (`/websites/pub_dev_fl_chart`) -- BarChartData constructor (maxY defaults to double.nan), BarChartRodData, BarChartGroupData.lerp (HIGH confidence)
- GitHub source: `bar_chart_helper.dart` -- `calculateMaxAxisValues()` returns `(0, 0)` for empty barGroups (HIGH confidence)
- GitHub source: `bar_chart_data.dart` -- constructor assigns `maxY ?? double.nan` (HIGH confidence)
- GitHub issue #1911 -- `showingTooltipIndicators` index out of bounds crash on data change (HIGH confidence, confirmed bug)
- GitHub issue #1963 -- axis labels stop rendering past certain reserved thresholds (MEDIUM confidence)
- Existing codebase analysis: `history_screen.dart`, `stream_providers.dart`, `water_entry_dao.dart`, `water_repository.dart`, `app_router.dart`, `app_database.dart` (HIGH confidence)
