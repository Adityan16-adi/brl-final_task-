import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/application/auth_providers.dart';
import 'package:mobile/features/auth/data/mock_auth_repository.dart';
import 'package:mobile/features/home/data/home_repository_impl.dart';
import 'package:mobile/features/home/data/http_home_repository.dart';
import 'package:mobile/features/home/domain/home_repository.dart';
import 'package:mobile/features/home/presentation/home_providers.dart';
import 'package:mobile/features/home/presentation/widgets/classrooms_view.dart';
import 'package:mobile/features/home/presentation/widgets/join_class_dialog.dart';

void _setDimensions(WidgetTester tester) {
  tester.view.physicalSize = const Size(412, 892);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('HttpHomeRepository Unit Tests', () {
    test('createClassroom parses response correctly on 201', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 201,
                data: {
                  'success': true,
                  'message': 'Classroom created successfully',
                  'classroom': {
                    '_id': 'class-123',
                    'name': 'Quantum Physics',
                    'subject': 'Physics',
                    'code': 'QUANTUM1',
                    'teacherName': 'Dr. Curie',
                    'students': [],
                  },
                },
              ),
            );
          },
        ),
      );

      final repo = HttpHomeRepository(dio: dio);
      final item = await repo.createClassroom(
        name: 'Quantum Physics',
        subject: 'Physics',
      );

      expect(item.id, 'class-123');
      expect(item.name, 'Quantum Physics');
      expect(item.code, 'QUANTUM1');
    });

    test(
      'createClassroom throws ClassroomException on 400 missing fields',
      () async {
        final dio = Dio();
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              return handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response(
                    requestOptions: options,
                    statusCode: 400,
                    data: {
                      'success': false,
                      'message': 'Classroom name is required',
                    },
                  ),
                ),
              );
            },
          ),
        );

        final repo = HttpHomeRepository(dio: dio);
        expect(
          () => repo.createClassroom(name: '', subject: 'Physics'),
          throwsA(
            isA<ClassroomException>().having(
              (e) => e.message,
              'message',
              'Classroom name is required',
            ),
          ),
        );
      },
    );

    test('joinClassroom parses response on 200', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'message': 'Joined classroom successfully',
                  'classroom': {
                    '_id': 'class-456',
                    'name': 'Cell Biology',
                    'code': 'CELL24',
                    'students': ['student-01'],
                  },
                },
              ),
            );
          },
        ),
      );

      final repo = HttpHomeRepository(dio: dio);
      final item = await repo.joinClassroom('CELL24');
      expect(item.id, 'class-456');
      expect(item.name, 'Cell Biology');
    });

    test('joinClassroom throws ClassroomException with server message on 409 conflict', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 409,
                  data: {
                    'success': false,
                    'message': 'Already joined this classroom',
                  },
                ),
              ),
            );
          },
        ),
      );

      final repo = HttpHomeRepository(dio: dio);
      expect(
        () => repo.joinClassroom('CELL24'),
        throwsA(
          isA<ClassroomException>().having(
            (e) => e.message,
            'message',
            'Already joined this classroom',
          ),
        ),
      );
    });
  });

  group('Classroom UI Workflow Widget Tests', () {
    testWidgets(
      'Teacher views classrooms: sees Create Class button, creates classroom successfully',
      (tester) async {
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
            child: const MaterialApp(home: Scaffold(body: ClassroomsView())),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Check Create Class button is displayed for teacher
        expect(find.text('Create Class'), findsOneWidget);
        expect(find.text('Join Code'), findsNothing);

        // 2. Open Create Class Dialog
        await tester.tap(find.text('Create Class'));
        await tester.pumpAndSettle();

        expect(find.text('Create a Classroom'), findsOneWidget);
        expect(find.text('Class Name *'), findsOneWidget);
        expect(find.text('Subject *'), findsOneWidget);

        // 3. Submit empty form -> validation fails
        await tester.tap(
          find.widgetWithText(FilledButton, 'Create Class').last,
        );
        await tester.pumpAndSettle();
        expect(find.text('Please enter a classroom name'), findsOneWidget);

        // 4. Fill in valid data and submit
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Class Name *'),
          'Advanced Astrophysics',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Subject *'),
          'Astronomy',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Schedule (Optional)'),
          'Tue, Thu 02:00 PM',
        );

        await tester.tap(
          find.widgetWithText(FilledButton, 'Create Class').last,
        );
        await tester.pumpAndSettle();

        // 5. Success screen in dialog shows shareable join code
        expect(find.text('Classroom Created!'), findsOneWidget);
        expect(find.text('SHAREABLE JOIN CODE'), findsOneWidget);
        expect(find.text('Copy Code'), findsOneWidget);

        // 6. Dismiss dialog and verify class list updated
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();

        expect(find.text('Create a Classroom'), findsNothing);
        expect(find.text('Advanced Astrophysics'), findsOneWidget);
      },
    );

    testWidgets(
      'Student views classrooms: sees Join Code button, joins with valid code',
      (tester) async {
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
            child: const MaterialApp(home: Scaffold(body: ClassroomsView())),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Students see Join Code, not Create Class
        expect(find.text('Join Code'), findsOneWidget);
        expect(find.text('Create Class'), findsNothing);

        // 2. Open Join Dialog
        await tester.tap(find.text('Join Code'));
        await tester.pumpAndSettle();

        expect(find.text('Join a Classroom'), findsOneWidget);

        // 3. Enter valid code PHYS40 and join
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Class Code'),
          'PHYS40',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Join Class'));
        await tester.pumpAndSettle();

        // 4. Dialog is dismissed and class list contains the joined class
        expect(find.text('Join a Classroom'), findsNothing);
        expect(find.text('Applied Classical Mechanics'), findsWidgets);
        expect(find.text('Classroom Hub'), findsOneWidget);
      },
    );

    testWidgets(
      'Student enters invalid code: displays useful error message and rejects',
      (tester) async {
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
            child: const MaterialApp(home: Scaffold(body: JoinClassDialog())),
          ),
        );
        await tester.pumpAndSettle();

        // Enter invalid code with special characters
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Class Code'),
          'INVALID-99',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Join Class'));
        await tester.pumpAndSettle();

        // Error message appears
        expect(find.text('Invalid classroom code'), findsOneWidget);
      },
    );

    testWidgets('Duplicate join code is rejected with descriptive error', (
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
          child: const MaterialApp(home: Scaffold(body: JoinClassDialog())),
        ),
      );
      await tester.pumpAndSettle();

      // CELL24 is already in the default initial classrooms list
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Class Code'),
        'CELL24',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Join Class'));
      await tester.pumpAndSettle();

      // Duplicate rejection message displayed
      expect(find.text('Already joined this classroom'), findsOneWidget);
    });
  });
}
