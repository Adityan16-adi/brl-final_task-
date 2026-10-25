import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/clay_theme.dart';
import 'package:mobile/features/auth/application/auth_providers.dart';
import 'package:mobile/features/auth/data/mock_auth_repository.dart';
import 'package:mobile/features/home/data/home_repository_impl.dart';
import 'package:mobile/features/home/domain/home_repository.dart';
import 'package:mobile/features/home/presentation/home_providers.dart';
import 'package:mobile/features/home/presentation/screens/classroom_detail_screen.dart';

void _setDimensions(WidgetTester tester) {
  tester.view.physicalSize = const Size(412, 892);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('Step 3: Attendance Models Unit Tests', () {
    test('AttendanceRecordItem serialization and deserialization', () {
      const item = AttendanceRecordItem(
        studentUid: 'student-101',
        studentName: 'Alice Walker',
        status: 'present',
        remarks: 'Great effort',
      );

      final json = item.toJson();
      expect(json['studentUid'], 'student-101');
      expect(json['studentName'], 'Alice Walker');
      expect(json['status'], 'present');
      expect(json['remarks'], 'Great effort');

      final fromJson = AttendanceRecordItem.fromJson(json);
      expect(fromJson.studentUid, 'student-101');
      expect(fromJson.studentName, 'Alice Walker');
      expect(fromJson.status, 'present');
      expect(fromJson.remarks, 'Great effort');
    });

    test('AttendanceSession calculates present, late, absent counts correctly', () {
      final session = AttendanceSession(
        id: 'sess-01',
        classId: 'class-01',
        sessionDate: DateTime(2026, 10, 25),
        topic: 'Introductory Mechanics',
        records: const [
          AttendanceRecordItem(
            studentUid: 's1',
            studentName: 'Alice',
            status: 'present',
          ),
          AttendanceRecordItem(
            studentUid: 's2',
            studentName: 'Bob',
            status: 'present',
          ),
          AttendanceRecordItem(
            studentUid: 's3',
            studentName: 'Charlie',
            status: 'late',
          ),
          AttendanceRecordItem(
            studentUid: 's4',
            studentName: 'David',
            status: 'absent',
          ),
        ],
      );

      expect(session.presentCount, 2);
      expect(session.lateCount, 1);
      expect(session.absentCount, 1);
      expect(session.records.length, 4);
    });

    test('StudentAttendanceSummary handles percentages and sessions', () {
      const summary = StudentAttendanceSummary(
        totalSessions: 10,
        presentCount: 8,
        absentCount: 1,
        lateCount: 1,
        percentage: 85,
        sessions: [
          {
            'attendanceId': 'att-1',
            'topic': 'Kinematics',
            'status': 'present',
            'sessionDate': '2026-10-24T10:00:00.000Z',
          },
        ],
      );

      expect(summary.totalSessions, 10);
      expect(summary.presentCount, 8);
      expect(summary.percentage, 85);
      expect(summary.sessions.length, 1);
    });
  });

  group('Step 3: Teacher Attendance UI Flow Tests', () {
    const testClass = ClassroomItem(
      id: 'class-att-test',
      name: 'Advanced Astrophysics',
      subject: 'Astronomy',
      teacher: 'Prof. Kepler',
      schedule: 'Mon, Wed 10:00 AM',
      room: 'Observatory Room',
      studentCount: 3,
      code: 'ASTRO1',
    );

    testWidgets('Teacher switches to Attendance tab, marks attendance, and saves', (
      tester,
    ) async {
      _setDimensions(tester);

      final inMemoryRepo = InMemoryHomeRepository();
      final authRepo = MockAuthRepository(
        initialUser: MockAuthRepository.teacherUser,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(authRepo),
            homeRepositoryProvider.overrideWithValue(inMemoryRepo),
          ],
          child: const MaterialApp(
            home: ClassroomDetailScreen(classroom: testClass),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Attendance tab button exists and switch to it
      expect(find.text('Attendance'), findsOneWidget);
      await tester.ensureVisible(find.text('Attendance'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Attendance'));
      await tester.pumpAndSettle();

      // Verify Attendance Register header
      expect(find.text('Attendance Register'), findsOneWidget);
      expect(find.text('Session Topic / Remarks'), findsOneWidget);
      expect(find.text('All Present'), findsOneWidget);
      expect(find.text('All Absent'), findsOneWidget);
      expect(find.text('Save Attendance Record'), findsOneWidget);

      // Tap "All Absent" shortcut
      await tester.ensureVisible(find.text('All Absent'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('All Absent'));
      await tester.pumpAndSettle();

      // Tap "Save Attendance Record"
      await tester.ensureVisible(find.text('Save Attendance Record'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Attendance Record'));
      await tester.pumpAndSettle();

      // Expect confirmation message
      expect(find.text('Attendance recorded successfully!'), findsOneWidget);
    });
  });

  group('Step 3: Student Attendance UI Flow Tests', () {
    const testClass = ClassroomItem(
      id: 'class-student-att-test',
      name: 'Organic Chemistry Lab',
      subject: 'Chemistry',
      teacher: 'Dr. Mendeleev',
      schedule: 'Fri 02:00 PM',
      room: 'Lab 4',
      studentCount: 12,
      code: 'CHEM99',
    );

    testWidgets('Student switches to Attendance tab and views summary and metrics', (
      tester,
    ) async {
      _setDimensions(tester);

      final inMemoryRepo = InMemoryHomeRepository();
      final authRepo = MockAuthRepository(
        initialUser: MockAuthRepository.studentUser,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(authRepo),
            homeRepositoryProvider.overrideWithValue(inMemoryRepo),
          ],
          child: const MaterialApp(
            home: ClassroomDetailScreen(classroom: testClass),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Attendance tab
      await tester.ensureVisible(find.text('Attendance'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Attendance'));
      await tester.pumpAndSettle();

      // Verify Student Attendance summary card
      expect(find.text('My Attendance Summary'), findsOneWidget);
      expect(find.text('Overall standing across all classes'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Present'), findsWidgets);
      expect(find.text('Late'), findsWidgets);
      expect(find.text('Absent'), findsWidgets);
    });
  });
}
