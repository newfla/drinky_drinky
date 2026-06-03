import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/drink_presets_table.dart';

part 'drink_preset_dao.g.dart';

@DriftAccessor(tables: [DrinkPresets])
class DrinkPresetDao extends DatabaseAccessor<AppDatabase>
    with _$DrinkPresetDaoMixin {
  DrinkPresetDao(super.attachedDatabase);

  /// Watch all presets ordered by sortOrder ascending.
  Stream<List<DrinkPreset>> watchAllPresets() {
    return (select(drinkPresets)
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  /// Update a preset's amount.
  Future<void> updatePreset(int id, int amountMl) {
    return (update(drinkPresets)..where((t) => t.id.equals(id)))
        .write(DrinkPresetsCompanion(amountMl: Value(amountMl)));
  }
}
