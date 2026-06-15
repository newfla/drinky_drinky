import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'l10n/generated/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // L10N-03: Initialize date formatting for all locales.
  // table_calendar uses intl internally for month/day names.
  await initializeDateFormatting();

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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          localeListResolutionCallback: (locales, supportedLocales) {
            if (locales == null || locales.isEmpty) return const Locale('en');
            final primary = locales.first;
            for (final supported in supportedLocales) {
              if (supported.languageCode == primary.languageCode) return supported;
            }
            return const Locale('en');
          },
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
