import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/drink_preset_entity.dart';
import '../../domain/entities/target_history_entry.dart';
import '../../domain/entities/user_settings_entity.dart';
import '../../domain/entities/water_entry_entity.dart';
import 'database_provider.dart';
import 'repository_providers.dart';

part 'stream_providers.g.dart';

/// Local helper to convert an arbitrary DateTime to a dateKey string (YYYY-MM-DD).
/// Matches the format used by [todayDateKey()].
String _toDateKey(DateTime d) {
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Watch water entries for the given [dateKey] as a reactive stream.
///
/// Callers should pass [dateKey] computed from [DateTime.now()] at widget
/// build time (e.g. via [todayDateKey()]) so the stream re-subscribes with
/// the correct date on every rebuild and naturally refreshes after midnight.
@riverpod
Stream<List<WaterEntryEntity>> waterEntriesForDate(
    Ref ref, String dateKey) {
  final repo = ref.watch(waterRepositoryProvider);
  return repo.watchEntriesForDate(dateKey);
}

/// Watch total ml consumed for the given [dateKey] as a reactive stream.
///
/// Callers should pass [dateKey] computed from [DateTime.now()] at widget
/// build time (e.g. via [todayDateKey()]) so the stream re-subscribes with
/// the correct date on every rebuild and naturally refreshes after midnight.
@riverpod
Stream<int> totalMlForDate(Ref ref, String dateKey) {
  final repo = ref.watch(waterRepositoryProvider);
  return repo.watchTotalForDate(dateKey);
}

/// Watch user settings as a reactive stream.
@Riverpod(keepAlive: true)
Stream<UserSettingsEntity> userSettings(Ref ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watchSettings();
}

/// Watch drink presets as a reactive stream.
@Riverpod(keepAlive: true)
Stream<List<DrinkPresetEntity>> drinkPresets(Ref ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watchPresets();
}

/// Format today's date as YYYY-MM-DD for date_key queries.
///
/// Call this at widget build time (e.g. inside [build] or a [ConsumerWidget]'s
/// build method) so that the returned string reflects the actual current date
/// each time the widget rebuilds, rather than a date captured once at startup.
String todayDateKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

/// Watch daily totals for a specific month as a reactive stream.
///
/// Family provider: each (year, month) combination is cached separately by
/// Riverpod. Navigating back to a previously visited month does not re-query
/// (D-07). Returns a `Map<dateKey, totalMl>` where absent keys mean no data
/// for that day (D-01).
@riverpod
Stream<Map<String, int>> calendarMonth(Ref ref, int year, int month) {
  final repo = ref.watch(waterRepositoryProvider);
  final firstDay = DateTime(year, month, 1);
  final lastDay = DateTime(year, month + 1, 0); // day 0 = last day of prev month
  final startKey = _toDateKey(firstDay);
  final endKey = _toDateKey(lastDay);
  return repo.watchDailyTotalsInRange(startKey, endKey);
}

/// Watch the current streak of consecutive days where the daily goal was met.
///
/// Counts backwards from yesterday (today is incomplete, D-08). Queries the
/// full history from 2020-01-01 as a safe lower bound. Returns 0 when no
/// target history rows exist. Evaluates each historical day against that
/// day's effective target from target_history, not a single global target
/// (D-11).
@riverpod
Stream<int> streak(Ref ref) {
  final repo = ref.watch(waterRepositoryProvider);
  final db = ref.watch(appDatabaseProvider);

  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  final yesterdayKey = _toDateKey(yesterday);

  // Use targetHistoryDao.watchAll() as the outer stream via asyncExpand (D-11).
  // TargetHistoryData is only used inside the body (not in the function signature)
  // so riverpod_generator resolves this correctly.
  return db.targetHistoryDao.watchAll().asyncExpand((targets) {
    if (targets.isEmpty) {
      return Stream.value(0);
    }

    return repo
        .watchDailyTotalsInRange('2020-01-01', yesterdayKey)
        .map((totals) {
      int count = 0;
      var current = yesterday;
      while (true) {
        final key = _toDateKey(current);
        final total = totals[key] ?? 0;

        // Find the active target for this day: last entry where effectiveDate <= key
        // targets is sorted ASC by effectiveDate (D-11)
        int activeTarget = targets.first.targetMl; // earliest target as fallback
        for (final t in targets) {
          if (t.effectiveDate.compareTo(key) <= 0) {
            activeTarget = t.targetMl;
          } else {
            break;
          }
        }

        if (activeTarget <= 0) return 0;

        if (total >= activeTarget) {
          count++;
          current = current.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
      return count;
    });
  });
}

/// Persist the focused month in the calendar across tab switches.
///
/// keepAlive: true so the state survives when HistoryScreen is not visible
/// (D-09). Initialized to the current month. The widget calls
/// [ref.read(focusedMonthProvider.notifier).set(month)] on page change.
@Riverpod(keepAlive: true)
class FocusedMonth extends _$FocusedMonth {
  @override
  DateTime build() => DateTime.now();

  /// Update the focused month (called from TableCalendar.onPageChanged).
  void set(DateTime month) => state = month;
}

/// Provides today's date key (YYYY-MM-DD) as a keepAlive Notifier that
/// automatically updates state at midnight without polling (D-01, D-02,
/// BUG-02 fix). Uses a single Timer that fires after the remaining seconds
/// of the current day expire, then reschedules itself for the next midnight.
@Riverpod(keepAlive: true)
class TodayDateKey extends _$TodayDateKey {
  Timer? _midnightTimer;

  @override
  String build() {
    ref.onDispose(() => _midnightTimer?.cancel());
    _scheduleMidnightRefresh();
    return _computeTodayKey();
  }

  String _computeTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final duration = nextMidnight.difference(now) + const Duration(seconds: 1);
    _midnightTimer = Timer(duration, _onMidnight);
  }

  void _onMidnight() {
    state = _computeTodayKey();
    _scheduleMidnightRefresh();
  }
}

/// Reactive stream of the effective target (in ml) for a given [dateKey].
///
/// Returns the targetMl from the most recent target_history row where
/// effectiveDate <= dateKey. Falls back to 2000 ml if no row exists
/// (defensive fallback -- should never be null after seed).
///
/// keepAlive: true so the same stream is reused across widgets on the
/// same day (D-08).
@Riverpod(keepAlive: true)
Stream<int> effectiveTargetForDate(Ref ref, String dateKey) {
  final db = ref.watch(appDatabaseProvider);
  return db.targetHistoryDao
      .watchTargetForDate(dateKey)
      .map((targetMl) => targetMl ?? 2000); // defensive fallback -- should never be null after seed
}

/// Reactive stream of all target_history rows ordered by effectiveDate ASC,
/// mapped to the domain [TargetHistoryEntry] type.
///
/// Used by calendar and streak providers for batch lookup of per-day targets
/// without making one DB query per day (D-10, D-11).
///
/// keepAlive: true so the stream is shared and not recreated on every rebuild.
@Riverpod(keepAlive: true)
Stream<List<TargetHistoryEntry>> allTargetHistory(Ref ref) {
  return ref.watch(appDatabaseProvider).targetHistoryDao.watchAll().map(
        (rows) => rows
            .map(
              (r) => TargetHistoryEntry(
                id: r.id,
                effectiveDate: r.effectiveDate,
                targetMl: r.targetMl,
              ),
            )
            .toList(),
      );
}
