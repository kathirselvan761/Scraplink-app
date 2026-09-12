import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/collector.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';

/// Repository managing collector authentication lifecycle, token persistence,
/// and session state across the app.
class AuthRepository extends ChangeNotifier {
  final AuthService _authService;
  final SessionService _sessionService;
  final ApiClient _apiClient;

  Collector? _currentCollector;
  String? _currentToken;
  bool _isInitialized = false;

  AuthRepository({
    AuthService? authService,
    SessionService? sessionService,
    ApiClient? apiClient,
  })  : _apiClient = apiClient ?? ApiClient(),
        _authService = authService ?? AuthService(client: apiClient),
        _sessionService = sessionService ?? SessionService();

  static AuthRepository? _instance;

  /// Global singleton instance for easy app-wide state access
  static AuthRepository get instance {
    _instance ??= AuthRepository();
    return _instance!;
  }

  /// Active logged in collector
  Collector? get currentCollector => _currentCollector;

  /// Active auth token
  String? get currentToken => _currentToken;

  /// Whether collector is currently authenticated
  bool get isAuthenticated => _currentCollector != null && _currentToken != null;

  /// Whether initial session check has completed
  bool get isInitialized => _isInitialized;

  /// Initialize and restore any persisted session from disk
  Future<bool> restoreSession() async {
    try {
      final token = await _sessionService.getToken();
      final collector = await _sessionService.getCollector();

      if (token != null && token.isNotEmpty && collector != null) {
        _currentToken = token;
        _currentCollector = collector;
        _apiClient.setAuthToken(token);
        _isInitialized = true;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('[AuthRepository] Error restoring session: $e');
    }

    _currentCollector = null;
    _currentToken = null;
    _apiClient.clearAuthToken();
    _isInitialized = true;
    notifyListeners();
    return false;
  }

  /// Perform login against existing backend
  Future<Collector> login({
    required String identifier,
    required String password,
  }) async {
    final result = await _authService.login(
      identifier: identifier,
      password: password,
    );

    _currentToken = result.token;
    _currentCollector = result.collector;
    _apiClient.setAuthToken(result.token);

    // Persist session to disk
    await _sessionService.saveSession(
      token: result.token,
      collector: result.collector,
    );

    notifyListeners();
    return result.collector;
  }

  /// Perform logout, clearing session and headers
  Future<void> logout() async {
    try {
      await _sessionService.clearSession();
    } catch (e) {
      debugPrint('[AuthRepository] Error clearing session: $e');
    }

    _currentToken = null;
    _currentCollector = null;
    _apiClient.clearAuthToken();
    notifyListeners();
  }
}
