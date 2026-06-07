import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/power_up_inventory_controller.dart';
import '../../controllers/upgrade_controller.dart';
import '../../models/power_up_cell.dart';
import '../../models/upgrade_config.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../home/widgets/neon_grid_painter.dart';

class UpgradeView extends StatefulWidget {
  const UpgradeView({super.key});

  @override
  State<UpgradeView> createState() => _UpgradeViewState();
}

class _UpgradeViewState extends State<UpgradeView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<UpgradeController>();

    return Scaffold(
      body: Stack(
        children: [
          // Neon grid arka plan
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (context, _) => CustomPaint(
              painter: NeonGridPainter(_bgCtrl.value),
              size: Size.infinite,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Üst bar ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_rounded,
                            color: AppColors.foreground, size: 20),
                        onPressed: Get.back,
                      ),
                      Expanded(
                        child: Text(
                          'title_upgrades_view'.tr,
                          style: AppTextStyles.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // Gem bakiyesi
                      Obx(() => _GemChip(gems: ctrl.gems.value)),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Kart listesi ──────────────────────────────────────────
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      // ── Power-Up Şarj Paketi Bölümü ──────────────────────
                      if (Get.isRegistered<PowerUpInventoryController>()) ...[
                        _SectionHeader(title: 'section_powerup_charges'.tr),
                        const SizedBox(height: 10),
                        ...PowerUpType.values.map((type) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PowerUpShopCard(
                            type: type,
                            upgradeCtrl: ctrl,
                          ),
                        )),
                        const SizedBox(height: 8),
                        _SectionHeader(title: 'section_permanent_upgrades'.tr),
                        const SizedBox(height: 10),
                      ],
                      // ── Normal Yükseltmeler ────────────────────────────────
                      ...UpgradeCatalog.all.map((def) => Padding(
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
                                _showBoughtSnack(def);
                              }
                            },
                          );
                        }),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBoughtSnack(UpgradeDef def) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'snack_upgraded'.trParams({'name': def.name}),
          style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
        ),
        backgroundColor: def.color.withAlpha(220),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// ── Bölüm Başlığı ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.border, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            title,
            style: AppTextStyles.hudLabel.copyWith(
              fontSize: 9,
              letterSpacing: 2.5,
              color: AppColors.muted,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.border, thickness: 1)),
      ],
    );
  }
}

// ── Power-Up Shop Kartı ───────────────────────────────────────────────────

class _PowerUpShopCard extends StatelessWidget {
  const _PowerUpShopCard({required this.type, required this.upgradeCtrl});
  final PowerUpType type;
  final UpgradeController upgradeCtrl;

  static Color _colorOf(PowerUpType t) => switch (t) {
    PowerUpType.fireball   => const Color(0xFFEF4444),
    PowerUpType.nuke       => const Color(0xFF8B5CF6),
    PowerUpType.multiBall  => const Color(0xFF06B6D4),
    PowerUpType.speedBoost => const Color(0xFFFBBF24),
    PowerUpType.shieldRow  => const Color(0xFF3B82F6),
  };

  static IconData _iconOf(PowerUpType t) => switch (t) {
    PowerUpType.fireball   => Icons.local_fire_department_rounded,
    PowerUpType.nuke       => Icons.blur_circular_rounded,
    PowerUpType.multiBall  => Icons.bubble_chart_rounded,
    PowerUpType.speedBoost => Icons.flash_on_rounded,
    PowerUpType.shieldRow  => Icons.shield_rounded,
  };

  static String _nameOf(PowerUpType t) => switch (t) {
    PowerUpType.fireball   => 'Fireball',
    PowerUpType.nuke       => 'Nuke',
    PowerUpType.multiBall  => 'Multi-Ball',
    PowerUpType.speedBoost => 'Speed Boost',
    PowerUpType.shieldRow  => 'Shield Row',
  };

