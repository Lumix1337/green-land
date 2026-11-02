import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/alert_model.dart';
import '../models/telemetry_model.dart';
import '../models/settings_model.dart';
import '../services/alert_service.dart';

class AlertController extends ChangeNotifier {
  final AlertService _alertService;
  StreamSubscription<List<AlertModel>>? _alertsSub;

  List<AlertModel> get activeAlerts => _alertService.activeAlerts;
  bool get hasActiveAlert => _alertService.hasActiveAlert;
  AlertModel? get primaryAlert => _alertService.primaryAlert;

  AlertController({AlertService? alertService})
      : _alertService = alertService ?? AlertService() {
    _alertsSub = _alertService.onAlertsChanged.listen((_) {
      notifyListeners();
    });
  }

  void evaluateTelemetry(TelemetryModel telemetry, SettingsModel settings) {
    _alertService.evaluateTelemetry(telemetry, settings);
  }

  void triggerDemoOverheat() {
    _alertService.triggerDemoOverheat();
  }

  void setOfflineAlert(bool isOffline) {
    _alertService.setOfflineAlert(isOffline);
  }

  void dismissAlert(String id) {
    _alertService.dismissAlert(id);
  }

  void clearAll() {
    _alertService.clearAllAlerts();
  }

  @override
  void dispose() {
    _alertsSub?.cancel();
    super.dispose();
  }
}
