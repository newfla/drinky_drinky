// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drink_preset_dao.dart';

// ignore_for_file: type=lint
mixin _$DrinkPresetDaoMixin on DatabaseAccessor<AppDatabase> {
  $DrinkPresetsTable get drinkPresets => attachedDatabase.drinkPresets;
  DrinkPresetDaoManager get managers => DrinkPresetDaoManager(this);
}

class DrinkPresetDaoManager {
  final _$DrinkPresetDaoMixin _db;
  DrinkPresetDaoManager(this._db);
  $$DrinkPresetsTableTableManager get drinkPresets =>
      $$DrinkPresetsTableTableManager(_db.attachedDatabase, _db.drinkPresets);
}
