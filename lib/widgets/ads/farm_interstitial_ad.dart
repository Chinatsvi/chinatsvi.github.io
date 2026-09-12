import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:agribased/services/ad_manager.dart';

/// Static helper that loads and shows an interstitial ad.
/// Ad Unit: generate_report  ca-app-pub-2606126305565597/8706014157
class FarmInterstitialAd {
  FarmInterstitialAd._();

  static InterstitialAd? _ad;
  static bool _loading = false;

  /// Preload the interstitial so it's ready when needed.
  static void preload() {
    if (!AdManager.instance.adsEnabled || _loading || _ad != null) return;
    _loading = true;

    InterstitialAd.load(
      adUnitId: AdManager.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
          debugPrint('✅ [Interstitial] Loaded');
        },
        onAdFailedToLoad: (error) {
          _ad = null;
          _loading = false;
          debugPrint('⚠️ [Interstitial] Failed to preload: $error');
        },
      ),
    );
  }

  /// Show the interstitial for [screenKey].
  /// If [force] is true, ignores 1-per-session cap and loads on-demand if not ready.
  /// Calls [onDone] after the ad completes or on failure.
  static void show({
    required BuildContext context,
    required String screenKey,
    VoidCallback? onDone,
    bool force = true,
  }) {
    final adMgr = AdManager.instance;

    // Respect 1-per-session cap only if not forced
    if (!force && adMgr.hasShownInterstitialFor(screenKey)) {
      onDone?.call();
      return;
    }

    if (!adMgr.adsEnabled) {
      onDone?.call();
      return;
    }

    // If already preloaded, show immediately
    if (_ad != null) {
      final adToShow = _ad!;
      _ad = null; // consume
      adToShow.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          preload(); // reload for future
          onDone?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('⚠️ [Interstitial] Failed to show: $error');
          ad.dispose();
          preload();
          onDone?.call();
        },
      );

      adMgr.markInterstitialShown(screenKey);
      adToShow.show();
      return;
    }

    // Ad not preloaded: show quick loading dialog and load on-demand
    bool dialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(strokeWidth: 3),
                  SizedBox(width: 16),
                  Text(
                    'Loading sponsor ad...',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    InterstitialAd.load(
      adUnitId: AdManager.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (dialogOpen && context.mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            dialogOpen = false;
          }
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (adInstance) {
              adInstance.dispose();
              preload();
              onDone?.call();
            },
            onAdFailedToShowFullScreenContent: (adInstance, error) {
              debugPrint('⚠️ [Interstitial] Failed to show on-demand: $error');
              adInstance.dispose();
              preload();
              onDone?.call();
            },
          );
          adMgr.markInterstitialShown(screenKey);
          ad.show();
        },
        onAdFailedToLoad: (error) {
          debugPrint('⚠️ [Interstitial] Failed to load on-demand: $error');
          if (dialogOpen && context.mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            dialogOpen = false;
          }
          preload();
          onDone?.call();
        },
      ),
    );
  }
}
