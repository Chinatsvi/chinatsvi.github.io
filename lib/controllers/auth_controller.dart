import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/farmer_profile_utils.dart';
import '../services/google_sign_in_service.dart';

enum AccountType { basic, premium, enterprise }

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  static User? get currentUserStatic => FirebaseAuth.instance.currentUser;
  static String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// Saved verification ID for phone re-authentication
  // Phone authentication removed — flows replaced by email/google only.

  final String defaultProfilePic = 'assets/images/default_avatar.png';
  final String defaultCoverPhoto = 'assets/images/farmer_cover.jpg';

  // =========================
  // User Info Getters (single source: user_name)
  // =========================
  static Future<String?> get currentUserName async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('farmers')
        .doc(uid)
        .get();
    return doc.data()?['user_name'] as String?;
  }

  static Future<String?> get currentUserProfilePic async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('farmers')
        .doc(uid)
        .get();
    return doc.data()?['profile_pic'] as String?;
  }

  static Future<String?> get currentUserCoverPhoto async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('farmers')
        .doc(uid)
        .get();
    return doc.data()?['cover_photo'] as String?;
  }

  // =========================
  // Reactivation Helper
  // =========================
  Future<void> _reactivateAccount(String userId) async {
    try {
      // Check if account was inactive
      final userDoc = await _db.collection('farmers').doc(userId).get();
      final isActive = userDoc.data()?['active'] ?? true;

      if (!isActive) {
        // Reactivate the account
        await _db.collection('farmers').doc(userId).update({'active': true});

        // Reactivate all posts by this user
        final postsQuery = await _db
            .collection('posts')
            .where('authorId', isEqualTo: userId)
            .get();

        for (final postDoc in postsQuery.docs) {
          await postDoc.reference.update({'active': true});
        }
      }
    } catch (e) {
      // Log error but don't fail login
      print('Error reactivating account: $e');
    }
  }

  // =========================
  // Email Authentication
  // =========================
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String userName,
    String location = '',
    String bio = '',
    String phone = '',
    String work = '',
    String education = '',
    String farmType = '',
    AccountType accountType = AccountType.basic,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = userCredential.user;
    if (user != null) {
      await user.getIdToken(true);

      // Ensure Firestore profile is created. Retry a couple times on transient failures.
      var attempts = 0;
      const maxAttempts = 3;
      while (attempts < maxAttempts) {
        try {
          await _createOrUpdateFirestoreProfile(
            uid: user.uid,
            userName: userName,
            email: email,
            profilePic: defaultProfilePic,
            coverPhoto: defaultCoverPhoto,
            location: location,
            bio: bio,
            phone: phone,
            work: work,
            education: education,
            farmType: farmType,
            accountType: accountType,
          );

          // Verify doc exists
          final doc = await _db.collection('farmers').doc(user.uid).get();
          if (doc.exists) break;
        } catch (e) {
          // swalllow and retry
          debugPrint('AuthController.signUpWithEmail: profile create attempt ${attempts + 1} failed: $e');
        }

        attempts++;
        if (attempts < maxAttempts) await Future.delayed(const Duration(seconds: 1));
      }
    }
    return user;
  }

  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = userCredential.user;
    if (user != null) {
      await user.getIdToken(true);
      final doc = await _db.collection('farmers').doc(user.uid).get();
      if (!doc.exists) {
        throw Exception("No farmer profile found. Please sign up first.");
      }

      // Reactivate account and posts if they were deactivated
      await _reactivateAccount(user.uid);
    }
    return user;
  }

  // =========================
  // Google Authentication
  // =========================
  Future<User?> signUpWithGoogle() async {
    await GoogleSignInService.instance.initialize();
    final googleUser = await GoogleSignInService.instance.authenticate();
    final googleAuth = await googleUser!.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user != null) {
      await user.getIdToken(true);
      await _createOrUpdateFirestoreProfile(
        uid: user.uid,
        userName: user.displayName ?? 'Farmer',
        email: user.email ?? '',
        profilePic: defaultProfilePic,
        coverPhoto: defaultCoverPhoto,
      );
    }
    return user;
  }

  Future<User?> loginWithGoogle() async {
    await GoogleSignInService.instance.initialize();
    final googleUser = await GoogleSignInService.instance.authenticate();
    final googleAuth = await googleUser!.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user != null) {
      await user.getIdToken(true);
      final doc = await _db.collection('farmers').doc(user.uid).get();
      if (!doc.exists) {
        throw Exception("No farmer profile found. Please sign up first.");
      }

      // Reactivate account and posts if they were deactivated
      await _reactivateAccount(user.uid);
    }
    return user;
  }

  static Future<AuthCredential?> getGoogleCredential() async {
    await GoogleSignInService.instance.initialize();
    final googleUser = await GoogleSignInService.instance.authenticate();
    final googleAuth = await googleUser!.authentication;
    return GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
  }

  // Phone authentication helper methods removed per project requirement.

  // =========================
  // Sign Out
  // =========================
  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignInService.instance.signOut();
  }

  // =========================
  // Firestore Profile Handling (single source: user_name)
  // =========================
  Future<void> _createOrUpdateFirestoreProfile({
    required String uid,
    required String userName,
    required String email,
    String profilePic = '',
    String coverPhoto = '',
    String location = '',
    String bio = '',
    String phone = '',
    String work = '',
    String education = '',
    String farmType = '',
    AccountType accountType = AccountType.basic,
  }) async {
    final docRef = _db.collection('farmers').doc(uid);
    final doc = await docRef.get();

    // ✅ **FIX**: If profile already exists, DO NOT TOUCH IT
    // This prevents wiping followers, following, and other profile data
    // when someone re-taps "Sign Up" or completes Google sign-in again
    if (doc.exists) {
      debugPrint('✅ Profile already exists for $uid — skipping creation (treating as login)');
      return;
    }

    // Genuinely new account — safe to create from scratch
    final profileData = buildFarmerProfilePayload(
      uid: uid,
      userName: userName,
      email: email,
      profilePic: profilePic,
      coverPhoto: coverPhoto,
      location: location,
      bio: bio,
      phone: phone,
      work: work,
      education: education,
      farmType: farmType,
      accountTypeName: accountType.name,
      existingData: null, // Always null for new profiles (doc doesn't exist)
      includeCreatedAt: true, // Always set createdAt for new profiles
    );

    await docRef.set(profileData); // Safe to use `.set()` without merge—doc is brand new
  }

  // Phone helper methods removed — keep account creation via email/google.

  // =========================
  // Backwards-compatible wrappers
  // =========================
  Future<User?> signInWithGoogle() => loginWithGoogle();
}
