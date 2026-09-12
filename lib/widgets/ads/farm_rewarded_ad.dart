import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:agribased/services/ad_manager.dart';

/// A button that loads and shows a Rewarded ad then calls [onRewarded].
/// Shows a loading indicator while the ad is loading.
///
/// Ad Unit: guidebook_unlock_reward  ca-app-pub-2606126305565597/9859796223
class FarmRewardedAdButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onRewarded;
  final Color? color;

  const FarmRewardedAdButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onRewarded,
    this.color,
  });

  @override
  State<FarmRewardedAdButton> createState() => _FarmRewardedAdButtonState();
}

class _FarmRewardedAdButtonState extends State<FarmRewardedAdButton> {
  RewardedAd? _rewardedAd;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (AdManager.instance.adsEnabled) {
      _loadAd();
    }
  }

  void _loadAd() {
    if (_loading) return;
    setState(() => _loading = true);

    RewardedAd.load(
      // guidebook_unlock_reward
      adUnitId: AdManager.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (mounted) setState(() {
            _rewardedAd = ad;
            _loading = false;
          });
          debugPrint('✅ [Rewarded] Loaded');
        },
        onAdFailedToLoad: (error) {
          if (mounted) setState(() {
            _rewardedAd = null;
            _loading = false;
          });
          debugPrint('⚠️ [Rewarded] Failed: ');
        },
      ),
    );
  }

  void _showAd() {
    if (_rewardedAd == null) {
      // No ad available — grant reward anyway (graceful fallback)
      widget.onRewarded();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (mounted) setState(() => _rewardedAd = null);
        _loadAd(); // reload for next time
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (mounted) setState(() => _rewardedAd = null);
        widget.onRewarded(); // graceful fallback
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (_, reward) {
        debugPrint('🎁 [Rewarded] Reward earned:  x');
        widget.onRewarded();
      },
    );
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.color ?? Colors.green.shade700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _loading ? null : _showAd,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(widget.icon),
          label: Text(widget.label, style: const TextStyle(fontSize: 15)),
        ),
        if (AdManager.instance.adsEnabled)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_outline,
                    size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  'Watch a short ad to unlock',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
