// ApiService: a thin data source layer over ApiClient. Keeps separation of concerns.
import '../../core/models/api_response.dart';
import '../../core/network/api_client.dart';

class ApiService {
  final ApiClient client;

  ApiService({required this.client});

  Future<ApiResponse<T>> get<T>({required String url, Map<String, dynamic>? params, Map<String, String>? headers}) {
    return client.get<T>(url: url, params: params, headers: headers);
  }

  Future<ApiResponse<T>> post<T>({required String url, dynamic body, Map<String, dynamic>? params, Map<String, String>? headers}) {
    return client.post<T>(url: url, body: body, params: params, headers: headers);
  }

  Future<ApiResponse<T>> put<T>({required String url, dynamic body, Map<String, dynamic>? params, Map<String, String>? headers}) {
    return client.put<T>(url: url, body: body, params: params, headers: headers);
  }

  Future<ApiResponse<T>> delete<T>({required String url, Map<String, dynamic>? params, Map<String, String>? headers}) {
    return client.delete<T>(url: url, params: params, headers: headers);
  }
}
