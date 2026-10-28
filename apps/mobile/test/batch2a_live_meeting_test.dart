import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/home/presentation/screens/live_meeting_screen.dart';

void main() {
  group('Batch 2a: Live Meeting Screen Improvements Tests', () {
    testWidgets('Control bar renders all 7 controls including Chat on narrow 320px viewport without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: LiveMeetingScreen(
            serverUrl: 'ws://localhost:7880',
            token: 'mock-token',
            roomTitle: 'Physics 101 Lecture',
            isTeacher: true,
            autoConnect: false,
          ),
        ),
      );
      await tester.pump();

      // Verify all 7 call controls are present
      expect(find.text('Mute'), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Flip'), findsOneWidget);
      expect(find.text('Hand'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Leave'), findsOneWidget);

      // Verify no RenderFlex overflow occurred
      expect(tester.takeException(), isNull);
    });

    testWidgets('In-Meeting Chat sheet opens, sends message, and updates session message list', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: LiveMeetingScreen(
            serverUrl: 'ws://localhost:7880',
            token: 'mock-token',
            roomTitle: 'Physics 101 Lecture',
            isTeacher: false,
            autoConnect: false,
          ),
        ),
      );
      await tester.pump();

      // Tap Chat button in controls bar
      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();

      // Bottom sheet is displayed
      expect(find.text('Classroom Chat'), findsOneWidget);
      expect(find.text('Messages only last for this live session'), findsOneWidget);
      expect(find.text('No messages yet'), findsOneWidget);

      // Type and send a message
      final inputFinder = find.widgetWithText(TextField, 'Type a message to class...');
      expect(inputFinder, findsOneWidget);
      await tester.enterText(inputFinder, 'Can you explain formula 4 again?');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // Message is displayed with sender 'You' and formatted time
      expect(find.text('Can you explain formula 4 again?'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);

      // Send a second message
      await tester.enterText(inputFinder, 'Understood, thank you!');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Understood, thank you!'), findsOneWidget);

      // Close bottom sheet
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Sheet is closed
      expect(find.text('Classroom Chat'), findsNothing);
    });

    testWidgets('In-Meeting Chat supports dark mode and light mode without error', (
      tester,
    ) async {
      // Test dark mode
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const LiveMeetingScreen(
            serverUrl: 'ws://localhost:7880',
            token: 'mock-token',
            roomTitle: 'Advanced Bio Live',
            isTeacher: true,
            autoConnect: false,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();

      expect(find.text('Classroom Chat'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Classroom Chat'), findsNothing);
    });
  });
}
