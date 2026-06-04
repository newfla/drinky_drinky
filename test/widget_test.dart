import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drinky_drinky/main.dart';
import 'package:drinky_drinky/core/providers/database_provider.dart';
import 'package:drinky_drinky/data/database/app_database.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(
            AppDatabase(NativeDatabase.memory()),
          ),
        ],
        child: const DrinkyDrinkyApp(),
      ),
    );

    expect(find.text('Drinky Drinky'), findsOneWidget);

    // Dispose the widget tree to cancel HomeScreen's Timer.periodic.
    // Pump with a small duration to flush the zero-duration cleanup timers
    // that Drift's StreamQueryStore.markAsClosed() creates during provider disposal.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
