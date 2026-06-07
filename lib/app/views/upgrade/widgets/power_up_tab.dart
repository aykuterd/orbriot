import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../controllers/power_up_inventory_controller.dart';
import '../../../controllers/upgrade_controller.dart';
import '../../../models/power_up_cell.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'mega_pack_card.dart';
import 'shop_widgets.dart';

class PowerUpTab extends StatelessWidget {
  const PowerUpTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const MegaPackCard(),
        const SizedBox(height: 16),
        SectionHeader(title: 'section_single_packs'.tr),
        const SizedBox(height: 12),
        ...PowerUpType.values.map((type) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PowerUpShopCard(type: type),
            )),
      ],
    );
  }
}

// ── Power-Up Shop Kartı ───────────────────────────────────────────────────

class _PowerUpShopCard extends StatelessWidget {
  const _PowerUpShopCard({required this.type});
  final PowerUpType type;

  static Color _colorOf(PowerUpType t) => switch (t) {
        PowerUpType.fireball => const Color(0xFFEF4444),
        PowerUpType.nuke => const Color(0xFF8B5CF6),
        PowerUpType.multiBall => AppColors.cyan,
        PowerUpType.speedBoost => AppColors.amber,
        PowerUpType.shieldRow => const Color(0xFF3B82F6),
      };

  static IconData _iconOf(PowerUpType t) => switch (t) {
        PowerUpType.fireball => Icons.local_fire_department_rounded,
        PowerUpType.nuke => Icons.blur_circular_rounded,
        PowerUpType.multiBall => Icons.bubble_chart_rounded,
        PowerUpType.speedBoost => Icons.flash_on_rounded,
        PowerUpType.shieldRow => Icons.shield_rounded,
      };

  static String _nameOf(PowerUpType t) => switch (t) {
        PowerUpType.fireball => 'Fireball',
        PowerUpType.nuke => 'Nuke',
        PowerUpType.multiBall => 'Multi-Ball',
        PowerUpType.speedBoost => 'Speed Boost',
        PowerUpType.shieldRow => 'Shield Row',
      };

  static String _descOf(PowerUpType t) => switch (t) {
        PowerUpType.fireball => 'desc_fireball'.tr,
        PowerUpType.nuke => 'desc_nuke'.tr,
        PowerUpType.multiBall => 'desc_multiball'.tr,
        PowerUpType.speedBoost => 'desc_speed_boost'.tr,
        PowerUpType.shieldRow => 'desc_shield_row'.tr,
      };

  @override
  Widget build(BuildContext context) {
    final inventory = Get.find<PowerUpInventoryController>();
    final upgradeCtrl = Get.find<UpgradeController>();
    final color = _colorOf(type);
    final price = PowerUpInventoryController.packPrices[type]!;
    const packSize = PowerUpInventoryController.packSize;

    return Obx(() {
      final charges = inventory.chargesOf(type);
      final canAfford = upgradeCtrl.gems.value >= price;

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(60), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: color.withAlpha(15), blurRadius: 12, spreadRadius: 1),
          ],
        ),
        child: Row(
          children: [
            // İkon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withAlpha(80)),
              ),
              child: Icon(_iconOf(type), color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _nameOf(type),
                        style: AppTextStyles.headlineMedium.copyWith(
                          fontSize: 13,
                          color: AppColors.foreground,
                        ),
                      ),
                      const Spacer(),
                      // Mevcut şarj badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withAlpha(charges > 0 ? 30 : 10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: color.withAlpha(charges > 0 ? 120 : 40)),
                        ),
                        child: Text(
                          'x$charges',
                          style: AppTextStyles.hudValue.copyWith(
                            fontSize: 12,
                            color: charges > 0 ? color : AppColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _descOf(type),
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                  ),
                  const SizedBox(height: 8),
                  // Satın al butonu
                  GestureDetector(
                    onTap: canAfford
                        ? () async {
                            HapticFeedback.mediumImpact();
                            final ok = await upgradeCtrl.spendGems(price);
                            if (ok) {
                              await inventory.addCharges(type, packSize);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'snack_pu_added'.trParams({'name': _nameOf(type), 'count': '$packSize'}),
                                      style: AppTextStyles.bodySmall
                                          .copyWith(color: Colors.white),
                                    ),
                                    backgroundColor: color.withAlpha(220),
                                    duration: const Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                  ),
                                );
                              }
                            }
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: canAfford
                            ? color.withAlpha(35)
                            : Colors.white.withAlpha(8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: canAfford
                              ? color.withAlpha(160)
                              : Colors.white.withAlpha(25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.diamond_rounded,
                              size: 11,
                              color: canAfford ? color : AppColors.muted),
                          const SizedBox(width: 4),
                          Text(
                            'label_charge_price'.trParams({'price': '$price', 'count': '$packSize'}),
                            style: AppTextStyles.hudValue.copyWith(
                              fontSize: 11,
                              color: canAfford ? color : AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
