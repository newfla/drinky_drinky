import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/target_history_table.dart';

part 'target_history_dao.g.dart';

@DriftAccessor(tables: [TargetHistory])
class TargetHistoryDao extends DatabaseAccessor<AppDatabase>
    with _$TargetHistoryDaoMixin {
  TargetHistoryDao(super.attachedDatabase);

  /// Returns the targetMl for the most recent row where effectiveDate <= dateKey.
  /// Returns null if no rows exist (defensive -- should not happen after onCreate seed).
  Future<int?> getTargetForDate(String dateKey) async {
    final row = await (select(targetHistory)
          ..where((t) => t.effectiveDate.isSmallerOrEqualValue(dateKey))
          ..orderBy([(t) => OrderingTerm.desc(t.effectiveDate)])
          ..limit(1))
        .getSingleOrNull();
    return row?.targetMl;
  }

  /// Reactive stream of all history rows, ordered by effectiveDate ASC.
  Stream<List<TargetHistoryData>> watchAll() {
    return (select(targetHistory)
          ..orderBy([(t) => OrderingTerm.asc(t.effectiveDate)]))
        .watch();
  }

  /// Upsert: insert a new row or update targetMl if effectiveDate already exists.
  Future<void> insertOrReplace(String effectiveDate, int targetMl) {
    return into(targetHistory).insert(
      TargetHistoryCompanion.insert(
        effectiveDate: effectiveDate,
        targetMl: targetMl,
      ),
      onConflict: DoUpdate(
        (old) => TargetHistoryCompanion.custom(
          targetMl: Constant(targetMl),
        ),
        target: [targetHistory.effectiveDate],
      ),
    );
  }
}
