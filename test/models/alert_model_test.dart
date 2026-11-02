import 'package:flutter_test/flutter_test.dart';
import 'package:green_land/models/alert_model.dart';

void main() {
  group('AlertModel Tests (Module M5)', () {
    test('Factory .overheat() creates high-severity alert with ventilation action', () {
      final alert = AlertModel.overheat(currentTemp: 34.2, threshold: 28.0);
      expect(alert.type, equals(AlertType.overheat));
      expect(alert.severity, equals(AlertSeverity.danger));
      expect(alert.actionKey, equals('ventilation'));
      expect(alert.message, contains('34.2°C'));
    });

    test('Factory .drought() creates alert with irrigation action', () {
      final alert = AlertModel.drought(currentMoisture: 22.0, threshold: 30.0);
      expect(alert.type, equals(AlertType.drought));
      expect(alert.actionKey, equals('irrigation'));
      expect(alert.message, contains('22.0%'));
    });

    test('Factory .offline() creates alert with reconnect action', () {
      final alert = AlertModel.offline();
      expect(alert.type, equals(AlertType.offline));
      expect(alert.severity, equals(AlertSeverity.warning));
      expect(alert.actionKey, equals('reconnect'));
    });

    test('JSON serialization roundtrip works accurately', () {
      final alert = AlertModel.overheat(currentTemp: 35.0, threshold: 28.0);
      final json = alert.toJson();
      final parsed = AlertModel.fromJson(json);

      expect(parsed.type, equals(alert.type));
      expect(parsed.severity, equals(alert.severity));
      expect(parsed.actionKey, equals(alert.actionKey));
    });

    test('copyWith updates properties accurately', () {
      final alert = AlertModel.offline();
      final updated = alert.copyWith(isDismissed: true);
      expect(updated.isDismissed, isTrue);
      expect(updated.title, equals(alert.title));
    });
  });
}
