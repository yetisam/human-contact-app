import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: unused_import
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage for tokens and sensitive data
class SecureStorageService {
  static const _accessTokenKey = 'hc_access_token';
  static const _refreshTokenKey = 'hc_refresh_token';
  static const _userIdKey = 'hc_user_id';

  final FlutterSecureStorage _storage;

  SecureStorageService()
      : _storage = const FlutterSecureStorage();

  // Tokens
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  // User ID
  Future<void> saveUserId(String userId) =>
      _storage.write(key: _userIdKey, value: userId);

  Future<String?> getUserId() => _storage.read(key: _userIdKey);

  Future<void> clearUserId() => _storage.delete(key: _userIdKey);

  // Clear everything
  Future<void> clearAll() async {
    await clearTokens();
    await clearUserId();
  }
}

/// Provider for SecureStorageService
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
