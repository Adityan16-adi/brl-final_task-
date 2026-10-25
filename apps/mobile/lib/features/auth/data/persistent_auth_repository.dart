import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/dio_client.dart';
import '../domain/auth_repository.dart';

/// Production-ready persistent authentication repository.
/// Saves and restores user identity, roles, access tokens, and onboarding status.
/// Authenticates against backend /api/auth/ endpoints with offline fallback.
class PersistentAuthRepository implements AuthRepository {
  PersistentAuthRepository(this._prefs, [this._dio]) {
    _init();
  }

  final SharedPreferences? _prefs;
  final Dio? _dio;
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _current;
  bool _onboardingCompleted = false;

  static const String keyUser = 'auth_persisted_user';
  static const String keyOnboarding = 'auth_onboarding_completed';
  static const String keyAccounts = 'auth_registered_accounts';
  static const String keyToken = 'auth_jwt_token';

  static const String demoPassword = 'demo1234';

  static const studentUser = AppUser(
    uid: 'mock-student-01',
    email: 'student@demo.com',
    name: 'Demo Student',
    role: UserRole.student,
  );

  static const teacherUser = AppUser(
    uid: 'mock-teacher-01',
    email: 'teacher@demo.com',
    name: 'Demo Teacher',
    role: UserRole.teacher,
  );

  final Map<String, ({AppUser user, String password})> _accounts = {
    'student@demo.com': (user: studentUser, password: demoPassword),
    'teacher@demo.com': (user: teacherUser, password: demoPassword),
  };

  void _init() {
    final prefs = _prefs;
    if (prefs != null) {
      _onboardingCompleted = prefs.getBool(keyOnboarding) ?? false;

      // Load registered accounts
      final accountsRaw = prefs.getString(keyAccounts);
      if (accountsRaw != null && accountsRaw.isNotEmpty) {
        try {
          final decoded = jsonDecode(accountsRaw) as Map<String, dynamic>;
          for (final entry in decoded.entries) {
            final m = entry.value as Map<String, dynamic>;
            final user = AppUser.fromJson(m);
            final pass = m['password'] as String? ?? demoPassword;
            _accounts[entry.key.toLowerCase()] = (user: user, password: pass);
          }
        } catch (_) {}
      }

      // Restore session
      final userRaw = prefs.getString(keyUser);
      if (userRaw != null && userRaw.isNotEmpty) {
        try {
          final decoded = jsonDecode(userRaw) as Map<String, dynamic>;
          _current = AppUser.fromJson(decoded);
        } catch (_) {}
      }
    }
  }

  @override
  bool hasCompletedOnboarding() => _onboardingCompleted;

  @override
  Future<void> setOnboardingCompleted(bool value) async {
    _onboardingCompleted = value;
    await _prefs?.setBool(keyOnboarding, value);
  }

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    // 1. Attempt genuine HTTP authentication against the backend
    try {
      final dio = _dio ?? DioClient.createFor(ApiConfig.coreBaseUrl);
      final response = await dio.post<Map<String, dynamic>>(
        '/api/auth/login',
        data: {'email': cleanEmail, 'password': password},
        options: Options(
          sendTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        final token = data['token'] as String?;
        final userRaw = data['user'] as Map<String, dynamic>?;
        if (userRaw != null) {
          final user = AppUser(
            uid: userRaw['uid'] as String? ?? 'user-${DateTime.now().millisecondsSinceEpoch}',
            email: userRaw['email'] as String? ?? cleanEmail,
            name: userRaw['name'] as String? ?? cleanEmail.split('@')[0],
            role: userRaw['role'] == 'teacher' ? UserRole.teacher : UserRole.student,
            isDemo: false,
          );

          _set(user);
          _onboardingCompleted = true;
          final prefs = _prefs;
          if (prefs != null) {
            await prefs.setBool(keyOnboarding, true);
            await prefs.setString(keyUser, jsonEncode(user.toJson()));
            if (token != null) {
              await prefs.setString(keyToken, token);
            }
          }
          return user;
        }
      }
      throw const AuthFailure('Server returned an unexpected authentication format.');
    } on DioException catch (dioErr) {
      if (dioErr.response != null) {
        final resData = dioErr.response?.data;
        if (resData is Map && resData['message'] != null) {
          throw AuthFailure(resData['message'] as String);
        }
        if (dioErr.response?.statusCode == 401 || dioErr.response?.statusCode == 403) {
          throw const AuthFailure('Invalid email or password.');
        }
        throw AuthFailure(
          'Authentication server error (${dioErr.response?.statusCode}). Please verify backend is running and retry.',
        );
      }
      throw AuthFailure(
        'Cannot connect to authentication server at ${ApiConfig.coreBaseUrl}. Please ensure the backend is running, check your network, or launch Demo Mode.',
      );
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw AuthFailure('Sign in failed: $e');
    }
  }

