import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/analytics_service.dart';
import '../core/utils/firestore_service.dart';
import '../core/utils/sound_service.dart';
import '../models/power_up_cell.dart';
import '../models/upgrade_config.dart';
import 'achievement_controller.dart';
import 'power_up_inventory_controller.dart';

class UpgradeController extends GetxController {
  final RxInt gems = 0.obs;
  final RxInt prestigeLevel = 0.obs;
  final RxInt adCountToday = 0.obs;

  // key → seviye (0 = hiç alınmamış)
  final RxMap<String, int> _levels = <String, int>{}.obs;

  static const _kGems        = 'gems';
  static const _kPrestigeLevel = 'prestige_level';
  static const int maxPrestigeLevel = 5;
  static const _kAdDateKey  = 'ad_date';
  static const _kAdCountKey = 'ad_count';
  static const _kDailyAdLimit = 5;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    gems.value = prefs.getInt(_kGems) ?? 0;
    prestigeLevel.value = prefs.getInt(_kPrestigeLevel) ?? 0;
    for (final def in UpgradeCatalog.all) {
      _levels[def.key] = prefs.getInt('upg_${def.key}') ?? 0;
    }
    _loadAdCount(prefs);
  }

  void _loadAdCount(SharedPreferences prefs) {
    final savedDate = prefs.getString(_kAdDateKey) ?? '';
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (savedDate == today) {
      adCountToday.value = prefs.getInt(_kAdCountKey) ?? 0;
    } else {
      adCountToday.value = 0;
      prefs.setString(_kAdDateKey, today);
      prefs.setInt(_kAdCountKey, 0);
    }
  }

  int get remainingAdRewards => (_kDailyAdLimit - adCountToday.value).clamp(0, _kDailyAdLimit);

  /// Veri sıfırlandıktan sonra UI'yı tazeler.
  Future<void> reload() => _load();

  int levelOf(String key) => _levels[key] ?? 0;

  // ── Hesaplanan oyun efektleri ─────────────────────────────────────────────

  /// Yeni oyun başında kaç topla başlanır.
  int get startingBalls => 1 + levelOf(UpgradeCatalog.extraBalls.key);

  /// Top hızı çarpanı (1.0 = değişmez).
  double get speedMultiplier =>
      1.0 + 0.08 * levelOf(UpgradeCatalog.ballSpeed.key);

  /// Top boyutu çarpanı (1.0 = değişmez).
  double get sizeMultiplier =>
      1.0 + 0.12 * levelOf(UpgradeCatalog.ballSize.key);

  /// Gem kazanım çarpanı (1.0 = değişmez).
  double get gemMultiplier =>
      1.0 + 0.30 * levelOf(UpgradeCatalog.gemBonus.key);

  /// Prestige başına +%10 gem çarpanı (stacks, max x5 = +%50)
  double get prestigeGemMultiplier =>
      1.0 + 0.10 * prestigeLevel.value;

  /// Toplam gem çarpanı (upgrade çarpanı × prestige çarpanı)
  double get totalGemMultiplier => gemMultiplier * prestigeGemMultiplier;

  // ── İşlemler ─────────────────────────────────────────────────────────────

  /// Gem bakiyesine [amount] ekler ve kaydeder.
  Future<void> addGems(int amount) async {
    gems.value += amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kGems, gems.value);
    // Başarım: gem kazanma
    if (amount > 0 && Get.isRegistered<AchievementController>()) {
      Get.find<AchievementController>().reportGemsEarned(amount);
    }
  }

  /// Gem harca. Yeterliyse true döner ve bakiye azalır.
  Future<bool> spendGems(int amount) async {
    if (gems.value < amount) return false;
    gems.value -= amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kGems, gems.value);
    return true;
  }

  /// Günlük reklam ödülü talep et. Başarılıysa true döner ve +10 gem eklenir.
  Future<bool> claimAdReward() async {
    if (adCountToday.value >= _kDailyAdLimit) return false;
    await addGems(10);
    adCountToday.value++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kAdCountKey, adCountToday.value);
    return true;
  }

  /// Mega Pack satın al (80💎 → her power-up türüne +3 şarj).
  Future<bool> purchaseMegaPack() async {
    const int cost = 80;
    const int chargesPerType = 3;
    if (gems.value < cost) return false;
    final ok = await spendGems(cost);
    if (!ok) return false;
    try {
      final inventory = Get.find<PowerUpInventoryController>();
      for (final type in PowerUpType.values) {
        await inventory.addCharges(type, chargesPerType);
      }
      if (Get.isRegistered<AnalyticsService>()) {
        Get.find<AnalyticsService>().logMegaPackPurchase();
      }
      return true;
    } catch (_) {
      await addGems(cost); // iade
      return false;
    }
  }

  /// Prestige için yükseltme seviyelerini ve gem'i sıfırlar.
  /// Prestige level ve diğer sistemler (skinler, başarımlar) korunur.
  Future<void> resetForPrestige() async {
    // Tüm upgrade seviyelerini sıfırla
    for (final def in UpgradeCatalog.all) {
      _levels[def.key] = 0;
    }
    // Gem'i sıfırla
    gems.value = 0;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kGems, 0);
    for (final def in UpgradeCatalog.all) {
      await prefs.setInt('upg_${def.key}', 0);
    }
  }

  /// Prestige level'ı artırır ve kaydeder.
  Future<void> incrementPrestigeLevel() async {
    if (prestigeLevel.value >= maxPrestigeLevel) return;
    prestigeLevel.value++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPrestigeLevel, prestigeLevel.value);
  }

  /// Yükseltme satın al. Başarılıysa `true` döner.
  Future<bool> purchase(UpgradeDef def) async {
    final current = levelOf(def.key);
    if (current >= def.maxLevel) return false;
    final cost = def.costs[current];
    if (gems.value < cost) return false;

    gems.value -= cost;
    _levels[def.key] = current + 1;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kGems, gems.value);
    await prefs.setInt('upg_${def.key}', current + 1);
    Get.find<SoundService>().playUpgradeBuy();
    // Başarım: ilk yükseltme
    if (Get.isRegistered<AchievementController>()) {
      Get.find<AchievementController>().reportUpgradeBought();
    }
    // Analytics: upgrade satın alındı
    if (Get.isRegistered<AnalyticsService>()) {
      Get.find<AnalyticsService>().logUpgrade(
        upgradeName: def.key,
        level: current + 1,
      );
    }
    // Otomatik cloud save
    if (Get.isRegistered<FirestoreService>()) {
      Get.find<FirestoreService>().autoSave();
    }
    return true;
  }
}
