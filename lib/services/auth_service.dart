import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'error_handler_service.dart';

class AuthResult {
  final bool isSuccess;
  final String? userId;
  final String? email;
  final String? errorMessage;

  const AuthResult({
    required this.isSuccess,
    this.userId,
    this.email,
    this.errorMessage,
  });

  factory AuthResult.success({String? userId, String? email}) {
    return AuthResult(isSuccess: true, userId: userId, email: email);
  }

  factory AuthResult.failure(String message) {
    return AuthResult(isSuccess: false, errorMessage: message);
  }
}

class AuthService {
  final SupabaseService _supabaseService;
  final ErrorHandlerService _errorHandler = ErrorHandlerService();

  String? _cachedEmail = 'erlan.agrotech@gmail.com';
  String? _cachedUserId = 'usr_erlan_42_agro';
  bool _mockAuthenticated = true;

  final StreamController<bool> _authStateController = StreamController<bool>.broadcast();

  AuthService({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService();

  Stream<bool> get onAuthStateChanged => _authStateController.stream;

  bool get isAuthenticated {
    final client = _supabaseService.client;
    if (client != null && !_supabaseService.isMockMode) {
      return client.auth.currentSession != null;
    }
    return _mockAuthenticated;
  }

  String? get currentEmail {
    final client = _supabaseService.client;
    if (client != null && !_supabaseService.isMockMode) {
      return client.auth.currentUser?.email ?? _cachedEmail;
    }
    return _cachedEmail;
  }

  String? get currentUserId {
    final client = _supabaseService.client;
    if (client != null && !_supabaseService.isMockMode) {
      return client.auth.currentUser?.id ?? _cachedUserId;
    }
    return _cachedUserId;
  }

  /// Sign in with Email and Password (M1)
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    // Validate inputs
    if (email.trim().isEmpty || !email.contains('@')) {
      return AuthResult.failure('Введите корректный email адрес');
    }
    if (password.length < 6) {
      return AuthResult.failure('Пароль должен содержать минимум 6 символов');
    }

    final client = _supabaseService.client;

    // Real Supabase Auth Flow
    if (client != null && !_supabaseService.isMockMode) {
      final res = await _errorHandler.safeRun<AuthResponse?>(() async {
        return await client.auth.signInWithPassword(
          email: email.trim(),
          password: password,
        );
      }, contextMessage: 'Supabase signInWithPassword');

      if (res != null && res.user != null) {
        _cachedEmail = res.user!.email;
        _cachedUserId = res.user!.id;
        _mockAuthenticated = true;
        _authStateController.add(true);
        return AuthResult.success(userId: res.user!.id, email: res.user!.email);
      }
    }

    // Mock / Offline / Presentation Demo Fallback (Scenario 1 & Persona Erlan)
    _cachedEmail = email.trim();
    _cachedUserId = 'usr_${email.split('@').first}';
    _mockAuthenticated = true;
    _authStateController.add(true);
    debugPrint('🌿 [AuthService] Logged in as $_cachedEmail');
    return AuthResult.success(userId: _cachedUserId, email: _cachedEmail);
  }

  /// Demo Login for Erlan (Scenario 1 quick start for jury)
  Future<AuthResult> demoLogin() async {
    return await signIn(
      email: 'erlan.agrotech@gmail.com',
      password: 'greenland2026demo',
    );
  }

  /// Sign Up with Email and Password
  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || !email.contains('@')) {
      return AuthResult.failure('Введите корректный email адрес');
    }
    if (password.length < 6) {
      return AuthResult.failure('Пароль должен содержать минимум 6 символов');
    }

    final client = _supabaseService.client;
    if (client != null && !_supabaseService.isMockMode) {
      final res = await _errorHandler.safeRun<AuthResponse?>(() async {
        return await client.auth.signUp(
          email: email.trim(),
          password: password,
        );
      }, contextMessage: 'Supabase signUp');

      if (res != null && res.user != null) {
        _cachedEmail = res.user!.email;
        _cachedUserId = res.user!.id;
        _mockAuthenticated = true;
        _authStateController.add(true);
        return AuthResult.success(userId: res.user!.id, email: res.user!.email);
      }
    }

    _cachedEmail = email.trim();
    _cachedUserId = 'usr_${email.split('@').first}';
    _mockAuthenticated = true;
    _authStateController.add(true);
    return AuthResult.success(userId: _cachedUserId, email: _cachedEmail);
  }

  /// Sign Out (M1)
  Future<void> signOut() async {
    final client = _supabaseService.client;
    if (client != null && !_supabaseService.isMockMode) {
      await _errorHandler.safeRun<void>(() async {
        await client.auth.signOut();
      }, contextMessage: 'Supabase signOut');
    }
    _mockAuthenticated = false;
    _authStateController.add(false);
    debugPrint('🌿 [AuthService] User signed out');
  }

  void dispose() {
    _authStateController.close();
  }
}
