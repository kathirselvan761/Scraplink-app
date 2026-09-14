import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<dynamic> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final body = {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'role': 'collector',
    };

    return await _api.post(ApiConfig.register, body: body);
  }

  Future<UserModel> login(String email, String password) async {
    final url = '${ApiConfig.baseUrl}${ApiConfig.login}';
    print('AUTH SERVICE CALL: $url');
    print('AUTH SERVICE: calling /auth/login');

    final response = await _api.post(
      ApiConfig.login,
      body: {
        'email': email,
        'password': password,
      },
    );

    print('AUTH SERVICE: parsed response: $response');

    // Support responses in format { token, user } or { success: true, data: { token, user } }
    Map<String, dynamic> data = response is Map<String, dynamic> ? response : {};
    if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
      data = data['data'] as Map<String, dynamic>;
    }

    final token = data['token'] ?? (response is Map ? response['token'] : null);
    dynamic userMap = data['user'] ?? data['collector'] ?? (response is Map ? (response['user'] ?? response['collector']) : null);

    if (userMap == null && data.containsKey('email') && data.containsKey('role')) {
      userMap = data;
    }

    if (userMap == null || userMap is! Map<String, dynamic>) {
      throw ApiException('Invalid response received from server: missing user data.');
    }

    final role = (userMap['role'] ?? '').toString().toLowerCase();
    if (role != 'collector') {
      throw ApiException('This app is for collectors only. Please use the web portal.');
    }

    if (token != null) {
      await StorageService.saveToken(token.toString());
      print('AUTH SERVICE: token saved successfully');
    }
    await StorageService.saveUser(userMap);
    print('AUTH SERVICE: user saved successfully');

    return UserModel.fromJson(userMap);
  }

  Future<UserModel?> getMe() async {
    final response = await _api.get(ApiConfig.me);
    Map<String, dynamic> data = response is Map<String, dynamic> ? response : {};
    if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
      data = data['data'] as Map<String, dynamic>;
    }
    final userMap = data['user'] ?? data;
    if (userMap is Map<String, dynamic>) {
      await StorageService.saveUser(userMap);
      return UserModel.fromJson(userMap);
    }
    return null;
  }

  Future<void> logout() async {
    await StorageService.clear();
  }
}
