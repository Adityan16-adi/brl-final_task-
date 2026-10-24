enum UserRole {
  student,
  teacher;

  static UserRole fromString(String? value) =>
      value == 'teacher' ? UserRole.teacher : UserRole.student;
}

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
  });

  final String uid;
  final String email;
  final String name;
  final UserRole role;

  bool get isTeacher => role == UserRole.teacher;
  bool get isStudent => role == UserRole.student;
}

/// A user-facing authentication failure.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract interface class AuthRepository {
  /// Emits the signed-in user or null when signed out.
  Stream<AppUser?> authStateChanges();

  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    UserRole role = UserRole.student,
  });

  Future<void> signOut();

  /// Current ID token for API calls, or null.
  Future<String?> getIdToken();
}
