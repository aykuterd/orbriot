import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/upgrade_controller.dart';

/// 👑 Glowing Crown prestige badge.
/// Prestige level 0'da görünmez.
/// Hem HomeView hem GameView HUD'ında kullanılır.
class PrestigeBadgeWidget extends StatefulWidget {
  /// Küçük versiyon (HUD için). Varsayılan: false (home için normal boy).
  final bool compact;

  const PrestigeBadgeWidget({super.key, this.compact = false});

  @override
  State<PrestigeBadgeWidget> createState() => _PrestigeBadgeWidgetState();
}

class _PrestigeBadgeWidgetState extends State<PrestigeBadgeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmer;
  late Animation<double> _shimmerAnim;
  late UpgradeController _upgradeCtrl;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _shimmerAnim = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmer, curve: Curves.easeInOut),
    );
    _upgradeCtrl = Get.find<UpgradeController>();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  String _romanNumeral(int level) {
    const numerals = ['I', 'II', 'III', 'IV', 'V'];
    if (level < 1 || level > 5) return '';
    return numerals[level - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final level = _upgradeCtrl.prestigeLevel.value;
      if (level == 0) return const SizedBox.shrink();

      final double badgeH = widget.compact ? 28 : 36;
      final double crownSize = widget.compact ? 14 : 18;
      final double titleSize = widget.compact ? 7 : 8;
      final double levelSize = widget.compact ? 11 : 13;
      final double hPad = widget.compact ? 8 : 12;
      final double vPad = widget.compact ? 4 : 6;

      return AnimatedBuilder(
        animation: _shimmerAnim,
        builder: (context, child) {
          return Container(
            height: badgeH,
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF1c1000),
                  Color(0xFF2a1a00),
                  Color(0xFF1c1000),
                ],
              ),
              borderRadius: BorderRadius.circular(widget.compact ? 10 : 14),
              border: Border.all(
                color: const Color(0xFFFBBF24).withAlpha(128),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFBBF24).withAlpha(51),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Shimmer overlay
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(widget.compact ? 10 : 14),
                    child: Transform.translate(
                      offset: Offset(_shimmerAnim.value * 80, 0),
                      child: Container(
                        width: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              const Color(0xFFFBBF24).withAlpha(20),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // İçerik
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '👑',
                      style: TextStyle(fontSize: crownSize),
                    ),
                    const SizedBox(width: 5),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PRESTIGE',
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: titleSize,
                            letterSpacing: 1.5,
                            color: const Color(0xFFFBBF24).withAlpha(153),
                            height: 1.0,
                          ),
                        ),
                        Text(
                          'LV. ${_romanNumeral(level)}',
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: levelSize,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: const Color(0xFFFBBF24),
                            height: 1.0,
                            shadows: [
                              Shadow(
                                color: const Color(0xFFFBBF24).withAlpha(153),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    });
  }
}
