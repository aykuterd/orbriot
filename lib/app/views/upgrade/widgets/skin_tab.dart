import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/skin_controller.dart';
import '../../../controllers/upgrade_controller.dart';
import '../../../models/skin.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class SkinTab extends StatelessWidget {
  const SkinTab({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<SkinController>();

    return Obx(() {
      final activeSkin  = ctrl.activeSkin;
      final preview     = ctrl.previewSkin.value;
      final isPreview   = preview != null;
      final displaySkin = isPreview ? preview : activeSkin;

      return Column(
        children: [
          // ── Featured Area ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: isPreview
                  ? _FeaturedPreview(
                      key: ValueKey('preview_${displaySkin.id}'),
                      skin: displaySkin,
                      ctrl: ctrl,
                    )
                  : _FeaturedActive(
                      key: ValueKey('active_${displaySkin.id}'),
                      skin: displaySkin,
                    ),
            ),
          ),

          // ── Divider ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(child: Divider(color: AppColors.border.withAlpha(80), thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'label_all_skins'.tr,
                    style: AppTextStyles.hudLabel.copyWith(
                      color: AppColors.muted,
                      letterSpacing: 2,
                      fontSize: 9,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: AppColors.border.withAlpha(80), thickness: 1)),
              ],
            ),
          ),

          // ── Grid ──────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.85,
                ),
                itemCount: SkinCatalog.all.length,
                itemBuilder: (context, i) {
                  final skin = SkinCatalog.all[i];
                  final unlocked = ctrl.isUnlocked(skin.id);
                  final isActive  = activeSkin.id == skin.id;
                  final isPreviewed = preview?.id == skin.id;

                  return _SkinGridCell(
                    skin: skin,
                    unlocked: unlocked,
                    isActive: isActive,
                    isPreviewed: isPreviewed,
                    onTap: () {
                      if (unlocked) {
                        ctrl.selectSkin(skin.id);
                      } else {
                        ctrl.previewLockedSkin(skin);
                      }
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      );
    });
  }
}

// ── Featured: Aktif Skin ────────────────────────────────────────────────────

