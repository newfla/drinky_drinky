import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'tables/water_entries_table.dart';
import 'tables/user_settings_table.dart';
import 'tables/drink_presets_table.dart';
import 'daos/water_entry_dao.dart';
import 'daos/user_settings_dao.dart';
import 'daos/drink_preset_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [WaterEntries, UserSettings, DrinkPresets],
  daos: [WaterEntryDao, UserSettingsDao, DrinkPresetDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'drinky_drinky',
      native: DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Seed default settings (single row, id=1).
        // All columns have defaults, so empty insert works.
        await into(userSettings).insert(
          UserSettingsCompanion.insert(),
        );
        // Seed default drink presets (200/300/400/500ml).
        await batch((batch) {
          batch.insertAll(drinkPresets, [
            DrinkPresetsCompanion.insert(amountMl: 200, sortOrder: 0),
            DrinkPresetsCompanion.insert(amountMl: 300, sortOrder: 1),
            DrinkPresetsCompanion.insert(amountMl: 400, sortOrder: 2),
            DrinkPresetsCompanion.insert(amountMl: 500, sortOrder: 3),
          ]);
        });
      },
      beforeOpen: (details) async {
        // Enable foreign keys.
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}
