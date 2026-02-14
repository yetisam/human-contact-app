import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../models/interest.dart';

/// Profile API service
class ProfileService {
  final ApiClient _api;

  ProfileService(this._api);

  /// Get all interest categories and tags
  Future<List<InterestCategory>> getInterests() async {
    try {
      final response = await _api.get('/users/interests');
      final categories = (response.data['categories'] as List)
          .map((c) => InterestCategory.fromJson(c))
          .toList();
      return categories;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Complete profile setup
  Future<void> setupProfile({
    required String firstName,
    required String purposeStatement,
    required bool meetingPreference,
    required List<String> interestIds,
    String? city,
    String? state,
    String country = 'AU',
    double? locationLat,
    double? locationLng,
  }) async {
    try {
      final data = <String, dynamic>{
        'firstName': firstName,
        'purposeStatement': purposeStatement,
        'meetingPreference': meetingPreference,
        'interestIds': interestIds,
        'country': country,
      };
      if (city != null) data['city'] = city;
      if (state != null) data['state'] = state;
      if (locationLat != null) data['locationLat'] = locationLat;
      if (locationLng != null) data['locationLng'] = locationLng;

      await _api.put('/users/me/profile', data: data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final profileServiceProvider = Provider<ProfileService>((ref) {
  final api = ref.read(apiClientProvider);
  return ProfileService(api);
});
