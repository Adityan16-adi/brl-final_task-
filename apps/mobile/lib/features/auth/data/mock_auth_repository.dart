import 'dart:async';

import '../domain/auth_repository.dart';

/// Offline mock authentication used for development and testing.
/// Provides instant student and teacher test credentials.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({AppUser? initialUser}) : _current = initialUser;

  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _current;

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

  static final Map<String, AppUser> _accounts = {
    'student@demo.com': studentUser,
    'teacher@demo.com': teacherUser,
  };

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
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final key = email.trim().toLowerCase();
    final user = _accounts[key];

    if (user == null || password != demoPassword) {
      throw const AuthFailure(
        'Demo mode: use student@demo.com or teacher@demo.com with password demo1234.',
      );
    }

    _set(user);
    return user;
  }

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    UserRole role = UserRole.student,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final key = email.trim().toLowerCase();

    if (_accounts.containsKey(key)) {
      throw const AuthFailure('An account with this email already exists.');
    }

    final user = AppUser(
      uid: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      email: email.trim(),
      name: name.trim(),
      role: role,
    );

    _accounts[key] = user;
    _set(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    _set(null);
  }

  @override
  Future<String?> getIdToken() async =>
      _current == null ? null : 'mock-jwt-token-${_current!.uid}';

  void _set(AppUser? user) {
    _current = user;
    _controller.add(user);
  }
}
