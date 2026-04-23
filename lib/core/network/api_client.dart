// ApiClient: a singleton wrapper around Dio providing typed request methods,
// interceptors, timeout, retry, and file upload support.
import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import '../models/api_response.dart';
import '../exceptions/api_exception.dart';
import 'network_config.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/retry_interceptor.dart';

// ApiClient is a configurable singleton. Call [initialize] before use.
class ApiClient {
  static ApiClient? _instance;

  final Dio _dio;
  // Optional global error callback
  final void Function(ApiException)? _onErrorCallback;
  // Simple broadcast stream for errors
  Stream<ApiException>? _errorStream;

  final Future<bool> Function(Dio)? _refreshTokenHandler;
  Completer<bool>? _refreshCompleter;

  ApiClient._(this._dio, {void Function(ApiException)? onError, Future<bool> Function(Dio)? refreshTokenHandler}) : _onErrorCallback = onError, _refreshTokenHandler = refreshTokenHandler {
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (err, handler) async {
        try {
          final status = err.response?.statusCode;
          if (status == 401 && _refreshTokenHandler != null) {
            final options = err.requestOptions;
            final alreadyRetried = options.extra['retried_with_refresh'] as bool? ?? false;
            if (!alreadyRetried) {
              if (_refreshCompleter != null) {
                try {
                  await _refreshCompleter!.future;
                } catch (_) {}
              } else {
                _refreshCompleter = Completer<bool>();
                final localCompleter = _refreshCompleter;
                try {
                  final refreshDio = Dio(BaseOptions(baseUrl: _dio.options.baseUrl));
                  final refreshHandler = _refreshTokenHandler;
                  final refreshed = await refreshHandler(refreshDio);
                  localCompleter?.complete(refreshed);
                } catch (e) {
                  localCompleter?.complete(false);
                }
                _refreshCompleter = null;
              }

              final opts = err.requestOptions;
              opts.extra['retried_with_refresh'] = true;
              opts.headers.remove('Authorization');
              try {
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              } catch (e) {}
            }
          }
        } catch (_) {}

        final apiEx = ApiException.fromDio(err);
        if (_onErrorCallback != null) {
          try {
            _onErrorCallback(apiEx);
          } catch (_) {}
        }
        handler.next(err);
      },
    ));
  }

  static void initialize({required NetworkConfig config, TokenProvider? tokenProvider, bool enableLogging = false, void Function(ApiException)? onError, Future<bool> Function(Dio)? refreshTokenHandler}) {
    final dio = Dio(BaseOptions(baseUrl: config.baseUrl, headers: config.defaultHeaders));
    dio.options.connectTimeout = config.timeout;
    dio.options.receiveTimeout = config.timeout;
    dio.options.sendTimeout = config.timeout;

    if (tokenProvider != null) {
      dio.interceptors.add(AuthInterceptor(tokenProvider));
    }
    dio.interceptors.add(LoggingInterceptor(enabled: enableLogging));
    dio.interceptors.add(RetryInterceptor(dio: dio, maxRetries: config.maxRetries));

    _instance = ApiClient._(dio, onError: onError, refreshTokenHandler: refreshTokenHandler);
  }

  static ApiClient get instance {
    if (_instance == null) {
      throw StateError('ApiClient not initialized. Call ApiClient.initialize(...) first.');
    }
    return _instance!;
  }

  Dio get dio => _dio;

  Stream<ApiException> get errorStream {
    _errorStream ??= (() {
      final controller = StreamController<ApiException>.broadcast();
      _dio.interceptors.add(InterceptorsWrapper(
        onError: (err, handler) {
          try {
            final apiEx = ApiException.fromDio(err);
            controller.add(apiEx);
          } catch (_) {}
          handler.next(err);
        },
      ));
      return controller.stream;
    })();
    return _errorStream!;
  }

  /// Perform a GET request.
  Future<ApiResponse<T>> get<T>({required String url, Map<String, dynamic>? params, Map<String, String>? headers}) async {
    try {
      final response = await _dio.get(url, queryParameters: params, options: Options(headers: headers));
      return ApiResponse.success(response.data as T);
    } on DioException catch (e) {
      return ApiResponse.failure(ApiException.fromDio(e));
    }
  }

  /// POST request with optional body and query parameters.
  Future<ApiResponse<T>> post<T>({required String url, dynamic body, Map<String, dynamic>? params, Map<String, String>? headers}) async {
    try {
      dynamic data = body;
      Options options = Options(headers: headers);

      // Handle File upload automatically if body contains a File
      if (body is Map<String, dynamic>) {
        bool hasFile = false;
        final map = <String, dynamic>{};
        for (final entry in body.entries) {
          if (entry.value is File) {
            hasFile = true;
            final file = entry.value as File;
            map[entry.key] = await MultipartFile.fromFile(file.path, filename: file.path.split(Platform.pathSeparator).last);
          } else {
            map[entry.key] = entry.value;
          }
        }
        if (hasFile) {
          data = FormData.fromMap(map);
          options.contentType = 'multipart/form-data';
        }
      }

      final response = await _dio.post(url, data: data, queryParameters: params, options: options);
      return ApiResponse.success(response.data as T);
    } on DioException catch (e) {
      return ApiResponse.failure(ApiException.fromDio(e));
    }
  }

  /// PUT request
  Future<ApiResponse<T>> put<T>({required String url, dynamic body, Map<String, dynamic>? params, Map<String, String>? headers}) async {
    try {
      final response = await _dio.put(url, data: body, queryParameters: params, options: Options(headers: headers));
      return ApiResponse.success(response.data as T);
    } on DioException catch (e) {
      return ApiResponse.failure(ApiException.fromDio(e));
    }
  }

  /// DELETE request
  Future<ApiResponse<T>> delete<T>({required String url, Map<String, dynamic>? params, Map<String, String>? headers}) async {
    try {
      final response = await _dio.delete(url, queryParameters: params, options: Options(headers: headers));
      return ApiResponse.success(response.data as T);
    } on DioException catch (e) {
      return ApiResponse.failure(ApiException.fromDio(e));
    }
  }

  /// PATCH request
  Future<ApiResponse<T>> patch<T>({required String url, dynamic body, Map<String, dynamic>? params, Map<String, String>? headers}) async {
    try {
      final response = await _dio.patch(url, data: body, queryParameters: params, options: Options(headers: headers));
      return ApiResponse.success(response.data as T);
    } on DioException catch (e) {
      return ApiResponse.failure(ApiException.fromDio(e));
    }
  }
}
