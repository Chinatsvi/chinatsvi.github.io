import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'google_sign_in_service.dart';

import 'farmer_profile_utils.dart';

/// Centralized AuthService to provide a single source of truth for auth state.
/// This avoids multiple independent waits on FirebaseAuth which can cause
/// race conditions and welcome-screen flicker on slow devices.
class AuthService {
  // =========================================================================
  // SINGLETON INSTANCE for centralized auth state management
  // =========================================================================
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? currentUser;
  StreamSubscription<User?>? _sub;

  /// Whether the service finished its initial restore check.
  bool _initialized = false;

  /// Initialize the service and start listening to auth changes.
  /// Safe to call multiple times.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Start with current user (fast path)
    currentUser = _auth.currentUser;
    try {
      // Log initial snapshot for debugging startup issues
      debugPrint('🔁 AuthService.init - currentUser: ${currentUser?.uid ?? 'null'}');
      debugPrint('🔁 AuthService.init - currentUser email: ${currentUser?.email ?? 'null'}');
    } catch (_) {}

    // Listen to auth changes and keep local cache updated
    _sub = _auth.authStateChanges().listen((user) {
      debugPrint('🔔 AuthService.authStateChanges event - user: ${user?.uid ?? 'null'}');
      currentUser = user;
    }, onError: (err) {
      debugPrint('❌ AuthService.authStateChanges error: $err');
    });
  }

  /// Wait for the first auth event (or short timeout) to allow Firebase to
  /// restore a persisted session on slow devices. Returns the resolved user
  /// or null if none.
  Future<User?> waitForInitialAuth({Duration timeout = const Duration(seconds: 8)}) async {
    await init();

    try {
      debugPrint('⏳ AuthService.waitForInitialAuth - waiting up to ${timeout.inSeconds}s');
      final user = await _auth.authStateChanges().first.timeout(timeout, onTimeout: () => _auth.currentUser);
      currentUser = user;
      debugPrint('✅ AuthService.waitForInitialAuth - resolved user: ${user?.uid ?? 'null'}');
      return user;
    } catch (_) {
      // final fallback
      currentUser = _auth.currentUser;
      debugPrint('⚠️ AuthService.waitForInitialAuth - exception, fallback to currentUser: ${currentUser?.uid ?? 'null'}');
      return currentUser;
    }
  }

  /// Synchronous check (fast). Use this when you already know init completed.
  bool isAuthenticatedSync() => currentUser != null;

  /// Asynchronous check that waits briefly if needed.
  Future<bool> isAuthenticated({Duration timeout = const Duration(seconds: 2)}) async {
    final user = await waitForInitialAuth(timeout: timeout);
    return user != null;
  }

  /// Dispose listener (mostly for tests)
  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _initialized = false;
  }

  // =========================================================================
  // STATIC ACCESSORS for backward compatibility
  // =========================================================================
  static final FirebaseAuth _authStatic = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // STATIC GETTERS
  static User? get currentUserStatic => _authStatic.currentUser;
  static String? get currentUserId => _authStatic.currentUser?.uid;
  static bool get isLoggedIn => _authStatic.currentUser != null;

  // =========================================================================
  // EMAIL SIGN-UP → Always creates Firestore profile in 'farmers'
  // =========================================================================
  static Future<User?> emailSignUp({
    required String email,
    required String password,
    required String userName,
  }) async {
    final cred = await _authStatic.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user;
    if (user != null) {
      await _createUserProfile(
        uid: user.uid,
        userName: userName,
        email: email,
        image: '',
      );
    }

    return user;
  }

  // =========================================================================
  // EMAIL LOGIN → Block if no Firestore profile in 'farmers'
  // =========================================================================
  static Future<User?> emailLogin({
    required String email,
    required String password,
  }) async {
    final cred = await _authStatic.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = cred.user;

    if (user != null) {
      final exists = await _profileExists(user.uid);
      if (!exists) {
        await _authStatic.signOut();
        throw Exception("Account not found. Please sign up first.");
      }
    }

    return user;
  }

  // =========================================================================
  // GOOGLE SIGN-UP → Always creates Firestore profile in 'farmers'
  // =========================================================================
  static Future<User?> googleSignUp() async {
    await GoogleSignInService.instance.initialize();
    final googleUser = await GoogleSignInService.instance.authenticate();
    final googleAuth = await googleUser!.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final result = await _authStatic.signInWithCredential(credential);
    final user = result.user;
    if (user == null) return null;

    final doc = await _firestore.collection('farmers').doc(user.uid).get();
    
    // ✅ **FIX**: If profile already exists, DO NOT TOUCH IT
    // This prevents wiping followers, following, and other profile data
    // when someone re-taps "Sign Up" or completes Google sign-in again
    if (doc.exists) {
      debugPrint('✅ Profile already exists for ${user.uid} — skipping creation (treating as login)');
      return user;
    }

    // Genuinely new — safe to create fresh
    final googleName = googleUser.displayName?.trim() ?? '';
    final userName = googleName.isNotEmpty ? googleName : 'User';
    await _createUserProfile(
      uid: user.uid,
      userName: userName,
      email: googleUser.email,
      image: googleUser.photoUrl ?? '',
      existingData: null, // Always null for new profiles (doc doesn't exist)
      includeCreatedAt: true, // Always set createdAt for new profiles
    );

    return user;
  }

  // =========================================================================
  // GOOGLE LOGIN → BLOCK if no Firestore profile in 'farmers'
  // =========================================================================
  static Future<User?> googleLogin() async {
    await GoogleSignInService.instance.initialize();
    final googleUser = await GoogleSignInService.instance.authenticate();
    final googleAuth = await googleUser!.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final result = await _authStatic.signInWithCredential(credential);
    final user = result.user;
    if (user == null) return null;

    final exists = await _profileExists(user.uid);
    if (!exists) {
      await _authStatic.signOut();
      throw Exception("No account found. Please sign up first.");
    }

    return user;
  }

  // =========================================================================
  // PHONE VERIFICATION → BLOCK if profile missing in 'farmers'
  // =========================================================================
  static Future<User?> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final cred = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    final result = await _authStatic.signInWithCredential(cred);
    final user = result.user;

    if (user != null) {
      final exists = await _profileExists(user.uid);
      if (!exists) {
        await _authStatic.signOut();
        throw Exception("No account found. Please sign up first.");
      }
    }

    return user;
  }

  // =========================================================================
  // PASSWORD RESET
  // =========================================================================
  static Future<void> resetPassword(String email) async {
    await _authStatic.sendPasswordResetEmail(email: email);
  }

  // =========================================================================
  // LOGOUT
  // =========================================================================
  static Future<void> signOut() async {
    // EnhancedAiService automatically handles user ID from Firebase Auth
    // No need to manually clear user ID

    await GoogleSignInService.instance.signOut();
    await _authStatic.signOut();
  }

  /// Initialize Google Sign In (call at app startup)
  static Future<void> initializeGoogleSignIn() async {
    await GoogleSignInService.instance.initialize();
  }

  // =========================================================================
  // DELETE ACCOUNT
  // =========================================================================
  static Future<void> deleteAccount() async {
    final user = _authStatic.currentUser;
    if (user != null) {
      await _firestore.collection('farmers').doc(user.uid).delete();
      await user.delete();
    }
  }

  // =========================================================================
  // PRIVATE HELPERS
  // =========================================================================

  static Future<bool> _profileExists(String uid) async {
    final doc = await _firestore.collection('farmers').doc(uid).get();
    return doc.exists;
  }

  static Future<void> _createUserProfile({
    required String uid,
    required String userName,
    required String email,
    required String image,
    Map<String, dynamic>? existingData,
    bool includeCreatedAt = true,
  }) async {
    final docRef = _firestore.collection('farmers').doc(uid);
    final doc = await docRef.get();
    final payload = buildFarmerProfilePayload(
      uid: uid,
      userName: userName,
      email: email,
      profilePic: image,
      coverPhoto: '',
      existingData: existingData ?? (doc.exists ? doc.data() : null),
      includeCreatedAt: includeCreatedAt,
    );

    if (!doc.exists) {
      await docRef.set(payload);
    } else {
      await docRef.set(payload, SetOptions(merge: true));
    }
  }
}
