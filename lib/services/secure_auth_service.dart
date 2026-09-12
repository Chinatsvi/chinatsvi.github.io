import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'google_sign_in_service.dart';

/// Service for secure token persistence and biometric authentication
/// Allows offline authentication after initial Firebase login
class SecureAuthService {
  static final SecureAuthService _instance = SecureAuthService._internal();
  factory SecureAuthService() => _instance;
  SecureAuthService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accountName: 'flutter_secure_storage_auth',
    ),
  );

  final LocalAuthentication _localAuth = LocalAuthentication();

  // Storage keys
  static const String _keyAuthToken = 'auth_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserPassword = 'user_password';  // For auto re-login
  static const String _keyTokenExpiry = 'token_expiry';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyLastLoginTime = 'last_login_time';
  static const String _keyOfflineAuthEnabled = 'offline_auth_enabled';

  /// Save auth credentials after successful Firebase login
  Future<void> saveAuthCredentials(User user, {String? refreshToken}) async {
    try {
      final token = await user.getIdToken();
      final tokenResult = await user.getIdTokenResult();
      final expiry = tokenResult.expirationTime;

      await Future.wait([
        _secureStorage.write(key: _keyAuthToken, value: token),
        if (refreshToken != null)
          _secureStorage.write(key: _keyRefreshToken, value: refreshToken),
        _secureStorage.write(key: _keyUserId, value: user.uid),
        _secureStorage.write(key: _keyUserEmail, value: user.email ?? ''),
        if (expiry != null)
          _secureStorage.write(
            key: _keyTokenExpiry,
            value: expiry.millisecondsSinceEpoch.toString(),
          ),
        _secureStorage.write(
          key: _keyLastLoginTime,
          value: DateTime.now().millisecondsSinceEpoch.toString(),
        ),
      ]);

      // Cache user profile data for offline access
      await _cacheUserProfile(user.uid);
    } catch (e) {
      print('❌ SecureAuthService: Error saving credentials: $e');
    }
  }

  /// Cache user profile from Firestore for offline access
  Future<void> _cacheUserProfile(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          await _secureStorage.write(
            key: 'cached_profile_$userId',
            value: jsonEncode(normalizeForStorage(data)),
          );
        }
      }
    } catch (e) {
      print('❌ SecureAuthService: Error caching profile: $e');
    }
  }

  static Map<String, dynamic> normalizeForStorage(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is Timestamp) {
        return MapEntry(key, value.millisecondsSinceEpoch);
      }
      if (value is DateTime) {
        return MapEntry(key, value.toIso8601String());
      }
      if (value is List) {
        return MapEntry(key, value.map((item) {
          if (item is Timestamp) return item.millisecondsSinceEpoch;
          if (item is DateTime) return item.toIso8601String();
          return item;
        }).toList());
      }
      if (value is Map<String, dynamic>) {
        return MapEntry(key, normalizeForStorage(value));
      }
      return MapEntry(key, value);
    });
  }

  /// Get cached user profile (for offline access)
  Future<Map<String, dynamic>?> getCachedProfile(String userId) async {
    try {
      final profileJson = await _secureStorage.read(
        key: 'cached_profile_$userId',
      );
      if (profileJson != null) {
        return jsonDecode(profileJson) as Map<String, dynamic>;
      }
    } catch (e) {
      print('❌ SecureAuthService: Error reading cached profile: $e');
    }
    return null;
  }

  /// Check if offline authentication is available
  Future<bool> canAuthenticateOffline() async {
    try {
      final userId = await _secureStorage.read(key: _keyUserId);
      final token = await _secureStorage.read(key: _keyAuthToken);
      final offlineEnabled = await _secureStorage.read(
        key: _keyOfflineAuthEnabled,
      );

      return userId != null &&
          token != null &&
          offlineEnabled == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Check if token is expired
  Future<bool> isTokenExpired() async {
    try {
      final expiryStr = await _secureStorage.read(key: _keyTokenExpiry);
      if (expiryStr == null) return true;

      final expiry = DateTime.fromMillisecondsSinceEpoch(int.parse(expiryStr));
      return DateTime.now().isAfter(expiry);
    } catch (e) {
      return true;
    }
  }

  /// Check if device supports biometric authentication
  Future<bool> canCheckBiometrics() async {
    try {
      final isAvailable = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      return isAvailable && canCheck;
    } catch (e) {
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Authenticate with biometrics
  Future<bool> authenticateWithBiometrics({
    String localizedReason = 'Please authenticate to access the app',
    bool sensitiveTransaction = true,
    bool persistAcrossBackgrounding = true,
  }) async {
    try {
      final isAvailable = await canCheckBiometrics();
      if (!isAvailable) return false;

      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Biometric Authentication',
            cancelButton: 'Cancel',
          ),
        ],
        sensitiveTransaction: sensitiveTransaction,
        persistAcrossBackgrounding: persistAcrossBackgrounding,
      );
    } catch (e) {
      print('❌ SecureAuthService: Biometric auth error: $e');
      return false;
    }
  }

  /// Enable/disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _keyBiometricEnabled,
      value: enabled.toString(),
    );
  }

  /// Check if biometric is enabled
  Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(key: _keyBiometricEnabled);
    return value == 'true';
  }

  /// Enable/disable offline authentication
  Future<void> setOfflineAuthEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _keyOfflineAuthEnabled,
      value: enabled.toString(),
    );
  }

  /// Check if offline auth is enabled
  Future<bool> isOfflineAuthEnabled() async {
    final value = await _secureStorage.read(key: _keyOfflineAuthEnabled);
    return value == 'true';
  }

  /// Get stored user ID
  Future<String?> getStoredUserId() async {
    return await _secureStorage.read(key: _keyUserId);
  }

  /// Get stored auth token
  Future<String?> getStoredToken() async {
    return await _secureStorage.read(key: _keyAuthToken);
  }

  /// Get stored user email
  Future<String?> getStoredEmail() async {
    return await _secureStorage.read(key: _keyUserEmail);
  }

  /// Clear all stored auth data (logout)
  Future<void> clearAuthData() async {
    try {
      final keys = [
        _keyAuthToken,
        _keyRefreshToken,
        _keyUserId,
        _keyUserEmail,
        _keyUserPassword,
        _keyTokenExpiry,
        _keyBiometricEnabled,
        _keyLastLoginTime,
        _keyOfflineAuthEnabled,
      ];

      for (final key in keys) {
        await _secureStorage.delete(key: key);
      }

      // Also clear cached profiles
      final allKeys = await _secureStorage.readAll();
      for (final key in allKeys.keys) {
        if (key.startsWith('cached_profile_')) {
          await _secureStorage.delete(key: key);
        }
      }
    } catch (e) {
      print('❌ SecureAuthService: Error clearing auth data: $e');
    }
  }

  /// Save email and password for auto re-login
  Future<void> saveLoginCredentials(String email, String password) async {
    // 🔥 Validate - don't save empty credentials
    if (email.isEmpty || password.isEmpty) {
      print('⚠️ [SECURE_AUTH] Refusing to save empty credentials');
      return;
    }
    try {
      await _secureStorage.write(key: _keyUserEmail, value: email);
      await _secureStorage.write(key: _keyUserPassword, value: password);
      print('✅ [SECURE_AUTH] Saved login credentials for: $email');
    } catch (e) {
      print('❌ [SECURE_AUTH] Error saving login credentials: $e');
    }
  }

  /// Get stored login credentials
  Future<Map<String, String?>?> getStoredLoginCredentials() async {
    try {
      final email = await _secureStorage.read(key: _keyUserEmail);
      final password = await _secureStorage.read(key: _keyUserPassword);
      // 🔥 Validate - reject empty/null credentials
      if (email != null &&
          password != null &&
          email.isNotEmpty &&
          password.isNotEmpty) {
        return {'email': email, 'password': password};
      }
      print('❌ [SECURE_AUTH] Invalid/empty credentials found');
    } catch (e) {
      print('❌ [SECURE_AUTH] Error getting stored credentials: $e');
    }
    return null;
  }

  /// Auto-login using stored credentials
  Future<User?> autoLogin() async {
    try {
      final creds = await getStoredLoginCredentials();
      if (creds == null) {
        print('❌ [SECURE_AUTH] No stored credentials for auto-login');
        return null;
      }

      final email = creds['email']!;
      final password = creds['password']!;

      // 🔥 Check if this is Google OAuth user
      if (password == 'GOOGLE_OAUTH') {
        print('🔄 [SECURE_AUTH] Google user detected - trying silent sign-in');
        return await _autoLoginWithGoogle();
      }

      // 🔥 Regular email/password login
      print('🔄 [SECURE_AUTH] Attempting email auto-login: $email');
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('✅ [SECURE_AUTH] Email auto-login successful: ${credential.user?.uid}');
      return credential.user;
    } catch (e) {
      print('❌ [SECURE_AUTH] Auto-login failed: $e');
      return null;
    }
  }

  /// Auto-login Google user using silent sign-in
  Future<User?> _autoLoginWithGoogle() async {
    try {
      // Try Google silent sign-in first
      await GoogleSignInService.instance.initialize();
      final googleUser = await GoogleSignInService.instance.authenticate();
      if (googleUser == null) {
        throw Exception('Google sign-in unavailable');
      }

      print('✅ [SECURE_AUTH] Google silent sign-in success: ${googleUser.email}');

      // Get auth details
      final googleAuth = googleUser.authentication;

      // Create Firebase credential - new API only provides idToken
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      print('✅ [SECURE_AUTH] Firebase Google auto-login: ${userCredential.user?.uid}');
      return userCredential.user;
    } catch (e) {
      print('❌ [SECURE_AUTH] Google auto-login failed: $e');
      return null;
    }
  }

  /// Attempt offline authentication
  /// Returns user data if successful, null if failed
  Future<Map<String, dynamic>?> authenticateOffline() async {
    try {
      // Check if offline auth is enabled
      final offlineEnabled = await isOfflineAuthEnabled();
      if (!offlineEnabled) return null;

      // Get stored credentials
      final userId = await getStoredUserId();
      final token = await getStoredToken();

      if (userId == null || token == null) return null;

      // Check if biometric is required and verify
      if (await isBiometricEnabled()) {
        final authenticated = await authenticateWithBiometrics(
          localizedReason: 'Authenticate to access your account offline',
        );
        if (!authenticated) return null;
      }

      // Get cached profile
      final profile = await getCachedProfile(userId);

      return {
        'userId': userId,
        'token': token,
        'isOffline': true,
        'profile': profile,
      };
    } catch (e) {
      print('❌ SecureAuthService: Offline auth error: $e');
      return null;
    }
  }

  /// Refresh Firebase token if online
  Future<String?> refreshTokenIfOnline() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final newToken = await user.getIdToken(true);
        await _secureStorage.write(key: _keyAuthToken, value: newToken);
        return newToken;
      }
    } catch (e) {
      print('❌ SecureAuthService: Token refresh failed: $e');
    }
    return null;
  }

  /// Check if user should use offline mode
  /// Returns true if token is expired and we're in offline mode
  Future<bool> shouldUseOfflineMode() async {
    final isExpired = await isTokenExpired();
    final canOffline = await canAuthenticateOffline();
    return isExpired && canOffline;
  }
}
