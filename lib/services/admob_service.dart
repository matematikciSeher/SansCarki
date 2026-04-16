import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum RewardedPlacement {
  homeExtraSpin,
  wheelExtraHint,
  quizFiftyFifty,
}

class AdMobService {
  AdMobService._();

  static final AdMobService instance = AdMobService._();

  // Not: Release'te sadece olusturulmus gercek reklam birimlerini kullanin.
  // Henuz olusturulmayan alanlar bos birakildi; bu durumda ilgili reklam gosterilmez.
  static const String _homeRewardedAdUnitId = '';
  static const String _wheelRewardedAdUnitId =
      'ca-app-pub-7068164541011250/8157435697';
  static const String _quizRewardedAdUnitId = '';
  static const String _quizInterstitialAdUnitId = '';

  static String get _testRewardedAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/5224354917';
    return 'ca-app-pub-3940256099942544/1712485313';
  }

  static String get _testInterstitialAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/1033173712';
    return 'ca-app-pub-3940256099942544/4411468910';
  }

  bool _isInitialized = false;
  final Map<RewardedPlacement, RewardedAd?> _rewardedAds = {
    for (final placement in RewardedPlacement.values) placement: null,
  };
  final Map<RewardedPlacement, bool> _rewardedLoading = {
    for (final placement in RewardedPlacement.values) placement: false,
  };

  InterstitialAd? _quizInterstitialAd;
  bool _isQuizInterstitialLoading = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    await MobileAds.instance.initialize();
    _isInitialized = true;

    for (final placement in RewardedPlacement.values) {
      loadRewardedAd(placement);
    }
    loadQuizInterstitialAd();
  }

  bool isRewardedAdReady(RewardedPlacement placement) =>
      _rewardedAds[placement] != null;

  void loadRewardedAd(RewardedPlacement placement) {
    final adUnitId = _rewardedAdUnitIdFor(placement);
    if (adUnitId == null) return;
    if (_rewardedAds[placement] != null || (_rewardedLoading[placement] ?? false)) {
      return;
    }

    _rewardedLoading[placement] = true;
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedLoading[placement] = false;
          _rewardedAds[placement] = ad;
          debugPrint('Rewarded ad loaded for $placement');
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAds[placement] = null;
              loadRewardedAd(placement);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Rewarded ad show failed for $placement: ${error.message}');
              ad.dispose();
              _rewardedAds[placement] = null;
              loadRewardedAd(placement);
            },
          );
        },
        onAdFailedToLoad: (error) {
          _rewardedLoading[placement] = false;
          debugPrint('Rewarded ad load failed for $placement: ${error.message}');
        },
      ),
    );
  }

  Future<bool> showRewardedAd({
    required RewardedPlacement placement,
    required VoidCallback onRewarded,
  }) async {
    final ad = _rewardedAds[placement];
    if (ad == null) {
      loadRewardedAd(placement);
      return false;
    }

    var rewarded = false;
    _rewardedAds[placement] = null;
    await ad.show(
      onUserEarnedReward: (ad, reward) {
        rewarded = true;
        onRewarded();
      },
    );
    loadRewardedAd(placement);
    return rewarded;
  }

  bool get isQuizInterstitialReady => _quizInterstitialAd != null;

  void loadQuizInterstitialAd() {
    final adUnitId = _quizInterstitialAdUnitIdForCurrentMode();
    if (adUnitId == null) return;
    if (_quizInterstitialAd != null || _isQuizInterstitialLoading) return;

    _isQuizInterstitialLoading = true;
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isQuizInterstitialLoading = false;
          _quizInterstitialAd = ad;
          debugPrint('Quiz interstitial loaded');
        },
        onAdFailedToLoad: (error) {
          _isQuizInterstitialLoading = false;
          debugPrint('Quiz interstitial failed to load: ${error.message}');
        },
      ),
    );
  }

  Future<void> showQuizInterstitialAdIfAvailable() async {
    final ad = _quizInterstitialAd;
    if (ad == null) {
      loadQuizInterstitialAd();
      return;
    }

    final completer = Completer<void>();
    _quizInterstitialAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete();
        loadQuizInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Quiz interstitial failed to show: ${error.message}');
        ad.dispose();
        if (!completer.isCompleted) completer.complete();
        loadQuizInterstitialAd();
      },
    );

    await ad.show();
    await completer.future;
  }

  String? _rewardedAdUnitIdFor(RewardedPlacement placement) {
    if (kDebugMode) return _testRewardedAdUnitId;

    final adUnitId = switch (placement) {
      RewardedPlacement.homeExtraSpin => _homeRewardedAdUnitId,
      RewardedPlacement.wheelExtraHint => _wheelRewardedAdUnitId,
      RewardedPlacement.quizFiftyFifty => _quizRewardedAdUnitId,
    };

    if (adUnitId.isEmpty) {
      debugPrint('Release rewarded ad unit is missing for $placement');
      return null;
    }
    return adUnitId;
  }

  String? _quizInterstitialAdUnitIdForCurrentMode() {
    if (kDebugMode) return _testInterstitialAdUnitId;
    if (_quizInterstitialAdUnitId.isEmpty) {
      debugPrint('Release quiz interstitial ad unit is missing');
      return null;
    }
    return _quizInterstitialAdUnitId;
  }
}
