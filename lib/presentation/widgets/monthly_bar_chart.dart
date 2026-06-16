import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/target_history_entry.dart';

/// Convert an arbitrary DateTime to a dateKey string (YYYY-MM-DD).
/// Duplicated from history_screen.dart -- both files need this helper
/// and the chart widget must remain a pure StatelessWidget with no
/// dependency on history_screen internals.
String _toDateKey(DateTime d) {
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Finds the effective target for a date by scanning sorted target history.
/// Returns 2000 as fallback if no targets exist.
///
/// [targets] must be sorted ASC by effectiveDate. Iterates through entries
/// and picks the last one where effectiveDate <= dateKey.
int _findActiveTarget(List<TargetHistoryEntry> targets, String dateKey) {
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

/// A bar chart showing daily hydration totals for a single month.
///
/// Bars are green when the daily target is met and red when not.
/// A dashed horizontal line marks the daily target.
/// Tapping a bar shows a tooltip with the exact ml value.
/// Months with no data show a textual empty-state message.
class MonthlyBarChart extends StatelessWidget {
  const MonthlyBarChart({
    super.key,
    required this.monthTotals,
    required this.year,
    required this.month,
    required this.targets,
  });

  /// dateKey -> ml totals for the month, from calendarMonthProvider.
  final Map<String, int> monthTotals;

  /// The year being displayed.
  final int year;

  /// The month being displayed (1-12).
  final int month;

  /// Sorted ASC target history entries, from allTargetHistoryProvider.
  final List<TargetHistoryEntry> targets;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brightness = theme.brightness;

    // Empty-state check (CHART-05, D-05).
    if (monthTotals.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No data this month',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    // Compute days in month and last valid day.
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final now = DateTime.now();
    final isCurrentMonth = year == now.year && month == now.month;
    final lastValidDay = isCurrentMonth ? now.day : daysInMonth;

    // Compute target for the end of the month (D-06).
    final endDateKey = _toDateKey(DateTime(year, month, daysInMonth));
    final targetMl = _findActiveTarget(targets, endDateKey);

    // Bar colors.
    final green = brightness == Brightness.dark
        ? Colors.green.shade400
        : Colors.green.shade600;
    final red = brightness == Brightness.dark
        ? Colors.red.shade400
        : Colors.red.shade600;

    // Build bar groups (CHART-01, CHART-02, D-04, D-05).
    double actualMaxValue = 0;
    final barGroups = <BarChartGroupData>[];

    for (int day = 1; day <= lastValidDay; day++) {
      final dateKey = _toDateKey(DateTime(year, month, day));
      final total = monthTotals[dateKey] ?? 0;
      final toY = total.toDouble();

      if (toY > actualMaxValue) {
        actualMaxValue = toY;
      }

      Color barColor;
      if (total >= targetMl && targetMl > 0) {
        barColor = green;
      } else if (total > 0) {
        barColor = red;
      } else {
        // total == 0: no visible bar (D-04).
        barColor = Colors.transparent;
      }

      barGroups.add(
        BarChartGroupData(
          x: day,
          barRods: [
            BarChartRodData(
              toY: toY,
              width: 6,
              color: barColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(2),
              ),
            ),
          ],
        ),
      );
    }

    // Compute maxY (Pitfall 1): at least max(actual, target) * 1.1, floor 100.
    final computedMax = max(actualMaxValue, targetMl.toDouble()) * 1.1;
    final maxY = max(computedMax, 100.0);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 180,
          child: BarChart(
            key: ValueKey('$year-$month'),
            BarChartData(
              alignment: BarChartAlignment.spaceEvenly,
              maxY: maxY,
              minY: 0,
              barGroups: barGroups,

              // Target line (CHART-03, D-06).
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: targetMl.toDouble(),
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    strokeWidth: 1.5,
                    dashArray: [8, 4],
                  ),
                ],
              ),

              // Tooltips (CHART-04).
              barTouchData: BarTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${rod.toY.toInt()} ml',
                      TextStyle(
                        color: colorScheme.onInverseSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),

              // Axis labels.
              titlesData: FlTitlesData(
                // Bottom (x-axis): show day numbers at key positions.
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) {
                      final day = value.toInt();
                      // Show labels for days 1, 5, 10, 15, 20, 25, and last day.
                      if (day == 1 ||
                          day == 5 ||
                          day == 10 ||
                          day == 15 ||
                          day == 20 ||
                          day == 25 ||
                          day == daysInMonth) {
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            '$day',
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),

                // Left (y-axis): auto-interval, reservedSize 40 (Pitfall 12).
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                  ),
                ),

                // Hide top and right axes.
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),

              // Grid: horizontal only.
              gridData: const FlGridData(
                drawVerticalLine: false,
                drawHorizontalLine: true,
              ),

              // No border.
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ),
    );
  }
}
