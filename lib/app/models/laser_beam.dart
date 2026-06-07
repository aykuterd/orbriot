/// Aktif lazer ışını — ekranda kısa süre görünür, sonra solar.
class LaserBeam {
  final bool isHorizontal;
  final double position; // Y koordinatı (H lazer) veya X koordinatı (V lazer)
  double lifetime;

  static const double maxLifetime = 0.35; // saniye

  LaserBeam({
    required this.isHorizontal,
    required this.position,
  }) : lifetime = maxLifetime;

  /// 0.0 (tamamen soluk) → 1.0 (tam parlak)
  double get alpha => (lifetime / maxLifetime).clamp(0.0, 1.0);

  bool get isExpired => lifetime <= 0;
}
