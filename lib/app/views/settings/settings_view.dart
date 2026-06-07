import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/settings_controller.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../home/widgets/neon_grid_painter.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bgCtrl;
  int _devTapCount = 0;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<SettingsController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Neon grid arkaplan
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, _) => CustomPaint(
              painter: NeonGridPainter(_bgCtrl.value),
              size: Size.infinite,
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Üst bar ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_rounded,
                            color: AppColors.foreground, size: 20),
                        onPressed: Get.back,
                      ),
                      Expanded(
                        child: Text(
                          'title_settings'.tr,
                          style: AppTextStyles.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // denge için
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── İçerik ────────────────────────────────────────────────
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      // ── Ses Bölümü ────────────────────────────────────
                      _SectionHeader(
                        icon: Icons.volume_up_rounded,
                        title: 'section_sound'.tr,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 10),
                      _SettingsCard(
                        color: AppColors.primary,
                        children: [
                          // SFX Toggle
                          Obx(() => _ToggleRow(
                                icon: Icons.music_note_rounded,
                                title: 'label_sfx'.tr,
                                subtitle: 'subtitle_sfx'.tr,
                                value: ctrl.sfxEnabled.value,
                                color: AppColors.primary,
                                onTap: ctrl.toggleSfx,
                              )),
                          _divider(),
                          // SFX Volume
                          Obx(() => _SliderRow(
                                icon: Icons.tune_rounded,
                                title: 'label_sfx_volume'.tr,
                                value: ctrl.sfxVolume.value,
                                color: AppColors.primary,
                                enabled: ctrl.sfxEnabled.value,
                                onChanged: ctrl.updateSfxVolume,
                              )),
                          _divider(),
                          // BGM Toggle
                          Obx(() => _ToggleRow(
                                icon: Icons.queue_music_rounded,
                                title: 'label_music'.tr,
                                subtitle: 'subtitle_music'.tr,
                                value: ctrl.bgmEnabled.value,
                                color: const Color(0xFF06B6D4),
                                onTap: ctrl.toggleBgm,
                              )),
                          _divider(),
                          // BGM Volume
                          Obx(() => _SliderRow(
                                icon: Icons.graphic_eq_rounded,
                                title: 'label_music_volume'.tr,
                                value: ctrl.bgmVolume.value,
                                color: const Color(0xFF06B6D4),
                                enabled: ctrl.bgmEnabled.value,
                                onChanged: ctrl.updateBgmVolume,
                              )),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Oynanabilirlik Bölümü ─────────────────────────
                      _SectionHeader(
                        icon: Icons.gamepad_rounded,
                        title: 'section_gameplay'.tr,
                        color: AppColors.success,
                      ),
                      const SizedBox(height: 10),
                      _SettingsCard(
                        color: AppColors.success,
                        children: [
                          Obx(() => _ToggleRow(
                                icon: Icons.vibration_rounded,
                                title: 'label_haptic'.tr,
                                subtitle: 'subtitle_haptic'.tr,
                                value: ctrl.hapticEnabled.value,
                                color: AppColors.success,
                                onTap: ctrl.toggleHaptic,
                              )),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Hakkında Bölümü ───────────────────────────────
                      _SectionHeader(
                        icon: Icons.info_outline_rounded,
                        title: 'section_about'.tr,
                        color: AppColors.muted,
                      ),
                      const SizedBox(height: 10),
                      _SettingsCard(
                        color: AppColors.muted,
                        children: [
                          _InfoRow(
                            icon: Icons.sports_esports_rounded,
                            title: 'ORBRIOT',
                            value: 'BRICK BLAST',
                            color: AppColors.primaryLight,
                          ),
                          _divider(),
                          GestureDetector(
                            onTap: () {
                              _devTapCount++;
                              if (_devTapCount >= 5) {
                                _devTapCount = 0;
                                Get.toNamed(AppRoutes.screenshotHelper);
                              }
                            },
                            child: _InfoRow(
                              icon: Icons.tag_rounded,
                              title: 'label_version'.tr,
                              value: 'v1.0.0',
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Veri Bölümü ───────────────────────────────────
                      _SectionHeader(
                        icon: Icons.storage_rounded,
                        title: 'section_data'.tr,
                        color: AppColors.accent,
                      ),
                      const SizedBox(height: 10),
                      _SettingsCard(
                        color: AppColors.accent,
                        children: [
                          _DangerRow(
                            icon: Icons.restart_alt_rounded,
                            title: 'btn_reset_progress'.tr,
                            subtitle: 'subtitle_reset_progress'.tr,
                            color: AppColors.accent,
                            onTap: () => _showResetDialog(context, ctrl),
                          ),
                        ],
                      ),

                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Divider(
          color: AppColors.borderLight,
          height: 1,
        ),
      );

  void _showResetDialog(BuildContext context, SettingsController ctrl) {
    showDialog(
      context: context,
      builder: (_) => _ResetDialog(
        onConfirm: () async {
          await ctrl.resetProgress();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'snack_progress_reset'.tr,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.foreground),
                ),
                backgroundColor: AppColors.surface,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            );
          }
        },
      ),
    );
  }
}

// ── Bölüm başlığı ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });
  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.hudLabel.copyWith(
            color: color,
            fontSize: 11,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withAlpha(80), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Kart container ─────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.color, required this.children});
  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(40), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(15),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: children,
        ),
      ),
    );
  }
}

