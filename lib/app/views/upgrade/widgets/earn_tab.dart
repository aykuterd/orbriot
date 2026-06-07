import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../controllers/power_up_inventory_controller.dart';
import '../../../controllers/upgrade_controller.dart';
import '../../../core/utils/ad_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'mega_pack_card.dart';
import 'shop_widgets.dart';

class EarnTab extends StatelessWidget {
  const EarnTab({super.key});

  @override
  Widget build(BuildContext context) {
    final adService = Get.find<AdService>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const _DailyChargeCard(),
        const SizedBox(height: 12),
        Obx(() => adService.isAdFree.value
            ? const SizedBox.shrink()
            : const _AdRewardCard()),
        const SizedBox(height: 16),
        SectionHeader(title: 'section_pack'.tr),
        const SizedBox(height: 12),
        const MegaPackCard(),
      ],
    );
  }
}

// ── Günlük Bedava Şarj ────────────────────────────────────────────────────

class _DailyChargeCard extends StatefulWidget {
  const _DailyChargeCard();

  @override
  State<_DailyChargeCard> createState() => _DailyChargeCardState();
}

class _DailyChargeCardState extends State<_DailyChargeCard> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _updateRemaining());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    _remaining = tomorrow.difference(now);
  }

  String get _countdownText {
    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final inventory = Get.find<PowerUpInventoryController>();
    const color = AppColors.success;

    return Obx(() {
      final claimed = inventory.dailyClaimed.value;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(60), width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withAlpha(15), blurRadius: 16, spreadRadius: 1),
          ],
        ),
        child: Row(
          children: [
            // İkon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withAlpha(80)),
              ),
              child: const Icon(Icons.card_giftcard_rounded,
                  color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'label_daily_charge'.tr,
                    style: AppTextStyles.headlineMedium.copyWith(
                      fontSize: 12,
                      color: AppColors.foreground,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'subtitle_daily_charge'.tr,
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                  ),
                  const SizedBox(height: 10),
                  if (claimed) ...[
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: color, size: 14),
                        const SizedBox(width: 5),
                        Text(
                          'label_claimed_today'.tr,
                          style: AppTextStyles.hudLabel.copyWith(
                            color: color,
                            fontSize: 10,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _countdownText,
                          style: AppTextStyles.hudValue.copyWith(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    GestureDetector(
                      onTap: () async {
                        HapticFeedback.mediumImpact();
                        await inventory.tryClaimDailyCharge();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: color.withAlpha(35),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color.withAlpha(160)),
                          boxShadow: [
                            BoxShadow(
                                color: color.withAlpha(40), blurRadius: 10),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.download_rounded,
                                color: color, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'btn_claim'.tr,
                              style: AppTextStyles.hudValue.copyWith(
                                fontSize: 12,
                                color: color,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ── Reklam İzle ───────────────────────────────────────────────────────────

class _AdRewardCard extends StatelessWidget {
  const _AdRewardCard();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<UpgradeController>();
    const color = AppColors.amber;

    return Obx(() {
      final remaining = ctrl.remainingAdRewards;
      final canClaim = remaining > 0;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withAlpha(canClaim ? 60 : 30),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
                color: color.withAlpha(canClaim ? 15 : 8),
                blurRadius: 16,
                spreadRadius: 1),
          ],
        ),
        child: Row(
          children: [
            // İkon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withAlpha(canClaim ? 25 : 12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withAlpha(canClaim ? 80 : 40)),
              ),
              child: Icon(Icons.play_circle_outline_rounded,
                  color: canClaim ? color : AppColors.muted, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'label_watch_ad_title'.tr,
                        style: AppTextStyles.headlineMedium.copyWith(
                          fontSize: 12,
                          color: canClaim
                              ? AppColors.foreground
                              : AppColors.muted,
                        ),
                      ),
                      const Spacer(),
                      // Kalan hak göstergesi (noktalar)
                      Row(
                        children: List.generate(5, (i) {
                          final filled = i < remaining;
                          return Padding(
                            padding: const EdgeInsets.only(left: 3),
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: filled
                                    ? color
                                    : color.withAlpha(35),
                                border: Border.all(
                                    color: color.withAlpha(
                                        filled ? 0 : 80)),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'subtitle_watch_ad'.tr,
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: canClaim
                        ? () async {
                            HapticFeedback.lightImpact();
                            final adService = Get.find<AdService>();
                            final adShown = await adService.showRewardedAd();
                            if (!adShown) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'snack_ad_failed_earn'.tr,
                                      style: AppTextStyles.bodySmall
                                          .copyWith(color: Colors.white),
                                    ),
                                    backgroundColor: AppColors.accent.withAlpha(220),
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                );
                              }
                              return;
                            }
                            final ok = await ctrl.claimAdReward();
                            if (ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'snack_gems_earned'.tr,
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
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: canClaim
                            ? color.withAlpha(35)
                            : Colors.white.withAlpha(8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: canClaim
                              ? color.withAlpha(160)
                              : Colors.white.withAlpha(25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow_rounded,
                              size: 14,
                              color: canClaim ? color : AppColors.muted),
                          const SizedBox(width: 6),
                          Text(
                            canClaim
                                ? 'label_watch_ad_title'.tr
                                : 'btn_exhausted'.tr,
                            style: AppTextStyles.hudValue.copyWith(
                              fontSize: 12,
                              color: canClaim ? color : AppColors.muted,
                              letterSpacing: 1.5,
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
