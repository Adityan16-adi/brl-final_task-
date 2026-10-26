import 'package:dio/dio.dart';

import '../config/api_config.dart';

typedef TokenReader = Future<String?> Function();
typedef SessionExpiredHandler = void Function();
typedef NetworkStatusHandler = void Function(bool isUnreachable);

class DioClient {
  DioClient._();

  /// ML service base URL (retained for existing callers)
  static String get baseUrl => ApiConfig.mlBaseUrl;

  /// Default client for the ML service
  static Dio create() => createFor(baseUrl);

  /// Client for any backend endpoint with optional Bearer token authorization,
  /// 401 session expiration handling, and network reachability tracking.
  static Dio createFor(
    String targetBaseUrl, {
    TokenReader? tokenReader,
    SessionExpiredHandler? onSessionExpired,
    NetworkStatusHandler? onNetworkStatusChanged,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: targetBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 15),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (tokenReader != null) {
            final token = await tokenReader();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          // Successful response confirms server is reachable
          onNetworkStatusChanged?.call(false);
          handler.next(response);
        },
        onError: (DioException err, handler) {
          // Check for network unreachable / connection timeout
          if (err.type == DioExceptionType.connectionError ||
              err.type == DioExceptionType.connectionTimeout) {
            onNetworkStatusChanged?.call(true);
          } else if (err.response != null) {
            // Received response from server, so network is reachable
            onNetworkStatusChanged?.call(false);
          }

          // Check for 401 Unauthorized
          if (err.response?.statusCode == 401) {
            onSessionExpired?.call();
          }

          handler.next(err);
        },
      ),
    );

    return dio;
  }
}
