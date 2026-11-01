import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/telemetry_model.dart';
import '../models/actuator_model.dart';
import '../models/settings_model.dart';

class GreenhouseProvider extends ChangeNotifier {
  AppLanguage _language = AppLanguage.ru;
  bool _isLoggedIn = true;
  bool _isOffline = false;
  String _userEmail = 'erlan.agrotech@gmail.com';

  TelemetryModel _telemetry = TelemetryModel.initial();
  ActuatorModel _actuators = ActuatorModel.initial();
  SettingsModel _settings = SettingsModel.initial();

  Timer? _ticker;
  double _commandLatencySeconds = 0.8;
  bool _hasActiveAlert = false;
  String? _alertMessage;

  // Getters
  AppLanguage get language => _language;
  AppLocalizations get l10n => AppLocalizations(_language);
  bool get isLoggedIn => _isLoggedIn;
  bool get isOffline => _isOffline;
  String get userEmail => _userEmail;
  TelemetryModel get telemetry => _telemetry;
  ActuatorModel get actuators => _actuators;
  SettingsModel get settings => _settings;
  double get commandLatencySeconds => _commandLatencySeconds;
  bool get hasActiveAlert => _hasActiveAlert;
  String? get alertMessage => _alertMessage;

  GreenhouseProvider() {
    _startLiveTicker();
  }

  void switchLanguage(AppLanguage lang) {
    _language = lang;
    notifyListeners();
  }

  void toggleLanguage() {
    _language = _language == AppLanguage.ru ? AppLanguage.kz : AppLanguage.ru;
    notifyListeners();
  }

  void login(String email, String password) {
    _userEmail = email;
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }

  // M8 Stress Test Toggle
  void toggleOfflineStressTest(bool offline) {
    _isOffline = offline;
    notifyListeners();
  }

  // M3 Remote Control Actuators
  Future<void> toggleActuator(String name, bool value) async {
    final startTime = DateTime.now();

    // Simulate device toggle
    switch (name) {
      case 'irrigation':
        _actuators = _actuators.copyWith(irrigation: value, updatedAt: DateTime.now());
        // Physics feedback: irrigation increases soil moisture
        if (value) {
          _telemetry = TelemetryModel(
            airTemp: _telemetry.airTemp,
            airHumidity: min(95.0, _telemetry.airHumidity + 2.0),
            soilMoisture: min(90.0, _telemetry.soilMoisture + 4.5),
            lightLevel: _telemetry.lightLevel,
            timestamp: DateTime.now(),
          );
        }
        break;
      case 'ventilation':
        _actuators = _actuators.copyWith(ventilation: value, updatedAt: DateTime.now());
        // Physics feedback: ventilation cools the greenhouse down
        if (value) {
          _telemetry = TelemetryModel(
            airTemp: max(16.0, _telemetry.airTemp - 2.8),
            airHumidity: max(35.0, _telemetry.airHumidity - 5.0),
            soilMoisture: _telemetry.soilMoisture,
            lightLevel: _telemetry.lightLevel,
            timestamp: DateTime.now(),
          );
          _hasActiveAlert = false;
          _alertMessage = null;
        }
        break;
      case 'heater':
        _actuators = _actuators.copyWith(heater: value, updatedAt: DateTime.now());
        if (value) {
          _telemetry = TelemetryModel(
            airTemp: min(35.0, _telemetry.airTemp + 3.0),
            airHumidity: _telemetry.airHumidity,
            soilMoisture: _telemetry.soilMoisture,
            lightLevel: _telemetry.lightLevel,
            timestamp: DateTime.now(),
          );
        }
        break;
      case 'lighting':
        _actuators = _actuators.copyWith(lighting: value, updatedAt: DateTime.now());
        if (value) {
          _telemetry = TelemetryModel(
            airTemp: _telemetry.airTemp,
            airHumidity: _telemetry.airHumidity,
            soilMoisture: _telemetry.soilMoisture,
            lightLevel: min(25000.0, _telemetry.lightLevel + 6000.0),
            timestamp: DateTime.now(),
          );
        }
        break;
    }

    _commandLatencySeconds = DateTime.now().difference(startTime).inMilliseconds / 1000.0 + 0.5;
    notifyListeners();
  }

  // M4 Mode Toggle
  void toggleAutoMode(bool auto) {
    _settings = _settings.copyWith(autoMode: auto);
    notifyListeners();
  }

  // M7 Update Thresholds
  void updateThresholds({double? minSoil, double? maxTemp}) {
    _settings = _settings.copyWith(
      minSoilMoisture: minSoil ?? _settings.minSoilMoisture,
      maxAirTemp: maxTemp ?? _settings.maxAirTemp,
    );
    notifyListeners();
  }

  // Trigger Overheating for Demo (Scenario 2)
  void triggerOverheatAlert() {
    _telemetry = TelemetryModel(
      airTemp: 32.8,
      airHumidity: 55.0,
      soilMoisture: 38.0,
      lightLevel: 18000.0,
      timestamp: DateTime.now(),
    );
    _hasActiveAlert = true;
    _alertMessage = l10n.tr('alert_overheat_title');
    notifyListeners();
  }

  void dismissAlert() {
    _hasActiveAlert = false;
    _alertMessage = null;
    notifyListeners();
  }

  // Live data ticker (simulates live sensor variations if not connected to live backend)
  void _startLiveTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_isOffline) return;

      final rand = Random();
      // Natural minor fluctuations
      double tempDelta = (rand.nextDouble() - 0.5) * 0.4;
      double soilDelta = _actuators.irrigation ? 1.5 : -0.2;
      double humidityDelta = (rand.nextDouble() - 0.5) * 0.8;

      double newTemp = (_telemetry.airTemp + tempDelta).clamp(14.0, 38.0);
      double newSoil = (_telemetry.soilMoisture + soilDelta).clamp(15.0, 95.0);
      double newHumidity = (_telemetry.airHumidity + humidityDelta).clamp(30.0, 95.0);

      // M4: Auto mode rule test
      if (_settings.autoMode && newSoil < _settings.minSoilMoisture && !_actuators.irrigation) {
        // Automatic watering rule fired!
        _actuators = _actuators.copyWith(irrigation: true);
      }

      _telemetry = TelemetryModel(
        airTemp: double.parse(newTemp.toStringAsFixed(1)),
        airHumidity: double.parse(newHumidity.toStringAsFixed(1)),
        soilMoisture: double.parse(newSoil.toStringAsFixed(1)),
        lightLevel: _telemetry.lightLevel,
        timestamp: DateTime.now(),
      );

      notifyListeners();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
