import 'dart:math';
import 'dart:ui';
import '../../models/ball.dart';
import '../../models/brick.dart';
import '../../models/bonus_ball.dart';
import '../../models/power_up_cell.dart';
import '../utils/constants.dart';
import 'collision_detector.dart';

class BallPhysicsConfig {
  final double speed;
  final double leftBound;
  final double rightBound;
  final double topBound;
  final double bottomBound;
  final double brickSize;
  final double brickGap;
  final double brickPadding;
  final double brickTopOffset;

  /// Fireball aktifken 3, normal turda 1.
  final int damageMultiplier;

  const BallPhysicsConfig({
    required this.speed,
    required this.leftBound,
    required this.rightBound,
    required this.topBound,
    required this.bottomBound,
    required this.brickSize,
    required this.brickGap,
    required this.brickPadding,
    required this.brickTopOffset,
    this.damageMultiplier = 1,
  });
}

/// Ateşlenen lazer bilgisi — görsel için controller'a aktarılır
class FiredLaser {
  final bool isHorizontal;
  final double position; // H için Y, V için X koordinatı

  const FiredLaser({required this.isHorizontal, required this.position});
}

class PhysicsTickResult {
  final List<Brick> hitBricks;              // bu tick'te vurulan tuğlalar
  final List<BonusBall> collected;          // bu tick'te toplanan bonuslar
  final List<PowerUpCell> collectedPowerUps;// bu tick'te toplanan power-up'lar
  final bool hitFloor;                      // top zemine değdi mi
  final int extraBalls;                     // multiplier tuğlasından gelen ekstra top
  final List<FiredLaser> firedLasers;       // bu tick'te ateşlenen lazerler
  final int wallBounces;                    // duvar/tavan sekmesi sayısı

  const PhysicsTickResult({
    required this.hitBricks,
    required this.collected,
    this.collectedPowerUps = const [],
    required this.hitFloor,
    this.extraBalls = 0,
    this.firedLasers = const [],
    this.wallBounces = 0,
  });
}

class BallPhysics {
  final CollisionDetector _detector;
  final Random _rng = Random();

  BallPhysics() : _detector = const CollisionDetector();

