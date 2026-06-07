import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class AnimatedLogo extends StatefulWidget {
  const AnimatedLogo({super.key});

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) {
        final glow = _pulse.value;
        return Column(
          children: [
            // Ana logo
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight, AppColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                'ORBRIOT',
                style: AppTextStyles.displayLarge.copyWith(
                  shadows: [
                    Shadow(
                      color: AppColors.primary.withAlpha((glow * 200).round()),
                      blurRadius: 24 * glow,
                    ),
                    Shadow(
                      color: AppColors.primaryLight.withAlpha((glow * 140).round()),
                      blurRadius: 48 * glow,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Alt yazı
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 1,
                  color: AppColors.border,
                ),
                const SizedBox(width: 8),
                Text(
                  'BRICK  BLAST',
                  style: AppTextStyles.bodySmall.copyWith(
                    letterSpacing: 5,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 28,
                  height: 1,
                  color: AppColors.border,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
