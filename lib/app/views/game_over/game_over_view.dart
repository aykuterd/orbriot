import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/game_controller.dart';
import '../../controllers/power_up_inventory_controller.dart';
import '../../controllers/upgrade_controller.dart';
import '../../core/utils/ad_service.dart';
import '../../core/utils/constants.dart';
import '../../models/power_up_cell.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../routes/app_routes.dart';
import '../home/widgets/neon_button.dart';
import '../home/widgets/neon_grid_painter.dart';
import 'first_purchase_modal.dart';

class GameOverView extends StatefulWidget {
  const GameOverView({super.key});

  @override
  State<GameOverView> createState() => _GameOverViewState();
}

class _GameOverViewState extends State<GameOverView>
    with TickerProviderStateMixin {
  late final AnimationController _bgCtrl;
  late final AnimationController _entryCtrl;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  late final int _score;
  late final int _stage;
  late final int _highScore;
  late final int _earnedGems;
  late final bool _isNewRecord;
  late final int _continuesLeft;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _score = args['score'] ?? 0;
    _stage = args['stage'] ?? 0;
    _highScore = args['high_score'] ?? 0;
    _earnedGems = args['earned_gems'] ?? 0;
    _continuesLeft = args['continues_left'] ?? 0;
    _isNewRecord = _score >= _highScore && _score > 0;

    // Arkaplan animasyonu
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    // Giriş animasyonu
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _fadeIn = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));

    // First-purchase offer kontrolü (IAP hazırsa göster)
    maybeShowFirstPurchaseOffer();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  void _navigateWithInterstitial(String route) {
    final adService = Get.find<AdService>();
    adService.incrementGameOver();
    if (adService.shouldShowInterstitial) {
      adService.showInterstitialAd().then((_) {
        Get.offAllNamed(route);
      });
    } else {
      Get.offAllNamed(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Arkaplan
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, child) => CustomPaint(
              painter: NeonGridPainter(_bgCtrl.value),
              size: Size.infinite,
            ),
          ),
          // İçerik
          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      _GameOverTitle(isNewRecord: _isNewRecord),
                      const Spacer(flex: 1),
                      _ResultCard(
                        score: _score,
                        stage: _stage,
                        highScore: _highScore,
                        earnedGems: _earnedGems,
                        isNewRecord: _isNewRecord,
                      ),
                      if (_continuesLeft > 0) ...[
                        const SizedBox(height: 16),
                        _ContinueButtons(continuesLeft: _continuesLeft),
                      ],
                      const SizedBox(height: 16),
                      _LastChanceButton(),
                      const Spacer(flex: 2),
                      NeonButton(
                        label: 'btn_play_again'.tr,
                        onTap: () => _navigateWithInterstitial(AppRoutes.game),
                        icon: Icons.replay_rounded,
                      ),
                      const SizedBox(height: 12),
                      NeonButton(
                        label: 'btn_main_menu'.tr,
                        onTap: () => _navigateWithInterstitial(AppRoutes.home),
                        outlined: true,
                        icon: Icons.home_outlined,
                      ),
                      const Spacer(flex: 1),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Başlık ────────────────────────────────────────────────────────────────

class _GameOverTitle extends StatefulWidget {
  const _GameOverTitle({required this.isNewRecord});
  final bool isNewRecord;

  @override
  State<_GameOverTitle> createState() => _GameOverTitleState();
}

class _GameOverTitleState extends State<_GameOverTitle>
    with TickerProviderStateMixin {
  late final AnimationController _glowCtrl;
  late final AnimationController _scaleCtrl;

  @override
  void initState() {
    super.initState();

    // Glow nabzı — yavaş, dramatik
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    // Ölçek nabzı — glow'dan biraz geride kalacak şekilde offset
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_glowCtrl, _scaleCtrl]),
      builder: (context, _) {
        final glow  = CurvedAnimation(parent: _glowCtrl,  curve: Curves.easeInOut).value;
        final scale = CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut).value;

        // Renk: accent → hafif beyazlaşan rose (peak'de)
        final titleColor = Color.lerp(
          AppColors.accent,
          const Color(0xFFFF6B84),
          glow * 0.4,
        )!;

        final titleStyle = AppTextStyles.displayLarge.copyWith(
          fontSize: 52,
          fontWeight: FontWeight.w900,
          letterSpacing: 8,
          color: titleColor,
          height: 1.1,
          shadows: [
            // Beyaz sıcak çekirdek
            Shadow(
              color: Colors.white.withAlpha((100 * glow).round()),
              blurRadius: 4,
            ),
            // Dar kırmızı neon halka
            Shadow(
              color: AppColors.accent.withAlpha((180 + (60 * glow).round())),
              blurRadius: 14 + 10 * glow,
            ),
            // Orta katman glow
            Shadow(
              color: AppColors.accent.withAlpha((80 + (40 * glow).round())),
              blurRadius: 32 + 16 * glow,
            ),
            // Uzak ambient — her zaman görünür
            Shadow(
              color: AppColors.accent.withAlpha(40),
              blurRadius: 60,
            ),
          ],
        );

        return Column(
          children: [
            Transform.scale(
              scale: 1.0 + scale * 0.025, // 1.000 → 1.025 arası nefes
              child: Column(
                children: [
                  Text('GAME', style: titleStyle),
                  Text('OVER', style: titleStyle),
                ],
              ),
            ),
            if (widget.isNewRecord) ...[
              const SizedBox(height: 16),
              _NewRecordBadge(glowValue: glow),
            ],
          ],
        );
      },
    );
  }
}

