import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/application/auth_providers.dart';
import 'package:mobile/features/auth/data/mock_auth_repository.dart';
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

  group('Part C: AppDrawer & Hamburger Menu Tests', () {
    testWidgets('Three-line menu icon is present on AppBar and opens AppDrawer', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestHome());
      await tester.pumpAndSettle();

      // Find hamburger menu icon
      final menuIconFinder = find.byIcon(Icons.menu_rounded);
      expect(menuIconFinder, findsOneWidget);

      // Tap hamburger to open drawer
      await tester.tap(menuIconFinder);
      await tester.pumpAndSettle();

      // Verify AppDrawer opened
      expect(find.byType(AppDrawer), findsOneWidget);
      expect(find.text('Demo Student'), findsOneWidget);
      expect(find.text('Student'), findsWidgets);
    });

    testWidgets('AppDrawer renders rich navigation items and badges', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 960));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestHome(
        mockClasses: [
          const ClassroomItem(
            id: 'c1',
            name: 'Advanced Physics',
            subject: 'Physics',
            teacher: 'Prof Newton',
            schedule: 'Mon, Wed 10:00 AM',
            room: 'Room 301',
            studentCount: 18,
            code: 'PHY401',
          ),
        ],
        mockAssignments: [
          const AssignmentItem(
            id: 'a1',
            title: 'Quantum Mechanics Problem Set',
            subject: 'Physics',
            description: 'Solve problems 1-5',
            classId: 'c1',
            dueDate: 'Tomorrow',
            points: 100,
            status: AssignmentStatus.pending,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      // Check navigation items inside AppDrawer
      Finder drawerText(String text) => find.descendant(
            of: find.byType(AppDrawer),
            matching: find.text(text),
          );

      expect(drawerText('Dashboard Overview'), findsOneWidget);
      expect(drawerText('My Classes'), findsOneWidget);
      expect(drawerText('Assignments'), findsOneWidget);
      expect(drawerText('Study Planner & To-Do'), findsOneWidget);
      expect(drawerText('Learning Materials'), findsOneWidget);
      expect(drawerText('Weekly Schedule'), findsOneWidget);
      expect(drawerText('Attendance Records'), findsOneWidget);
      expect(drawerText('Live Video Meetings'), findsOneWidget);
      expect(drawerText('AI Mentor Tutor'), findsOneWidget);
      expect(drawerText('Settings & Preferences'), findsOneWidget);
      expect(drawerText('Help Desk & FAQ'), findsOneWidget);
      expect(drawerText('Sign Out'), findsOneWidget);

      // Verify class count badge (1) and assignment badge count (1) are both present in drawer
      expect(drawerText('1'), findsNWidgets(2));
    });

    testWidgets('AppDrawer My Classes expands and displays enrolled classes', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestHome(
        mockClasses: [
          const ClassroomItem(
            id: 'c10',
            name: 'Cell Biology',
            subject: 'Biology',
            teacher: 'Dr. Darwin',
            schedule: 'Tue, Thu 2:00 PM',
            room: 'Lab 102',
            studentCount: 24,
            code: 'BIO101',
          ),
        ],
      ));
      await tester.pumpAndSettle();

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      // Tap on My Classes ExpansionTile to expand
      await tester.tap(find.text('My Classes'));
      await tester.pumpAndSettle();

      expect(find.text('View All Classrooms'), findsOneWidget);
      expect(find.text('Cell Biology'), findsOneWidget);
      expect(find.text('Biology'), findsOneWidget);
    });

    testWidgets('AppDrawer Sign Out shows confirmation dialog', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestHome());
      await tester.pumpAndSettle();

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      // Scroll to bottom to ensure Sign Out is visible
      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Sign Out'), findsOneWidget);
      expect(find.text('Are you sure you want to sign out?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Cancel leaves dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Confirm Sign Out'), findsNothing);
    });

    testWidgets('Wide screen layout renders hamburger menu icon in AppBar and opens drawer', (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestHome(size: const Size(900, 700)));
      await tester.pumpAndSettle();

      // Hamburger menu icon in wide AppBar
      final menuIconFinder = find.byIcon(Icons.menu_rounded);
      expect(menuIconFinder, findsOneWidget);

      await tester.tap(menuIconFinder);
      await tester.pumpAndSettle();

      expect(find.byType(AppDrawer), findsOneWidget);
    });
  });
}
