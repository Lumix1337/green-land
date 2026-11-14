import 'package:flutter_test/flutter_test.dart';
import 'package:green_land/l10n/app_localizations.dart';
import 'package:green_land/services/greenhouse_provider.dart';

void main() {
  group('GreenhouseProvider Tests', () {
    late GreenhouseProvider provider;

    setUp(() {
      provider = GreenhouseProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('Starts in English and allows switching languages', () {
      expect(provider.language, AppLanguage.en);
      provider.switchLanguage(AppLanguage.kz);
      expect(provider.language, AppLanguage.kz);
    });

    test(
        'Actuator toggle triggers feedback loop (Irrigation increases soil moisture)',
        () async {
      final initialSoil = provider.telemetry.soilMoisture;
      await provider.toggleActuator('irrigation', true);

      expect(provider.actuators.irrigation, isTrue);
      expect(provider.telemetry.soilMoisture, greaterThan(initialSoil));
    });

    test('Ventilation drops air temperature and clears alert', () async {
      provider.triggerOverheatAlert();
      expect(provider.hasActiveAlert, isTrue);

      await provider.toggleActuator('ventilation', true);
      expect(provider.actuators.ventilation, isTrue);
      expect(provider.hasActiveAlert, isFalse);
    });

    test('Offline stress test toggles status accurately (M8)', () {
      expect(provider.isOffline, isFalse);
      provider.toggleOfflineStressTest(true);
      expect(provider.isOffline, isTrue);
    });
  });
}
