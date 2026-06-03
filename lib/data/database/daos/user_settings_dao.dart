import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/user_settings_table.dart';

part 'user_settings_dao.g.dart';

@DriftAccessor(tables: [UserSettings])
class UserSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$UserSettingsDaoMixin {
  UserSettingsDao(super.attachedDatabase);

  /// Watch the single settings row (id=1).
  Stream<UserSetting> watchSettings() {
    return (select(userSettings)..where((t) => t.id.equals(1))).watchSingle();
  }

  /// Get settings once.
  Future<UserSetting> getSettings() {
    return (select(userSettings)..where((t) => t.id.equals(1))).getSingle();
  }

  /// Update settings (single-row table, id=1).
  Future<void> updateSettings(UserSettingsCompanion settings) {
    return (update(userSettings)..where((t) => t.id.equals(1)))
        .write(settings);
  }
}
