import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/game_controller.dart';
import '../../../controllers/power_up_controller.dart';
import '../../../controllers/skin_controller.dart';
import '../../../models/game_state.dart';
import '../../../theme/app_colors.dart';
import 'game_painter.dart';
import 'particle_painter.dart';
import 'power_up_bar.dart';

class GameCanvas extends GetView<GameController> {
  const GameCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) => controller.onDragStart(d.localPosition),
      onPanUpdate: (d) => controller.onDragUpdate(d.localPosition),
      onPanEnd: (_) => controller.onDragEnd(),
      child: Obx(() {
        final state = controller.gameState.value;
        final angle = controller.aimAngle.value;

        if (state == null) return const SizedBox.expand();

        final magnitude        = controller.aimDragMagnitude.value;
        final dangerFlash      = controller.dangerFlash.value;
        final brickShiftOffset = controller.brickShiftOffset.value;

        // Aktif skin renkleri
        final skinCtrl = Get.isRegistered<SkinController>()
            ? Get.find<SkinController>()
            : null;
        final skin = skinCtrl?.activeSkin;
        final stageText    = controller.stageTransitionText.value;
        final comboText    = controller.comboText.value;
        final streakText   = controller.streakText.value;
        final powerUpText  = controller.powerUpText.value;

        return Stack(
          children: [
            // Oyun elementleri (tuğla, top, bonus, nişan)
            CustomPaint(
              painter: GamePainter(
                state: state,
                aimAngle: angle,
                aimDragMagnitude: magnitude,
                activeLasers: controller.activeLasers,
                dangerFlash: dangerFlash,
                dangerLineY: controller.dangerLineY,
                brickShiftOffset: brickShiftOffset,
                skinPrimary: skin?.primary ?? AppColors.primary,
                skinLight:   skin?.light   ?? AppColors.primaryLight,
                skinDark:    skin?.dark    ?? AppColors.border,
              ),
              size: Size.infinite,
            ),
            // Parçacık efektleri (üst katman)
            CustomPaint(
              painter: ParticlePainter(controller.particles.particles),
              size: Size.infinite,
            ),
            // Aktif power-up HUD pill (sol üst)
            const _ActivePowerUpHud(),
            // Cep envanteri — backdrop + alttan açılan drawer
            const _InventoryDrawer(),
            // Sahne geçiş animasyonu
            if (stageText.isNotEmpty)
              _StageTransitionBanner(
                key: ValueKey(stageText),
                text: stageText,
              ),
            // Power-up aktivasyon banner
            if (powerUpText.isNotEmpty)
              _PowerUpBanner(
                key: ValueKey(powerUpText),
                text: powerUpText,
              ),
            // Combo göstergesi
            if (comboText.isNotEmpty)
              _ComboBanner(
                key: ValueKey(comboText),
                text: comboText,
              ),
            // Streak göstergesi
            if (streakText.isNotEmpty)
              _StreakBanner(
                key: ValueKey(streakText),
                text: streakText,
              ),
            // Duraklatma overlay
            _PauseOverlay(state: state),
          ],
        );
      }),
    );
  }
}

// ── Aktif Power-Up HUD Pill ───────────────────────────────────────────────

class _ActivePowerUpHud extends StatelessWidget {
  const _ActivePowerUpHud();

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<PowerUpController>()) return const SizedBox.shrink();
    final pu = Get.find<PowerUpController>();

    return Obx(() {
      if (!pu.hasActive && !pu.hasPending) return const SizedBox.shrink();

      final color = Color(pu.displayColorValue);
      final label = pu.displayName;
      final isPending = !pu.hasActive && pu.hasPending;

      return Positioned(
        top: 12,
        left: 12,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(180),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color, width: 1.5),
            boxShadow: [BoxShadow(color: color.withAlpha(80), blurRadius: 8)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: color, blurRadius: 4)],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isPending ? '$label →' : label,
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 1.2,
                ),
              ),
              if (pu.hasActive) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: color.withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withAlpha(120), width: 1),
                  ),
                  child: Text(
                    '${pu.activeTurnsLeft.value}T',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}

// ── Cep Envanteri Drawer ──────────────────────────────────────────────────

class _InventoryDrawer extends StatefulWidget {
  const _InventoryDrawer();

