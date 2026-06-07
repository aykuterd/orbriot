import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/daily_login_controller.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// Ana ekrandan veya otomatik olarak açılan günlük giriş paneli
void showDailyLoginPanel(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _DailyLoginSheet(),
  );
}

class _DailyLoginSheet extends GetView<DailyLoginController> {
  const _DailyLoginSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.glowPrimary,
            blurRadius: 32,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tutaç
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),

          // Başlık + seri ateşi
          Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_fire_department_rounded,
                      color: Color(0xFFF97316), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'title_daily_login'.tr,
                    style: AppTextStyles.hudLabel.copyWith(
                      color: AppColors.foreground,
                      fontSize: 15,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Gün rozeti  (Gün X / 7)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(60),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.primaryLight.withAlpha(120)),
                    ),
                    child: Text(
                      'label_login_day'.trParams({'day': controller.currentDay.value.toString()}),
                      style: const TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 11,
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              )),

          const SizedBox(height: 6),
          Text(
            'subtitle_daily_login'.tr,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
          ),

          const SizedBox(height: 22),

          // 7 günlük kart sırası
          Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  final day = i + 1;
                  return _DayCard(
                    day: day,
                    reward: DailyLoginController.rewards[i],
                    currentDay: controller.currentDay.value,
                    claimed: controller.claimedToday.value,
                  );
                }),
              )),

          const SizedBox(height: 24),

          // Claim butonu ya da "zaten alındı" mesajı
          Obx(() {
            if (controller.claimedToday.value) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'label_login_claimed'.tr,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.success),
                  ),
                ],
              );
            }

            final reward = controller.todayReward;
            final isDay7 = controller.currentDay.value == 7;

            return GestureDetector(
              onTap: () {
                controller.claimToday();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDay7
                        ? [
                            const Color(0xFFF59E0B),
                            const Color(0xFFEF4444),
                          ]
                        : [
                            AppColors.primary,
                            const Color(0xFF9333EA),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: isDay7
                          ? const Color(0x99F59E0B)
                          : AppColors.glowPrimary,
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isDay7
                          ? Icons.workspace_premium_rounded
                          : Icons.diamond_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isDay7
                          ? 'btn_claim_day7'.trParams({'reward': '$reward'})
                          : 'btn_claim_daily'.trParams({'reward': '$reward'}),
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Tek günlük kart ────────────────────────────────────────────────────────

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.reward,
    required this.currentDay,
    required this.claimed,
  });

  final int  day;
  final int  reward;
  final int  currentDay;
  final bool claimed;

  @override
  Widget build(BuildContext context) {
    final isPast   = day < currentDay;
    final isToday  = day == currentDay;
    final isDay7   = day == 7;

    // Renk sistemi
    Color borderColor;
    Color bgColor;
    Color textColor;
    Color gemColor;

    if (isPast) {
      borderColor = AppColors.success.withAlpha(120);
      bgColor     = AppColors.success.withAlpha(25);
      textColor   = AppColors.success.withAlpha(180);
      gemColor    = AppColors.success.withAlpha(180);
    } else if (isToday && claimed) {
      borderColor = AppColors.primary.withAlpha(200);
      bgColor     = AppColors.primary.withAlpha(40);
      textColor   = AppColors.primaryLight;
      gemColor    = AppColors.primaryLight;
    } else if (isToday) {
      borderColor = isDay7
          ? const Color(0xFFF59E0B)
          : AppColors.primaryLight;
      bgColor     = isDay7
          ? const Color(0x33F59E0B)
          : AppColors.primary.withAlpha(50);
      textColor   = isDay7
          ? const Color(0xFFF59E0B)
          : AppColors.primaryLight;
      gemColor    = textColor;
    } else {
      // Future
      borderColor = AppColors.border.withAlpha(80);
      bgColor     = AppColors.surfaceVariant.withAlpha(80);
      textColor   = AppColors.muted.withAlpha(120);
      gemColor    = AppColors.muted.withAlpha(120);
    }

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: borderColor,
            width: isToday ? 1.5 : 1,
          ),
          boxShadow: isToday && !claimed
              ? [
                  BoxShadow(
                    color: isDay7
                        ? const Color(0x66F59E0B)
                        : AppColors.glowPrimary,
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gün numarası veya checkmark
            if (isPast || (isToday && claimed))
              Icon(Icons.check_rounded, size: 14, color: textColor)
            else
              Text(
                isDay7 ? '★' : '$day',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: isDay7 ? 13 : 11,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            const SizedBox(height: 4),
            // Gem ikonu
            if (isDay7 && !isPast)
              Icon(Icons.workspace_premium_rounded, size: 13, color: gemColor)
            else
              Icon(Icons.diamond_rounded, size: 11, color: gemColor),
            const SizedBox(height: 2),
            // Gem miktarı
            FittedBox(
              child: Text(
                '+$reward',
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: gemColor,
                ),
              ),
            ),
            // "GÜN X" etiketi — sadece bugün
            if (isToday) ...[
              const SizedBox(height: 3),
              FittedBox(
                child: Text(
                  'label_today'.tr,
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
