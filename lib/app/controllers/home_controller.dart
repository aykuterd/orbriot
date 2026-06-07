import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/game_save_service.dart';
import '../models/game_state.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class HomeController extends GetxController {
  final RxInt highScore = 0.obs;
  final RxInt bestLevel = 0.obs;

  /// Kayıtlı oyun durumları (klasik, sonsuz)
  final RxBool hasClassicSave = false.obs;
  final RxBool hasEndlessSave = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadStats();
    refreshSavedGames();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    highScore.value = prefs.getInt('high_score') ?? 0;
    bestLevel.value = prefs.getInt('best_level') ?? 0;
  }

  /// Kayıtlı oyunları kontrol et (ana menüye her dönüşte çağrılır).
  Future<void> refreshSavedGames() async {
    final saves = await GameSaveService.savedGames();
    hasClassicSave.value = saves[GameMode.classic] ?? false;
    hasEndlessSave.value = saves[GameMode.endless] ?? false;
  }

  void startGame() => startClassicGame();

  void startClassicGame() {
    if (hasClassicSave.value) {
      _showContinueDialog(GameMode.classic);
    } else {
      Get.toNamed(AppRoutes.game, arguments: GameMode.classic);
    }
  }

  void startEndlessGame() {
    if (hasEndlessSave.value) {
      _showContinueDialog(GameMode.endless);
    } else {
      Get.toNamed(AppRoutes.game, arguments: GameMode.endless);
    }
  }

  /// "DEVAM ET" butonu — tek kayıt varsa direkt, iki kayıt varsa seç.
  void continueGame() {
    final hasClassic = hasClassicSave.value;
    final hasEndless = hasEndlessSave.value;

    if (hasClassic && hasEndless) {
      _showSelectModeDialog();
    } else if (hasClassic) {
      Get.toNamed(AppRoutes.game,
          arguments: GameMode.classic,
          parameters: {'restore': 'true'});
    } else if (hasEndless) {
      Get.toNamed(AppRoutes.game,
          arguments: GameMode.endless,
          parameters: {'restore': 'true'});
    }
  }

  /// Devam eden oyun varken aynı mod butonuna basıldığında.
  void _showContinueDialog(GameMode mode) {
    final modeName = mode == GameMode.classic ? 'Klasik' : 'Sonsuz';

    Get.dialog(
      Dialog(
        backgroundColor: const Color(0xFF1A1A3E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.save_rounded,
                  color: AppColors.primaryLight, size: 36),
              const SizedBox(height: 12),
              Text(
                'Devam Eden Oyun',
                style: AppTextStyles.headlineMedium.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                '$modeName modunda kayıtlı bir oyunun var.\nNe yapmak istersin?',
                style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Devam et
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back();
                    Get.toNamed(AppRoutes.game,
                        arguments: mode,
                        parameters: {'restore': 'true'});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.foreground,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('DEVAM ET',
                      style: AppTextStyles.hudLabel
                          .copyWith(fontSize: 12, letterSpacing: 1.5)),
                ),
              ),
              const SizedBox(height: 10),
              // Yeni oyun
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    Get.back();
                    await GameSaveService.delete(mode);
                    hasClassicSave.value =
                        mode == GameMode.classic ? false : hasClassicSave.value;
                    hasEndlessSave.value =
                        mode == GameMode.endless ? false : hasEndlessSave.value;
                    Get.toNamed(AppRoutes.game, arguments: mode);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('YENİ OYUN',
                      style: AppTextStyles.hudLabel
                          .copyWith(fontSize: 12, letterSpacing: 1.5, color: AppColors.error)),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierColor: Colors.black54,
    );
  }

  /// İki modda da kayıtlı oyun varken "DEVAM ET"e basıldığında.
  void _showSelectModeDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: const Color(0xFF1A1A3E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.gamepad_rounded,
                  color: AppColors.primaryLight, size: 36),
              const SizedBox(height: 12),
              Text(
                'Hangi Oyuna Dönmek İstersin?',
                style: AppTextStyles.headlineMedium.copyWith(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Klasik
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.back();
                    Get.toNamed(AppRoutes.game,
                        arguments: GameMode.classic,
                        parameters: {'restore': 'true'});
                  },
                  icon: const Icon(Icons.emoji_events_rounded, size: 18),
                  label: Text('KLASİK',
                      style: AppTextStyles.hudLabel
                          .copyWith(fontSize: 12, letterSpacing: 1.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.foreground,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Sonsuz
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.back();
                    Get.toNamed(AppRoutes.game,
                        arguments: GameMode.endless,
                        parameters: {'restore': 'true'});
                  },
                  icon: const Icon(Icons.all_inclusive_rounded, size: 18),
                  label: Text('SONSUZ',
                      style: AppTextStyles.hudLabel
                          .copyWith(fontSize: 12, letterSpacing: 1.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceVariant,
                    foregroundColor: AppColors.foreground,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierColor: Colors.black54,
    );
  }
}
