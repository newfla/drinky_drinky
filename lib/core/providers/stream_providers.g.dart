// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stream_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Watch water entries for the given [dateKey] as a reactive stream.
///
/// Callers should pass [dateKey] computed from [DateTime.now()] at widget
/// build time (e.g. via [todayDateKey()]) so the stream re-subscribes with
/// the correct date on every rebuild and naturally refreshes after midnight.

@ProviderFor(waterEntriesForDate)
final waterEntriesForDateProvider = WaterEntriesForDateFamily._();

/// Watch water entries for the given [dateKey] as a reactive stream.
///
/// Callers should pass [dateKey] computed from [DateTime.now()] at widget
/// build time (e.g. via [todayDateKey()]) so the stream re-subscribes with
/// the correct date on every rebuild and naturally refreshes after midnight.

final class WaterEntriesForDateProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WaterEntryEntity>>,
          List<WaterEntryEntity>,
          Stream<List<WaterEntryEntity>>
        >
    with
        $FutureModifier<List<WaterEntryEntity>>,
        $StreamProvider<List<WaterEntryEntity>> {
  /// Watch water entries for the given [dateKey] as a reactive stream.
  ///
  /// Callers should pass [dateKey] computed from [DateTime.now()] at widget
  /// build time (e.g. via [todayDateKey()]) so the stream re-subscribes with
  /// the correct date on every rebuild and naturally refreshes after midnight.
  WaterEntriesForDateProvider._({
    required WaterEntriesForDateFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'waterEntriesForDateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$waterEntriesForDateHash();

  @override
  String toString() {
    return r'waterEntriesForDateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<WaterEntryEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<WaterEntryEntity>> create(Ref ref) {
    final argument = this.argument as String;
    return waterEntriesForDate(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WaterEntriesForDateProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$waterEntriesForDateHash() =>
    r'26248f3eaf09c0019e02f086506d979b3e75641f';

/// Watch water entries for the given [dateKey] as a reactive stream.
///
/// Callers should pass [dateKey] computed from [DateTime.now()] at widget
/// build time (e.g. via [todayDateKey()]) so the stream re-subscribes with
/// the correct date on every rebuild and naturally refreshes after midnight.

final class WaterEntriesForDateFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<WaterEntryEntity>>, String> {
  WaterEntriesForDateFamily._()
    : super(
        retry: null,
        name: r'waterEntriesForDateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Watch water entries for the given [dateKey] as a reactive stream.
  ///
  /// Callers should pass [dateKey] computed from [DateTime.now()] at widget
  /// build time (e.g. via [todayDateKey()]) so the stream re-subscribes with
  /// the correct date on every rebuild and naturally refreshes after midnight.

  WaterEntriesForDateProvider call(String dateKey) =>
      WaterEntriesForDateProvider._(argument: dateKey, from: this);

  @override
  String toString() => r'waterEntriesForDateProvider';
}

/// Watch total ml consumed for the given [dateKey] as a reactive stream.
///
/// Callers should pass [dateKey] computed from [DateTime.now()] at widget
/// build time (e.g. via [todayDateKey()]) so the stream re-subscribes with
/// the correct date on every rebuild and naturally refreshes after midnight.

@ProviderFor(totalMlForDate)
final totalMlForDateProvider = TotalMlForDateFamily._();

/// Watch total ml consumed for the given [dateKey] as a reactive stream.
///
/// Callers should pass [dateKey] computed from [DateTime.now()] at widget
/// build time (e.g. via [todayDateKey()]) so the stream re-subscribes with
/// the correct date on every rebuild and naturally refreshes after midnight.

final class TotalMlForDateProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// Watch total ml consumed for the given [dateKey] as a reactive stream.
  ///
  /// Callers should pass [dateKey] computed from [DateTime.now()] at widget
  /// build time (e.g. via [todayDateKey()]) so the stream re-subscribes with
  /// the correct date on every rebuild and naturally refreshes after midnight.
  TotalMlForDateProvider._({
    required TotalMlForDateFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'totalMlForDateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$totalMlForDateHash();

  @override
  String toString() {
    return r'totalMlForDateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    final argument = this.argument as String;
    return totalMlForDate(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TotalMlForDateProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$totalMlForDateHash() => r'46cf92c93dd6e8d396684c5d47de6b62ce61ffc7';

/// Watch total ml consumed for the given [dateKey] as a reactive stream.
///
/// Callers should pass [dateKey] computed from [DateTime.now()] at widget
/// build time (e.g. via [todayDateKey()]) so the stream re-subscribes with
/// the correct date on every rebuild and naturally refreshes after midnight.

final class TotalMlForDateFamily extends $Family
    with $FunctionalFamilyOverride<Stream<int>, String> {
  TotalMlForDateFamily._()
    : super(
        retry: null,
        name: r'totalMlForDateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Watch total ml consumed for the given [dateKey] as a reactive stream.
  ///
  /// Callers should pass [dateKey] computed from [DateTime.now()] at widget
  /// build time (e.g. via [todayDateKey()]) so the stream re-subscribes with
  /// the correct date on every rebuild and naturally refreshes after midnight.

  TotalMlForDateProvider call(String dateKey) =>
      TotalMlForDateProvider._(argument: dateKey, from: this);

  @override
  String toString() => r'totalMlForDateProvider';
}

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
