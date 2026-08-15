// Widget smoke test for the Mid Day Meal System app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:midday_meal_system/main.dart';

void main() {
  testWidgets('App smoke test - MaterialApp renders without crashing',
      (WidgetTester tester) async {
    // Use fakeAsync-compatible approach: pump the widget and immediately
    // ignore pending timers (SplashScreen has an auto-navigate Timer).
    await tester.pumpWidget(const MidDayMealApp());

    // Verify the MaterialApp and its initial route rendered some widgets.
    expect(find.byType(MaterialApp), findsOneWidget);

    // Pump a single frame so the splash screen builds its UI.
    await tester.pump(Duration.zero);
  }, timeout: const Timeout(Duration(seconds: 10)));
}
