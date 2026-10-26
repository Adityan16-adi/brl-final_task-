import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/application/auth_providers.dart';
import 'package:mobile/features/auth/data/mock_auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/presentation/login_screen.dart';
import 'package:mobile/features/auth/presentation/register_screen.dart';
import 'package:mobile/features/home/domain/home_repository.dart';
import 'package:mobile/features/home/presentation/home_providers.dart';
import 'package:mobile/features/home/presentation/home_screen.dart';
import 'package:mobile/features/home/presentation/widgets/app_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestLogin({AuthRepository? authRepo}) {
    return ProviderScope(
      overrides: [
        if (authRepo != null) authRepositoryProvider.overrideWithValue(authRepo),
      ],
      child: const MaterialApp(
        themeMode: ThemeMode.light,
        home: LoginScreen(),
      ),
    );
  }

  Widget buildTestRegister({AuthRepository? authRepo}) {
    return ProviderScope(
      overrides: [
        if (authRepo != null) authRepositoryProvider.overrideWithValue(authRepo),
      ],
      child: const MaterialApp(
        themeMode: ThemeMode.light,
        home: RegisterScreen(),
      ),
    );
  }

  Widget buildTestHome({
    bool isTeacher = false,
    List<ClassroomItem>? mockClasses,
    List<AssignmentItem>? mockAssignments,
    Size size = const Size(360, 640),
  }) {
    final user = isTeacher ? MockAuthRepository.teacherUser : MockAuthRepository.studentUser;

    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(user),
        sharedPreferencesProvider.overrideWithValue(null),
        if (mockClasses != null)
          classroomsProvider.overrideWith((ref) => Future.value(mockClasses)),
        if (mockAssignments != null)
          assignmentsProvider.overrideWith((ref) => Future.value(mockAssignments)),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: const HomeScreen(),
          ),
        ),
      ),
    );
  }

  group('Part C: Student / Teacher Separation on Auth', () {
    testWidgets('Login screen has Student | Teacher selector and persists selection', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestLogin());
      await tester.pumpAndSettle();

      expect(find.text('Student'), findsWidgets);
      expect(find.text('Teacher'), findsWidgets);

      // Tap Teacher
      await tester.tap(find.text('Teacher').first);
      await tester.pumpAndSettle();

      // Verify stored in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('last_login_role'), 'teacher');
    });

    testWidgets('Role mismatch shows expected error and does not allow sign-in', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockRepo = MockAuthRepository();
      await tester.pumpWidget(buildTestLogin(authRepo: mockRepo));
      await tester.pumpAndSettle();

      // Enter student email while Teacher is selected
      await tester.tap(find.text('Teacher').first);
      await tester.pumpAndSettle();

      final emailFinder = find.byType(TextFormField).first;
      final passFinder = find.byType(TextFormField).at(1);

      await tester.enterText(emailFinder, 'student@demo.com');
      await tester.enterText(passFinder, 'demo1234');
      await tester.pumpAndSettle();

      // Submit
      final signInBtn = find.widgetWithText(ElevatedButton, 'Sign In');
      await tester.ensureVisible(signInBtn);
      await tester.tap(signInBtn);
      await tester.pumpAndSettle();

      // Verify mismatch message
      expect(
        find.text('This is a student account. Switch to Student to sign in.'),
        findsOneWidget,
      );
    });

    testWidgets('Register screen shows Teacher invite key only when Teacher is selected', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestRegister());
      await tester.pumpAndSettle();

      // In Student mode, teacher invite key field is absent
      expect(find.text('Teacher invite key'), findsNothing);
      expect(find.text('Configured in TEACHER_INVITE_KEY on the server'), findsNothing);

      // Select Teacher
      await tester.tap(find.text('Teacher'));
      await tester.pumpAndSettle();

      // Teacher invite key field is now visible
      expect(find.text('Teacher invite key'), findsOneWidget);
      expect(find.text('Configured in TEACHER_INVITE_KEY on the server'), findsOneWidget);

      // Select Student again
      await tester.tap(find.text('Student'));
      await tester.pumpAndSettle();

      expect(find.text('Teacher invite key'), findsNothing);
    });
  });

  group('Part B: Drawer & Dashboard Complete Structure', () {
    testWidgets('AppDrawer contains all primary navigation, tools, account links and badges', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockClasses = [
        const ClassroomItem(
          id: 'c1',
          name: 'Advanced Math',
          subject: 'Mathematics',
          room: 'Room 201',
          teacher: 'Dr. Smith',
          studentCount: 24,
          schedule: 'Mon, Wed 10:00 AM',
        ),
      ];
      final mockAssignments = [
        const AssignmentItem(
          id: 'a1',
          title: 'Calculus Problem Set 1',
          subject: 'Mathematics',
          dueDate: 'Tomorrow, 5:00 PM',
          points: 100,
          status: AssignmentStatus.pending,
        ),
      ];

      await tester.pumpWidget(buildTestHome(
        isTeacher: true,
        mockClasses: mockClasses,
        mockAssignments: mockAssignments,
      ));
      await tester.pumpAndSettle();

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      Finder drawerText(String text) => find.descendant(
            of: find.byType(AppDrawer),
            matching: find.text(text),
          );

      expect(find.byType(AppDrawer), findsOneWidget);
      expect(drawerText('Dashboard'), findsOneWidget);
      expect(drawerText('My Classes'), findsOneWidget);
      expect(drawerText('Assignments'), findsOneWidget);
      expect(drawerText('Study Planner & To-Do'), findsOneWidget);
      expect(drawerText('Learning Materials'), findsOneWidget);
      expect(drawerText('Weekly Schedule'), findsOneWidget);
      expect(drawerText('Attendance Records'), findsOneWidget);
      expect(drawerText('Live Video Meetings'), findsOneWidget);
      expect(drawerText('AI Mentor Tutor'), findsOneWidget);

      // Teacher section items
      expect(drawerText('Create Class'), findsOneWidget);
      expect(drawerText('Start Live Class'), findsOneWidget);
      expect(drawerText('Grade Submissions'), findsOneWidget);

      // Account items
      expect(drawerText('My Profile'), findsOneWidget);
      expect(drawerText('Settings & Preferences'), findsOneWidget);
      expect(drawerText('Help Desk & FAQ'), findsOneWidget);
      expect(drawerText('Sign Out'), findsOneWidget);
    });

    testWidgets('Dashboard Overview renders without overflow at 320px width', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestHome(size: const Size(320, 1600)));
      await tester.pumpAndSettle();

      // Verify category title
      expect(find.text('Dashboard Overview'), findsOneWidget);
      // Verify quick action tiles
      expect(find.text('Join Class'), findsOneWidget);
      expect(find.text('Ask Mentor'), findsOneWidget);
      // Verify sections
      expect(find.text('My classes'), findsOneWidget);
      expect(find.text('Upcoming schedule'), findsOneWidget);
      expect(find.text('Due soon'), findsWidgets);
      expect(find.text('Recent materials'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Ask Pragti AI Mentor'), 300);
      expect(find.text('Ask Pragti AI Mentor'), findsOneWidget);

      // Ensure no flutter overflow errors
      expect(tester.takeException(), isNull);
    });
  });
}
