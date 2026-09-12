import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../google_sign_in_service.dart';

class AuthInitializationService {
  static final AuthInitializationService _instance = AuthInitializationService._internal();
  factory AuthInitializationService() => _instance;
  AuthInitializationService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isInitialized = false;

  /// Initialize Firebase Auth with proper persistence
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('🔥 Initializing Firebase Auth...');

    try {
      // On web we can set persistence; on mobile this API is unsupported.
      if (kIsWeb) {
        try {
          await _auth.setPersistence(Persistence.LOCAL);
          debugPrint('🔒 Auth persistence set to LOCAL (web)');
        } catch (e) {
          debugPrint('⚠️ Could not set auth persistence (web): $e');
        }
      }

      // Wait for auth state to be determined (will complete quickly if user cached)
      await _auth.authStateChanges().first;

      // Note: Silent Google sign-in is not available in this version of the package

    } catch (e) {
      debugPrint('❌ Firebase Auth initialization failed: $e');
      // Continue - we'll still mark initialized so auth checks won't block navigation
    } finally {
      _isInitialized = true;
      final user = _auth.currentUser;
      debugPrint('✅ Firebase Auth initialization complete');
      debugPrint('👤 Current user: ${user?.email ?? 'Not signed in'}');
      debugPrint('🔐 User ID: ${user?.uid ?? 'None'}');
    }
  }

  /// Check if user is actually authenticated
  bool get isUserAuthenticated {
    if (!_isInitialized) {
      debugPrint('⚠️ Auth not initialized yet');
      return false;
    }
    
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('👤 No current user');
      return false;
    }
    
    // Additional validation
    if (user.email == null || user.uid.isEmpty) {
      debugPrint('⚠️ User data incomplete');
      return false;
    }
    
    debugPrint('✅ User is authenticated: ${user.email}');
    return true;
  }

  /// Force refresh user token
  Future<void> refreshUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        debugPrint('🔄 User token refreshed');
      }
    } catch (e) {
      debugPrint('❌ Failed to refresh user: $e');
    }
  }

  /// Get current user with validation
  User? get validatedUser {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user != null &&
        email != null &&
        email.isNotEmpty &&
        user.uid.isNotEmpty) {
      return user;
    }
    return null;
  }

  /// Sign out properly
  Future<void> signOut() async {
    try {
      await GoogleSignInService.instance.signOut();
      await _auth.signOut();
      debugPrint('👋 User signed out successfully');
    } catch (e) {
      debugPrint('❌ Sign out failed: $e');
    }
  }

  /// Debug auth state
  void debugAuthState() {
    debugPrint('\n🔍 AUTHENTICATION DEBUG INFO');
    debugPrint('================================');
    debugPrint('Initialized: $_isInitialized');
    debugPrint('Current User: ${_auth.currentUser?.email ?? 'None'}');
    debugPrint('User UID: ${_auth.currentUser?.uid ?? 'None'}');
    debugPrint('Is Email Verified: ${_auth.currentUser?.emailVerified ?? false}');
    debugPrint('Creation Time: ${_auth.currentUser?.metadata.creationTime}');
    debugPrint('Last Sign In: ${_auth.currentUser?.metadata.lastSignInTime}');
    debugPrint('================================');
  }
}