  /// Tek bir top için bir frame'lik fizik adımı.
  ///
  /// Tünel etkisini ve köşe gömülmesini önlemek için frame 3 eşit alt adıma
  /// bölünür.  Her alt adımda top ~3 px hareket eder; bu değer tuğla
  /// boşluğundan (4 px) küçük olduğundan top boşluktan geçemez.
  /// Aynı tuğla bir frame içinde yalnızca bir kez hasar alır.
  PhysicsTickResult tick(
    Ball ball,
    double dt,
    List<Brick> bricks,
    List<BonusBall> bonusBalls,
    BallPhysicsConfig config, {
    List<PowerUpCell> powerUpCells = const [],
  }) {
    if (!ball.isActive || ball.hasReturned) {
      return const PhysicsTickResult(
          hitBricks: [], collected: [], hitFloor: false);
    }

    final hitBricks           = <Brick>[];
    final collected           = <BonusBall>[];
    final collectedPowerUps   = <PowerUpCell>[];
    final firedLasers         = <FiredLaser>[];
    int   extraBalls          = 0;
    int   wallBounces         = 0;
    // Bu tick'te zaten vurulan tuğlalar tekrar hasar almasın
    final hitThisTick       = <Brick>{};

    const subSteps = 3;
    final subDt    = dt / subSteps;

    for (int step = 0; step < subSteps; step++) {
      // ── Hareketi uygula ──────────────────────────────────────────────────
      ball.position = ball.position + ball.velocity * subDt;

      // ── Duvar sekmeleri ──────────────────────────────────────────────────
      if (_detector.hitsLeftWall(ball, config.leftBound)) {
        ball.position = Offset(config.leftBound + ball.radius, ball.position.dy);
        ball.velocity = Offset(ball.velocity.dx.abs(), ball.velocity.dy);
        _ensureMinVerticalSpeed(ball);
        wallBounces++;
      }
      if (_detector.hitsRightWall(ball, config.rightBound)) {
        ball.position = Offset(config.rightBound - ball.radius, ball.position.dy);
        ball.velocity = Offset(-ball.velocity.dx.abs(), ball.velocity.dy);
        _ensureMinVerticalSpeed(ball);
        wallBounces++;
      }
      if (_detector.hitsCeiling(ball, config.topBound)) {
        ball.position = Offset(ball.position.dx, config.topBound + ball.radius);
        ball.velocity = Offset(ball.velocity.dx, ball.velocity.dy.abs());
        _ensureMinVerticalSpeed(ball);
        wallBounces++;
      }

      // ── Zemin: tur sonu ──────────────────────────────────────────────────
      if (_detector.hitsFloor(ball, config.bottomBound)) {
        ball.position = Offset(ball.position.dx, config.bottomBound - ball.radius);
        ball.velocity = Offset.zero;
        ball.isActive = false;
        ball.hasReturned = true;
        return PhysicsTickResult(
            hitBricks: hitBricks, collected: collected,
            collectedPowerUps: collectedPowerUps,
            hitFloor: true,
            firedLasers: firedLasers, wallBounces: wallBounces);
      }

      // ── Tuğla çarpışması (alt adım başına en fazla 1) ────────────────────
      for (final brick in bricks) {
        if (!brick.isAlive || hitThisTick.contains(brick)) continue;
        final result = _detector.checkBrickCollision(ball, brick);
        if (result == null) continue;

        // Üçgen: mesafeye dayalı çarpışma kontrolü
        if (brick.type == BrickType.triangle) {
          if (!_applyTriangleCollision(ball, brick, result.side)) continue;
        } else {
          _resolveVelocity(ball, result.side);
        }
        _ensureMinVerticalSpeed(ball);

        // Topun tuğlanın içine gömülmesini önle
        // Boss tuğla 2×2 hücre kapladığından büyük rect kullan
        final pushRect = brick.type == BrickType.boss ? brick.bossRect : brick.rect;
        _pushOut(ball, pushRect, result.side);

        // ── Lazer düğmesi: hasar almaz, top değdikçe ışın fırlatır ────────
        if (brick.type == BrickType.laserH || brick.type == BrickType.laserV) {
          brick.hitFlashTimer = 0.25;
          final isH = brick.type == BrickType.laserH;
          firedLasers.add(FiredLaser(
            isHorizontal: isH,
            position: isH ? brick.rect.center.dy : brick.rect.center.dx,
          ));
          for (final other in bricks) {
            if (!other.isAlive || other == brick) continue;
            if (other.type == BrickType.laserH || other.type == BrickType.laserV) continue;
            final matches = isH ? other.row == brick.row : other.col == brick.col;
            if (matches) {
              other.hit(1);
              hitBricks.add(other);
            }
          }
          hitThisTick.add(brick);
          break;
        }

        brick.hit(config.damageMultiplier);
        hitThisTick.add(brick);

        if (!brick.isAlive) {
          hitBricks.add(brick);

          // ── Bomba: komşuları vur ─────────────────────────────────────────
          if (brick.type == BrickType.bomb) {
            for (final other in bricks) {
              if (!other.isAlive || other == brick) continue;
              if (_isNeighbor(brick, other)) {
                other.hit(1);
                hitBricks.add(other);
              }
            }
          }

          // ── Zincir: rastgele bir tuğlaya hasar ver ───────────────────────
          if (brick.type == BrickType.chain) {
            final alive = bricks.where((b) => b.isAlive && b != brick).toList();
            if (alive.isNotEmpty) {
              final target = alive[_rng.nextInt(alive.length)];
              target.hit(1);
              hitBricks.add(target);
            }
          }

          // ── Çoğaltıcı: 2 ekstra top ──────────────────────────────────────
          if (brick.type == BrickType.multiplier) {
            extraBalls += 2;
          }
        } else {
          // Tuğla hayatta, ama vuruş kaydedildi (hasar ya da kalkan kırıldı)
          hitBricks.add(brick);
        }

        break; // alt adım başına tek tuğla çarpışması
      }

      // ── Bonus top toplama ─────────────────────────────────────────────────
      for (final bonus in bonusBalls) {
        if (_detector.checkBonusBallCollision(
          ball, bonus,
          brickSize: config.brickSize,
          brickGap:  config.brickGap,
          padding:   config.brickPadding,
          topOffset: config.brickTopOffset,
        )) {
          if (!bonus.isCollected) {
            bonus.isCollected = true;
            collected.add(bonus);
          }
        }
      }

      // ── Power-up hücre toplama ─────────────────────────────────────────
      for (final cell in powerUpCells) {
        if (cell.isCollected) continue;
        if (cell.collidesWithBall(
          ball.position, ball.radius,
          brickSize: config.brickSize,
          brickGap:  config.brickGap,
          padding:   config.brickPadding,
          topOffset: config.brickTopOffset,
        )) {
          cell.isCollected = true;
          collectedPowerUps.add(cell);
        }
      }
    }

    return PhysicsTickResult(
        hitBricks:          hitBricks,
        collected:          collected,
        collectedPowerUps:  collectedPowerUps,
        hitFloor:           false,
        extraBalls:         extraBalls,
        firedLasers:        firedLasers,
        wallBounces:        wallBounces);
  }

  // ── Yardımcılar ──────────────────────────────────────────────────────────

  /// Normal tuğla çarpışması — ekseni ters çevir
  void _resolveVelocity(Ball ball, CollisionSide side) {
    switch (side) {
      case CollisionSide.top:
      case CollisionSide.bottom:
        ball.velocity = Offset(ball.velocity.dx, -ball.velocity.dy);
      case CollisionSide.left:
      case CollisionSide.right:
        ball.velocity = Offset(-ball.velocity.dx, ball.velocity.dy);
      case CollisionSide.none:
        break;
    }
    _clampToTargetSpeed(ball);
  }

