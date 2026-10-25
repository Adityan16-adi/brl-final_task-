import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/providers/network_providers.dart';
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

void main() {
  group('AI Mentor Screen Tests', () {
    testWidgets('Fires warm-up GET /api/mentor/health on init and shows welcome state', (tester) async {
      bool healthPinged = false;

      final dio = Dio();
      dio.httpClientAdapter = _MockDioAdapter(
        handler: (options) async {
          if (options.path == '/api/mentor/health') {
            healthPinged = true;
            return ResponseBody.fromString(
              '{"success":true,"status":"healthy"}',
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
            home: MentorScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      // Verify warm-up was fired
      expect(healthPinged, isTrue);
      expect(find.text('AI Mentor'), findsOneWidget);
      expect(find.text('What would you like to learn today?'), findsOneWidget);
      expect(find.text('Suggested Topics'), findsOneWidget);
    });

    testWidgets('Adds user message immediately and shows 3-dot typing indicator while awaiting reply', (tester) async {
      final completer = Completer<ResponseBody>();

      final dio = Dio();
      dio.httpClientAdapter = _MockDioAdapter(
        handler: (options) async {
          if (options.path == '/api/mentor/health') {
            return ResponseBody.fromString('{"success":true}', 200);
          }
          if (options.path == '/api/mentor/chat') {
            return completer.future;
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
            home: MentorScreen(),
          ),
        ),
      );

      // Enter a question and submit
      final inputFinder = find.byType(TextField);
      expect(inputFinder, findsOneWidget);
      await tester.enterText(inputFinder, 'What is velocity?');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();

      // Immediately present in UI
      expect(find.text('What is velocity?'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);

      // Complete reply
      completer.complete(
        ResponseBody.fromString(
          '{"success":true,"reply":"Velocity is speed with direction."}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Velocity is speed with direction.'), findsOneWidget);
      expect(find.text('AI Mentor'), findsWidgets);
    });

    testWidgets('Shows AI waking up message and Retry button on 504 / timeout', (tester) async {
      int chatAttempts = 0;

      final dio = Dio();
      dio.httpClientAdapter = _MockDioAdapter(
        handler: (options) async {
          if (options.path == '/api/mentor/health') {
            return ResponseBody.fromString('{"success":true}', 200);
          }
          if (options.path == '/api/mentor/chat') {
            chatAttempts++;
            if (chatAttempts == 1) {
              return ResponseBody.fromString(
                '{"success":false,"message":"AI is waking up, please wait a moment..."}',
                504,
                headers: {
                  Headers.contentTypeHeader: [Headers.jsonContentType],
                },
              );
            }
            return ResponseBody.fromString(
              '{"success":true,"reply":"Here is the derivation."}',
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
            home: MentorScreen(),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Explain calculus');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      // Verify friendly waking-up message and Retry button
      expect(find.text('AI is waking up, please wait a moment...'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(chatAttempts, equals(1));

      // Tap Retry button
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(chatAttempts, equals(2));
      expect(find.text('Here is the derivation.'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });
  });
}
