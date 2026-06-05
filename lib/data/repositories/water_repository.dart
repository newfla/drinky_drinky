import 'package:collection/collection.dart';

import '../database/app_database.dart';
import '../../domain/entities/water_entry_entity.dart';

class WaterRepository {
  final AppDatabase _db;

  WaterRepository(this._db);

  /// Watch all entries for a specific date, mapped to domain entities.
  Stream<List<WaterEntryEntity>> watchEntriesForDate(String dateKey) {
    return _db.waterEntryDao.watchEntriesForDate(dateKey).map(
          (rows) => rows
              .map((r) => WaterEntryEntity(
                    id: r.id,
                    amountMl: r.amountMl,
                    loggedAt: r.loggedAt,
                    dateKey: r.dateKey,
                  ))
              .toList(),
        );
  }

  /// Insert a new water entry with input validation.
  Future<void> insertEntry(
      int amountMl, DateTime loggedAt, String dateKey) async {
    // T-01-01: Validate amountMl > 0
    if (amountMl <= 0) {
      throw ArgumentError.value(
          amountMl, 'amountMl', 'Must be greater than 0');
    }
    // T-01-02: Validate dateKey matches YYYY-MM-DD format and is a real calendar date.
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateKey)) {
      throw ArgumentError.value(
          dateKey, 'dateKey', 'Must match YYYY-MM-DD format');
    }
    final parsed = DateTime.tryParse(dateKey);
    final roundTrip = parsed == null
        ? null
        : '${parsed.year.toString().padLeft(4, '0')}-'
            '${parsed.month.toString().padLeft(2, '0')}-'
            '${parsed.day.toString().padLeft(2, '0')}';
    if (parsed == null || roundTrip != dateKey) {
      throw ArgumentError.value(
          dateKey, 'dateKey', 'Not a valid calendar date');
    }
    await _db.waterEntryDao.insertEntry(
      WaterEntriesCompanion.insert(
        amountMl: amountMl,
        loggedAt: loggedAt,
        dateKey: dateKey,
      ),
    );
  }

  /// Delete the most recent entry for [dateKey] (undo). Returns count of rows deleted.
  Future<int> deleteLastEntry(String dateKey) =>
      _db.waterEntryDao.deleteLastEntry(dateKey);

  /// Watch total ml consumed for a specific date.
  Stream<int> watchTotalForDate(String dateKey) {
    return _db.waterEntryDao.watchTotalForDate(dateKey);
  }

  /// Watch daily totals for a date range, grouped by dateKey.
  ///
  /// Returns a [Stream<Map<String, int>>] where key = dateKey (YYYY-MM-DD)
  /// and value = sum of amountMl for that day. Days with no entries are
  /// absent from the map (not zero). Used by both calendar and streak
  /// providers (D-01, D-02).
  Stream<Map<String, int>> watchDailyTotalsInRange(
      String startDateKey, String endDateKey) {
    return _db.waterEntryDao
        .watchEntriesInRange(startDateKey, endDateKey)
        .map((entries) {
      final grouped = groupBy(entries, (e) => e.dateKey);
      return grouped.map((dateKey, dayEntries) =>
          MapEntry(dateKey, dayEntries.fold(0, (sum, e) => sum + e.amountMl)));
    });
  }

  /// Get the earliest dateKey in the database. Pass-through to DAO.
  /// Returns null if no entries exist (new user) per D-05.
  Future<String?> getEarliestDateKey() =>
      _db.waterEntryDao.getEarliestDateKey();
}
