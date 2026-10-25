import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/features/account/presentation/account_screen.dart';
import 'package:mobile/features/auth/application/auth_providers.dart';
import 'package:mobile/features/auth/data/persistent_auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/help/presentation/help_desk_screen.dart';
import 'package:mobile/features/home/presentation/home_screen.dart';
import 'package:mobile/features/home/presentation/screens/todo_screen.dart';
import 'package:mobile/features/home/presentation/widgets/app_drawer.dart';
import 'package:mobile/features/settings/presentation/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PersistentAuthRepository Unit Tests', () {
    test('fresh install defaults to onboarding false and signed out', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = PersistentAuthRepository(prefs);

      expect(repo.hasCompletedOnboarding(), isFalse);
      expect(await repo.authStateChanges().first, isNull);
    });

    test('setOnboardingCompleted updates preference and getter', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = PersistentAuthRepository(prefs);

      await repo.setOnboardingCompleted(true);
      expect(repo.hasCompletedOnboarding(), isTrue);
      expect(prefs.getBool(PersistentAuthRepository.keyOnboarding), isTrue);
    });

    test('signIn with demo student persists session', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = PersistentAuthRepository(prefs);

      final user = await repo.signIn(
        email: 'student@demo.com',
        password: PersistentAuthRepository.demoPassword,
      );

      expect(user.email, 'student@demo.com');
      expect(user.role, UserRole.student);
      expect(repo.hasCompletedOnboarding(), isTrue);
      expect(prefs.getString(PersistentAuthRepository.keyUser), isNotNull);
    });

    test('reopening app restores persisted session', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo1 = PersistentAuthRepository(prefs);

      await repo1.signIn(
        email: 'teacher@demo.com',
        password: PersistentAuthRepository.demoPassword,
      );

      // Simulate app kill and relaunch with same prefs
      final repo2 = PersistentAuthRepository(prefs);
      final restored = await repo2.authStateChanges().first;

      expect(restored, isNotNull);
      expect(restored!.email, 'teacher@demo.com');
      expect(restored.role, UserRole.teacher);
      expect(repo2.hasCompletedOnboarding(), isTrue);
    });

    test('signOut clears user and token but keeps onboarding completed',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = PersistentAuthRepository(prefs);

      await repo.signIn(
        email: 'student@demo.com',
        password: PersistentAuthRepository.demoPassword,
      );
      await repo.signOut();

      expect(await repo.authStateChanges().first, isNull);
      expect(prefs.getString(PersistentAuthRepository.keyUser), isNull);
      expect(repo.hasCompletedOnboarding(), isTrue);
    });
  });

  group('AppDrawer & Navigation Widget Tests', () {
    testWidgets('AppDrawer opens and renders all navigation options',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(
              const AppUser(
                uid: 'test-student',
                email: 'test@demo.com',
                name: 'Test Student',
                role: UserRole.student,
              ),
            ),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open drawer via scaffold state
      final scaffoldFinder = find.byType(Scaffold).first;
      final ScaffoldState state = tester.state(scaffoldFinder);
      state.openDrawer();
      await tester.pumpAndSettle();

      expect(find.byType(AppDrawer), findsOneWidget);
      expect(find.text('Study Planner & To-Do'), findsOneWidget);
      expect(find.text('Settings & Preferences'), findsOneWidget);
      expect(find.text('Manage Account'), findsOneWidget);
      expect(find.text('Help Desk & FAQ'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });
  });

  group('Phase 1 New Screen Widget Tests', () {
    testWidgets('TodoScreen renders urgency buckets and search filter',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TodoScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Study Planner & To-Do'), findsOneWidget);
      expect(find.text('Urgent & Active'), findsOneWidget);
      expect(find.text('All Tasks'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('SettingsScreen displays theme, server and notification toggles',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings & Preferences'), findsOneWidget);
      expect(find.text('Theme Mode'), findsOneWidget);
      expect(find.text('Backend Node.js Core API'), findsOneWidget);
      expect(find.text('Assignment Due Reminders'), findsOneWidget);
    });

    testWidgets('AccountScreen displays user details and sign out button',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(
              const AppUser(
                uid: 'user-xyz',
                email: 'user@example.com',
                name: 'Alice Johnson',
                role: UserRole.student,
              ),
            ),
          ],
          child: const MaterialApp(
            home: AccountScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Manage Account'), findsOneWidget);
      expect(find.text('Alice Johnson'), findsOneWidget);
      expect(find.text('user@example.com'), findsAtLeastNWidgets(1));
      expect(find.text('Sign Out of Account'), findsOneWidget);
    });

    testWidgets('HelpDeskScreen displays searchable FAQ accordion',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HelpDeskScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Help Desk & FAQ'), findsOneWidget);
      expect(find.text('How do I join a classroom as a student?'), findsOneWidget);
      expect(find.text('Still need help?'), findsOneWidget);
    });
  });
}
