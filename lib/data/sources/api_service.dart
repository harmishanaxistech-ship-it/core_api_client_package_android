// ApiService: a thin data source layer over ApiClient. Keeps separation of concerns.
import '../../core/models/api_response.dart';
import '../../core/network/api_client.dart';

class ApiService {
  final ApiClient client;

  ApiService({required this.client});

  Future<ApiResponse<T>> get<T>(String path, {Map<String, dynamic>? queryParameters, Map<String, String>? headers}) {
    return client.get<T>(path, queryParameters: queryParameters, headers: headers);
  }

  Future<ApiResponse<T>> post<T>(String path, {dynamic body, Map<String, dynamic>? queryParameters, Map<String, String>? headers}) {
    return client.post<T>(path, body: body, queryParameters: queryParameters, headers: headers);
  }

  Future<ApiResponse<T>> put<T>(String path, {dynamic body, Map<String, dynamic>? queryParameters, Map<String, String>? headers}) {
    return client.put<T>(path, body: body, queryParameters: queryParameters, headers: headers);
  }

  Future<ApiResponse<T>> delete<T>(String path, {Map<String, dynamic>? queryParameters, Map<String, String>? headers}) {
    return client.delete<T>(path, queryParameters: queryParameters, headers: headers);
  }
}
