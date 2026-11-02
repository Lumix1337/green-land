import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/actuator_model.dart';
import '../services/actuator_service.dart';

class ActuatorController extends ChangeNotifier {
  final ActuatorService _actuatorService;
  StreamSubscription<ActuatorModel>? _actuatorSub;
  StreamSubscription<double>? _latencySub;

  bool _isBusy = false;
  String? _errorMessage;

  ActuatorModel get actuators => _actuatorService.actuators;
  double get latencySeconds => _actuatorService.lastLatencySeconds;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;

  ActuatorController({ActuatorService? actuatorService})
      : _actuatorService = actuatorService ?? ActuatorService() {
    _actuatorSub = _actuatorService.onActuatorsUpdated.listen((_) {
      notifyListeners();
    });

    _latencySub = _actuatorService.onLatencyMeasured.listen((_) {
      notifyListeners();
    });

    _actuatorService.startRealtimeSubscription();
  }

  /// Toggle actuator with latency measurement (< 5s brief limit)
  Future<bool> toggleActuator(String name, bool value) async {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _actuatorService.setActuatorState(name: name, value: value);
    _isBusy = false;

    if (!result.isSuccess) {
      _errorMessage = result.errorMessage;
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  /// Emergency all-off command
  Future<bool> turnOffAll() async {
    _isBusy = true;
    notifyListeners();

    final result = await _actuatorService.turnOffAll();
    _isBusy = false;
    notifyListeners();
    return result.isSuccess;
  }

  @override
  void dispose() {
    _actuatorSub?.cancel();
    _latencySub?.cancel();
    super.dispose();
  }
}
