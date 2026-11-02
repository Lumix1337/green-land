import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'error_handler_service.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static const String defaultUrl = 'https://greenland-smart-greenhouse.supabase.co';
  static const String defaultAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdyZWVubGFuZC1zbWFydC1ncmVlbmhvdXNlIiwicm9sZSI6ImFub24iLCJpYXQiOjE2ODAwMDAwMDAsImV4cCI6MjAwMDAwMDAwMH0.mock_signature_for_offline_and_eval';

  bool _isInitialized = false;
  bool _isMockMode = true;
  String _activeGreenhouseId = 'gh_erlan_01';

  final StreamController<bool> _connectivityStream = StreamController<bool>.broadcast();

  bool get isInitialized => _isInitialized;
  bool get isMockMode => _isMockMode;
  String get activeGreenhouseId => _activeGreenhouseId;
  Stream<bool> get onConnectivityChanged => _connectivityStream.stream;

  void setActiveGreenhouseId(String id) {
    _activeGreenhouseId = id;
  }

  /// Initialize supabase_flutter with fail-safe error handling (M8 compliance)
  Future<bool> initialize({
    String? url,
    String? anonKey,
    bool forceMock = false,
  }) async {
    if (forceMock) {
      _isMockMode = true;
      _isInitialized = true;
      debugPrint('🌿 [SupabaseService] Initialized in Mock / Offline Resilience Mode');
      return true;
    }

    final supabaseUrl = url ?? defaultUrl;
    final supabaseKey = anonKey ?? defaultAnonKey;

    final result = await ErrorHandlerService().safeRun<bool>(() async {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseKey,
        realtimeClientOptions: const RealtimeClientOptions(
          eventsPerSecond: 10,
        ),
      );
      _isInitialized = true;
      _isMockMode = false;
      _connectivityStream.add(true);
      debugPrint('🌿 [SupabaseService] Supabase client initialized successfully at $supabaseUrl');
      return true;
    }, contextMessage: 'Supabase.initialize', fallbackValue: false);

    if (result != true) {
      // Graceful fallback to offline/mock mode for demo reliability
      _isInitialized = true;
      _isMockMode = true;
      _connectivityStream.add(false);
      debugPrint('🛡️ [SupabaseService] Fallback to Mock/Offline mode active. App operational.');
      return false;
    }

    return true;
  }

  SupabaseClient? get client {
    if (!_isInitialized || _isMockMode) {
      return null;
    }
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  void reportConnectivity(bool isConnected) {
    _connectivityStream.add(isConnected);
  }

  void dispose() {
    _connectivityStream.close();
  }
}
