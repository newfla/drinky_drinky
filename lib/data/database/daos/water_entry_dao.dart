import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/water_entries_table.dart';

part 'water_entry_dao.g.dart';

@DriftAccessor(tables: [WaterEntries])
class WaterEntryDao extends DatabaseAccessor<AppDatabase>
    with _$WaterEntryDaoMixin {
  WaterEntryDao(super.attachedDatabase);

  /// Insert a new water entry.
  Future<int> insertEntry(WaterEntriesCompanion entry) {
    return into(waterEntries).insert(entry);
  }

  /// Watch all entries for a specific date_key, ordered by loggedAt ascending.
  Stream<List<WaterEntry>> watchEntriesForDate(String dateKey) {
    return (select(waterEntries)
          ..where((t) => t.dateKey.equals(dateKey))
          ..orderBy([(t) => OrderingTerm.asc(t.loggedAt)]))
        .watch();
  }

  /// Watch total ml for a date_key (aggregate sum).
  Stream<int> watchTotalForDate(String dateKey) {
    final totalMl = waterEntries.amountMl.sum();
    final query = selectOnly(waterEntries)
      ..addColumns([totalMl])
      ..where(waterEntries.dateKey.equals(dateKey));
    return query.watchSingle().map((row) => row.read(totalMl) ?? 0);
  }

  /// Delete the most recent entry (for undo). Returns number of rows deleted.
  Future<int> deleteLastEntry() async {
    final lastEntry = await (select(waterEntries)
          ..orderBy([(t) => OrderingTerm.desc(t.loggedAt)])
          ..limit(1))
        .getSingleOrNull();
    if (lastEntry == null) return 0;
    return (delete(waterEntries)..where((t) => t.id.equals(lastEntry.id)))
        .go();
  }

  /// Watch entries in a date range (for calendar view).
  Stream<List<WaterEntry>> watchEntriesInRange(
      String startDateKey, String endDateKey) {
    return (select(waterEntries)
          ..where((t) =>
              t.dateKey.isBiggerOrEqualValue(startDateKey) &
              t.dateKey.isSmallerOrEqualValue(endDateKey)))
        .watch();
  }
}
