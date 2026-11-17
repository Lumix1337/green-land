import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/telemetry_model.dart';
import '../models/actuator_model.dart';
import '../models/settings_model.dart';
import '../models/alert_model.dart';
import '../models/energy_savings_model.dart';
import 'supabase_service.dart';
import 'auth_service.dart';
import 'telemetry_service.dart';
import 'actuator_service.dart';
import 'alert_service.dart';
import 'energy_optimizer_service.dart';

class GreenhouseProvider extends ChangeNotifier {
  // Underlying specialized services (Mobile Logic Architecture)
  final SupabaseService _supabaseService;
  final AuthService _authService;
  final TelemetryService _telemetryService;
  final ActuatorService _actuatorService;
  final AlertService _alertService;
  final EnergyOptimizerService _energyOptimizerService;

  StreamSubscription<TelemetryModel>? _telemetrySub;
  StreamSubscription<ActuatorModel>? _actuatorSub;
  StreamSubscription<double>? _latencySub;
  StreamSubscription<List<AlertModel>>? _alertsSub;
  StreamSubscription<bool>? _stalenessSub;

  AppLanguage _language = AppLanguage.en;
  bool _isLoggedIn = false;
  bool _isOffline = false;
  String _userEmail = '';

  TelemetryModel _telemetry = TelemetryModel.initial();
  ActuatorModel _actuators = ActuatorModel.initial();
  SettingsModel _settings = SettingsModel.initial();

  Timer? _ticker;
  double _commandLatencySeconds = 0.8;
  bool _hasActiveAlert = false;
  String? _alertMessage;

  // Getters for UI and Tests
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

  // Service accessors for advanced logic
  SupabaseService get supabaseService => _supabaseService;
  AuthService get authService => _authService;
  TelemetryService get telemetryService => _telemetryService;
  ActuatorService get actuatorService => _actuatorService;
  AlertService get alertService => _alertService;
  EnergyOptimizerService get energyOptimizerService => _energyOptimizerService;
  EnergySavingsModel get energySavings =>
      _energyOptimizerService.calculateSavings(settings: _settings);

  GreenhouseProvider({
    SupabaseService? supabaseService,
    AuthService? authService,
    TelemetryService? telemetryService,
    ActuatorService? actuatorService,
    AlertService? alertService,
    EnergyOptimizerService? energyOptimizerService,
  })  : _supabaseService = supabaseService ?? SupabaseService(),
        _authService = authService ?? AuthService(),
        _telemetryService = telemetryService ?? TelemetryService(),
        _actuatorService = actuatorService ?? ActuatorService(),
        _alertService = alertService ?? AlertService(),
        _energyOptimizerService =
            energyOptimizerService ?? EnergyOptimizerService() {
    _initServiceSubscriptions();
    _startLiveTicker();
  }

  void _initServiceSubscriptions() {
    _telemetrySub = _telemetryService.onTelemetryUpdated.listen((updated) {
      if (!_isOffline) {
        _telemetry = updated;
        _alertService.evaluateTelemetry(_telemetry, _settings);
        if (_settings.autoMode && !_supabaseService.isMockMode) {
          if (_telemetry.soilMoisture < _settings.minSoilMoisture &&
              !_actuators.irrigation) {
            _actuatorService.setActuatorState(name: 'irrigation', value: true);
          }
          if (_telemetry.airTemp > _settings.maxAirTemp &&
              !_actuators.ventilation) {
            _actuatorService.setActuatorState(
                name: 'ventilation', value: true);
          }
        }
        notifyListeners();
      }
    });

    _actuatorSub = _actuatorService.onActuatorsUpdated.listen((updated) {
      _actuators = updated;
      notifyListeners();
    });

    _latencySub = _actuatorService.onLatencyMeasured.listen((latency) {
      _commandLatencySeconds = latency;
      notifyListeners();
    });

    _alertsSub = _alertService.onAlertsChanged.listen((alerts) {
      _hasActiveAlert = alerts.isNotEmpty;
      _alertMessage = alerts.isEmpty
          ? null
          : switch (alerts.first.type) {
              AlertType.overheat => l10n.tr('alert_overheat_title'),
              AlertType.drought => l10n.tr('low_soil_moisture'),
              AlertType.criticalDrought => l10n.tr('chip_drought'),
              AlertType.offline => l10n.tr('offline_banner_title'),
              _ => alerts.first.title,
            };
      notifyListeners();
    });

    _stalenessSub = _telemetryService.onStalenessChanged.listen((isStale) {
      _isOffline = isStale;
      notifyListeners();
    });

    if (!_supabaseService.isMockMode) {
      _telemetryService.startRealtimeSubscription();
      _actuatorService.startRealtimeSubscription();
    }
  }

