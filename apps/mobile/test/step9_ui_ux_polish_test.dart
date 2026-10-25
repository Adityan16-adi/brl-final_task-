import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/branding/app_branding.dart';
import 'package:mobile/features/auth/application/auth_providers.dart';
import 'package:mobile/features/auth/data/mock_auth_repository.dart';
import 'package:mobile/features/home/presentation/home_providers.dart';
import 'package:mobile/main.dart';

void main() {
  group('Step 9: UI/UX Polish, Viewport & Dark Mode Verification', () {
    testWidgets('360px width renders Dashboard and all 5 tabs cleanly without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final authRepo = MockAuthRepository(
        initialUser: MockAuthRepository.teacherUser,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(authRepo),
          ],
          child: const LearningApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Tab 0: Overview
      expect(find.text('Dashboard Overview'), findsOneWidget);
      expect(find.text('Welcome back, Teacher'), findsOneWidget);
      expect(find.text('Classes instructed'), findsOneWidget);

      final navBar = find.byType(NavigationBar);

      // Tab 1: Classrooms
      await tester.tap(find.descendant(of: navBar, matching: find.text('Classrooms')));
      await tester.pumpAndSettle();
      expect(find.text('Create Class'), findsOneWidget);

      // Tab 2: Assignments
      await tester.tap(find.descendant(of: navBar, matching: find.text('Assignments')));
      await tester.pumpAndSettle();
      expect(find.text('New Task'), findsOneWidget);

      // Tab 3: Materials
      await tester.tap(find.descendant(of: navBar, matching: find.text('Materials')));
      await tester.pumpAndSettle();
      expect(find.text('Upload Study Material'), findsOneWidget);

      // Tab 4: Schedule
      await tester.tap(find.descendant(of: navBar, matching: find.text('Schedule')));
      await tester.pumpAndSettle();
      expect(find.text('Deadlines'), findsOneWidget);
    });

    testWidgets('Dark mode renders with dark clay palette and switches cleanly', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 892);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final authRepo = MockAuthRepository(
        initialUser: MockAuthRepository.studentUser,
      );

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo),
        ],
      );
      addTearDown(container.dispose);

      // Set to Dark Mode
      container.read(themeModeProvider.notifier).state = ThemeMode.dark;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const LearningApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify that dark mode is active
      expect(container.read(themeModeProvider), ThemeMode.dark);

      // Verify overview renders properly under dark theme
      expect(find.text('Dashboard Overview'), findsOneWidget);
      expect(find.text('Active enrollments'), findsOneWidget);

      // Switch back to light mode
      container.read(themeModeProvider.notifier).state = ThemeMode.light;
      await tester.pumpAndSettle();

      expect(container.read(themeModeProvider), ThemeMode.light);
      expect(find.text('Dashboard Overview'), findsOneWidget);
    });

    testWidgets('Wide screen layout (1280px) renders NavigationRail and wide content', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final authRepo = MockAuthRepository(
        initialUser: MockAuthRepository.teacherUser,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(authRepo),
          ],
          child: const LearningApp(),
        ),
      );
      await tester.pumpAndSettle();

      // On wide screens, NavigationRail is rendered
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text(AppBranding.appName), findsOneWidget);
    });
  });
}
