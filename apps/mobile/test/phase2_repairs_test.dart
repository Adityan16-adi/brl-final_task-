import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/application/auth_providers.dart';
import 'package:mobile/features/auth/data/mock_auth_repository.dart';
import 'package:mobile/features/home/data/home_repository_impl.dart';
import 'package:mobile/features/home/domain/home_repository.dart';
import 'package:mobile/features/home/presentation/home_providers.dart';
import 'package:mobile/features/home/presentation/screens/classroom_detail_screen.dart';
import 'package:mobile/features/home/presentation/widgets/assignments_view.dart';
import 'package:mobile/features/home/presentation/widgets/create_assignment_dialog.dart';
import 'package:mobile/features/home/presentation/widgets/create_class_dialog.dart';
import 'package:mobile/features/home/presentation/widgets/schedule_view.dart';
import 'package:mobile/features/home/presentation/widgets/submit_assignment_dialog.dart';

void _setDimensions(WidgetTester tester) {
  tester.view.physicalSize = const Size(412, 892);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('Phase 2 Classroom Scheduling & Hub Tests', () {
    testWidgets(
      'CreateClassDialog offers date, time, duration, and Start Now switch',
      (tester) async {
        _setDimensions(tester);

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: Scaffold(body: CreateClassDialog())),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Create a Classroom'), findsOneWidget);
        expect(find.text('Start Class Session Now'), findsOneWidget);
        expect(find.byType(Switch), findsOneWidget);
        expect(
          find.text('Pick Date'),
          findsNothing,
        ); // Date button displays formatted date
        expect(find.text('Schedule (Optional)'), findsOneWidget);

        // Toggle Start Now switch
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();

        expect(find.text('Started Now · Live Session'), findsOneWidget);
        expect(find.text('Start Classroom Now'), findsOneWidget);
      },
    );

    testWidgets(
      'ClassroomDetailScreen renders meeting lobby, readiness controls, and coursework',
      (tester) async {
        _setDimensions(tester);

        const testClass = ClassroomItem(
          id: 'class-test-01',
          name: 'Quantum Optics Seminar',
          subject: 'Physics',
          teacher: 'Dr. Jane Smith',
          schedule: 'Started Now · Live Session',
          room: 'Virtual Room',
          studentCount: 15,
          code: 'QUANT24',
        );

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ClassroomDetailScreen(classroom: testClass),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Classroom Hub'), findsOneWidget);
        expect(find.text('Quantum Optics Seminar'), findsOneWidget);
        expect(find.text('CODE: QUANT24'), findsOneWidget);
        expect(find.text('Active Class Session · In Progress'), findsOneWidget);

        // Meeting room section
        expect(find.text('Live Class Lobby (Active)'), findsOneWidget);
        expect(find.text('Lobby Readiness Test'), findsOneWidget);
        expect(find.text('Mic: Ready'), findsOneWidget);
        expect(find.text('Cam: Ready'), findsOneWidget);

        // Toggle readiness buttons
        await tester.tap(find.text('Mic: Ready'));
        await tester.pumpAndSettle();
        expect(find.text('Mic: Muted'), findsOneWidget);

        // Switch to Coursework tab
        await tester.tap(find.text('Coursework'));
        await tester.pumpAndSettle();
        expect(find.text('Assignments & Tasks'), findsOneWidget);

        // Switch to Learners tab
        await tester.tap(find.text('Learners'));
        await tester.pumpAndSettle();
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );
  });

  group('Phase 2 Assignment Creation & Submission Tests', () {
    testWidgets(
      'CreateAssignmentDialog includes attachment link, due date picker and validated fields',
      (tester) async {
        _setDimensions(tester);

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: Scaffold(body: CreateAssignmentDialog())),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Create Assignment'), findsOneWidget);
        expect(
          find.text('Attachment / Reference URL (Optional)'),
          findsOneWidget,
        );
        expect(find.text('Publish Assignment'), findsOneWidget);
        expect(find.byIcon(Icons.edit_calendar_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'SubmitAssignmentDialog allows entering text and attachment URL',
      (tester) async {
        _setDimensions(tester);

        const testAssign = AssignmentItem(
          id: 'assign-test-101',
          title: 'Wave Equations Proof',
          subject: 'Physics',
          dueDate: 'Tomorrow',
          points: 25,
          status: AssignmentStatus.pending,
          description: 'Derive wave propagation formula.',
        );

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SubmitAssignmentDialog(assignment: testAssign),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Wave Equations Proof'), findsOneWidget);
        expect(
          find.text('Submission Attachment / Document Link (Optional)'),
          findsOneWidget,
        );
        expect(find.text('Turn In'), findsOneWidget);

        // Submitting without entering text or link shows error
        await tester.tap(find.text('Turn In'));
        await tester.pumpAndSettle();

        expect(
          find.text('Please enter written notes or attach a file link'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Submitted assignment reflects submitted status in AssignmentsView',
      (tester) async {
        _setDimensions(tester);

        final inMemoryRepo = InMemoryHomeRepository();
        // Submit an assignment using real async zone so Future.delayed resolves
        await tester.runAsync(() async {
          await inMemoryRepo.submitAssignment(
            'assign-cell-notes',
            'Here is my completed concept map.',
            fileUrl: 'https://docs.example.com/cell-map.pdf',
          );
        });

        final authRepo = MockAuthRepository(
          initialUser: MockAuthRepository.studentUser,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(authRepo),
              homeRepositoryProvider.overrideWithValue(inMemoryRepo),
            ],
            child: const MaterialApp(home: Scaffold(body: AssignmentsView())),
          ),
        );
        await tester.pumpAndSettle();

        // assign-cell-notes is now Submitted, not Pending
        expect(find.text('Submitted'), findsWidgets);
      },
    );
  });

  group('Phase 2 Calendar & Schedule Tests', () {
    testWidgets(
      'ScheduleView renders filter chips and notification center alert',
      (tester) async {
        _setDimensions(tester);

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: Scaffold(body: ScheduleView())),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('All'), findsOneWidget);
        expect(find.text('Today'), findsOneWidget);
        expect(find.text('Lectures'), findsOneWidget);
        expect(find.text('Deadlines'), findsOneWidget);
        expect(find.byIcon(Icons.notifications_rounded), findsOneWidget);

        // Tap notifications center
        await tester.tap(find.byIcon(Icons.notifications_rounded));
        await tester.pumpAndSettle();

        expect(find.text('Classroom Reminders & Alerts'), findsOneWidget);
      },
    );
  });
}
