import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../controllers/achievement_controller.dart';
import '../../../controllers/daily_mission_controller.dart';
import '../../../controllers/game_controller.dart';
import '../../../controllers/power_up_controller.dart';
import '../../../controllers/power_up_inventory_controller.dart';
import '../../../models/power_up_cell.dart';

/// ── Cep Envanteri Power-Up Bar ──────────────────────────────────────────
///
/// Sadece bar içeriğini render eder.
/// Görünürlük ve konumlama _InventoryDrawer (game_canvas.dart) tarafından yönetilir.
class PowerUpBar extends StatelessWidget {
  const PowerUpBar({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<PowerUpInventoryController>()) {
      return const SizedBox.shrink();
    }
    final inventory = Get.find<PowerUpInventoryController>();
    final gc        = Get.find<GameController>();
    return _BarContainer(inventory: inventory, gc: gc);
  }
}

// ── Çerçeve ───────────────────────────────────────────────────────────────

class _BarContainer extends StatelessWidget {
  const _BarContainer({required this.inventory, required this.gc});
  final PowerUpInventoryController inventory;
  final GameController gc;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0F).withAlpha(230),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF2A2A3A),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(180),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HUD etiket
            const _HudLabel(),
            const SizedBox(height: 6),
            // Slot'lar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: PowerUpType.values
                  .map((type) => _Slot(type: type, inventory: inventory, gc: gc))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── HUD Başlık Etiketi ────────────────────────────────────────────────────

class _HudLabel extends StatelessWidget {
  const _HudLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Sol köşe bracket
        _bracket(true),
        const Expanded(
          child: Text(
            'CEP ENVANTERİ',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 7,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A4A6A),
              letterSpacing: 2.5,
            ),
          ),
        ),
        // Sağ köşe bracket
        _bracket(false),
      ],
    );
  }

  Widget _bracket(bool left) => Text(
    left ? '[' : ']',
    style: const TextStyle(
      fontFamily: 'Orbitron',
      fontSize: 10,
      color: Color(0xFF3A3A5A),
      fontWeight: FontWeight.w900,
    ),
  );
}

// ── Tek Slot ──────────────────────────────────────────────────────────────

class _Slot extends StatefulWidget {
  const _Slot({
    required this.type,
    required this.inventory,
    required this.gc,
  });
  final PowerUpType type;
  final PowerUpInventoryController inventory;
  final GameController gc;

  @override
  State<_Slot> createState() => _SlotState();
}

class _SlotState extends State<_Slot> with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scaleAnim = Tween(begin: 1.0, end: 0.90)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_pressCtrl);
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  Color get _neonColor => Color(_colorOf(widget.type));

  static int _colorOf(PowerUpType type) => switch (type) {
    PowerUpType.fireball   => 0xFFEF4444,
    PowerUpType.nuke       => 0xFF8B5CF6,
    PowerUpType.multiBall  => 0xFF06B6D4,
    PowerUpType.speedBoost => 0xFFFBBF24,
    PowerUpType.shieldRow  => 0xFF3B82F6,
  };

  static IconData _iconOf(PowerUpType type) => switch (type) {
    PowerUpType.fireball   => Icons.local_fire_department_rounded,
    PowerUpType.nuke       => Icons.blur_circular_rounded,
    PowerUpType.multiBall  => Icons.bubble_chart_rounded,
    PowerUpType.speedBoost => Icons.flash_on_rounded,
    PowerUpType.shieldRow  => Icons.shield_rounded,
  };

  static String _labelOf(PowerUpType type) => switch (type) {
    PowerUpType.fireball   => 'FIRE',
    PowerUpType.nuke       => 'NUKE',
    PowerUpType.multiBall  => 'MULTI',
    PowerUpType.speedBoost => 'SPEED',
    PowerUpType.shieldRow  => 'SHLD',
  };

  Future<void> _onTap() async {
    final charges = widget.inventory.chargesOf(widget.type);
    if (charges <= 0) {
      // Boş slot — hafif titreşim
      HapticFeedback.lightImpact();
      return;
    }
    _pressCtrl.forward().then((_) => _pressCtrl.reverse());
    HapticFeedback.mediumImpact();

    final used = await widget.inventory.useCharge(widget.type);
    if (!used) return;

    // Başarım ve günlük görev raporla
    if (Get.isRegistered<AchievementController>()) {
      Get.find<AchievementController>().reportPowerUpUsed();
    }
    if (Get.isRegistered<DailyMissionController>()) {
      Get.find<DailyMissionController>().reportPowerUpUsed();
    }

    // GameController üzerinden sıraya al
    if (Get.isRegistered<PowerUpController>()) {
      Get.find<PowerUpController>().queueForNextTurn(widget.type);
    }
    widget.gc.showInventoryPowerUpBanner(widget.type);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final charges  = widget.inventory.chargesOf(widget.type);
      final hasCharge = charges > 0;
      final color     = _neonColor;
      final dimColor  = color.withAlpha(55);

      return GestureDetector(
        onTap: _onTap,
        child: AnimatedBuilder(
          animation: _scaleAnim,
          builder: (_, child) => Transform.scale(
            scale: _scaleAnim.value,
            child: child,
          ),
          child: SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Slot kart
                Container(
                  decoration: BoxDecoration(
                    color: hasCharge
                        ? color.withAlpha(18)
                        : const Color(0xFF0D0D15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: hasCharge ? color.withAlpha(140) : const Color(0xFF1E1E2A),
                      width: 1.5,
                    ),
                    boxShadow: hasCharge
                        ? [
                            BoxShadow(
                              color: color.withAlpha(60),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // İkon
                      Icon(
                        _iconOf(widget.type),
                        size: 22,
                        color: hasCharge ? color : dimColor,
                      ),
                      const SizedBox(height: 2),
                      // Kısa etiket
                      Text(
                        _labelOf(widget.type),
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 6,
                          fontWeight: FontWeight.w700,
                          color: hasCharge ? color.withAlpha(200) : dimColor,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),

                // Şarj sayısı badge — sağ üst köşe
                Positioned(
                  top: -4,
                  right: -4,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: hasCharge ? 1.0 : 0.3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: hasCharge ? color : const Color(0xFF1E1E2A),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: hasCharge
                            ? [BoxShadow(color: color.withAlpha(120), blurRadius: 4)]
                            : null,
                      ),
                      child: Text(
                        charges.toString(),
                        style: const TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                // Boş slot — ince X işareti
                if (!hasCharge)
                  Center(
                    child: Opacity(
                      opacity: 0.15,
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: color,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
