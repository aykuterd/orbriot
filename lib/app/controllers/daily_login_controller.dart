import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'achievement_controller.dart';
import 'upgrade_controller.dart';

class DailyLoginController extends GetxController {
  static const _kLastDate     = 'daily_login_last_date';
  static const _kCurrentDay   = 'daily_login_current_day';
  static const _kClaimedToday = 'daily_login_claimed_today';

  /// Her gün için gem ödülü (1. günden 7. güne)
  static const List<int> rewards = [3, 5, 5, 8, 10, 10, 50];

  /// Mevcut seri günü (1–7)
  final RxInt  currentDay   = 1.obs;
  /// Bugünkü ödül alındı mı?
  final RxBool claimedToday = false.obs;

  SharedPreferences? _prefs;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _checkAndUpdate();
  }

  void _checkAndUpdate() {
    final prefs      = _prefs!;
    final todayKey   = _todayKey();
    final lastDateStr = prefs.getString(_kLastDate);

    if (lastDateStr == todayKey) {
      // Bugün zaten açıldı — kaydedilmiş durumu yükle
      currentDay.value   = prefs.getInt(_kCurrentDay) ?? 1;
      claimedToday.value = prefs.getBool(_kClaimedToday) ?? false;
      return;
    }

    if (lastDateStr != null) {
      final last  = _parseDate(lastDateStr);
      final today = _todayDate();
      final diff  = today.difference(last).inDays;

      if (diff == 1) {
        // Ardışık gün → seriyi ilerlet (7 → 1 döngüsü)
        final savedDay    = prefs.getInt(_kCurrentDay) ?? 1;
        currentDay.value  = (savedDay % 7) + 1;
      } else {
        // Seri koptu → başa dön
        currentDay.value = 1;
      }
    } else {
      // İlk açılış
      currentDay.value = 1;
    }

    claimedToday.value = false;
    prefs.setString(_kLastDate,     todayKey);
    prefs.setInt(_kCurrentDay,      currentDay.value);
    prefs.setBool(_kClaimedToday,   false);
  }

  /// Bugünün ödülünü al
  Future<void> claimToday() async {
    if (claimedToday.value) return;
    final reward = rewards[currentDay.value - 1];
    await Get.find<UpgradeController>().addGems(reward);
    if (Get.isRegistered<AchievementController>()) {
      Get.find<AchievementController>().reportDayPlayed();
    }
    claimedToday.value = true;
    await _prefs?.setBool(_kClaimedToday, true);
  }

  /// Bugünün gem ödülü
  int get todayReward => rewards[currentDay.value - 1];

  /// Bugün ödül alınmadıysa göster badge'i
  bool get hasUnclaimedReward => !claimedToday.value;

  // ── Yardımcılar ──────────────────────────────────────────────────────────

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  DateTime _todayDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _parseDate(String s) {
    final p = s.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }
}
