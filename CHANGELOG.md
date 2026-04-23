## 1.1.0

* Renamed package to `core_api_client`.
* Updated API methods to use named parameters (`url`, `body`, `params`, `headers`).
* Added automatic `File` detection in `post` body for easier uploads.
* Improved debug logging format with clear separators and pretty-printed JSON.

## 1.0.0

* Initial release.
* Features:
    * Singleton ApiClient wrapping Dio.
    * Support for GET, POST, PUT, DELETE.
    * File upload (multipart) support.
    * Interceptors: Logging, Auth, Retry (exponential backoff).
    * Configurable timeouts, headers, and base URL.
    * ApiResponse wrapper and ApiException for structured errors.
