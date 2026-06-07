import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/upgrade_controller.dart';
import '../../../models/upgrade_config.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'prestige_button.dart';
import 'shop_widgets.dart';

class UpgradesTab extends StatelessWidget {
  const UpgradesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<UpgradeController>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        ...UpgradeCatalog.all
            .map((def) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Obx(() {
                    final level = ctrl.levelOf(def.key);
                    final isMax = level >= def.maxLevel;
                    final cost = def.nextCost(level);
                    final canAfford = ctrl.gems.value >= cost;
                    return _UpgradeCard(
                      def: def,
                      level: level,
                      isMax: isMax,
                      cost: cost,
                      canAfford: canAfford,
                      onBuy: () async {
                        final ok = await ctrl.purchase(def);
                        if (ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'snack_upgraded'.trParams({'name': def.name}),
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: Colors.white),
                              ),
                              backgroundColor: def.color.withAlpha(220),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          );
                        }
                      },
                    );
                  }),
                )),
        const PrestigeButton(),
      ],
    );
  }
}

// ── Yükseltme Kartı ───────────────────────────────────────────────────────

class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard({
    required this.def,
    required this.level,
    required this.isMax,
    required this.cost,
    required this.canAfford,
    required this.onBuy,
  });

  final UpgradeDef def;
  final int level;
  final bool isMax;
  final int cost;
  final bool canAfford;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMax
              ? def.color.withAlpha(180)
              : def.color.withAlpha(60),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: def.color.withAlpha(isMax ? 30 : 15),
            blurRadius: isMax ? 24 : 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          // İkon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: def.color.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: def.color.withAlpha(80)),
            ),
            child: Icon(def.icon, color: def.color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // İsim + seviye/max
                Row(
                  children: [
                    Text(
                      def.name,
                      style: AppTextStyles.headlineMedium.copyWith(
                        fontSize: 13,
                        color: AppColors.foreground,
                      ),
                    ),
                    const Spacer(),
                    if (isMax)
                      MaxBadge(color: def.color)
                    else
                      Text(
                        '$level/${def.maxLevel}',
                        style: AppTextStyles.hudLabel
                            .copyWith(color: def.color),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  def.desc.tr,
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                ),
                const SizedBox(height: 6),
                // Seviye noktaları + satın al butonu
                Row(
                  children: [
                    ...List.generate(
                      def.maxLevel,
                      (i) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < level
                                ? def.color
                                : def.color.withAlpha(40),
                            border: Border.all(
                              color: def.color
                                  .withAlpha(i < level ? 0 : 80),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (!isMax)
                      BuyButton(
                        cost: cost,
                        canAfford: canAfford,
                        color: def.color,
                        onTap: onBuy,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  def.effectLabel.tr,
                  style: AppTextStyles.hudLabel.copyWith(
                    color: def.color.withAlpha(230),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
