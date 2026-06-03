import 'package:drift/drift.dart';

class DrinkPresets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get amountMl => integer()();
  IntColumn get sortOrder => integer()();
}
