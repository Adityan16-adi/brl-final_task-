import 'package:dio/dio.dart';

class DioClient {
  DioClient._();

  static const String baseUrl = String.fromEnvironment(
    'ML_API_BASE_URL',
    defaultValue: 'http://192.168.0.105:8001',
  );

  static Dio create() {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 15),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
  }
}
