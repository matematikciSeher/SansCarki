import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Çark ekranındaki tüm reklam birimlerini yöneten merkezi servis.
class WheelAdManager {
  WheelAdManager._();
  static final WheelAdManager instance = WheelAdManager._();

  // ── Production reklam birimi ID'leri ──
  static const String _bannerAdUnitId =
      'ca-app-pub-7068164541011250/3679959047';
  static const String _interstitialAdUnitId =
      'ca-app-pub-7068164541011250/1464859247';
  static const String _rewardedInterstitialAdUnitId =
      'ca-app-pub-7068164541011250/3031024107';
  static const String _rewardedAdUnitId =
      'ca-app-pub-7068164541011250/7838695908';

  // ── Test reklam birimi ID'leri (debug modda) ──
  static String get _testBannerAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-3940256099942544/2934735716';

  static String get _testInterstitialAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';

  static String get _testRewardedInterstitialAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/5354046379'
      : 'ca-app-pub-3940256099942544/6978759866';

  static String get _testRewardedAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/5224354917'
      : 'ca-app-pub-3940256099942544/1712485313';

  // ── Aktif ID'ler (mod'a göre) ──
  static String get bannerUnitId =>
      kDebugMode ? _testBannerAdUnitId : _bannerAdUnitId;
  static String get interstitialUnitId =>
      kDebugMode ? _testInterstitialAdUnitId : _interstitialAdUnitId;
  static String get rewardedInterstitialUnitId => kDebugMode
      ? _testRewardedInterstitialAdUnitId
      : _rewardedInterstitialAdUnitId;
  static String get rewardedUnitId =>
      kDebugMode ? _testRewardedAdUnitId : _rewardedAdUnitId;

  // ── Durum ──
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;

  RewardedInterstitialAd? _rewardedInterstitialAd;
  bool _isRewardedInterstitialLoading = false;

  RewardedAd? _rewardedAd;
  bool _isRewardedLoading = false;

  int _spinCount = 0;
  static const int _interstitialInterval = 3;

  /// Kötü sayılan çark sonuçları (düşük puan, Pas, İflas).
  static const Set<String> badResults = {'Pas', 'İflas', '+100', '+200'};
  static bool isBadResult(String result) => badResults.contains(result);

  // ── Ön-yükleme ──
  void preloadAll() {
    loadInterstitialAd();
    loadRewardedInterstitialAd();
    loadRewardedAd();
  }

  // ── Spin Sayacı ──
  void incrementSpinCount() => _spinCount++;
  bool get shouldShowInterstitial =>
      _spinCount > 0 && _spinCount % _interstitialInterval == 0;

  // ═══════════════════════════════════════════════════════════
  //  INTERSTITIAL  –  Her 3. çevirişte gösterilir
  // ═══════════════════════════════════════════════════════════
  bool get isInterstitialReady => _interstitialAd != null;

  void loadInterstitialAd() {
    if (_interstitialAd != null || _isInterstitialLoading) return;
    _isInterstitialLoading = true;
    InterstitialAd.load(
      adUnitId: interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isInterstitialLoading = false;
          _interstitialAd = ad;
          debugPrint('[WheelAdManager] Interstitial loaded');
        },
        onAdFailedToLoad: (error) {
          _isInterstitialLoading = false;
          debugPrint(
              '[WheelAdManager] Interstitial load failed: ${error.message}');
        },
      ),
    );
  }

  Future<void> showInterstitialAd() async {
    final ad = _interstitialAd;
    if (ad == null) {
      loadInterstitialAd();
      return;
    }

    final completer = Completer<void>();
    _interstitialAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete();
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint(
            '[WheelAdManager] Interstitial show failed: ${error.message}');
        ad.dispose();
        if (!completer.isCompleted) completer.complete();
        loadInterstitialAd();
      },
    );
    await ad.show();
    await completer.future;
  }

  // ═══════════════════════════════════════════════════════════
  //  REWARDED INTERSTITIAL  –  Ekstra çevirme hakkı
  // ═══════════════════════════════════════════════════════════
  bool get isRewardedInterstitialReady => _rewardedInterstitialAd != null;

  void loadRewardedInterstitialAd() {
    if (_rewardedInterstitialAd != null || _isRewardedInterstitialLoading) {
      return;
    }
    _isRewardedInterstitialLoading = true;
    RewardedInterstitialAd.load(
      adUnitId: rewardedInterstitialUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isRewardedInterstitialLoading = false;
          _rewardedInterstitialAd = ad;
          debugPrint('[WheelAdManager] Rewarded interstitial loaded');
        },
        onAdFailedToLoad: (error) {
          _isRewardedInterstitialLoading = false;
          debugPrint(
              '[WheelAdManager] Rewarded interstitial load failed: ${error.message}');
        },
      ),
    );
  }

  Future<bool> showRewardedInterstitialAd({
    required VoidCallback onRewarded,
  }) async {
    final ad = _rewardedInterstitialAd;
    if (ad == null) {
      loadRewardedInterstitialAd();
      return false;
    }

    var rewarded = false;
    final completer = Completer<void>();
    _rewardedInterstitialAd = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete();
        loadRewardedInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint(
            '[WheelAdManager] Rewarded interstitial show failed: ${error.message}');
        ad.dispose();
        if (!completer.isCompleted) completer.complete();
        loadRewardedInterstitialAd();
      },
    );

    await ad.show(onUserEarnedReward: (ad, reward) {
      rewarded = true;
      onRewarded();
    });
    await completer.future;
    return rewarded;
  }

  // ═══════════════════════════════════════════════════════════
  //  REWARDED  –  Kötü ödül sonrası tekrar çevirme
  // ═══════════════════════════════════════════════════════════
  bool get isRewardedReady => _rewardedAd != null;

  void loadRewardedAd() {
    if (_rewardedAd != null || _isRewardedLoading) return;
    _isRewardedLoading = true;
    RewardedAd.load(
      adUnitId: rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _isRewardedLoading = false;
          _rewardedAd = ad;
          debugPrint('[WheelAdManager] Rewarded ad loaded');
        },
        onAdFailedToLoad: (error) {
          _isRewardedLoading = false;
          debugPrint(
              '[WheelAdManager] Rewarded ad load failed: ${error.message}');
        },
      ),
    );
  }

  Future<bool> showRewardedAd({required VoidCallback onRewarded}) async {
    final ad = _rewardedAd;
    if (ad == null) {
      loadRewardedAd();
      return false;
    }

    var rewarded = false;
    final completer = Completer<void>();
    _rewardedAd = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete();
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[WheelAdManager] Rewarded show failed: ${error.message}');
        ad.dispose();
        if (!completer.isCompleted) completer.complete();
        loadRewardedAd();
      },
    );

    await ad.show(onUserEarnedReward: (ad, reward) {
      rewarded = true;
      onRewarded();
    });
    await completer.future;
    return rewarded;
  }

  // ── Temizlik ──
  void disposeAds() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _rewardedInterstitialAd?.dispose();
    _rewardedInterstitialAd = null;
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _spinCount = 0;
  }
}
