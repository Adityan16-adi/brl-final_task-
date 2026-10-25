import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/mock_auth_repository.dart';
import '../data/persistent_auth_repository.dart';
import '../domain/auth_repository.dart';

/// Provider for SharedPreferences instance. Overridden in main().
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

/// Provides the active AuthRepository.
/// Uses PersistentAuthRepository when SharedPreferences is available; falls back to MockAuthRepository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  if (prefs != null) {
    return PersistentAuthRepository(prefs);
  }
  return MockAuthRepository();
});

/// Emits the signed-in user or null when signed out.
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// Current authenticated user
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authStateProvider).value;
});

/// True if current user is a teacher
final isTeacherProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.isTeacher ?? false;
});

/// Whether the user has completed onboarding / seen welcome
final hasCompletedOnboardingProvider = Provider<bool>((ref) {
  return ref.watch(authRepositoryProvider).hasCompletedOnboarding();
});
