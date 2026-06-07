import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

// ── Gem Chip ──────────────────────────────────────────────────────────────

class GemChip extends StatelessWidget {
  const GemChip({super.key, required this.gems});
  final int gems;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cyan.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cyan.withAlpha(120)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.diamond_rounded, color: AppColors.cyan, size: 14),
          const SizedBox(width: 5),
          Text(
            gems.toString(),
            style: AppTextStyles.hudValue.copyWith(
              fontSize: 14,
              color: AppColors.cyan,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title});
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

// ── Buy Button ────────────────────────────────────────────────────────────

class BuyButton extends StatelessWidget {
  const BuyButton({
    super.key,
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
                size: 12, color: canAfford ? color : AppColors.muted),
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

// ── Max Badge ─────────────────────────────────────────────────────────────

class MaxBadge extends StatelessWidget {
  const MaxBadge({super.key, required this.color});
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
