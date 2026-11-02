import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/alert_model.dart';
import '../models/telemetry_model.dart';
import '../models/settings_model.dart';

class AlertService {
  final List<AlertModel> _activeAlerts = [];
  final StreamController<List<AlertModel>> _alertsStreamController = StreamController<List<AlertModel>>.broadcast();

  List<AlertModel> get activeAlerts => List.unmodifiable(_activeAlerts);
  Stream<List<AlertModel>> get onAlertsChanged => _alertsStreamController.stream;

  bool get hasActiveAlert => _activeAlerts.isNotEmpty;
  AlertModel? get primaryAlert => _activeAlerts.isNotEmpty ? _activeAlerts.first : null;

  /// Check telemetry against configurable safety thresholds (M5)
  void evaluateTelemetry(TelemetryModel telemetry, SettingsModel settings) {
    bool stateChanged = false;

    // 1. Overheating Check (Scenario 2: temp > maxTemp or > 30°C)
    final isOverheated = telemetry.airTemp > settings.maxAirTemp || telemetry.airTemp > 30.0;
    final existingOverheatIndex = _activeAlerts.indexWhere((a) => a.type == AlertType.overheat);

    if (isOverheated && existingOverheatIndex == -1) {
      _activeAlerts.insert(
        0,
        AlertModel.overheat(
          currentTemp: telemetry.airTemp,
          threshold: settings.maxAirTemp,
          actionLabel: 'Включить вентиляцию',
        ),
      );
      stateChanged = true;
      debugPrint('🚨 [AlertService] OVERHEAT ALERT TRIGGERED: ${telemetry.airTemp}°C');
    } else if (!isOverheated && existingOverheatIndex != -1) {
      // Auto-resolve when temperature returns to normal
      _activeAlerts.removeAt(existingOverheatIndex);
      stateChanged = true;
      debugPrint('✅ [AlertService] Overheat alert auto-resolved');
    }

    // 2. Drought / Soil Moisture Check (Scenario 3: soil < 30%)
    final isDrought = telemetry.soilMoisture < settings.minSoilMoisture || telemetry.soilMoisture < 30.0;
    final existingDroughtIndex = _activeAlerts.indexWhere(
      (a) => a.type == AlertType.drought || a.type == AlertType.criticalDrought,
    );

    if (isDrought && existingDroughtIndex == -1) {
      _activeAlerts.add(
        AlertModel.drought(
          currentMoisture: telemetry.soilMoisture,
          threshold: settings.minSoilMoisture,
          actionLabel: 'Включить автополив',
        ),
      );
      stateChanged = true;
      debugPrint('🚨 [AlertService] DROUGHT ALERT TRIGGERED: ${telemetry.soilMoisture}%');
    } else if (!isDrought && existingDroughtIndex != -1) {
      // Auto-resolve when irrigation replenishes moisture
      _activeAlerts.removeAt(existingDroughtIndex);
      stateChanged = true;
      debugPrint('✅ [AlertService] Drought alert auto-resolved');
    }

    if (stateChanged) {
      _alertsStreamController.add(List.unmodifiable(_activeAlerts));
    }
  }

  /// Trigger explicit overheat alert for jury demonstration (Scenario 2)
  void triggerDemoOverheat() {
    _activeAlerts.removeWhere((a) => a.type == AlertType.overheat);
    _activeAlerts.insert(
      0,
      AlertModel.overheat(
        currentTemp: 34.5,
        threshold: 28.0,
        actionLabel: 'Включить вентиляцию',
      ),
    );
    _alertsStreamController.add(List.unmodifiable(_activeAlerts));
  }

  /// Trigger offline alert (M8 stress test)
  void setOfflineAlert(bool isOffline) {
    final existingIndex = _activeAlerts.indexWhere((a) => a.type == AlertType.offline);
    if (isOffline && existingIndex == -1) {
      _activeAlerts.insert(0, AlertModel.offline());
      _alertsStreamController.add(List.unmodifiable(_activeAlerts));
    } else if (!isOffline && existingIndex != -1) {
      _activeAlerts.removeAt(existingIndex);
      _alertsStreamController.add(List.unmodifiable(_activeAlerts));
    }
  }

  /// Dismiss an alert by ID
  void dismissAlert(String alertId) {
    _activeAlerts.removeWhere((a) => a.id == alertId);
    _alertsStreamController.add(List.unmodifiable(_activeAlerts));
  }

  /// Clear all active alerts
  void clearAllAlerts() {
    _activeAlerts.clear();
    _alertsStreamController.add(List.unmodifiable(_activeAlerts));
  }

  void dispose() {
    _alertsStreamController.close();
  }
}
