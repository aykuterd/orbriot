import 'dart:math';
import 'package:flutter/material.dart';
import '../../../models/bonus_ball.dart';
import '../../../models/brick.dart';
import '../../../models/game_state.dart';
import '../../../models/power_up_cell.dart';
import '../../../models/laser_beam.dart';
import '../../../theme/app_colors.dart';
import '../../../core/utils/constants.dart';

class GamePainter extends CustomPainter {
  final GameState state;
  final double? aimAngle;
  final double aimDragMagnitude;
  final List<LaserBeam> activeLasers;
  final double dangerFlash;       // 0..1 — kırmızı hale nabzı
  final double dangerLineY;       // game over çizgisinin Y koordinatı
  final double brickShiftOffset;  // continue kayma animasyonu (piksel, 0 = normal)

  // Skin renkleri
  final Color skinPrimary;
  final Color skinLight;
  final Color skinDark;

  GamePainter({
    required this.state,
    this.aimAngle,
    this.aimDragMagnitude = 0,
    this.activeLasers = const [],
    this.dangerFlash = 0,
    this.dangerLineY = double.infinity,
    this.brickShiftOffset = 0,
    this.skinPrimary = const Color(0xFF7C3AED),
    this.skinLight   = const Color(0xFFA78BFA),
    this.skinDark    = const Color(0xFF4C1D95),
  });

  // Sabit paint nesneleri
  final Paint _p        = Paint();
  final Paint _border   = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5;
  final Paint _aimPaint = Paint()..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    // Grid elemanları (tuğla, bonus top, power-up) continue animasyonu sırasında
    // aşağıdan yukarı kaydığı için canvas'ı geçici olarak öteleyip geri alıyoruz.
    if (brickShiftOffset > 0) {
      canvas.save();
      canvas.translate(0, brickShiftOffset);
    }
    _drawBricks(canvas);
    _drawBonusBalls(canvas);
    _drawPowerUpCells(canvas);
    if (brickShiftOffset > 0) canvas.restore();

