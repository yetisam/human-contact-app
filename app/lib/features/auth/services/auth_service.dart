import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../models/user.dart';

/// Auth API service
class AuthService {
  final ApiClient _api;
  final SecureStorageService _storage;

  AuthService(this._api, this._storage);

  /// Register a new user
  Future<User> register({
    required String email,
    required String password,
    required String firstName,
  }) async {
    try {
      final response = await _api.post('/auth/register', data: {
        'email': email,
        'password': password,
        'firstName': firstName,
      });

      final data = response.data;
      await _storage.saveTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
      );
      await _storage.saveUserId(data['user']['id']);

      return User.fromJson(data['user']);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Login with email and password
  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final data = response.data;
      await _storage.saveTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
      );
      await _storage.saveUserId(data['user']['id']);

      return User.fromJson(data['user']);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get current user profile
  Future<User> getProfile() async {
    try {
      final response = await _api.get('/users/me');
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      await _api.post('/auth/logout', data: {
        'refreshToken': refreshToken,
      });
    } catch (_) {
      // Best effort — clear local tokens regardless
    } finally {
      await _storage.clearAll();
    }
  }

  /// Check if user has stored tokens (for auto-login)
  Future<bool> hasStoredSession() async {
    final token = await _storage.getAccessToken();
    return token != null;
  }
}

/// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  final api = ref.read(apiClientProvider);
  final storage = ref.read(secureStorageProvider);
  return AuthService(api, storage);
});
