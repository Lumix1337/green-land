import 'package:flutter_test/flutter_test.dart';
import 'package:green_land/controllers/auth_controller.dart';
import 'package:green_land/controllers/telemetry_controller.dart';
import 'package:green_land/controllers/actuator_controller.dart';
import 'package:green_land/controllers/alert_controller.dart';
import 'package:green_land/controllers/analytics_controller.dart';
import 'package:green_land/models/telemetry_model.dart';
import 'package:green_land/models/settings_model.dart';

void main() {
  group('Controllers Layer Tests (State Management & Reactive Binding)', () {
    test('AuthController handles demo login and logout reactively', () async {
      final auth = AuthController();
      expect(auth.isAuthenticated, isTrue);

      await auth.logout();
      expect(auth.isAuthenticated, isFalse);

      final success = await auth.demoLogin();
      expect(success, isTrue);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.userEmail, equals('erlan.agrotech@gmail.com'));
      auth.dispose();
    });

    test('TelemetryController provides live metrics and human-readable timestamp', () {
      final telemCtrl = TelemetryController();
      expect(telemCtrl.telemetry.airTemp, greaterThan(0));
      expect(telemCtrl.isOffline, isFalse);
      expect(telemCtrl.getLastUpdatedText().isNotEmpty, isTrue);

      telemCtrl.toggleOfflineStressTest(true);
      expect(telemCtrl.isOffline, isTrue);
      telemCtrl.dispose();
    });

    test('ActuatorController controls devices with measured latency < 5s', () async {
      final actCtrl = ActuatorController();
      expect(actCtrl.actuators.irrigation, isFalse);

      final ok = await actCtrl.toggleActuator('irrigation', true);
      expect(ok, isTrue);
      expect(actCtrl.actuators.irrigation, isTrue);
      expect(actCtrl.latencySeconds, lessThan(5.0));

      final allOffOk = await actCtrl.turnOffAll();
      expect(allOffOk, isTrue);
      expect(actCtrl.actuators.irrigation, isFalse);
      actCtrl.dispose();
    });

    test('AlertController triggers overheat banner and evaluates thresholds', () {
      final alertCtrl = AlertController();
      alertCtrl.triggerDemoOverheat();
      expect(alertCtrl.hasActiveAlert, isTrue);
      expect(alertCtrl.primaryAlert?.title, contains('перегрев'));

      alertCtrl.clearAll();
      expect(alertCtrl.hasActiveAlert, isFalse);

      final hotTelemetry = TelemetryModel(
        airTemp: 34.0,
        airHumidity: 50.0,
        soilMoisture: 40.0,
        lightLevel: 14000.0,
        timestamp: DateTime.now(),
      );
      alertCtrl.evaluateTelemetry(hotTelemetry, SettingsModel.initial());
      expect(alertCtrl.hasActiveAlert, isTrue);
      alertCtrl.dispose();
    });

    test('AnalyticsController loads 7-day data and computes spots for fl_chart', () async {
      final analyticsCtrl = AnalyticsController();
      await analyticsCtrl.loadHistoricalData(7);

      expect(analyticsCtrl.selectedPeriodDays, equals(7));
      expect(analyticsCtrl.historyPoints.length, equals(7));
      expect(analyticsCtrl.soilMoistureSpots.length, equals(7));
      expect(analyticsCtrl.airTempSpots.length, equals(7));
      expect(analyticsCtrl.xLabels.length, equals(7));

      // Scenario 4: water deficit point has soil moisture < 30%
      final deficitPoint = analyticsCtrl.waterDeficitPoint;
      expect(deficitPoint, isNotNull);
      expect(deficitPoint!.soilMoisture, lessThan(30.0));
      analyticsCtrl.dispose();
    });
  });
}
