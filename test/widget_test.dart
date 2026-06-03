import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drinky_drinky/main.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: DrinkyDrinkyApp()),
    );

    expect(find.text('Drinky Drinky'), findsOneWidget);
    expect(find.text('Home Screen'), findsOneWidget);
  });
}
