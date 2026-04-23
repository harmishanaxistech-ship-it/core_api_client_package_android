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

## License

MIT
