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
  group('Step 4: Chat & Spam Models Unit Tests', () {
    test('ChatMessageItem serialization and deserialization', () {
      final now = DateTime(2026, 10, 25, 14, 30);
      final item = ChatMessageItem(
        id: 'msg-01',
        classId: 'class-123',
        senderUid: 'user-01',
        senderName: 'Prof. Kepler',
        senderRole: 'teacher',
        text: 'Exam date is confirmed for next Monday.',
        createdAt: now,
      );

      expect(item.isTeacher, isTrue);
      final json = item.toJson();
      expect(json['id'], 'msg-01');
      expect(json['classId'], 'class-123');
      expect(json['text'], 'Exam date is confirmed for next Monday.');

      final fromJson = ChatMessageItem.fromJson(json);
      expect(fromJson.id, 'msg-01');
      expect(fromJson.senderName, 'Prof. Kepler');
      expect(fromJson.isTeacher, isTrue);
    });

    test('SpamCheckResult serialization and deserialization', () {
      const result = SpamCheckResult(
        isSpam: true,
        score: 3,
        action: 'block',
        reasons: ['Repeated characters', 'Flood'],
      );
      expect(result.isSpam, isTrue);

      final json = {
        'is_spam': true,
        'score': 3,
        'action': 'block',
        'reasons': ['Repeated characters', 'Flood'],
      };

      final parsed = SpamCheckResult.fromJson(json);
      expect(parsed.isSpam, isTrue);
      expect(parsed.score, 3);
      expect(parsed.action, 'block');
      expect(parsed.reasons.length, 2);
    });

    test('InMemoryHomeRepository spam check flags suspicious text correctly', () async {
      final repo = InMemoryHomeRepository();

      // Normal text passes
      final clean = await repo.checkSpam(
        meetingId: 'meet-1',
        userId: 'u1',
        message: 'Hello class, where is the homework link?',
      );
      expect(clean.isSpam, isFalse);

      // Character repetition spam
      final spamChars = await repo.checkSpam(
        meetingId: 'meet-1',
        userId: 'u1',
        message: 'Heeeeeeeeeeelllllllllllloooooooooooo',
      );
      expect(spamChars.isSpam, isTrue);
      expect(spamChars.reasons, contains('Repeated characters'));

      // Link flooding spam
      final spamLinks = await repo.checkSpam(
        meetingId: 'meet-1',
        userId: 'u1',
        message: 'Click https://sp1.com and https://sp2.com and https://sp3.com now!',
      );
      expect(spamLinks.isSpam, isTrue);
      expect(spamLinks.reasons, contains('Excessive external links'));
    });
  });

  group('Step 4: Classroom Chat UI & Spam Blocking Flow Tests', () {
    const testClass = ClassroomItem(
      id: 'class-chat-test',
      name: 'Modern Astrophysics',
      subject: 'Astronomy',
      teacher: 'Prof. Kepler',
      schedule: 'Daily 10:00 AM',
      room: 'Virtual Room',
      studentCount: 5,
      code: 'ASTRO2',
    );

    testWidgets('Classroom Chat renders messages and allows sending clean messages', (
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

      // Switch to Chat tab
      expect(find.text('Chat'), findsOneWidget);
      await tester.ensureVisible(find.text('Chat'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();

      // Verify Chat screen header and input
      expect(find.text('ML Spam Filter Active · Secure Channel'), findsOneWidget);
      expect(find.text('Type a classroom message...'), findsOneWidget);

      // Enter normal message and send
      await tester.enterText(
        find.widgetWithText(TextField, 'Type a classroom message...'),
        'What chapters are covered in the upcoming quiz?',
      );
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // Message should appear in chat
      expect(
        find.text('What chapters are covered in the upcoming quiz?'),
        findsOneWidget,
      );
    });

    testWidgets('Classroom Chat blocks spam message and displays warning SnackBar', (
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

      // Switch to Chat tab
      await tester.ensureVisible(find.text('Chat'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();

      // Enter repeated character spam
      await tester.enterText(
        find.widgetWithText(TextField, 'Type a classroom message...'),
        'Spammmmmmmmmmmmmmmmm text flooding',
      );
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // Verify SnackBar warning appears
      expect(
        find.text('Message blocked by spam filter: Repeated characters'),
        findsOneWidget,
      );

      // Verify the spam message was NOT posted into the chat list
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && w.data == 'Spammmmmmmmmmmmmmmmm text flooding',
        ),
        findsNothing,
      );
      final msgs = await inMemoryRepo.getClassMessages(testClass.id);
      expect(msgs.any((m) => m.text.contains('Spammmmmmmmmmmmmmmmm')), isFalse);
    });
  });
}
