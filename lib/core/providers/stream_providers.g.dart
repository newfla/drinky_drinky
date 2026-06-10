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

/// Watch daily totals for a specific month as a reactive stream.
///
/// Family provider: each (year, month) combination is cached separately by
/// Riverpod. Navigating back to a previously visited month does not re-query
/// (D-07). Returns a `Map<dateKey, totalMl>` where absent keys mean no data
/// for that day (D-01).

@ProviderFor(calendarMonth)
final calendarMonthProvider = CalendarMonthFamily._();

/// Watch daily totals for a specific month as a reactive stream.
///
/// Family provider: each (year, month) combination is cached separately by
/// Riverpod. Navigating back to a previously visited month does not re-query
/// (D-07). Returns a `Map<dateKey, totalMl>` where absent keys mean no data
/// for that day (D-01).

final class CalendarMonthProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, int>>,
          Map<String, int>,
          Stream<Map<String, int>>
        >
    with $FutureModifier<Map<String, int>>, $StreamProvider<Map<String, int>> {
  /// Watch daily totals for a specific month as a reactive stream.
  ///
  /// Family provider: each (year, month) combination is cached separately by
  /// Riverpod. Navigating back to a previously visited month does not re-query
  /// (D-07). Returns a `Map<dateKey, totalMl>` where absent keys mean no data
  /// for that day (D-01).
  CalendarMonthProvider._({
    required CalendarMonthFamily super.from,
    required (int, int) super.argument,
  }) : super(
         retry: null,
         name: r'calendarMonthProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$calendarMonthHash();

  @override
  String toString() {
    return r'calendarMonthProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<Map<String, int>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, int>> create(Ref ref) {
    final argument = this.argument as (int, int);
    return calendarMonth(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is CalendarMonthProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$calendarMonthHash() => r'c6e7445d9773a6a3f6fc2b67242dd305e054c134';

/// Watch daily totals for a specific month as a reactive stream.
///
/// Family provider: each (year, month) combination is cached separately by
/// Riverpod. Navigating back to a previously visited month does not re-query
/// (D-07). Returns a `Map<dateKey, totalMl>` where absent keys mean no data
/// for that day (D-01).

final class CalendarMonthFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Map<String, int>>, (int, int)> {
  CalendarMonthFamily._()
    : super(
        retry: null,
        name: r'calendarMonthProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Watch daily totals for a specific month as a reactive stream.
  ///
  /// Family provider: each (year, month) combination is cached separately by
  /// Riverpod. Navigating back to a previously visited month does not re-query
  /// (D-07). Returns a `Map<dateKey, totalMl>` where absent keys mean no data
  /// for that day (D-01).

  CalendarMonthProvider call(int year, int month) =>
      CalendarMonthProvider._(argument: (year, month), from: this);

  @override
  String toString() => r'calendarMonthProvider';
}

/// Watch the current streak of consecutive days where the daily goal was met.
///
/// Counts backwards from yesterday (today is incomplete, D-08). Queries the
/// full history from 2020-01-01 as a safe lower bound. Returns 0 when no
/// target history rows exist. Evaluates each historical day against that
/// day's effective target from target_history, not a single global target
/// (D-11).

@ProviderFor(streak)
final streakProvider = StreakProvider._();

/// Watch the current streak of consecutive days where the daily goal was met.
///
/// Counts backwards from yesterday (today is incomplete, D-08). Queries the
/// full history from 2020-01-01 as a safe lower bound. Returns 0 when no
/// target history rows exist. Evaluates each historical day against that
/// day's effective target from target_history, not a single global target
/// (D-11).

final class StreakProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// Watch the current streak of consecutive days where the daily goal was met.
  ///
  /// Counts backwards from yesterday (today is incomplete, D-08). Queries the
  /// full history from 2020-01-01 as a safe lower bound. Returns 0 when no
  /// target history rows exist. Evaluates each historical day against that
  /// day's effective target from target_history, not a single global target
  /// (D-11).
  StreakProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'streakProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$streakHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return streak(ref);
  }
}

String _$streakHash() => r'a93d9c00892435ef62d1695ff95c71b68a2d1235';

/// Persist the focused month in the calendar across tab switches.
///
/// keepAlive: true so the state survives when HistoryScreen is not visible
/// (D-09). Initialized to the current month. The widget calls
/// [ref.read(focusedMonthProvider.notifier).set(month)] on page change.

@ProviderFor(FocusedMonth)
final focusedMonthProvider = FocusedMonthProvider._();

/// Persist the focused month in the calendar across tab switches.
///
/// keepAlive: true so the state survives when HistoryScreen is not visible
/// (D-09). Initialized to the current month. The widget calls
/// [ref.read(focusedMonthProvider.notifier).set(month)] on page change.
final class FocusedMonthProvider
    extends $NotifierProvider<FocusedMonth, DateTime> {
  /// Persist the focused month in the calendar across tab switches.
  ///
  /// keepAlive: true so the state survives when HistoryScreen is not visible
  /// (D-09). Initialized to the current month. The widget calls
  /// [ref.read(focusedMonthProvider.notifier).set(month)] on page change.
  FocusedMonthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'focusedMonthProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$focusedMonthHash();

  @$internal
  @override
  FocusedMonth create() => FocusedMonth();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$focusedMonthHash() => r'a13edcbf60c2e7a6ff991fec7f1d20ed9f9e3281';

/// Persist the focused month in the calendar across tab switches.
///
/// keepAlive: true so the state survives when HistoryScreen is not visible
/// (D-09). Initialized to the current month. The widget calls
/// [ref.read(focusedMonthProvider.notifier).set(month)] on page change.

abstract class _$FocusedMonth extends $Notifier<DateTime> {
  DateTime build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DateTime, DateTime>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime, DateTime>,
              DateTime,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Provides today's date key (YYYY-MM-DD) as a keepAlive Notifier that
/// automatically updates state at midnight without polling (D-01, D-02,
/// BUG-02 fix). Uses a single Timer that fires after the remaining seconds
/// of the current day expire, then reschedules itself for the next midnight.

@ProviderFor(TodayDateKey)
final todayDateKeyProvider = TodayDateKeyProvider._();

/// Provides today's date key (YYYY-MM-DD) as a keepAlive Notifier that
/// automatically updates state at midnight without polling (D-01, D-02,
/// BUG-02 fix). Uses a single Timer that fires after the remaining seconds
/// of the current day expire, then reschedules itself for the next midnight.
final class TodayDateKeyProvider
    extends $NotifierProvider<TodayDateKey, String> {
  /// Provides today's date key (YYYY-MM-DD) as a keepAlive Notifier that
  /// automatically updates state at midnight without polling (D-01, D-02,
  /// BUG-02 fix). Uses a single Timer that fires after the remaining seconds
  /// of the current day expire, then reschedules itself for the next midnight.
  TodayDateKeyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayDateKeyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayDateKeyHash();

  @$internal
  @override
  TodayDateKey create() => TodayDateKey();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$todayDateKeyHash() => r'93852a8c2eaf7fe46432d8fcfae24e47b0ebd405';

/// Provides today's date key (YYYY-MM-DD) as a keepAlive Notifier that
/// automatically updates state at midnight without polling (D-01, D-02,
/// BUG-02 fix). Uses a single Timer that fires after the remaining seconds
/// of the current day expire, then reschedules itself for the next midnight.

abstract class _$TodayDateKey extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Reactive stream of the effective target (in ml) for a given [dateKey].
///
/// Returns the targetMl from the most recent target_history row where
/// effectiveDate <= dateKey. Falls back to 2000 ml if no row exists
/// (defensive fallback -- should never be null after seed).
///
/// keepAlive: true so the same stream is reused across widgets on the
/// same day (D-08).

@ProviderFor(effectiveTargetForDate)
final effectiveTargetForDateProvider = EffectiveTargetForDateFamily._();

/// Reactive stream of the effective target (in ml) for a given [dateKey].
///
/// Returns the targetMl from the most recent target_history row where
/// effectiveDate <= dateKey. Falls back to 2000 ml if no row exists
/// (defensive fallback -- should never be null after seed).
///
/// keepAlive: true so the same stream is reused across widgets on the
/// same day (D-08).

final class EffectiveTargetForDateProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// Reactive stream of the effective target (in ml) for a given [dateKey].
  ///
  /// Returns the targetMl from the most recent target_history row where
  /// effectiveDate <= dateKey. Falls back to 2000 ml if no row exists
  /// (defensive fallback -- should never be null after seed).
  ///
  /// keepAlive: true so the same stream is reused across widgets on the
  /// same day (D-08).
  EffectiveTargetForDateProvider._({
    required EffectiveTargetForDateFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'effectiveTargetForDateProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$effectiveTargetForDateHash();

  @override
  String toString() {
    return r'effectiveTargetForDateProvider'
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
    return effectiveTargetForDate(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EffectiveTargetForDateProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$effectiveTargetForDateHash() =>
    r'6f7d7872562db0ae9121e51672f4956e17cc09a2';

/// Reactive stream of the effective target (in ml) for a given [dateKey].
///
/// Returns the targetMl from the most recent target_history row where
/// effectiveDate <= dateKey. Falls back to 2000 ml if no row exists
/// (defensive fallback -- should never be null after seed).
///
/// keepAlive: true so the same stream is reused across widgets on the
/// same day (D-08).

final class EffectiveTargetForDateFamily extends $Family
    with $FunctionalFamilyOverride<Stream<int>, String> {
  EffectiveTargetForDateFamily._()
    : super(
        retry: null,
        name: r'effectiveTargetForDateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Reactive stream of the effective target (in ml) for a given [dateKey].
  ///
  /// Returns the targetMl from the most recent target_history row where
  /// effectiveDate <= dateKey. Falls back to 2000 ml if no row exists
  /// (defensive fallback -- should never be null after seed).
  ///
  /// keepAlive: true so the same stream is reused across widgets on the
  /// same day (D-08).

  EffectiveTargetForDateProvider call(String dateKey) =>
      EffectiveTargetForDateProvider._(argument: dateKey, from: this);

  @override
  String toString() => r'effectiveTargetForDateProvider';
}

/// Reactive stream of all target_history rows ordered by effectiveDate ASC,
/// mapped to the domain [TargetHistoryEntry] type.
///
/// Used by calendar and streak providers for batch lookup of per-day targets
/// without making one DB query per day (D-10, D-11).
///
/// keepAlive: true so the stream is shared and not recreated on every rebuild.

@ProviderFor(allTargetHistory)
final allTargetHistoryProvider = AllTargetHistoryProvider._();

/// Reactive stream of all target_history rows ordered by effectiveDate ASC,
/// mapped to the domain [TargetHistoryEntry] type.
///
/// Used by calendar and streak providers for batch lookup of per-day targets
/// without making one DB query per day (D-10, D-11).
///
/// keepAlive: true so the stream is shared and not recreated on every rebuild.

final class AllTargetHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TargetHistoryEntry>>,
          List<TargetHistoryEntry>,
          Stream<List<TargetHistoryEntry>>
        >
    with
        $FutureModifier<List<TargetHistoryEntry>>,
        $StreamProvider<List<TargetHistoryEntry>> {
  /// Reactive stream of all target_history rows ordered by effectiveDate ASC,
  /// mapped to the domain [TargetHistoryEntry] type.
  ///
  /// Used by calendar and streak providers for batch lookup of per-day targets
  /// without making one DB query per day (D-10, D-11).
  ///
  /// keepAlive: true so the stream is shared and not recreated on every rebuild.
  AllTargetHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allTargetHistoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allTargetHistoryHash();

  @$internal
  @override
  $StreamProviderElement<List<TargetHistoryEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<TargetHistoryEntry>> create(Ref ref) {
    return allTargetHistory(ref);
  }
}

String _$allTargetHistoryHash() => r'f4f644a84a37edc093adf48902ba6d5c85dd32b7';
