import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/upgrade_controller.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/animated_logo.dart';
import 'widgets/neon_button.dart';
import 'widgets/neon_grid_painter.dart';
import '../../controllers/daily_mission_controller.dart';
import '../../controllers/daily_login_controller.dart';
import '../../controllers/achievement_controller.dart';
import 'widgets/daily_mission_panel.dart';
import 'widgets/daily_login_panel.dart';
import 'widgets/prestige_badge_widget.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animasyonlu arkaplan grid
          const _AnimatedBackground(),
          // İçerik
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  // Üst bar — prestige (sol), ikonlar (sağ)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const PrestigeBadgeWidget(),
                        const Spacer(),
                        // Profil
                        IconButton(
                          icon: const Icon(Icons.person_rounded,
                              color: AppColors.muted, size: 22),
                          onPressed: () =>
                              Get.toNamed(AppRoutes.profile),
                          tooltip: 'tooltip_profile'.tr,
                        ),
                        // Başarım badge
                        Obx(() {
                          final ac = Get.find<AchievementController>();
                          final hasNew = ac.unclaimedCount > 0;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              IconButton(
                                icon: const Icon(
                                    Icons.emoji_events_rounded,
                                    color: AppColors.muted,
                                    size: 22),
                                onPressed: () =>
                                    Get.toNamed(AppRoutes.achievements),
                                tooltip: 'tooltip_achievements'.tr,
                              ),
                              if (hasNew)
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF59E0B),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }),
                        // Günlük giriş badge
                        Obx(() {
                          final dl = Get.find<DailyLoginController>();
                          final hasReward = dl.hasUnclaimedReward;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.calendar_today_rounded,
                                    color: AppColors.muted, size: 22),
                                onPressed: () =>
                                    showDailyLoginPanel(context),
                                tooltip: 'tooltip_daily_login'.tr,
                              ),
                              if (hasReward)
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF59E0B),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }),
                        // Günlük görev badge
                        Obx(() {
                          final dm = Get.find<DailyMissionController>();
                          final count = dm.unclaimedCount;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.task_alt_rounded,
                                    color: AppColors.muted, size: 22),
                                onPressed: () =>
                                    showDailyMissionPanel(context),
                                tooltip: 'tooltip_daily_missions'.tr,
                              ),
                              if (count > 0)
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF97316),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }),
                        // Ayarlar
                        IconButton(
                          icon: const Icon(Icons.settings_rounded,
                              color: AppColors.muted, size: 22),
                          onPressed: () => Get.toNamed(AppRoutes.settings),
                          tooltip: 'tooltip_settings'.tr,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 2),
                  // Logo
                  const AnimatedLogo(),
                  const Spacer(flex: 3),
                  // Skor kartı
                  _ScoreCard(controller: controller),
                  const Spacer(flex: 2),
                  // Butonlar
                  // Devam Et butonu (kayıtlı oyun varsa aktif)
                  Obx(() {
                    final hasSave = controller.hasClassicSave.value ||
                        controller.hasEndlessSave.value;
                    return NeonButton(
                      label: 'btn_continue'.tr,
                      onTap: hasSave ? controller.continueGame : null,
                      icon: Icons.play_arrow_rounded,
                      disabled: !hasSave,
                    );
                  }),
                  const SizedBox(height: 12),
                  NeonButton(
                    label: 'btn_classic'.tr,
                    onTap: controller.startClassicGame,
                    icon: Icons.emoji_events_rounded,
                  ),
                  const SizedBox(height: 12),
                  NeonButton(
                    label: 'btn_endless'.tr,
                    onTap: controller.startEndlessGame,
                    outlined: true,
                    icon: Icons.all_inclusive_rounded,
                  ),
                  const SizedBox(height: 12),
                  NeonButton(
                    label: 'btn_upgrades'.tr,
                    onTap: () => Get.toNamed(AppRoutes.upgrade),
                    outlined: true,
                    icon: Icons.auto_awesome_rounded,
                  ),
                  const SizedBox(height: 12),
                  NeonButton(
                    label: 'btn_leaderboard'.tr,
                    onTap: () => Get.toNamed(AppRoutes.leaderboard),
                    outlined: true,
                    icon: Icons.leaderboard_rounded,
                  ),
                  const Spacer(flex: 1),
                  // Versiyon
                  Text('v1.0.0', style: AppTextStyles.bodySmall),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animasyonlu arkaplan ──────────────────────────────────────────────────

class _AnimatedBackground extends StatefulWidget {
  const _AnimatedBackground();

  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => CustomPaint(
        painter: NeonGridPainter(_ctrl.value),
        size: Size.infinite,
      ),
    );
  }
}

// ── Skor Kartı ────────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withAlpha(120), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(20),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Obx(() {
            final upgrades = Get.find<UpgradeController>();
            return Column(
              children: [
                Text('label_high_score'.tr, style: AppTextStyles.hudLabel),
                const SizedBox(height: 8),
                Text(
                  controller.highScore.value.toString().padLeft(7, '0'),
                  style: AppTextStyles.scoreDisplay.copyWith(
                    color: AppColors.success,
                    shadows: [
                      Shadow(
                        color: AppColors.glowSuccess,
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.emoji_events_outlined,
                        color: AppColors.primaryLight, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'label_best_level'.trParams({'level': controller.bestLevel.value.toString()}),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryLight,
                      ),
                    ),
                    const Spacer(),
                    // Gem bakiyesi (tıklanabilir → GemShop)
                    Obx(() => GestureDetector(
                          onTap: () => Get.toNamed(AppRoutes.upgrade),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.diamond_rounded,
                                  color: Color(0xFF06B6D4), size: 14),
                              const SizedBox(width: 4),
                              Text(
                                upgrades.gems.value.toString(),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: const Color(0xFF06B6D4),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ],
            );
          }),
    );
  }
}