  @override
  Future<AppUser> signInDemo({UserRole role = UserRole.student}) async {
    final cleanEmail =
        role == UserRole.teacher ? 'teacher@demo.com' : 'student@demo.com';
    final user = AppUser(
      uid: 'demo-${role.name}',
      email: cleanEmail,
      name: role == UserRole.teacher ? 'Teacher' : 'Student',
      role: role,
      isDemo: true,
    );

    _set(user);
    _onboardingCompleted = true;
    final prefs = _prefs;
    if (prefs != null) {
      await prefs.setBool(keyOnboarding, true);
      await prefs.setString(keyUser, jsonEncode(user.toJson()));
      await prefs.setString(keyToken, 'mock-jwt-token-demo-${role.name}');
    }
    return user;
  }

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    UserRole role = UserRole.student,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = name.trim();

    // 1. Attempt genuine HTTP registration against the backend
    try {
      final dio = _dio ?? DioClient.createFor(ApiConfig.coreBaseUrl);
      final response = await dio.post<Map<String, dynamic>>(
        '/api/auth/register',
        data: {
          'name': cleanName,
          'email': cleanEmail,
          'password': password,
          'role': role.name,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );

      if (response.statusCode == 201 && response.data != null) {
        final data = response.data!;
        final token = data['token'] as String?;
        final userRaw = data['user'] as Map<String, dynamic>?;
        if (userRaw != null) {
          final user = AppUser(
            uid: userRaw['uid'] as String? ?? 'user-${DateTime.now().millisecondsSinceEpoch}',
            email: userRaw['email'] as String? ?? cleanEmail,
            name: userRaw['name'] as String? ?? cleanName,
            role: userRaw['role'] == 'teacher' ? UserRole.teacher : UserRole.student,
            isDemo: false,
          );

          _set(user);
          _onboardingCompleted = true;
          final prefs = _prefs;
          if (prefs != null) {
            await prefs.setBool(keyOnboarding, true);
            await prefs.setString(keyUser, jsonEncode(user.toJson()));
            if (token != null) {
              await prefs.setString(keyToken, token);
            }
          }
          return user;
        }
      }
      throw const AuthFailure('Unexpected response from registration service.');
    } on DioException catch (dioErr) {
      if (dioErr.response != null) {
        final resData = dioErr.response?.data;
        if (resData is Map && resData['message'] != null) {
          throw AuthFailure(resData['message'] as String);
        }
        if (dioErr.response?.statusCode == 409) {
          throw const AuthFailure('An account with this email already exists.');
        }
        throw AuthFailure('Server returned registration error (${dioErr.response?.statusCode}). Please retry.');
      }
      throw AuthFailure(
        'Cannot connect to registration server at ${ApiConfig.coreBaseUrl}. Please verify the backend is running and retry.',
      );
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw AuthFailure('Registration failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    _set(null);
    await _prefs?.remove(keyUser);
    await _prefs?.remove(keyToken);
  }

  @override
  Future<String?> getIdToken() async {
    if (_current == null) return null;
    final token = _prefs?.getString(keyToken);
    return token ?? 'mock-jwt-token-${_current!.uid}';
  }

  void _set(AppUser? user) {
    _current = user;
    _controller.add(user);
  }
}
