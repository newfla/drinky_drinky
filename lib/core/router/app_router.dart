import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n_extensions.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/history_screen.dart';
import '../../presentation/screens/permission_screen.dart';
import '../../presentation/screens/hydration_calculator_screen.dart';
import '../../presentation/screens/settings_screen.dart';

part 'app_router.g.dart';

/// Application router as a keepAlive Riverpod provider so it participates in
/// the provider container lifecycle (disposal via [ref.onDispose]) and can be
/// overridden in tests.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final router = GoRouter(
    initialLocation: '/',
    // First-launch redirect guard (D-01, NOTF-02, Pitfall 6).
    // Checks SharedPreferences once per navigation event; lightweight because
    // SharedPreferences caches results after the first disk read.
    redirect: (BuildContext context, GoRouterState state) async {
      // Prevent redirect loop: if already on /permission or /calculator, do not redirect again.
      if (state.matchedLocation == '/permission') return null;
      if (state.matchedLocation == '/calculator') return null;

      final prefs = await SharedPreferences.getInstance();
      final permissionShown = prefs.getBool('drinky_permissionScreenShown') ?? false;
      if (!permissionShown) return '/permission';

      final calculatorShown = prefs.getBool('drinky_calculatorShown') ?? false;
      if (!calculatorShown) return '/calculator';

      return null;
    },
    routes: [
      // /permission is a TOP-LEVEL route (outside StatefulShellRoute) so it
      // renders without the bottom NavigationBar (onboarding, shown once).
      GoRoute(
        path: '/permission',
        builder: (context, state) => const PermissionScreen(),
      ),

      // /calculator is a TOP-LEVEL route so it renders without the bottom
      // NavigationBar. isOnboarding=true when navigated by redirect guard;
      // isOnboarding=false when pushed from Settings.
      GoRoute(
        path: '/calculator',
        builder: (context, state) => HydrationCalculatorScreen(
          isOnboarding: state.extra as bool? ?? true,
        ),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: navigationShell.goBranch,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.water_drop_outlined),
                  selectedIcon: const Icon(Icons.water_drop),
                  label: context.l10n.tabHome,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.calendar_month_outlined),
                  selectedIcon: const Icon(Icons.calendar_month),
                  label: context.l10n.tabHistory,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.settings_outlined),
                  selectedIcon: const Icon(Icons.settings),
                  label: context.l10n.tabSettings,
                ),
              ],
            ),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}
