import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ErrorRecord {
  final DateTime timestamp;
  final String errorType;
  final String message;
  final StackTrace? stackTrace;

  ErrorRecord({
    required this.timestamp,
    required this.errorType,
    required this.message,
    this.stackTrace,
  });

  @override
  String toString() => '[$timestamp] $errorType: $message';
}

class ErrorHandlerService {
  static final ErrorHandlerService _instance = ErrorHandlerService._internal();
  factory ErrorHandlerService() => _instance;
  ErrorHandlerService._internal();

  final List<ErrorRecord> _errorLog = [];
  final StreamController<ErrorRecord> _errorStreamController = StreamController<ErrorRecord>.broadcast();

  List<ErrorRecord> get errorLog => List.unmodifiable(_errorLog);
  Stream<ErrorRecord> get onError => _errorStreamController.stream;

  /// Safely executes an asynchronous function and catches all known and unknown exceptions
  /// Ensures M8 "never crashes" guarantee
  Future<T?> safeRun<T>(
    Future<T> Function() action, {
    T? fallbackValue,
    String contextMessage = 'Операция',
    void Function(Object error)? onError,
  }) async {
    try {
      return await action();
    } on SocketException catch (e, stack) {
      _recordError('SocketException', '$contextMessage: Ошибка сетевого сокета (${e.message})', stack);
      onError?.call(e);
      return fallbackValue;
    } on TimeoutException catch (e, stack) {
      _recordError('TimeoutException', '$contextMessage: Превышен таймаут ответа (${e.duration})', stack);
      onError?.call(e);
      return fallbackValue;
    } on AuthException catch (e, stack) {
      _recordError('AuthException', '$contextMessage: Ошибка аутентификации (${e.message})', stack);
      onError?.call(e);
      return fallbackValue;
    } on PostgrestException catch (e, stack) {
      _recordError('PostgrestException', '$contextMessage: Ошибка базы данных (${e.message})', stack);
      onError?.call(e);
      return fallbackValue;
    } catch (e, stack) {
      _recordError('GenericException', '$contextMessage: Непредвиденная ошибка ($e)', stack);
      onError?.call(e);
      return fallbackValue;
    }
  }

  /// Safely executes a synchronous function
  T? safeRunSync<T>(
    T Function() action, {
    T? fallbackValue,
    String contextMessage = 'Синхронная операция',
  }) {
    try {
      return action();
    } catch (e, stack) {
      _recordError('SyncException', '$contextMessage: Ошибка ($e)', stack);
      return fallbackValue;
    }
  }

  void _recordError(String type, String message, [StackTrace? stack]) {
    final record = ErrorRecord(
      timestamp: DateTime.now(),
      errorType: type,
      message: message,
      stackTrace: stack,
    );
    _errorLog.add(record);
    if (_errorLog.length > 50) {
      _errorLog.removeAt(0);
    }
    _errorStreamController.add(record);
    debugPrint('🛡️ [M8 ErrorHandler] $type caught: $message');
  }

  /// Translates error to human-readable message for UI banner or snackbar
  static String formatErrorMessage(Object error) {
    if (error is SocketException) {
      return 'Нет подключения к интернету или серверу.';
    } else if (error is TimeoutException) {
      return 'Сервер не ответил вовремя. Проверьте сеть.';
    } else if (error is AuthException) {
      if (error.message.toLowerCase().contains('invalid login credentials')) {
        return 'Неверный email или пароль.';
      }
      return 'Ошибка авторизации: ${error.message}';
    } else if (error is PostgrestException) {
      return 'Ошибка синхронизации данных: ${error.message}';
    }
    return 'Произошла непредвиденная ошибка. Приложение стабильно.';
  }

  void dispose() {
    _errorStreamController.close();
  }
}
