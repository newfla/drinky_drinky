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

  group('DrinkPresetDao', () {
    test('default presets are seeded with correct amounts in sort order',
        () async {
      final presets = await db.drinkPresetDao.watchAllPresets().first;

      expect(presets, hasLength(3));
      expect(presets[0].amountMl, 150);
      expect(presets[1].amountMl, 250);
      expect(presets[2].amountMl, 500);

      // Verify sort order values.
      expect(presets[0].sortOrder, 0);
      expect(presets[1].sortOrder, 1);
      expect(presets[2].sortOrder, 2);
    });

    test('updatePreset changes amountMl and watchAllPresets reflects it',
        () async {
      final presets = await db.drinkPresetDao.watchAllPresets().first;
      final firstPresetId = presets.first.id;

      await db.drinkPresetDao.updatePreset(firstPresetId, 200);

      final updatedPresets = await db.drinkPresetDao.watchAllPresets().first;
      final updatedFirst =
          updatedPresets.firstWhere((p) => p.id == firstPresetId);
      expect(updatedFirst.amountMl, 200);
    });
  });
}
