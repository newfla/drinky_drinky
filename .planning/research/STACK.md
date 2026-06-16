# Stack Research: Drinky Drinky v1.5 (Bar Charts)

**Project:** Drinky Drinky (Hydration Tracker)
**Researched:** 2026-06-16
**Scope:** fl_chart BarChart APIs for monthly overview and daily detail bar charts.
**Overall confidence:** HIGH

## New Dependency Required

### fl_chart ^1.2.0

| Field | Value |
|-------|-------|
| Package | `fl_chart` |
| Version | `^1.2.0` (latest as of June 2026) |
| Purpose | Render bar charts: monthly daily-totals overview and daily individual-entries detail |
| Dependencies | `equatable ^2.0.7`, `vector_math ^2.2.0`, `flutter` -- no conflicts with existing pubspec |
| Min Flutter | 3.27.4 (required since fl_chart 1.0.0 -- satisfied by project's 3.44.1) |

**pubspec.yaml addition:**

```yaml
dependencies:
  # Charts
  fl_chart: ^1.2.0
```

**Confidence:** HIGH -- version 1.2.0 verified via pub.dev direct fetch (published ~March 2026). Dependencies verified compatible with existing pubspec.

## No Other New Packages Required

fl_chart is the only addition. The project already has `intl` for date formatting (axis labels) and `collection` for `groupBy` (data aggregation). No additional libraries needed.

---

## fl_chart API Reference for Two Bar Chart Use Cases

### Core Widget Hierarchy

Every fl_chart bar chart follows this nesting:

```
BarChart (widget)
  -> BarChartData (configuration object)
       -> List<BarChartGroupData> (one per bar/column on x-axis)
            -> List<BarChartRodData> (one or more rods per group)
       -> FlTitlesData (axis labels)
       -> FlGridData (grid lines)
       -> BarTouchData (touch/tooltip behavior)
       -> ExtraLinesData (horizontal reference lines, e.g., target)
       -> FlBorderData (chart border)
```

### Key Classes and Their Required Parameters

#### 1. `BarChart` (Widget)

```dart
BarChart(
  BarChartData data,          // REQUIRED -- the chart configuration
  {
    Duration duration,        // Animation duration when data changes. Default: 150ms
    Curve curve,              // Animation curve. Default: Curves.linear
    Key? chartRendererKey,    // For widget testing
    FlTransformationConfig transformationConfig, // Scroll/zoom. Default: none
  }
)
```

**Usage note:** `BarChart` is NOT const (since fl_chart 0.70.0) due to internal assertions. Do not attempt `const BarChart(...)`.

**Deprecated parameters (DO NOT USE):**
- `swapAnimationDuration` -- use `duration` instead
- `swapAnimationCurve` -- use `curve` instead

#### 2. `BarChartData` (Configuration)

```dart
BarChartData({
  List<BarChartGroupData>? barGroups,    // The bars. Default: []
  double? groupsSpace,                   // Space between groups (only with center/start/end alignment). Default: 16
  BarChartAlignment? alignment,          // How bars are arranged. Default: spaceEvenly
  FlTitlesData? titlesData,              // Axis labels
  BarTouchData? barTouchData,            // Touch/tooltip config
  double? maxY,                          // Y-axis max. Default: auto-calculated from data
  double? minY,                          // Y-axis min. Default: auto-calculated
  double? baselineY,                     // Y baseline. Default: 0
  FlGridData? gridData,                  // Grid lines
  FlBorderData? borderData,              // Chart border
  Color? backgroundColor,               // Chart background
  ExtraLinesData? extraLinesData,        // Horizontal reference lines (for target line)
})
```

**Critical for this project:**
- `maxY` -- explicitly set for the monthly chart so the target line is always visible (set to `max(maxDailyTotal, dailyTarget) * 1.1`)
- `minY` -- leave as 0 (water intake is never negative)
- `alignment` -- use `BarChartAlignment.spaceEvenly` for monthly (31 bars, auto-spaced) and daily detail (variable count)
- `extraLinesData` -- use for the daily target horizontal line on the monthly chart

#### 3. `BarChartGroupData` (One Per Bar)

```dart
BarChartGroupData({
  required int x,                              // X-axis position identifier
  List<BarChartRodData> barRods,               // The rods in this group. Default: []
  double barsSpace,                            // Space between rods in same group. Default: 2
  List<int> showingTooltipIndicators,          // Indices of rods to show tooltips for
})
```

**For monthly chart:** `x` = day of month (1-31). One `BarChartRodData` per group.
**For daily detail chart:** `x` = index of entry (0, 1, 2...). One `BarChartRodData` per group.

**Important:** `x` is an `int`, not a `double`. For the monthly chart, map day-of-month directly. For the daily chart, use sequential indices and map to time labels via `getTitlesWidget`.

#### 4. `BarChartRodData` (The Actual Bar)

```dart
BarChartRodData({
  double? fromY,                              // Bar start Y. Default: 0
  required double toY,                        // Bar end Y (the value)
  Color? color,                               // Solid color. Default: Colors.cyan
  Gradient? gradient,                         // Alternative to color (mutually exclusive)
  double? width,                              // Bar width in pixels. Default: 8
  BorderRadius? borderRadius,                 // Corner rounding
  BackgroundBarChartRodData? backDrawRodData,  // Background bar (for target indicator)
  BarChartRodLabel label,                      // Label on the rod. Default: not shown
})
```

**For this project:**
- `toY` = amount in ml (the daily total or individual entry amount)
- `width` = adjust based on bar count: ~8 for 28-31 bars (monthly), ~20-24 for daily detail (fewer bars)
- `color` = use theme `colorScheme.primary` for bars at/above target, `colorScheme.primary.withOpacity(0.6)` for below-target, or a single color for all
- `borderRadius` = `BorderRadius.vertical(top: Radius.circular(4))` for rounded tops only

#### 5. `FlTitlesData` (Axis Labels)

```dart
FlTitlesData({
  bool show,                    // Default: true
  AxisTitles topTitles,         // Top axis config
  AxisTitles bottomTitles,      // Bottom axis (x-axis labels)
  AxisTitles leftTitles,        // Left axis (y-axis labels)
  AxisTitles rightTitles,       // Right axis config
})
```

Each `AxisTitles` contains:

```dart
AxisTitles({
  AxisTitleData? axisNameWidget, // Axis name (e.g., "ml")
  SideTitles? sideTitles,        // The tick labels
})
```

Each `SideTitles` contains:

```dart
SideTitles({
  bool showTitles,              // Default: false
  GetTitleWidgetFunction getTitlesWidget,  // Callback: (double value, TitleMeta meta) -> Widget
  double reservedSize,          // Space reserved for labels. Default: 22
  double? interval,             // Label interval. Default: auto-calculated
  bool minIncluded,             // Show label at min value. Default: true
  bool maxIncluded,             // Show label at max value. Default: true
})
```

**Monthly chart axis configuration:**
- **Bottom (x-axis):** Show every 5th day label (`1, 5, 10, 15, 20, 25, 30`) to avoid overcrowding 31 labels. Use `getTitlesWidget` to return day numbers. Set `interval: 1` but filter in the callback, or set `interval: 5` and handle edge days.
- **Left (y-axis):** Show ml values. `reservedSize: 40` (to fit "2000" text). Auto-interval or set explicitly based on target (e.g., interval = target / 4).
- **Top/Right:** Hide (`SideTitles(showTitles: false)`).

**Daily detail chart axis configuration:**
- **Bottom (x-axis):** Show entry time (HH:mm). Use `getTitlesWidget` with the entry index mapped to `loggedAt` time. `reservedSize: 30`.
- **Left (y-axis):** Show ml values. `reservedSize: 40`.
- **Top/Right:** Hide.

#### 6. `FlGridData` (Grid Lines)

```dart
const FlGridData({
  bool show,                     // Default: true
  bool drawHorizontalLine,      // Default: true
  double? horizontalInterval,   // Auto if null
  GetDrawingGridLine getDrawingHorizontalLine,  // Style callback
  bool drawVerticalLine,        // Default: true
  double? verticalInterval,     // Auto if null
})
```

**For both charts:** `drawVerticalLine: false` (vertical grid lines add noise to bar charts). Keep `drawHorizontalLine: true` with a subtle color from the theme.

#### 7. `ExtraLinesData` + `HorizontalLine` (Target Reference Line)

```dart
ExtraLinesData({
  bool extraLinesOnTop,          // Draw over bars (true) or behind (false). Default: true
  List<HorizontalLine> horizontalLines,
  List<VerticalLine> verticalLines,  // NOTE: vertical lines are ignored in BarChart
})

HorizontalLine({
  double? y,                     // Y-coordinate of the line
  Color color,                   // Default: Colors.black
  double strokeWidth,            // Default: 2.0
  List<int>? dashArray,          // For dashed line. e.g., [5, 5]
  HorizontalLineLabel? label,   // Text label on the line
})
```

**For monthly chart:** Draw one `HorizontalLine` at `y: dailyTarget.toDouble()` with a dashed style and label "Target: {X} ml". Use `extraLinesOnTop: true` so the line draws over bars.

**For daily detail chart:** No target line needed (individual entries are not compared to a daily target per-entry).

#### 8. `BarTouchData` + `BarTouchTooltipData` (Touch Tooltips)

```dart
BarTouchData({
  bool? enabled,                  // Default: true
  BarTouchTooltipData? touchTooltipData,
  bool? handleBuiltInTouches,    // Auto-show tooltip on touch. Default: true
  BaseTouchCallback<BarTouchResponse>? touchCallback,
  EdgeInsets? touchExtraThreshold, // Default: EdgeInsets.all(4)
})

BarTouchTooltipData({
  GetBarTooltipItem? getTooltipItem,     // Custom tooltip content
  GetBarTooltipColor? getTooltipColor,   // Custom tooltip background
  double? tooltipMargin,                 // Margin from bar top
  BorderRadius? tooltipBorderRadius,
  EdgeInsets? tooltipPadding,
  double? maxContentWidth,
  bool? fitInsideHorizontally,   // Keep tooltip inside chart bounds
  bool? fitInsideVertically,
})
```

The `getTooltipItem` callback signature:

```dart
typedef GetBarTooltipItem = BarTooltipItem? Function(
  BarChartGroupData group,
  int groupIndex,
  BarChartRodData rod,
  int rodIndex,
);
```

`BarTooltipItem` constructor:

```dart
BarTooltipItem(
  String text,           // e.g., "1500 ml"
  TextStyle textStyle,
  {
    TextAlign textAlign,
    List<TextSpan>? children,
  }
)
```

**For monthly chart tooltip:** Show "Day {x}: {toY.toInt()} ml" on tap.
**For daily detail tooltip:** Show "{time}: {toY.toInt()} ml" on tap.

#### 9. `BackgroundBarChartRodData` (Background Target Indicator -- ALTERNATIVE)

```dart
BackgroundBarChartRodData({
  double? fromY,     // Default: 0
  double? toY,       // The background bar height (e.g., daily target)
  bool? show,        // Default: false
  Color? color,      // Background bar color
  Gradient? gradient,
})
```

**Alternative to HorizontalLine for target visualization:** Each bar can have a faded background rod showing the full target height. Set `toY: dailyTarget.toDouble()`, `show: true`, `color: theme.colorScheme.surfaceVariant`. This creates a "fill to target" visual per bar.

**Recommendation:** Use `HorizontalLine` for the monthly chart (cleaner, single line across all bars) rather than per-bar backgrounds. Reserve `BackgroundBarChartRodData` as a possible future enhancement.

#### 10. `FlBorderData` (Chart Border)

```dart
FlBorderData({
  bool? show,         // Default: true
  Border? border,     // Default: all sides with grey
})
```

**For both charts:** `FlBorderData(show: false)` -- no border frame around the chart. The grid lines and axis labels provide sufficient framing.

---

## Chart-Specific Implementation Patterns

### Monthly Bar Chart (History Screen)

**Data source:** `calendarMonthProvider(year, month)` -- already exists, returns `Stream<Map<String, int>>` where key = `YYYY-MM-DD` dateKey, value = total ml for that day.

**Target line source:** `allTargetHistoryProvider` -- already exists. Use `_findActiveTarget()` (already in history_screen.dart) to get the target for the focused month. For simplicity, use the target effective at month start as the reference line (targets rarely change mid-month).

**Data transformation pattern:**

```dart
// Convert Map<String, int> to List<BarChartGroupData>
List<BarChartGroupData> buildMonthlyBars(
  Map<String, int> monthTotals,
  int year,
  int month,
  int targetMl,
  ColorScheme colorScheme,
) {
  final daysInMonth = DateTime(year, month + 1, 0).day;
  return List.generate(daysInMonth, (i) {
    final day = i + 1;
    final dateKey = _toDateKey(DateTime(year, month, day));
    final total = monthTotals[dateKey] ?? 0;
    final metTarget = total >= targetMl && targetMl > 0;

    return BarChartGroupData(
      x: day,
      barRods: [
        BarChartRodData(
          toY: total.toDouble(),
          width: 8,
          color: metTarget
              ? colorScheme.primary
              : colorScheme.primary.withOpacity(0.4),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(2),
          ),
        ),
      ],
    );
  });
}
```

**Widget sizing:** Wrap in `AspectRatio(aspectRatio: 1.8)` or a fixed `SizedBox(height: 200)` inside a `Card` with padding. The chart needs a bounded height -- fl_chart will assert if given unbounded constraints.

**Scrollability:** 28-31 bars at width 8 with `BarChartAlignment.spaceEvenly` fit comfortably in a standard phone width (~360dp). No horizontal scrolling needed. If future months have wider bars, `FlTransformationConfig` supports horizontal scrolling, but avoid it for now (the assertion blocks `spaceEvenly` alignment with horizontal scaling).

### Daily Detail Chart (New Screen -- Push Route)

**Data source:** `waterEntriesForDate(dateKey)` -- already exists, returns `Stream<List<WaterEntryEntity>>`. Each entity has `amountMl` and `loggedAt`.

**Data transformation pattern:**

```dart
// Convert List<WaterEntryEntity> to List<BarChartGroupData>
List<BarChartGroupData> buildDailyBars(
  List<WaterEntryEntity> entries,
  ColorScheme colorScheme,
) {
  return entries.asMap().entries.map((mapEntry) {
    final index = mapEntry.key;
    final entry = mapEntry.value;

    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          toY: entry.amountMl.toDouble(),
          width: entries.length <= 5 ? 24 : (entries.length <= 10 ? 16 : 10),
          color: colorScheme.primary,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(4),
          ),
        ),
      ],
    );
  }).toList();
}
```

**X-axis labels:** Map index to time using `DateFormat.Hm()` (24h) or `DateFormat.jm()` (locale-aware AM/PM):

```dart
getTitlesWidget: (value, meta) {
  final index = value.toInt();
  if (index < 0 || index >= entries.length) return const SizedBox();
  final time = DateFormat.Hm(locale).format(entries[index].loggedAt);
  return SideTitleWidget(
    meta: meta,
    child: Text(time, style: const TextStyle(fontSize: 10)),
  );
},
```

**Label rotation:** For many entries (>8), labels may overlap. Options:
1. Show every Nth label (e.g., every 2nd)
2. Use `SideTitleWidget` with `angle` parameter for rotation (not natively supported by `SideTitleWidget` -- would need `Transform.rotate` wrapper)
3. Keep bar width dynamic and accept that >15 entries will get tight

**Recommendation:** Show all labels when entries <= 8, show every other label when > 8.

---

## Riverpod Integration Pattern

The existing `calendarMonthProvider` and `waterEntriesForDate` providers return `AsyncValue<T>`. The chart widget should use `.when()` pattern, showing a loading indicator or empty state before data arrives:

```dart
final monthData = ref.watch(calendarMonthProvider(year, month));

return monthData.when(
  loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
  error: (e, _) => const SizedBox(height: 200, child: Center(child: Text('Error loading chart'))),
  data: (totals) => SizedBox(
    height: 200,
    child: BarChart(
      BarChartData(
        barGroups: buildMonthlyBars(totals, year, month, target, colorScheme),
        // ... other config
      ),
    ),
  ),
);
```

**Important:** fl_chart handles implicit animations when `BarChartData` changes. When the Riverpod stream emits new data, the `BarChart` widget automatically animates bar heights. The `duration` and `curve` parameters on `BarChart` control this animation. Use `Duration(milliseconds: 300)` with `Curves.easeInOut` for a smooth feel.

---

## Version-Specific Notes for fl_chart 1.2.0

### Breaking changes since 0.x that affect implementation

| Version | Change | Impact |
|---------|--------|--------|
| 1.0.0 | Min Flutter 3.27.4 | No impact (project is 3.44.1) |
| 1.0.0 | Removed deprecated `tooltipRoundedRadius` | Use `tooltipBorderRadius` in `BarTouchTooltipData` instead |
| 0.70.0 | `BarChart` is no longer `const` | Cannot write `const BarChart(...)` -- not a problem since data is always dynamic |
| 0.67.0 | Removed `tooltipBgColor` | Use `getTooltipColor` callback instead for tooltip background color |
| 0.50.0 | `SideTitles.getTitlesWidget` returns Widget (not String) | Must return a Widget from the callback. Use `SideTitleWidget` wrapper for proper alignment |
| 0.50.0 | Replaced `colors` list with single `color` + `gradient` | Use `color:` or `gradient:`, not `colors:` |
| 1.1.0 | `borderSide` in `BarChartRodStackItem` is now a named parameter | Not relevant (no stacked bars needed) |

### fl_chart 1.2.0 specific features available

- `BarChartRodLabel` -- can display text labels directly on bar rods (new in 1.2.0). Useful if you want to show ml values on top of bars without tooltips.
- `enabled` property is now properly respected across all touch data classes.

### Known API quirks

1. **`BarChart` alignment assertion:** When using `FlTransformationConfig` with horizontal scaling, `BarChartAlignment.center`, `.end`, or `.start` will trigger an assertion failure. Stick with `spaceEvenly` if you ever enable scroll/zoom.

2. **Vertical extra lines ignored:** `ExtraLinesData.verticalLines` is silently ignored in BarChart (documented in issue #1149). Only `horizontalLines` work. This is fine for this project (target is a horizontal line).

3. **`maxY` auto-calculation:** If `maxY` is not set, fl_chart calculates it from the bar data. This means bars with 0 value on an empty day will cause `maxY = 0`, resulting in division-by-zero rendering issues. Always set `maxY` explicitly to at least the target value.

4. **`getTitlesWidget` receives all values in range:** The callback fires for every value at the computed interval, including values that do not correspond to actual bars. Always guard with bounds checks (e.g., `if (value.toInt() < 1 || value.toInt() > daysInMonth) return const SizedBox()`).

5. **`SideTitleWidget`:** The official recommendation is to wrap your custom title Text in `SideTitleWidget(meta: meta, child: ...)` for proper alignment with the axis. Using bare `Text` widgets works but may have alignment issues.

---

## What NOT to Use from fl_chart

| Feature | Why Not |
|---------|---------|
| `LineChart` | Bar chart is the specified visualization. Line charts suit continuous data; discrete daily totals are better as bars |
| `PieChart` | Does not apply to time-series daily totals |
| `ScatterChart` | Not applicable for this use case |
| `CandlestickChart` | Financial charting widget, irrelevant |
| `RadarChart` | Multi-axis comparison, not applicable |
| `BarChartRodStackItem` | Stacked bars. Each bar is a single value (total or entry amount), no stacking needed |
| `FlTransformationConfig` (scroll/zoom) | Adds complexity; 31 bars fit on screen without scrolling. The alignment assertion also blocks this with `spaceEvenly` |
| `rotationQuarterTurns` | Horizontal bar charts. Both charts should be vertical (standard orientation) |

---

## pubspec.yaml Diff

```diff
 dependencies:
   # ... existing deps ...

+  # Charts
+  fl_chart: ^1.2.0

   # UI Components
   percent_indicator: ^4.2.5
   table_calendar: ^3.2.0
```

No dev dependencies needed. fl_chart has no code generation step.

**After adding:**

```bash
flutter pub get
```

No `build_runner` needed for fl_chart.

---

## Data Layer Assessment

### Existing providers that feed the charts (NO CHANGES NEEDED)

| Provider | Returns | Used By |
|----------|---------|---------|
| `calendarMonthProvider(year, month)` | `Stream<Map<String, int>>` (dateKey -> totalMl) | Monthly bar chart |
| `waterEntriesForDate(dateKey)` | `Stream<List<WaterEntryEntity>>` (with amountMl + loggedAt) | Daily detail bar chart |
| `allTargetHistoryProvider` | `Stream<List<TargetHistoryEntry>>` | Target line on monthly chart |
| `focusedMonthProvider` | `DateTime` (keepAlive) | Controls which month the bar chart displays |

### Possibly needed: new provider for daily detail screen navigation

The daily detail screen needs a `dateKey` parameter (from calendar day tap). This can be passed via GoRouter path parameter or `state.extra`. No new Riverpod provider needed -- `waterEntriesForDate(dateKey)` already accepts a dateKey parameter.

### No new DAO queries needed

Both `watchDailyTotalsInRange` (monthly) and `watchEntriesForDate` (daily) already exist in `WaterEntryDao` and are exposed through `WaterRepository` and the Riverpod providers. The data layer is complete.

---

## Sources

- fl_chart pub.dev API documentation (Context7: pub.dev/documentation/fl_chart/latest/) -- HIGH confidence
- fl_chart GitHub documentation (Context7: github.com/imanneo/fl_chart/repo_files/documentations/bar_chart.md) -- HIGH confidence
- fl_chart changelog (pub.dev/packages/fl_chart/changelog) -- HIGH confidence, version 1.2.0 verified
- fl_chart pub.dev package page -- version 1.2.0, dependencies (equatable, vector_math, flutter) verified -- HIGH confidence
- Existing project codebase: pubspec.yaml, stream_providers.dart, water_repository.dart, water_entry_dao.dart, history_screen.dart -- HIGH confidence
