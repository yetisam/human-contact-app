import 'package:dio/dio.dart';

/// Parse API errors into user-friendly messages
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  ApiException(this.message, {this.statusCode, this.details});

  factory ApiException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException('Connection timed out. Please try again.');

      case DioExceptionType.connectionError:
        return ApiException('No internet connection.');

      case DioExceptionType.badResponse:
        final data = error.response?.data;
        final statusCode = error.response?.statusCode;

        if (data is Map) {
          return ApiException(
            data['error'] ?? 'Something went wrong',
            statusCode: statusCode,
            details: data['details'],
          );
        }
        return ApiException(
          'Server error ($statusCode)',
          statusCode: statusCode,
        );

      default:
        return ApiException('Something went wrong. Please try again.');
    }
  }

  @override
  String toString() => message;
}
