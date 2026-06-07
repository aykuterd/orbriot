import 'dart:math';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/analytics_service.dart';
import '../models/power_up_cell.dart';

/// Satın alınan ve günlük bedava şarjları yöneten kontroller.
///
/// Her [PowerUpType] için SharedPreferences'ta şarj sayısı tutulur.
/// Oyun içinde slot'a dokunulunca [useCharge] → [PowerUpController.queueForNextTurn].
class PowerUpInventoryController extends GetxController {
  // ── Şarj sayaçları ────────────────────────────────────────────────────────

  final RxMap<String, int> _charges = <String, int>{}.obs;
  final RxBool dailyClaimed = false.obs;

  static const _kDailyDate   = 'pu_daily_date';
  static const _kChargePrefix = 'pu_charge_';

  // Fiyatlar (gem) — 5'li paket başına
  static const Map<PowerUpType, int> packPrices = {
    PowerUpType.fireball:   25,
    PowerUpType.nuke:       30,
    PowerUpType.multiBall:  20,
    PowerUpType.speedBoost: 15,
    PowerUpType.shieldRow:  20,
  };

  static const int packSize     = 5;  // 5 şarj / paket
  static const int maxCharges   = 99; // tür başına maksimum şarj

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  // ── Yükleme ───────────────────────────────────────────────────────────────

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    for (final type in PowerUpType.values) {
      _charges[type.name] = prefs.getInt('$_kChargePrefix${type.name}') ?? 0;
    }
    final lastDate = prefs.getString(_kDailyDate) ?? '';
    final today = DateTime.now().toLocal().toString().substring(0, 10);
    dailyClaimed.value = lastDate == today;
  }

  Future<void> _save(PowerUpType type, int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_kChargePrefix${type.name}', count);
  }

  // ── Sorgular ──────────────────────────────────────────────────────────────

  int chargesOf(PowerUpType type) => _charges[type.name] ?? 0;
  bool canUse(PowerUpType type)   => chargesOf(type) > 0;

  // ── Kullanım & Ekleme ────────────────────────────────────────────────────

  /// 1 şarj tüketir. Şarj yoksa false döner.
  Future<bool> useCharge(PowerUpType type) async {
    final current = chargesOf(type);
    if (current <= 0) return false;
    final newCount = current - 1;
    _charges[type.name] = newCount;
    await _save(type, newCount);
    if (Get.isRegistered<AnalyticsService>()) {
      Get.find<AnalyticsService>().logPowerUpUsed(type: type.name);
    }
    return true;
  }

  /// [count] şarj ekler. Maksimum [maxCharges]'a kadar.
  Future<void> addCharges(PowerUpType type, int count) async {
    final current = chargesOf(type);
    final newCount = (current + count).clamp(0, maxCharges);
    _charges[type.name] = newCount;
    await _save(type, newCount);
  }

  // ── Günlük Bedava Şarj ────────────────────────────────────────────────────

  /// Bugün zaten alındıysa false döner; aksi hâlde random 1 şarj verir ve true döner.
  Future<bool> tryClaimDailyCharge() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_kDailyDate) ?? '';
    final today    = DateTime.now().toLocal().toString().substring(0, 10);
    if (lastDate == today) return false;

    final types = PowerUpType.values;
    final type  = types[Random().nextInt(types.length)];
    await addCharges(type, 1);
    await prefs.setString(_kDailyDate, today);
    _lastDailyType.value = type;
    dailyClaimed.value = true;
    return true;
  }

  /// Son verilen günlük şarjın türü (bildirim için).
  final Rx<PowerUpType?> _lastDailyType = Rx(null);
  PowerUpType? get lastDailyType => _lastDailyType.value;

  // ── Tüm şarjları sıfırla (test/debug) ────────────────────────────────────

  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final type in PowerUpType.values) {
      _charges[type.name] = 0;
      await prefs.remove('$_kChargePrefix${type.name}');
    }
  }
}
