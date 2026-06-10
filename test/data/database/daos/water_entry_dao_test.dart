import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drinky_drinky/data/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('WaterEntryDao', () {
    test('insert an entry and watch entries for that date returns it', () async {
      await db.waterEntryDao.insertEntry(
        WaterEntriesCompanion.insert(
          amountMl: 250,
          loggedAt: DateTime(2026, 6, 3, 10, 30),
          dateKey: '2026-06-03',
        ),
      );

      final entries =
          await db.waterEntryDao.watchEntriesForDate('2026-06-03').first;
      expect(entries, hasLength(1));
      expect(entries.first.amountMl, 250);
    });

    test('watchTotalForDate aggregates sum correctly', () async {
      await db.waterEntryDao.insertEntry(
        WaterEntriesCompanion.insert(
          amountMl: 200,
          loggedAt: DateTime(2026, 6, 3, 8, 0),
          dateKey: '2026-06-03',
        ),
      );
      await db.waterEntryDao.insertEntry(
        WaterEntriesCompanion.insert(
          amountMl: 300,
          loggedAt: DateTime(2026, 6, 3, 9, 0),
          dateKey: '2026-06-03',
        ),
      );

      final total =
          await db.waterEntryDao.watchTotalForDate('2026-06-03').first;
      expect(total, 500);
    });

    test('deleteLastEntry removes entry with later loggedAt', () async {
      await db.waterEntryDao.insertEntry(
        WaterEntriesCompanion.insert(
          amountMl: 200,
          loggedAt: DateTime(2026, 6, 3, 8, 0),
          dateKey: '2026-06-03',
        ),
      );
      await db.waterEntryDao.insertEntry(
        WaterEntriesCompanion.insert(
          amountMl: 300,
          loggedAt: DateTime(2026, 6, 3, 9, 0),
          dateKey: '2026-06-03',
        ),
      );

      await db.waterEntryDao.deleteLastEntry('2026-06-03');

      final entries =
          await db.waterEntryDao.watchEntriesForDate('2026-06-03').first;
      expect(entries, hasLength(1));
      expect(entries.first.amountMl, 200);
    });

    test('watchEntriesForDate returns entries ordered by loggedAt ascending',
        () async {
      // Insert in reverse chronological order.
      await db.waterEntryDao.insertEntry(
        WaterEntriesCompanion.insert(
          amountMl: 300,
          loggedAt: DateTime(2026, 6, 3, 12, 0),
          dateKey: '2026-06-03',
        ),
      );
      await db.waterEntryDao.insertEntry(
        WaterEntriesCompanion.insert(
          amountMl: 200,
          loggedAt: DateTime(2026, 6, 3, 8, 0),
          dateKey: '2026-06-03',
        ),
      );
      await db.waterEntryDao.insertEntry(
        WaterEntriesCompanion.insert(
          amountMl: 250,
          loggedAt: DateTime(2026, 6, 3, 10, 0),
          dateKey: '2026-06-03',
        ),
      );

      final entries =
          await db.waterEntryDao.watchEntriesForDate('2026-06-03').first;
      expect(entries, hasLength(3));
      expect(entries[0].amountMl, 200); // 08:00
      expect(entries[1].amountMl, 250); // 10:00
      expect(entries[2].amountMl, 300); // 12:00
    });

    test('entries for different date_keys are isolated', () async {
      await db.waterEntryDao.insertEntry(
        WaterEntriesCompanion.insert(
          amountMl: 250,
          loggedAt: DateTime(2026, 6, 3, 10, 0),
          dateKey: '2026-06-03',
        ),
      );
      await db.waterEntryDao.insertEntry(
        WaterEntriesCompanion.insert(
          amountMl: 400,
          loggedAt: DateTime(2026, 6, 4, 10, 0),
          dateKey: '2026-06-04',
        ),
      );

      final entriesJune3 =
          await db.waterEntryDao.watchEntriesForDate('2026-06-03').first;
      final entriesJune4 =
          await db.waterEntryDao.watchEntriesForDate('2026-06-04').first;

      expect(entriesJune3, hasLength(1));
      expect(entriesJune3.first.amountMl, 250);
      expect(entriesJune4, hasLength(1));
      expect(entriesJune4.first.amountMl, 400);
    });

    test('watchEntriesInRange returns entries within the date range only',
        () async {
      await db.waterEntryDao.insertEntry(
        WaterEntriesCompanion.insert(
          amountMl: 100,
          loggedAt: DateTime(2026, 6, 1, 10, 0),
          dateKey: '2026-06-01',
        ),
      );
      await db.waterEntryDao.insertEntry(
        WaterEntriesCompanion.insert(
          amountMl: 200,
          loggedAt: DateTime(2026, 6, 3, 10, 0),
          dateKey: '2026-06-03',
        ),
      );
      await db.waterEntryDao.insertEntry(
        WaterEntriesCompanion.insert(
          amountMl: 300,
          loggedAt: DateTime(2026, 6, 5, 10, 0),
          dateKey: '2026-06-05',
        ),
      );
      await db.waterEntryDao.insertEntry(
        WaterEntriesCompanion.insert(
          amountMl: 400,
          loggedAt: DateTime(2026, 6, 7, 10, 0),
          dateKey: '2026-06-07',
        ),
      );

      final inRange = await db.waterEntryDao
          .watchEntriesInRange('2026-06-02', '2026-06-05')
          .first;

      expect(inRange, hasLength(2));
      expect(inRange.map((e) => e.amountMl).toList(), containsAll([200, 300]));
    });

    test('deleteLastEntry does not delete entries from other dates (BUG-01)',
        () async {
      // Insert entry for yesterday
      await db.waterEntryDao.insertEntry(
        WaterEntriesCompanion.insert(
          amountMl: 500,
          loggedAt: DateTime(2026, 6, 2, 20, 0),
          dateKey: '2026-06-02',
        ),
      );
      // Insert entry for today
      await db.waterEntryDao.insertEntry(
        WaterEntriesCompanion.insert(
          amountMl: 250,
          loggedAt: DateTime(2026, 6, 3, 8, 0),
          dateKey: '2026-06-03',
        ),
      );

      // Delete last entry for today
      await db.waterEntryDao.deleteLastEntry('2026-06-03');

      // Yesterday's entry must still exist
      final yesterdayEntries =
          await db.waterEntryDao.watchEntriesForDate('2026-06-02').first;
      expect(yesterdayEntries, hasLength(1));
      expect(yesterdayEntries.first.amountMl, 500);

      // Today should be empty
      final todayEntries =
          await db.waterEntryDao.watchEntriesForDate('2026-06-03').first;
      expect(todayEntries, isEmpty);
    });
  });
}
