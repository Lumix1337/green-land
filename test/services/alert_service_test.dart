import 'package:flutter_test/flutter_test.dart';
import 'package:green_land/models/alert_model.dart';
import 'package:green_land/models/telemetry_model.dart';
import 'package:green_land/models/settings_model.dart';
import 'package:green_land/services/alert_service.dart';

void main() {
  group('AlertService Tests (Module M5 In-App Banners & Threshold Triggers)', () {
    late AlertService alertService;
    late SettingsModel settings;

    setUp(() {
      alertService = AlertService();
      settings = SettingsModel.initial();
    });

    tearDown(() {
      alertService.dispose();
    });

    test('Trigger Overheat alert when temperature exceeds 30°C (Scenario 2)', () {
      final hotTelemetry = TelemetryModel(
        airTemp: 33.5,
        airHumidity: 50.0,
        soilMoisture: 45.0,
        lightLevel: 15000.0,
        timestamp: DateTime.now(),
      );

      alertService.evaluateTelemetry(hotTelemetry, settings);

      expect(alertService.hasActiveAlert, isTrue);
      expect(alertService.primaryAlert?.type, equals(AlertType.overheat));
      expect(alertService.primaryAlert?.severity, equals(AlertSeverity.danger));
      expect(alertService.primaryAlert?.actionKey, equals('ventilation'));
    });

    test('Auto-resolves Overheat alert when temperature returns below threshold', () {
      final hotTelemetry = TelemetryModel(
        airTemp: 33.5,
        airHumidity: 50.0,
        soilMoisture: 45.0,
        lightLevel: 15000.0,
        timestamp: DateTime.now(),
      );
      alertService.evaluateTelemetry(hotTelemetry, settings);
      expect(alertService.hasActiveAlert, isTrue);

      final normalTelemetry = TelemetryModel(
        airTemp: 23.0,
        airHumidity: 55.0,
        soilMoisture: 45.0,
        lightLevel: 15000.0,
        timestamp: DateTime.now(),
      );
      alertService.evaluateTelemetry(normalTelemetry, settings);

      expect(alertService.hasActiveAlert, isFalse);
    });

    test('Trigger Drought alert when soil moisture < 30% (Scenario 3)', () {
      final dryTelemetry = TelemetryModel(
        airTemp: 24.0,
        airHumidity: 50.0,
        soilMoisture: 22.0,
        lightLevel: 12000.0,
        timestamp: DateTime.now(),
      );

      alertService.evaluateTelemetry(dryTelemetry, settings);

      expect(alertService.hasActiveAlert, isTrue);
      expect(alertService.primaryAlert?.type, equals(AlertType.drought));
      expect(alertService.primaryAlert?.actionKey, equals('irrigation'));
    });

    test('setOfflineAlert adds and clears offline warning banner (M8)', () {
      alertService.setOfflineAlert(true);
      expect(alertService.hasActiveAlert, isTrue);
      expect(alertService.primaryAlert?.type, equals(AlertType.offline));

      alertService.setOfflineAlert(false);
      expect(alertService.hasActiveAlert, isFalse);
    });
  });
}
