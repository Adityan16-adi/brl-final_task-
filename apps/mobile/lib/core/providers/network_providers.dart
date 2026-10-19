
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/dio_client.dart';

final dioProvider = Provider<Dio>((ref) {
  return DioClient.create();
});
