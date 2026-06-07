import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/prestige_controller.dart';
import '../../../controllers/upgrade_controller.dart';
import '../../../core/utils/sound_service.dart';
import '../../../models/upgrade_config.dart';

/// Prestige onay modal'ını gösterir.
void showPrestigeModal(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Prestige',
    barrierColor: Colors.black.withAlpha(204),
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (_, a, b) => const _PrestigeModalContent(),
    transitionBuilder: (context, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(curved),
        child: FadeTransition(opacity: anim, child: child),
      );
    },
  );
}

class _PrestigeModalContent extends StatelessWidget {
  const _PrestigeModalContent();

  String _roman(int n) {
    const r = ['I', 'II', 'III', 'IV', 'V'];
    if (n < 1) return '';
    if (n > 5) return 'V';  // cap at max
    return r[n - 1];
  }

  /// Builds the level subtitle. When currentLevel == 0 (first prestige ever),
  /// there is no meaningful "from" level, so we show "İLK PRESTİGE".
  /// Otherwise we show the roman numeral transition, e.g. "LV. II → LV. III".
  String _levelSubtitle(int currentLevel, int nextLevel) {
    if (currentLevel == 0) {
      return 'label_prestige_first'.trParams({'level': _roman(nextLevel)});
    }
    return 'label_prestige_level_change'.trParams({'from': _roman(currentLevel), 'to': _roman(nextLevel)});
  }

