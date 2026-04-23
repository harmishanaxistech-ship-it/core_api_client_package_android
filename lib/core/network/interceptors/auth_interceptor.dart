// Interceptor that injects an Authorization header using a provided token provider.
import 'dart:developer' as developer;
import 'package:dio/dio.dart';

typedef TokenProvider = Future<String?> Function();

class AuthInterceptor extends Interceptor {
  final TokenProvider tokenProvider;

  AuthInterceptor(this.tokenProvider);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final token = await tokenProvider();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        developer.log('Authorization header added for request: ${options.uri}', name: 'AuthInterceptor');
      }
    } catch (e, st) {
      developer.log('Failed to read token: $e', name: 'AuthInterceptor', error: e, stackTrace: st);
    }
    handler.next(options);
  }
}
