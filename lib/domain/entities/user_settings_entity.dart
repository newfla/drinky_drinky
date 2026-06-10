import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_settings_entity.freezed.dart';

@freezed
abstract class UserSettingsEntity with _$UserSettingsEntity {
  const factory UserSettingsEntity({
    required int dailyTargetMl,
    required int notificationIntervalMinutes,
    required int dndStartHour,
    required int dndStartMinute,
    required int dndEndHour,
    required int dndEndMinute,
    required bool dndEnabled,
    required bool applyFromTomorrow,
  }) = _UserSettingsEntity;
}
