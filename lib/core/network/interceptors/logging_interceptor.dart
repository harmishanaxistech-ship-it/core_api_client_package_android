// Logging interceptor for request/response debugging.
import 'dart:developer' as developer;
import 'package:dio/dio.dart';

class LoggingInterceptor extends Interceptor {
  final bool enabled;

  LoggingInterceptor({this.enabled = true});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (enabled) {
      developer.log('Request: [${options.method}] ${options.uri}', name: 'LoggingInterceptor');
      if (options.headers.isNotEmpty) {
        developer.log('Request headers: ${options.headers}', name: 'LoggingInterceptor');
      }
      if (options.queryParameters.isNotEmpty) {
        developer.log('Query params: ${options.queryParameters}', name: 'LoggingInterceptor');
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (enabled) {
      developer.log('Response: [${response.statusCode}] ${response.requestOptions.uri}', name: 'LoggingInterceptor');
      developer.log('Response data: ${response.data}', name: 'LoggingInterceptor');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (enabled) {
      developer.log('Error: [${err.response?.statusCode}] ${err.requestOptions.uri} - ${err.message}',
          name: 'LoggingInterceptor', error: err);
    }
    handler.next(err);
  }
}
