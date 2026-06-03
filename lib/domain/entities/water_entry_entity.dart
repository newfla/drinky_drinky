import 'package:freezed_annotation/freezed_annotation.dart';

part 'water_entry_entity.freezed.dart';

@freezed
abstract class WaterEntryEntity with _$WaterEntryEntity {
  const factory WaterEntryEntity({
    required int id,
    required int amountMl,
    required DateTime loggedAt,
    required String dateKey,
  }) = _WaterEntryEntity;
}
