import 'package:flutter_test/flutter_test.dart';
import 'package:green_land/models/actuator_model.dart';
import 'package:green_land/models/settings_model.dart';
import 'package:green_land/services/energy_optimizer_service.dart';

void main() {
  group('EnergyOptimizerService Tests (Signature Feature KZT Savings)', () {
    late EnergyOptimizerService optimizer;

    setUp(() {
      optimizer = EnergyOptimizerService();
    });

    test('isNightTariffHour classifies 23:00-07:00 preferential window accurately', () {
      expect(optimizer.isNightTariffHour(23), isTrue);
      expect(optimizer.isNightTariffHour(2), isTrue);
      expect(optimizer.isNightTariffHour(6), isTrue);
      expect(optimizer.isNightTariffHour(7), isFalse);
      expect(optimizer.isNightTariffHour(15), isFalse);
    });

    test('calculateSavings computes 48200 KZT monthly savings for default Almaty tariffs', () {
      final settings = SettingsModel.initial();
      final report = optimizer.calculateSavings(
        settings: settings,
        areaSqMeters: 800.0,
        sunnyWeatherForecast: true,
        currentHour: 1,
      );

      expect(report.monthlySavedTenge, equals(48200.0));
      expect(report.dailySavedTenge, greaterThan(1500.0));
      expect(report.isNightTariffActive, isTrue);
    });

    test('computeInstantPowerKw sums active equipment ratings accurately', () {
      final actuators = ActuatorModel.initial().copyWith(
        heater: true,
        lighting: true,
      );
      expect(optimizer.computeInstantPowerKw(actuators), equals(32.0));
    });
  });
}
