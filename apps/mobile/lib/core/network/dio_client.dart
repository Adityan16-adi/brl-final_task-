import 'package:dio/dio.dart';

import '../config/api_config.dart';

typedef TokenReader = Future<String?> Function();

class DioClient {
  DioClient._();

  /// ML service base URL (retained for existing callers)
  static String get baseUrl => ApiConfig.mlBaseUrl;

  /// Default client for the ML service
  static Dio create() => createFor(baseUrl);

  /// Client for any backend endpoint with optional Bearer token authorization
  static Dio createFor(String targetBaseUrl, {TokenReader? tokenReader}) {
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

    if (tokenReader != null) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final token = await tokenReader();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            handler.next(options);
          },
        ),
      );
    }

    return dio;
  }
}
