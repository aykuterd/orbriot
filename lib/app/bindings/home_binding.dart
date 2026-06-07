import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../controllers/power_up_inventory_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/skin_controller.dart';
import '../controllers/upgrade_controller.dart';
import '../controllers/daily_mission_controller.dart';
import '../controllers/daily_login_controller.dart';
import '../controllers/achievement_controller.dart';
import '../controllers/prestige_controller.dart';
import '../core/utils/sound_service.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // SoundService uygulama boyunca yaşar (permanent: true)
    if (!Get.isRegistered<SoundService>()) {
      Get.putAsync<SoundService>(() => SoundService().init(), permanent: true);
    }
    // UpgradeController uygulama boyunca yaşar (permanent: true)
    if (!Get.isRegistered<UpgradeController>()) {
      Get.put<UpgradeController>(UpgradeController(), permanent: true);
    }
    // SettingsController uygulama boyunca yaşar (permanent: true)
    if (!Get.isRegistered<SettingsController>()) {
      Get.put<SettingsController>(SettingsController(), permanent: true);
    }
    // DailyMissionController uygulama boyunca yaşar (permanent: true)
    if (!Get.isRegistered<DailyMissionController>()) {
      Get.put<DailyMissionController>(DailyMissionController(), permanent: true);
    }
    // DailyLoginController uygulama boyunca yaşar (permanent: true)
    if (!Get.isRegistered<DailyLoginController>()) {
      Get.put<DailyLoginController>(DailyLoginController(), permanent: true);
    }
    // AchievementController uygulama boyunca yaşar (permanent: true)
    if (!Get.isRegistered<AchievementController>()) {
      Get.put<AchievementController>(AchievementController(), permanent: true);
    }
    // PowerUpInventoryController uygulama boyunca yaşar (permanent: true)
    if (!Get.isRegistered<PowerUpInventoryController>()) {
      Get.put<PowerUpInventoryController>(PowerUpInventoryController(), permanent: true);
    }
    // SkinController uygulama boyunca yaşar (permanent: true)
    if (!Get.isRegistered<SkinController>()) {
      Get.put<SkinController>(SkinController(), permanent: true);
    }
    // PrestigeController uygulama boyunca yaşar (permanent: true)
    if (!Get.isRegistered<PrestigeController>()) {
      Get.put<PrestigeController>(PrestigeController(), permanent: true);
    }
    Get.lazyPut<HomeController>(() => HomeController());
  }
}
