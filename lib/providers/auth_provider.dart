import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null && _currentUser != null;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void setUser(UserModel? user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<bool> checkAuthStatus() async {
    _setLoading(true);
    _setError(null);
    try {
      final storedToken = await StorageService.getToken();
      if (storedToken == null || storedToken.isEmpty) {
        _token = null;
        _currentUser = null;
        return false;
      }

      _token = storedToken;

      // Try reading user from storage first
      final userMap = await StorageService.getUser();
      if (userMap != null) {
        _currentUser = UserModel.fromJson(userMap);
      }

      // Refresh user profile from backend
      try {
        final refreshedUser = await _authService.getMe();
        if (refreshedUser != null) {
          _currentUser = refreshedUser;
        }
      } catch (_) {
        // If offline, keep cached user
      }

      return _currentUser != null;
    } catch (e) {
      _errorMessage = e.toString();
      _token = null;
      _currentUser = null;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login(String email, String password) async {
    print('AUTH PROVIDER LOGIN START');
    _setLoading(true);
    _setError(null);
    try {
      final user = await _authService.login(email.trim(), password);
      _currentUser = user;
      _token = await StorageService.getToken();
      print('AUTH PROVIDER: user logged in: ${user.email}');
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      print('AUTH PROVIDER ApiException: ${e.message}');
      _setError(e.message);
      return false;
    } catch (e) {
      print('AUTH PROVIDER Exception: $e');
      _setError('Login failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      await _authService.register(
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        password: password,
      );
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Registration failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.logout();
    } catch (_) {}
    _currentUser = null;
    _token = null;
    _errorMessage = null;
    _setLoading(false);
  }
}