  @override
  Widget build(BuildContext context) {
    final prestige = Get.find<PrestigeController>();
    final upgrade = Get.find<UpgradeController>();
    final currentLevel = prestige.currentLevel;
    final nextLevel = currentLevel + 1;
    final nextMultiplierPct = ((prestige.nextMultiplier - 1.0) * 100).round();

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F23),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFBBF24).withAlpha(102),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFBBF24).withAlpha(38),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Başlık
              const Text('👑', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text(
                'label_prestige'.tr,
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  color: const Color(0xFFFBBF24),
                  shadows: [
                    Shadow(
                      color: const Color(0xFFFBBF24).withAlpha(179),
                      blurRadius: 16,
                    ),
                  ],
                ),
              ),
              Text(
                _levelSubtitle(currentLevel, nextLevel),
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 11,
                  letterSpacing: 2,
                  color: const Color(0xFFFBBF24).withAlpha(153),
                ),
              ),
              const SizedBox(height: 24),

              // Kaybedilecekler
              _SectionCard(
                icon: '⚠️',
                title: 'section_prestige_lose'.tr,
                titleColor: const Color(0xFFEF4444),
                borderColor: const Color(0xFFEF4444).withAlpha(77),
                items: [
                  '${upgrade.gems.value} 💎 gem',
                  ...UpgradeCatalog.all.map((d) =>
                      '${d.name}: LV.${upgrade.levelOf(d.key)} → LV.0'),
                ],
                itemColor: const Color(0xFFFCA5A5),
              ),
              const SizedBox(height: 12),

              // Kazanılacaklar
              _SectionCard(
                icon: '✨',
                title: 'section_prestige_gain'.tr,
                titleColor: const Color(0xFF22C55E),
                borderColor: const Color(0xFF22C55E).withAlpha(77),
                items: [
                  'label_prestige_gem_bonus'.trParams({'pct': '$nextMultiplierPct'}),
                  'label_prestige_badge'.trParams({'level': _roman(nextLevel)}),
                ],
                itemColor: const Color(0xFF86EFAC),
              ),
              const SizedBox(height: 24),

              // Butonlar
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: Colors.white.withAlpha(51),
                          ),
                        ),
                      ),
                      child: Text(
                        'btn_cancel'.tr,
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 12,
                          letterSpacing: 2,
                          color: Colors.white.withAlpha(128),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await prestige.executePrestige();
                        // Prestige sesi
                        if (Get.isRegistered<SoundService>()) {
                          Get.find<SoundService>().playLevelUp();
                        }
                        // Kutlama animasyonu — Get.overlayContext dialog
                        // kapandıktan sonra da geçerli kalır.
                        if (Get.overlayContext != null) {
                          _showPrestigeCelebration(
                            Get.overlayContext!,
                            level: nextLevel,
                            multiplierPct: nextMultiplierPct,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFBBF24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'btn_confirm'.tr,
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Kutlama Animasyonu ────────────────────────────────────────────────────

void _showPrestigeCelebration(
  BuildContext context, {
  required int level,
  required int multiplierPct,
}) {
  final String roman = const ['I', 'II', 'III', 'IV', 'V'][level.clamp(1, 5) - 1];
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'PrestigeCelebration',
    barrierColor: Colors.black.withAlpha(217),
    transitionDuration: const Duration(milliseconds: 600),
    pageBuilder: (_, a, b) => _PrestigeCelebrationOverlay(
      roman: roman,
      multiplierPct: multiplierPct,
    ),
    transitionBuilder: (context, anim, _, child) {
      return FadeTransition(opacity: anim, child: child);
    },
  );
}

class _PrestigeCelebrationOverlay extends StatefulWidget {
  final String roman;
  final int multiplierPct;
  const _PrestigeCelebrationOverlay({
    required this.roman,
    required this.multiplierPct,
  });

  @override
  State<_PrestigeCelebrationOverlay> createState() =>
      _PrestigeCelebrationOverlayState();
}

class _PrestigeCelebrationOverlayState
    extends State<_PrestigeCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _crownScale;
  late Animation<double> _crownFade;
  late Animation<double> _textSlide;
  late Animation<double> _textFade;
  late Animation<double> _glowPulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _crownScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _crownFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _textSlide = Tween(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _textFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.3, 0.65, curve: Curves.easeIn),
      ),
    );

    _glowPulse = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.6), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
    ));

    _ctrl.forward();

    // 2.5 saniye sonra otomatik kapat
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 👑 Taç — scale + fade giriş
                  FadeTransition(
                    opacity: _crownFade,
                    child: ScaleTransition(
                      scale: _crownScale,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFBBF24)
                                  .withAlpha((180 * _glowPulse.value).round()),
                              blurRadius: 60,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                        child: const Text(
                          '👑',
                          style: TextStyle(fontSize: 80),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // PRESTIGE yazısı — aşağıdan yukarı + fade
                  Transform.translate(
                    offset: Offset(0, _textSlide.value),
                    child: Opacity(
                      opacity: _textFade.value,
                      child: Column(
                        children: [
                          Text(
                            'label_prestige'.tr,
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 6,
                              color: const Color(0xFFFBBF24),
                              shadows: [
                                Shadow(
                                  color: const Color(0xFFFBBF24).withAlpha(
                                      (200 * _glowPulse.value).round()),
                                  blurRadius: 30,
                                ),
                                Shadow(
                                  color: const Color(0xFFFBBF24).withAlpha(
                                      (120 * _glowPulse.value).round()),
                                  blurRadius: 60,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'LV. ${widget.roman}',
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 4,
                              color: const Color(0xFFFBBF24).withAlpha(200),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'label_prestige_gem_bonus'.trParams({'pct': '${widget.multiplierPct}'}),
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 11,
                              letterSpacing: 2,
                              color: const Color(0xFF22C55E).withAlpha(220),
                              shadows: [
                                Shadow(
                                  color: const Color(0xFF22C55E).withAlpha(150),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'label_continue_tap'.tr,
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 9,
                              letterSpacing: 2,
                              color: Colors.white.withAlpha(80),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Section Card ─────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String icon;
  final String title;
  final Color titleColor;
  final Color borderColor;
  final List<String> items;
  final Color itemColor;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.titleColor,
    required this.borderColor,
    required this.items,
    required this.itemColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: titleColor.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: titleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                '• $item',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 10,
                  color: itemColor,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
