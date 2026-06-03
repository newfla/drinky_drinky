import 'package:freezed_annotation/freezed_annotation.dart';

part 'drink_preset_entity.freezed.dart';

@freezed
abstract class DrinkPresetEntity with _$DrinkPresetEntity {
  const factory DrinkPresetEntity({
    required int id,
    required int amountMl,
    required int sortOrder,
  }) = _DrinkPresetEntity;
}
