import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/providers/network_providers.dart';
import 'package:mobile/features/home/domain/home_repository.dart';
import 'package:mobile/features/home/presentation/home_providers.dart';
import 'package:mobile/features/home/presentation/widgets/create_assignment_dialog.dart';
import 'package:mobile/features/mentor/presentation/mentor_screen.dart';

class _MockDioAdapter implements HttpClientAdapter {
  _MockDioAdapter({required this.handler});

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }
}

class _TestHomeRepository implements HomeRepository {
  @override
  Future<AssignmentItem> createAssignment({
    required String classId,
    required String title,
    required String subject,
    required String dueDate,
    required int points,
    String? description,
    String? createdBy,
    String? attachmentUrl,
    String? attachmentName,
    SelectedAttachmentItem? file,
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
    void Function(int sent, int total)? onProgress,
  }) async {
    return AssignmentItem(
      id: 'assign-batch1-101',
      classId: classId,
      title: title,
      subject: subject,
      dueDate: dueDate,
      points: points,
      status: AssignmentStatus.pending,
      description: description ?? '',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Batch 1 Bug 1: Create Assignment Dialog Return Type Tests', () {
    testWidgets(
      'CreateAssignmentDialog pops AssignmentItem and showDialog<AssignmentItem> succeeds without type error',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        AssignmentItem? poppedItem;
        bool invalidateCalled = false;

        final container = ProviderContainer(
          overrides: [
            homeRepositoryProvider.overrideWithValue(_TestHomeRepository()),
            classroomsProvider.overrideWith((ref) async => [
                  const ClassroomItem(
                    id: 'class-math-1',
                    name: 'Advanced Calculus',
                    subject: 'Mathematics',
                    teacher: 'Dr. Euler',
                    schedule: 'Mon, Wed 10:00 AM',
                    room: 'Room 302',
                    studentCount: 15,
                  ),
                ]),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () async {
                        poppedItem = await showDialog<AssignmentItem>(
                          context: context,
                          builder: (_) => const CreateAssignmentDialog(),
                        );
                        if (poppedItem != null) {
                          invalidateCalled = true;
                        }
                      },
                      child: const Text('Open Dialog'),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap to open dialog
        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Create Assignment'), findsOneWidget);

        // Enter assignment details
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Assignment Title *'),
          'Integration by Parts Problem Set',
        );

        // Submit assignment
        await tester.tap(find.text('Publish Assignment'));
        await tester.pumpAndSettle();

        // Dialog should be popped successfully with the AssignmentItem
        expect(poppedItem, isNotNull);
        expect(poppedItem!.title, equals('Integration by Parts Problem Set'));
        expect(poppedItem!.id, equals('assign-batch1-101'));
        expect(invalidateCalled, isTrue);

        // No type error snackbar or alert displayed
        expect(
          find.textContaining('is not a subtype of type'),
          findsNothing,
        );
      },
    );
  });

  group('Batch 1 Bug 2: AI Mentor Markdown & HTML Break Rendering Tests', () {
    testWidgets(
      'Renders AI reply with MarkdownBody, replacing <br> and formatting bold, headers, and tables',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final dio = Dio();
        dio.httpClientAdapter = _MockDioAdapter(
          handler: (options) async {
            if (options.path == '/api/mentor/health') {
              return ResponseBody.fromString('{"success":true}', 200);
            }
            if (options.path == '/api/mentor/chat') {
              // Return markdown response with <br>, headers, bold, list, and tables
              const replyMarkdown =
                  '### Calculus Breakdown<br>Here are the key formulas:<br><br>'
                  '| Rule | Formula |<br>'
                  '| :--- | :--- |<br>'
                  '| Power | d/dx[x^n] = n*x^(n-1) |<br>'
                  '| Product | (uv)\' = u\'v + uv\' |<br><br>'
                  'Remember: **always add the integration constant** +C.<br>'
                  '- Step 1: Identify terms<br>'
                  '- Step 2: Apply rule';

              return ResponseBody.fromString(
                jsonEncode({'success': true, 'reply': replyMarkdown}),
                200,
                headers: {
                  Headers.contentTypeHeader: [Headers.jsonContentType],
                },
              );
            }
            return ResponseBody.fromString('{}', 200);
          },
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              coreDioProvider.overrideWithValue(dio),
            ],
            child: const MaterialApp(
              themeMode: ThemeMode.light,
              home: MentorScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Send a user question
        await tester.enterText(
          find.byType(TextField),
          'Show me calculus derivatives table',
        );
        await tester.testTextInput.receiveAction(TextInputAction.send);
        await tester.pumpAndSettle();

        // 1. User message is plain text
        expect(
          find.widgetWithText(SelectableText, 'Show me calculus derivatives table'),
          findsOneWidget,
        );

        // 2. AI reply is rendered via MarkdownBody including tables
        expect(find.byType(MarkdownBody), findsOneWidget);
        expect(find.byType(Table), findsOneWidget);

        // 3. Raw "<br>" is NOT displayed
        expect(find.textContaining('<br>'), findsNothing);
        expect(find.textContaining('<br/>'), findsNothing);
      },
    );
  });
}
