import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/application/auth_providers.dart';
import 'package:mobile/features/auth/data/mock_auth_repository.dart';
import 'package:mobile/features/home/presentation/home_providers.dart';
import 'package:mobile/main.dart';

void _setMobileDimensions(WidgetTester tester) {
  tester.view.physicalSize = const Size(412, 892);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void _setDesktopDimensions(WidgetTester tester) {
  tester.view.physicalSize = const Size(1024, 768);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('Signed-out users see WelcomeScreen with Get Started and Sign in', (
    WidgetTester tester,
  ) async {
    _setMobileDimensions(tester);

    await tester.pumpWidget(const ProviderScope(child: LearningApp()));
    await tester.pumpAndSettle();

    expect(find.text('Get Started'), findsOneWidget);
    expect(find.textContaining('Sign in'), findsWidgets);
  });

  testWidgets('Quick login as student navigates to Dashboard Overview', (
    WidgetTester tester,
  ) async {
    _setMobileDimensions(tester);

    await tester.pumpWidget(const ProviderScope(child: LearningApp()));
    await tester.pumpAndSettle();

    // Tap sign in link on WelcomeScreen
    await tester.tap(find.textContaining('Sign in'));
    await tester.pumpAndSettle();

    // Tap Try demo
    await tester.tap(find.text('Try demo'));
    await tester.pumpAndSettle();

    // Select Continue as Student
    await tester.tap(find.text('Continue as Student'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard Overview'), findsOneWidget);
    expect(find.textContaining('Demo'), findsWidgets);
    expect(find.text('Join Class'), findsWidgets);
  });

  testWidgets(
    'Quick login as teacher navigates to Teacher Dashboard Overview',
    (WidgetTester tester) async {
      _setMobileDimensions(tester);

      await tester.pumpWidget(const ProviderScope(child: LearningApp()));
      await tester.pumpAndSettle();

      // Tap sign in link on WelcomeScreen
      await tester.tap(find.textContaining('Sign in'));
      await tester.pumpAndSettle();

      // Tap Try demo
      await tester.tap(find.text('Try demo'));
      await tester.pumpAndSettle();

      // Select Continue as Teacher
      await tester.tap(find.text('Continue as Teacher'));
      await tester.pumpAndSettle();

      expect(find.text('Dashboard Overview'), findsOneWidget);
      expect(find.textContaining('Demo'), findsWidgets);
      expect(find.text('Create Class'), findsWidgets);
    },
  );

  testWidgets(
    'Tab navigation switches between tabs via NavigationBar on mobile',
    (WidgetTester tester) async {
      _setMobileDimensions(tester);

      // Provide pre-authenticated repo so test lands directly on dashboard
      final authRepo = MockAuthRepository(
        initialUser: MockAuthRepository.studentUser,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(authRepo)],
          child: const LearningApp(),
        ),
      );
      await tester.pumpAndSettle();

      final navBar = find.byType(NavigationBar);
      expect(navBar, findsOneWidget);

      // 1. Switch to Classrooms
      await tester.tap(
        find.descendant(of: navBar, matching: find.text('Classrooms')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Enrolled Classrooms'), findsOneWidget);

      // 2. Switch to Assignments
      await tester.tap(
        find.descendant(of: navBar, matching: find.text('Assignments')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Course Assignments'), findsOneWidget);

      // 3. Switch to Materials
      await tester.tap(
        find.descendant(of: navBar, matching: find.text('Materials')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Learning Materials'), findsOneWidget);

      // 4. Switch to Schedule
      await tester.tap(
        find.descendant(of: navBar, matching: find.text('Schedule')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Weekly Schedule'), findsOneWidget);

      // 5. Return to Overview
      await tester.tap(
        find.descendant(of: navBar, matching: find.text('Overview')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Dashboard Overview'), findsOneWidget);
    },
  );

  testWidgets('Join Classroom dialog opens and can be cancelled', (
    WidgetTester tester,
  ) async {
    _setMobileDimensions(tester);

    final authRepo = MockAuthRepository(
      initialUser: MockAuthRepository.studentUser,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(authRepo)],
        child: const LearningApp(),
      ),
    );
    await tester.pumpAndSettle();

    final joinBtn = find.byTooltip('Join Classroom with Code');
    expect(joinBtn, findsOneWidget);
    await tester.tap(joinBtn);
    await tester.pumpAndSettle();

    expect(find.text('Join a Classroom'), findsOneWidget);
    expect(find.text('Class Code'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Join a Classroom'), findsNothing);
  });

  testWidgets('Theme mode cycles when theme button is pressed', (
    WidgetTester tester,
  ) async {
    _setMobileDimensions(tester);

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          MockAuthRepository(initialUser: MockAuthRepository.studentUser),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const LearningApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.system);

    final themeBtn = find.byTooltip('Theme: System (Tap to toggle)');
    expect(themeBtn, findsOneWidget);
    await tester.tap(themeBtn);
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.light);

    final lightBtn = find.byTooltip('Theme: Light (Tap to toggle)');
    expect(lightBtn, findsOneWidget);
    await tester.tap(lightBtn);
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.dark);
  });

  testWidgets('Submit assignment dialog opens from Assignments view', (
    WidgetTester tester,
  ) async {
    _setMobileDimensions(tester);

    final authRepo = MockAuthRepository(
      initialUser: MockAuthRepository.studentUser,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(authRepo)],
        child: const LearningApp(),
      ),
    );
    await tester.pumpAndSettle();

    final navBar = find.byType(NavigationBar);

    // Navigate to Assignments
    await tester.tap(
      find.descendant(of: navBar, matching: find.text('Assignments')),
    );
    await tester.pumpAndSettle();

    // Tap the first 'Submit Assignment' button
    final submitButton = find
        .widgetWithText(FilledButton, 'Submit Assignment')
        .first;
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // Verify modal dialog appeared
    expect(find.text('Submit Assignment'), findsWidgets);
    expect(find.text('Submit Solution / Notes'), findsOneWidget);

    // Dismiss dialog
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Submit Solution / Notes'), findsNothing);
  });

  testWidgets('Wide screen layout renders NavigationRail correctly', (
    WidgetTester tester,
  ) async {
    _setDesktopDimensions(tester);

    final authRepo = MockAuthRepository(
      initialUser: MockAuthRepository.studentUser,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(authRepo)],
        child: const LearningApp(),
      ),
    );
    await tester.pumpAndSettle();

    // In wide screen, NavigationRail is rendered, NavigationBar is not
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    // App title is visible in NavigationRail header
    expect(find.text('Pragti'), findsOneWidget);

    // Tap Classrooms icon in NavigationRail
    await tester.tap(find.byIcon(Icons.school_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Enrolled Classrooms'), findsOneWidget);
  });
}
