import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/iap_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// IAP gem paketleri ve ad-free satın alma sekmesi.
class GemPackagesTab extends StatelessWidget {
  const GemPackagesTab({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<IAPService>()) {
      return const _UnavailableMessage();
    }
    return Obx(() {
      final iap = Get.find<IAPService>();
      if (!iap.isAvailable.value) return const _UnavailableMessage();
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _SectionLabel('pkg_section_gems'.tr),
          const SizedBox(height: 10),
          _GemPackCard(pack: GemPack.starter),
          const SizedBox(height: 10),
          _GemPackCard(pack: GemPack.value, isBestValue: true),
          const SizedBox(height: 10),
          _GemPackCard(pack: GemPack.mega),
          const SizedBox(height: 24),
          _SectionLabel('pkg_section_adfree'.tr),
          const SizedBox(height: 10),
          _AdFreeCard(),
        ],
      );
    });
  }
}

// ── Bölüm başlığı ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.hudLabel.copyWith(
        color: AppColors.muted,
        letterSpacing: 2.5,
        fontSize: 10,
      ),
    );
  }
}

// ── Gem paketi kartı ───────────────────────────────────────────────────────

class _GemPackCard extends StatelessWidget {
  const _GemPackCard({required this.pack, this.isBestValue = false});
  final GemPack pack;
  final bool isBestValue;

  Color get _accent {
    switch (pack) {
      case GemPack.starter: return AppColors.primary;
      case GemPack.value:   return const Color(0xFF06B6D4);
      case GemPack.mega:    return const Color(0xFFFBBF24);
      case GemPack.adFree:  return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final iap   = Get.find<IAPService>();
    final price = iap.priceOf(pack);
    final gems  = pack.gemReward;

    return Obx(() {
      final loading = iap.isPurchasing.value;
      return GestureDetector(
        onTap: loading ? null : () => iap.buyPack(pack),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _accent.withAlpha(15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _accent.withAlpha(isBestValue ? 160 : 80)),
            boxShadow: isBestValue
                ? [BoxShadow(color: _accent.withAlpha(30), blurRadius: 16)]
                : null,
          ),
          child: Row(
            children: [
              // Sol: ikon + gem sayısı
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _accent.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.diamond_rounded, color: _accent, size: 26),
              ),
              const SizedBox(width: 14),
              // Orta: bilgi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$gems 💎',
                          style: AppTextStyles.hudValue.copyWith(
                            color: AppColors.foreground,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (isBestValue) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _accent.withAlpha(40),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: _accent.withAlpha(120)),
                            ),
                            child: Text(
                              'badge_best_value'.tr,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 8,
                                color: _accent,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Sağ: fiyat butonu
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: loading ? _accent.withAlpha(60) : _accent.withAlpha(220),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: loading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.background,
                        ),
                      )
                    : Text(
                        price,
                        style: AppTextStyles.hudLabel.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
              ),
            ],
          ),
        ),
      );
    });
  }

  String get _subtitle {
    switch (pack) {
      case GemPack.starter: return 'pkg_starter_desc'.tr;
      case GemPack.value:   return 'pkg_value_desc'.tr;
      case GemPack.mega:    return 'pkg_mega_desc'.tr;
      case GemPack.adFree:  return 'pkg_adfree_desc'.tr;
    }
  }
}

// ── Ad-Free kartı ──────────────────────────────────────────────────────────

class _AdFreeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<IAPService>()) return const SizedBox.shrink();
    final iap = Get.find<IAPService>();

    return Obx(() {
      final loading = iap.isPurchasing.value;
      final price   = iap.priceOf(GemPack.adFree);

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withAlpha(12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withAlpha(80)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.block_rounded,
                  color: AppColors.success, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'pkg_adfree_title'.tr,
                    style: AppTextStyles.hudValue.copyWith(
                      color: AppColors.foreground,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'pkg_adfree_subtitle'.tr,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: loading ? null : () => iap.buyAdFree(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: loading
                      ? AppColors.success.withAlpha(60)
                      : AppColors.success.withAlpha(220),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        price,
                        style: AppTextStyles.hudLabel.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ── IAP kullanılamıyor ─────────────────────────────────────────────────────

class _UnavailableMessage extends StatelessWidget {
  const _UnavailableMessage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'pkg_unavailable'.tr,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted),
        ),
      ),
    );
  }
}
