import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/ball.dart';
import '../../models/bonus_ball.dart';
import '../../models/brick.dart';
import '../../models/game_state.dart';
import '../../models/power_up_cell.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../game/widgets/game_painter.dart';

/// Sadece geliştirici kullanımı — App Store screenshot sahneleri.
/// Settings ekranındaki gizli butona 5 kez basınca açılır.
class ScreenshotHelperView extends StatefulWidget {
  const ScreenshotHelperView({super.key});

  @override
  State<ScreenshotHelperView> createState() => _ScreenshotHelperViewState();
}

class _ScreenshotHelperViewState extends State<ScreenshotHelperView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _sceneTitles = [
    '1 — Dense Mid-Game Action',
    '2 — Boss Brick',
    '3 — Power-Up Field',
    '4 — Upgrade Screen',
    '5 — Combo Moment',
    '6 — Gem Reward',
    '7 — Skin Selection',
    '8 — Title Card',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _setupBrickConfig(double width) {
    const cols = 7;
    const gap = 4.0;
    const padding = 8.0;
    final totalGap = gap * (cols - 1) + padding * 2;
    BrickConfig.size = (width - totalGap) / cols;
    BrickConfig.gap = gap;
    BrickConfig.padding = padding;
    BrickConfig.topOffset = 0;
    BrickConfig.columns = cols;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: _sceneTitles[_currentPage],
              page: _currentPage + 1,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _GameScene(
                    sceneBuilder: _scene1,
                    setupBrickConfig: _setupBrickConfig,
                    callout: 'INFINITE UPGRADES',
                    calloutBottom: true,
                  ),
                  _GameScene(
                    sceneBuilder: _scene2,
                    setupBrickConfig: _setupBrickConfig,
                    callout: 'BOSS EVERY 5 STAGES',
                    calloutBottom: false,
                  ),
                  _GameScene(
                    sceneBuilder: _scene3,
                    setupBrickConfig: _setupBrickConfig,
                    callout: '5 POWER-UPS',
                    calloutBottom: true,
                  ),
                  _NavigateScene(
                    hint: 'GemShop will open → UPGRADES tab → take screenshot',
                    buttonLabel: 'Open Upgrade Screen →',
                    onTap: () => Get.toNamed(AppRoutes.upgrade),
                  ),
                  _GameScene(
                    sceneBuilder: _scene5,
                    setupBrickConfig: _setupBrickConfig,
                    callout: null,
                    calloutBottom: true,
                    extraOverlay: const _ComboOverlay(),
                  ),
                  _GameScene(
                    sceneBuilder: _scene6,
                    setupBrickConfig: _setupBrickConfig,
                    callout: 'EARN GEMS, LEVEL UP',
                    calloutBottom: true,
                  ),
                  _NavigateScene(
                    hint: 'GemShop will open → SKINS tab → take screenshot',
                    buttonLabel: 'Open Skin Shop →',
                    onTap: () => Get.toNamed(AppRoutes.upgrade, arguments: 3),
                  ),
                  const _TitleCardScene(),
                ],
              ),
            ),
            _NavBar(
              currentPage: _currentPage,
              pageCount: 8,
              onPrev: _currentPage > 0
                  ? () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut)
                  : null,
              onNext: _currentPage < 7
                  ? () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ── Scene builders ────────────────────────────────────────────────────────

  GameState _scene1(double w, double h) {
    final rng = Random(42);
    final bricks = <Brick>[];
    for (int row = 0; row < 5; row++) {
      for (int col = 0; col < 7; col++) {
        if (row == 0 && col == 3) continue;
        final hp = 8 + rng.nextInt(8);
        bricks.add(Brick(
          col: col, row: row, hp: hp, maxHp: hp + 4,
          type: _pickType(rng, 8),
        ));
      }
    }
    return GameState(
      balls: _scatterBalls(w, h, 18, rng),
      bricks: bricks, bonusBalls: [], powerUpCells: [],
      score: 42850, level: 23, stage: 8, ballCount: 18,
      turnPhase: TurnPhase.shooting, status: GameStatus.playing, launchX: w / 2,
    );
  }

  GameState _scene2(double w, double h) {
    final rng = Random(7);
    final bricks = <Brick>[];
    bricks.add(Brick(col: 2, row: 0, hp: 15, maxHp: 20, type: BrickType.boss));
    for (int col = 0; col < 7; col++) {
      if (col == 2 || col == 3) continue;
      final hp = 10 + rng.nextInt(5);
      bricks.add(Brick(col: col, row: 0, hp: hp, maxHp: hp + 2));
    }
    for (int row = 2; row < 5; row++) {
      for (int col = 0; col < 7; col++) {
        if (rng.nextDouble() < 0.25) continue;
        final hp = 8 + rng.nextInt(6);
        bricks.add(Brick(col: col, row: row, hp: hp, maxHp: hp + 3,
            type: _pickType(rng, 10)));
      }
    }
    return GameState(
      balls: _scatterBalls(w, h, 12, rng),
      bricks: bricks, bonusBalls: [], powerUpCells: [],
      score: 58200, level: 15, stage: 10, ballCount: 12,
      turnPhase: TurnPhase.shooting, status: GameStatus.playing, launchX: w / 2,
    );
  }

  GameState _scene3(double w, double h) {
    final rng = Random(13);
    final bricks = <Brick>[];
    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 7; col++) {
        if (rng.nextDouble() < 0.2) continue;
        final hp = 4 + rng.nextInt(4);
        bricks.add(Brick(col: col, row: row, hp: hp, maxHp: hp + 2));
      }
    }
    final powerUpCells = [
      PowerUpCell(col: 1, row: 4, type: PowerUpType.fireball),
      PowerUpCell(col: 3, row: 5, type: PowerUpType.multiBall),
      PowerUpCell(col: 5, row: 4, type: PowerUpType.nuke),
      PowerUpCell(col: 6, row: 6, type: PowerUpType.speedBoost),
    ];
    return GameState(
      balls: _scatterBalls(w, h, 8, rng),
      bricks: bricks, bonusBalls: [], powerUpCells: powerUpCells,
      score: 18400, level: 8, stage: 5, ballCount: 8,
      turnPhase: TurnPhase.shooting, status: GameStatus.playing, launchX: w / 2,
    );
  }

  GameState _scene5(double w, double h) {
    final rng = Random(99);
    final bricks = <Brick>[];
    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 7; col++) {
        final hp = 6 + rng.nextInt(5);
        bricks.add(Brick(col: col, row: row, hp: hp, maxHp: hp + 2,
            type: _pickType(rng, 6)));
      }
    }
    return GameState(
      balls: _scatterBalls(w, h, 14, rng),
      bricks: bricks, bonusBalls: [], powerUpCells: [],
      score: 31500, level: 18, stage: 6, ballCount: 14,
      turnPhase: TurnPhase.shooting, status: GameStatus.playing, launchX: w / 2,
    );
  }

  GameState _scene6(double w, double h) {
    final rng = Random(55);
    final bricks = <Brick>[];
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 7; col++) {
        if (rng.nextDouble() < 0.25) continue;
        final hp = 3 + rng.nextInt(3);
        bricks.add(Brick(col: col, row: row, hp: hp, maxHp: hp + 1));
      }
    }
    final bonusBalls = [
      BonusBall(col: 2, row: 3, type: BonusBallType.plus),
      BonusBall(col: 4, row: 4, type: BonusBallType.plus),
      BonusBall(col: 0, row: 5, type: BonusBallType.plus),
    ];
    return GameState(
      balls: _scatterBalls(w, h, 6, rng),
      bricks: bricks, bonusBalls: bonusBalls, powerUpCells: [],
      score: 12300, level: 10, stage: 4, ballCount: 6,
      turnPhase: TurnPhase.shooting, status: GameStatus.playing, launchX: w / 2,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<Ball> _scatterBalls(double w, double h, int count, Random rng) {
    return List.generate(count, (_) {
      final x = 20.0 + rng.nextDouble() * (w - 40);
      final y = h * 0.3 + rng.nextDouble() * (h * 0.45);
      final angle = -pi / 4 - rng.nextDouble() * pi / 2;
      return Ball(
        position: Offset(x, y),
        velocity: Offset(cos(angle) * 600, sin(angle) * 600),
        radius: 8.0,
        isActive: true,
      );
    });
  }

  BrickType _pickType(Random rng, int stage) {
    final r = rng.nextDouble();
    if (stage >= 6 && r < 0.08) return BrickType.stone;
    if (stage >= 4 && r < 0.13) return BrickType.bomb;
    if (r < 0.20) return BrickType.triangle;
    return BrickType.normal;
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String title;
  final int page;
  const _Header({required this.title, required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: Get.back,
            child: const Icon(Icons.arrow_back_ios, color: Colors.white54, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.orbitron(
                  color: Colors.white70, fontSize: 11, letterSpacing: 1),
            ),
          ),
          Text(
            '$page / 8',
            style: GoogleFonts.jetBrainsMono(
                color: AppColors.accent, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final int currentPage;
  final int pageCount;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _NavBar({
    required this.currentPage,
    required this.pageCount,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavButton(label: '← PREV', active: onPrev != null, onTap: onPrev),
          Row(
            children: List.generate(pageCount, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == currentPage ? 16 : 5,
              height: 5,
              decoration: BoxDecoration(
                color: i == currentPage ? AppColors.accent : Colors.white24,
                borderRadius: BorderRadius.circular(3),
              ),
            )),
          ),
          _NavButton(label: 'NEXT →', active: onNext != null, onTap: onNext),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;
  const _NavButton({required this.label, required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.accent.withAlpha(40) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: active ? AppColors.accent.withAlpha(120) : Colors.transparent),
        ),
        child: Text(
          label,
          style: GoogleFonts.orbitron(
            color: active ? AppColors.accent : Colors.transparent,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _GameScene extends StatelessWidget {
  final GameState Function(double w, double h) sceneBuilder;
  final void Function(double w) setupBrickConfig;
  final String? callout;
  final bool calloutBottom;
  final Widget? extraOverlay;

  const _GameScene({
    required this.sceneBuilder,
    required this.setupBrickConfig,
    required this.callout,
    required this.calloutBottom,
    this.extraOverlay,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      setupBrickConfig(w);
      final state = sceneBuilder(w, h);
      return Stack(
        children: [
          CustomPaint(
            size: Size(w, h),
            painter: GamePainter(state: state, dangerLineY: h * 0.88),
          ),
          if (callout != null)
            Positioned(
              bottom: calloutBottom ? 24 : null,
              top: calloutBottom ? null : 24,
              left: 24, right: 24,
              child: _Callout(callout!),
            ),
          ?extraOverlay,
        ],
      );
    });
  }
}

class _Callout extends StatelessWidget {
  final String text;
  const _Callout(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background.withAlpha(210),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.accent.withAlpha(180)),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withAlpha(80),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Text(
          text,
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            shadows: [Shadow(color: AppColors.accent, blurRadius: 12)],
          ),
        ),
      ),
    );
  }
}

class _ComboOverlay extends StatelessWidget {
  const _ComboOverlay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'x15',
            style: GoogleFonts.orbitron(
              color: AppColors.amber,
              fontSize: 80,
              fontWeight: FontWeight.w900,
              shadows: [Shadow(color: AppColors.amber, blurRadius: 40)],
            ),
          ),
          Text(
            'COMBO!',
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 22,
              letterSpacing: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigateScene extends StatelessWidget {
  final String hint;
  final String buttonLabel;
  final VoidCallback onTap;

  const _NavigateScene({
    required this.hint,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hint,
              textAlign: TextAlign.center,
              style: GoogleFonts.jetBrainsMono(
                  color: Colors.white38, fontSize: 12, height: 1.6),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.accent.withAlpha(60), blurRadius: 20)
                  ],
                ),
                child: Text(
                  buttonLabel,
                  style: GoogleFonts.orbitron(
                      color: Colors.white, fontSize: 14, letterSpacing: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleCardScene extends StatelessWidget {
  const _TitleCardScene();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [Color(0xFF1A0A3D), Color(0xFF0F0F23)],
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withAlpha(55),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ORBRIOT',
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                    shadows: [
                      Shadow(color: AppColors.accent, blurRadius: 30),
                      Shadow(color: AppColors.accent, blurRadius: 60),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: 220,
                  height: 2,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.transparent,
                      Color(0xFF06B6D4),
                      Colors.transparent,
                    ]),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'SMASH THE GRID',
                  style: GoogleFonts.orbitron(
                    color: const Color(0xFF06B6D4),
                    fontSize: 16,
                    letterSpacing: 4,
                    shadows: [
                      Shadow(color: const Color(0xFF06B6D4), blurRadius: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 52),
                Text(
                  'INFINITE UPGRADES · BOSS BATTLES\nPOWER-UPS · PRESTIGE SYSTEM',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white38,
                    fontSize: 11,
                    letterSpacing: 1,
                    height: 1.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
