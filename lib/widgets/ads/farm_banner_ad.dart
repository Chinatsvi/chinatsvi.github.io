import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:agribased/services/ad_manager.dart';

/// Self-loading Banner ad (320x50) with a small 'Sponsored' label.
/// Drop this widget at the bottom of any scrollable screen.
class FarmBannerAd extends StatefulWidget {
  const FarmBannerAd({super.key});

  @override
  State<FarmBannerAd> createState() => _FarmBannerAdState();
}

class _FarmBannerAdState extends State<FarmBannerAd> {
  BannerAd? _banner;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (AdManager.instance.adsEnabled) {
      _loadBanner();
    }
  }

  void _loadBanner() {
    final ad = BannerAd(
      // Farmers Community Banner
      adUnitId: AdManager.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('⚠️ [Banner] Failed: ');
        },
      ),
    );
    ad.load();
    _banner = ad;
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdManager.instance.adsEnabled || (!_loaded && _banner == null)) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sponsored',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            if (_loaded && _banner != null)
              SizedBox(
                height: _banner!.size.height.toDouble(),
                child: AdWidget(ad: _banner!),
              )
            else
              const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
