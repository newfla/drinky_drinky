import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Timezone init — required by flutter_local_notifications for zonedSchedule().
  // initializeTimeZones() must be called before any tz.getLocation() call.
  tz.initializeTimeZones();
  final tzInfo = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

  // Initialize notification service (registers Android channel, iOS hook).
  await NotificationService.instance.initialize();

  runApp(
    const ProviderScope(
      child: DrinkyDrinkyApp(),
    ),
  );
}

class DrinkyDrinkyApp extends ConsumerWidget {
  const DrinkyDrinkyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp.router(
          title: 'Drinky Drinky',
          theme: ThemeData(
            colorScheme: lightDynamic ??
                ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: darkDynamic ??
                ColorScheme.fromSeed(
                  seedColor: Colors.blue,
                  brightness: Brightness.dark,
                ),
            useMaterial3: true,
          ),
          themeMode: ThemeMode.system,
          routerConfig: router,
        );
      },
    );
  }
}
