import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool? mockIsOnline;

  bool get isOnline => mockIsOnline ?? _isOnline;

  Future<void> initialize(void Function(bool isOnline) onStatusChange) async {
    if (mockIsOnline != null) {
      _isOnline = mockIsOnline!;
      onStatusChange(_isOnline);
      return;
    }
    try {
      final results = await _connectivity.checkConnectivity();
      _isOnline = _checkIsOnline(results);
      onStatusChange(_isOnline);

      _subscription = _connectivity.onConnectivityChanged.listen((results) {
        final online = _checkIsOnline(results);
        if (online != _isOnline) {
          _isOnline = online;
          onStatusChange(_isOnline);
        }
      });
    } catch (_) {
      _isOnline = true; // Fallback to online if plugin error
    }
  }

  bool _checkIsOnline(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return !results.every((r) => r == ConnectivityResult.none);
  }

  Future<bool> checkConnection() async {
    if (mockIsOnline != null) {
      _isOnline = mockIsOnline!;
      return _isOnline;
    }
    try {
      final results = await _connectivity.checkConnectivity();
      _isOnline = _checkIsOnline(results);
      return _isOnline;
    } catch (_) {
      return true;
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
