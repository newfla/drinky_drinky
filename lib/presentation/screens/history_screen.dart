import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/providers/stream_providers.dart';
import '../../domain/entities/target_history_entry.dart';
import '../../l10n/l10n_extensions.dart';
import '../widgets/monthly_bar_chart.dart';

/// Convert an arbitrary DateTime to a dateKey string (YYYY-MM-DD).
/// Matches the format used by todayDateKey() in stream_providers.dart.
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

/// Builds a single calendar day cell with the appropriate decoration.
///
/// [metGoal] is true for green, false for red, null for today-only ring.
Widget _buildDayCell(
  BuildContext context,
  DateTime day, {
  required bool? metGoal,
  required bool isToday,
}) {
  final locale = Localizations.localeOf(context).toString();
  final colorScheme = Theme.of(context).colorScheme;
  final brightness = Theme.of(context).brightness;

  Color? fillColor;
  Color? textColor;

  if (metGoal == true) {
    final green = brightness == Brightness.dark
        ? Colors.green.shade400
        : Colors.green.shade600;
    fillColor = green.withValues(alpha: 0.15);
    textColor = green;
  } else if (metGoal == false) {
    final red = brightness == Brightness.dark
        ? Colors.red.shade400
        : Colors.red.shade600;
    fillColor = red.withValues(alpha: 0.15);
    textColor = red;
  }
  // metGoal == null: no fill, default text color (today ring only)

  final String semanticLabel;
  if (metGoal == true) {
    semanticLabel = context.l10n.calendarDayGoalMet(DateFormat.MMMM(locale).format(day), day.day);
  } else if (metGoal == false) {
    semanticLabel = context.l10n.calendarDayGoalNotMet(DateFormat.MMMM(locale).format(day), day.day);
  } else {
    semanticLabel = context.l10n.calendarDay(DateFormat.MMMM(locale).format(day), day.day);
  }

  return Semantics(
    label: semanticLabel,
    child: Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fillColor,
        border: isToday
            ? Border.all(color: colorScheme.primary, width: 2)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earliestAsync = ref.watch(earliestDateKeyProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.historyTitle)),
      body: earliestAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(context.l10n.errorLoadingData),
        ),
        data: (earliestDateKey) {
          // Empty state: no entries have ever been logged.
          if (earliestDateKey == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.noHistoryYet,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.noHistoryYetHint,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }

          final firstDay = DateTime.parse(earliestDateKey);

          // Watch the focused month from the keepAlive provider (D-09).
          final focused = ref.watch(focusedMonthProvider);
          // Watch all target history for per-day target evaluation (D-10).
          final targetsAsync = ref.watch(allTargetHistoryProvider);

          return targetsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(context.l10n.errorLoadingData),
            ),
            data: (targets) {
              // Watch per-month totals for the focused month (D-06, D-07).
              final monthTotals =
                  ref.watch(calendarMonthProvider(focused.year, focused.month)).value ??
                      <String, int>{};

              // Watch streak (D-06, D-08). Default to 0 while loading.
              final streak = ref.watch(streakProvider).value ?? 0;

              final theme = Theme.of(context);
              final colorScheme = theme.colorScheme;
              final streakColor = theme.brightness == Brightness.dark
                  ? Colors.orange.shade400
                  : Colors.orange.shade700;

              // Clamp focusedDay to [firstDay, lastDay] to prevent TableCalendar
              // assertion errors (Pitfall 3).
              final lastDay =
                  DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
              final clampedFocused = focused.isBefore(firstDay)
                  ? firstDay
                  : focused.isAfter(lastDay)
                      ? lastDay
                      : focused;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // lg top padding
                    const SizedBox(height: 24),

                    // ---- StreakCard ----
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              size: 32,
                              color: streakColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              context.l10n.dayStreak(streak),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // lg spacing between StreakCard and calendar
                    const SizedBox(height: 24),

                    // ---- TableCalendar ----
                    TableCalendar<Object>(
                      locale: Localizations.localeOf(context).toString(),
                      firstDay: firstDay,
                      lastDay: lastDay,
                      focusedDay: clampedFocused,
                      calendarFormat: CalendarFormat.month,
                      availableCalendarFormats: const {CalendarFormat.month: 'Month'},
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                      onDaySelected: (selectedDay, focusedDay) {
                        // Only allow selection for days not in the future.
                        if (selectedDay.isAfter(DateTime.now())) return;
                        // Also update the focused month provider (Pitfall 4: only
                        // use year/month, not the day component).
                        ref.read(focusedMonthProvider.notifier).set(focusedDay);
                        // Navigate to DayDetailScreen only if the day has data (D-02).
                        final dateKey = _toDateKey(selectedDay);
                        final total = monthTotals[dateKey];
                        if (total != null && total > 0) {
                          context.push('/day/$dateKey');
                        }
                      },
                      onPageChanged: (focusedDay) {
                        // D-09: persist the focused month across tab switches.
                        ref
                            .read(focusedMonthProvider.notifier)
                            .set(focusedDay);
                      },
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          // No decoration for future days.
                          if (day.isAfter(DateTime.now())) return null;
                          final dateKey = _toDateKey(day);
                          final total = monthTotals[dateKey];
                          // No data = no decoration (UI-SPEC rule 4).
                          if (total == null) return null;
                          final dailyTarget = _findActiveTarget(targets, dateKey);
                          if (total >= dailyTarget && dailyTarget > 0) {
                            return _buildDayCell(
                              context,
                              day,
                              metGoal: true,
                              isToday: false,
                            );
                          }
                          if (total > 0 && total < dailyTarget) {
                            return _buildDayCell(
                              context,
                              day,
                              metGoal: false,
                              isToday: false,
                            );
                          }
                          // total == 0 with an entry somehow — treat as no data.
                          return null;
                        },
                        todayBuilder: (context, day, focusedDay) {
                          final dateKey = _toDateKey(day);
                          final total = monthTotals[dateKey];
                          if (total == null) {
                            // Today with no data: show only the today ring (no fill).
                            return _buildDayCell(
                              context,
                              day,
                              metGoal: null,
                              isToday: true,
                            );
                          }
                          final dailyTarget = _findActiveTarget(targets, dateKey);
                          if (total >= dailyTarget && dailyTarget > 0) {
                            return _buildDayCell(
                              context,
                              day,
                              metGoal: true,
                              isToday: true,
                            );
                          }
                          if (total > 0) {
                            return _buildDayCell(
                              context,
                              day,
                              metGoal: false,
                              isToday: true,
                            );
                          }
                          // zero entries — today ring only
                          return _buildDayCell(
                            context,
                            day,
                            metGoal: null,
                            isToday: true,
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ---- MonthlyBarChart (CHART-01 through CHART-06) ----
                    MonthlyBarChart(
                      monthTotals: monthTotals,
                      year: focused.year,
                      month: focused.month,
                      targets: targets,
                      onBarTap: (dateKey) => context.push('/day/$dateKey'),
                    ),

                    // Bottom padding after MonthlyBarChart (last visible widget).
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
