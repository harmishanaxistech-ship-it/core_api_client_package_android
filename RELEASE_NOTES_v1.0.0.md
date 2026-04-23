# Release v1.0.0

## Highlights

- Initial stable release of core_api_client_package
- Features: ApiClient singleton, GET/POST/PUT/DELETE, file upload, interceptors (auth, logging, retry), ApiResponse/ApiException types
- Added structured logging with pretty JSON
- Added tests and CI workflow

## Patch notes

- feat(logging): structured pretty API logs
- feat(logging): add truncation & redaction options (maxBodyChars, redactHeaders, sensitiveHeaders)
- docs: add logging truncation and redaction guidance
- test: add interceptor and ApiException unit tests
- ci: add coverage upload step

## Usage

Pin to v1.0.0 in your pubspec.yaml:

core_api_client_package:
  git:
    url: https://github.com/harmishanaxistech-ship-it/core_api_client_package_android.git
    ref: v1.0.0

