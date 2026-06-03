import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/water_repository.dart';
import '../../data/repositories/settings_repository.dart';
import 'database_provider.dart';

part 'repository_providers.g.dart';

@Riverpod(keepAlive: true)
WaterRepository waterRepository(Ref ref) {
  return WaterRepository(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) {
  return SettingsRepository(ref.watch(appDatabaseProvider));
}
