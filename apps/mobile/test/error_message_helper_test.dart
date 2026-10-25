import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/errors/error_message_helper.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/home/domain/home_repository.dart';

void main() {
  group('ErrorMessageHelper Tests', () {
    test('handles connection timeouts with friendly waking-up message', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/api/test'),
        type: DioExceptionType.connectionTimeout,
      );
      final msg = ErrorMessageHelper.format(err);
      expect(msg.toLowerCase(), contains('waking up'));
    });

    test('handles 401 session expiry cleanly', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/api/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/api/test'),
          statusCode: 401,
        ),
      );
      final msg = ErrorMessageHelper.format(err);
      expect(msg, 'Your session has expired. Please sign in again.');
    });

    test('handles 502/504 server unavailable cleanly', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/api/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/api/test'),
          statusCode: 504,
        ),
      );
      final msg = ErrorMessageHelper.format(err);
      expect(msg.toLowerCase(), contains('waking up or temporarily unavailable'));
    });

    test('handles SocketException as no connection', () {
      const err = SocketException('Failed host lookup: test.com');
      final msg = ErrorMessageHelper.format(err);
      expect(msg, 'No internet connection. Please check your network and try again.');
    });

    test('handles AuthFailure with server down message', () {
      const err = AuthFailure('Cannot connect to authentication server at localhost');
      final msg = ErrorMessageHelper.format(err);
      expect(msg.toLowerCase(), contains('check your network or try demo mode'));
    });

    test('handles ClassroomException with status 404', () {
      const err = ClassroomException('Not found', statusCode: 404);
      final msg = ErrorMessageHelper.format(err);
      expect(msg, 'Classroom or coursework item was not found.');
    });

    test('never returns raw stack traces or MDN links', () {
      final rawError = Exception('Error: 500 Internal Server Error at line 42\nhttps://developer.mozilla.org/en-US/docs/Web/HTTP/Status/500');
      final msg = ErrorMessageHelper.format(rawError);
      expect(msg, isNot(contains('https://developer.mozilla.org')));
      expect(msg, isNot(contains('at line 42')));
      expect(msg, isNot(contains('Exception:')));
    });
  });
}
