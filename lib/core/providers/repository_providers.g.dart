// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(waterRepository)
final waterRepositoryProvider = WaterRepositoryProvider._();

final class WaterRepositoryProvider
    extends
        $FunctionalProvider<WaterRepository, WaterRepository, WaterRepository>
    with $Provider<WaterRepository> {
  WaterRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'waterRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$waterRepositoryHash();

  @$internal
  @override
  $ProviderElement<WaterRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WaterRepository create(Ref ref) {
    return waterRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WaterRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WaterRepository>(value),
    );
  }
}

String _$waterRepositoryHash() => r'cc29344204abc8cfdcbf98f2aad66610a08e50b9';

@ProviderFor(settingsRepository)
final settingsRepositoryProvider = SettingsRepositoryProvider._();

final class SettingsRepositoryProvider
    extends
        $FunctionalProvider<
          SettingsRepository,
          SettingsRepository,
          SettingsRepository
        >
    with $Provider<SettingsRepository> {
  SettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<SettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SettingsRepository create(Ref ref) {
    return settingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsRepository>(value),
    );
  }
}

String _$settingsRepositoryHash() =>
    r'3438db64b0bb6a4eaff60fcdb439987e740734c8';
