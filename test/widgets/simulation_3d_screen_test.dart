import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_land/services/greenhouse_provider.dart';
import 'package:green_land/views/simulation_3d_screen.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Simulation3DScreen renders telemetry, preview, and actuator toggles',
      (tester) async {
    final provider = GreenhouseProvider();
    try {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: Simulation3DScreen(),
          ),
        ),
      );

      expect(find.text('3D Digital Twin'), findsOneWidget);
      expect(find.text('3D Scene Actuators'), findsOneWidget);
      expect(find.text('Overheat 32.8°C'), findsOneWidget);

      await tester.tap(find.text('Overheat 32.8°C'));
      await tester.pumpAndSettle();
      expect(provider.telemetry.isOverheated(), isTrue);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      provider.dispose();
      provider.telemetryService.dispose();
    }
  });
}
