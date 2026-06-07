import 'package:get/get.dart';
import '../bindings/game_binding.dart';
import '../bindings/home_binding.dart';
import '../views/game/game_view.dart';
import '../views/game_over/game_over_view.dart';
import '../views/home/home_view.dart';
import '../views/leaderboard/leaderboard_view.dart';
import '../views/profile/profile_view.dart';
import '../views/screenshot_helper/screenshot_helper_view.dart';
import '../views/settings/settings_view.dart';
import '../views/splash/splash_view.dart';
import '../views/upgrade/gem_shop_view.dart';
import '../views/achievements/achievement_view.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = AppRoutes.splash;

  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.game,
      page: () => const GameView(),
      binding: GameBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.gameOver,
      page: () => const GameOverView(),
      transition: Transition.downToUp,
    ),
    GetPage(
      name: AppRoutes.upgrade,
      page: () => const GemShopView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.achievements,
      page: () => const AchievementView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.leaderboard,
      page: () => const LeaderboardView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.screenshotHelper,
      page: () => const ScreenshotHelperView(),
      transition: Transition.fadeIn,
    ),
  ];
}
