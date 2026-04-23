// Lightweight wrapper for API results.
class ApiResponse<T> {
  final T? data;
  final bool success;
  final Object? error;

  const ApiResponse({this.data, this.success = true, this.error});

  factory ApiResponse.success(T data) => ApiResponse(data: data, success: true);
  factory ApiResponse.failure(Object error) => ApiResponse(data: null, success: false, error: error);
}
