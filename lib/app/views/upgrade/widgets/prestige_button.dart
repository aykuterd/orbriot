import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/prestige_controller.dart';
import '../../../controllers/upgrade_controller.dart';
import 'prestige_modal.dart';

/// Upgrade Shop'ta tüm yükseltmeler max'a gelince görünen Prestige butonu.
class PrestigeButton extends StatelessWidget {
  const PrestigeButton({super.key});

  String _roman(int n) {
    const r = ['I', 'II', 'III', 'IV', 'V'];
    if (n < 1 || n > 5) return '';
    return r[n - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final prestige = Get.find<PrestigeController>();
      final upgrade = Get.find<UpgradeController>();

      final canPrestige = prestige.canPrestige;
      final level = upgrade.prestigeLevel.value;
      final isMaxed = level >= UpgradeController.maxPrestigeLevel;

      // Max prestige'e ulaşıldıysa banner göster
      if (isMaxed) {
        return _MaxPrestigeBanner(level: level);
      }

      return Column(
        children: [
          const SizedBox(height: 8),
          // Ayırıcı çizgi
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  canPrestige
                      ? const Color(0xFFFBBF24).withAlpha(128)
                      : Colors.white.withAlpha(20),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Durum mesajı (sadece kilitliyken)
          if (!canPrestige)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'label_prestige_hint'.tr,
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 10,
                  letterSpacing: 1,
                  color: Colors.white.withAlpha(51),
                ),
              ),
            ),
          // Ana buton
          GestureDetector(
            onTap: canPrestige
                ? () => showPrestigeModal(context)
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: canPrestige
                    ? const LinearGradient(
                        colors: [Color(0xFF2a1a00), Color(0xFF3d2500)],
                      )
                    : null,
                color: canPrestige ? null : const Color(0xFF1a1a2e),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: canPrestige
                      ? const Color(0xFFFBBF24).withAlpha(179)
                      : Colors.white.withAlpha(20),
                  width: 1.5,
                ),
                boxShadow: canPrestige
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFBBF24).withAlpha(77),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Text(
                    '👑',
                    style: TextStyle(
                      fontSize: canPrestige ? 28 : 20,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'PRESTIGE',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      color: canPrestige
                          ? const Color(0xFFFBBF24)
                          : Colors.white.withAlpha(51),
                      shadows: canPrestige
                          ? [
                              Shadow(
                                color: const Color(0xFFFBBF24).withAlpha(179),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    level == 0
                        ? 'label_prestige_first_bonus'.tr
                        : 'label_prestige_level_bonus'.trParams({
                            'from': _roman(level),
                            'to': _roman(level + 1),
                            'pct': '${(level + 1) * 10}',
                          }),
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 9,
                      letterSpacing: 1,
                      color: canPrestige
                          ? const Color(0xFFFBBF24).withAlpha(179)
                          : Colors.white.withAlpha(38),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      );
    });
  }
}

class _MaxPrestigeBanner extends StatelessWidget {
  final int level;
  const _MaxPrestigeBanner({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2a1a00), Color(0xFF1c1000)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFBBF24).withAlpha(102),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👑', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PRESTIGE LV. V',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFBBF24),
                ),
              ),
              Text(
                'label_prestige_max_reached'.tr,
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 9,
                  color: const Color(0xFFFBBF24).withAlpha(128),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
