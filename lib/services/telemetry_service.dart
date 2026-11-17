import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/telemetry_model.dart';
import '../models/historical_point.dart';
import 'supabase_service.dart';
import 'error_handler_service.dart';

class TelemetryService {
  final SupabaseService _supabaseService;
  final ErrorHandlerService _errorHandler = ErrorHandlerService();

  TelemetryModel _latestTelemetry = TelemetryModel.initial();
  bool _isOffline = false;
  DateTime _lastTelemetryReceivedAt = DateTime.now();

  final StreamController<TelemetryModel> _telemetryStreamController = StreamController<TelemetryModel>.broadcast();
  final StreamController<bool> _stalenessStreamController = StreamController<bool>.broadcast();

  RealtimeChannel? _realtimeChannel;
  Timer? _stalenessWatchdog;
  Timer? _connectivityHeartbeat;
  Timer? _mockTicker;
  bool _manualOfflineOverride = false;

  TelemetryModel get latestTelemetry => _latestTelemetry;
  bool get isOffline => _isOffline;
  DateTime get lastReceivedAt => _lastTelemetryReceivedAt;
  Stream<TelemetryModel> get onTelemetryUpdated => _telemetryStreamController.stream;
  Stream<bool> get onStalenessChanged => _stalenessStreamController.stream;

