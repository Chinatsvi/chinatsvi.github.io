import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:agribased/services/ad_manager.dart';

/// Self-loading Native Advanced ad rendered as a small template card.
/// Styled to match the app's green theme.
/// Ad Unit ID: animal_&_crop_tabs  ca-app-pub-2606126305565597/9089157531
class FarmNativeAd extends StatefulWidget {
  const FarmNativeAd({super.key});

  @override
  State<FarmNativeAd> createState() => _FarmNativeAdState();
}

class _FarmNativeAdState extends State<FarmNativeAd> {
  NativeAd? _nativeAd;
  bool _loaded = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (AdManager.instance.adsEnabled) {
      _loadNative();
    }
  }

  void _loadNative() {
    final ad = NativeAd(
      // animal_&_crop_tabs Native Advanced
      adUnitId: AdManager.nativeAdUnitId,
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() {
              _loaded = true;
              _failed = false;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('⚠️ [Native] Failed to load: ${error.message}');
          if (mounted) {
            setState(() {
              _loaded = false;
              _failed = true;
              _nativeAd = null;
            });
          }
        },
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: Colors.green.shade50,
        cornerRadius: 12.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: Colors.green.shade700,
          style: NativeTemplateFontStyle.bold,
          size: 13.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black87,
          style: NativeTemplateFontStyle.bold,
          size: 13.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.grey.shade700,
          style: NativeTemplateFontStyle.normal,
          size: 11.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.grey.shade600,
          style: NativeTemplateFontStyle.normal,
          size: 11.0,
        ),
      ),
    );
    ad.load();
    _nativeAd = ad;
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdManager.instance.adsEnabled || _failed) return const SizedBox.shrink();

    if (!_loaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      constraints: const BoxConstraints(
        minWidth: 320,
        minHeight: 90,
        maxHeight: 110,
      ),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 100,
        child: AdWidget(ad: _nativeAd!),
      ),
    );
  }
}
