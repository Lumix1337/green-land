import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_land/widgets/metric_card.dart';

void main() {
  testWidgets('MetricCard displays title, value, unit, and status badge',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MetricCard(
            title: 'Температура воздуха',
            value: '24.5',
            unit: '°C',
            icon: Icons.thermostat_rounded,
            status: MetricStatus.normal,
            statusText: 'Норма',
            progress: 0.5,
          ),
        ),
      ),
    );

    expect(find.text('Температура воздуха'), findsOneWidget);
    expect(find.text('24.5'), findsOneWidget);
    expect(find.text('°C'), findsOneWidget);
    expect(find.text('Норма'), findsOneWidget);
  });
}