  /// Üçgen çarpışmasını uygular; false dönerse boş köşe, çarpışma yok.
  ///
  /// Hipotenüse olan imzalı mesafeye göre 3 durum:
  ///  1. Boş tarafta ve hipotenüsten uzak  → false (çarpışma yok)
  ///  2. Hipotenüse yakın (±radius)        → köşegen yansıma
  ///  3. Dolu alanda ve hipotenüsten uzak  → normal yüz yansıması
  bool _applyTriangleCollision(Ball ball, Brick brick, CollisionSide side) {
    final rect = brick.rect;
    final dx = ball.position.dx - rect.left; // yerel koordinat
    final dy = ball.position.dy - rect.top;
    final S  = rect.width; // kare tuğla (width == height)
    final r  = ball.radius;
    final orientation = brick.triangleOrientation ?? TriangleOrientation.slash;

    // İmzalı mesafe: pozitif = boş taraf, negatif = dolu taraf
    final double signedDist;
    if (orientation == TriangleOrientation.slash) {
      // "/" hipotenüs: dx + dy = S   (boş taraf: dx+dy > S)
      signedDist = (dx + dy - S) / sqrt(2.0);
    } else {
      // "\" hipotenüs: dy - dx = 0  (boş taraf: dy > dx)
      signedDist = (dy - dx) / sqrt(2.0);
    }

    if (signedDist > r + 2) {
      // Top boş köşede ve hipotenüsten uzak → çarpışma yok
      return false;
    }

    if (signedDist > -(r + 2)) {
      // Hipotenüse yakın (her iki taraftan) → köşegen yansıma
      final vx = ball.velocity.dx;
      final vy = ball.velocity.dy;
      switch (orientation) {
        case TriangleOrientation.slash:
          ball.velocity = Offset(-vy, -vx); // "/" normal: (1,1)/√2
        case TriangleOrientation.backslash:
          ball.velocity = Offset(vy, vx);   // "\" normal: (-1,1)/√2
      }
      _clampToTargetSpeed(ball);
    } else {
      // Dolu alanda, bacak kenara çarptı → normal yansıma
      _resolveVelocity(ball, side);
    }

    return true;
  }

  void _pushOut(Ball ball, Rect rect, CollisionSide side) {
    const epsilon = 0.5;
    switch (side) {
      case CollisionSide.top:
        ball.position = Offset(ball.position.dx, rect.top - ball.radius - epsilon);
      case CollisionSide.bottom:
        ball.position = Offset(ball.position.dx, rect.bottom + ball.radius + epsilon);
      case CollisionSide.left:
        ball.position = Offset(rect.left - ball.radius - epsilon, ball.position.dy);
      case CollisionSide.right:
        ball.position = Offset(rect.right + ball.radius + epsilon, ball.position.dy);
      case CollisionSide.none:
        break;
    }
  }

  /// Topun yatay kilitleme döngüsüne girmesini engeller.
  /// |vy| çok küçükse minimum dikey hız garantilenir.
  /// Eşik: toplam hızın %15'i (~90 px/s, yaklaşık 8.6° minimum açı)
  void _ensureMinVerticalSpeed(Ball ball) {
    final minVy = GameConstants.ballSpeed * 0.15;
    final vy = ball.velocity.dy;
    if (vy.abs() < minVy) {
      // Yön bilgisini koru; sıfırsa rastgele seç
      final sign = vy < 0 ? -1.0 : (vy > 0 ? 1.0 : (_rng.nextBool() ? 1.0 : -1.0));
      ball.velocity = Offset(ball.velocity.dx, sign * minVy);
      _clampToTargetSpeed(ball);
    }
  }

  void _clampToTargetSpeed(Ball ball) {
    final current = ball.velocity.distance;
    if (current == 0) return;
    final target = GameConstants.ballSpeed;
    if ((current - target).abs() > target * 0.05) {
      ball.velocity = ball.velocity / current * target;
    }
  }

  bool _isNeighbor(Brick a, Brick b) {
    final dc = (a.col - b.col).abs();
    final dr = (a.row - b.row).abs();
    return dc <= 1 && dr <= 1 && !(dc == 0 && dr == 0);
  }

  /// Nişan açısından hız vektörü üretir.
  static Offset velocityFromAngle(double angle, double speed) {
    final clamped = _clampAngle(angle);
    return Offset(cos(clamped) * speed, sin(clamped) * speed);
  }

  /// Açıyı yukarı yarım daireyle sınırlar (top aşağı gitmesin)
  static double _clampAngle(double angle) {
    const minAngle = -pi + 0.17; // ~10° sol duvardan
    const maxAngle = -0.17;      // ~10° sağ duvardan
    return angle.clamp(minAngle, maxAngle);
  }
}
