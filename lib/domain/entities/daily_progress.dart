import 'package:freezed_annotation/freezed_annotation.dart';
import 'water_entry_entity.dart';

part 'daily_progress.freezed.dart';

@freezed
abstract class DailyProgress with _$DailyProgress {
  const factory DailyProgress({
    required int totalMl,
    required int targetMl,
    required List<WaterEntryEntity> entries,
    required String dateKey,
  }) = _DailyProgress;
}
