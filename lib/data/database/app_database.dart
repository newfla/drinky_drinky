import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'tables/water_entries_table.dart';
import 'tables/user_settings_table.dart';
import 'tables/drink_presets_table.dart';
import 'daos/water_entry_dao.dart';
import 'daos/user_settings_dao.dart';
import 'daos/drink_preset_dao.dart';
import 'tables/target_history_table.dart';
import 'daos/target_history_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [WaterEntries, UserSettings, DrinkPresets, TargetHistory],
  daos: [WaterEntryDao, UserSettingsDao, DrinkPresetDao, TargetHistoryDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

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
        // Seed default drink presets (150/250/500ml).
        await batch((batch) {
          batch.insertAll(drinkPresets, [
            DrinkPresetsCompanion.insert(amountMl: 150, sortOrder: 0),
            DrinkPresetsCompanion.insert(amountMl: 250, sortOrder: 1),
            DrinkPresetsCompanion.insert(amountMl: 500, sortOrder: 2),
          ]);
        });
        // Seed default target history with today's date and default target.
        // Date formatting inlined to avoid circular dependency on providers layer.
        final now = DateTime.now();
        final todayKey =
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        await into(targetHistory).insert(
          TargetHistoryCompanion.insert(
            effectiveDate: todayKey,
            targetMl: 2000,
          ),
        );
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(userSettings, userSettings.applyFromTomorrow);
        }
      },
      beforeOpen: (details) async {
        // Enable foreign keys.
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}
