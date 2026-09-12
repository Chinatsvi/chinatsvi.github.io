import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'device_capability_service.dart';

class GoogleSignInService {
  GoogleSignInService._internal();
  static final GoogleSignInService instance = GoogleSignInService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<bool> get isAvailable async {
    return await DeviceCapabilityService.instance.canUseGoogleSignIn;
  }

  Future<void> initialize() async {
    if (!await isAvailable) {
      throw Exception('Google sign-in is unavailable because Google Play Services are missing on this device.');
    }
    await _googleSignIn.initialize();
  }

  Future<GoogleSignInAccount?> authenticate() async {
    if (!await isAvailable) {
      throw Exception('Google sign-in is unavailable because Google Play Services are missing on this device.');
    }
    return await _googleSignIn.authenticate();
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore sign-out failures for devices without Google Play Services.
    }
  }

  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
    } catch (_) {
      // Ignore disconnect failures for devices without Google Play Services.
    }
  }
}
