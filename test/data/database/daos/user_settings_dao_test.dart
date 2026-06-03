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

  group('UserSettingsDao', () {
    test('default settings are seeded on database creation', () async {
      final settings = await db.userSettingsDao.getSettings();

      expect(settings.dailyTargetMl, 2000);
      expect(settings.notificationIntervalMinutes, 60);
      expect(settings.dndStartHour, 23);
      expect(settings.dndStartMinute, 0);
      expect(settings.dndEndHour, 7);
      expect(settings.dndEndMinute, 0);
      expect(settings.dndEnabled, true);
    });

    test('updateSettings persists and is retrievable', () async {
      await db.userSettingsDao.updateSettings(
        UserSettingsCompanion(dailyTargetMl: Value(2500)),
      );

      final settings = await db.userSettingsDao.getSettings();
      expect(settings.dailyTargetMl, 2500);
      // Other fields should remain at defaults.
      expect(settings.notificationIntervalMinutes, 60);
      expect(settings.dndEnabled, true);
    });

    test('watchSettings emits updated value after updateSettings', () async {
      // Get the initial emission.
      final initial = await db.userSettingsDao.watchSettings().first;
      expect(initial.dailyTargetMl, 2000);

      // Update and verify the stream emits the new value.
      await db.userSettingsDao.updateSettings(
        UserSettingsCompanion(dailyTargetMl: Value(3000)),
      );

      final updated = await db.userSettingsDao.watchSettings().first;
      expect(updated.dailyTargetMl, 3000);
    });
  });
}
