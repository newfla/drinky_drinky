import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../../domain/entities/user_settings_entity.dart';
import '../../domain/entities/drink_preset_entity.dart';

class SettingsRepository {
  final AppDatabase _db;

  SettingsRepository(this._db);

  /// Watch the single settings row, mapped to domain entity.
  Stream<UserSettingsEntity> watchSettings() {
    return _db.userSettingsDao.watchSettings().map(
          (row) => UserSettingsEntity(
            dailyTargetMl: row.dailyTargetMl,
            notificationIntervalMinutes: row.notificationIntervalMinutes,
            dndStartHour: row.dndStartHour,
            dndStartMinute: row.dndStartMinute,
            dndEndHour: row.dndEndHour,
            dndEndMinute: row.dndEndMinute,
            dndEnabled: row.dndEnabled,
          ),
        );
  }

  /// Get settings once, mapped to domain entity.
  Future<UserSettingsEntity> getSettings() async {
    final row = await _db.userSettingsDao.getSettings();
    return UserSettingsEntity(
      dailyTargetMl: row.dailyTargetMl,
      notificationIntervalMinutes: row.notificationIntervalMinutes,
      dndStartHour: row.dndStartHour,
      dndStartMinute: row.dndStartMinute,
      dndEndHour: row.dndEndHour,
      dndEndMinute: row.dndEndMinute,
      dndEnabled: row.dndEnabled,
    );
  }

  /// Update settings from domain entity.
  ///
  /// Throws [ArgumentError] if any field is outside its valid range.
  Future<void> updateSettings(UserSettingsEntity entity) {
    if (entity.dailyTargetMl <= 0) {
      throw ArgumentError('dailyTargetMl must be > 0');
    }
    if (entity.notificationIntervalMinutes <= 0) {
      throw ArgumentError('notificationIntervalMinutes must be > 0');
    }
    if (entity.dndStartHour < 0 ||
        entity.dndStartHour > 23 ||
        entity.dndEndHour < 0 ||
        entity.dndEndHour > 23 ||
        entity.dndStartMinute < 0 ||
        entity.dndStartMinute > 59 ||
        entity.dndEndMinute < 0 ||
        entity.dndEndMinute > 59) {
      throw ArgumentError('DND hour/minute values out of valid range');
    }
    return _db.userSettingsDao.updateSettings(
      UserSettingsCompanion(
        dailyTargetMl: Value(entity.dailyTargetMl),
        notificationIntervalMinutes:
            Value(entity.notificationIntervalMinutes),
        dndStartHour: Value(entity.dndStartHour),
        dndStartMinute: Value(entity.dndStartMinute),
        dndEndHour: Value(entity.dndEndHour),
        dndEndMinute: Value(entity.dndEndMinute),
        dndEnabled: Value(entity.dndEnabled),
      ),
    );
  }

  /// Watch all presets, mapped to domain entities.
  Stream<List<DrinkPresetEntity>> watchPresets() {
    return _db.drinkPresetDao.watchAllPresets().map(
          (rows) => rows
              .map((r) => DrinkPresetEntity(
                    id: r.id,
                    amountMl: r.amountMl,
                    sortOrder: r.sortOrder,
                  ))
              .toList(),
        );
  }

  /// Update a preset's amount.
  Future<void> updatePreset(int id, int amountMl) {
    return _db.drinkPresetDao.updatePreset(id, amountMl);
  }
}
