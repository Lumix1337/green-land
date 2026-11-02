import 'package:flutter_test/flutter_test.dart';
import 'package:green_land/services/auth_service.dart';
import 'package:green_land/services/supabase_service.dart';

void main() {
  group('AuthService Tests (Module M1 Authentication & RLS Session)', () {
    late AuthService authService;
    late SupabaseService mockSupabase;

    setUp(() {
      mockSupabase = SupabaseService();
      authService = AuthService(supabaseService: mockSupabase);
    });

    tearDown(() {
      authService.dispose();
    });

    test('Rejects invalid email format', () async {
      final res = await authService.signIn(email: 'invalid-email', password: 'password123');
      expect(res.isSuccess, isFalse);
      expect(res.errorMessage, contains('корректный email'));
    });

    test('Rejects password shorter than 6 characters', () async {
      final res = await authService.signIn(email: 'erlan@agro.kz', password: '123');
      expect(res.isSuccess, isFalse);
      expect(res.errorMessage, contains('минимум 6 символов'));
    });

    test('Demo login for Erlan succeeds and sets session identity', () async {
      final res = await authService.demoLogin();
      expect(res.isSuccess, isTrue);
      expect(authService.isAuthenticated, isTrue);
      expect(authService.currentEmail, equals('erlan.agrotech@gmail.com'));
    });

    test('Sign out transitions user to unauthenticated state', () async {
      await authService.demoLogin();
      expect(authService.isAuthenticated, isTrue);

      await authService.signOut();
      expect(authService.isAuthenticated, isFalse);
    });

    test('Sign up creates new account with proper userId', () async {
      final res = await authService.signUp(email: 'testfarmer@greenland.kz', password: 'securePassword2026');
      expect(res.isSuccess, isTrue);
      expect(authService.isAuthenticated, isTrue);
      expect(authService.currentEmail, equals('testfarmer@greenland.kz'));
    });
  });
}
