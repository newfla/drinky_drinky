// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Application router as a keepAlive Riverpod provider so it participates in
/// the provider container lifecycle (disposal via [ref.onDispose]) and can be
/// overridden in tests.

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

/// Application router as a keepAlive Riverpod provider so it participates in
/// the provider container lifecycle (disposal via [ref.onDispose]) and can be
/// overridden in tests.

final class AppRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// Application router as a keepAlive Riverpod provider so it participates in
  /// the provider container lifecycle (disposal via [ref.onDispose]) and can be
  /// overridden in tests.
  AppRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appRouterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appRouterHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return appRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$appRouterHash() => r'556a84fa5b14162710551e17e3e5b692849f2b2c';
