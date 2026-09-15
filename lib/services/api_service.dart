import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// Global callback when a 401 Unauthorized response is received
  static VoidCallback? onUnauthorized;

  final Duration _timeoutDuration = const Duration(seconds: 15);

  Future<Map<String, String>> _getHeaders([Map<String, String>? extraHeaders]) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = await StorageService.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  Uri _buildUri(String endpoint) {
    final base = ApiConfig.baseUrl.endsWith('/')
        ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
        : ApiConfig.baseUrl;
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return Uri.parse('$base$path');
  }

  dynamic _processResponse(http.Response response, {String? endpoint}) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    // 401: Auto-logout and redirect ONLY if this is not a login/register request
    final isAuthEndpoint = endpoint != null &&
        (endpoint.contains('/auth/login') || endpoint.contains('/auth/register'));

    if (response.statusCode == 401) {
      String message = 'Invalid email or password';
      if (decoded is Map<String, dynamic>) {
        message = decoded['message'] ?? decoded['error'] ?? message;
      }
      if (!isAuthEndpoint) {
        StorageService.clear();
        onUnauthorized?.call();
      }
      throw ApiException(message, 401);
    }

    // 500: Friendly server error
    if (response.statusCode >= 500) {
      String message = 'Something went wrong. Try again.';
      if (decoded is Map<String, dynamic>) {
        message = decoded['message'] ?? decoded['error'] ?? message;
      }
      throw ApiException(message, response.statusCode);
    }

    String message = 'Server error occurred (${response.statusCode})';
    if (decoded is Map<String, dynamic>) {
      message = decoded['message'] ?? decoded['error'] ?? message;
    }
    throw ApiException(message, response.statusCode);
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? headers}) async {
    try {
      final uri = _buildUri(endpoint);
      final reqHeaders = await _getHeaders(headers);
      final response = await http.get(uri, headers: reqHeaders).timeout(_timeoutDuration);
      return _processResponse(response, endpoint: endpoint);
    } on SocketException catch (e) {
      print('API SOCKET EXCEPTION: $e');
      throw ApiException('No internet connection', 0);
    } on TimeoutException catch (e) {
      print('API TIMEOUT EXCEPTION: $e');
      throw ApiException('Server not responding', 408);
    } on http.ClientException catch (e) {
      print('API CLIENT EXCEPTION: $e');
      throw ApiException('No internet connection', 0);
    }
  }

  Future<dynamic> post(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final reqHeaders = await _getHeaders(headers);
      final payload = body != null ? (body is String ? body : jsonEncode(body)) : null;
      print('AUTH SERVICE CALL: $uri');
      final response = await http
          .post(uri, headers: reqHeaders, body: payload)
          .timeout(_timeoutDuration);
      print('AUTH SERVICE RESPONSE: ${response.statusCode} ${response.body}');
      print('AUTH SERVICE: status ${response.statusCode}');
      print('AUTH SERVICE: body ${response.body}');
      return _processResponse(response, endpoint: endpoint);
    } on SocketException catch (e) {
      print('API SOCKET EXCEPTION: $e');
      throw ApiException('No internet connection', 0);
    } on TimeoutException catch (e) {
      print('API TIMEOUT EXCEPTION: $e');
      throw ApiException('Server not responding', 408);
    } on http.ClientException catch (e) {
      print('API CLIENT EXCEPTION: $e');
      throw ApiException('No internet connection', 0);
    }
  }

  Future<dynamic> put(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final reqHeaders = await _getHeaders(headers);
      final payload = body != null ? (body is String ? body : jsonEncode(body)) : null;
      final response = await http
          .put(uri, headers: reqHeaders, body: payload)
          .timeout(_timeoutDuration);
      return _processResponse(response, endpoint: endpoint);
    } on SocketException catch (e) {
      print('API SOCKET EXCEPTION: $e');
      throw ApiException('No internet connection', 0);
    } on TimeoutException catch (e) {
      print('API TIMEOUT EXCEPTION: $e');
      throw ApiException('Server not responding', 408);
    } on http.ClientException catch (e) {
      print('API CLIENT EXCEPTION: $e');
      throw ApiException('No internet connection', 0);
    }
  }

  Future<dynamic> delete(String endpoint, {Map<String, String>? headers}) async {
    try {
      final uri = _buildUri(endpoint);
      final reqHeaders = await _getHeaders(headers);
      final response = await http.delete(uri, headers: reqHeaders).timeout(_timeoutDuration);
      return _processResponse(response, endpoint: endpoint);
    } on SocketException catch (e) {
      print('API SOCKET EXCEPTION: $e');
      throw ApiException('No internet connection', 0);
    } on TimeoutException catch (e) {
      print('API TIMEOUT EXCEPTION: $e');
      throw ApiException('Server not responding', 408);
    } on http.ClientException catch (e) {
      print('API CLIENT EXCEPTION: $e');
      throw ApiException('No internet connection', 0);
    }
  }

  Future<dynamic> postMultipart(
    String endpoint, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final request = http.MultipartRequest('POST', uri);

      final token = await StorageService.getToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      if (headers != null) {
        request.headers.addAll(headers);
      }

      if (fields != null) {
        request.fields.addAll(fields);
      }
      if (files != null) {
        request.files.addAll(files);
      }

      final streamedResponse = await request.send().timeout(_timeoutDuration);
      final response = await http.Response.fromStream(streamedResponse);
      print('API MULTIPART RESPONSE: ${response.statusCode} ${response.body}');
      return _processResponse(response, endpoint: endpoint);
    } on SocketException catch (e) {
      print('API SOCKET EXCEPTION: $e');
      throw ApiException('No internet connection', 0);
    } on TimeoutException catch (e) {
      print('API TIMEOUT EXCEPTION: $e');
      throw ApiException('Server not responding', 408);
    } on http.ClientException catch (e) {
      print('API CLIENT EXCEPTION: $e');
      throw ApiException('No internet connection', 0);
    }
  }
}
