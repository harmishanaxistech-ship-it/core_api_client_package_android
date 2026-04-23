// Custom exception type for API-related failures.
import 'package:dio/dio.dart';

/// Broad categories of API errors for easier handling.
enum ApiErrorType { network, timeout, cancelled, server, client, parse, unknown }

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;
  final ApiErrorType type;

  ApiException(this.message, {this.statusCode, this.details, this.type = ApiErrorType.unknown});

  @override
  String toString() => 'ApiException(type: $type, status: $statusCode, message: $message)';

  /// Convert a DioException into a structured ApiException.
  factory ApiException.fromDio(DioException error) {
    int? status;
    String msg = 'Unknown error';
    dynamic details;
    ApiErrorType type = ApiErrorType.unknown;

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

      if (status != null) {
        if (status >= 500) {
          type = ApiErrorType.server;
        } else if (status >= 400) {
          type = ApiErrorType.client;
        }
      }
    } else {
      // Map DioErrorType to readable message and ApiErrorType
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          msg = 'Request timed out';
          type = ApiErrorType.timeout;
          break;
        case DioExceptionType.cancel:
          msg = 'Request cancelled';
          type = ApiErrorType.cancelled;
          break;
        case DioExceptionType.unknown:
          msg = 'Network error';
          type = ApiErrorType.network;
          break;
        default:
          msg = error.message ?? 'Request failed';
          type = ApiErrorType.unknown;
      }
    }

    return ApiException(msg, statusCode: status, details: details, type: type);
  }
}
