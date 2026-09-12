import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_api_availability/google_api_availability.dart';

class DeviceCapabilityService {
  DeviceCapabilityService._internal();
  static final DeviceCapabilityService instance = DeviceCapabilityService._internal();

  bool? _hasGooglePlayServices;

  Future<bool> get hasGooglePlayServices async {
    if (_hasGooglePlayServices != null) {
      return _hasGooglePlayServices!;
    }

    if (kIsWeb) {
      _hasGooglePlayServices = true;
      return _hasGooglePlayServices!;
    }

    if (!Platform.isAndroid) {
      _hasGooglePlayServices = true;
      return _hasGooglePlayServices!;
    }

    final status = await GoogleApiAvailability.instance.checkGooglePlayServicesAvailability();
    _hasGooglePlayServices = status == GooglePlayServicesAvailability.success;
    return _hasGooglePlayServices!;
  }

  Future<bool> get canUseGoogleSignIn async {
    return await hasGooglePlayServices;
  }

  Future<bool> get canUseGoogleAds async {
    return await hasGooglePlayServices;
  }

  Future<bool> get canUseFirebaseMessaging async {
    return await hasGooglePlayServices;
  }
}
