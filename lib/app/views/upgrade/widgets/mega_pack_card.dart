import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../controllers/upgrade_controller.dart';
import '../../../models/power_up_cell.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class MegaPackCard extends StatefulWidget {
  const MegaPackCard({super.key});

  @override
  State<MegaPackCard> createState() => _MegaPackCardState();
}

class _MegaPackCardState extends State<MegaPackCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _gradCtrl;

  static const int _cost = 80;
  static const int _originalCost = 110;

  @override
  void initState() {
    super.initState();
    _gradCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _gradCtrl.dispose();
    super.dispose();
  }

  static IconData _iconOf(PowerUpType t) => switch (t) {
        PowerUpType.fireball => Icons.local_fire_department_rounded,
        PowerUpType.nuke => Icons.blur_circular_rounded,
        PowerUpType.multiBall => Icons.bubble_chart_rounded,
        PowerUpType.speedBoost => Icons.flash_on_rounded,
        PowerUpType.shieldRow => Icons.shield_rounded,
      };

  static Color _colorOf(PowerUpType t) => switch (t) {
        PowerUpType.fireball => const Color(0xFFEF4444),
        PowerUpType.nuke => const Color(0xFF8B5CF6),
        PowerUpType.multiBall => AppColors.cyan,
        PowerUpType.speedBoost => AppColors.amber,
        PowerUpType.shieldRow => const Color(0xFF3B82F6),
      };

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<UpgradeController>();

    return Obx(() {
      final canAfford = ctrl.gems.value >= _cost;

      return AnimatedBuilder(
        animation: _gradCtrl,
        builder: (context, child) {
          final c1 = Color.lerp(
            AppColors.primary,
            AppColors.cyan,
            _gradCtrl.value,
          )!.withAlpha(200);
          final c2 = Color.lerp(
            AppColors.cyan,
            AppColors.primary,
            _gradCtrl.value,
          )!.withAlpha(200);

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [c1, c2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(1.5),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(20),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık + badge
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: AppColors.primaryLight, size: 18),
                const SizedBox(width: 8),
                Text(
                  'label_mega_pack'.tr,
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontSize: 14,
                    color: AppColors.foreground,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: AppColors.primary.withAlpha(150)),
                  ),
                  child: Text(
                    'badge_best_value'.tr,
                    style: AppTextStyles.hudLabel.copyWith(
                      fontSize: 9,
                      color: AppColors.primaryLight,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // İkon grubu
            Row(
              children: PowerUpType.values
                  .map((type) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _colorOf(type).withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: _colorOf(type).withAlpha(80)),
                          ),
                          child: Icon(_iconOf(type),
                              color: _colorOf(type), size: 18),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            Text(
              'subtitle_mega_pack'.tr,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.muted,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 12),
            // Fiyat satırı
            Row(
              children: [
                Text(
                  '$_originalCost💎',
                  style: AppTextStyles.hudValue.copyWith(
                    fontSize: 12,
                    color: AppColors.muted,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: AppColors.muted,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: canAfford
                        ? () async {
                            HapticFeedback.mediumImpact();
                            final ok = await ctrl.purchaseMegaPack();
                            if (ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'snack_mega_pack_bought'.tr,
                                    style: AppTextStyles.bodySmall
                                        .copyWith(color: Colors.white),
                                  ),
                                  backgroundColor:
                                      AppColors.primary.withAlpha(220),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8)),
                                ),
                              );
                            }
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: canAfford
                            ? AppColors.primary.withAlpha(40)
                            : Colors.white.withAlpha(8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: canAfford
                              ? AppColors.primary.withAlpha(200)
                              : Colors.white.withAlpha(25),
                        ),
                        boxShadow: canAfford
                            ? [
                                BoxShadow(
                                    color: AppColors.primary.withAlpha(40),
                                    blurRadius: 12)
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.diamond_rounded,
                              size: 14,
                              color: canAfford
                                  ? AppColors.primaryLight
                                  : AppColors.muted),
                          const SizedBox(width: 6),
                          Text(
                            '$_cost  SATIN AL',
                            style: AppTextStyles.hudValue.copyWith(
                              fontSize: 13,
                              color: canAfford
                                  ? AppColors.primaryLight
                                  : AppColors.muted,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
