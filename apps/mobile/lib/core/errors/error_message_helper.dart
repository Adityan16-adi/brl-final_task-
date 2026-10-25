import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/home/domain/home_repository.dart';

/// Centralized human-friendly error formatter for Pragti.
/// Converts technical exceptions, HTTP status codes, Dio errors,
/// and timeouts into concise, actionable messages for the user.
/// NEVER outputs raw stack traces, exception type names, or technical URLs.
class ErrorMessageHelper {
  ErrorMessageHelper._();

  /// Formats any error object into a clean, human-readable sentence.
  static String format(Object? error, {String? fallback}) {
    if (error == null) {
      return fallback ?? 'Something went wrong. Please try again.';
    }

    if (error is DioException) {
      return _formatDioException(error, fallback);
    }

    if (error is AuthFailure) {
      return _formatAuthFailure(error, fallback);
    }

    if (error is ClassroomException) {
      return _formatClassroomException(error, fallback);
    }

    if (error is SocketException || error is TimeoutException) {
      return 'No internet connection. Please check your network and try again.';
    }

    // Inspect string representations for common system or network messages
    final str = error.toString().toLowerCase();

    if (str.contains('socketexception') ||
        str.contains('failed host lookup') ||
        str.contains('network is unreachable') ||
        str.contains('connection refused') ||
        str.contains('no internet')) {
      return 'No internet connection. Please check your network and try again.';
    }

    if (str.contains('timed out') || str.contains('timeout')) {
      return 'The server took too long to respond. It may be waking up, please try again.';
    }

    if (str.contains('waking up') || str.contains('cold start')) {
      return 'The server is waking up. Please try again in a moment.';
    }

    if (str.contains('session expired') || str.contains('unauthorized') || str.contains('jwt')) {
      return 'Your session has expired. Please sign in again.';
    }

    if (str.contains('not found') || str.contains('404')) {
      return 'The requested resource was not found.';
    }

    if (str.contains('too large') || str.contains('25mb') || str.contains('entity too large')) {
      return 'The selected file exceeds the 25MB size limit.';
    }

    if (str.contains('unsupported') || str.contains('invalid file type')) {
      return 'Unsupported file format. Please upload a valid document or image.';
    }

    // Default clean fallback
    return fallback ?? 'Something went wrong. Please try again.';
  }

  static String _formatDioException(DioException error, String? fallback) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The server is waking up or connection timed out. Please try again.';

      case DioExceptionType.connectionError:
        return 'Cannot connect to server. Please check your network connection.';

      case DioExceptionType.cancel:
        return 'The request was cancelled.';

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;

        // Try extracting backend server message if it is clean
        String? serverMsg;
        if (responseData is Map<String, dynamic>) {
          final raw = responseData['message'] ?? responseData['error'];
          if (raw is String && raw.trim().isNotEmpty) {
            final trimmed = raw.trim();
            // Discard any raw stack traces or HTML or debug traces
            if (!trimmed.contains('<!DOCTYPE') &&
                !trimmed.contains('<html>') &&
                !trimmed.contains('Error:') &&
                !trimmed.contains('at ') &&
                !trimmed.contains('Trace:')) {
              serverMsg = trimmed;
            }
          }
        }

        switch (statusCode) {
          case 400:
            return serverMsg ?? 'Invalid request. Please check your details and try again.';
          case 401:
            return 'Your session has expired. Please sign in again.';
          case 403:
            return serverMsg ?? 'Access denied. You do not have permission for this action.';
          case 404:
            return serverMsg ?? 'The requested resource was not found.';
          case 409:
            return serverMsg ?? 'This item already exists or a conflict occurred.';
          case 413:
            return 'File is too large. Maximum allowed size is 25MB.';
          case 415:
            return 'Unsupported file type. Please upload a valid document or image.';
          case 429:
            return 'Too many requests. Please wait a moment and try again.';
          case 502:
          case 503:
          case 504:
            return 'The server is currently waking up or temporarily unavailable. Please try again in a moment.';
          case 500:
          default:
            return serverMsg ?? 'Something went wrong on the server. Please try again.';
        }

      case DioExceptionType.badCertificate:
        return 'Secure connection error. Please verify your connection.';

      case DioExceptionType.unknown:
      default:
        final inner = error.error;
        if (inner != null && inner is! DioException) {
          return format(inner, fallback: fallback);
        }
        return fallback ?? 'Something went wrong. Please check your network and try again.';
    }
  }

  static String _formatAuthFailure(AuthFailure failure, String? fallback) {
    final msg = failure.message.trim();
    final lower = msg.toLowerCase();

    if (lower.contains('socketexception') ||
        lower.contains('cannot connect') ||
        lower.contains('connection refused') ||
        lower.contains('failed host lookup')) {
      return 'Cannot connect to authentication server. Please check your network or try demo mode.';
    }

    if (lower.contains('invalid email or password') ||
        lower.contains('invalid credentials') ||
        lower.contains('wrong password')) {
      return 'Incorrect email or password. Please try again.';
    }

    if (lower.contains('google-services.json') || lower.contains('google sign-in is unavailable')) {
      return "Google sign-in isn't set up on this build. Use email instead.";
    }

    if (lower.contains('already in use') || lower.contains('already registered')) {
      return 'An account with this email address already exists.';
    }

    if (lower.contains('teacher signup key') || lower.contains('invite key')) {
      return 'Invalid teacher invite key. Please check with your administrator.';
    }

    // Strip technical prefix if present
    if (msg.startsWith('Exception: ')) {
      return msg.substring('Exception: '.length);
    }

    return msg.isNotEmpty ? msg : (fallback ?? 'Authentication failed. Please try again.');
  }

  static String _formatClassroomException(ClassroomException exception, String? fallback) {
    final msg = exception.message.trim();
    if (exception.statusCode != null) {
      if (exception.statusCode == 401) {
        return 'Your session has expired. Please sign in again.';
      }
      if (exception.statusCode == 403) {
        return 'You do not have permission to perform this classroom action.';
      }
      if (exception.statusCode == 404) {
        return 'Classroom or coursework item was not found.';
      }
      if (exception.statusCode == 413) {
        return 'File exceeds the 25MB limit.';
      }
      if (exception.statusCode! >= 500) {
        return 'The server is waking up or unavailable. Please try again shortly.';
      }
    }

    final lower = msg.toLowerCase();
    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection error')) {
      return 'Cannot reach the classroom server. Please check your network.';
    }

    if (msg.isNotEmpty && !lower.contains('exception:') && !lower.contains('dioexception')) {
      return msg;
    }

    return fallback ?? 'Classroom operation failed. Please try again.';
  }
}
