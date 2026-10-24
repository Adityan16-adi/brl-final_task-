import 'package:flutter/foundation.dart';

/// Central place for backend addresses and Firebase client configuration.
///
/// Default hosts adapt automatically to the platform:
/// - Android emulator uses 10.0.2.2 to reach host services.
/// - Web, macOS, Windows, Linux, and iOS simulators use localhost.
/// - Physical devices or remote deployments can be overridden via --dart-define.
class ApiConfig {
  ApiConfig._();

  static const String _definedMlUrl = String.fromEnvironment('ML_API_BASE_URL');
  static const String _definedCoreUrl = String.fromEnvironment(
    'CORE_API_BASE_URL',
  );
  static const String _definedLearningUrl = String.fromEnvironment(
    'LEARNING_API_BASE_URL',
  );

  // Firebase client parameters (supplied via --dart-define)
  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
  );
  static const String firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );

  /// True only when required Firebase client values are provided.
  static bool get hasFirebaseConfig =>
      firebaseApiKey.isNotEmpty &&
      firebaseAppId.isNotEmpty &&
      firebaseProjectId.isNotEmpty;

  /// Returns the appropriate default hostname based on target platform.
  static String get defaultHost {
    if (kIsWeb) return 'localhost';
    if (defaultTargetPlatform == TargetPlatform.android) return '10.0.2.2';
    return 'localhost';
  }

  /// ML service base URL (FastAPI on port 8001)
  static String get mlBaseUrl {
    if (_definedMlUrl.isNotEmpty) return _definedMlUrl;
    return 'http://$defaultHost:8001';
  }

  /// Core backend base URL (Node.js/Express on port 5000)
  static String get coreBaseUrl {
    if (_definedCoreUrl.isNotEmpty) return _definedCoreUrl;
    return 'http://$defaultHost:5000';
  }

  /// Learning backend base URL (same Node.js/Express server on port 5000)
  static String get learningBaseUrl {
    if (_definedLearningUrl.isNotEmpty) return _definedLearningUrl;
    return 'http://$defaultHost:5000';
  }
}
