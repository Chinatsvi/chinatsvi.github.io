import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
class AuthStateManager {
  static final AuthStateManager _instance = AuthStateManager._internal();
  factory AuthStateManager() => _instance;
  AuthStateManager._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  SharedPreferences? _prefs;

  final StreamController<AuthState> _authStateController =
      StreamController<AuthState>.broadcast();
  Stream<AuthState> get authStateStream => _authStateController.stream;

  AuthState _currentState = AuthState.initial();
  AuthState get currentState => _currentState;

  Timer? _stabilizationTimer;
  Timer? _timeoutTimer;
  DateTime? _startTime;

  static const String _keyUserId = 'auth_user_id';
  static const String _keyLastLogin = 'auth_last_login';
  static const String _keySessionValid = 'auth_session_valid';

  static const Duration _stabilizationDelay = Duration(milliseconds: 500);
  static const Duration _maxWaitTime = Duration(seconds: 5);
  static const int _minTrustTimeMs = 3000;

  Future<void> initialize() async {
    debugPrint('🔐 [AUTH_MANAGER] Initializing...');

    _prefs = await SharedPreferences.getInstance();

    final cachedUserId = _prefs?.getString(_keyUserId);
    final sessionValid = _prefs?.getBool(_keySessionValid) ?? false;

    if (cachedUserId != null && sessionValid) {
      debugPrint('🔐 Cached session found: $cachedUserId');
      _updateState(AuthState.loading(cachedUserId));
    }

    _listenToAuthState();
  }

  void _listenToAuthState() {
    debugPrint('🔐 Listening to Firebase auth state...');
    _startTime = DateTime.now();

    // ALWAYS listen (no early return)
    _auth.authStateChanges().listen(
      (User? user) {
        _stabilizationTimer?.cancel();

        final elapsedMs =
            DateTime.now().difference(_startTime!).inMilliseconds;

        // Ignore early nulls
        if (user == null && elapsedMs < _minTrustTimeMs) {
          debugPrint('⏳ Ignoring early null ($elapsedMs ms)');
          return;
        }

        _stabilizationTimer = Timer(_stabilizationDelay, () {
          if (user != null) {
            debugPrint('✅ Authenticated: ${user.uid}');
            _handleAuthenticated(user);
          } else {
            debugPrint('⚠️ Firebase says unauthenticated');

            // ❗ DO NOT immediately trust this
            _handlePossibleLogout();
          }
        });
      },
      onError: (error) {
        debugPrint('❌ Auth error: $error');
        _handleError(error);
      },
    );

    // Timeout fallback
    _timeoutTimer = Timer(_maxWaitTime, () {
      debugPrint('⏱️ Timeout reached');

      final user = _auth.currentUser;

      if (user != null) {
        _handleAuthenticated(user);
      } else {
        _handlePossibleLogout();
      }
    });
  }

  /// 🔥 SAFE logout handling
  void _handlePossibleLogout() {
    final cachedUserId = _prefs?.getString(_keyUserId);
    final lastLogin = _prefs?.getInt(_keyLastLogin) ?? 0;
    final sessionValid = _prefs?.getBool(_keySessionValid) ?? false;

    final sessionAge =
        DateTime.now().millisecondsSinceEpoch - lastLogin;

    final maxAge = 30 * 24 * 60 * 60 * 1000;

    if (cachedUserId != null &&
        sessionValid &&
        sessionAge < maxAge) {
      debugPrint('🔄 Keeping session alive (retrying)');
      _updateState(AuthState.retrying(cachedUserId));

      // Retry instead of logout
      Future.delayed(const Duration(seconds: 2), () {
        final retryUser = _auth.currentUser;

        if (retryUser != null) {
          _handleAuthenticated(retryUser);
        } else {
          debugPrint('⏳ Still waiting for Firebase...');
          // DO NOTHING — wait for stream again
        }
      });
    } else {
      debugPrint('🚪 Confirmed logout');
      _handleUnauthenticated();
    }
  }

  void _handleAuthenticated(User user) {
    _timeoutTimer?.cancel();
    _stabilizationTimer?.cancel();

    _persistSession(user.uid);

    _updateState(AuthState.authenticated(user.uid));
  }

  void _handleUnauthenticated() {
    _timeoutTimer?.cancel();
    _stabilizationTimer?.cancel();

    _clearSession();

    _updateState(AuthState.unauthenticated());
  }

  void _handleError(dynamic error) {
    _timeoutTimer?.cancel();
    _stabilizationTimer?.cancel();

    _updateState(AuthState.error(error.toString()));
  }

  void _updateState(AuthState newState) {
    debugPrint('🔐 State: ${newState.status}');
    _currentState = newState;
    _authStateController.add(newState);
  }

  Future<void> _persistSession(String userId) async {
    await _prefs?.setString(_keyUserId, userId);
    await _prefs?.setInt(
        _keyLastLogin, DateTime.now().millisecondsSinceEpoch);
    await _prefs?.setBool(_keySessionValid, true);
  }

  Future<void> _clearSession() async {
    await _prefs?.remove(_keyUserId);
    await _prefs?.remove(_keyLastLogin);
    await _prefs?.setBool(_keySessionValid, false);
  }

  Future<void> onLogin(String userId) async {
    await _persistSession(userId);
    _updateState(AuthState.authenticated(userId));
  }

  Future<void> onLogout() async {
    await _clearSession();
    _updateState(AuthState.unauthenticated());
  }

  void dispose() {
    _stabilizationTimer?.cancel();
    _timeoutTimer?.cancel();
    _authStateController.close();
  }
}

class AuthState {
  final AuthStatus status;
  final String? userId;
  final String? errorMessage;

  const AuthState._({
    required this.status,
    this.userId,
    this.errorMessage,
  });

  factory AuthState.initial() =>
      const AuthState._(status: AuthStatus.initial);

  factory AuthState.loading(String? userId) =>
      AuthState._(status: AuthStatus.loading, userId: userId);

  factory AuthState.authenticated(String userId) =>
      AuthState._(status: AuthStatus.authenticated, userId: userId);

  factory AuthState.unauthenticated() =>
      const AuthState._(status: AuthStatus.unauthenticated);

  factory AuthState.error(String message) =>
      AuthState._(status: AuthStatus.error, errorMessage: message);

  factory AuthState.retrying(String userId) =>
      AuthState._(status: AuthStatus.retrying, userId: userId);

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading =>
      status == AuthStatus.loading || status == AuthStatus.initial;
}

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
  retrying,
}