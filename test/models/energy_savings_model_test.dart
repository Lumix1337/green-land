import 'package:flutter_test/flutter_test.dart';
import 'package:green_land/models/energy_savings_model.dart';

void main() {
  group('EnergySavingsModel Tests', () {
    test('initial() returns calibrated 48200 KZT monthly savings for 800 m2 greenhouse', () {
      final model = EnergySavingsModel.initial();
      expect(model.monthlySavedTenge, equals(48200.0));
      expect(model.dailyBaselineKwh, equals(156.0));
      expect(model.nightShiftRatio, equals(0.72));
    });

    test('toJson and fromJson preserve all KZT and kWh metrics', () {
      final original = EnergySavingsModel.initial();
      final json = original.toJson();
      final restored = EnergySavingsModel.fromJson(json);

      expect(restored.monthlySavedTenge, equals(original.monthlySavedTenge));
      expect(restored.dailySavedTenge, equals(original.dailySavedTenge));
      expect(restored.monthlySavedKwh, equals(original.monthlySavedKwh));
      expect(restored.savingsPercentage, equals(original.savingsPercentage));
    });
  });
}
