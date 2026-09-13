import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';

/// Environment and runtime configuration for ScrapLink Collector app.
class AppConfig extends ChangeNotifier {
  static const String _prefKeyBaseUrl = 'scraplink_custom_base_url';

  // Support both compile-time --dart-define=API_BASE_URL=... and --dart-define=API_URL=...
  static const String _definedBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: String.fromEnvironment('API_URL', defaultValue: ''),
  );

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
        // Sanitize legacy "localhost" saved on physical mobile devices
        final isPhysicalMobile = !kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS);

        if (isPhysicalMobile && saved.contains('localhost')) {
          _baseUrl = ApiConstants.defaultLanBaseUrl;
          await prefs.setString(_prefKeyBaseUrl, _baseUrl);
        } else {
          _baseUrl = saved;
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Resolves initial default URL:
  /// 1. Uses `--dart-define=API_BASE_URL=...` or `API_URL` if passed during compilation.
  /// 2. For physical Android/iOS phones, defaults to PC LAN IP (`http://192.168.1.18:5000/api`).
  /// 3. For Desktop/Web, defaults to `http://localhost:5000/api`.
  static AppConfig _createDefaultConfig() {
    if (_definedBaseUrl.isNotEmpty) {
      return AppConfig(baseUrl: _definedBaseUrl);
    }

    final isPhysicalMobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    if (isPhysicalMobile) {
      return AppConfig(baseUrl: ApiConstants.defaultLanBaseUrl);
    }

    return AppConfig(baseUrl: ApiConstants.defaultLocalBaseUrl);
  }

  /// Check health of backend on specified URL or current base URL
  Future<bool> checkHealth([String? targetUrl]) async {
    final testUrl = targetUrl ?? baseUrl;
    try {
      final client = ApiClient(
        config: copyWith(
          baseUrl: testUrl,
          connectTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
          enableLogging: false,
        ),
      );
      final res = await client.get(ApiConstants.health);
      if (res is Map && (res['success'] == true || res['database'] != null)) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Automatically tests current gateway and falls back to alternate reachable development endpoint
  Future<String?> autoDiscoverGateway() async {
    if (await checkHealth()) {
      return baseUrl;
    }

    // Candidate development endpoints in priority order
    final candidates = [
      ApiConstants.usbAdbReverseBaseUrl, // 127.0.0.1:5000 (USB adb reverse)
      ApiConstants.defaultLanBaseUrl,    // 192.168.1.18:5000 (Wi-Fi LAN)
    ];

    for (final candidate in candidates) {
      if (candidate != baseUrl && await checkHealth(candidate)) {
        await updateBaseUrl(candidate);
        return candidate;
      }
    }

    return null;
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
