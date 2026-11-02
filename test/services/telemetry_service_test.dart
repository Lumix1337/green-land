import 'package:flutter_test/flutter_test.dart';
import 'package:green_land/models/telemetry_model.dart';
import 'package:green_land/services/telemetry_service.dart';

void main() {
  group('TelemetryService Tests (Module M2 Realtime Stream & Staleness)', () {
    late TelemetryService telemetryService;

    setUp(() {
      telemetryService = TelemetryService();
    });

    tearDown(() {
      telemetryService.dispose();
    });

    test('Initial telemetry contains valid initial sensor readings', () {
      expect(telemetryService.latestTelemetry.airTemp, greaterThan(0));
      expect(telemetryService.latestTelemetry.airHumidity, greaterThan(0));
      expect(telemetryService.latestTelemetry.soilMoisture, greaterThan(0));
      expect(telemetryService.isOffline, isFalse);
    });

    test('Injecting telemetry triggers stream notification', () async {
      final newReading = TelemetryModel(
        airTemp: 27.5,
        airHumidity: 58.0,
        soilMoisture: 42.0,
        lightLevel: 14000.0,
        timestamp: DateTime.now(),
      );

      expectLater(
        telemetryService.onTelemetryUpdated,
        emits(predicate<TelemetryModel>((t) => t.airTemp == 27.5 && t.soilMoisture == 42.0)),
      );

      telemetryService.setTelemetry(newReading);
      expect(telemetryService.latestTelemetry.airTemp, equals(27.5));
    });

    test('fetchHistory for 7 days returns 7 points with water deficit point (M6)', () async {
      final points = await telemetryService.fetchHistory(days: 7);
      expect(points.length, equals(7));

      final minSoilPoint = points.reduce((a, b) => a.soilMoisture < b.soilMoisture ? a : b);
      expect(minSoilPoint.soilMoisture, lessThan(30.0)); // Day 3 deficit point in mock
    });

    test('fetchHistory for 24 hours returns hourly series', () async {
      final points = await telemetryService.fetchHistory(days: 1);
      expect(points.isNotEmpty, isTrue);
    });

    test('setOfflineStressTest triggers offline state and staleness stream (M8)', () async {
      expectLater(telemetryService.onStalenessChanged, emits(true));
      telemetryService.setOfflineStressTest(true);
      expect(telemetryService.isOffline, isTrue);
    });
  });
}
