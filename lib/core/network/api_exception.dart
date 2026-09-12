/// Classification of ScrapLink API & network failures
enum ApiExceptionType {
  timeout,
  unreachable,
  unauthorized, // 401
  forbidden,    // 403
  notFound,     // 404
  serverError,  // 500+
  clientError,  // 400
  other,
}

/// Rich exception class distinguishing unreachable backend, timeouts, 404, 401, 500
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic responseBody;
  final ApiExceptionType type;
  final Uri? attemptedUri;

  const ApiException({
    required this.message,
    this.statusCode,
    this.responseBody,
    this.type = ApiExceptionType.other,
    this.attemptedUri,
  });

  factory ApiException.unreachable({
    required String message,
    Uri? uri,
  }) {
    return ApiException(
      message: message,
      type: ApiExceptionType.unreachable,
      attemptedUri: uri,
    );
  }

  factory ApiException.timeout({
    String message = 'Connection timed out. Please check backend server status.',
    Uri? uri,
  }) {
    return ApiException(
      message: message,
      type: ApiExceptionType.timeout,
      attemptedUri: uri,
    );
  }

  factory ApiException.fromHttp({
    required int statusCode,
    required String message,
    dynamic responseBody,
    Uri? uri,
  }) {
    ApiExceptionType type;
    if (statusCode == 401) {
      type = ApiExceptionType.unauthorized;
    } else if (statusCode == 403) {
      type = ApiExceptionType.forbidden;
    } else if (statusCode == 404) {
      type = ApiExceptionType.notFound;
    } else if (statusCode >= 500) {
      type = ApiExceptionType.serverError;
    } else if (statusCode >= 400 && statusCode < 500) {
      type = ApiExceptionType.clientError;
    } else {
      type = ApiExceptionType.other;
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      responseBody: responseBody,
      type: type,
      attemptedUri: uri,
    );
  }

  bool get isTimeout => type == ApiExceptionType.timeout;
  bool get isUnreachable => type == ApiExceptionType.unreachable;
  bool get isUnauthorized => type == ApiExceptionType.unauthorized || statusCode == 401;
  bool get isForbidden => type == ApiExceptionType.forbidden || statusCode == 403;
  bool get isNotFound => type == ApiExceptionType.notFound || statusCode == 404;
  bool get isServerError => type == ApiExceptionType.serverError || (statusCode != null && statusCode! >= 500);

  /// User-friendly, actionable diagnostic message for the mobile UI
  String get userFriendlyMessage {
    final target = attemptedUri != null ? '${attemptedUri!.scheme}://${attemptedUri!.host}:${attemptedUri!.port}' : 'backend server';

    switch (type) {
      case ApiExceptionType.unreachable:
        return 'Backend Unreachable ($target).\nMake sure the backend is running and the device can reach the host via USB (adb reverse) or Wi-Fi.';
      case ApiExceptionType.timeout:
        return 'Connection Timed Out ($target).\nServer did not respond in time. Verify the IP/port and firewall settings.';
      case ApiExceptionType.unauthorized:
        return 'Invalid Credentials. Please check your Collector Email and Password.';
      case ApiExceptionType.forbidden:
        return message.isNotEmpty ? message : 'Access Forbidden (403): You are not authorized for this action.';
      case ApiExceptionType.notFound:
        return 'Endpoint Not Found (404) on $target.\nCheck API route and base URL.';
      case ApiExceptionType.serverError:
        return 'Backend Server Error (${statusCode ?? 500}):\n$message';
      case ApiExceptionType.clientError:
        return message.isNotEmpty ? message : 'Invalid request parameters ($statusCode).';
      case ApiExceptionType.other:
        return message;
    }
  }

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException [$statusCode] ($type): $message';
    }
    return 'ApiException ($type): $message';
  }
}
