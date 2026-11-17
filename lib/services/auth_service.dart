import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'error_handler_service.dart';

class AuthResult {
  final bool isSuccess;
  final bool requiresVerification;
  final String? userId;
  final String? email;
  final String? errorMessage;

  const AuthResult({
    required this.isSuccess,
    this.requiresVerification = false,
    this.userId,
    this.email,
    this.errorMessage,
  });

  factory AuthResult.success({
    String? userId,
    String? email,
    bool requiresVerification = false,
  }) {
    return AuthResult(
      isSuccess: true,
      requiresVerification: requiresVerification,
      userId: userId,
      email: email,
    );
  }

  factory AuthResult.failure(String message) {
    return AuthResult(isSuccess: false, errorMessage: message);
  }
}

class AuthService {
  final SupabaseService _supabaseService;
  final ErrorHandlerService _errorHandler = ErrorHandlerService();

  final Map<String, String> _mockUsers = {
    'erlan.agrotech@gmail.com': 'greenland2026demo',
  };

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
    final normalizedEmail = email.trim().toLowerCase();
    // Validate inputs
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      return AuthResult.failure('Введите корректный email адрес');
    }
    if (password.length < 6) {
      return AuthResult.failure('Пароль должен содержать минимум 6 символов');
    }

    final client = _supabaseService.client;

    // Real Supabase Auth Flow (never fall back to mock on bad credentials)
    if (client != null && !_supabaseService.isMockMode) {
      try {
        final res = await client.auth.signInWithPassword(
          email: normalizedEmail,
          password: password,
        );
        if (res.session != null && res.user != null) {
          _cachedEmail = res.user!.email;
          _cachedUserId = res.user!.id;
          _mockAuthenticated = true;
          _authStateController.add(true);
          return AuthResult.success(userId: res.user!.id, email: res.user!.email);
        }
        return AuthResult.failure('Sign-in did not return a session.');
      } on AuthException catch (e) {
        return AuthResult.failure(e.message);
      } catch (e) {
        debugPrint('⚠️ [AuthService] signIn error: $e');
        return AuthResult.failure('Could not connect. Please try again.');
      }
    }

    // Mock / Offline Mode (verify registered passwords)
    final registeredPassword = _mockUsers[normalizedEmail];
    if (registeredPassword != null && registeredPassword != password) {
      return AuthResult.failure('Invalid email or password.');
    }
    _mockUsers.putIfAbsent(normalizedEmail, () => password);
    _cachedEmail = normalizedEmail;
    _cachedUserId = 'usr_${normalizedEmail.split('@').first}';
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
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      return AuthResult.failure('Введите корректный email адрес');
    }
    if (password.length < 6) {
      return AuthResult.failure('Пароль должен содержать минимум 6 символов');
    }

    final client = _supabaseService.client;
    if (client != null && !_supabaseService.isMockMode) {
      try {
        final res = await client.auth.signUp(
          email: normalizedEmail,
          password: password,
        );
        if (res.session != null && res.user != null) {
          _cachedEmail = res.user!.email;
          _cachedUserId = res.user!.id;
          _mockAuthenticated = true;
          _authStateController.add(true);
          return AuthResult.success(userId: res.user!.id, email: res.user!.email);
        }
        if (res.user != null) {
          return AuthResult.success(
            userId: res.user!.id,
            email: res.user!.email,
            requiresVerification: true,
          );
        }
        return AuthResult.failure('Unable to create account.');
      } on AuthException catch (e) {
        return AuthResult.failure(e.message);
      } catch (e) {
        debugPrint('⚠️ [AuthService] signUp error: $e');
        return AuthResult.failure('Could not connect. Please try again.');
      }
    }

    if (_mockUsers.containsKey(normalizedEmail)) {
      return AuthResult.failure('An account with this email already exists.');
    }
    _mockUsers[normalizedEmail] = password;
    _cachedEmail = normalizedEmail;
    _cachedUserId = 'usr_${normalizedEmail.split('@').first}';
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
