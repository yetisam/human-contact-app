import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';

class ExchangeService {
  final ApiClient _api;

  ExchangeService(this._api);

  /// Request a contact exchange
  Future<Map<String, dynamic>> requestExchange({
    required String connectionId,
    required bool shareEmail,
    required bool sharePhone,
    required bool wantsEmail,
    required bool wantsPhone,
  }) async {
    try {
      final response = await _api.post('/exchange', data: {
        'connectionId': connectionId,
        'shareEmail': shareEmail,
        'sharePhone': sharePhone,
        'wantsEmail': wantsEmail,
        'wantsPhone': wantsPhone,
      });
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Approve an exchange
  Future<Map<String, dynamic>> approveExchange({
    required String exchangeId,
    required bool shareEmail,
    required bool sharePhone,
  }) async {
    try {
      final response = await _api.patch('/exchange/$exchangeId/approve', data: {
        'shareEmail': shareEmail,
        'sharePhone': sharePhone,
      });
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Decline an exchange
  Future<void> declineExchange(String exchangeId) async {
    try {
      await _api.patch('/exchange/$exchangeId/decline');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get reveal data
  Future<Map<String, dynamic>> getReveal(String exchangeId) async {
    try {
      final response = await _api.get('/exchange/$exchangeId/reveal');
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Check exchange status for a connection
  Future<Map<String, dynamic>> getExchangeStatus(String connectionId) async {
    try {
      final response = await _api.get('/exchange/connection/$connectionId');
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final exchangeServiceProvider = Provider<ExchangeService>((ref) {
  return ExchangeService(ref.read(apiClientProvider));
});
