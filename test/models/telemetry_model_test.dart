import 'package:flutter_test/flutter_test.dart';
import 'package:green_land/models/telemetry_model.dart';

void main() {
  group('TelemetryModel Tests', () {
    test('Correctly identifies normal conditions', () {
      final telemetry = TelemetryModel(
        airTemp: 24.0,
        airHumidity: 60.0,
        soilMoisture: 45.0,
        lightLevel: 10000.0,
        timestamp: DateTime.now(),
      );

      expect(telemetry.isOptimal, isTrue);
      expect(telemetry.isSoilMoistureLow, isFalse);
      expect(telemetry.isAirTempHigh, isFalse);
    });

    test('Correctly identifies drought when soil moisture < 30%', () {
      final dryTelemetry = TelemetryModel(
        airTemp: 24.0,
        airHumidity: 60.0,
        soilMoisture: 22.5,
        lightLevel: 10000.0,
        timestamp: DateTime.now(),
      );

      expect(dryTelemetry.isSoilMoistureLow, isTrue);
      expect(dryTelemetry.isOptimal, isFalse);
    });

    test('JSON serialization roundtrip works accurately', () {
      final initial = TelemetryModel.initial();
      final json = initial.toJson();
      final parsed = TelemetryModel.fromJson(json);

      expect(parsed.airTemp, equals(initial.airTemp));
      expect(parsed.soilMoisture, equals(initial.soilMoisture));
    });
  });
}
