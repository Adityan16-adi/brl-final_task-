import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/clay_theme.dart';
import 'package:mobile/features/auth/application/auth_providers.dart';
import 'package:mobile/features/auth/data/mock_auth_repository.dart';
import 'package:mobile/features/auth/presentation/register_screen.dart';
import 'package:mobile/features/auth/presentation/welcome_screen.dart';
import 'package:mobile/features/home/presentation/widgets/overview_view.dart';

void _setMobileDimensions(WidgetTester tester) {
  tester.view.physicalSize = const Size(412, 892);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('Claymorphism Design System Component Tests', () {
    testWidgets('ClayContainer renders with dual-layer clay shadows', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ClayContainer(depth: 6, child: Text('Clay Surface')),
          ),
        ),
      );

      expect(find.text('Clay Surface'), findsOneWidget);
      final containerFinder = find.byType(ClayContainer);
      expect(containerFinder, findsOneWidget);

      final containerWidget = tester.widget<ClayContainer>(containerFinder);
      expect(containerWidget.depth, 6.0);
    });

    testWidgets('ClayBadge displays custom label, icon and colors', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ClayBadge(
              label: 'TEACHER',
              icon: Icons.co_present_rounded,
              backgroundColor: Color(0xFFF3E8FF),
              textColor: Color(0xFF8B5CF6),
            ),
          ),
        ),
      );

      expect(find.text('TEACHER'), findsOneWidget);
      expect(find.byIcon(Icons.co_present_rounded), findsOneWidget);
    });

    testWidgets('ClayButton triggers onPressed callback on tap', (
      tester,
    ) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClayButton(
              onPressed: () => pressed = true,
              child: const Text('Action Button'),
            ),
          ),
        ),
      );

      expect(find.text('Action Button'), findsOneWidget);
      await tester.tap(find.text('Action Button'));
      await tester.pumpAndSettle();

      expect(pressed, isTrue);
    });
  });

  group('Welcome / Get Started Screen Flow Tests', () {
    testWidgets(
      'WelcomeScreen renders branding, feature highlights and call to actions',
      (tester) async {
        _setMobileDimensions(tester);

        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: WelcomeScreen())),
        );
        await tester.pumpAndSettle();

        expect(find.text('Unified Learn'), findsOneWidget);
        expect(find.text('Role-Secured Classrooms'), findsOneWidget);
        expect(find.text('Assignments & Direct Feedback'), findsOneWidget);
        expect(find.text('24/7 AI Mentor Assistant'), findsOneWidget);
        expect(find.text('Get Started — Create Account'), findsOneWidget);
        expect(find.text('Sign In'), findsOneWidget);
        expect(find.text('Development Demo Mode'), findsOneWidget);
      },
    );
  });

  group('Registration Flow Tests', () {
    testWidgets(
      'RegisterScreen allows toggling between Student and Teacher roles',
      (tester) async {
        _setMobileDimensions(tester);

        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: RegisterScreen())),
        );
        await tester.pumpAndSettle();

        expect(find.text('Create Account'), findsOneWidget);
        expect(find.text('Register as Student'), findsOneWidget);

        // Select Teacher Role
        await tester.tap(find.text('Teacher'));
        await tester.pumpAndSettle();

        expect(find.text('Register as Teacher'), findsOneWidget);

        // Switch back to Student Role
        await tester.tap(find.text('Student'));
        await tester.pumpAndSettle();

        expect(find.text('Register as Student'), findsOneWidget);
      },
    );

    testWidgets('RegisterScreen validates matching passwords before submit', (
      tester,
    ) async {
      _setMobileDimensions(tester);

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: RegisterScreen())),
      );
      await tester.pumpAndSettle();

      // Enter name, email, and mismatching passwords
      await tester.enterText(find.byType(TextFormField).at(0), 'Alex Mercer');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'alex@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.enterText(
        find.byType(TextFormField).at(3),
        'differentPassword',
      );

      await tester.tap(find.text('Register as Student'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });
  });

  group('Personalized Dashboards Role Testing', () {
    testWidgets('Student dashboard renders student-specific widgets', (
      tester,
    ) async {
      _setMobileDimensions(tester);

      final authRepo = MockAuthRepository(
        initialUser: MockAuthRepository.studentUser,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(authRepo)],
          child: MaterialApp(
            home: Scaffold(body: OverviewView(onNavigateToTab: (_) {})),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome back, Student'), findsOneWidget);
      expect(find.text('STUDENT'), findsOneWidget);
      expect(find.text('Academic Progress & Attendance'), findsOneWidget);
      expect(find.text('Join Class'), findsOneWidget);
      expect(find.text('Ask Mentor'), findsOneWidget);
    });

    testWidgets(
      'Teacher dashboard renders teacher-specific widgets and notice',
      (tester) async {
        _setMobileDimensions(tester);

        final authRepo = MockAuthRepository(
          initialUser: MockAuthRepository.teacherUser,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [authRepositoryProvider.overrideWithValue(authRepo)],
            child: MaterialApp(
              home: Scaffold(body: OverviewView(onNavigateToTab: (_) {})),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Welcome back, Teacher'), findsOneWidget);
        expect(find.text('TEACHER'), findsOneWidget);
        expect(find.text('Instructor Dashboard Active'), findsOneWidget);
        expect(find.text('Create Class'), findsOneWidget);
        expect(find.text('Add Assignment'), findsOneWidget);
        expect(find.text('Attendance'), findsOneWidget);
      },
    );
  });
}
