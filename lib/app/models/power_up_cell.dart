import 'dart:ui';

/// Sahne grid'inde beliren power-up kutucuğunun türü.
enum PowerUpType {
  fireball,   // 1 tur: toplar 3× hasar verir (ateş top görünümü)
  nuke,       // Anında: tüm tuğlaların HP'sini 1 azalt
  multiBall,  // 1 tur: top sayısı 2× olur
  speedBoost, // 1 tur: top hızı 2× olur
  shieldRow,  // 1 tur: tuğlalar aşağı inmiyor
}

/// Grid içinde beliren, top değince aktif olan power-up hücresi.
/// BonusBall ile aynı koordinat sistemini kullanır.
class PowerUpCell {
  final int col;
  final int row;
  final PowerUpType type;
  bool isCollected;

  /// Grid hücresinde çizim yarıçapı (px).
  static const double radius = 17.0;

  PowerUpCell({
    required this.col,
    required this.row,
    required this.type,
    this.isCollected = false,
  });

  /// Hücrenin ekran merkez koordinatı.
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

  /// Bir satır aşağı iner (tur sonu).
  PowerUpCell movedDown() => PowerUpCell(
        col: col,
        row: row + 1,
        type: type,
        isCollected: isCollected,
      );

  /// Top ile çarpışma kontrolü.
  bool collidesWithBall(
    Offset ballPos,
    double ballRadius, {
    required double brickSize,
    required double brickGap,
    required double padding,
    required double topOffset,
  }) {
    final center = centerFor(
      brickSize: brickSize,
      brickGap: brickGap,
      padding: padding,
      topOffset: topOffset,
    );
    return (ballPos - center).distance <= (radius + ballRadius);
  }
}
