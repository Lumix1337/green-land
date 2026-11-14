import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_land/main.dart';
import 'package:green_land/services/greenhouse_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('English mobile demo opens controls from the overheating banner',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final provider = GreenhouseProvider();
    final errorBuilder = ErrorWidget.builder;

    try {
      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: provider,
        child: const GreenLandApp(),
      ));

      expect(find.text('Sign in'), findsOneWidget);
      await tester.tap(find.text('Try demo as Erlan'));
      await tester.pumpAndSettle();
      expect(find.text('Greenhouse 1 · Tomatoes'), findsOneWidget);

      await tester.tap(find.text('Simulate overheating'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open ventilation controls →'));
      await tester.pumpAndSettle();
      expect(find.text('Equipment controls'), findsOneWidget);

      await tester.tap(find.text('Analytics'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('7 days'));
      await tester.pumpAndSettle();
      expect(find.text('Low soil moisture'), findsOneWidget);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Monthly energy savings'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      provider.dispose();
      provider.telemetryService.dispose();
      ErrorWidget.builder = errorBuilder;
    }
  });
}
