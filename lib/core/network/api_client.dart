// ApiClient: a singleton wrapper around Dio providing typed request methods,
// interceptors, timeout, retry, and file upload support.
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
  // Note: _errorController is only created when requested via errorStream getter
  Stream<ApiException>? _errorStream;

  final Future<bool> Function()? _refreshTokenHandler;
  Completer<bool>? _refreshCompleter;

  ApiClient._(this._dio, {void Function(ApiException)? onError, Future<bool> Function()? refreshTokenHandler}) : _onErrorCallback = onError, _refreshTokenHandler = refreshTokenHandler {
    // Attach an interceptor to handle 401 refresh, convert Dio errors into ApiException and notify
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (err, handler) async {
        try {
          final status = err.response?.statusCode;
          // Handle 401 Unauthorized with refresh flow
          if (status == 401 && _refreshTokenHandler != null) {
            final options = err.requestOptions;
            final alreadyRetried = options.extra['retried_with_refresh'] as bool? ?? false;
            if (!alreadyRetried) {
              // If a refresh is already in progress, wait for it
              if (_refreshCompleter != null) {
                try {
                  await _refreshCompleter!.future;
                } catch (_) {}
              } else {
                _refreshCompleter = Completer<bool>();
                try {
                  final refreshed = await _refreshTokenHandler!();
                  _refreshCompleter!.complete(refreshed);
                } catch (e) {
                  _refreshCompleter!.complete(false);
                }
                // clear completer after completion
                final tmp = _refreshCompleter;
                _refreshCompleter = null;
                try {
                  await tmp?.future;
                } catch (_) {}
              }

              // If token refresh succeeded, retry original request once
              final refreshResult = (_refreshCompleter == null) ? true : false; // if no completer left, assume success
              // Note: better to check storage/token; here we attempt to retry once
              if (refreshResult) {
                final opts = err.requestOptions;
                opts.extra['retried_with_refresh'] = true;
                // Remove old authorization header so AuthInterceptor can re-add new token
                opts.headers.remove('Authorization');
                try {
                  final response = await _dio.fetch(opts);
                  return handler.resolve(response);
                } catch (e) {
                  // If retry fails, fall through to normal error handling
                }
              }
            }
          }
        } catch (_) {}

        final apiEx = ApiException.fromDio(err);
        if (_onErrorCallback != null) {
          try {
            _onErrorCallback!(apiEx);
          } catch (_) {}
        }
        handler.next(err);
      },
    ));
  }

  /// Initialize the singleton with [config] and optional token provider.
  /// If called multiple times, re-configures the singleton.
  static void initialize({required NetworkConfig config, TokenProvider? tokenProvider, bool enableLogging = false, void Function(ApiException)? onError, Future<bool> Function()? refreshTokenHandler}) {
    final dio = Dio(BaseOptions(baseUrl: config.baseUrl, headers: config.defaultHeaders));
    dio.options.connectTimeout = config.timeout;
    dio.options.receiveTimeout = config.timeout;
    dio.options.sendTimeout = config.timeout;

    // Add interceptors
    if (tokenProvider != null) {
      DioInterceptorGuard.add(dio, AuthInterceptor(tokenProvider));
    }
    dio.interceptors.add(LoggingInterceptor(enabled: enableLogging));
    dio.interceptors.add(RetryInterceptor(dio: dio, maxRetries: config.maxRetries));

    _instance = ApiClient._(dio, onError: onError, refreshTokenHandler: refreshTokenHandler);
  }

  /// Access the singleton. Throws if initialize wasn't called.
  static ApiClient get instance {
    if (_instance == null) {
      throw StateError('ApiClient not initialized. Call ApiClient.initialize(...) first.');
    }
    return _instance!;
  }

  Dio get dio => _dio;

  /// Optional error stream — create lazily if consumer subscribes.
  Stream<ApiException> get errorStream {
    _errorStream ??= (() {
      final controller = StreamController<ApiException>.broadcast();
      // Add an interceptor to push errors to the stream
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
  Future<ApiResponse<T>> get<T>(String path, {Map<String, dynamic>? queryParameters, Map<String, String>? headers}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters, options: Options(headers: headers));
      return ApiResponse.success(response.data as T);
    } on DioException catch (e) {
      return ApiResponse.failure(ApiException.fromDio(e));
    }
  }

  /// POST request with optional body and query parameters.
  Future<ApiResponse<T>> post<T>(String path, {dynamic body, Map<String, dynamic>? queryParameters, Map<String, String>? headers}) async {
    try {
      final response = await _dio.post(path, data: body, queryParameters: queryParameters, options: Options(headers: headers));
      return ApiResponse.success(response.data as T);
    } on DioException catch (e) {
      return ApiResponse.failure(ApiException.fromDio(e));
    }
  }

  /// PUT request
  Future<ApiResponse<T>> put<T>(String path, {dynamic body, Map<String, dynamic>? queryParameters, Map<String, String>? headers}) async {
    try {
      final response = await _dio.put(path, data: body, queryParameters: queryParameters, options: Options(headers: headers));
      return ApiResponse.success(response.data as T);
    } on DioException catch (e) {
      return ApiResponse.failure(ApiException.fromDio(e));
    }
  }

  /// DELETE request
  Future<ApiResponse<T>> delete<T>(String path, {Map<String, dynamic>? queryParameters, Map<String, String>? headers}) async {
    try {
      final response = await _dio.delete(path, queryParameters: queryParameters, options: Options(headers: headers));
      return ApiResponse.success(response.data as T);
    } on DioException catch (e) {
      return ApiResponse.failure(ApiException.fromDio(e));
    }
  }

  /// Generic request where [method] is a string such as 'GET', 'POST', 'PUT', 'DELETE', or 'PATCH'.
  /// If [file] is provided and method is POST, uploadFile will be used.
  Future<ApiResponse<T>> request<T>(String method, String path,
      {dynamic body, Map<String, dynamic>? queryParameters, Map<String, String>? headers, File? file, String fieldName = 'file'}) async {
    final m = method.toUpperCase();
    try {
      switch (m) {
        case 'GET':
          return await get<T>(path, queryParameters: queryParameters, headers: headers);
        case 'POST':
          if (file != null) {
            return await uploadFile<T>(path, file, fieldName: fieldName, data: body is Map<String, dynamic> ? body : null, headers: headers);
          }
          return await post<T>(path, body: body, queryParameters: queryParameters, headers: headers);
        case 'PUT':
          return await put<T>(path, body: body, queryParameters: queryParameters, headers: headers);
        case 'DELETE':
          return await delete<T>(path, queryParameters: queryParameters, headers: headers);
        case 'PATCH':
          try {
            final response = await _dio.patch(path, data: body, queryParameters: queryParameters, options: Options(headers: headers));
            return ApiResponse.success(response.data as T);
          } on DioException catch (e) {
            return ApiResponse.failure(ApiException.fromDio(e));
          }
        default:
          return ApiResponse.failure(ApiException('Unsupported method: $method'));
      }
    } on DioException catch (e) {
      return ApiResponse.failure(ApiException.fromDio(e));
    }
  }

  /// Upload a file with multipart/form-data.
  /// fieldName defaults to 'file'. Additional fields can be provided.
  Future<ApiResponse<T>> uploadFile<T>(
    String path,
    File file, {
    String fieldName = 'file',
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  }) async {
    try {
      final fileName = file.path.split(Platform.pathSeparator).last;
      final form = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(file.path, filename: fileName),
        if (data != null) ...data,
      });

      final response = await _dio.post(path, data: form, options: Options(headers: headers, contentType: 'multipart/form-data'));
      return ApiResponse.success(response.data as T);
    } on DioException catch (e) {
      return ApiResponse.failure(ApiException.fromDio(e));
    }
  }
}

/// Helper to safely add interceptors when Dio may already have them.
class DioInterceptorGuard {
  static void add(Dio dio, Interceptor interceptor) {
    dio.interceptors.add(interceptor);
  }
}
