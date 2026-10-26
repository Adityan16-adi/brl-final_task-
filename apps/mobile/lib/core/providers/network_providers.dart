import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_providers.dart';
import '../config/api_config.dart';
import '../network/dio_client.dart';

final dioProvider = Provider<Dio>((ref) {
  return DioClient.create();
});

class ServerUnreachableNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setUnreachable(bool value) {
    state = value;
  }
}

/// Indicates whether the backend is unreachable (connection error / timeout)
final serverUnreachableProvider =
    NotifierProvider<ServerUnreachableNotifier, bool>(
  ServerUnreachableNotifier.new,
);

class SessionExpiredMessageNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setMessage(String? message) {
    state = message;
  }

  void clear() {
    state = null;
  }
}

/// Tracks session expiration message to display on the sign-in screen
final sessionExpiredMessageProvider =
    NotifierProvider<SessionExpiredMessageNotifier, String?>(
  SessionExpiredMessageNotifier.new,
);

final coreDioProvider = Provider<Dio>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);

  return DioClient.createFor(
    ApiConfig.coreBaseUrl,
    tokenReader: () => authRepo.getIdToken(),
    onSessionExpired: () {
      ref.read(sessionExpiredMessageProvider.notifier).setMessage(
            'Session expired, please sign in again',
          );
      authRepo.signOut();
    },
    onNetworkStatusChanged: (isUnreachable) {
      if (ref.read(serverUnreachableProvider) != isUnreachable) {
        ref.read(serverUnreachableProvider.notifier).setUnreachable(isUnreachable);
      }
    },
  );
});
