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
    this.isDemo = false,
    this.avatarUrl,
  });

  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final bool isDemo;
  final String? avatarUrl;

  String get id => uid;

  bool get isTeacher => role == UserRole.teacher;
  bool get isStudent => role == UserRole.student;

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'name': name,
        'role': role.name,
        'isDemo': isDemo,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        uid: json['uid']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        role: UserRole.fromString(json['role']?.toString()),
        isDemo: json['isDemo'] == true,
        avatarUrl: json['avatarUrl']?.toString(),
      );

  AppUser copyWith({
    String? uid,
    String? email,
    String? name,
    UserRole? role,
    bool? isDemo,
    String? avatarUrl,
  }) =>
      AppUser(
        uid: uid ?? this.uid,
        email: email ?? this.email,
        name: name ?? this.name,
        role: role ?? this.role,
        isDemo: isDemo ?? this.isDemo,
        avatarUrl: avatarUrl ?? this.avatarUrl,
      );
}

/// Result returned from a Google Sign-In attempt
class GoogleAuthResult {
  const GoogleAuthResult({
    this.user,
    this.needsRoleSelection = false,
    this.idToken,
    this.email,
    this.displayName,
    this.photoUrl,
    this.message,
  });

  final AppUser? user;
  final bool needsRoleSelection;
  final String? idToken;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String? message;
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

  /// Explicitly starts an offline demonstration session with demo credentials.
  Future<AppUser> signInDemo({UserRole role = UserRole.student});

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    UserRole role = UserRole.student,
    String? teacherCode,
  });

  /// Signs in using Google via Firebase authentication.
  Future<GoogleAuthResult> signInWithGoogle({
    UserRole? role,
    String? teacherCode,
    String? idTokenOverride,
  });

  /// Update the current user's display name or avatar URL.
  Future<AppUser> updateProfile({String? name, String? avatarUrl});

  Future<void> signOut();

  /// Current ID token for API calls, or null.
  Future<String?> getIdToken();

  /// Whether onboarding has been completed by the user
  bool hasCompletedOnboarding();

  /// Mark onboarding state
  Future<void> setOnboardingCompleted(bool value);
}