// ── Toggle satırı ──────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // İkon
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: (value ? color : AppColors.muted).withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (value ? color : AppColors.muted).withAlpha(60),
                  ),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: value ? color : AppColors.muted,
                ),
              ),
              const SizedBox(width: 14),
              // Metin
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: value ? AppColors.foreground : AppColors.muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style:
                          AppTextStyles.bodySmall.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Neon toggle
              _NeonToggle(value: value, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Slider satırı ──────────────────────────────────────────────────────────

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.enabled,
    required this.onChanged,
  });
  final IconData icon;
  final String title;
  final double value;
  final Color color;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final activeColor = enabled ? color : AppColors.muted;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: activeColor),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppTextStyles.bodySmall.copyWith(
                  color: enabled ? AppColors.foreground : AppColors.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Text(
                '${(value * 100).round()}%',
                style: AppTextStyles.hudLabel.copyWith(
                  color: activeColor,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: activeColor,
              inactiveTrackColor: AppColors.surfaceVariant,
              thumbColor: activeColor,
              overlayColor: activeColor.withAlpha(30),
            ),
            child: Slider(
              value: value,
              onChanged: enabled ? onChanged : null,
              min: 0.0,
              max: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bilgi satırı ───────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withAlpha(40)),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 14),
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.foreground,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.hudLabel.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

// ── Tehlikeli işlem satırı ─────────────────────────────────────────────────

class _DangerRow extends StatelessWidget {
  const _DangerRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withAlpha(80)),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: color.withAlpha(160), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Neon Toggle widget ─────────────────────────────────────────────────────

class _NeonToggle extends StatelessWidget {
  const _NeonToggle({required this.value, required this.color});
  final bool value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: 46,
      height: 26,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        color: value ? color.withAlpha(35) : AppColors.surfaceVariant,
        border: Border.all(
          color: value ? color.withAlpha(200) : AppColors.borderLight,
          width: 1.2,
        ),
        boxShadow: value
            ? [
                BoxShadow(
                  color: color.withAlpha(80),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ]
            : [],
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            left: value ? 22 : 2,
            top: 2,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? color : AppColors.muted.withAlpha(120),
                boxShadow: value
                    ? [
                        BoxShadow(
                          color: color.withAlpha(160),
                          blurRadius: 8,
                        )
                      ]
                    : [],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reset dialog ───────────────────────────────────────────────────────────

class _ResetDialog extends StatelessWidget {
  const _ResetDialog({required this.onConfirm});
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.accent.withAlpha(120), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(20),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent.withAlpha(120)),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: AppColors.accent, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              'dialog_reset_title'.tr,
              style: AppTextStyles.headlineMedium.copyWith(
                fontSize: 16,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'dialog_reset_body'.tr,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 12,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: Get.back,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.borderLight),
                      ),
                      child: Text(
                        'btn_cancel'.tr,
                        style: AppTextStyles.button.copyWith(
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Get.back();
                      onConfirm();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.accent.withAlpha(180)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withAlpha(40),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Text(
                        'btn_reset'.tr,
                        style: AppTextStyles.button.copyWith(
                          fontSize: 13,
                          color: AppColors.accent,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
