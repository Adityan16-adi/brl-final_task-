import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
  const testClass = ClassroomItem(
    id: 'class-meet-01',
    name: 'Quantum Mechanics 401',
    subject: 'Physics',
    teacher: 'Dr. Feynman',
    schedule: 'Flexible Online',
    room: 'Hall B',
    studentCount: 14,
    code: 'QM401',
  );

  group('Step 6: Live Meeting Link & Jitsi / Google Meet Fallback Tests', () {
    testWidgets('Teacher sees Web Meeting Link card with default Jitsi room and teacher actions', (
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

      // Ensure Web Meeting Link card is visible
      await tester.ensureVisible(find.text('Web Meeting Link'));
      await tester.pumpAndSettle();

      expect(find.text('Web Meeting Link'), findsOneWidget);
      expect(find.text('Jitsi / Google Meet Fallback'), findsOneWidget);
      expect(find.text('ZERO-CONFIG'), findsOneWidget);
      expect(find.text('https://meet.jit.si/UnifiedLearn-QM401'), findsOneWidget);

      // Verify Teacher controls
      expect(find.text('Launch Zero-Config Meeting'), findsOneWidget);
      expect(find.text('Copy Meeting Link'), findsOneWidget);
      expect(find.text('Set Custom Meet / Zoom Link'), findsOneWidget);

      // Tap Copy Meeting Link
      await tester.ensureVisible(find.text('Copy Meeting Link'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy Meeting Link'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Meeting link copied to clipboard'), findsOneWidget);

      // Dismiss the SnackBar so it doesn't block taps
      ScaffoldMessenger.of(
        tester.element(find.byType(ClassroomDetailScreen)),
      ).clearSnackBars();
      await tester.pumpAndSettle();

      // Tap Set Custom Meet / Zoom Link
      await tester.ensureVisible(find.text('Set Custom Meet / Zoom Link'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Set Custom Meet / Zoom Link'));
      await tester.pumpAndSettle();

      expect(find.text('Custom Meeting Link'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);

      // Enter a custom Google Meet URL
      await tester.enterText(
        find.byType(TextFormField),
        'https://meet.google.com/abc-defg-hij',
      );
      await tester.pump();

      // Tap Save Link
      await tester.tap(find.text('Save Link'));
      await tester.pumpAndSettle();

      // Verify that the custom link is now displayed
      expect(find.text('https://meet.google.com/abc-defg-hij'), findsOneWidget);
      expect(find.text('Custom meeting link saved!'), findsOneWidget);
    });

    testWidgets('Student sees Web Meeting Link card with student join and copy controls', (
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

      // Verify Meeting Lobby Web Meeting Link card
      await tester.ensureVisible(find.text('Web Meeting Link'));
      await tester.pumpAndSettle();

      expect(find.text('Web Meeting Link'), findsOneWidget);
      expect(find.text('https://meet.jit.si/UnifiedLearn-QM401'), findsOneWidget);

      // Student controls
      expect(find.text('Join via Web / Meet Link'), findsOneWidget);
      expect(find.text('Copy Link'), findsOneWidget);

      // Tap Join via Web / Meet Link
      await tester.ensureVisible(find.text('Join via Web / Meet Link'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Join via Web / Meet Link'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Meeting link copied to clipboard! Open in any browser:'),
        findsOneWidget,
      );
    });
  });
}
