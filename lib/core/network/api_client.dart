import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../constants/api_constants.dart';
import 'api_exception.dart';

/// Reusable HTTP client supporting GET, POST, PUT, PATCH, DELETE
/// with error classification, timeout management, auth headers, and JSON parsing.
class ApiClient {
  final http.Client _httpClient;
  final AppConfig _config;
  String? _authToken;

  ApiClient({
    http.Client? httpClient,
    AppConfig? config,
  })  : _httpClient = httpClient ?? http.Client(),
        _config = config ?? AppConfig.current;

  /// Set the active authorization token (Bearer token)
  void setAuthToken(String? token) {
    _authToken = token;
  }

  /// Get current authorization token
  String? get authToken => _authToken;

  /// Clear active authorization token
  void clearAuthToken() {
    _authToken = null;
  }

  /// Perform a GET request
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    return _sendRequest(
      method: 'GET',
      endpoint: endpoint,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  /// Perform a POST request
  Future<dynamic> post(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    return _sendRequest(
      method: 'POST',
      endpoint: endpoint,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  /// Perform a PUT request
  Future<dynamic> put(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    return _sendRequest(
      method: 'PUT',
      endpoint: endpoint,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  /// Perform a PATCH request
  Future<dynamic> patch(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    return _sendRequest(
      method: 'PATCH',
      endpoint: endpoint,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  /// Perform a DELETE request
  Future<dynamic> delete(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    return _sendRequest(
      method: 'DELETE',
      endpoint: endpoint,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  /// Perform a multipart POST request (e.g. for photo uploads)
  Future<dynamic> multipartPost(
    String endpoint, {
    required Map<String, String> fields,
    String? fileField,
    String? filePath,
    Uint8List? fileBytes,
    String? fileName,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(endpoint, null);
    final request = http.MultipartRequest('POST', uri);

    if (_authToken != null && _authToken!.isNotEmpty) {
      request.headers[ApiConstants.headerAuthorization] = 'Bearer $_authToken';
    }
    if (headers != null) {
      request.headers.addAll(headers);
    }

    request.fields.addAll(fields);

    if (fileField != null) {
      if (filePath != null && filePath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(fileField, filePath));
      } else if (fileBytes != null && fileName != null) {
        request.files.add(http.MultipartFile.fromBytes(fileField, fileBytes, filename: fileName));
      }
    }

    if (_config.enableLogging) {
      debugPrint('[ApiClient] MULTIPART POST $uri (fields: ${request.fields.keys.toList()})');
    }

    try {
      final streamedResponse = await _httpClient
          .send(request)
          .timeout(_config.connectTimeout);

      final response = await http.Response.fromStream(streamedResponse)
          .timeout(_config.receiveTimeout);

      return _handleResponse(response, uri);
    } on TimeoutException {
      throw ApiException.timeout(
        message: 'Connection timed out connecting to $uri after ${_config.connectTimeout.inSeconds}s.',
        uri: uri,
      );
    } on SocketException catch (e) {
      throw ApiException.unreachable(
        message: 'Unable to reach backend server at $uri (${e.message}).',
        uri: uri,
      );
    } on http.ClientException catch (e) {
      throw ApiException.unreachable(
        message: 'Network client error connecting to $uri: ${e.message}',
        uri: uri,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Unexpected network error during upload: $e',
        attemptedUri: uri,
      );
    }
  }

  /// Core HTTP execution pipeline
  Future<dynamic> _sendRequest({
    required String method,
    required String endpoint,
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(endpoint, queryParameters);
    final requestHeaders = _buildHeaders(headers);

    if (_config.enableLogging) {
      debugPrint('[ApiClient] $method $uri');
    }

    try {
      final request = http.Request(method, uri);
      request.headers.addAll(requestHeaders);

      if (body != null) {
        if (body is String) {
          request.body = body;
        } else {
          request.body = jsonEncode(body);
        }
      }

      final streamedResponse = await _httpClient
          .send(request)
          .timeout(_config.connectTimeout);

      final response = await http.Response.fromStream(streamedResponse)
          .timeout(_config.receiveTimeout);

      return _handleResponse(response, uri);
    } on TimeoutException {
      throw ApiException.timeout(
        message: 'Connection timed out connecting to $uri after ${_config.connectTimeout.inSeconds}s.',
        uri: uri,
      );
    } on SocketException catch (e) {
      throw ApiException.unreachable(
        message: 'Unable to reach backend server at $uri (${e.message}).',
        uri: uri,
      );
    } on http.ClientException catch (e) {
      throw ApiException.unreachable(
        message: 'Network client error connecting to $uri: ${e.message}',
        uri: uri,
      );
    } on FormatException catch (e) {
      throw ApiException(
        message: 'Invalid response format from server: ${e.message}',
        attemptedUri: uri,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Unexpected network error: $e',
        attemptedUri: uri,
      );
    }
  }

  /// Build complete URI incorporating base URL, relative endpoint, and query params
  Uri _buildUri(String endpoint, Map<String, dynamic>? queryParameters) {
    String cleanBase = _config.baseUrl.endsWith('/')
        ? _config.baseUrl.substring(0, _config.baseUrl.length - 1)
        : _config.baseUrl;

    String cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    String fullUrl = '$cleanBase$cleanEndpoint';

    final uri = Uri.parse(fullUrl);

    if (queryParameters != null && queryParameters.isNotEmpty) {
      final sanitizedParams = <String, String>{};
      queryParameters.forEach((key, value) {
        if (value != null) {
          sanitizedParams[key] = value.toString();
        }
      });
      return uri.replace(queryParameters: {
        ...uri.queryParameters,
        ...sanitizedParams,
      });
    }

    return uri;
  }

  /// Merge standard headers, authentication header, and custom headers
  Map<String, String> _buildHeaders(Map<String, String>? customHeaders) {
    final headers = <String, String>{
      ApiConstants.headerContentType: ApiConstants.contentTypeJson,
    };

    if (_authToken != null && _authToken!.isNotEmpty) {
      headers[ApiConstants.headerAuthorization] = 'Bearer $_authToken';
    }

    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    return headers;
  }

  /// Parse response status and decode JSON payload
  dynamic _handleResponse(http.Response response, Uri requestUri) {
    final statusCode = response.statusCode;
    final bodyString = response.body.trim();

    dynamic parsedBody;
    if (bodyString.isNotEmpty) {
      try {
        parsedBody = jsonDecode(bodyString);
      } catch (_) {
        parsedBody = bodyString;
      }
    }

    if (statusCode >= 200 && statusCode < 300) {
      return parsedBody;
    }

    // Extract error message from server response if available
    String errorMessage = 'HTTP Error $statusCode';
    if (parsedBody is Map<String, dynamic>) {
      if (parsedBody.containsKey('message')) {
        errorMessage = parsedBody['message'].toString();
      } else if (parsedBody.containsKey('error')) {
        errorMessage = parsedBody['error'].toString();
      }
    } else if (statusCode == 401) {
      errorMessage = 'Invalid email or password.';
    } else if (statusCode == 404) {
      errorMessage = 'Endpoint not found: ${requestUri.path}';
    }

    throw ApiException.fromHttp(
      statusCode: statusCode,
      message: errorMessage,
      responseBody: parsedBody,
      uri: requestUri,
    );
  }

  /// Closes underlying client
  void close() {
    _httpClient.close();
  }
}
