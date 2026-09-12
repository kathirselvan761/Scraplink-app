import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/collector.dart';

/// Service for authenticating collectors using the existing ScrapLink Backend Auth API.
class AuthService {
  final ApiClient _client;

  AuthService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Authenticate against existing backend endpoint POST /api/auth/login
  Future<({String token, Collector collector})> login({
    required String identifier,
    required String password,
  }) async {
    final cleanIdentifier = identifier.trim();

    final response = await _client.post(
      ApiConstants.authLogin,
      body: {
        'email': cleanIdentifier,
        'password': password,
      },
    );

    if (response is Map<String, dynamic>) {
      final token = response['token']?.toString();
      final userData = response['user'] ?? response['data'];

      if (token == null || token.isEmpty) {
        throw const ApiException(
          message: 'Invalid response from server: Authentication token missing.',
        );
      }

      if (userData is! Map<String, dynamic>) {
        throw const ApiException(
          message: 'Invalid response from server: User profile data missing.',
        );
      }

      final collector = Collector.fromJson(userData);

      // Verify collector role
      final role = (collector.role).toLowerCase();
      if (role != 'collector') {
        throw ApiException.fromHttp(
          statusCode: 403,
          message: 'Access Restricted: This application is only for verified collectors. Your role is: $role',
        );
      }

      return (token: token, collector: collector);
    }

    throw const FormatException('Unexpected response format from auth server');
  }

  /// Fetch current user profile via GET /api/auth/me
  Future<Collector> getProfile() async {
    final response = await _client.get(ApiConstants.authMe);

    if (response is Map<String, dynamic>) {
      final userData = response['user'] ?? response['data'] ?? response;
      if (userData is Map<String, dynamic>) {
        return Collector.fromJson(userData);
      }
    }

    throw const FormatException('Unexpected response format for user profile');
  }
}
