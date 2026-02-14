import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/api_config.dart';
import '../storage/secure_storage.dart';

/// Dio HTTP client with auth token interceptor
class ApiClient {
  final Dio _dio;
  final SecureStorageService _storage;

  ApiClient(this._storage)
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.timeout,
          receiveTimeout: ApiConfig.timeout,
          headers: {'Content-Type': 'application/json'},
        )) {
    _dio.interceptors.add(_AuthInterceptor(_storage, _dio));
  }

  Dio get dio => _dio;

  // Convenience methods
  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) =>
      _dio.get(path, queryParameters: queryParams);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> patch(String path, {dynamic data}) =>
      _dio.patch(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);
}

/// Interceptor that adds auth token and handles token refresh
class _AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;
  final Dio _dio;

  _AuthInterceptor(this._storage, this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip auth for public endpoints
    final publicPaths = ['/auth/register', '/auth/login', '/auth/refresh'];
    if (publicPaths.any((p) => options.path.contains(p))) {
      return handler.next(options);
    }

    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // If 401 and we have a refresh token, try to refresh
    if (err.response?.statusCode == 401) {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null) {
        try {
          final response = await Dio(BaseOptions(
            baseUrl: ApiConfig.baseUrl,
          )).post('/auth/refresh', data: {'refreshToken': refreshToken});

          final newAccess = response.data['accessToken'] as String;
          final newRefresh = response.data['refreshToken'] as String;

          await _storage.saveTokens(
            accessToken: newAccess,
            refreshToken: newRefresh,
          );

          // Retry the original request with new token
          err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
          final retryResponse = await _dio.fetch(err.requestOptions);
          return handler.resolve(retryResponse);
        } catch (_) {
          // Refresh failed — clear tokens, user needs to log in again
          await _storage.clearTokens();
        }
      }
    }

    handler.next(err);
  }
}

/// Provider for ApiClient
final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.read(secureStorageProvider);
  return ApiClient(storage);
});
