import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import '../models/historical_point.dart';
import '../services/telemetry_service.dart';

class AnalyticsController extends ChangeNotifier {
  final TelemetryService _telemetryService;

  int _selectedPeriodDays = 7; // 1 = 24h, 7 = 7 days
  List<HistoricalTelemetryPoint> _historyPoints = [];
  bool _isLoading = false;

  int get selectedPeriodDays => _selectedPeriodDays;
  List<HistoricalTelemetryPoint> get historyPoints => List.unmodifiable(_historyPoints);
  bool get isLoading => _isLoading;

  AnalyticsController({TelemetryService? telemetryService})
      : _telemetryService = telemetryService ?? TelemetryService() {
    loadHistoricalData(_selectedPeriodDays);
  }

  Future<void> setPeriod(int days) async {
    if (_selectedPeriodDays == days) return;
    _selectedPeriodDays = days;
    await loadHistoricalData(days);
  }

  Future<void> loadHistoricalData(int days) async {
    _isLoading = true;
    notifyListeners();

    _historyPoints = await _telemetryService.fetchHistory(days: days);
    _isLoading = false;
    notifyListeners();
  }

  /// FlSpot lists for fl_chart integration (M6)
  List<FlSpot> get soilMoistureSpots {
    if (_historyPoints.isEmpty) return [];
    return List.generate(_historyPoints.length, (i) {
      return FlSpot(i.toDouble(), _historyPoints[i].soilMoisture);
    });
  }

  List<FlSpot> get airTempSpots {
    if (_historyPoints.isEmpty) return [];
    return List.generate(_historyPoints.length, (i) {
      return FlSpot(i.toDouble(), _historyPoints[i].airTemp);
    });
  }

  List<String> get xLabels {
    if (_historyPoints.isEmpty) return [];
    if (_selectedPeriodDays == 7) {
      return ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    } else {
      return ['00:00', '04:00', '08:00', '12:00', '16:00', '20:00', '24:00'];
    }
  }

  double get maxTemp {
    if (_historyPoints.isEmpty) return 30.0;
    return _historyPoints.map((p) => p.airTemp).reduce((a, b) => a > b ? a : b);
  }

  double get minTemp {
    if (_historyPoints.isEmpty) return 15.0;
    return _historyPoints.map((p) => p.airTemp).reduce((a, b) => a < b ? a : b);
  }

  double get maxSoilMoisture {
    if (_historyPoints.isEmpty) return 70.0;
    return _historyPoints.map((p) => p.soilMoisture).reduce((a, b) => a > b ? a : b);
  }

  double get minSoilMoisture {
    if (_historyPoints.isEmpty) return 20.0;
    return _historyPoints.map((p) => p.soilMoisture).reduce((a, b) => a < b ? a : b);
  }

  /// Scenario 4: Identify water deficit point where soil moisture reached minimum
  HistoricalTelemetryPoint? get waterDeficitPoint {
    if (_historyPoints.isEmpty) return null;
    return _historyPoints.reduce((a, b) => a.soilMoisture < b.soilMoisture ? a : b);
  }
}
