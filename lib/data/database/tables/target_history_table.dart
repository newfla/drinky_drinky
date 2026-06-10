import 'package:drift/drift.dart';

class TargetHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get effectiveDate => text().unique()(); // YYYY-MM-DD, UNIQUE constraint
  IntColumn get targetMl => integer()();
}
