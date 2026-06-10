import 'package:drift/drift.dart';

class UserSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dailyTargetMl =>
      integer().withDefault(const Constant(2000))();
  IntColumn get notificationIntervalMinutes =>
      integer().withDefault(const Constant(60))();
  IntColumn get dndStartHour =>
      integer().withDefault(const Constant(23))();
  IntColumn get dndStartMinute =>
      integer().withDefault(const Constant(0))();
  IntColumn get dndEndHour =>
      integer().withDefault(const Constant(7))();
  IntColumn get dndEndMinute =>
      integer().withDefault(const Constant(0))();
  BoolColumn get dndEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get applyFromTomorrow =>
      boolean().withDefault(const Constant(false))();
}
