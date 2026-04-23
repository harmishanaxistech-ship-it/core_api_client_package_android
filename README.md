# core_api_client_package

A lightweight Flutter package providing a production-ready API client built on Dio.

## Features

- Singleton ApiClient wrapping Dio
- GET, POST, PUT, DELETE methods
- File upload (multipart)
- Interceptors: Logging, Auth, Retry (exponential backoff)
- Configurable timeouts, headers, base URL, and retry count
- ApiResponse wrapper and ApiException for structured errors

## Quick start

1. Initialize the client (e.g. in main):

```dart
ApiClient.initialize(
  config: NetworkConfig(
    baseUrl: 'https://api.example.com',
    maxRetries: 3,
    timeout: Duration(seconds: 15),
  ),
  tokenProvider: () async => await mySecureStorage.read('token'),
  enableLogging: true,
);
```

2. Make calls:

```dart
final res = await ApiClient.instance.get<Map<String, dynamic>>('/status');
if (res.success) print(res.data); else print(res.error);
```

3. Upload a file (example):

```dart
final file = File('/path/to/file');
final res = await ApiClient.instance.uploadFile('/upload', file);
```

## Example app

See `example/lib/main.dart` for a simple example showing:
- Basic GET call
- File upload demo (creates a small temp file)
- Retry demo that triggers the retry interceptor by calling an unreachable IP

## Notes

- Replace tokenProvider with secure storage in production
- Logging uses `dart:developer.log` for safer production logging
- Keep retry counts and timeouts conservative in production

## Logging options (truncate & redact)

The LoggingInterceptor prints pretty JSON by default. To avoid printing very large bodies or sensitive headers (Authorization, Cookie), use these patterns:

1) Truncate large bodies

- Add a simple helper to the interceptor to truncate stringified bodies:

```dart
const int _maxBodyChars = 10240; // 10 KB
String _shorten(String s) {
  if (s.length <= _maxBodyChars) return s;
  return s.substring(0, _maxBodyChars) + '\n... (truncated, ${s.length} bytes)';
}
```

- Use `_shorten(_prettyJson(body))` when writing BODY to the log.

2) Redact sensitive headers

- Provide a set of headers to redact and replace their values with `"<REDACTED>"`:

```dart
final _sensitiveHeaders = {'authorization', 'cookie', 'set-cookie'};
Map<String, dynamic> _redactHeaders(Map<String, dynamic> headers) {
  final out = <String, dynamic>{};
  headers.forEach((k, v) {
    if (_sensitiveHeaders.contains(k.toLowerCase())) {
      out[k] = '<REDACTED>';
    } else {
      out[k] = v;
    }
  });
  return out;
}
```

- Call `_redactHeaders(_normalizeHeaders(options.headers))` before pretty printing.

3) Configuration

- To expose truncation/redaction as options, add constructor parameters to `LoggingInterceptor`:

```dart
LoggingInterceptor({this.enabled = true, this.maxBodyChars = 10240, this.redactHeaders = true});
```

Then apply the logic above using the instance fields.

---

## License

MIT
