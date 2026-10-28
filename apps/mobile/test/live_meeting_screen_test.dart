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

    testWidgets('Chat button opens in-meeting chat bottom sheet and sends message', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LiveMeetingScreen(
            serverUrl: 'ws://localhost:7880',
            token: 'mock-token',
            roomTitle: 'Physics 101 Live Class',
            isTeacher: true,
            autoConnect: false,
          ),
        ),
      );
      await tester.pump();

      // Chat button is present in control bar
      expect(find.text('Chat'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);

      // Tap Chat to open sheet
      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();

      // Verify chat sheet elements
      expect(find.text('Classroom Chat'), findsOneWidget);
      expect(find.text('No messages yet'), findsOneWidget);

      // Enter a chat message and send
      await tester.enterText(
        find.widgetWithText(TextField, 'Type a message to class...'),
        'Welcome students, class has started!',
      );
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // Verify message is added to chat
      expect(find.text('Welcome students, class has started!'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);

      // Close the chat sheet
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Classroom Chat'), findsNothing);
    });
  });
}
