## 1.0.0

* Initial release.
* Features:
    * Singleton ApiClient wrapping Dio.
    * Support for GET, POST, PUT, DELETE.
    * File upload (multipart) support.
    * Interceptors: Logging, Auth, Retry (exponential backoff).
    * Configurable timeouts, headers, and base URL.
    * ApiResponse wrapper and ApiException for structured errors.
