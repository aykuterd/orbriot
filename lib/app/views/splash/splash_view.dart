import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with TickerProviderStateMixin {
  late final AnimationController _bgCtrl;
  late final AnimationController _logoCtrl;
  late final AnimationController _orbitCtrl;
  late final AnimationController _loadCtrl;
  late final AnimationController _exitCtrl;

  late final Animation<double> _bgFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _loadProgress;
  late final Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();

    // Arkaplan pulse
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    // Logo giriş animasyonu
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _bgFade = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut),
    );

    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    // Orbit dönüş
    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    // Loading bar
    _loadCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _loadProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadCtrl, curve: Curves.easeInOut),
    );

    // Çıkış fade
    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    // Logo giriş
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _logoCtrl.forward();

    // Yükleme başlat
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _loadCtrl.forward();

    // Çıkış
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    await _exitCtrl.forward();
    if (!mounted) return;
    Get.offNamed(AppRoutes.home);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _logoCtrl.dispose();
    _orbitCtrl.dispose();
    _loadCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _bgCtrl,
          _logoCtrl,
          _orbitCtrl,
          _loadCtrl,
          _exitCtrl,
        ]),
        builder: (context, _) {
          return Opacity(
            opacity: _exitFade.value,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Arkaplan parçacıkları ──────────────────────────────
                CustomPaint(
                  painter: _SplashBackgroundPainter(
                    pulse: _bgFade.value,
                    orbit: _orbitCtrl.value,
                  ),
                ),

                // ── Merkez içerik ─────────────────────────────────────
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    // Orbit animasyonlu top
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: CustomPaint(
                        painter: _OrbitPainter(
                          angle: _orbitCtrl.value * 2 * pi,
                          pulse: _bgFade.value,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Logo
                    FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primaryLight,
                              AppColors.accent,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: Text(
                            'ORBRIOT',
                            style: AppTextStyles.displayLarge.copyWith(
                              fontSize: 48,
                              shadows: [
                                Shadow(
                                  color: AppColors.primary
                                      .withAlpha((_bgFade.value * 200).round()),
                                  blurRadius: 32 * _bgFade.value,
                                ),
                                Shadow(
                                  color: AppColors.primaryLight
                                      .withAlpha((_bgFade.value * 140).round()),
                                  blurRadius: 64 * _bgFade.value,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Alt yazı
                    FadeTransition(
                      opacity: _subtitleFade,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _dividerLine(),
                          const SizedBox(width: 10),
                          Text(
                            'BRICK  BLAST',
                            style: AppTextStyles.bodySmall.copyWith(
                              letterSpacing: 6,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _dividerLine(),
                        ],
                      ),
                    ),

                    const Spacer(flex: 2),

                    // Loading bar
                    FadeTransition(
                      opacity: _subtitleFade,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: Column(
                          children: [
                            _NeonLoadingBar(progress: _loadProgress.value),
                            const SizedBox(height: 12),
                            Text(
                              'label_loading'.tr,
                              style: AppTextStyles.hudLabel.copyWith(
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _dividerLine() => Container(
        width: 32,
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.border.withAlpha(0),
              AppColors.border,
            ],
          ),
        ),
      );
}

// ── Arkaplan painter ────────────────────────────────────────────────────────

class _SplashBackgroundPainter extends CustomPainter {
  final double pulse;
  final double orbit;

  _SplashBackgroundPainter({required this.pulse, required this.orbit});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Ana glow dairesi
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primary.withAlpha((pulse * 60).round()),
          AppColors.primary.withAlpha((pulse * 25).round()),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(cx, cy),
        radius: 280 * pulse,
      ))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);

    canvas.drawCircle(Offset(cx, cy), 280 * pulse, glowPaint);

    // Accent glow (üst sol köşe)
    final accentPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.accent.withAlpha((pulse * 40).round()),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(cx * 0.3, cy * 0.4),
        radius: 160,
      ));
    canvas.drawCircle(Offset(cx * 0.3, cy * 0.4), 160, accentPaint);

    // Mavi glow (sağ alt)
    final bluePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.neonBlue.withAlpha((pulse * 35).round()),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(cx * 1.7, cy * 1.6),
        radius: 180,
      ));
    canvas.drawCircle(Offset(cx * 1.7, cy * 1.6), 180, bluePaint);

    // Grid noktaları
    _drawDotGrid(canvas, size);
  }

  void _drawDotGrid(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = AppColors.border.withAlpha((pulse * 30).round())
      ..style = PaintingStyle.fill;

    const spacing = 44.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_SplashBackgroundPainter old) =>
      old.pulse != pulse || old.orbit != orbit;
}

// ── Orbit painter ────────────────────────────────────────────────────────────

class _OrbitPainter extends CustomPainter {
  final double angle;
  final double pulse;

  _OrbitPainter({required this.angle, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Dış orbit halkası
    final ringPaint = Paint()
      ..color = AppColors.primary.withAlpha((pulse * 80).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(cx, cy), r - 8, ringPaint);

    // İç orbit halkası
    final innerRingPaint = Paint()
      ..color = AppColors.accent.withAlpha((pulse * 50).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(Offset(cx, cy), r * 0.6, innerRingPaint);

    // Merkez top (glow)
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primaryLight,
          AppColors.primary,
          AppColors.primary.withAlpha(0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromCircle(center: Offset(cx, cy), radius: 28 * pulse),
      );
    canvas.drawCircle(Offset(cx, cy), 28 * pulse, corePaint);

    // Parlak merkez
    final dotPaint = Paint()
      ..color = Colors.white.withAlpha((pulse * 230).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(cx, cy), 6, dotPaint);

    // Yörüngede dönen top
    final ballX = cx + (r - 8) * cos(angle);
    final ballY = cy + (r - 8) * sin(angle);

    final ballGlowPaint = Paint()
      ..color = AppColors.accent.withAlpha((pulse * 160).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(ballX, ballY), 10, ballGlowPaint);

    final ballPaint = Paint()
      ..color = AppColors.accent.withAlpha((pulse * 255).round());
    canvas.drawCircle(Offset(ballX, ballY), 6, ballPaint);

    final ballCorePaint = Paint()
      ..color = Colors.white.withAlpha((pulse * 200).round());
    canvas.drawCircle(Offset(ballX, ballY), 2.5, ballCorePaint);

    // İkinci top (zıt yönde, iç yörüngede)
    final ball2X = cx + (r * 0.6) * cos(-angle * 1.5 + pi / 3);
    final ball2Y = cy + (r * 0.6) * sin(-angle * 1.5 + pi / 3);

    final ball2GlowPaint = Paint()
      ..color = AppColors.neonBlue.withAlpha((pulse * 130).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(ball2X, ball2Y), 7, ball2GlowPaint);

    final ball2Paint = Paint()
      ..color = AppColors.neonBlue.withAlpha((pulse * 255).round());
    canvas.drawCircle(Offset(ball2X, ball2Y), 4, ball2Paint);
  }

  @override
  bool shouldRepaint(_OrbitPainter old) =>
      old.angle != angle || old.pulse != pulse;
}

// ── Neon loading bar ─────────────────────────────────────────────────────────

class _NeonLoadingBar extends StatelessWidget {
  final double progress;

  const _NeonLoadingBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight, AppColors.accent],
            ),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(180),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
