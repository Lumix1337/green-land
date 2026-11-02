import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_land/services/error_handler_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('ErrorHandlerService Tests (Module M8 Resilience)', () {
    late ErrorHandlerService errorHandler;

    setUp(() {
      errorHandler = ErrorHandlerService();
    });

    test('safeRun successfully returns computed result without error', () async {
      final result = await errorHandler.safeRun<int>(() async {
        return 42;
      }, fallbackValue: 0);

      expect(result, equals(42));
    });

    test('safeRun catches SocketException and returns fallbackValue (No crash)', () async {
      final result = await errorHandler.safeRun<String>(() async {
        throw const SocketException('Network connection dropped by commission stress test');
      }, fallbackValue: 'fallback_cached_data');

      expect(result, equals('fallback_cached_data'));
      expect(errorHandler.errorLog.isNotEmpty, isTrue);
      expect(errorHandler.errorLog.last.errorType, equals('SocketException'));
    });

    test('safeRun catches TimeoutException gracefully', () async {
      final result = await errorHandler.safeRun<bool>(() async {
        throw TimeoutException('Supabase query exceeded limit');
      }, fallbackValue: false);

      expect(result, isFalse);
      expect(errorHandler.errorLog.last.errorType, equals('TimeoutException'));
    });

    test('safeRun catches AuthException gracefully', () async {
      final result = await errorHandler.safeRun<bool>(() async {
        throw const AuthException('Invalid login credentials');
      }, fallbackValue: false);

      expect(result, isFalse);
      expect(errorHandler.errorLog.last.errorType, equals('AuthException'));
    });

    test('formatErrorMessage translates SocketException to Russian text', () {
      const err = SocketException('No route to host');
      final msg = ErrorHandlerService.formatErrorMessage(err);
      expect(msg, contains('Нет подключения к интернету'));
    });
  });
}
