import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/game_controller.dart';
import '../../controllers/power_up_inventory_controller.dart';
import '../../models/game_state.dart';
import '../../models/power_up_cell.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/game_canvas.dart';
import '../home/widgets/prestige_badge_widget.dart';

class GameView extends GetView<GameController> {
  const GameView({super.key});

  // HUD yüksekliği: içerik (56) + sahne ilerleme çubuğu (4)
  static const double _hudTotal = 60;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final canvasW = constraints.maxWidth;
            final canvasH = constraints.maxHeight - _hudTotal;
            final mode = Get.arguments is GameMode
                ? Get.arguments as GameMode
                : GameMode.classic;
            final shouldRestore = Get.parameters['restore'] == 'true';

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (controller.gameState.value == null) {
                if (shouldRestore) {
                  controller.restoreGame(canvasW, canvasH, mode).then((ok) {
                    if (!ok) controller.initGame(canvasW, canvasH, mode);
                  });
                } else {
                  controller.initGame(canvasW, canvasH, mode);
                }
              }
            });

            return Obx(() {
              final state = controller.gameState.value;
              final progress = controller.stageProgress.value;
              final currentMode = controller.gameMode.value;

              if (state == null) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              return Column(
                children: [
                  _NeonHudBar(
                    score: state.score,
                    stage: state.stage,
                    ballCount: state.ballCount,
                    stageProgress: progress,
                    gameMode: currentMode,
                    bricksDestroyed: controller.stageBricksDestroyed,
                    onPause: controller.pauseGame,
                  ),
                  const Expanded(child: GameCanvas()),
                ],
              );
            });
          },
        ),
      ),
    );
  }
}

// ── Neon HUD Çubuğu ──────────────────────────────────────────────────────────

class _NeonHudBar extends StatelessWidget {
  const _NeonHudBar({
    required this.score,
    required this.stage,
    required this.ballCount,
    required this.stageProgress,
    required this.gameMode,
    required this.bricksDestroyed,
    required this.onPause,
  });

  final int score;
  final int stage;
  final int ballCount;
  final double stageProgress;
  final GameMode gameMode;
  final int bricksDestroyed;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: AppColors.surface,
      child: Column(
        children: [
          // İçerik satırı
          SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _ScoreBlock(score: score),
                  const SizedBox(width: 8),
                  const PrestigeBadgeWidget(compact: true),
                  const Spacer(),
                  _StageBadge(
                    stage: stage,
                    gameMode: gameMode,
                    bricksDestroyed: bricksDestroyed,
                  ),
                  const Spacer(),
                  _BallCount(count: ballCount),
                  const SizedBox(width: 4),
                  // Cep envanteri butonu
                  const _InventoryButton(),
                  const SizedBox(width: 2),
                  // Duraklat butonu — 44pt dokunma hedefi
                  GestureDetector(
                    onTap: onPause,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: Icon(
                          Icons.pause_rounded,
                          color: AppColors.muted,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Sahne ilerleme çubuğu
          _StageProgressBar(progress: stageProgress),
        ],
      ),
    );
  }
}

// ── Cep Envanteri Butonu ──────────────────────────────────────────────────────

class _InventoryButton extends StatelessWidget {
  const _InventoryButton();

  @override
  Widget build(BuildContext context) {
    final gc = Get.find<GameController>();

    return Obx(() {
      final isOpen    = gc.inventoryOpen.value;
      final isAiming  = gc.gameState.value?.turnPhase == TurnPhase.aiming;

      // Toplam şarj sayısı — badge için
      int totalCharges = 0;
      if (Get.isRegistered<PowerUpInventoryController>()) {
        final inv = Get.find<PowerUpInventoryController>();
        for (final t in PowerUpType.values) {
          totalCharges += inv.chargesOf(t);
        }
      }

      final hasCharges  = totalCharges > 0;
      final activeColor = isOpen
          ? const Color(0xFF06B6D4)
          : hasCharges
              ? const Color(0xFF06B6D4).withAlpha(180)
              : AppColors.muted;

      return GestureDetector(
        onTap: isAiming ? gc.toggleInventory : null,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // İkon
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isOpen
                      ? const Color(0xFF06B6D4).withAlpha(25)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isOpen
                      ? Border.all(
                          color: const Color(0xFF06B6D4).withAlpha(120),
                          width: 1,
                        )
                      : null,
                ),
                child: Icon(
                  Icons.inventory_2_rounded,
                  color: activeColor,
                  size: 18,
                ),
              ),
              // Şarj badge — sağ üst köşe
              if (hasCharges)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF06B6D4),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF06B6D4).withAlpha(160),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

// ── Skor Bloğu ───────────────────────────────────────────────────────────────

class _ScoreBlock extends StatelessWidget {
  const _ScoreBlock({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('label_score'.tr, style: AppTextStyles.hudLabel),
        const SizedBox(height: 1),
        Text(
          score.toString().padLeft(7, '0'),
          style: GoogleFonts.jetBrainsMono(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryLight,
            letterSpacing: 2,
            shadows: [
              Shadow(
                color: AppColors.glowPrimary,
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Sahne Badge ───────────────────────────────────────────────────────────────

class _StageBadge extends StatelessWidget {
  const _StageBadge({
    required this.stage,
    required this.gameMode,
    required this.bricksDestroyed,
  });
  final int stage;
  final GameMode gameMode;
  final int bricksDestroyed;

  @override
  Widget build(BuildContext context) {
    final isEndless = gameMode == GameMode.endless;
    final target = GameController.classicTarget(stage);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: isEndless
            ? const Color(0xFFF43F5E).withAlpha(20)
            : AppColors.primary.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEndless
              ? const Color(0xFFF43F5E).withAlpha(140)
              : AppColors.primary.withAlpha(140),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isEndless
                ? const Color(0x99F43F5E)
                : AppColors.glowPrimary,
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isEndless ? 'label_endless_hud'.tr : 'label_level_hud'.tr,
            style: AppTextStyles.hudLabel.copyWith(
              color: isEndless
                  ? const Color(0xFFF43F5E).withAlpha(200)
                  : null,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                isEndless ? '∞' : '$stage',
                style: GoogleFonts.orbitron(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isEndless
                      ? const Color(0xFFF43F5E)
                      : AppColors.primaryLight,
                  letterSpacing: 1,
                  shadows: [
                    Shadow(
                      color: isEndless
                          ? const Color(0x99F43F5E)
                          : AppColors.glowPrimary,
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              // Klasik modda: ·23/35
              if (!isEndless) ...[
                const SizedBox(width: 4),
                Text(
                  '$bricksDestroyed/$target',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    color: AppColors.muted,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Top Sayısı ────────────────────────────────────────────────────────────────

class _BallCount extends StatelessWidget {
  const _BallCount({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('label_ball_count'.tr, style: AppTextStyles.hudLabel),
        const SizedBox(height: 1),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryLight,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.glowPrimary,
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            Text(
              'x$count',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryLight,
                letterSpacing: 1,
                shadows: [
                  Shadow(
                    color: AppColors.glowPrimary,
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Sahne İlerleme Çubuğu ────────────────────────────────────────────────────

class _StageProgressBar extends StatelessWidget {
  const _StageProgressBar({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: progress),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context2, value, child) => SizedBox(
        height: 4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // İz (boş kısım)
            Container(color: AppColors.border.withAlpha(50)),
            // Dolgu (neon gradient)
            FractionallySizedBox(
              widthFactor: value,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withAlpha(130),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