  static String _descOf(PowerUpType t) => switch (t) {
    PowerUpType.fireball   => 'desc_fireball'.tr,
    PowerUpType.nuke       => 'desc_nuke'.tr,
    PowerUpType.multiBall  => 'desc_multiball'.tr,
    PowerUpType.speedBoost => 'desc_speed_boost'.tr,
    PowerUpType.shieldRow  => 'desc_shield_row'.tr,
  };

  @override
  Widget build(BuildContext context) {
    final inventory = Get.find<PowerUpInventoryController>();
    final color     = _colorOf(type);
    final price     = PowerUpInventoryController.packPrices[type]!;
    final packSize  = PowerUpInventoryController.packSize;

    return Obx(() {
      final charges   = inventory.chargesOf(type);
      final canAfford = upgradeCtrl.gems.value >= price;

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(60), width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withAlpha(15), blurRadius: 12, spreadRadius: 1),
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
            // Bilgi
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
                      // Mevcut şarj
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withAlpha(charges > 0 ? 30 : 10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color.withAlpha(charges > 0 ? 120 : 40)),
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
                                        borderRadius: BorderRadius.circular(8)),
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

// ── Gem Chip ──────────────────────────────────────────────────────────────

class _GemChip extends StatelessWidget {
  const _GemChip({required this.gems});
  final int gems;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF06B6D4).withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF06B6D4).withAlpha(120)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.diamond_rounded,
              color: Color(0xFF06B6D4), size: 14),
          const SizedBox(width: 5),
          Text(
            gems.toString(),
            style: AppTextStyles.hudValue.copyWith(
              fontSize: 14,
              color: const Color(0xFF06B6D4),
            ),
          ),
        ],
      ),
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
            blurRadius: 16,
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

          // Bilgi alanı
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // İsim + seviye
                Row(
                  children: [
                    Text(def.name,
                        style: AppTextStyles.headlineMedium.copyWith(
                          fontSize: 13,
                          color: AppColors.foreground,
                        )),
                    const Spacer(),
                    if (isMax)
                      _MaxBadge(color: def.color)
                    else
                      Text(
                        '$level/${def.maxLevel}',
                        style: AppTextStyles.hudLabel
                            .copyWith(color: def.color),
                      ),
                  ],
                ),

                const SizedBox(height: 4),

                // Açıklama
                Text(def.desc,
                    style: AppTextStyles.bodySmall
                        .copyWith(fontSize: 11)),

                const SizedBox(height: 6),

                // Seviye noktaları + maliyet/al
                Row(
                  children: [
                    // Seviye göstergesi (dolu/boş noktalar)
                    ...List.generate(def.maxLevel, (i) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i < level
                                  ? def.color
                                  : def.color.withAlpha(40),
                              border: Border.all(
                                color: def.color.withAlpha(i < level ? 0 : 80),
                                width: 1,
                              ),
                            ),
                          ),
                        )),

                    const Spacer(),

                    // Satın al butonu
                    if (!isMax)
                      _BuyButton(
                        cost: cost,
                        canAfford: canAfford,
                        color: def.color,
                        onTap: onBuy,
                      ),
                  ],
                ),

                // Efekt etiketi
                const SizedBox(height: 4),
                Text(
                  def.effectLabel,
                  style: AppTextStyles.hudLabel.copyWith(
                    color: def.color.withAlpha(200),
                    fontSize: 10,
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

class _MaxBadge extends StatelessWidget {
  const _MaxBadge({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(150)),
      ),
      child: Text(
        'MAX',
        style: AppTextStyles.hudLabel.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BuyButton extends StatelessWidget {
  const _BuyButton({
    required this.cost,
    required this.canAfford,
    required this.color,
    required this.onTap,
  });

  final int cost;
  final bool canAfford;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canAfford ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: canAfford ? color.withAlpha(40) : Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: canAfford ? color.withAlpha(180) : Colors.white.withAlpha(30),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.diamond_rounded,
                size: 12,
                color: canAfford ? color : AppColors.muted),
            const SizedBox(width: 4),
            Text(
              cost.toString(),
              style: AppTextStyles.hudValue.copyWith(
                fontSize: 13,
                color: canAfford ? color : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
