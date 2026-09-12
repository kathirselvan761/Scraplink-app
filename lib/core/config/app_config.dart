import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

/// Environment and runtime configuration for ScrapLink Collector app.
class AppConfig extends ChangeNotifier {
  static const String _prefKeyBaseUrl = 'scraplink_custom_base_url';
  static const String _definedBaseUrl = String.fromEnvironment('API_URL');

  String _baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final bool enableLogging;

  AppConfig({
    required String baseUrl,
    this.connectTimeout = const Duration(seconds: 12),
    this.receiveTimeout = const Duration(seconds: 12),
    this.enableLogging = true,
  }) : _baseUrl = baseUrl;

  String get baseUrl => _baseUrl;

  static AppConfig? _current;

  /// Active runtime configuration.
  static AppConfig get current {
    _current ??= _createDefaultConfig();
    return _current!;
  }

  /// Override active configuration
  static void setConfiguration(AppConfig config) {
    _current = config;
  }

  /// Update the base URL dynamically and persist it
  Future<void> updateBaseUrl(String newUrl) async {
    final clean = newUrl.trim();
    if (clean.isEmpty) return;

    _baseUrl = clean.endsWith('/') ? clean.substring(0, clean.length - 1) : clean;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyBaseUrl, _baseUrl);
    } catch (_) {}
  }

  /// Load any persisted URL from SharedPreferences at startup
  Future<void> loadPersistedUrl() async {
    if (_definedBaseUrl.isNotEmpty) {
      _baseUrl = _definedBaseUrl;
      notifyListeners();
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKeyBaseUrl);
      if (saved != null && saved.isNotEmpty) {
        _baseUrl = saved;
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Resolves initial default URL:
  /// 1. Uses `--dart-define=API_URL=...` if passed during compilation.
  /// 2. Defaults to `http://localhost:5000/api` (works for Desktop/Web and physical Android via `adb reverse tcp:5000 tcp:5000`).
  static AppConfig _createDefaultConfig() {
    if (_definedBaseUrl.isNotEmpty) {
      return AppConfig(baseUrl: _definedBaseUrl);
    }

    // Default to localhost:5000/api (paired with adb reverse for USB, or LAN IP option)
    return AppConfig(baseUrl: ApiConstants.defaultLocalBaseUrl);
  }

  AppConfig copyWith({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    bool? enableLogging,
  }) {
    return AppConfig(
      baseUrl: baseUrl ?? _baseUrl,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      enableLogging: enableLogging ?? this.enableLogging,
    );
  }
}
