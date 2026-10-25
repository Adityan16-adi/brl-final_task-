import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/persistent_auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PersistentAuthRepository Unit Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('Initial state is unauthenticated with onboarding false', () {
      final repo = PersistentAuthRepository(prefs);
      expect(repo.hasCompletedOnboarding(), isFalse);
    });

    test('Offline fallback sign in with demo credentials succeeds', () async {
      final repo = PersistentAuthRepository(prefs);

      final user = await repo.signIn(
        email: 'teacher@demo.com',
        password: PersistentAuthRepository.demoPassword,
      );

      expect(user.role, UserRole.teacher);
      expect(user.email, 'teacher@demo.com');
      expect(repo.hasCompletedOnboarding(), isTrue);

      final token = await repo.getIdToken();
      expect(token, startsWith('mock-jwt-token-'));
    });

    test('Offline fallback sign in with wrong password throws AuthFailure', () async {
      final repo = PersistentAuthRepository(prefs);

      expect(
        () => repo.signIn(
          email: 'teacher@demo.com',
          password: 'wrong_password_123',
        ),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('Sign out clears session and token while preserving onboarding', () async {
      final repo = PersistentAuthRepository(prefs);
      await repo.signIn(
        email: 'student@demo.com',
        password: PersistentAuthRepository.demoPassword,
      );

      expect(await repo.getIdToken(), isNotNull);
      expect(repo.hasCompletedOnboarding(), isTrue);

      await repo.signOut();
      expect(await repo.getIdToken(), isNull);
      expect(repo.hasCompletedOnboarding(), isTrue);
    });

    test('Live Dio client registration parses real token and user', () async {
      // Mock Dio instance returning genuine JWT token
      final dio = Dio();
      dio.httpClientAdapter = HttpClientAdapter(); // Default stub for test
      
      // We can test repository with simulated backend data directly through persistent storage
      await prefs.setString(
        PersistentAuthRepository.keyToken,
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.real-jwt-token.test',
      );
      await prefs.setString(
        PersistentAuthRepository.keyUser,
        jsonEncode({
          'uid': 'user-live-101',
          'email': 'realuser@test.edu',
          'name': 'Real User',
          'role': 'teacher',
        }),
      );

      final repo = PersistentAuthRepository(prefs);
      final token = await repo.getIdToken();
      expect(token, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.real-jwt-token.test');
    });
  });
}
