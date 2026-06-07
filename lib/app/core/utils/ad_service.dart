import 'dart:async';
import 'dart:io' show Platform;
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'analytics_service.dart';

/// Merkezi reklam yönetim servisi.
/// Global GetxService olarak app ömür boyu yaşar.
class AdService extends GetxService {
  // ── Ad-Free Flag ────────────────────────────────────────────────────────
  static const _kAdFreeKey = 'ad_free';
  final RxBool isAdFree = false.obs;

  // ── Interstitial Sayacı ─────────────────────────────────────────────────
  int _gameOverCount = 0;

  // ── Ad Instances ────────────────────────────────────────────────────────
  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  bool _isShowingAd = false;

  // ── Test Ad Unit IDs ────────────────────────────────────────────────────
  String get _rewardedAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-9388120393263060/2295552501'
      : 'ca-app-pub-9388120393263060/6370528888';

  String get _interstitialAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-9388120393263060/4921715848'
      : 'ca-app-pub-9388120393263060/7915240921';

  // ── Initialization ──────────────────────────────────────────────────────

  /// Servisi başlat: isAdFree flag'i yükle ve reklamları ön yükle.
  /// MobileAds.instance.initialize() main.dart'ta çağrılmalı.
  Future<AdService> init() async {
    final prefs = await SharedPreferences.getInstance();
    isAdFree.value = prefs.getBool(_kAdFreeKey) ?? false;
    _preloadRewarded();
    _preloadInterstitial();
    return this;
  }

  // ── Ad-Free Yönetimi ───────────────────────────────────────────────────

  Future<void> setAdFree(bool value) async {
    isAdFree.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAdFreeKey, value);
  }

  // ── Rewarded Ad ─────────────────────────────────────────────────────────

  /// Rewarded reklam gösterir.
  /// Kullanıcı ödülü kazandıysa `true`, aksi halde `false` döner.
  Future<bool> showRewardedAd() async {
    if (isAdFree.value) return false;
    if (_isShowingAd) return false;

    // Reklam yüklü değilse yüklemeyi dene, 10 sn timeout
    if (_rewardedAd == null) {
      _preloadRewarded();
      final loaded = await _waitForRewarded();
      if (!loaded) return false;
    }

    final ad = _rewardedAd;
    if (ad == null) return false;

    _isShowingAd = true;
    bool earned = false;
    final completer = Completer<bool>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _isShowingAd = false;
        _preloadRewarded();
        if (!completer.isCompleted) completer.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _isShowingAd = false;
        _preloadRewarded();
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    ad.show(onUserEarnedReward: (ad, reward) {
      earned = true;
      if (Get.isRegistered<AnalyticsService>()) {
        Get.find<AnalyticsService>().logAdWatched(placement: 'rewarded');
      }
    });

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _isShowingAd = false;
        return false;
      },
    );
  }

  /// Rewarded reklam yüklenmesini 10 sn bekler.
  Future<bool> _waitForRewarded() async {
    for (int i = 0; i < 20; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (_rewardedAd != null) return true;
    }
    return false;
  }

  void _preloadRewarded() {
    if (_rewardedAd != null) return;
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (error) {
          // Sessizce log — sonraki kullanıcı aksiyonunda tekrar dener
          _rewardedAd = null;
        },
      ),
    );
  }

  // ── Interstitial Ad ─────────────────────────────────────────────────────

  /// Game over sayacını artırır.
  void incrementGameOver() => _gameOverCount++;

  /// Interstitial gösterilmeli mi? (Her 3 game over'da 1)
  bool get shouldShowInterstitial =>
      _gameOverCount % 3 == 0 && _gameOverCount > 0 && !isAdFree.value;

  /// Interstitial reklam gösterir.
  /// Reklam yüklü değilse beklemez, direkt true döner (navigasyon engellenmez).
  /// Reklam kapandıktan sonra `true` döner.
  Future<bool> showInterstitialAd() async {
    if (isAdFree.value) return true;
    if (_isShowingAd) return true;

    // Reklam yüklü değilse navigasyonu engelleme, preload et ve geç
    if (_interstitialAd == null) {
      _preloadInterstitial();
      return true;
    }

    final ad = _interstitialAd;
    if (ad == null) return true;

    _isShowingAd = true;
    final completer = Completer<bool>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _isShowingAd = false;
        _preloadInterstitial();
        if (!completer.isCompleted) completer.complete(true);
      },
      onAdImpression: (ad) {
        if (Get.isRegistered<AnalyticsService>()) {
          Get.find<AnalyticsService>().logInterstitialShown();
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _isShowingAd = false;
        _preloadInterstitial();
        if (!completer.isCompleted) completer.complete(true);
      },
    );

    ad.show();

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _isShowingAd = false;
        return true;
      },
    );
  }

  void _preloadInterstitial() {
    if (_interstitialAd != null) return;
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
        },
      ),
    );
  }

  // ── Cleanup ─────────────────────────────────────────────────────────────

  @override
  void onClose() {
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    super.onClose();
  }
}