  @override
  State<_InventoryDrawer> createState() => _InventoryDrawerState();
}

class _InventoryDrawerState extends State<_InventoryDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    // GameController'daki inventoryOpen değişikliğini dinle
    ever(Get.find<GameController>().inventoryOpen, (bool open) {
      if (open) {
        _ctrl.forward();
      } else {
        _ctrl.reverse();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gc = Get.find<GameController>();

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        if (_ctrl.value == 0) return const SizedBox.shrink();

        return Stack(
          children: [
            // Yarı saydam backdrop — dokunulunca kapanır
            Positioned.fill(
              child: FadeTransition(
                opacity: _fade,
                child: GestureDetector(
                  onTap: gc.closeInventory,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    color: Colors.black.withAlpha(100),
                  ),
                ),
              ),
            ),
            // Slide-up bar — backdrop'a dokunma event'ini blokla
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SlideTransition(
                position: _slide,
                child: GestureDetector(
                  // Bar'ın kendisine dokunulunca kapanmasın
                  onTap: () {},
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(12, 0, 12, 24),
                    child: PowerUpBar(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Power-Up Aktivasyon Banner ────────────────────────────────────────────

class _PowerUpBanner extends StatefulWidget {
  const _PowerUpBanner({required super.key, required this.text});
  final String text;

  @override
  State<_PowerUpBanner> createState() => _PowerUpBannerState();
}

class _PowerUpBannerState extends State<_PowerUpBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward();

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0),           weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_ctrl);

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.6, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.05, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 5,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 85),
    ]).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Rengi text'ten bağımsız tutmak için PowerUpController'dan oku
    final color = Get.isRegistered<PowerUpController>()
        ? Color(Get.find<PowerUpController>().displayColorValue)
        : const Color(0xFF06B6D4);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => IgnorePointer(
        child: Align(
          alignment: const Alignment(0, 0.6),
          child: Opacity(
            opacity: _opacity.value,
            child: Transform.scale(
              scale: _scale.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(200),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: color.withAlpha(100), blurRadius: 16),
                    BoxShadow(color: color.withAlpha(50), blurRadius: 32),
                  ],
                ),
                child: Text(
                  widget.text,
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 2,
                    shadows: [Shadow(color: color, blurRadius: 12)],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sahne Geçiş Animasyonu ───────────────────────────────────────────────

class _StageTransitionBanner extends StatefulWidget {
  const _StageTransitionBanner({required super.key, required this.text});
  final String text;

  @override
  State<_StageTransitionBanner> createState() => _StageTransitionBannerState();
}

class _StageTransitionBannerState extends State<_StageTransitionBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;
  late final Animation<double> _offsetY;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..forward();

    // 0-12%: fade in + scale up │ 12-68%: görünür │ 68-100%: yukarı kayıp gider
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 12),
      TweenSequenceItem(tween: ConstantTween(1.0),           weight: 56),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 32),
    ]).animate(_ctrl);

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.55, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 8,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 80),
    ]).animate(_ctrl);

    _offsetY = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 68),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -60.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 32,
      ),
    ]).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context2, _) => IgnorePointer(
        child: Align(
          alignment: const Alignment(0, -0.10),
          child: Transform.translate(
            offset: Offset(0, _offsetY.value),
            child: Transform.scale(
              scale: _scale.value,
              child: Opacity(
                opacity: _opacity.value,
                child: _buildContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    const neonColors = [
      Color(0xFF7C3AED), // mor
      Color(0xFF06B6D4), // cyan
      Color(0xFFF97316), // turuncu
    ];
    // Stage numarasına göre renk seç
    final stageNum = int.tryParse(widget.text.split(' ').last) ?? 1;
    final color = neonColors[(stageNum - 1) % neonColors.length];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.text,
          style: TextStyle(
            fontSize: 54,
            fontWeight: FontWeight.w900,
            fontFamily: 'Orbitron',
            letterSpacing: 6,
            color: color,
            shadows: [
              Shadow(color: color, blurRadius: 24),
              Shadow(color: color, blurRadius: 48),
              const Shadow(color: Colors.white, blurRadius: 8),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'BAŞLIYOR',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Orbitron',
            letterSpacing: 8,
            color: Colors.white.withAlpha(180),
          ),
        ),
      ],
    );
  }
}

// ── Combo Göstergesi ─────────────────────────────────────────────────────

class _ComboBanner extends StatefulWidget {
  const _ComboBanner({required super.key, required this.text});
  final String text;

  @override
  State<_ComboBanner> createState() => _ComboBannerState();
}

class _ComboBannerState extends State<_ComboBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    // 0-15%: fırlayarak giriş │ 15-70%: görünür │ 70-100%: solar
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0),           weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_ctrl);

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.4, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 10,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 75),
    ]).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Renk: x2 sarı, x3 turuncu, x4 kırmızı
    final color = widget.text.contains('x4') ? const Color(0xFFEF4444)
                : widget.text.contains('x3') ? const Color(0xFFF97316)
                : const Color(0xFFEAB308);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => IgnorePointer(
        child: Align(
          alignment: const Alignment(0, 0.3),
          child: Opacity(
            opacity: _opacity.value,
            child: Transform.scale(
              scale: _scale.value,
              child: Text(
                widget.text,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Orbitron',
                  letterSpacing: 3,
                  color: color,
                  shadows: [
                    Shadow(color: color, blurRadius: 20),
                    Shadow(color: color, blurRadius: 40),
                    const Shadow(color: Colors.white, blurRadius: 6),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Streak Göstergesi ─────────────────────────────────────────────────────

class _StreakBanner extends StatefulWidget {
  const _StreakBanner({required super.key, required this.text});
  final String text;

  @override
  State<_StreakBanner> createState() => _StreakBannerState();
}

class _StreakBannerState extends State<_StreakBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;
  late final Animation<double> _offsetY;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();

    // 0-12%: fırlayarak yukarıdan giriş │ 12-70%: görünür │ 70-100%: solar
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 12),
      TweenSequenceItem(tween: ConstantTween(1.0),           weight: 58),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_ctrl);

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.5, end: 1.12)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.12, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 8,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 80),
    ]).animate(_ctrl);

    // Yukarı doğru hafifçe kayar (combo'nun tersine)
    _offsetY = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 70),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -30.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Renk: x2=cyan, x3=mor/pembe, x5=altın
    final Color color;
    if (widget.text.contains('x5')) {
      color = const Color(0xFFF59E0B); // Altın
    } else if (widget.text.contains('x3')) {
      color = const Color(0xFFA78BFA); // Mor
    } else {
      color = const Color(0xFF06B6D4); // Cyan
    }

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => IgnorePointer(
        child: Align(
          alignment: const Alignment(0, -0.35),
          child: Transform.translate(
            offset: Offset(0, _offsetY.value),
            child: Opacity(
              opacity: _opacity.value,
              child: Transform.scale(
                scale: _scale.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.text,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Orbitron',
                        letterSpacing: 3,
                        color: color,
                        shadows: [
                          Shadow(color: color, blurRadius: 20),
                          Shadow(color: color, blurRadius: 40),
                          const Shadow(color: Colors.white, blurRadius: 6),
                        ],
                      ),
                    ),
                    Text(
                      'BONUS PUAN!',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Orbitron',
                        letterSpacing: 4,
                        color: color.withAlpha(200),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Duraklatma Overlay ────────────────────────────────────────────────────

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({required this.state});
  final GameState state;

  @override
  Widget build(BuildContext context) {
    if (state.status != GameStatus.paused) return const SizedBox.expand();

    return Container(
      color: Colors.black.withAlpha(160),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'DURAKLATILDI',
              style: const TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.foreground,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 32),
            _PauseButton(
              label: 'DEVAM ET',
              color: AppColors.primary,
              onTap: Get.find<GameController>().resumeGame,
            ),
            const SizedBox(height: 12),
            _PauseButton(
              label: 'YENİDEN BAŞLA',
              color: AppColors.surfaceVariant,
              onTap: Get.find<GameController>().restartGame,
            ),
            const SizedBox(height: 12),
            _PauseButton(
              label: 'ANA MENÜ',
              color: Colors.transparent,
              onTap: () => Get.find<GameController>().saveAndGoHome(),
              outlined: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _PauseButton extends StatelessWidget {
  const _PauseButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        height: 48,
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(8),
          border: outlined
              ? Border.all(color: AppColors.border, width: 1.5)
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.foreground,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
