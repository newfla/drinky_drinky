import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/stream_providers.dart';
import '../../domain/entities/target_history_entry.dart';
import '../../domain/entities/water_entry_entity.dart';
import '../../l10n/l10n_extensions.dart';

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

/// A screen showing per-entry bar chart for a selected day.
///
/// Displays each water intake entry as a bar with the HH:mm time on the
/// x-axis and ml on the y-axis. Shows total ml and the daily target as
/// text above the chart inside the same Card (CHART-08, CHART-09).
/// Shows an empty-state message when there are no entries for the day
/// (CHART-10). AppBar title is the locale-formatted date (D-06).
class DayDetailScreen extends ConsumerWidget {
  const DayDetailScreen({super.key, required this.dateKey});

  /// The date to display, in YYYY-MM-DD format.
  final String dateKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(waterEntriesForDateProvider(dateKey));
    final targetsAsync = ref.watch(allTargetHistoryProvider);

    final locale = Localizations.localeOf(context).toString();
    final parsedDate = DateTime.parse(dateKey);
    final appBarTitle = DateFormat.yMMMMd(locale).format(parsedDate);

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(context.l10n.errorLoadingData)),
        data: (entries) {
          return targetsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(context.l10n.errorLoadingData)),
            data: (targets) {
              return _buildContent(context, entries, targets);
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<WaterEntryEntity> entries,
    List<TargetHistoryEntry> targets,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // CHART-10: Empty state when no entries for the selected day.
    if (entries.isEmpty) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    context.l10n.dayDetailNoEntries,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    // CHART-09: Compute total ml for the day.
    final totalMl = entries.fold(0, (sum, e) => sum + e.amountMl);

    // CHART-09: Find the active target for this dateKey.
    final targetMl = _findActiveTarget(targets, dateKey);

    // CHART-08: Group entries by minutes-since-midnight for the x-axis.
    // Entries at the same minute get multiple barRods in one BarChartGroupData.
    final Map<int, List<WaterEntryEntity>> grouped = {};
    for (final entry in entries) {
      final minutesSinceMidnight =
          entry.loggedAt.hour * 60 + entry.loggedAt.minute;
      grouped.putIfAbsent(minutesSinceMidnight, () => []).add(entry);
    }

    // Sort groups ascending by x (minutes-since-midnight).
    final sortedKeys = grouped.keys.toList()..sort();

    // Build a lookup from minutes-since-midnight to the first entry for labels.
    final Map<int, WaterEntryEntity> firstEntryForMinute = {
      for (final k in sortedKeys) k: grouped[k]!.first,
    };

    // Bar color: primary (not green/red — these are individual additions).
    final barColor = colorScheme.primary;

    // Compute actualMaxMl for maxY.
    double actualMaxMl = 0;
    for (final entry in entries) {
      if (entry.amountMl > actualMaxMl) actualMaxMl = entry.amountMl.toDouble();
    }

    // MANDATORY explicit maxY ceiling (WR-02 pitfall). Never zero or auto.
    final maxY = max(actualMaxMl * 1.1, 100.0);

    // Build bar groups.
    final barGroups = <BarChartGroupData>[];
    for (final key in sortedKeys) {
      final entryList = grouped[key]!;
      barGroups.add(
        BarChartGroupData(
          x: key,
          barRods: entryList
              .map(
                (entry) => BarChartRodData(
                  toY: entry.amountMl.toDouble(),
                  width: 10,
                  color: barColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(2),
                  ),
                ),
              )
              .toList(),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),

          // ---- Chart Card (total text + bar chart inside same Card per D-08) ----
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // CHART-09: Total and target text above the chart.
                  Text(
                    context.l10n.dayDetailTotal(totalMl, targetMl),
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),

                  // CHART-08: Per-entry bar chart.
                  SizedBox(
                    height: 220,
                    child: BarChart(
                      // MANDATORY ValueKey per WR-01 to prevent render artifacts.
                      key: ValueKey('day-$dateKey'),
                      BarChartData(
                        alignment: BarChartAlignment.spaceEvenly,
                        maxY: maxY,
                        minY: 0,
                        barGroups: barGroups,

                        // Tooltip: show HH:mm on line 1, ml on line 2.
                        barTouchData: BarTouchData(
                          handleBuiltInTouches: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final entry = firstEntryForMinute[group.x];
                              final timeLabel = entry != null
                                  ? DateFormat('HH:mm').format(entry.loggedAt)
                                  : '';
                              return BarTooltipItem(
                                '$timeLabel\n',
                                TextStyle(
                                  color: colorScheme.onInverseSurface,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11,
                                ),
                                children: [
                                  TextSpan(
                                    text: '${rod.toY.toInt()} ml',
                                    style: TextStyle(
                                      color: colorScheme.onInverseSurface,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        // Axis labels.
                        titlesData: FlTitlesData(
                          // Bottom (x-axis): HH:mm labels for each group.
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                final minutes = value.toInt();
                                // Only show label for first entry in each group
                                // to avoid overlap on grouped bars.
                                final entry = firstEntryForMinute[minutes];
                                if (entry == null) {
                                  return const SizedBox.shrink();
                                }
                                return SideTitleWidget(
                                  meta: meta,
                                  child: Text(
                                    DateFormat('HH:mm').format(entry.loggedAt),
                                    style: const TextStyle(fontSize: 9),
                                  ),
                                );
                              },
                            ),
                          ),

                          // Left (y-axis): values in L (data is stored in ml, divide by 1000 for display).
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 46,
                              getTitlesWidget: (value, meta) {
                                // Skip min and max values (same pattern as monthly chart).
                                if (value == meta.min || value == meta.max) {
                                  return const SizedBox.shrink();
                                }
                                final lLabel = (value / 1000)
                                    .toStringAsFixed(2)
                                    .replaceAll(RegExp(r'\.?0+$'), '');
                                return SideTitleWidget(
                                  meta: meta,
                                  child: Text(
                                    '$lLabel L',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
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

                        // Grid: horizontal lines only.
                        gridData: const FlGridData(
                          drawVerticalLine: false,
                          drawHorizontalLine: true,
                        ),

                        // No border.
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
