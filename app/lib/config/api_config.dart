import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;

/// API configuration
class ApiConfig {
  ApiConfig._();

  /// Production backend URL (Railway)
  static const String _prodBaseUrl = 'https://human-contact-app-production.up.railway.app/api/v1';
  static const String _prodWsUrl = 'wss://human-contact-app-production.up.railway.app/ws';

  /// Local dev URL
  static const String _devBaseUrl = 'http://localhost:5001/api/v1';
  static const String _devWsUrl = 'ws://localhost:5001/ws';

  /// Base URL for the Human Contact API
  /// Uses production URL for web/release builds, local for debug
  static String get baseUrl {
    if (kIsWeb || kReleaseMode) return _prodBaseUrl;
    return const String.fromEnvironment('API_BASE_URL', defaultValue: '') 
        .isNotEmpty 
        ? const String.fromEnvironment('API_BASE_URL') 
        : _devBaseUrl;
  }

  /// WebSocket URL
  static String get wsUrl {
    if (kIsWeb || kReleaseMode) return _prodWsUrl;
    return const String.fromEnvironment('WS_URL', defaultValue: '')
        .isNotEmpty
        ? const String.fromEnvironment('WS_URL')
        : _devWsUrl;
  }

  /// Request timeout
  static const Duration timeout = Duration(seconds: 30);

  /// API version
  static const String version = 'v1';
}
