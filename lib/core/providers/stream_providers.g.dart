// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stream_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Watch today's water entries as a reactive stream.

@ProviderFor(todayWaterEntries)
final todayWaterEntriesProvider = TodayWaterEntriesProvider._();

/// Watch today's water entries as a reactive stream.

final class TodayWaterEntriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WaterEntryEntity>>,
          List<WaterEntryEntity>,
          Stream<List<WaterEntryEntity>>
        >
    with
        $FutureModifier<List<WaterEntryEntity>>,
        $StreamProvider<List<WaterEntryEntity>> {
  /// Watch today's water entries as a reactive stream.
  TodayWaterEntriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayWaterEntriesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayWaterEntriesHash();

  @$internal
  @override
  $StreamProviderElement<List<WaterEntryEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<WaterEntryEntity>> create(Ref ref) {
    return todayWaterEntries(ref);
  }
}

String _$todayWaterEntriesHash() => r'9d233dd27ff11e0707f2f35c277d67b6dd9aaaa8';

/// Watch today's total ml consumed as a reactive stream.

@ProviderFor(todayTotalMl)
final todayTotalMlProvider = TodayTotalMlProvider._();

/// Watch today's total ml consumed as a reactive stream.

final class TodayTotalMlProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// Watch today's total ml consumed as a reactive stream.
  TodayTotalMlProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayTotalMlProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayTotalMlHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return todayTotalMl(ref);
  }
}

String _$todayTotalMlHash() => r'85f194149c99e49ef6839d0448c8ac927c85899d';

/// Watch user settings as a reactive stream.

@ProviderFor(userSettings)
final userSettingsProvider = UserSettingsProvider._();

/// Watch user settings as a reactive stream.

final class UserSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<UserSettingsEntity>,
          UserSettingsEntity,
          Stream<UserSettingsEntity>
        >
    with
        $FutureModifier<UserSettingsEntity>,
        $StreamProvider<UserSettingsEntity> {
  /// Watch user settings as a reactive stream.
  UserSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userSettingsHash();

  @$internal
  @override
  $StreamProviderElement<UserSettingsEntity> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<UserSettingsEntity> create(Ref ref) {
    return userSettings(ref);
  }
}

String _$userSettingsHash() => r'0f03c46a891754c8b609a9535554c42a929e0b50';

/// Watch drink presets as a reactive stream.

@ProviderFor(drinkPresets)
final drinkPresetsProvider = DrinkPresetsProvider._();

/// Watch drink presets as a reactive stream.

final class DrinkPresetsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DrinkPresetEntity>>,
          List<DrinkPresetEntity>,
          Stream<List<DrinkPresetEntity>>
        >
    with
        $FutureModifier<List<DrinkPresetEntity>>,
        $StreamProvider<List<DrinkPresetEntity>> {
  /// Watch drink presets as a reactive stream.
  DrinkPresetsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'drinkPresetsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$drinkPresetsHash();

  @$internal
  @override
  $StreamProviderElement<List<DrinkPresetEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<DrinkPresetEntity>> create(Ref ref) {
    return drinkPresets(ref);
  }
}

String _$drinkPresetsHash() => r'd662ffa8b2558fe41a71fdd2c5a6dae4719bf01e';
