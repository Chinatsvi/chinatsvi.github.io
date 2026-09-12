import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

/// Service to store and retrieve auth state for bulletproof navigation
/// This is a backup to Firebase Auth for slow phones
class AuthStateStorage {
  static const String _keyWasLoggedIn = 'was_logged_in';
  static const String _keyUserId = 'cached_user_id';
  static const String _keyLastLoginTime = 'last_login_time';
  static const String _keyCachedUserName = 'cached_user_name';
  static const String _keyCachedProfilePic = 'cached_profile_pic';
  
  static final AuthStateStorage _instance = AuthStateStorage._internal();
  factory AuthStateStorage() {
    return _instance;
  }
  AuthStateStorage._internal();

  SharedPreferences? _prefs;
  bool _initialized = false;
  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  /// Initialize the storage
  Future<void> init() async {
    if (_initialized) return;
    try {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
      developer.log('✅ AuthStateStorage initialized', name: 'AuthStateStorage');
    } catch (e) {
      developer.log('❌ AuthStateStorage init failed: $e', name: 'AuthStateStorage');
    }
  }

  /// Save login state when user logs in
  Future<void> saveLoginState(String userId) async {
    if (!_initialized || _prefs == null) return;
    try {
      await Future.wait([
        _prefs!.setBool(_keyWasLoggedIn, true),
        _prefs!.setString(_keyUserId, userId),
        _prefs!.setInt(_keyLastLoginTime, DateTime.now().millisecondsSinceEpoch),
      ]);
      // Also store a secure copy for optimistic startup (mobile only)
      try {
        await _secure.write(key: 'lastUid', value: userId);
      } catch (_) {
        // ignore secure storage failures
      }
      developer.log('💾 Login state saved for $userId', name: 'AuthStateStorage');
    } catch (e) {
      developer.log('❌ Failed to save login state: $e', name: 'AuthStateStorage');
    }
  }

  /// Clear login state when user logs out
  Future<void> clearLoginState() async {
    if (!_initialized || _prefs == null) return;
    try {
      await Future.wait([
        _prefs!.remove(_keyWasLoggedIn),
        _prefs!.remove(_keyUserId),
        _prefs!.remove(_keyLastLoginTime),
      ]);
      try {
        await _secure.delete(key: 'lastUid');
      } catch (_) {
        // ignore
      }
      developer.log('🗑️ Login state cleared', name: 'AuthStateStorage');
    } catch (e) {
      developer.log('❌ Failed to clear login state: $e', name: 'AuthStateStorage');
    }
  }

  /// Check if user was logged in (for app startup)
  Future<bool> wasLoggedIn() async {
    if (!_initialized || _prefs == null) return false;
    try {
      final wasLoggedIn = _prefs!.getBool(_keyWasLoggedIn) ?? false;
      final userId = _prefs!.getString(_keyUserId);
      // If shared prefs indicate no login, fallback to secure storage
      if (!wasLoggedIn || userId == null || userId.isEmpty) {
        try {
          final secureUid = await _secure.read(key: 'lastUid');
          if (secureUid != null && secureUid.isNotEmpty) {
            developer.log('🔁 Fallback: found lastUid in secure storage', name: 'AuthStateStorage');
            // Warm the prefs for future runs
            await Future.wait([
              _prefs!.setBool(_keyWasLoggedIn, true),
              _prefs!.setString(_keyUserId, secureUid),
              _prefs!.setInt(_keyLastLoginTime, DateTime.now().millisecondsSinceEpoch),
            ]);
            return true;
          }
        } catch (e) {
          // ignore secure storage read errors
        }

        return false;
      }
      
      // Firebase Auth persistence handles session management - no expiration needed
      developer.log('✅ Was logged in: $userId', name: 'AuthStateStorage');
      return true;
    } catch (e) {
      developer.log('❌ Error checking login state: $e', name: 'AuthStateStorage');
      return false;
    }
  }

  /// Get cached user ID
  String? getCachedUserId() {
    if (!_initialized || _prefs == null) return null;
    try {
      return _prefs!.getString(_keyUserId);
    } catch (e) {
      return null;
    }
  }

  /// Get last UID from secure storage (fallback)
  Future<String?> getLastUid() async {
    try {
      return await _secure.read(key: 'lastUid');
    } catch (e) {
      return null;
    }
  }

  /// Load cached profile (if any)
  Future<Map<String, String>?> getCachedProfile() async {
    try {
      // First try secure storage
      final raw = await _secure.read(key: 'cached_profile');
      if (raw != null && raw.isNotEmpty) {
        final decoded = json.decode(raw) as Map<String, dynamic>;
        return decoded.map((k, v) => MapEntry(k, v?.toString() ?? ''));
      }
    } catch (e) {
      // Fall through to SharedPreferences
    }
    
    // Fallback to SharedPreferences (more reliable)
    if (_prefs != null) {
      final uid = _prefs!.getString(_keyUserId);
      if (uid != null && uid.isNotEmpty) {
        return {
          'uid': uid,
          'user_name': _prefs!.getString(_keyCachedUserName) ?? '',
          'profile_pic': _prefs!.getString(_keyCachedProfilePic) ?? '',
        };
      }
    }
    return null;
  }

  /// Save a minimal profile securely for optimistic startup.
  Future<void> saveCachedProfile({required String uid, String? userName, String? profilePic}) async {
    try {
      // Save to secure storage
      final map = {
        'uid': uid,
        'user_name': userName ?? '',
        'profile_pic': profilePic ?? '',
      };
      await _secure.write(key: 'cached_profile', value: json.encode(map));
      
      // ALSO save to SharedPreferences as backup (more reliable on some devices)
      if (_prefs != null) {
        await _prefs!.setString(_keyUserId, uid);
        if (userName != null && userName.isNotEmpty) {
          await _prefs!.setString(_keyCachedUserName, userName);
        }
        if (profilePic != null && profilePic.isNotEmpty) {
          await _prefs!.setString(_keyCachedProfilePic, profilePic);
        }
      }
    } catch (e) {
      // ignore write errors
    }
  }

  /// Clear cached profile
  Future<void> clearCachedProfile() async {
    try {
      await _secure.delete(key: 'cached_profile');
    } catch (_) {}
  }

  /// Sync with current Firebase Auth state (call this on app startup after auth check)
  Future<void> syncWithFirebase() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await saveLoginState(currentUser.uid);
    } else {
      await clearLoginState();
    }
  }
}
