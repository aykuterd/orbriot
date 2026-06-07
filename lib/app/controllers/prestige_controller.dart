import 'package:get/get.dart';
import '../core/utils/analytics_service.dart';
import '../core/utils/firestore_service.dart';
import 'upgrade_controller.dart';
import '../models/upgrade_config.dart';

class PrestigeController extends GetxController {
  UpgradeController get _upgrade => Get.find<UpgradeController>();

  /// Tüm yükseltmeler max seviyede VE prestige limiti dolmamışsa true.
  /// Not: Bu getter reaktif değildir; Obx içinde doğru çalışması için
  /// _upgrade.prestigeLevel.value ve _upgrade._levels (RxMap) okunur.
  bool get canPrestige {
    if (_upgrade.prestigeLevel.value >= UpgradeController.maxPrestigeLevel) {
      return false;
    }
    return UpgradeCatalog.all
        .every((def) => _upgrade.levelOf(def.key) >= def.maxLevel);
  }

  /// Mevcut prestige level (0-5).
  int get currentLevel => _upgrade.prestigeLevel.value;

  /// Prestige yapıldıktan sonraki gem çarpanı.
  double get nextMultiplier =>
      1.0 + 0.10 * (currentLevel + 1);

  /// Prestige uygula: önce level artır (crash-safe), sonra sıfırla.
  /// Crash olursa oyuncu prestige kazanmış ama sıfırlanmamış olur — kurtarılabilir durum.
  Future<void> executePrestige() async {
    if (!canPrestige) return;
    await _upgrade.incrementPrestigeLevel();  // önce level artır
    await _upgrade.resetForPrestige();         // sonra sıfırla
    if (Get.isRegistered<AnalyticsService>()) {
      Get.find<AnalyticsService>().logPrestige(level: _upgrade.prestigeLevel.value);
    }
    // Otomatik cloud save
    if (Get.isRegistered<FirestoreService>()) {
      Get.find<FirestoreService>().autoSave();
    }
  }
}
