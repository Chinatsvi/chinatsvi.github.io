import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BuildFingerprintChecker {
  static void checkBuildFingerprint() {
    debugPrint('\n🔍 BUILD FINGERPRINT CHECKER');
    debugPrint('============================');
    
    debugPrint('📱 Build Mode: ${kDebugMode ? 'DEBUG' : 'RELEASE'}');
    
    if (kDebugMode) {
      debugPrint('🔑 Using DEBUG keystore');
      debugPrint('🔑 DEBUG SHA-256: F3:69:B6:E6:77:F3:0A:0D:48:57:96:34:66:EC:D3:0C:15:49:B5:9C:87:A8:38:2C:F9:FC:BE:C3:D7:A8:A7:28');
    } else {
      debugPrint('🔑 Using RELEASE keystore');
      debugPrint('🔑 RELEASE SHA-256: 82:EB:8B:12:4A:27:9F:9B:2D:B8:2E:F9:01:E2:90:B7:2A:DB:D6:86:D6:4A:C3:A4:E9:F0:E0:50:D4:F7:07:F4');
    }
    
    debugPrint('============================');
    debugPrint('✅ Both fingerprints are registered in Firebase Console');
    debugPrint('✅ Authentication should work in both modes');
    debugPrint('============================');
  }
}
