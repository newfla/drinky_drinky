import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/user_settings_table.dart';

part 'user_settings_dao.g.dart';

@DriftAccessor(tables: [UserSettings])
class UserSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$UserSettingsDaoMixin {
  UserSettingsDao(super.attachedDatabase);

  /// Watch the single settings row (id=1).
  ///
  /// Emits default values if the row is absent (e.g. after a data-clear or
  /// a failed migration) instead of throwing a [StateError].
  Stream<UserSetting> watchSettings() {
    return (select(userSettings)..where((t) => t.id.equals(1)))
        .watchSingleOrNull()
        .map((row) => row ?? _defaultSettings());
  }

  /// Get settings once.
  ///
  /// Returns default values if the row is absent instead of throwing a
  /// [StateError].
  Future<UserSetting> getSettings() async {
    final row =
        await (select(userSettings)..where((t) => t.id.equals(1))).getSingleOrNull();
    return row ?? _defaultSettings();
  }

  /// Default settings used when the id=1 row is absent.
  UserSetting _defaultSettings() {
    return const UserSetting(
      id: 1,
      dailyTargetMl: 2000,
      notificationIntervalMinutes: 60,
      dndStartHour: 23,
      dndStartMinute: 0,
      dndEndHour: 7,
      dndEndMinute: 0,
      dndEnabled: true,
      applyFromTomorrow: false,
    );
  }

  /// Update settings (single-row table, id=1).
  Future<void> updateSettings(UserSettingsCompanion settings) {
    return (update(userSettings)..where((t) => t.id.equals(1)))
        .write(settings);
  }
}
