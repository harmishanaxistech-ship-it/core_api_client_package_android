/// Network configuration for ApiClient.
class NetworkConfig {
  /// Base URL of the API (e.g. https://api.example.com)
  final String baseUrl;

  /// Default headers applied to every request
  final Map<String, String> defaultHeaders;

  /// Request timeout
  final Duration timeout;

  /// Number of automatic retry attempts (for idempotent operations / network errors)
  final int maxRetries;

  const NetworkConfig({
    required this.baseUrl,
    this.defaultHeaders = const {},
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 2,
  });
}
