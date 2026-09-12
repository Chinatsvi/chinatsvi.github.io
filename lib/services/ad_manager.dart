import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'build_config_service.dart';
import 'device_capability_service.dart';

class AdManager {
  AdManager._internal();
  static final AdManager instance = AdManager._internal();

  // ─── Ad Unit IDs ───────────────────────────────────────────────────────────
  static const String bannerAdUnitId =
      'ca-app-pub-2606126305565597/1136425567';
  static const String nativeAdUnitId =
      'ca-app-pub-2606126305565597/9089157531';
  static const String interstitialAdUnitId =
      'ca-app-pub-2606126305565597/8706014157';
  static const String rewardedAdUnitId =
      'ca-app-pub-2606126305565597/9859796223';

  // Legacy getter kept for backward compat
  static String get appId => BuildConfigService.admobAppId.isNotEmpty
      ? BuildConfigService.admobAppId
      : 'ca-app-pub-2606126305565597~6598731736';

  // ─── Session interstitial cap (max 1 per screen per session) ───────────────
  final Set<String> _interstitialShownFor = {};

  bool hasShownInterstitialFor(String screenKey) =>
      _interstitialShownFor.contains(screenKey);

  void markInterstitialShown(String screenKey) =>
      _interstitialShownFor.add(screenKey);

  // ─── State ─────────────────────────────────────────────────────────────────
  bool _initialized = false;
  bool _adsEnabled = false;

  bool get adsEnabled => _adsEnabled;

  // ─── Initialize ────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      if (!await DeviceCapabilityService.instance.canUseGoogleAds) {
        debugPrint(
          '📱 [AdMob] Skipped: Google Play Services unavailable',
        );
        _adsEnabled = false;
        return;
      }

      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('📱 [AdMob] Initializing Google Mobile Ads SDK...');
      debugPrint('📱 [AdMob] Banner       : ');
      debugPrint('📱 [AdMob] Native       : ');
      debugPrint('📱 [AdMob] Interstitial : ');
      debugPrint('📱 [AdMob] Rewarded     : ');

      final initStatus = await MobileAds.instance.initialize();
      _adsEnabled = true;

      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds: ['DDD6016E8227219FD32F6B8C5A14696E'],
        ),
      );

      debugPrint('✅ [AdMob] Initialized successfully!');
      initStatus.adapterStatuses.forEach((key, status) {
        debugPrint('📱 [AdMob] Adapter []: ');
      });
      debugPrint('═══════════════════════════════════════════════════');
    } catch (e) {
      debugPrint('⚠️ [AdMob] Init failed: $e');
      _adsEnabled = false;
    }
  }
}
