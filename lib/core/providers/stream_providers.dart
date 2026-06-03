import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/water_entry_entity.dart';
import '../../domain/entities/user_settings_entity.dart';
import '../../domain/entities/drink_preset_entity.dart';
import 'repository_providers.dart';

part 'stream_providers.g.dart';

/// Watch today's water entries as a reactive stream.
@Riverpod(keepAlive: true)
Stream<List<WaterEntryEntity>> todayWaterEntries(Ref ref) {
  final repo = ref.watch(waterRepositoryProvider);
  return repo.watchEntriesForDate(_todayDateKey());
}

/// Watch today's total ml consumed as a reactive stream.
@Riverpod(keepAlive: true)
Stream<int> todayTotalMl(Ref ref) {
  final repo = ref.watch(waterRepositoryProvider);
  return repo.watchTotalForDate(_todayDateKey());
}

/// Watch user settings as a reactive stream.
@Riverpod(keepAlive: true)
Stream<UserSettingsEntity> userSettings(Ref ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watchSettings();
}

/// Watch drink presets as a reactive stream.
@Riverpod(keepAlive: true)
Stream<List<DrinkPresetEntity>> drinkPresets(Ref ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watchPresets();
}

/// Format today's date as YYYY-MM-DD for date_key queries.
String _todayDateKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}
