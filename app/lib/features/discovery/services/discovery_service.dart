import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../models/match_suggestion.dart';

class DiscoveryService {
  final ApiClient _api;

  DiscoveryService(this._api);

  /// Get match suggestions
  Future<MatchSuggestionsResponse> getSuggestions({
    int limit = 20,
    int offset = 0,
    double minScore = 0.1,
  }) async {
    try {
      final response = await _api.get('/discovery/suggestions', queryParameters: {
        'limit': limit,
        'offset': offset,
        'minScore': minScore,
      });
      return MatchSuggestionsResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Send connection request
  Future<void> sendConnectionRequest({
    required String recipientId,
    required String introMessage,
  }) async {
    try {
      await _api.post('/connections', data: {
        'recipientId': recipientId,
        'introMessage': introMessage,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get user's connections
  Future<Map<String, dynamic>> getConnections({
    String type = 'all',
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final params = <String, dynamic>{
        'type': type,
        'limit': limit,
        'offset': offset,
      };
      if (status != null) params['status'] = status;

      final response = await _api.get('/connections', queryParameters: params);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Accept a connection request
  Future<void> acceptConnection(String connectionId) async {
    try {
      await _api.patch('/connections/$connectionId/accept');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Decline a connection request
  Future<void> declineConnection(String connectionId) async {
    try {
      await _api.patch('/connections/$connectionId/decline');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final discoveryServiceProvider = Provider<DiscoveryService>((ref) {
  return DiscoveryService(ref.read(apiClientProvider));
});
