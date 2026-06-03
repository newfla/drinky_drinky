import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/water_entry_entity.dart';
import '../../domain/entities/user_settings_entity.dart';
import '../../domain/entities/drink_preset_entity.dart';
import 'repository_providers.dart';

part 'stream_providers.g.dart';

/// Watch water entries for the given [dateKey] as a reactive stream.
///
/// Callers should pass [dateKey] computed from [DateTime.now()] at widget
/// build time (e.g. via [todayDateKey()]) so the stream re-subscribes with
/// the correct date on every rebuild and naturally refreshes after midnight.
@riverpod
Stream<List<WaterEntryEntity>> waterEntriesForDate(
    Ref ref, String dateKey) {
  final repo = ref.watch(waterRepositoryProvider);
  return repo.watchEntriesForDate(dateKey);
}

/// Watch total ml consumed for the given [dateKey] as a reactive stream.
///
/// Callers should pass [dateKey] computed from [DateTime.now()] at widget
/// build time (e.g. via [todayDateKey()]) so the stream re-subscribes with
/// the correct date on every rebuild and naturally refreshes after midnight.
@riverpod
Stream<int> totalMlForDate(Ref ref, String dateKey) {
  final repo = ref.watch(waterRepositoryProvider);
  return repo.watchTotalForDate(dateKey);
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
///
/// Call this at widget build time (e.g. inside [build] or a [ConsumerWidget]'s
/// build method) so that the returned string reflects the actual current date
/// each time the widget rebuilds, rather than a date captured once at startup.
String todayDateKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}