class _FeaturedActive extends StatelessWidget {
  const _FeaturedActive({super.key, required this.skin});
  final SkinDefinition skin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            skin.dark.withAlpha(120),
            skin.primary.withAlpha(60),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: skin.primary.withAlpha(180), width: 1.5),
        boxShadow: [
          BoxShadow(color: skin.primary.withAlpha(60), blurRadius: 16),
        ],
      ),
      child: Row(
        children: [
          _BallPreview(skin: skin, size: 52),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'label_active_skin'.tr,
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: skin.light,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  skin.name,
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.foreground,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.check_circle_rounded, size: 12, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      'label_selected'.tr,
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Featured: Önizleme + Satın Al ─────────────────────────────────────────

class _FeaturedPreview extends StatefulWidget {
  const _FeaturedPreview({
    super.key,
    required this.skin,
    required this.ctrl,
  });
  final SkinDefinition skin;
  final SkinController ctrl;

  @override
  State<_FeaturedPreview> createState() => _FeaturedPreviewState();
}

class _FeaturedPreviewState extends State<_FeaturedPreview> {
  bool _loading = false;

  Future<void> _onBuy() async {
    if (_loading) return;
    setState(() => _loading = true);
    final ok = await widget.ctrl.purchaseSkin(widget.skin.id);
    if (mounted) setState(() => _loading = false);
    if (!ok) {
      // Gem yetersiz — görsel feedback
      _showInsufficientGems();
    }
  }

  void _showInsufficientGems() {
    final gems = Get.find<UpgradeController>().gems.value;
    Get.snackbar(
      'snack_insufficient_gems'.tr,
      'snack_insufficient_gems_body'.trParams({'cost': '${widget.skin.cost}', 'current': '$gems'}),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surface,
      colorText: AppColors.foreground,
      margin: const EdgeInsets.all(12),
      borderRadius: 10,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final skin = widget.skin;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surface,
            skin.dark.withAlpha(80),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cyan.withAlpha(140), width: 1.5),
        boxShadow: [
          BoxShadow(color: AppColors.cyan.withAlpha(50), blurRadius: 14),
        ],
      ),
      child: Row(
        children: [
          _BallPreview(skin: skin, size: 52),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'label_preview'.tr,
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cyan,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  skin.name,
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.foreground,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Satın al butonu
                    Expanded(
                      child: _BuyButton(
                        cost: skin.cost,
                        loading: _loading,
                        onTap: _onBuy,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // İptal
                    GestureDetector(
                      onTap: widget.ctrl.clearPreview,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Grid Cell ───────────────────────────────────────────────────────────────

class _SkinGridCell extends StatefulWidget {
  const _SkinGridCell({
    required this.skin,
    required this.unlocked,
    required this.isActive,
    required this.isPreviewed,
    required this.onTap,
  });

  final SkinDefinition skin;
  final bool unlocked;
  final bool isActive;
  final bool isPreviewed;
  final VoidCallback onTap;

  @override
  State<_SkinGridCell> createState() => _SkinGridCellState();
}

class _SkinGridCellState extends State<_SkinGridCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  Color get _borderColor {
    if (widget.isPreviewed) return AppColors.cyan;
    if (widget.isActive)    return widget.skin.primary;
    return AppColors.border.withAlpha(60);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pressCtrl,
      builder: (_, child) => Transform.scale(
        scale: _scale.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: (_) => _pressCtrl.forward(),
        onTapUp:   (_) { _pressCtrl.reverse(); widget.onTap(); },
        onTapCancel: () => _pressCtrl.reverse(),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _borderColor, width: 1.5),
            boxShadow: widget.isActive || widget.isPreviewed
                ? [BoxShadow(
                    color: (widget.isPreviewed
                        ? AppColors.cyan
                        : widget.skin.primary).withAlpha(80),
                    blurRadius: 10,
                  )]
                : null,
          ),
          child: Stack(
            children: [
              // İçerik
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(
                      opacity: widget.unlocked ? 1.0 : 0.45,
                      child: _BallPreview(skin: widget.skin, size: 34),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.skin.name,
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                        color: widget.unlocked
                            ? AppColors.foreground
                            : AppColors.muted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (!widget.unlocked) ...[
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.diamond_rounded,
                              size: 8, color: AppColors.cyan),
                          const SizedBox(width: 2),
                          Text(
                            '${widget.skin.cost}',
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: AppColors.cyan,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Kilit ikonu (sağ üst)
              if (!widget.unlocked)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Icon(
                    widget.skin.cost >= 150
                        ? Icons.workspace_premium_rounded
                        : Icons.lock_rounded,
                    size: 9,
                    color: AppColors.muted,
                  ),
                ),
              // Aktif dot (sağ alt)
              if (widget.isActive)
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: widget.skin.primary,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(
                        color: widget.skin.primary,
                        blurRadius: 4,
                      )],
                    ),
                  ),
                ),
              // Önizleme dot (sağ alt — aktif değilken)
              if (widget.isPreviewed && !widget.isActive)
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.cyan,
                      shape: BoxShape.circle,
                      boxShadow: [const BoxShadow(
                        color: AppColors.cyan,
                        blurRadius: 4,
                      )],
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

// ── Top Önizleme (radial gradient top) ─────────────────────────────────────

class _BallPreview extends StatelessWidget {
  const _BallPreview({required this.skin, required this.size});
  final SkinDefinition skin;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.35),
          colors: [Colors.white, skin.light, skin.primary, skin.dark],
          stops: const [0.0, 0.35, 0.65, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: skin.primary.withAlpha(150),
            blurRadius: size * 0.4,
          ),
        ],
      ),
    );
  }
}

// ── Satın Al Butonu ─────────────────────────────────────────────────────────

class _BuyButton extends StatelessWidget {
  const _BuyButton({
    required this.cost,
    required this.loading,
    required this.onTap,
  });

  final int cost;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.cyan,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            const BoxShadow(color: AppColors.glowCyan, blurRadius: 10),
          ],
        ),
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.background,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.diamond_rounded,
                    size: 11,
                    color: AppColors.background,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'btn_buy_skin'.trParams({'cost': '$cost'}),
                    style: const TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: AppColors.background,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
