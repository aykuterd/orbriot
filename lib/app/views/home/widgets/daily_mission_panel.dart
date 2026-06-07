import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/daily_mission_controller.dart';
import '../../../models/daily_mission.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// Ana ekranda badge'e tıklanınca açılan bottom sheet
void showDailyMissionPanel(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _DailyMissionSheet(),
  );
}

class _DailyMissionSheet extends GetView<DailyMissionController> {
  const _DailyMissionSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
          const SizedBox(height: 16),
          Text('title_daily_missions'.tr, style: AppTextStyles.hudLabel),
          const SizedBox(height: 4),
          Text(
            'label_missions_refresh'.trParams({'date': _tomorrowMidnight()}),
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 20),
          Obx(() => Column(
            children: controller.missions
                .map((m) => _MissionCard(mission: m))
                .toList(),
          )),
        ],
      ),
    );
  }

  String _tomorrowMidnight() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return '${tomorrow.day}.${tomorrow.month.toString().padLeft(2, '0')}.${tomorrow.year}';
  }
}

class _MissionCard extends GetView<DailyMissionController> {
  const _MissionCard({required this.mission});
  final DailyMission mission;

  @override
  Widget build(BuildContext context) {
    final progress = (mission.progress / mission.target).clamp(0.0, 1.0);
    final done = mission.isCompleted;
    final claimed = mission.rewardClaimed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: done ? AppColors.primary.withAlpha(160) : AppColors.border,
          width: done ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  missionLabel(mission),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: claimed
                        ? AppColors.foreground.withAlpha(100)
                        : AppColors.foreground,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Ödül claim butonu veya gem göstergesi
              if (done && !claimed)
                GestureDetector(
                  onTap: () => controller.claimReward(mission),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.diamond_outlined, size: 13, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          '+${mission.reward}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.diamond_outlined,
                      size: 13,
                      color: AppColors.foreground.withAlpha(claimed ? 80 : 160),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${mission.reward}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.foreground.withAlpha(claimed ? 80 : 160),
                      ),
                    ),
                    if (claimed) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.check_circle, size: 15, color: AppColors.primary.withAlpha(180)),
                    ],
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          // İlerleme çubuğu
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.border.withAlpha(80),
              valueColor: AlwaysStoppedAnimation<Color>(
                claimed ? AppColors.primary.withAlpha(80) : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${mission.progress} / ${mission.target}',
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 11,
              color: AppColors.foreground.withAlpha(120),
            ),
          ),
        ],
      ),
    );
  }
}