class _NewRecordBadge extends StatelessWidget {
  const _NewRecordBadge({required this.glowValue});
  final double glowValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.success.withAlpha(20),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.success.withAlpha((120 + (80 * glowValue).round())),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.glowSuccess.withAlpha((60 * glowValue).round()),
            blurRadius: 12 + 8 * glowValue,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.emoji_events_rounded,
            color: AppColors.success,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            'label_new_record'.tr,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.success,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sonuç Kartı ───────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.score,
    required this.stage,
    required this.highScore,
    required this.earnedGems,
    required this.isNewRecord,
  });

  final int score;
  final int stage;
  final int highScore;
  final int earnedGems;
  final bool isNewRecord;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNewRecord
              ? AppColors.success.withAlpha(120)
              : AppColors.border.withAlpha(120),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isNewRecord ? AppColors.success : AppColors.primary)
                .withAlpha(24),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          _StatRow(
            label: 'label_score'.tr,
            value: score.toString().padLeft(7, '0'),
            valueColor: AppColors.foreground,
            large: true,
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),
          _StatRow(label: 'label_level'.tr, value: stage.toString()),
          const SizedBox(height: 12),
          _StatRow(
            label: 'label_high_score'.tr,
            value: highScore.toString().padLeft(7, '0'),
            valueColor: AppColors.success,
          ),
          const SizedBox(height: 12),
          // Kazanılan gem satırı
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('label_earned_gems'.tr, style: AppTextStyles.hudLabel),
              Row(
                children: [
                  const Icon(Icons.diamond_rounded,
                      color: Color(0xFF06B6D4), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '+$earnedGems',
                    style: AppTextStyles.hudValue.copyWith(
                      color: const Color(0xFF06B6D4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.large = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.hudLabel),
        Text(
          value,
          style: large
              ? AppTextStyles.scoreDisplay.copyWith(
                  color: valueColor ?? AppColors.foreground,
                  fontSize: 28,
                )
              : AppTextStyles.hudValue.copyWith(
                  color: valueColor ?? AppColors.foreground,
                ),
        ),
      ],
    );
  }
}

// ── Continue Butonları ────────────────────────────────────────────────────

class _ContinueButtons extends StatefulWidget {
  const _ContinueButtons({required this.continuesLeft});
  final int continuesLeft;

  @override
  State<_ContinueButtons> createState() => _ContinueButtonsState();
}

class _ContinueButtonsState extends State<_ContinueButtons> {
  bool _adLoading = false;

  void _onGemTap() {
    final upgrades = Get.find<UpgradeController>();
    if (upgrades.gems.value < GameConstants.continueCostGems) {
      // Yeterli gem yok — shop'a yönlendir
      Get.toNamed(AppRoutes.upgrade);
      return;
    }
    upgrades.spendGems(GameConstants.continueCostGems).then((ok) {
      if (!ok) return;
      _doResume();
    });
  }

