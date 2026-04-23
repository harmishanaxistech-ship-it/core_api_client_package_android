// Custom exception type for API-related failures.
import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  ApiException(this.message, {this.statusCode, this.details});

  @override
  String toString() => 'ApiException(status: $statusCode, message: $message)';

  /// Convert a DioException into a structured ApiException.
  factory ApiException.fromDio(DioException error) {
    int? status;
    String msg = 'Unknown error';
    dynamic details;

    if (error.response != null) {
      status = error.response?.statusCode;
      details = error.response?.data;
      msg = error.response?.statusMessage ?? error.message ?? 'Http error';
      // If server returned an object with message
      try {
        if (details is Map && details['message'] != null) {
          msg = details['message'].toString();
        }
      } catch (_) {}
    } else {
      // Map DioErrorType to readable message
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          msg = 'Request timed out';
          break;
        case DioExceptionType.cancel:
          msg = 'Request cancelled';
          break;
        case DioExceptionType.unknown:
          msg = 'Network error';
          break;
        default:
          msg = error.message ?? 'Request failed';
      }
    }

    return ApiException(msg, statusCode: status, details: details);
  }
}