  TelemetryService({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService() {
    _startStalenessWatchdog();
  }

  /// Start Realtime subscription on 'telemetry' table (M2)
  void startRealtimeSubscription() {
    final client = _supabaseService.client;

    if (client != null && !_supabaseService.isMockMode) {
      fetchLatest();
      _startConnectivityHeartbeat();
      _errorHandler.safeRunSync(() {
        _realtimeChannel?.unsubscribe();
        _realtimeChannel = client
            .channel('public:telemetry_${_supabaseService.activeGreenhouseId}')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'telemetry',
              callback: (payload) {
                final newRecord = payload.newRecord;
                if (newRecord.isNotEmpty) {
                  final recordGh = newRecord['greenhouse_id']?.toString();
                  if (recordGh == null ||
                      recordGh == _supabaseService.activeGreenhouseId) {
                    final telemetry = TelemetryModel.fromJson(newRecord);
                    _updateTelemetry(telemetry);
                  }
                }
              },
            )
            .subscribe((status, [error]) {
          if (status == RealtimeSubscribeStatus.channelError ||
              status == RealtimeSubscribeStatus.timedOut) {
            if (!_isOffline) {
              _isOffline = true;
              _stalenessStreamController.add(true);
            }
          } else if (status == RealtimeSubscribeStatus.subscribed &&
              !_manualOfflineOverride) {
            if (_isOffline) {
              _isOffline = false;
              _stalenessStreamController.add(false);
              fetchLatest();
            }
          }
        });
        debugPrint(
            '🌿 [TelemetryService] Subscribed to Supabase Realtime telemetry channel');
      }, contextMessage: 'Supabase Realtime subscription');
    } else {
      // Start fallback simulated telemetry stream (updates every 15s)
      _startMockTelemetryTicker();
    }
  }

  /// Fetch latest telemetry row from Supabase for the active greenhouse (M2)
  Future<void> fetchLatest() async {
    final client = _supabaseService.client;
    if (client == null || _supabaseService.isMockMode) return;
    try {
      final List<dynamic> data = await client
          .from('telemetry')
          .select()
          .eq('greenhouse_id', _supabaseService.activeGreenhouseId)
          .order('timestamp', ascending: false)
          .limit(1);
      if (_manualOfflineOverride) return;
      if (_isOffline) {
        _isOffline = false;
        _stalenessStreamController.add(false);
      }
      if (data.isNotEmpty) {
        _updateTelemetry(
            TelemetryModel.fromJson(Map<String, dynamic>.from(data.first)));
      }
    } catch (e) {
      debugPrint('⚠️ [TelemetryService] fetchLatest failed: $e');
      if (!_isOffline) {
        _isOffline = true;
        _stalenessStreamController.add(true);
      }
    }
  }

  void _updateTelemetry(TelemetryModel telemetry) {
    _latestTelemetry = telemetry;
    _lastTelemetryReceivedAt = DateTime.now();
    if (_isOffline && !_manualOfflineOverride) {
      _isOffline = false;
      _stalenessStreamController.add(false);
    }
    _telemetryStreamController.add(telemetry);
  }

  /// Manually inject telemetry (for tests and immediate physics feedback from actuators)
  void setTelemetry(TelemetryModel telemetry) {
    _updateTelemetry(telemetry);
  }

  /// Fetch historical telemetry points for 24 hours or 7 days (M6)
  Future<List<HistoricalTelemetryPoint>> fetchHistory({required int days}) async {
    final client = _supabaseService.client;

    if (client != null && !_supabaseService.isMockMode) {
      final since = DateTime.now().subtract(Duration(days: days)).toIso8601String();
      final response = await _errorHandler.safeRun<List<Map<String, dynamic>>?>(() async {
        final List<dynamic> recent = await client
            .from('telemetry')
            .select()
            .eq('greenhouse_id', _supabaseService.activeGreenhouseId)
            .gte('timestamp', since)
            .order('timestamp', ascending: true);
        if (recent.isNotEmpty) {
          return recent.cast<Map<String, dynamic>>();
        }
        // Fallback to latest available points if seed history is older than `since`
        final List<dynamic> latest = await client
            .from('telemetry')
            .select()
            .eq('greenhouse_id', _supabaseService.activeGreenhouseId)
            .order('timestamp', ascending: false)
            .limit(days == 7 ? 7 : 24);
        return latest.reversed.toList().cast<Map<String, dynamic>>();
      }, contextMessage: 'fetchHistory from Supabase');

      if (response != null) {
        return response.map((row) => HistoricalTelemetryPoint.fromJson(row)).toList();
      }
    }

    // Return realistic seed historical data if offline or empty
    return days == 7
        ? HistoricalTelemetryPoint.generate7DaysMock()
        : HistoricalTelemetryPoint.generate24HoursMock();
  }

  void _startConnectivityHeartbeat() {
    _connectivityHeartbeat?.cancel();
    _connectivityHeartbeat = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (_manualOfflineOverride || _supabaseService.isMockMode) return;
      final client = _supabaseService.client;
      if (client == null) return;
      try {
        await client
            .from('greenhouses')
            .select('id')
            .limit(1)
            .timeout(const Duration(seconds: 5));
        if (_isOffline && !_manualOfflineOverride) {
          _isOffline = false;
          _stalenessStreamController.add(false);
          await fetchLatest();
        }
      } catch (_) {
        if (!_isOffline) {
          _isOffline = true;
          _stalenessStreamController.add(true);
        }
      }
    });
  }

  /// Watchdog checking if mock telemetry stopped (Scenario 5: Kill simulator stress test)
  void _startStalenessWatchdog() {
    _stalenessWatchdog = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_supabaseService.isMockMode) return;
      final secondsSinceLast = DateTime.now().difference(_lastTelemetryReceivedAt).inSeconds;
      if (secondsSinceLast > 30 && !_isOffline) {
        _isOffline = true;
        _stalenessStreamController.add(true);
        debugPrint('⚠️ [TelemetryService] No telemetry for ${secondsSinceLast}s. Greenhouse offline flagged.');
      } else if (secondsSinceLast <= 30 && _isOffline && !_manualOfflineOverride) {
        _isOffline = false;
        _stalenessStreamController.add(false);
      }
    });
  }

  /// Simulates 15-second telemetry arrivals when offline or in standalone demo
  void _startMockTelemetryTicker() {
    _mockTicker?.cancel();
    _mockTicker = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_isOffline) return;

      final rand = Random();
      final tempDelta = (rand.nextDouble() - 0.5) * 0.3;
      final humDelta = (rand.nextDouble() - 0.5) * 0.6;
      const soilDelta = -0.15; // natural dry-down

      final updated = _latestTelemetry.copyWith(
        airTemp: double.parse((_latestTelemetry.airTemp + tempDelta).clamp(16.0, 36.0).toStringAsFixed(1)),
        airHumidity: double.parse((_latestTelemetry.airHumidity + humDelta).clamp(35.0, 90.0).toStringAsFixed(1)),
        soilMoisture: double.parse((_latestTelemetry.soilMoisture + soilDelta).clamp(18.0, 85.0).toStringAsFixed(1)),
        timestamp: DateTime.now(),
      );

      _updateTelemetry(updated);
    });
  }

  /// Toggle manual offline stress test for presentation (M8)
  void setOfflineStressTest(bool offline) {
    _manualOfflineOverride = offline;
    _isOffline = offline;
    if (offline) {
      _lastTelemetryReceivedAt = DateTime.now().subtract(const Duration(seconds: 45));
    } else {
      _lastTelemetryReceivedAt = DateTime.now();
      fetchLatest();
    }
    _stalenessStreamController.add(offline);
  }

  void stopRealtimeSubscription() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
    _connectivityHeartbeat?.cancel();
    _connectivityHeartbeat = null;
  }

  void dispose() {
    _realtimeChannel?.unsubscribe();
    _stalenessWatchdog?.cancel();
    _connectivityHeartbeat?.cancel();
    _mockTicker?.cancel();
    _telemetryStreamController.close();
    _stalenessStreamController.close();
  }
}