  Future<void> _onAdTap() async {
    if (_adLoading) return;
    setState(() => _adLoading = true);
    final adService = Get.find<AdService>();
    final success = await adService.showRewardedAd();
    if (!mounted) return;
    setState(() => _adLoading = false);
    if (success) {
      _doResume();
    } else {
      Get.snackbar(
        'snack_ad_failed_title'.tr,
        'snack_ad_failed_body'.tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF1A1A2E),
        colorText: const Color(0xFFE2E8F0),
        margin: const EdgeInsets.all(12),
      );
    }
  }

  void _doResume() {
    if (!Get.isRegistered<GameController>()) return;
    Get.find<GameController>().continueGame();
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 💎 Gem ile devam
        _ContinueButton(
          label: 'btn_continue'.tr,
          badge: '${GameConstants.continueCostGems}',
          badgeIcon: Icons.diamond_rounded,
          color: AppColors.cyan,
          glowColor: AppColors.glowCyan,
          onTap: _adLoading ? null : _onGemTap,
        ),
        // ▶ Reklam ile devam (ad-free ise gizlenir)
        Obx(() {
          final adService = Get.find<AdService>();
          if (adService.isAdFree.value) return const SizedBox.shrink();
          return Column(
            children: [
              const SizedBox(height: 10),
              _ContinueButton(
                label: _adLoading ? 'btn_loading'.tr : 'btn_watch_ad'.tr,
                badge: 'label_free'.tr,
                color: AppColors.amber,
                glowColor: AppColors.amber.withAlpha(100),
                outlined: true,
                loading: _adLoading,
                onTap: _adLoading ? null : _onAdTap,
              ),
            ],
          );
        }),
        const SizedBox(height: 6),
        Text(
          'label_continues_left'.trParams({'count': widget.continuesLeft.toString(), 'max': GameConstants.maxContinues.toString()}),
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _ContinueButton extends StatefulWidget {
  const _ContinueButton({
    required this.label,
    required this.badge,
    required this.color,
    required this.glowColor,
    this.badgeIcon,
    this.outlined = false,
    this.loading = false,
    this.onTap,
  });

  final String label;
  final String badge;
  final Color color;
  final Color glowColor;
  final IconData? badgeIcon;
  final bool outlined;
  final bool loading;
  final VoidCallback? onTap;

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _down(_) => _ctrl.forward();
  void _up(_) { _ctrl.reverse(); widget.onTap?.call(); }
  void _cancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;

    return GestureDetector(
      onTapDown: disabled ? null : _down,
      onTapUp: disabled ? null : _up,
      onTapCancel: disabled ? null : _cancel,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: widget.outlined
                ? widget.color.withAlpha(20)
                : disabled
                    ? widget.color.withAlpha(60)
                    : widget.color.withAlpha(220),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: disabled
                  ? widget.color.withAlpha(40)
                  : widget.color.withAlpha(widget.outlined ? 160 : 80),
              width: widget.outlined ? 1.5 : 1,
            ),
            boxShadow: disabled || widget.outlined
                ? null
                : [
                    BoxShadow(
                      color: widget.glowColor,
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.loading) ...[
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.color,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: AppTextStyles.button.copyWith(
                  fontSize: 13,
                  color: widget.outlined
                      ? widget.color
                      : disabled
                          ? AppColors.muted
                          : AppColors.background,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: widget.outlined
                      ? widget.color.withAlpha(30)
                      : AppColors.background.withAlpha(50),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.badgeIcon != null) ...[
                      Icon(
                        widget.badgeIcon,
                        size: 11,
                        color: widget.outlined ? widget.color : AppColors.background,
                      ),
                      const SizedBox(width: 3),
                    ],
                    Text(
                      widget.badge,
                      style: AppTextStyles.hudLabel.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: widget.outlined ? widget.color : AppColors.background,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Son Şans Butonu ───────────────────────────────────────────────────────────

class _LastChanceButton extends StatelessWidget {
  static const int _cost = 10;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<PowerUpInventoryController>()) {
      return const SizedBox.shrink();
    }
    return Obx(() {
      final upgrades = Get.find<UpgradeController>();
      final canAfford = upgrades.gems.value >= _cost;
      return GestureDetector(
        onTap: canAfford ? _onTap : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: canAfford
                ? const Color(0xFF8B5CF6).withAlpha(20)
                : AppColors.border.withAlpha(15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: canAfford
                  ? const Color(0xFF8B5CF6).withAlpha(100)
                  : AppColors.border.withAlpha(40),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '💥 ${'label_last_chance'.tr}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: canAfford ? const Color(0xFFA78BFA) : AppColors.muted,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
              Icon(
                Icons.diamond_rounded,
                size: 12,
                color: canAfford ? AppColors.cyan : AppColors.muted,
              ),
              const SizedBox(width: 3),
              Text(
                'label_last_chance_action'.trParams({'cost': '$_cost'}),
                style: AppTextStyles.bodySmall.copyWith(
                  color: canAfford ? const Color(0xFFA78BFA) : AppColors.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _onTap() {
    final upgrades = Get.find<UpgradeController>();
    final inventory = Get.find<PowerUpInventoryController>();
    upgrades.spendGems(_cost).then((ok) {
      if (!ok) return;
      inventory.addCharges(PowerUpType.nuke, 1);
      Get.snackbar(
        'snack_last_chance_title'.tr,
        'snack_last_chance_body'.tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF1A1A2E),
        colorText: const Color(0xFFA78BFA),
        margin: const EdgeInsets.all(12),
      );
    });
  }
}
