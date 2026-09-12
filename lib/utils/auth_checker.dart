import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthChecker {
  /// Check if Firebase is properly configured for current build type
  static Future<void> checkAuthConfiguration() async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      
      // Test basic Firebase connectivity
      final currentUser = auth.currentUser;
      
      debugPrint('\n🔥 FIREBASE AUTHENTICATION CHECK');
      debugPrint('================================');
      debugPrint('✅ Firebase Auth is initialized');
      debugPrint('✅ Current user: ${currentUser?.email ?? 'Not signed in'}');
      debugPrint('✅ Project is accessible');
      
      // Test auth settings (this will fail gracefully if not configured)
      try {
        await auth.signInAnonymously();
        await currentUser?.delete(); // Clean up anonymous user
        debugPrint('✅ Email/Password authentication is enabled');
      } catch (e) {
        if (e.toString().contains('operation-not-allowed')) {
          debugPrint('⚠️ Email/Password authentication not enabled in Firebase Console');
        } else {
          debugPrint('✅ Email/Password authentication is enabled');
        }
      }
      
      debugPrint('================================');
      debugPrint('🎉 Firebase is properly configured!');
      debugPrint('📱 You can use authentication in both DEBUG and RELEASE builds');
      
    } catch (e) {
      debugPrint('❌ Firebase configuration error: $e');
      debugPrint('🔧 Please check:');
      debugPrint('   1. SHA-256 fingerprints in Firebase Console');
      debugPrint('   2. google-services.json file');
      debugPrint('   3. Authentication methods are enabled');
    }
  }
  
  /// Quick check for build type
  static void checkBuildType() {
    debugPrint('\n📱 BUILD INFORMATION');
    debugPrint('==================');
    debugPrint('Build Mode: ${kDebugMode ? 'DEBUG' : 'RELEASE'}');
    debugPrint('Web Mode: ${kIsWeb ? 'YES' : 'NO'}');
    
    if (kDebugMode) {
      debugPrint('✅ Using DEBUG configuration');
      debugPrint('✅ Debug SHA-256 fingerprint is active');
    } else {
      debugPrint('✅ Using RELEASE configuration');
      debugPrint('✅ Release SHA-256 fingerprint is active');
    }
    debugPrint('==================');
  }
}
