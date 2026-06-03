import 'package:drift/drift.dart';

@TableIndex(name: 'idx_water_entries_date_key', columns: {#dateKey})
class WaterEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get amountMl => integer()();
  DateTimeColumn get loggedAt => dateTime()();
  TextColumn get dateKey => text()(); // 'YYYY-MM-DD' local date
}
