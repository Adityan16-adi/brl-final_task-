import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/home/presentation/screens/live_meeting_screen.dart';

void main() {
  group('LiveMeetingScreen Controls & UI Tests', () {
    testWidgets('Renders all 6 call controls: Mute, Camera, Flip, Hand, Share, Leave', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LiveMeetingScreen(
            serverUrl: 'ws://localhost:7880',
            token: 'mock-token',
            roomTitle: 'Physics 101 Live Class',
            isTeacher: false,
            autoConnect: false,
          ),
        ),
      );
      await tester.pump();

      // Verify Title and Live badge
      expect(find.text('Physics 101 Live Class'), findsOneWidget);
      expect(find.textContaining('LIVE'), findsOneWidget);

      // Verify all 6 control buttons
      expect(find.text('Mute'), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Flip'), findsOneWidget);
      expect(find.text('Hand'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Leave'), findsOneWidget);

      // Tap Hand to toggle raise hand state
      await tester.tap(find.text('Hand'));
      await tester.pump();

      // Label switches to 'Lower'
      expect(find.text('Lower'), findsOneWidget);

      // Tap again to lower hand
      await tester.tap(find.text('Lower'));
      await tester.pump();

      expect(find.text('Hand'), findsOneWidget);

      // Tap Mute to toggle mute
      await tester.tap(find.text('Mute'));
      await tester.pump();
      expect(find.text('Unmute'), findsOneWidget);

      // Tap Camera to toggle camera
      await tester.tap(find.text('Camera'));
      await tester.pump();
      expect(find.text('Start Cam'), findsOneWidget);
    });

    testWidgets('Leave button pops the meeting screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const LiveMeetingScreen(
                        serverUrl: 'ws://localhost:7880',
                        token: 'mock-token',
                        roomTitle: 'Chemistry Lecture',
                        isTeacher: true,
                        autoConnect: false,
                      ),
                    ),
                  );
                },
                child: const Text('Open Meeting'),
              );
            },
          ),
        ),
      );

      // Open meeting
      await tester.tap(find.text('Open Meeting'));
      await tester.pumpAndSettle();

      expect(find.text('Chemistry Lecture'), findsOneWidget);
      expect(find.text('Leave'), findsOneWidget);

      // Tap Leave
      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();

      // Screen is popped back to original page
      expect(find.text('Open Meeting'), findsOneWidget);
      expect(find.text('Chemistry Lecture'), findsNothing);
    });
  });
}
