import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/telemetry_model.dart';
import '../services/telemetry_service.dart';
import '../l10n/app_localizations.dart';

class TelemetryController extends ChangeNotifier {
  final TelemetryService _telemetryService;
  StreamSubscription<TelemetryModel>? _telemetrySub;
  StreamSubscription<bool>? _stalenessSub;

  TelemetryModel get telemetry => _telemetryService.latestTelemetry;
  bool get isOffline => _telemetryService.isOffline;
  DateTime get lastReceivedAt => _telemetryService.lastReceivedAt;

  TelemetryController({TelemetryService? telemetryService})
      : _telemetryService = telemetryService ?? TelemetryService() {
    _telemetrySub = _telemetryService.onTelemetryUpdated.listen((_) {
      notifyListeners();
    });

    _stalenessSub = _telemetryService.onStalenessChanged.listen((_) {
      notifyListeners();
    });

    _telemetryService.startRealtimeSubscription();
  }

  String getLastUpdatedText([AppLanguage language = AppLanguage.en]) {
    return _telemetryService.latestTelemetry.getTimeAgo(language);
  }

  void injectTelemetry(TelemetryModel model) {
    _telemetryService.setTelemetry(model);
    notifyListeners();
  }

  void toggleOfflineStressTest(bool offline) {
    _telemetryService.setOfflineStressTest(offline);
    notifyListeners();
  }

  @override
  void dispose() {
    _telemetrySub?.cancel();
    _stalenessSub?.cancel();
    super.dispose();
  }
}
