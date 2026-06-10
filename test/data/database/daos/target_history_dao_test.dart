import 'package:drift/drift.dart' hide isNull, isNotNull;
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

  /// Helper: today's date as YYYY-MM-DD, matching the seed pattern in onCreate.
  String todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  group('TargetHistoryDao', () {
    test('seed row exists after database creation', () async {
      final rows = await db.targetHistoryDao.watchAll().first;
      expect(rows, hasLength(1));
      expect(rows.first.targetMl, 2000);
      expect(rows.first.effectiveDate, todayKey());
    });

    test('getTargetForDate returns seed target for today', () async {
      final target = await db.targetHistoryDao.getTargetForDate(todayKey());
      expect(target, 2000);
    });

    test('getTargetForDate returns most recent target on or before dateKey',
        () async {
      // Insert two rows with dates well in the future (after today's seed)
      await db.targetHistoryDao.insertOrReplace('2030-01-01', 1500);
      await db.targetHistoryDao.insertOrReplace('2030-06-01', 2500);

      // 2030-03-15 is after 2030-01-01 but before 2030-06-01
      // so the most recent row <= 2030-03-15 is 2030-01-01 (1500)
      final midTarget =
          await db.targetHistoryDao.getTargetForDate('2030-03-15');
      expect(midTarget, 1500);

      // 2030-07-01 is after 2030-06-01
      // so the most recent row <= 2030-07-01 is 2030-06-01 (2500)
      final laterTarget =
          await db.targetHistoryDao.getTargetForDate('2030-07-01');
      expect(laterTarget, 2500);
    });

    test('getTargetForDate returns null for date before any entry', () async {
      // The seed row has effectiveDate = today. A date far in the past
      // should precede even the seed.
      final target =
          await db.targetHistoryDao.getTargetForDate('2020-01-01');
      expect(target, isNull);
    });

    test('insertOrReplace inserts new row for new date', () async {
      await db.targetHistoryDao.insertOrReplace('2030-01-01', 3000);

      final rows = await db.targetHistoryDao.watchAll().first;
      // Seed row + new row = at least 2
      expect(rows.length, greaterThanOrEqualTo(2));

      final newRow =
          rows.where((r) => r.effectiveDate == '2030-01-01').toList();
      expect(newRow, hasLength(1));
      expect(newRow.first.targetMl, 3000);
    });

    test('insertOrReplace updates existing row for same date (upsert)',
        () async {
      await db.targetHistoryDao.insertOrReplace('2026-06-15', 1800);
      await db.targetHistoryDao.insertOrReplace('2026-06-15', 2200);

      final rows = await db.targetHistoryDao.watchAll().first;
      final matchingRows =
          rows.where((r) => r.effectiveDate == '2026-06-15').toList();
      expect(matchingRows, hasLength(1));
      expect(matchingRows.first.targetMl, 2200);
    });

    test('watchAll returns rows ordered by effectiveDate ASC', () async {
      // Insert in non-chronological order
      await db.targetHistoryDao.insertOrReplace('2026-12-01', 3000);
      await db.targetHistoryDao.insertOrReplace('2026-01-01', 1500);
      await db.targetHistoryDao.insertOrReplace('2026-06-01', 2500);

      final rows = await db.targetHistoryDao.watchAll().first;
      // Should include seed (today) + 3 inserted rows
      expect(rows.length, greaterThanOrEqualTo(4));

      // Verify ascending order
      for (int i = 1; i < rows.length; i++) {
        expect(
          rows[i].effectiveDate.compareTo(rows[i - 1].effectiveDate),
          greaterThan(0),
          reason:
              '${rows[i].effectiveDate} should come after ${rows[i - 1].effectiveDate}',
        );
      }
    });
  });
}
