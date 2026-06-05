import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/history_screen.dart';
import '../../presentation/screens/permission_screen.dart';
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
      // Prevent redirect loop: if already on /permission, do not redirect again.
      if (state.matchedLocation == '/permission') return null;

      final prefs = await SharedPreferences.getInstance();
      final shown = prefs.getBool('drinky_permissionScreenShown') ?? false;
      if (!shown) return '/permission';
      return null;
    },
    routes: [
      // /permission is a TOP-LEVEL route (outside StatefulShellRoute) so it
      // renders without the bottom NavigationBar (onboarding, shown once).
      GoRoute(
        path: '/permission',
        builder: (context, state) => const PermissionScreen(),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: navigationShell.goBranch,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.water_drop_outlined),
                  selectedIcon: Icon(Icons.water_drop),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month),
                  label: 'History',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Settings',
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
