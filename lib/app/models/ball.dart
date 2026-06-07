import 'dart:ui';

class Ball {
  Offset position;
  Offset velocity;
  final double radius;
  bool isActive; // oyun alanında hareket ediyor mu
  bool hasReturned; // dibe dönüp dönmediği (tur sonu için)

  /// Comet trail: son N pozisyon (en eski önce, en yeni sonda)
  final List<Offset> trail = [];

  static const int trailLength = 10;

  Ball({
    required this.position,
    required this.velocity,
    this.radius = 8.0,
    this.isActive = false,
    this.hasReturned = false,
  });

  Ball copyWith({
    Offset? position,
    Offset? velocity,
    double? radius,
    bool? isActive,
    bool? hasReturned,
  }) {
    return Ball(
      position: position ?? this.position,
      velocity: velocity ?? this.velocity,
      radius: radius ?? this.radius,
      isActive: isActive ?? this.isActive,
      hasReturned: hasReturned ?? this.hasReturned,
    );
  }

  // Topu fizik motoruna hazır konuma sıfırla
  void resetToLaunchPosition(Offset launchPos) {
    position = launchPos;
    isActive = false;
    hasReturned = false;
    trail.clear();
  }
}
