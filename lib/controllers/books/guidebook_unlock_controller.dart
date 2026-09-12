import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../services/ad_manager.dart';

class GuidebookUnlockState {
  final int adsWatched;      // 0, 1, 2 (progress toward this unlock)
  final DateTime? unlockedAt;
  const GuidebookUnlockState({this.adsWatched = 0, this.unlockedAt});

  bool get isUnlocked =>
      unlockedAt != null && DateTime.now().difference(unlockedAt!) < const Duration(hours: 24);

  Duration? get timeRemaining => isUnlocked
      ? const Duration(hours: 24) - DateTime.now().difference(unlockedAt!)
      : null;

  GuidebookUnlockState copyWith({
    int? adsWatched,
    DateTime? unlockedAt,
  }) {
    return GuidebookUnlockState(
      adsWatched: adsWatched ?? this.adsWatched,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}

class GuidebookUnlockController extends ChangeNotifier {
  final String guidebookId;
  final Box _box;
  RewardedAd? _rewardedAd;
  static const int adsRequired = 2;
  GuidebookUnlockState _state = const GuidebookUnlockState();

  GuidebookUnlockController(this.guidebookId) : _box = Hive.box('guidebook_unlocks') {
    _loadState();
  }

  GuidebookUnlockState get state => _state;

  void _loadState() {
    final unlockedAtMillis = _box.get('${guidebookId}_unlockedAt') as int?;
    final unlockedAt = unlockedAtMillis != null
        ? DateTime.fromMillisecondsSinceEpoch(unlockedAtMillis)
        : null;

    final stillValid = unlockedAt != null &&
        DateTime.now().difference(unlockedAt) < const Duration(hours: 24);

    // If the previous unlock expired, reset progress too — full re-watch required.
    final adsWatched = stillValid ? adsRequired : 0;
    if (!stillValid) _box.delete('${guidebookId}_unlockedAt');

    _state = GuidebookUnlockState(adsWatched: adsWatched, unlockedAt: stillValid ? unlockedAt : null);
    notifyListeners();
    if (!_state.isUnlocked) _preloadAd();
  }

  void _preloadAd() {
    if (!AdManager.instance.adsEnabled) return;
    
    RewardedAd.load(
      adUnitId: AdManager.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          debugPrint('✅ [Guidebook Ads] Rewarded ad loaded successfully');
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          debugPrint('⚠️ [Guidebook Ads] Rewarded ad failed to load: ${error.message}');
        },
      ),
    );
  }

  Future<void> watchAdToUnlock(BuildContext context) async {
    if (_rewardedAd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad not ready yet, try again in a moment')),
      );
      _preloadAd();
      return;
    }
    
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('📱 [Guidebook Ads] Rewarded ad showed fullscreen content');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('📱 [Guidebook Ads] Rewarded ad dismissed fullscreen content');
        ad.dispose();
        _rewardedAd = null;
        _preloadAd(); // Preload next ad
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('⚠️ [Guidebook Ads] Rewarded ad failed to show: ${error.message}');
        ad.dispose();
        _rewardedAd = null;
      },
    );
    
    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint('🎉 [Guidebook Ads] User earned reward: ${reward.amount} ${reward.type}');
        _onAdCompleted();
      },
    );
  }

  void _onAdCompleted() {
    final watched = (_state.adsWatched + 1).clamp(0, adsRequired);
    if (watched >= adsRequired) {
      final now = DateTime.now();
      _box.put('${guidebookId}_unlockedAt', now.millisecondsSinceEpoch);
      _state = GuidebookUnlockState(adsWatched: watched, unlockedAt: now);
      debugPrint('🎉 [Guidebook Ads] Guidebook unlocked for 24 hours!');
    } else {
      _state = _state.copyWith(adsWatched: watched);
      debugPrint('📱 [Guidebook Ads] Ad completed. Progress: $watched/$adsRequired');
      _preloadAd();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }
}

// Provider for a specific guidebook
final guidebookUnlockProvider = Provider.family<GuidebookUnlockController, String>(
  (ref, guidebookId) => GuidebookUnlockController(guidebookId),
);