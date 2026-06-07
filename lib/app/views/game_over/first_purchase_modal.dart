import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/iap_service.dart';
import '../../core/utils/session_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Session 3–5'te ilk game over'da gösterilen indirimli teklif.
/// VALUE PACK'i %50 indirimli sunar.
class FirstPurchaseModal extends StatefulWidget {
  const FirstPurchaseModal({super.key});

  @override
  State<FirstPurchaseModal> createState() => _FirstPurchaseModalState();
}

class _FirstPurchaseModalState extends State<FirstPurchaseModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow;
  late final IAPService _iap;
  late final SessionService _session;

  static const _targetPack = GemPack.value;

  @override
  void initState() {
    super.initState();
    _iap     = Get.find<IAPService>();
    _session = Get.find<SessionService>();

    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  Future<void> _onBuy() async {
    await _session.markFirstPurchaseShown();
    final ok = await _iap.buyPack(_targetPack);
    if (!mounted) return;
    if (ok) {
      Get.back();
    } else {
      Get.snackbar(
        'snack_purchase_failed_title'.tr,
        'snack_purchase_failed_body'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1A1A2E),
        colorText: AppColors.accent,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _onDismiss() async {
    await _session.markFirstPurchaseShown();
    if (!mounted) return;
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final fullPrice = _iap.priceOf(_targetPack);
    final halfPrice = _iap.priceOf(_targetPack, half: true);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: AnimatedBuilder(
        animation: _glow,
        builder: (_, child) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFBBF24).withAlpha(
                (120 + 80 * _glow.value).round(),
              ),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFBBF24).withAlpha(
                  (40 + 40 * _glow.value).round(),
                ),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          child: child,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24).withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFBBF24).withAlpha(160),
                  ),
                ),
                child: Text(
                  'fp_badge'.tr,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: const Color(0xFFFBBF24),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Başlık
              Text(
                'fp_title'.tr,
                textAlign: TextAlign.center,
                style: AppTextStyles.displayLarge.copyWith(
                  fontSize: 22,
                  color: AppColors.foreground,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'fp_subtitle'.tr,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.muted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
              // Paket içeriği
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF7C3AED).withAlpha(80),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.diamond_rounded,
                          color: Color(0xFF06B6D4),
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '600',
                          style: AppTextStyles.scoreDisplay.copyWith(
                            fontSize: 36,
                            color: const Color(0xFF06B6D4),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'fp_gems'.tr,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          fullPrice,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.muted,
                            fontSize: 13,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.success.withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: AppColors.success.withAlpha(120)),
                          ),
                          child: Text(
                            '%50 OFF',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          halfPrice,
                          style: AppTextStyles.scoreDisplay.copyWith(
                            fontSize: 22,
                            color: const Color(0xFFFBBF24),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Satın al butonu
              Obx(() {
                final loading = _iap.isPurchasing.value;
                return GestureDetector(
                  onTap: loading ? null : _onBuy,
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBF24).withAlpha(220),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFBBF24).withAlpha(80),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : Text(
                              'fp_buy'.trParams({'price': halfPrice}),
                              style: AppTextStyles.button.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 10),
              // Geç butonu
              GestureDetector(
                onTap: _onDismiss,
                child: Text(
                  'fp_dismiss'.tr,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.muted,
                    fontSize: 11,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// [GameOverView]'da çağrılır. Uygunsa modal gösterir.
void maybeShowFirstPurchaseOffer() {
  if (!Get.isRegistered<SessionService>()) return;
  if (!Get.isRegistered<IAPService>()) return;

  final session = Get.find<SessionService>();
  final iap     = Get.find<IAPService>();

  if (!session.shouldShowFirstPurchaseOffer) return;
  if (!iap.isAvailable.value) return;

  // Delay: score animasyonu bittikten sonra göster
  Future.delayed(const Duration(milliseconds: 1200), () {
    if (Get.context != null) {
      showDialog(
        context: Get.context!,
        barrierDismissible: false,
        barrierColor: Colors.black.withAlpha(160),
        builder: (_) => const FirstPurchaseModal(),
      );
    }
  });
}
