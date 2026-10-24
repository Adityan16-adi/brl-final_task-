import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_providers.dart';
import '../config/api_config.dart';
import '../network/dio_client.dart';

final dioProvider = Provider<Dio>((ref) {
  return DioClient.create();
});

final coreDioProvider = Provider<Dio>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return DioClient.createFor(
    ApiConfig.coreBaseUrl,
    tokenReader: () => authRepo.getIdToken(),
  );
});
