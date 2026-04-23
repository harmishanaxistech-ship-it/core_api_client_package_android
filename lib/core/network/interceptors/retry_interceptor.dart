// Retry interceptor with exponential backoff for transient failures.
import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration baseDelay;

  RetryInterceptor({required this.dio, this.maxRetries = 2, this.baseDelay = const Duration(milliseconds: 500)});

  bool _shouldRetry(DioException err) {
    // Retry on network errors and idempotent server errors (5xx)
    if (err.type == DioExceptionType.unknown || err.type == DioExceptionType.connectionTimeout || err.type == DioExceptionType.receiveTimeout) {
      return true;
    }
    final status = err.response?.statusCode ?? 0;
    return status >= 500 && status < 600;
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    int retries = (options.extra['retries'] as int?) ?? 0;

    if (retries >= maxRetries || !_shouldRetry(err)) {
      handler.next(err);
      return;
    }

    retries += 1;
    options.extra['retries'] = retries;

    final jitter = Random().nextDouble();
    final delayMs = (baseDelay.inMilliseconds * pow(2, retries - 1) * (1 + jitter)).toInt();

    await Future.delayed(Duration(milliseconds: delayMs));

    try {
      final response = await dio.fetch(options);
      handler.resolve(response);
      return;
    } catch (e) {
      if (e is DioException) {
        super.onError(e, handler);
        return;
      }
      handler.next(err);
      return;
    }
  }
}
