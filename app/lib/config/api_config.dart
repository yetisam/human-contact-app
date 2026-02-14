/// API configuration
class ApiConfig {
  ApiConfig._();

  /// Base URL for the Human Contact API
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5001/api/v1',
  );

  /// WebSocket URL
  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'ws://localhost:5001/ws',
  );

  /// Request timeout
  static const Duration timeout = Duration(seconds: 30);

  /// API version
  static const String version = 'v1';
}
