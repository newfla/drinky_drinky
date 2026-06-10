import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drinky_drinky/data/database/app_database.dart';
import 'package:drinky_drinky/data/repositories/water_repository.dart';

void main() {
  late AppDatabase db;
  late WaterRepository repo;

  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    repo = WaterRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('WaterRepository dateKey validation (BUG-03)', () {
    test('rejects semantically invalid date like 2024-02-30', () {
      expect(
        () => repo.insertEntry(250, DateTime.now(), '2024-02-30'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects malformed dateKey like abcd-ef-gh', () {
      expect(
        () => repo.insertEntry(250, DateTime.now(), 'abcd-ef-gh'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('accepts valid dateKey like 2026-06-03', () async {
      // Should not throw
      await repo.insertEntry(250, DateTime(2026, 6, 3, 10, 0), '2026-06-03');
    });
  });
}
