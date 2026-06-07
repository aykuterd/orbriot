import 'dart:math';
import 'dart:ui';
import '../../models/ball.dart';
import '../../models/brick.dart';
import '../../models/bonus_ball.dart';

enum CollisionSide { top, bottom, left, right, none }

class CollisionResult {
  final CollisionSide side;
  final Brick brick;

  const CollisionResult({required this.side, required this.brick});
}

class CollisionDetector {
  const CollisionDetector();

  // ── Duvar Çarpışmaları ───────────────────────────────────────────────────

  /// Sol/sağ duvar
  bool hitsLeftWall(Ball ball, double leftBound) =>
      ball.position.dx - ball.radius <= leftBound;

  bool hitsRightWall(Ball ball, double rightBound) =>
      ball.position.dx + ball.radius >= rightBound;

  /// Tavan
  bool hitsCeiling(Ball ball, double topBound) =>
      ball.position.dy - ball.radius <= topBound;

  /// Zemin — top dibe ulaştı, tura geri döner
  bool hitsFloor(Ball ball, double bottomBound) =>
      ball.position.dy + ball.radius >= bottomBound;

  // ── Tuğla AABB Çarpışması ────────────────────────────────────────────────

  /// Topun bir tuğlaya çarpıp çarpmadığını ve hangi yüzden çarptığını döner.
  CollisionResult? checkBrickCollision(Ball ball, Brick brick) {
    if (!brick.isAlive) return null;

    // Boss tuğla 2×2 hücre kaplar — büyük çarpışma alanı kullan
    final rect = brick.type == BrickType.boss ? brick.bossRect : brick.rect;
    final r = ball.radius;
    final pos = ball.position;

    // Geniş faz: AABB dışı ise erken çık
    if (pos.dx + r < rect.left ||
        pos.dx - r > rect.right ||
        pos.dy + r < rect.top ||
        pos.dy - r > rect.bottom) {
      return null;
    }

    // Tuğlanın en yakın noktası
    final closestX = pos.dx.clamp(rect.left, rect.right);
    final closestY = pos.dy.clamp(rect.top, rect.bottom);

    final distX = pos.dx - closestX;
    final distY = pos.dy - closestY;
    final distSq = distX * distX + distY * distY;

    if (distSq > r * r) return null;

    // Hangi yüzden çarptı?
    final side = _resolveSide(pos, ball.velocity, rect);
    return CollisionResult(side: side, brick: brick);
  }

  /// Temas normaline göre çarpılan yüzü belirler.
  ///
  /// Tuğla yüzeyindeki en yakın noktadan top merkezine uzanan vektör (temas
  /// normali) baskın ekseni belirlenir.  Köşe isabeti veya top gömülmesi
  /// durumunda hız yönü tiebreaker olarak kullanılır.
  CollisionSide _resolveSide(Offset pos, Offset vel, Rect rect) {
    final closestX = pos.dx.clamp(rect.left, rect.right);
    final closestY = pos.dy.clamp(rect.top, rect.bottom);

    final nx = pos.dx - closestX; // temas normali X
    final ny = pos.dy - closestY; // temas normali Y

    if (nx != 0.0 || ny != 0.0) {
      final ax = nx.abs();
      final ay = ny.abs();
      if (ax > ay) return nx > 0 ? CollisionSide.right : CollisionSide.left;
      if (ay > ax) return ny > 0 ? CollisionSide.bottom : CollisionSide.top;
      // Tam köşe (ax == ay): hız yönüne düş
    }

    // Top merkezi tuğla içinde veya tam köşe: baskın hız eksenine göre
    if (vel.dy.abs() >= vel.dx.abs()) {
      return vel.dy > 0 ? CollisionSide.top : CollisionSide.bottom;
    }
    return vel.dx > 0 ? CollisionSide.left : CollisionSide.right;
  }

  // ── Bonus Top Çarpışması ─────────────────────────────────────────────────

  bool checkBonusBallCollision(
    Ball ball,
    BonusBall bonus, {
    required double brickSize,
    required double brickGap,
    required double padding,
    required double topOffset,
  }) {
    if (bonus.isCollected) return false;
    return bonus.collidesWithBall(
      ball.position,
      ball.radius,
      brickSize: brickSize,
      brickGap: brickGap,
      padding: padding,
      topOffset: topOffset,
    );
  }

  // ── Yardımcı ────────────────────────────────────────────────────────────

  /// Nişan açısından birim hız vektörü üretir.
  /// [angle] radyan cinsinden (0 = sağ yatay, pi/2 = aşağı).
  static Offset velocityFromAngle(double angle, double speed) {
    return Offset(cos(angle) * speed, sin(angle) * speed);
  }
}
