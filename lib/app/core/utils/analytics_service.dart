import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:get/get.dart';

/// Merkezi analitik servisi.
/// Global GetxService olarak app ömür boyu yaşar.
class AnalyticsService extends GetxService {
  late final FirebaseAnalytics _analytics;

  Future<AnalyticsService> init() async {
    _analytics = FirebaseAnalytics.instance;
    return this;
  }

  /// Firebase Analytics observer — GetMaterialApp'a verilir.
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ── Oyun Eventleri ──────────────────────────────────────────────────────

  /// Oyun başladı
  Future<void> logGameStart() =>
      _analytics.logEvent(name: 'game_start');

  /// Oyun bitti
  Future<void> logGameOver({
    required int score,
    required int stage,
    required int earnedGems,
  }) =>
      _analytics.logEvent(
        name: 'game_over',
        parameters: {
          'score': score,
          'stage': stage,
          'earned_gems': earnedGems,
        },
      );

  /// Continue kullanıldı
  Future<void> logContinue({required String method}) =>
      _analytics.logEvent(
        name: 'continue_used',
        parameters: {'method': method},
      );

  // ── Ekonomi Eventleri ─────────────────────────────────────────────────

  /// Gem harcandı
  Future<void> logGemSpend({
    required int amount,
    required String item,
  }) =>
      _analytics.logEvent(
        name: 'gem_spend',
        parameters: {'amount': amount, 'item': item},
      );

  /// Upgrade satın alındı
  Future<void> logUpgrade({required String upgradeName, required int level}) =>
      _analytics.logEvent(
        name: 'upgrade_purchase',
        parameters: {'upgrade': upgradeName, 'level': level},
      );

  /// Prestige yapıldı
  Future<void> logPrestige({required int level}) =>
      _analytics.logEvent(
        name: 'prestige',
        parameters: {'level': level},
      );

  // ── Reklam Eventleri ──────────────────────────────────────────────────

  /// Rewarded ad izlendi
  Future<void> logAdWatched({required String placement}) =>
      _analytics.logEvent(
        name: 'ad_rewarded_watched',
        parameters: {'placement': placement},
      );

  /// Interstitial ad gösterildi
  Future<void> logInterstitialShown() =>
      _analytics.logEvent(name: 'ad_interstitial_shown');

  // ── Skin Eventleri ────────────────────────────────────────────────────

  /// Skin satın alındı
  Future<void> logSkinPurchase({required String skinId, required int cost}) =>
      _analytics.logEvent(
        name: 'skin_purchase',
        parameters: {'skin_id': skinId, 'cost': cost},
      );

  /// Skin seçildi (aktif yapıldı)
  Future<void> logSkinSelect({required String skinId}) =>
      _analytics.logEvent(
        name: 'skin_select',
        parameters: {'skin_id': skinId},
      );

  // ── Power-Up Eventleri ────────────────────────────────────────────────

  /// Power-up kullanıldı
  Future<void> logPowerUpUsed({required String type}) =>
      _analytics.logEvent(
        name: 'power_up_used',
        parameters: {'type': type},
      );

  /// Power-up paketi satın alındı
  Future<void> logPowerUpPurchase({required String type, required int cost}) =>
      _analytics.logEvent(
        name: 'power_up_purchase',
        parameters: {'type': type, 'cost': cost},
      );

  // ── Günlük Eventler ───────────────────────────────────────────────────

  /// Günlük görev tamamlandı
  Future<void> logDailyMissionComplete({required String missionId}) =>
      _analytics.logEvent(
        name: 'daily_mission_complete',
        parameters: {'mission_id': missionId},
      );

  /// Günlük giriş ödülü alındı
  Future<void> logDailyLoginClaim({required int day}) =>
      _analytics.logEvent(
        name: 'daily_login_claim',
        parameters: {'day': day},
      );

  // ── Hesap Eventleri ───────────────────────────────────────────────────

  /// Hesap oluşturuldu (anonim → email/password bağlandı)
  Future<void> logAccountLinked() =>
      _analytics.logEvent(name: 'account_linked');

  /// Giriş yapıldı (cihaz değişimi)
  Future<void> logSignIn() =>
      _analytics.logEvent(name: 'sign_in');

  /// Cloud save yapıldı
  Future<void> logCloudSave() =>
      _analytics.logEvent(name: 'cloud_save');

  // ── Mega Pack ─────────────────────────────────────────────────────────

  /// Mega Pack satın alındı
  Future<void> logMegaPackPurchase() =>
      _analytics.logEvent(name: 'mega_pack_purchase');
}
