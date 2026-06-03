// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'water_entry_dao.dart';

// ignore_for_file: type=lint
mixin _$WaterEntryDaoMixin on DatabaseAccessor<AppDatabase> {
  $WaterEntriesTable get waterEntries => attachedDatabase.waterEntries;
  WaterEntryDaoManager get managers => WaterEntryDaoManager(this);
}

class WaterEntryDaoManager {
  final _$WaterEntryDaoMixin _db;
  WaterEntryDaoManager(this._db);
  $$WaterEntriesTableTableManager get waterEntries =>
      $$WaterEntriesTableTableManager(_db.attachedDatabase, _db.waterEntries);
}
