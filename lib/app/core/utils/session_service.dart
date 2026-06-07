import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulama oturum (cold start) sayacı ve first-purchase teklifi durumu.
class SessionService extends GetxService {
  static const _kSessionCount        = 'session_count';
  static const _kFpOffered           = 'fp_offered';
  static const _kFpOfferedAt         = 'fp_offered_at_ms';

  final RxInt  sessionCount        = 0.obs;
  final RxBool firstPurchaseShown  = false.obs;

  late SharedPreferences _prefs;

  Future<SessionService> init() async {
    _prefs = await SharedPreferences.getInstance();
    final count = (_prefs.getInt(_kSessionCount) ?? 0) + 1;
    await _prefs.setInt(_kSessionCount, count);
    sessionCount.value        = count;
    firstPurchaseShown.value  = _prefs.getBool(_kFpOffered) ?? false;
    return this;
  }

  /// Session 3-5 arasında ve teklif daha önce gösterilmemişse true döner.
  bool get shouldShowFirstPurchaseOffer =>
      !firstPurchaseShown.value &&
      sessionCount.value >= 3 &&
      sessionCount.value <= 5;

  /// First-purchase teklifi gösterildi olarak işaretle.
  Future<void> markFirstPurchaseShown() async {
    firstPurchaseShown.value = true;
    await _prefs.setBool(_kFpOffered, true);
    await _prefs.setInt(_kFpOfferedAt, DateTime.now().millisecondsSinceEpoch);
  }
}