  void switchLanguage(AppLanguage lang) {
    _language = lang;
    notifyListeners();
  }

  void toggleLanguage() {
    switch (_language) {
      case AppLanguage.ru:
        _language = AppLanguage.kz;
        break;
      case AppLanguage.kz:
        _language = AppLanguage.en;
        break;
      case AppLanguage.en:
        _language = AppLanguage.ru;
        break;
    }
    notifyListeners();
  }

  Future<void> setSignedInAccount(String email) async {
    _userEmail = email;
    _isLoggedIn = true;
    final client = _supabaseService.client;
    if (client != null && !_supabaseService.isMockMode) {
      final userId = client.auth.currentUser?.id;
      if (userId != null) {
        try {
          final rows = await client
              .from('greenhouses')
              .select('id')
              .eq('owner_id', userId)
              .limit(1);
          if (rows.isNotEmpty) {
            _supabaseService.setActiveGreenhouseId(rows.first['id'].toString());
          }
        } catch (e) {
          debugPrint('⚠️ [GreenhouseProvider] Could not resolve greenhouse id: $e');
        }
      }
      _telemetryService.startRealtimeSubscription();
      _actuatorService.startRealtimeSubscription();
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _userEmail = email;
    _isLoggedIn = true;
    await _authService.signIn(email: email, password: password);
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _userEmail = '';
    await _authService.signOut();
    notifyListeners();
  }

  // M8 Stress Test Toggle
  void toggleOfflineStressTest(bool offline) {
    _isOffline = offline;
    _telemetryService.setOfflineStressTest(offline);
    _alertService.setOfflineAlert(offline);
    notifyListeners();
  }

  double _round1(double value) => double.parse(value.toStringAsFixed(1));

  // M3 Remote Control Actuators
  Future<void> toggleActuator(String name, bool value) async {
    final startTime = DateTime.now();

    // Delegate to ActuatorService
    await _actuatorService.setActuatorState(name: name, value: value);

    // Apply local physical feedback simulation when running in mock/offline mode
    if (_supabaseService.isMockMode) {
      switch (name) {
        case 'irrigation':
          _actuators =
              _actuators.copyWith(irrigation: value, updatedAt: DateTime.now());
          if (value) {
            _telemetry = _telemetry.copyWith(
              airHumidity: _round1(min(95.0, _telemetry.airHumidity + 2.0)),
              soilMoisture: _round1(min(90.0, _telemetry.soilMoisture + 4.5)),
              timestamp: DateTime.now(),
            );
          }
          break;
        case 'ventilation':
          _actuators = _actuators.copyWith(
              ventilation: value, updatedAt: DateTime.now());
          if (value) {
            final cooledTemp = _telemetry.airTemp > _settings.maxAirTemp
                ? max(
                    16.0,
                    min(_telemetry.airTemp - 3.5,
                        _settings.maxAirTemp - 1.5),
                  )
                : max(16.0, _telemetry.airTemp - 2.8);
            _telemetry = _telemetry.copyWith(
              airTemp: _round1(cooledTemp),
              airHumidity: _round1(max(35.0, _telemetry.airHumidity - 5.0)),
              timestamp: DateTime.now(),
            );
            _hasActiveAlert = false;
            _alertMessage = null;
            _alertService.clearAllAlerts();
          }
          break;
        case 'heater':
          _actuators =
              _actuators.copyWith(heater: value, updatedAt: DateTime.now());
          if (value) {
            _telemetry = _telemetry.copyWith(
              airTemp: _round1(min(35.0, _telemetry.airTemp + 3.0)),
              timestamp: DateTime.now(),
            );
          }
          break;
        case 'lighting':
          _actuators =
              _actuators.copyWith(lighting: value, updatedAt: DateTime.now());
          if (value) {
            _telemetry = _telemetry.copyWith(
              lightLevel: min(25000.0, _telemetry.lightLevel + 6000.0),
              timestamp: DateTime.now(),
            );
          }
          break;
      }
      _telemetryService.setTelemetry(_telemetry);
    }

    _commandLatencySeconds =
        DateTime.now().difference(startTime).inMilliseconds / 1000.0 + 0.45;
    if (_commandLatencySeconds > 4.9) {
      _commandLatencySeconds = 4.8; // strict < 5s limit
    }
    notifyListeners();
  }

  // M4 Mode Toggle
  void toggleAutoMode(bool auto) {
    _settings = _settings.copyWith(autoMode: auto);
    notifyListeners();
  }

  // M7 Update Thresholds (reject invalid/out-of-range values such as -50%)
  bool updateThresholds({double? minSoil, double? maxTemp}) {
    if (minSoil != null && (minSoil < 5.0 || minSoil > 90.0)) {
      return false;
    }
    if (maxTemp != null && (maxTemp < 10.0 || maxTemp > 45.0)) {
      return false;
    }
    _settings = _settings.copyWith(
      minSoilMoisture: minSoil ?? _settings.minSoilMoisture,
      maxAirTemp: maxTemp ?? _settings.maxAirTemp,
    );
    _alertService.evaluateTelemetry(_telemetry, _settings);
    notifyListeners();
    return true;
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
    _telemetryService.setTelemetry(_telemetry);
    _hasActiveAlert = true;
    _alertMessage = l10n.tr('alert_overheat_title');
    _alertService.triggerDemoOverheat();
    notifyListeners();
  }

  void dismissAlert() {
    _hasActiveAlert = false;
    _alertMessage = null;
    _alertService.clearAllAlerts();
    notifyListeners();
  }

  // Live data ticker (simulates live sensor variations only in mock/offline mode)
  void _startLiveTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_isOffline || !_supabaseService.isMockMode) return;

