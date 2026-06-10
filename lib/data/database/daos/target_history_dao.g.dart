// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'target_history_dao.dart';

// ignore_for_file: type=lint
mixin _$TargetHistoryDaoMixin on DatabaseAccessor<AppDatabase> {
  $TargetHistoryTable get targetHistory => attachedDatabase.targetHistory;
  TargetHistoryDaoManager get managers => TargetHistoryDaoManager(this);
}

class TargetHistoryDaoManager {
  final _$TargetHistoryDaoMixin _db;
  TargetHistoryDaoManager(this._db);
  $$TargetHistoryTableTableManager get targetHistory =>
      $$TargetHistoryTableTableManager(_db.attachedDatabase, _db.targetHistory);
}
