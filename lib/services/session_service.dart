import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/collector.dart';

/// Service managing persistent storage of the collector's authentication session.
class SessionService {
  static const String _keyToken = 'scraplink_collector_token';
  static const String _keyUser = 'scraplink_collector_user';

  SharedPreferences? _prefs;

  SessionService({SharedPreferences? prefs}) : _prefs = prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Save token and collector profile to disk
  Future<void> saveSession({
    required String token,
    required Collector collector,
  }) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUser, jsonEncode(collector.toJson()));
  }

  /// Retrieve saved authentication token if present
  Future<String?> getToken() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyToken);
  }

  /// Retrieve saved collector profile if present
  Future<Collector?> getCollector() async {
    final prefs = await _getPrefs();
    final userJson = prefs.getString(_keyUser);
    if (userJson == null || userJson.isEmpty) return null;

    try {
      final map = jsonDecode(userJson) as Map<String, dynamic>;
      return Collector.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Clear session data (logout)
  Future<void> clearSession() async {
    final prefs = await _getPrefs();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
  }

  /// Whether a session exists
  Future<bool> hasValidSession() async {
    final token = await getToken();
    final collector = await getCollector();
    return token != null && token.isNotEmpty && collector != null;
  }
}
