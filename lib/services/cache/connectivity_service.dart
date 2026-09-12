import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;

  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  bool _isOnline = true;
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Stream<bool> get connectivityStream => _connectivityController.stream;
  bool get isOnline => _isOnline;

  /// Start listening to real connectivity changes
  void startListening() {
    _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final hasConnection = results.isNotEmpty &&
          !results.contains(ConnectivityResult.none);
      setOnlineStatus(hasConnection);
    });
  }

  /// Check current connectivity synchronously
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final hasConnection = results.isNotEmpty &&
          !results.contains(ConnectivityResult.none);
      setOnlineStatus(hasConnection);
      return hasConnection;
    } catch (e) {
      setOnlineStatus(false);
      return false;
    }
  }

  void setOnlineStatus(bool online) {
    if (_isOnline != online) {
      _isOnline = online;
      _connectivityController.add(_isOnline);
      debugPrint('🌐 Connectivity changed: ${online ? "ONLINE" : "OFFLINE"}');
    }
  }

  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
  }
}
