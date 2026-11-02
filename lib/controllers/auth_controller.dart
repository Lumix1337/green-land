import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _authService.isAuthenticated;
  String? get userEmail => _authService.currentEmail;
  String? get userId => _authService.currentUserId;

  AuthController({AuthService? authService})
      : _authService = authService ?? AuthService() {
    _authService.onAuthStateChanged.listen((_) {
      notifyListeners();
    });
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.signIn(email: email, password: password);
    _isLoading = false;

    if (!result.isSuccess) {
      _errorMessage = result.errorMessage ?? 'Не удалось войти в систему';
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  Future<bool> demoLogin() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.demoLogin();
    _isLoading = false;

    if (!result.isSuccess) {
      _errorMessage = result.errorMessage ?? 'Не удалось войти через демо-режим';
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  Future<bool> register(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.signUp(email: email, password: password);
    _isLoading = false;

    if (!result.isSuccess) {
      _errorMessage = result.errorMessage ?? 'Не удалось зарегистрироваться';
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authService.signOut();
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
