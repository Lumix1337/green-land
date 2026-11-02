import 'package:flutter_test/flutter_test.dart';
import 'package:green_land/models/actuator_model.dart';
import 'package:green_land/services/actuator_service.dart';

void main() {
  group('ActuatorService Tests (Module M3 Remote Actuators & Latency < 5s)', () {
    late ActuatorService actuatorService;

    setUp(() {
      actuatorService = ActuatorService();
    });

    tearDown(() {
      actuatorService.dispose();
    });

    test('Initial actuator state has all devices turned off', () {
      expect(actuatorService.actuators.irrigation, isFalse);
      expect(actuatorService.actuators.ventilation, isFalse);
      expect(actuatorService.actuators.heater, isFalse);
      expect(actuatorService.actuators.lighting, isFalse);
      expect(actuatorService.actuators.isAnyActive, isFalse);
    });

    test('setActuatorState toggles irrigation and records latency < 5s', () async {
      final res = await actuatorService.setActuatorState(name: 'irrigation', value: true);

      expect(res.isSuccess, isTrue);
      expect(res.updatedActuators.irrigation, isTrue);
      expect(actuatorService.actuators.irrigation, isTrue);
      expect(res.latencySeconds, lessThan(5.0)); // Brief requirement: < 5s
    });

    test('setActuatorState emits updated model on onActuatorsUpdated stream', () async {
      expectLater(
        actuatorService.onActuatorsUpdated,
        emits(predicate<ActuatorModel>((a) => a.ventilation == true)),
      );

      await actuatorService.setActuatorState(name: 'ventilation', value: true);
    });

    test('Emergency turnOffAll sets all actuators to false atomically', () async {
      await actuatorService.setActuatorState(name: 'irrigation', value: true);
      await actuatorService.setActuatorState(name: 'heater', value: true);
      expect(actuatorService.actuators.activeCount, equals(2));

      final res = await actuatorService.turnOffAll();
      expect(res.isSuccess, isTrue);
      expect(actuatorService.actuators.irrigation, isFalse);
      expect(actuatorService.actuators.heater, isFalse);
      expect(actuatorService.actuators.isAnyActive, isFalse);
      expect(res.latencySeconds, lessThan(5.0));
    });
  });
}
