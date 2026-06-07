import 'dart:ui';

enum BonusBallType { plus, minus }

class BonusBall {
  final int col;      // grid sütunu
  final int row;      // grid satırı
  final BonusBallType type;
  bool isCollected;

  static const double radius = 12.0;

  BonusBall({
    required this.col,
    required this.row,
    this.type = BonusBallType.plus,
    this.isCollected = false,
  });

  // Bonus topun ekran merkez koordinatı
  Offset centerFor({
    required double brickSize,
    required double brickGap,
    required double padding,
    required double topOffset,
  }) {
    final cellSize = brickSize + brickGap;
    return Offset(
      col * cellSize + padding + brickSize / 2,
      row * cellSize + topOffset + brickSize / 2,
    );
  }

  // Bir satır aşağı iner (tur sonu)
  BonusBall movedDown() {
    return BonusBall(
      col: col,
      row: row + 1,
      type: type,
      isCollected: isCollected,
    );
  }

  // Top ile çarpışma kontrolü
  bool collidesWithBall(Offset ballPos, double ballRadius,
      {required double brickSize,
      required double brickGap,
      required double padding,
      required double topOffset}) {
    final center = centerFor(
      brickSize: brickSize,
      brickGap: brickGap,
      padding: padding,
      topOffset: topOffset,
    );
    final dist = (ballPos - center).distance;
    return dist <= (radius + ballRadius);
  }
}
