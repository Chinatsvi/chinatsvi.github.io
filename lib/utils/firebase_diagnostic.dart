import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseDiagnostic {
  static Future<void> runFullDiagnostic() async {
    debugPrint('\n🔥 FIREBASE DIAGNOSTIC TOOL');
    debugPrint('==========================');
    
    // Test 1: Basic Firebase connection
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final user = auth.currentUser;
      debugPrint('✅ Firebase Auth initialized');
      debugPrint('✅ Current user: ${user?.email ?? 'Not signed in'}');
    } catch (e) {
      debugPrint('❌ Firebase Auth failed: $e');
      return;
    }
    
    // Test 2: Test email authentication (will fail gracefully)
    try {
      final auth = FirebaseAuth.instance;
      await auth.signInWithEmailAndPassword(
        email: 'test@nonexistent.com',
        password: 'test123456',
      );
    } catch (e) {
      if (e.toString().contains('user-not-found') || 
          e.toString().contains('wrong-password')) {
        debugPrint('✅ Email authentication is properly configured');
      } else if (e.toString().contains('configuration') ||
                 e.toString().contains('internal error')) {
        debugPrint('❌ CONFIGURATION ERROR: $e');
        debugPrint('🔧 SOLUTION: Add SHA-256 fingerprints to Firebase Console');
      } else {
        debugPrint('⚠️ Unexpected error: $e');
      }
    }
    
    // Test 3: Check build type
    debugPrint('📱 Build Mode: ${kDebugMode ? 'DEBUG' : 'RELEASE'}');
    
    if (!kDebugMode) {
      debugPrint('🔍 RELEASE BUILD DETECTED');
      debugPrint('❌ This requires SHA-256 fingerprint in Firebase Console');
      debugPrint('🔧 Add RELEASE SHA-256 to Firebase Console');
    }
    
    debugPrint('==========================');
    debugPrint('📋 SUMMARY:');
    debugPrint('If you see CONFIGURATION ERROR above, you need to:');
    debugPrint('1. Go to Firebase Console');
    debugPrint('2. Add SHA-256 fingerprints');
    debugPrint('3. Download new google-services.json');
    debugPrint('4. Rebuild your app');
  }
}
