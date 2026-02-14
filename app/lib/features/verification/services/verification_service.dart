import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';

class VerificationService {
  final ApiClient _api;

  VerificationService(this._api);

  /// Send email verification code
  Future<int> sendEmailCode() async {
    try {
      final response = await _api.post('/verification/email/send');
      return response.data['expiresIn'] as int;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Verify email code
  Future<bool> verifyEmailCode(String code) async {
    try {
      final response = await _api.post('/verification/email/verify', data: {'code': code});
      return response.data['verified'] == true;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Send phone verification code
  Future<int> sendPhoneCode(String phone) async {
    try {
      final response = await _api.post('/verification/phone/send', data: {'phone': phone});
      return response.data['expiresIn'] as int;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Verify phone code
  Future<bool> verifyPhoneCode(String code) async {
    try {
      final response = await _api.post('/verification/phone/verify', data: {'code': code});
      return response.data['verified'] == true;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final verificationServiceProvider = Provider<VerificationService>((ref) {
  return VerificationService(ref.read(apiClientProvider));
});