    if (aimAngle != null && state.turnPhase == TurnPhase.aiming) {
      _drawAimGuide(canvas, size);
    }
    _drawBalls(canvas);
    _drawActiveLasers(canvas, size);
    _drawDangerHalo(canvas, size);
    _drawLaunchZone(canvas, size);
  }

  // ═══════════════════════════════════════════════════════════
  // TUĞLA ÇİZİMLERİ
  // ═══════════════════════════════════════════════════════════

  void _drawBricks(Canvas canvas) {
    for (final brick in state.bricks) {
      if (!brick.isAlive) continue;
      final rect = brick.rect;

      // Boss için 2×2 boyutlu rect kullan; diğerleri normal rect
      final drawRect = brick.type == BrickType.boss ? brick.bossRect : rect;

      switch (brick.type) {
        case BrickType.normal:
          _drawNormalBrick(canvas, rect, brick);
        case BrickType.triangle:
          _drawTriangleBrick(canvas, rect, brick);
        case BrickType.stone:
          _drawStoneBrick(canvas, rect, brick);
        case BrickType.bomb:
          _drawBombBrick(canvas, rect, brick);
        case BrickType.chain:
          _drawChainBrick(canvas, rect, brick);
        case BrickType.shield:
          _drawShieldBrick(canvas, rect, brick);
        case BrickType.multiplier:
          _drawMultiplierBrick(canvas, rect, brick);
        case BrickType.laserH:
          _drawLaserHBrick(canvas, rect, brick);
        case BrickType.laserV:
          _drawLaserVBrick(canvas, rect, brick);
        case BrickType.boss:
          _drawBossBrick(canvas, drawRect, brick);
      }

      _drawHpLabel(canvas, brick, drawRect);
      _drawHitFlash(canvas, brick, drawRect);
    }
  }

  // ── Normal — mor gradient, glossy ───────────────────────────────────────

  void _drawNormalBrick(Canvas canvas, Rect rect, Brick brick) {
    const r = Radius.circular(8);
    final rrect = RRect.fromRectAndRadius(rect, r);

    final base  = _hpColor(brick);
    final dark  = _darken(base, 0.25);   // 0.45→0.25: alt renk artık çok koyu değil
    final light = _lighten(base, 0.30);  // 0.15→0.30: üst renk daha parlak

    // 1. Dış neon glow — alpha artırıldı (80→140) her zaman görünsün
    canvas.drawRRect(rrect,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 10)
        ..color = base.withAlpha((140 * brick.hpRatio).clamp(60, 140).toInt()));

    // 2. Gradient gövde
    _p
      ..style  = PaintingStyle.fill
      ..shader = LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [light, base, dark],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(rect);
    canvas.drawRRect(rrect, _p);
    _p.shader = null;

    // 3. Sağ/alt koyu kenar — 3D derinlik
    _p
      ..color = Colors.black.withAlpha(50)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTRB(rect.left + 2, rect.bottom - 5, rect.right, rect.bottom),
        bottomLeft:  r, bottomRight: r,
      ),
      _p,
    );

    // 4. Üst glossy şerit
    _drawGloss(canvas, rect, r);

    // 5. Hasar kararması
    _drawDamageOverlay(canvas, rrect, brick.hpRatio);

    // 6. Neon çerçeve
    _border.color = light.withAlpha(230);
    canvas.drawRRect(rrect, _border);
  }

  // ── Üçgen — ikizkenar dik üçgen, yönlü hipotenüs ───────────────────────

  void _drawTriangleBrick(Canvas canvas, Rect rect, Brick brick) {
    const base  = AppColors.neonBlue;
    const light = Color(0xFF60A5FA);
    const dark  = Color(0xFF1E40AF);

    // slash (/) = ◺ — TL, TR, BL köşeleri
    // backslash (\) = ◸ — TL, TR, BR köşeleri
    final orientation = brick.triangleOrientation ?? TriangleOrientation.slash;
    final path = orientation == TriangleOrientation.slash
        ? (Path()
          ..moveTo(rect.left,  rect.top)
          ..lineTo(rect.right, rect.top)
          ..lineTo(rect.left,  rect.bottom)
          ..close())
        : (Path()
          ..moveTo(rect.left,  rect.top)
          ..lineTo(rect.right, rect.top)
          ..lineTo(rect.right, rect.bottom)
          ..close());

    // Glow
    canvas.drawPath(path,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 12)
        ..color = base.withAlpha((90 * brick.hpRatio).round()));

    // Gradient dolgu
    _p
      ..style  = PaintingStyle.fill
      ..shader = LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [light, base, dark],
        ).createShader(rect);
    canvas.drawPath(path, _p);
    _p.shader = null;

    // Hipotenüs üzerinde ince parlak çizgi
    final hipPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.white.withAlpha(70);
    if (orientation == TriangleOrientation.slash) {
      canvas.drawLine(Offset(rect.right, rect.top), Offset(rect.left, rect.bottom), hipPaint);
    } else {
      canvas.drawLine(Offset(rect.left, rect.top), Offset(rect.right, rect.bottom), hipPaint);
    }

    // Hasar
    if (brick.hpRatio < 0.6) {
      canvas.drawPath(path,
        Paint()
          ..color = Colors.black.withAlpha(((1 - brick.hpRatio) * 80).round())
          ..style = PaintingStyle.fill);
    }

    // Çerçeve
    _border.color = light.withAlpha(210);
    canvas.drawPath(path, _border);
  }

  // ── Zincir — teal, zincir halka simgesi ─────────────────────────────────

  void _drawChainBrick(Canvas canvas, Rect rect, Brick brick) {
    const r     = Radius.circular(8);
    final rrect = RRect.fromRectAndRadius(rect, r);
    const base  = Color(0xFF14B8A6);
    const light = Color(0xFF2DD4BF);
    const dark  = Color(0xFF0D7377);

    // Glow
    canvas.drawRRect(rrect,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 10)
        ..color = base.withAlpha((80 * brick.hpRatio).round()));

    // Gradient
    _p
      ..style  = PaintingStyle.fill
      ..shader = LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [light, base, dark],
        ).createShader(rect);
    canvas.drawRRect(rrect, _p);
    _p.shader = null;

    // Zincir halkaları
    _drawChainLinks(canvas, rect);

    _drawGloss(canvas, rect, r);
    _drawDamageOverlay(canvas, rrect, brick.hpRatio);
    _border.color = light.withAlpha(200);
    canvas.drawRRect(rrect, _border);
  }

  void _drawChainLinks(Canvas canvas, Rect rect) {
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final lp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = Colors.white.withAlpha(90);

    final rw = rect.width  * 0.20;
    final rh = rect.height * 0.28;

    // Sol halka
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - rw * 0.9, cy), width: rw * 2, height: rh * 2), lp);
    // Sağ halka (üst üste)
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + rw * 0.9, cy), width: rw * 2, height: rh * 2), lp);
  }

  // ── Kalkan — altın (aktif) / gri-mavi (kırık) ───────────────────────────

  void _drawShieldBrick(Canvas canvas, Rect rect, Brick brick) {
    const r     = Radius.circular(8);
    final rrect = RRect.fromRectAndRadius(rect, r);

    final Color base, light, dark;
    if (brick.shieldActive) {
      base  = const Color(0xFFF59E0B);
      light = const Color(0xFFFBBF24);
      dark  = const Color(0xFFB45309);
    } else {
      base  = const Color(0xFF64748B);
      light = const Color(0xFF94A3B8);
      dark  = const Color(0xFF334155);
    }

    // Glow
    canvas.drawRRect(rrect,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 10)
        ..color = base.withAlpha((85 * brick.hpRatio).round()));

    // Gradient
    _p
      ..style  = PaintingStyle.fill
      ..shader = LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [light, base, dark],
        ).createShader(rect);
    canvas.drawRRect(rrect, _p);
    _p.shader = null;

    // Kalkan simgesi
    _drawShieldIcon(canvas, rect, brick.shieldActive);

    _drawGloss(canvas, rect, r);
    _drawDamageOverlay(canvas, rrect, brick.hpRatio);
    _border.color = light.withAlpha(200);
    canvas.drawRRect(rrect, _border);
  }

  void _drawShieldIcon(Canvas canvas, Rect rect, bool active) {
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final w  = rect.width  * 0.38;
    final h  = rect.height * 0.44;
    final alpha = active ? 120 : 55;

    final path = Path()
      ..moveTo(cx, cy - h)
      ..lineTo(cx + w, cy - h * 0.4)
      ..lineTo(cx + w, cy + h * 0.2)
      ..quadraticBezierTo(cx + w * 0.4, cy + h, cx, cy + h)
      ..quadraticBezierTo(cx - w * 0.4, cy + h, cx - w, cy + h * 0.2)
      ..lineTo(cx - w, cy - h * 0.4)
      ..close();

    canvas.drawPath(path,
      Paint()..color = Colors.white.withAlpha(alpha)..style = PaintingStyle.stroke..strokeWidth = 2.0);

    if (!active) {
      // Kırık kalkan: çapraz çizgi
      canvas.drawLine(
        Offset(cx - w * 0.4, cy - h * 0.3),
        Offset(cx + w * 0.4, cy + h * 0.3),
        Paint()..color = Colors.white.withAlpha(60)..strokeWidth = 1.5..style = PaintingStyle.stroke,
      );
    }
  }

  // ── Çoğaltıcı — pembe, ×2 etiketi ───────────────────────────────────────

  void _drawMultiplierBrick(Canvas canvas, Rect rect, Brick brick) {
    const r     = Radius.circular(8);
    final rrect = RRect.fromRectAndRadius(rect, r);
    const base  = Color(0xFFEC4899);
    const light = Color(0xFFF472B6);
    const dark  = Color(0xFF9D174D);

    // Güçlü pembe glow
    canvas.drawRRect(rrect,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 12)
        ..color = base.withAlpha((100 * brick.hpRatio).round()));

    // Gradient
    _p
      ..style  = PaintingStyle.fill
      ..shader = LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [light, base, dark],
        ).createShader(rect);
    canvas.drawRRect(rrect, _p);
    _p.shader = null;

    // "×2" yazısı
    _drawX2Label(canvas, rect);

    _drawGloss(canvas, rect, r);
    _drawDamageOverlay(canvas, rrect, brick.hpRatio);
    _border.color = light.withAlpha(210);
    canvas.drawRRect(rrect, _border);
  }

  void _drawX2Label(Canvas canvas, Rect rect) {
    final tp = TextPainter(
      text: const TextSpan(
        text: '×2',
        style: TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
      rect.center + Offset(-tp.width / 2, -tp.height / 2));
  }

  // ── Yatay Lazer — turuncu, → ← okları ──────────────────────────────────

  void _drawLaserHBrick(Canvas canvas, Rect rect, Brick brick) {
    const r     = Radius.circular(8);
    final rrect = RRect.fromRectAndRadius(rect, r);
    const base  = Color(0xFFF97316);
    const light = Color(0xFFFB923C);
    const dark  = Color(0xFFC2410C);

    canvas.drawRRect(rrect,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 12)
        ..color = base.withAlpha((100 * brick.hpRatio).round()));

    _p
      ..style  = PaintingStyle.fill
      ..shader = LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [light, base, dark],
        ).createShader(rect);
    canvas.drawRRect(rrect, _p);
    _p.shader = null;

    _drawLaserLine(canvas, rect, isHorizontal: true);
    _drawGloss(canvas, rect, r);
    _border.color = light.withAlpha(210);
    canvas.drawRRect(rrect, _border);
  }

  // ── Dikey Lazer — cyan, dikey çizgi ─────────────────────────────────────

  void _drawLaserVBrick(Canvas canvas, Rect rect, Brick brick) {
    const r     = Radius.circular(8);
    final rrect = RRect.fromRectAndRadius(rect, r);
    const base  = Color(0xFF06B6D4);
    const light = Color(0xFF22D3EE);
    const dark  = Color(0xFF0E7490);

    canvas.drawRRect(rrect,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 12)
        ..color = base.withAlpha((100 * brick.hpRatio).round()));

    _p
      ..style  = PaintingStyle.fill
      ..shader = LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [light, base, dark],
        ).createShader(rect);
    canvas.drawRRect(rrect, _p);
    _p.shader = null;

    _drawLaserLine(canvas, rect, isHorizontal: false);
    _drawGloss(canvas, rect, r);
    _border.color = light.withAlpha(210);
    canvas.drawRRect(rrect, _border);
  }

  void _drawLaserLine(Canvas canvas, Rect rect, {required bool isHorizontal}) {
    final cx = rect.center.dx;
    final cy = rect.center.dy;

    final from = isHorizontal
        ? Offset(rect.left  + 4, cy)
        : Offset(cx, rect.top    + 4);
    final to   = isHorizontal
        ? Offset(rect.right - 4, cy)
        : Offset(cx, rect.bottom - 4);

    // Dış glow
    canvas.drawLine(from, to,
      Paint()
        ..color = Colors.white.withAlpha(60)
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
        ..style = PaintingStyle.stroke);

    // Parlak çekirdek çizgi
    canvas.drawLine(from, to,
      Paint()
        ..color = Colors.white.withAlpha(230)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke);

    // Merkez nokta
    canvas.drawCircle(rect.center, 4,
      Paint()..color = Colors.white.withAlpha(240)..style = PaintingStyle.fill);
  }

  // ═══════════════════════════════════════════════════════════
  // AKTİF LAZER IŞINLARI
  // ═══════════════════════════════════════════════════════════

  void _drawActiveLasers(Canvas canvas, Size size) {
    for (final laser in activeLasers) {
      final a = (laser.alpha * 255).round();
      if (a <= 0) continue;

      if (laser.isHorizontal) {
        _drawLaserBeam(canvas,
          from: Offset(0, laser.position),
          to:   Offset(size.width, laser.position),
          color: const Color(0xFFF97316),
          alpha: a);
      } else {
        _drawLaserBeam(canvas,
          from: Offset(laser.position, 0),
          to:   Offset(laser.position, size.height),
          color: const Color(0xFF06B6D4),
          alpha: a);
      }
    }
  }

  void _drawLaserBeam(Canvas canvas, {
    required Offset from,
    required Offset to,
    required Color color,
    required int alpha,
  }) {
    // Dış geniş glow
    canvas.drawLine(from, to,
      Paint()
        ..color = color.withAlpha((alpha * 0.3).round())
        ..strokeWidth = 24
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
        ..style = PaintingStyle.stroke);

    // Orta glow
    canvas.drawLine(from, to,
      Paint()
        ..color = color.withAlpha((alpha * 0.7).round())
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke);

    // Parlak çekirdek
    canvas.drawLine(from, to,
      Paint()
        ..color = Colors.white.withAlpha((alpha * 0.9).round())
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke);
  }

  // ── Taş — metalik gri ───────────────────────────────────────────────────

  void _drawStoneBrick(Canvas canvas, Rect rect, Brick brick) {
    const r = Radius.circular(6);
    final rrect = RRect.fromRectAndRadius(rect, r);

    // Metalik gradient: açık-koyu-açık (krom efekti)
    _p
      ..style  = PaintingStyle.fill
      ..shader = LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: const [
            Color(0xFF94A3B8),
            Color(0xFF475569),
            Color(0xFF334155),
            Color(0xFF64748B),
          ],
          stops: const [0.0, 0.35, 0.65, 1.0],
        ).createShader(rect);
    canvas.drawRRect(rrect, _p);
    _p.shader = null;

    // Dikey ışık çizgisi (metal yansıma)
    final shinePath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left + rect.width * 0.3, rect.top + 3, rect.width * 0.15, rect.height - 6),
        const Radius.circular(4),
      ));
    canvas.drawPath(shinePath,
      Paint()
        ..shader = LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.white.withAlpha(50), Colors.transparent],
          ).createShader(rect)
        ..style = PaintingStyle.fill);

    // Üst gloss
    _drawGloss(canvas, rect, r);

    // Hasar
    _drawDamageOverlay(canvas, rrect, brick.hpRatio);

    // Çerçeve
    _border.color = const Color(0xFF94A3B8).withAlpha(180);
    canvas.drawRRect(rrect, _border);
  }

  // ── Bomba — kırmızı + hedef işareti ────────────────────────────────────

  void _drawBombBrick(Canvas canvas, Rect rect, Brick brick) {
    const r = Radius.circular(8);
    final rrect = RRect.fromRectAndRadius(rect, r);

    const base  = AppColors.accent;
    const light = Color(0xFFFB7185);
    const dark  = Color(0xFF9F1239);

    // Daha güçlü kırmızı glow
    canvas.drawRRect(rrect,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 14)
        ..color = base.withAlpha((110 * brick.hpRatio).round()));

    // Gradient
    _p
      ..style  = PaintingStyle.fill
      ..shader = LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [light, base, dark],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(rect);
    canvas.drawRRect(rrect, _p);
    _p.shader = null;

    // Hedef dairesi
    _drawCrosshair(canvas, rect.center, rect.width * 0.28);

    // Üst gloss
    _drawGloss(canvas, rect, r);

    // Hasar
    _drawDamageOverlay(canvas, rrect, brick.hpRatio);

    // Çerçeve
    _border.color = light.withAlpha(210);
    canvas.drawRRect(rrect, _border);
  }

  // ── Çarpışma parlama efekti ──────────────────────────────────────────────

  void _drawHitFlash(Canvas canvas, Brick brick, Rect rect) {
    if (brick.hitFlashTimer <= 0) return;

    // t: 1.0 (yeni çarpışma) → 0.0 (söndü)
    final t = (brick.hitFlashTimer / 0.25).clamp(0.0, 1.0);

    // Tuğlaya özgü neon renk
    final flashColor = switch (brick.type) {
      BrickType.bomb       => const Color(0xFFFF6B9D),
      BrickType.stone      => const Color(0xFFCBD5E1),
      BrickType.triangle   => const Color(0xFF93C5FD),
      BrickType.chain      => const Color(0xFF5EEAD4),
      BrickType.shield     => const Color(0xFFFDE68A),
      BrickType.multiplier => const Color(0xFFF9A8D4),
      BrickType.laserH     => const Color(0xFFFDBA74),
      BrickType.laserV     => const Color(0xFF67E8F9),
      BrickType.boss       => const Color(0xFFFFD700),
      BrickType.normal     => Colors.white,
    };

    // Boss için daha büyük radius ve genişletilmiş flash
    final flashRadius = brick.type == BrickType.boss
        ? const Radius.circular(12)
        : const Radius.circular(8);

    final rrect = RRect.fromRectAndRadius(rect, flashRadius);

    // 1. Dış genişleyen neon halo — büyükçe blur, hızla söner
    final haloExpand = (1.0 - t) * 8; // t=1'de 0px, t=0'da 8px dışa taşar
    final haloRect = rect.inflate(haloExpand);
    canvas.drawRRect(
      RRect.fromRectAndRadius(haloRect, const Radius.circular(14)),
      Paint()
        ..maskFilter = MaskFilter.blur(BlurStyle.outer, 14 * t + 4)
        ..color = flashColor.withAlpha((200 * t).round()),
    );

    // 2. İç beyaz flaş — tuğlanın üzerinde parlak beyaz overlay
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white.withAlpha((120 * t).round())
        ..style = PaintingStyle.fill,
    );

    // 3. Parlak kenarlık halkası
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = flashColor.withAlpha((255 * t).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = brick.type == BrickType.boss ? 3.5 : 2.5,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // BOSS TUĞLA — Retro-Futurism × HUD Sci-Fi FUI
  // ═══════════════════════════════════════════════════════════

  void _drawBossBrick(Canvas canvas, Rect rect, Brick brick) {
    const r = Radius.circular(12);
    final rrect = RRect.fromRectAndRadius(rect, r);
    final phase = brick.hpRatio;

    // ── HP fazına göre renk paleti ────────────────────────────
    final Color glowColor, colorLight, colorMid, colorDark;
    if (phase > 0.66) {
      // Altın Hükümdar
      glowColor   = const Color(0xFFD97706);
      colorLight  = const Color(0xFFFDE68A);
      colorMid    = const Color(0xFFF59E0B);
      colorDark   = const Color(0xFF78350F);
    } else if (phase > 0.33) {
      // Kızgın Canavar
      glowColor   = const Color(0xFFEF4444);
      colorLight  = const Color(0xFFFCA5A5);
      colorMid    = const Color(0xFFEF4444);
      colorDark   = const Color(0xFF7F1D1D);
    } else {
      // Son Nefes
      glowColor   = const Color(0xFFDC2626);
      colorLight  = const Color(0xFFFF6B6B);
      colorMid    = const Color(0xFFDC2626);
      colorDark   = const Color(0xFF450A0A);
    }

    // 1. Üçlü dış glow — dramatik varlık
    canvas.drawRRect(rrect,
      Paint()
        ..maskFilter = MaskFilter.blur(BlurStyle.outer, 28 * phase + 8)
        ..color = glowColor.withAlpha((150 * phase + 40).round()));
    canvas.drawRRect(rrect,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 10)
        ..color = colorLight.withAlpha(70));
    canvas.drawRRect(rrect,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 3)
        ..color = Colors.white.withAlpha(30));

    // 2. Derin void zemin — köşegen gradient
    _p
      ..style  = PaintingStyle.fill
      ..shader = LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: const [
            Color(0xFF1A0A2E),
            Color(0xFF0D0D1A),
            Color(0xFF150505),
          ],
        ).createShader(rect);
    canvas.drawRRect(rrect, _p);
    _p.shader = null;

    // 3. Arka plan ızgara deseni (Retro-Futurism)
    _drawBossGridPattern(canvas, rect, rrect);

    // 4. Merkezi radyal enerji — HP renkli
    _p
      ..style  = PaintingStyle.fill
      ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.8,
          colors: [colorMid.withAlpha((55 * phase).round()), Colors.transparent],
        ).createShader(rect);
    canvas.drawRRect(rrect, _p);
    _p.shader = null;

    // 5. Köşe HUD bracket'ları
    _drawBossHudBrackets(canvas, rect, colorLight);

    // 6. Merkezi boss runu
    _drawBossRune(canvas, rect, colorLight, colorMid, colorDark, phase);

    // 7. HP enerji çubuğu (alt kenar)
    _drawBossHpBar(canvas, rect, phase, glowColor, colorLight);

    // 8. HP sayısı (büyük, stilize)
    _drawBossHpLabel(canvas, rect, brick);

    // 9. "BOSS" etiketi (üst-orta)
    _drawBossLabel(canvas, rect, colorLight);

    // 10. Tarama çizgileri — CRT efekti
    _drawScanLines(canvas, rect, rrect);

    // 11. Hasar karartması + çatlaklar
    _drawBossDamageOverlay(canvas, rrect, phase);

    // 12. Çift kenarlık — metalik dış + renkli iç
    canvas.drawRRect(rrect,
      Paint()
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color       = const Color(0xFF0D0D1A));
    canvas.drawRRect(RRect.fromRectAndRadius(rect.deflate(2), r),
      Paint()
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color       = colorLight.withAlpha(180));
  }

  // ── Boss: Arka plan ızgara deseni ───────────────────────────────────────

  void _drawBossGridPattern(Canvas canvas, Rect rect, RRect rrect) {
    canvas.save();
    canvas.clipRRect(rrect);

    final gridPaint = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color       = const Color(0xFF3D1F5E).withAlpha(55);

    const divisions = 8;
    final hStep = rect.height / divisions;
    final vStep = rect.width  / divisions;

    for (int i = 1; i < divisions; i++) {
      final y = rect.top  + i * hStep;
      final x = rect.left + i * vStep;
      canvas.drawLine(Offset(rect.left,  y), Offset(rect.right, y), gridPaint);
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), gridPaint);
    }

    canvas.restore();
  }

  // ── Boss: Köşe HUD bracket'ları ─────────────────────────────────────────

  void _drawBossHudBrackets(Canvas canvas, Rect rect, Color color) {
    final bs = rect.width * 0.11; // bracket boyutu
    final p  = Paint()
      ..style     = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color     = color.withAlpha(170)
      ..strokeCap = StrokeCap.square;
    const margin = 7.0;

    // Sol-üst
    canvas.drawLine(Offset(rect.left + margin, rect.top + margin + bs),
                    Offset(rect.left + margin, rect.top + margin), p);
    canvas.drawLine(Offset(rect.left + margin, rect.top + margin),
                    Offset(rect.left + margin + bs, rect.top + margin), p);
    // Sağ-üst
    canvas.drawLine(Offset(rect.right - margin - bs, rect.top + margin),
                    Offset(rect.right - margin, rect.top + margin), p);
    canvas.drawLine(Offset(rect.right - margin, rect.top + margin),
                    Offset(rect.right - margin, rect.top + margin + bs), p);
    // Sol-alt
    canvas.drawLine(Offset(rect.left + margin, rect.bottom - margin - bs),
                    Offset(rect.left + margin, rect.bottom - margin), p);
    canvas.drawLine(Offset(rect.left + margin, rect.bottom - margin),
                    Offset(rect.left + margin + bs, rect.bottom - margin), p);
    // Sağ-alt
    canvas.drawLine(Offset(rect.right - margin, rect.bottom - margin - bs),
                    Offset(rect.right - margin, rect.bottom - margin), p);
    canvas.drawLine(Offset(rect.right - margin, rect.bottom - margin),
                    Offset(rect.right - margin - bs, rect.bottom - margin), p);
  }

  // ── Boss: Merkezi rün (Karanlık Mühür) ──────────────────────────────────

  void _drawBossRune(Canvas canvas, Rect rect, Color light, Color mid, Color dark, double phase) {
    final cx       = rect.center.dx;
    final cy       = rect.center.dy - rect.height * 0.04; // hafif yukarı
    final outerR   = rect.width * 0.30;
    final innerR   = outerR * 0.56;
    final orbR     = outerR * 0.24;

    // Sekizgen dış çerçeve
    final octPath = _buildPolygon(cx, cy, outerR, 8, pi / 8);
    canvas.drawPath(octPath,
      Paint()
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color       = light.withAlpha(130));

    // Sekizgenin köşelerine küçük tick işaretleri
    for (int i = 0; i < 8; i++) {
      final angle  = pi / 8 + i * pi / 4;
      final inner  = outerR * 0.84;
      final outer2 = outerR * 1.0;
      canvas.drawLine(
        Offset(cx + inner  * cos(angle), cy + inner  * sin(angle)),
        Offset(cx + outer2 * cos(angle), cy + outer2 * sin(angle)),
        Paint()..strokeWidth = 1.2..color = mid.withAlpha(160)..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round,
      );
    }

    // 6 ışın (hex köşe → sekizgen arasında)
    for (int i = 0; i < 6; i++) {
      final angle = i * pi / 3;
      canvas.drawLine(
        Offset(cx + innerR * 0.88 * cos(angle), cy + innerR * 0.88 * sin(angle)),
        Offset(cx + outerR * 0.78 * cos(angle), cy + outerR * 0.78 * sin(angle)),
        Paint()
          ..strokeWidth = 1.8
          ..color       = mid.withAlpha(190)
          ..style       = PaintingStyle.stroke
          ..strokeCap   = StrokeCap.round,
      );
    }

    // Altıgen iç çerçeve
    final hexPath = _buildPolygon(cx, cy, innerR, 6, 0);
    canvas.drawPath(hexPath,
      Paint()
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color       = mid.withAlpha(150));

    // İç çift daire
    canvas.drawCircle(Offset(cx, cy), orbR * 1.55,
      Paint()
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color       = light.withAlpha(80));
    canvas.drawCircle(Offset(cx, cy), orbR * 1.2,
      Paint()
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color       = mid.withAlpha(100));

    // Merkezi enerji orbu — glow
    canvas.drawCircle(Offset(cx, cy), orbR + 4,
      Paint()
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10)
        ..color      = mid.withAlpha((160 * phase).round()));

    // Orb gövdesi — radyal gradient
    _p
      ..style  = PaintingStyle.fill
      ..shader = RadialGradient(
          colors: [light, mid, dark],
          stops:  const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: orbR));
    canvas.drawCircle(Offset(cx, cy), orbR, _p);
    _p.shader = null;

    // Orb içi parlama noktası
    canvas.drawCircle(
      Offset(cx - orbR * 0.28, cy - orbR * 0.32),
      orbR * 0.28,
      Paint()..color = Colors.white.withAlpha(130)..style = PaintingStyle.fill,
    );

    // Merkez artı imi
    final cl = orbR * 0.55;
    final cp = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color       = Colors.white.withAlpha(200)
      ..strokeCap   = StrokeCap.round;
    canvas.drawLine(Offset(cx - cl, cy), Offset(cx + cl, cy), cp);
    canvas.drawLine(Offset(cx, cy - cl), Offset(cx, cy + cl), cp);

    // Köşegen çizgiler (daha hafif)
    final dl = cl * 0.65;
    final dp = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color       = light.withAlpha(110);
    canvas.drawLine(Offset(cx - dl, cy - dl), Offset(cx + dl, cy + dl), dp);
    canvas.drawLine(Offset(cx + dl, cy - dl), Offset(cx - dl, cy + dl), dp);
  }

  // ── Boss: HP enerji çubuğu ───────────────────────────────────────────────

  void _drawBossHpBar(Canvas canvas, Rect rect, double phase, Color glow, Color light) {
    const barH   = 5.0;
    const margin = 14.0;
    const segCount = 5;
    final barY    = rect.bottom - barH - 12;
    final barLeft = rect.left  + margin;
    final barW    = rect.width - margin * 2;

    // Arka plan
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(barLeft, barY, barW, barH), const Radius.circular(3)),
      Paint()..color = Colors.black.withAlpha(140)..style = PaintingStyle.fill);

    // Dolu kısım
    final fillW = barW * phase;
    if (fillW > 0) {
      // İç glow
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(barLeft, barY, fillW, barH), const Radius.circular(3)),
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
          ..color      = glow.withAlpha(120));
      // Gradient dolgu
      _p
        ..style  = PaintingStyle.fill
        ..shader = LinearGradient(colors: [light, glow])
            .createShader(Rect.fromLTWH(barLeft, barY, fillW, barH));
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(barLeft, barY, fillW, barH), const Radius.circular(3)),
        _p);
      _p.shader = null;
    }

    // Segment ayraçları
    final segW = barW / segCount;
    final segPaint = Paint()..color = Colors.black.withAlpha(160)..strokeWidth = 1.5
                            ..style = PaintingStyle.stroke;
    for (int i = 1; i < segCount; i++) {
      final x = barLeft + i * segW;
      canvas.drawLine(Offset(x, barY), Offset(x, barY + barH), segPaint);
    }

    // Çerçeve
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(barLeft, barY, barW, barH), const Radius.circular(3)),
      Paint()..color = glow.withAlpha(90)..style = PaintingStyle.stroke..strokeWidth = 1.0);
  }

  // ── Boss: Büyük HP sayısı ────────────────────────────────────────────────

  void _drawBossHpLabel(Canvas canvas, Rect rect, Brick brick) {
    final text = brick.hp > 9999 ? '${brick.hp ~/ 1000}k' : '${brick.hp}';
    final cy   = rect.center.dy + rect.height * 0.20;

    final tp = TextPainter(
      text: TextSpan(text: text, style: const TextStyle(
        color: Colors.white, fontSize: 18,
        fontWeight: FontWeight.w900, fontFamily: 'monospace',
      )),
      textDirection: TextDirection.ltr,
    )..layout();

    // Gölge
    final shadow = TextPainter(
      text: TextSpan(text: text, style: TextStyle(
        color: Colors.black.withAlpha(160), fontSize: 18,
        fontWeight: FontWeight.w900, fontFamily: 'monospace',
      )),
      textDirection: TextDirection.ltr,
    )..layout();
    shadow.paint(canvas, Offset(rect.center.dx - shadow.width / 2 + 1, cy - shadow.height / 2 + 1));

    tp.paint(canvas, Offset(rect.center.dx - tp.width / 2, cy - tp.height / 2));
  }

  // ── Boss: "BOSS" etiketi ─────────────────────────────────────────────────

  void _drawBossLabel(Canvas canvas, Rect rect, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: 'BOSS',
        style: TextStyle(
          color: color.withAlpha(210),
          fontSize: 11,
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
          letterSpacing: 3.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Üst-orta konuma yerleştir, HUD bracket'ın altına
    tp.paint(canvas,
      Offset(rect.center.dx - tp.width / 2, rect.top + 14));
  }

  // ── Boss: CRT tarama çizgileri ───────────────────────────────────────────

  void _drawScanLines(Canvas canvas, Rect rect, RRect rrect) {
    canvas.save();
    canvas.clipRRect(rrect);

    final scanPaint = Paint()
      ..color = Colors.black.withAlpha(18)
      ..style = PaintingStyle.fill;

    var y = rect.top;
    while (y < rect.bottom) {
      canvas.drawRect(Rect.fromLTWH(rect.left, y, rect.width, 1.5), scanPaint);
      y += 4.0;
    }

    canvas.restore();
  }

  // ── Boss: Hasar karartması + çatlak ağı ─────────────────────────────────

  void _drawBossDamageOverlay(Canvas canvas, RRect rrect, double phase) {
    if (phase >= 0.7) return;

    // Karartma katmanı
    final alpha = ((1 - phase) * 100).round();
    canvas.drawRRect(rrect,
      Paint()..color = Colors.black.withAlpha(alpha)..style = PaintingStyle.fill);

    if (phase < 0.5) {
      final crackPaint = Paint()
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color       = Colors.white.withAlpha(35);

      final cx = rrect.left + rrect.width  * 0.5;
      final cy = rrect.top  + rrect.height * 0.5;

      // Sağ çatlak
      canvas.drawPath(
        Path()
          ..moveTo(cx + 8,  rrect.top + 10)
          ..lineTo(cx + 2,  cy - 5)
          ..lineTo(cx + 14, cy + 10)
          ..lineTo(cx + 4,  rrect.bottom - 12),
        crackPaint);

      // Sol çatlak
      canvas.drawPath(
        Path()
          ..moveTo(cx - 12, rrect.top + 20)
          ..lineTo(cx - 4,  cy)
          ..lineTo(cx - 16, cy + 12)
          ..lineTo(cx - 6,  rrect.bottom - 15),
        crackPaint);

      if (phase < 0.25) {
        // Diyagonal parçalanma çizgileri
        canvas.drawPath(
          Path()
            ..moveTo(rrect.left + 12,  rrect.top + 30)
            ..lineTo(cx - 2, cy + 5)
            ..lineTo(cx + 18, cy - 8),
          crackPaint..color = Colors.white.withAlpha(25));
      }
    }
  }

  // ── Yardımcı: Düzenli çokgen yolu ───────────────────────────────────────

  Path _buildPolygon(double cx, double cy, double radius, int sides, double startAngle) {
    final path = Path();
    for (int i = 0; i < sides; i++) {
      final angle = startAngle + i * 2 * pi / sides;
      final x = cx + radius * cos(angle);
      final y = cy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  // ── Ortak yardımcılar ────────────────────────────────────────────────────

  void _drawGloss(Canvas canvas, Rect rect, Radius r) {
    final glossRect = Rect.fromLTWH(
      rect.left + 4, rect.top + 3,
      rect.width - 8, rect.height * 0.38,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(glossRect, r),
      Paint()
        ..shader = LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.white.withAlpha(55), Colors.white.withAlpha(0)],
          ).createShader(glossRect)
        ..style = PaintingStyle.fill,
    );
  }

  void _drawDamageOverlay(Canvas canvas, RRect rrect, double hpRatio) {
    if (hpRatio >= 0.6) return;
    final alpha = ((1 - hpRatio) * 90).round();
    canvas.drawRRect(rrect,
      Paint()..color = Colors.black.withAlpha(alpha)..style = PaintingStyle.fill);

    // Çatlak çizgisi (iki eğri çizgi)
    if (hpRatio < 0.4) {
      final crackPaint = Paint()
        ..color = Colors.white.withAlpha(40)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      final cx = rrect.left + rrect.width * 0.5;
      final cy = rrect.top  + rrect.height * 0.5;
      final path = Path()
        ..moveTo(cx - 4, rrect.top + 4)
        ..lineTo(cx + 2, cy)
        ..lineTo(cx - 6, rrect.bottom - 4);
      canvas.drawPath(path, crackPaint);
    }
  }

  void _drawCrosshair(Canvas canvas, Offset center, double radius) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withAlpha(80);
    canvas.drawCircle(center, radius, p);
    canvas.drawCircle(center, radius * 0.5, p);
    final half = radius * 1.3;
    canvas.drawLine(center - Offset(half, 0), center + Offset(half, 0), p);
    canvas.drawLine(center - Offset(0, half), center + Offset(0, half), p);
  }

  Color _hpColor(Brick brick) {
    final r = brick.hpRatio;
    // Daha canlı renk skalası — koyu arkaplan üzerinde görünür olsun
    if (r > 0.66) return const Color(0xFF9D5FFF); // parlak mor (arkaplanla daha az kaynaşır)
    if (r > 0.33) return AppColors.brickColors[2]; // yeşil
    return AppColors.brickColors[4];               // kırmızı
  }

  Color _darken(Color c, double amount) {
    final r = ((c.r * 255) * (1 - amount)).round().clamp(0, 255);
    final g = ((c.g * 255) * (1 - amount)).round().clamp(0, 255);
    final b = ((c.b * 255) * (1 - amount)).round().clamp(0, 255);
    return Color.fromARGB(((c.a * 255).round()), r, g, b);
  }

  Color _lighten(Color c, double amount) {
    final cr = (c.r * 255).round();
    final cg = (c.g * 255).round();
    final cb = (c.b * 255).round();
    final r = (cr + (255 - cr) * amount).round().clamp(0, 255);
    final g = (cg + (255 - cg) * amount).round().clamp(0, 255);
    final b = (cb + (255 - cb) * amount).round().clamp(0, 255);
    return Color.fromARGB((c.a * 255).round(), r, g, b);
  }

  // ── HP Yazısı ────────────────────────────────────────────────────────────

  void _drawHpLabel(Canvas canvas, Brick brick, Rect rect) {
    final text = brick.hp > 999 ? '${brick.hp ~/ 1000}k' : '${brick.hp}';
    final fontSize = rect.width < 50 ? 11.0 : 13.0;

    // Çoğaltıcıda "×2", boss'ta özel HP çizimi var — standart etiketi gizle
    if (brick.type == BrickType.multiplier) return;
    if (brick.type == BrickType.boss) return;
    const dy = 0.0;

    // Gölge
    final shadow = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.black.withAlpha(120),
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    shadow.paint(canvas,
      rect.center + Offset(-shadow.width / 2 + 1, -shadow.height / 2 + dy + 1));

    // Asıl metin
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
      rect.center + Offset(-tp.width / 2, -tp.height / 2 + dy));
  }

  // ═══════════════════════════════════════════════════════════
  // POWER-UP HÜCRELERİ — Retro-Futurism × OLED Dark
  // ═══════════════════════════════════════════════════════════

  void _drawPowerUpCells(Canvas canvas) {
    for (final cell in state.powerUpCells) {
      if (cell.isCollected) continue;
      final center = cell.centerFor(
        brickSize: BrickConfig.size,
        brickGap:  BrickConfig.gap,
        padding:   BrickConfig.padding,
        topOffset: BrickConfig.topOffset,
      );
      _drawPowerUpCell(canvas, center, cell.type);
    }
  }

  void _drawPowerUpCell(Canvas canvas, Offset center, PowerUpType type) {
    const cr = PowerUpCell.radius;

    // ── Türe göre renk paleti ──────────────────────────────────────────────
    final (Color glowColor, Color lightColor, Color darkColor) = switch (type) {
      PowerUpType.fireball   => (const Color(0xFFEF4444), const Color(0xFFFF6B6B), const Color(0xFF7F1D1D)),
      PowerUpType.nuke       => (const Color(0xFF8B5CF6), const Color(0xFFA78BFA), const Color(0xFF4C1D95)),
      PowerUpType.multiBall  => (const Color(0xFF06B6D4), const Color(0xFF67E8F9), const Color(0xFF0E7490)),
      PowerUpType.speedBoost => (const Color(0xFFFBBF24), const Color(0xFFFDE68A), const Color(0xFF92400E)),
      PowerUpType.shieldRow  => (const Color(0xFF3B82F6), const Color(0xFF93C5FD), const Color(0xFF1E3A5F)),
    };

    // 1. Geniş dış glow hâlesi
    canvas.drawCircle(center, cr + 8,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18)
        ..color = glowColor.withAlpha(90));

    // 2. Dar iç glow
    canvas.drawCircle(center, cr + 2,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
        ..color = glowColor.withAlpha(140));

    // 3. Arka plan: radyal gradient (merkez aydınlık → kenar derin karanlık)
    _p
      ..style  = PaintingStyle.fill
      ..shader = RadialGradient(
          colors: [lightColor.withAlpha(210), darkColor],
          stops:  const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: cr));
    canvas.drawCircle(center, cr, _p);
    _p.shader = null;

    // 4. Dış halka (ana çerçeve)
    canvas.drawCircle(center, cr,
      Paint()
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color       = lightColor.withAlpha(210));

    // 5. İkincil iç halka (derinlik)
    canvas.drawCircle(center, cr * 0.75,
      Paint()
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color       = lightColor.withAlpha(70));

    // 6. Orbit noktaları: 4 köşede küçük parlak nokta (HUD bracket hissi)
    final orbitR = cr + 4.0;
    for (int i = 0; i < 4; i++) {
      final angle = pi / 4 + i * pi / 2;
      canvas.drawCircle(
        Offset(center.dx + orbitR * cos(angle), center.dy + orbitR * sin(angle)),
        2.2,
        Paint()..color = lightColor.withAlpha(230)..style = PaintingStyle.fill);
    }

    // 7. Türe özel geometrik ikon
    switch (type) {
      case PowerUpType.fireball:   _drawFireballIcon(canvas, center, cr);
      case PowerUpType.nuke:       _drawNukeIcon(canvas, center, cr);
      case PowerUpType.multiBall:  _drawMultiBallIcon(canvas, center, cr);
      case PowerUpType.speedBoost: _drawSpeedBoostIcon(canvas, center, cr);
      case PowerUpType.shieldRow:  _drawShieldRowIcon(canvas, center, cr);
    }
  }

  // ── Fireball: katmanlı alev üçgeni + merkez orb ─────────────────────────

  void _drawFireballIcon(Canvas canvas, Offset c, double cr) {
    final s = cr / 17.0;

    // Dış alev (büyük üçgen — yarı saydam)
    final outerFlame = Path()
      ..moveTo(c.dx,         c.dy - 12 * s)
      ..lineTo(c.dx + 8 * s, c.dy + 5  * s)
      ..lineTo(c.dx - 8 * s, c.dy + 5  * s)
      ..close();
    canvas.drawPath(outerFlame,
      Paint()..color = Colors.white.withAlpha(155)..style = PaintingStyle.fill);

    // İç alev (küçük üçgen — daha parlak)
    final innerFlame = Path()
      ..moveTo(c.dx,         c.dy - 7 * s)
      ..lineTo(c.dx + 5 * s, c.dy + 4 * s)
      ..lineTo(c.dx - 5 * s, c.dy + 4 * s)
      ..close();
    canvas.drawPath(innerFlame,
      Paint()..color = Colors.white.withAlpha(240)..style = PaintingStyle.fill);

    // Alev çekirdeği orb — merkez parlak nokta
    canvas.drawCircle(Offset(c.dx, c.dy + 2 * s), 3.5 * s,
      Paint()..color = Colors.white..style = PaintingStyle.fill);
    // İç glint
    canvas.drawCircle(Offset(c.dx - 1 * s, c.dy + 1 * s), 1.2 * s,
      Paint()..color = Colors.white.withAlpha(180)..style = PaintingStyle.fill);
  }

  // ── Nuke: merkez daire + 6 patlama ışını ────────────────────────────────

  void _drawNukeIcon(Canvas canvas, Offset c, double cr) {
    final s = cr / 17.0;
    final rayPaint = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 1.8 * s
      ..color       = Colors.white.withAlpha(210)
      ..strokeCap   = StrokeCap.round;

    // 6 ışın (60° aralıklı)
    for (int i = 0; i < 6; i++) {
      final angle = i * pi / 3;
      final from  = Offset(c.dx + 5.5 * s * cos(angle), c.dy + 5.5 * s * sin(angle));
      final to    = Offset(c.dx + 12  * s * cos(angle), c.dy + 12  * s * sin(angle));
      canvas.drawLine(from, to, rayPaint);
      // Işın ucunda küçük nokta
      canvas.drawCircle(to, 1.6 * s,
        Paint()..color = Colors.white.withAlpha(240)..style = PaintingStyle.fill);
    }

    // Merkez enerji orbu (dolu daire)
    canvas.drawCircle(c, 4.5 * s,
      Paint()..color = Colors.white..style = PaintingStyle.fill);
    // İç boşluk (derinlik)
    canvas.drawCircle(c, 2.2 * s,
      Paint()..color = Colors.white.withAlpha(60)..style = PaintingStyle.fill);
  }

  // ── Multi-Ball: 3 daire üçgen dizisi + bağlantı çizgileri ───────────────

  void _drawMultiBallIcon(Canvas canvas, Offset c, double cr) {
    final s      = cr / 17.0;
    final ballR  = 3.8 * s;

    final positions = [
      Offset(c.dx,          c.dy - 7   * s), // üst
      Offset(c.dx - 6.5 * s, c.dy + 5 * s), // sol-alt
      Offset(c.dx + 6.5 * s, c.dy + 5 * s), // sağ-alt
    ];

    // Bağlantı çizgileri (önce çiz, topların altında kalsın)
    final linePaint = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 1.0 * s
      ..color       = Colors.white.withAlpha(80);
    canvas.drawLine(positions[0], positions[1], linePaint);
    canvas.drawLine(positions[1], positions[2], linePaint);
    canvas.drawLine(positions[2], positions[0], linePaint);

    // Toplar
    for (final pos in positions) {
      canvas.drawCircle(pos, ballR,
        Paint()..color = Colors.white..style = PaintingStyle.fill);
      // Parlak üst glint
      canvas.drawCircle(
        Offset(pos.dx - ballR * 0.3, pos.dy - ballR * 0.3),
        ballR * 0.35,
        Paint()..color = Colors.white.withAlpha(160)..style = PaintingStyle.fill);
    }
  }

  // ── Speed Boost: çift sağa-bakan şerit (>>) ─────────────────────────────

  void _drawSpeedBoostIcon(Canvas canvas, Offset c, double cr) {
    final s  = cr / 17.0;
    final cp = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 2.2 * s
      ..color       = Colors.white.withAlpha(235)
      ..strokeJoin  = StrokeJoin.round
      ..strokeCap   = StrokeCap.round;

    // Sol şerit (>)
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - 7 * s, c.dy - 8 * s)
        ..lineTo(c.dx - 1 * s, c.dy)
        ..lineTo(c.dx - 7 * s, c.dy + 8 * s),
      cp,
    );

    // Sağ şerit (>>) — biraz sağda, tam parlak
    canvas.drawPath(
      Path()
        ..moveTo(c.dx + 0 * s, c.dy - 8 * s)
        ..lineTo(c.dx + 6 * s, c.dy)
        ..lineTo(c.dx + 0 * s, c.dy + 8 * s),
      cp..color = Colors.white,
    );
  }

  // ── Shield Row: kalkan şekli + yatay orta çizgi ─────────────────────────

  void _drawShieldRowIcon(Canvas canvas, Offset c, double cr) {
    final s  = cr / 17.0;
    final sp = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 1.8 * s
      ..color       = Colors.white.withAlpha(225)
      ..strokeJoin  = StrokeJoin.round
      ..strokeCap   = StrokeCap.round;

    // Klasik kalkan outline
    final shield = Path()
      ..moveTo(c.dx - 8 * s, c.dy - 9  * s)  // sol-üst köşe
      ..lineTo(c.dx + 8 * s, c.dy - 9  * s)  // sağ-üst köşe
      ..lineTo(c.dx + 8 * s, c.dy + 1  * s)  // sağ kenar
      ..quadraticBezierTo(
          c.dx + 8 * s, c.dy + 9  * s,
          c.dx,         c.dy + 12 * s)        // sağ-alt kavis → uç
      ..quadraticBezierTo(
          c.dx - 8 * s, c.dy + 9  * s,
          c.dx - 8 * s, c.dy + 1  * s)        // sol-alt kavis
      ..close();
    canvas.drawPath(shield, sp);

    // Yatay bölme çizgisi (kalkanı üst/alt ayırır)
    canvas.drawLine(
      Offset(c.dx - 6 * s, c.dy + 1 * s),
      Offset(c.dx + 6 * s, c.dy + 1 * s),
      Paint()
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 1.5 * s
        ..color       = Colors.white.withAlpha(180)
        ..strokeCap   = StrokeCap.round,
    );

    // Küçük merkez parlama noktası (kalkanda mücevher gibi)
    canvas.drawCircle(Offset(c.dx, c.dy - 3 * s), 1.8 * s,
      Paint()..color = Colors.white.withAlpha(200)..style = PaintingStyle.fill);
  }

  // ═══════════════════════════════════════════════════════════
  // BONUS TOPLAR
  // ═══════════════════════════════════════════════════════════

  void _drawBonusBalls(Canvas canvas) {
    for (final bonus in state.bonusBalls) {
      if (bonus.isCollected) continue;
      final center = bonus.centerFor(
        brickSize: BrickConfig.size, brickGap: BrickConfig.gap,
        padding: BrickConfig.padding, topOffset: BrickConfig.topOffset,
      );
      const cr = BonusBall.radius;

      final isMinus = bonus.type == BonusBallType.minus;
      final glowColor   = isMinus ? const Color(0xFFFF2244) : AppColors.success;
      final gradColors  = isMinus
          ? const [Color(0xFFFF5577), Color(0xFFCC0033)]
          : const [Color(0xFF4ADE80), Color(0xFF16A34A)];

      // Dış glow
      canvas.drawCircle(center, cr + 6,
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
          ..color = glowColor.withAlpha(100));

      // Gradient dolgu
      _p
        ..style  = PaintingStyle.fill
        ..shader = RadialGradient(colors: gradColors)
            .createShader(Rect.fromCircle(center: center, radius: cr));
      canvas.drawCircle(center, cr, _p);
      _p.shader = null;

      // Üst gloss
      canvas.drawCircle(
        center - Offset(cr * 0.2, cr * 0.3), cr * 0.4,
        Paint()..color = Colors.white.withAlpha(55)..style = PaintingStyle.fill);

      // + veya − işareti
      final lp = Paint()
        ..color = Colors.white..strokeWidth = 2.2
        ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
      final h = cr * 0.5;
      canvas.drawLine(center - Offset(h, 0), center + Offset(h, 0), lp);
      if (!isMinus) {
        canvas.drawLine(center - Offset(0, h), center + Offset(0, h), lp);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  // TOPLAR
  // ═══════════════════════════════════════════════════════════

  void _drawBalls(Canvas canvas) {
    for (final ball in state.balls) {
      if (!ball.isActive) continue;
      final pos = ball.position;
      final r   = ball.radius;

      // Comet trail (B stili: gradient kuyruk)
      _drawCometTrail(canvas, ball.trail);

      // Dış skin rengi glow
      canvas.drawCircle(pos, r + 3,
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7)
          ..color = skinPrimary.withAlpha(120));

      // Radyal gradient dolgu (skin renkleriyle)
      _p
        ..style  = PaintingStyle.fill
        ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.4),
            colors: [Colors.white, skinLight, skinPrimary],
          ).createShader(Rect.fromCircle(center: pos, radius: r));
      canvas.drawCircle(pos, r, _p);
      _p.shader = null;

      // Parlama noktası
      canvas.drawCircle(
        pos - Offset(r * 0.25, r * 0.3), r * 0.3,
        Paint()..color = Colors.white.withAlpha(200)..style = PaintingStyle.fill);
    }
  }

  /// Comet trail: eski pozisyonlardan yeniye doğru incelen gradient kuyruk.
  /// Son 2 nokta atlanır — top glow'uyla iç içe geçip boyut illüzyonu oluşmasın.
  void _drawCometTrail(Canvas canvas, List<Offset> trail) {
    if (trail.length < 2) return;
    final end = trail.length - 2; // son 2 nokta yok sayılır
    for (int i = 1; i < end; i++) {
      final t     = i / end;       // 0 = eski uç, 1 = topa yakın uç
      final p1    = trail[i - 1];
      final p2    = trail[i];
      final alpha = (t * 160).round().clamp(0, 255);
      final width = (t * 4.0).clamp(0.5, 4.0);

      canvas.drawLine(
        p1, p2,
        Paint()
          ..color      = skinLight.withAlpha(alpha)
          ..strokeWidth = width
          ..strokeCap  = StrokeCap.round,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // NİŞAN ÇİZGİSİ
  // ═══════════════════════════════════════════════════════════

  void _drawAimGuide(Canvas canvas, Size size) {
    if (aimAngle == null) return;
    final angle = aimAngle!;
    if (sin(angle) >= 0) return;

    final dotSpacing  = 18.0 * GameConstants.scaleFactor;
    final totalLength = (aimDragMagnitude * 5.0).clamp(200.0, size.height * 1.8);
    final dotCount    = (totalLength / dotSpacing).round();

    final launchPos = Offset(state.launchX, size.height);
    var   pos       = launchPos;
    var   vel       = Offset(cos(angle), sin(angle));
    int   bounces   = 0;

    for (int i = 0; i < dotCount; i++) {
      pos = pos + vel * dotSpacing;

      if (pos.dx - 3 <= 0) {
        pos = Offset(3, pos.dy);
        vel = Offset(-vel.dx, vel.dy);
        bounces++;
      } else if (pos.dx + 3 >= size.width) {
        pos = Offset(size.width - 3, pos.dy);
        vel = Offset(-vel.dx, vel.dy);
        bounces++;
      }
      if (pos.dy <= 4 || bounces > 3) break;

      final t     = i / dotCount;
      final alpha = ((1 - t * 0.85) * 230).round().clamp(0, 255);
      final dr    = (3.5 - t * 2.2).clamp(1.2, 3.5);

      // Neon nokta: glow + çekirdek
      canvas.drawCircle(pos, dr + 2,
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
          ..color = Colors.white.withAlpha((alpha * 0.4).round()));
      _aimPaint.color = Colors.white.withAlpha(alpha);
      canvas.drawCircle(pos, dr, _aimPaint);
    }

    // Ok ucu
    _drawArrowHead(canvas, pos, vel);
  }

  void _drawArrowHead(Canvas canvas, Offset tip, Offset dir) {
    if (tip.dy <= 16) return;
    final perp = Offset(-dir.dy, dir.dx);
    final left  = tip - dir * 9 + perp * 5;
    final right = tip - dir * 9 - perp * 5;

    canvas.drawPath(
      Path()..moveTo(tip.dx, tip.dy)..lineTo(left.dx, left.dy)..lineTo(right.dx, right.dy)..close(),
      Paint()..color = Colors.white.withAlpha(190)..style = PaintingStyle.fill,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TEHLİKE HALESI
  // ═══════════════════════════════════════════════════════════

  void _drawDangerHalo(Canvas canvas, Size size) {
    if (dangerFlash <= 0 || dangerLineY >= size.height) return;

    const red = Color(0xFFFF2244);
    final a   = dangerFlash; // 0..1

    // ── Yumuşak kırmızı arka plan bandı ───────────────────────────────────
    final bandH = 24.0 + a * 8;
    final bandRect = Rect.fromLTWH(0, dangerLineY - bandH * 0.5, size.width, bandH);
    canvas.drawRect(
      bandRect,
      Paint()
        ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, red.withAlpha((80 * a).round()), Colors.transparent],
          ).createShader(bandRect),
    );

    // ── Neon kırmızı çizgi ────────────────────────────────────────────────
    final lineRect = Rect.fromLTWH(0, dangerLineY - 1, size.width, 2);

    // Dış glow
    canvas.drawRect(
      lineRect.inflate(6),
      Paint()
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 + a * 6)
        ..color = red.withAlpha((160 * a).round()),
    );

    // Parlak çekirdek çizgi
    canvas.drawRect(
      lineRect,
      Paint()
        ..shader = LinearGradient(
            colors: [
              Colors.transparent,
              red.withAlpha((220 * a).round()),
              Colors.white.withAlpha((200 * a).round()),
              red.withAlpha((220 * a).round()),
              Colors.transparent,
            ],
            stops: const [0.0, 0.1, 0.5, 0.9, 1.0],
          ).createShader(lineRect),
    );

    // ── Sol & sağ köşe hale noktaları ─────────────────────────────────────
    for (final x in [0.0, size.width]) {
      canvas.drawCircle(
        Offset(x, dangerLineY),
        6 + a * 4,
        Paint()
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 + a * 4)
          ..color = red.withAlpha((180 * a).round()),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // FIRLATMA ZEMİNİ
  // ═══════════════════════════════════════════════════════════

  void _drawLaunchZone(Canvas canvas, Size size) {
    // Zemin çizgisi — gradient
    final lineRect = Rect.fromLTWH(0, size.height - 1, size.width, 1);
    canvas.drawRect(lineRect,
      Paint()
        ..shader = LinearGradient(
            colors: [Colors.transparent, AppColors.primary.withAlpha(150), Colors.transparent],
          ).createShader(lineRect));

    // Fırlatma noktası
    final lx = state.launchX;
    final ly = size.height - GameConstants.ballRadius - 2;

    canvas.drawCircle(Offset(lx, ly), GameConstants.ballRadius + 3,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7)
        ..color = skinPrimary.withAlpha(120));

    _p
      ..style  = PaintingStyle.fill
      ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: [Colors.white, skinLight, skinPrimary],
        ).createShader(Rect.fromCircle(center: Offset(lx, ly), radius: GameConstants.ballRadius));
    canvas.drawCircle(Offset(lx, ly), GameConstants.ballRadius, _p);
    _p.shader = null;
  }

  @override
  bool shouldRepaint(GamePainter _) => true;
}
