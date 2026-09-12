import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class SHA256Checker {
  static Future<void> checkGoogleServicesConfig() async {
    try {
      // Read the google-services.json file
      final String configString = await rootBundle.loadString('android/app/google-services.json');
      final Map<String, dynamic> config = json.decode(configString);
      
      debugPrint('\n🔍 GOOGLE-SERVICES.JSON ANALYSIS');
      debugPrint('================================');
      
      // Check certificate hashes
      final clients = config['client'] as List;
      bool hasSHA256 = false;
      
      for (final client in clients) {
        final oauthClients = client['oauth_client'] as List;
        for (final oauth in oauthClients) {
          if (oauth['android_info'] != null) {
            final hash = oauth['android_info']['certificate_hash'] as String;
            debugPrint('📋 Certificate Hash: $hash');
            debugPrint('📏 Hash Length: ${hash.length} characters');
            
            if (hash.length == 64) {
              hasSHA256 = true;
              debugPrint('✅ SHA-256 hash found!');
            } else if (hash.length == 40) {
              debugPrint('⚠️ SHA-1 hash found (not sufficient for release builds)');
            }
          }
        }
      }
      
      debugPrint('================================');
      
      if (hasSHA256) {
        debugPrint('✅ GOOD: SHA-256 fingerprint is present');
        debugPrint('✅ Your app should work in release mode');
      } else {
        debugPrint('❌ PROBLEM: No SHA-256 fingerprint found');
        debugPrint('🔧 SOLUTION: Add SHA-256 fingerprints to Firebase Console');
        debugPrint('📋 REQUIRED SHA-256:');
        debugPrint('   RELEASE: 82:EB:8B:12:4A:27:9F:9B:2D:B8:2E:F9:01:E2:90:B7:2A:DB:D6:86:D6:4A:C3:A4:E9:F0:E0:50:D4:F7:07:F4');
        debugPrint('   DEBUG:   F3:69:B6:E6:77:F3:0A:0D:48:57:96:34:66:EC:D3:0C:15:49:B5:9C:87:A8:38:2C:F9:FC:BE:C3:D7:A8:A7:28');
      }
      
      debugPrint('================================');
      
    } catch (e) {
      debugPrint('❌ Error reading google-services.json: $e');
    }
  }
}
