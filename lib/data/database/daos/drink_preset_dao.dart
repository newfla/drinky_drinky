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

  /// Update a preset's amount. Returns the number of rows affected.
  ///
  /// Returns 0 if no row with [id] exists (silent no-op). Throws
  /// [ArgumentError] if [amountMl] is not greater than 0.
  Future<int> updatePreset(int id, int amountMl) {
    if (amountMl <= 0) {
      throw ArgumentError.value(amountMl, 'amountMl', 'Must be greater than 0');
    }
    return (update(drinkPresets)..where((t) => t.id.equals(id)))
        .write(DrinkPresetsCompanion(amountMl: Value(amountMl)));
  }
}
