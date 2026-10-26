import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  Future<GoogleAuthResult> signInWithGoogle({
    UserRole? role,
    String? teacherCode,
    String? idTokenOverride,
  }) async {
    String? tokenToUse = idTokenOverride;

    if (tokenToUse == null || tokenToUse.isEmpty) {
      try {
        if (Firebase.apps.isEmpty) {
          if (ApiConfig.hasFirebaseConfig) {
            await Firebase.initializeApp(
              options: const FirebaseOptions(
                apiKey: ApiConfig.firebaseApiKey,
                appId: ApiConfig.firebaseAppId,
                messagingSenderId: ApiConfig.firebaseMessagingSenderId,
                projectId: ApiConfig.firebaseProjectId,
              ),
            );
          } else {
            await Firebase.initializeApp();
          }
        }

        final googleSignIn = GoogleSignIn();
        final googleAccount = await googleSignIn.signIn();
        if (googleAccount == null) {
          throw const AuthFailure('Google sign-in was cancelled.');
        }

        final googleAuth = await googleAccount.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
        tokenToUse = await userCred.user?.getIdToken();

        if (tokenToUse == null || tokenToUse.isEmpty) {
          throw const AuthFailure('Failed to obtain Firebase ID token from Google account.');
        }
      } on AuthFailure {
        rethrow;
      } catch (err) {
        throw const AuthFailure(
          'Google Sign-In is unavailable on this device (google-services.json is missing or not configured). Please sign in using Email & Password or use Demo Mode.',
        );
      }
    }

    // Call backend /api/auth/google
    try {
      final dio = _dio ?? DioClient.createFor(ApiConfig.coreBaseUrl);
      final response = await dio.post<Map<String, dynamic>>(
        '/api/auth/google',
        data: {
          'idToken': tokenToUse,
          if (role != null) 'role': role.name,
          if (teacherCode != null && teacherCode.isNotEmpty) 'teacherCode': teacherCode.trim(),
        },
        options: Options(
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );

      final data = response.data;
      if (data != null) {
        if (data['needsRoleSelection'] == true) {
          return GoogleAuthResult(
            needsRoleSelection: true,
            idToken: tokenToUse,
            email: data['email'] as String?,
            displayName: data['name'] as String?,
            photoUrl: data['picture'] as String?,
            message: data['message'] as String?,
          );
        }

        if (data['success'] == true && data['user'] is Map) {
          final userRaw = data['user'] as Map<String, dynamic>;
          final token = data['token'] as String?;
          final user = AppUser(
            uid: userRaw['uid'] as String? ?? 'user-${DateTime.now().millisecondsSinceEpoch}',
            email: userRaw['email'] as String? ?? '',
            name: userRaw['name'] as String? ?? 'User',
            role: userRaw['role'] == 'teacher' ? UserRole.teacher : UserRole.student,
            avatarUrl: userRaw['avatarUrl'] as String?,
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
          return GoogleAuthResult(user: user);
        }
      }
      throw const AuthFailure('Unexpected response from Google authentication service.');
    } on DioException catch (dioErr) {
      if (dioErr.response != null) {
        final resData = dioErr.response?.data;
        if (resData is Map && resData['message'] != null) {
          throw AuthFailure(resData['message'] as String);
        }
        throw AuthFailure('Server returned Google auth error (${dioErr.response?.statusCode}). Please retry.');
      }
      throw AuthFailure(
        'Cannot connect to authentication server at ${ApiConfig.coreBaseUrl}. Please verify the backend is running and retry.',
      );
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw AuthFailure('Google sign in failed: $e');
    }
  }

  @override
  Future<AppUser> updateProfile({String? name, String? avatarUrl}) async {
    if (_current == null) {
      throw const AuthFailure('No active user session to update.');
    }

    if (_current!.isDemo) {
      final updated = _current!.copyWith(
        name: name ?? _current!.name,
        avatarUrl: avatarUrl ?? _current!.avatarUrl,
      );
      _set(updated);
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setString(keyUser, jsonEncode(updated.toJson()));
      return updated;
    }

    try {
      final token = await getIdToken();
      final dio = DioClient.createFor(
        ApiConfig.coreBaseUrl,
        tokenReader: () async => token,
      );

      final body = <String, dynamic>{};
      if (name != null) body['name'] = name.trim();
      if (avatarUrl != null) body['avatarUrl'] = avatarUrl.trim();

      final res = await dio.put<Map<String, dynamic>>(
        '/api/auth/profile',
        data: body,
      );

      if (res.statusCode == 200 && res.data != null) {
        final userData = res.data!['user'] as Map<String, dynamic>?;
        if (userData != null) {
          final updated = AppUser.fromJson(userData);
          _set(updated);
          final prefs = _prefs ?? await SharedPreferences.getInstance();
          await prefs.setString(keyUser, jsonEncode(updated.toJson()));
          return updated;
        }
      }

      final fallback = _current!.copyWith(
        name: name ?? _current!.name,
        avatarUrl: avatarUrl ?? _current!.avatarUrl,
      );
      _set(fallback);
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setString(keyUser, jsonEncode(fallback.toJson()));
      return fallback;
    } on DioException catch (dioErr) {
      final msg = dioErr.response?.data is Map &&
              dioErr.response?.data['message'] != null
          ? dioErr.response!.data['message'] as String
          : 'Could not connect to profile service (${dioErr.message}).';
      throw AuthFailure(msg);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw AuthFailure('Failed to update profile: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await GoogleSignIn().signOut().catchError((_) => null);
        await FirebaseAuth.instance.signOut().catchError((_) => null);
      }
    } catch (_) {}
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
