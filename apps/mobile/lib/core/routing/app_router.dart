import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/presentation/account_screen.dart';
import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/help/presentation/help_desk_screen.dart';
import '../../features/home/domain/home_repository.dart';
import '../../features/home/presentation/home_providers.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/screens/classroom_detail_screen.dart';
import '../../features/home/presentation/screens/todo_screen.dart';
import '../../features/mentor/presentation/mentor_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, _) => refreshNotifier.value++);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authAsync = ref.read(authStateProvider);
      final user = authAsync.value;
      final isSignedIn = user != null;
      final authRepo = ref.read(authRepositoryProvider);
      final hasCompletedOnboarding = authRepo.hasCompletedOnboarding();

      final loc = state.matchedLocation;
      final isAuthRoute =
          loc == '/welcome' || loc == '/login' || loc == '/register';

      // 1. Signed-in users should not access welcome/login/register
      if (isSignedIn) {
        if (isAuthRoute) {
          return '/';
        }
        return null;
      }

      // 2. Unauthenticated users trying to access protected screens
      if (!isSignedIn && !isAuthRoute) {
        // First-time users see welcome; returning users go directly to login
        return hasCompletedOnboarding ? '/login' : '/welcome';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/overview',
        redirect: (context, state) => '/',
      ),
      GoRoute(
        path: '/todo',
        builder: (context, state) => const TodoScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/account',
        builder: (context, state) => const AccountScreen(),
      ),
      GoRoute(
        path: '/help',
        builder: (context, state) => const HelpDeskScreen(),
      ),
      GoRoute(
        path: '/mentor',
        builder: (context, state) => const MentorScreen(),
      ),
      GoRoute(
        path: '/classroom/:id',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is ClassroomItem) {
            return ClassroomDetailScreen(classroom: extra);
          }
          final classId = state.pathParameters['id'] ?? '';
          final classes = ref.read(classroomsProvider).value ?? [];
          final classroom = classes.firstWhere(
            (c) => c.id == classId,
            orElse: () => ClassroomItem(
              id: classId,
              name: 'Virtual Classroom',
              subject: 'General Study',
              teacher: 'Course Instructor',
              schedule: 'Active Session',
              room: 'Hall 101',
              studentCount: 1,
            ),
          );
          return ClassroomDetailScreen(classroom: classroom);
        },
      ),
    ],
  );
});