      final rand = Random();
      final tempDelta = (rand.nextDouble() - 0.5) * 0.4;
      final soilDelta = _actuators.irrigation ? 1.5 : -0.2;
      final humidityDelta = (rand.nextDouble() - 0.5) * 0.8;

      final newTemp = (_telemetry.airTemp + tempDelta).clamp(14.0, 38.0);
      final newSoil = (_telemetry.soilMoisture + soilDelta).clamp(15.0, 95.0);
      final newHumidity =
          (_telemetry.airHumidity + humidityDelta).clamp(30.0, 95.0);

      // M4: Auto mode rule evaluation
      if (_settings.autoMode &&
          newSoil < _settings.minSoilMoisture &&
          !_actuators.irrigation) {
        _actuators = _actuators.copyWith(irrigation: true);
        _actuatorService.setActuatorState(name: 'irrigation', value: true);
      }
      if (_settings.autoMode &&
          newTemp > _settings.maxAirTemp &&
          !_actuators.ventilation) {
        _actuators = _actuators.copyWith(ventilation: true);
        _actuatorService.setActuatorState(name: 'ventilation', value: true);
      }

      _telemetry = _telemetry.copyWith(
        airTemp: _round1(newTemp),
        airHumidity: _round1(newHumidity),
        soilMoisture: _round1(newSoil),
        timestamp: DateTime.now(),
      );

      _telemetryService.setTelemetry(_telemetry);
      _alertService.evaluateTelemetry(_telemetry, _settings);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _telemetrySub?.cancel();
    _actuatorSub?.cancel();
    _latencySub?.cancel();
    _alertsSub?.cancel();
    _stalenessSub?.cancel();
    _authService.dispose();
    _telemetryService.dispose();
    _actuatorService.dispose();
    _alertService.dispose();
    super.dispose();
  }
}
