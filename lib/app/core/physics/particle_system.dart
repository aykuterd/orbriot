import 'dart:math';
import 'dart:ui';

enum ParticleType { spark, shard, ring }

class Particle {
  Offset position;
  Offset velocity;
  double radius;
  double alpha; // 0.0 – 1.0
  Color color;
  ParticleType type;
  double life;       // kalan ömür (0.0 – 1.0)
  double rotation;
  double rotSpeed;

  Particle({
    required this.position,
    required this.velocity,
    required this.radius,
    required this.alpha,
    required this.color,
    required this.type,
    this.life = 1.0,
    this.rotation = 0,
    this.rotSpeed = 0,
  });

  /// dt saniye cinsinden
  void update(double dt) {
    position += velocity * dt;
    velocity = velocity * 0.88; // hava direnci
    rotation += rotSpeed * dt;
    life -= dt * 1.8;           // ~0.55 sn ömür
    alpha = life.clamp(0.0, 1.0);
  }

  bool get isDead => life <= 0;
}

class ParticleSystem {
  final List<Particle> _particles = [];
  final Random _rng = Random();

  List<Particle> get particles => _particles;

  // ── Tuğla Patlaması ──────────────────────────────────────────────────────

  void emitBrickExplosion(Offset center, Color color) {
    // Kıvılcımlar
    for (int i = 0; i < 14; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 120 + _rng.nextDouble() * 260;
      _particles.add(Particle(
        position: center,
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        radius: 2.5 + _rng.nextDouble() * 2.5,
        alpha: 1.0,
        color: color,
        type: ParticleType.spark,
        life: 0.7 + _rng.nextDouble() * 0.4,
        rotSpeed: (_rng.nextDouble() - 0.5) * 8,
      ));
    }

    // Parçalar (shard) — daha büyük, kısa ömürlü
    for (int i = 0; i < 6; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 60 + _rng.nextDouble() * 120;
      _particles.add(Particle(
        position: center,
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        radius: 4 + _rng.nextDouble() * 5,
        alpha: 0.85,
        color: color.withAlpha(180),
        type: ParticleType.shard,
        life: 0.4 + _rng.nextDouble() * 0.3,
        rotation: _rng.nextDouble() * 2 * pi,
        rotSpeed: (_rng.nextDouble() - 0.5) * 12,
      ));
    }

    // Genişleyen halka
    _particles.add(Particle(
      position: center,
      velocity: Offset.zero,
      radius: 6,
      alpha: 0.7,
      color: color.withAlpha(140),
      type: ParticleType.ring,
      life: 0.5,
    ));
  }

  // ── Boss Patlaması ────────────────────────────────────────────────────────

  /// Boss yıkılınca çağrılır — normal explosiondan 4× büyük, altın rengi.
  void emitBossExplosion(Offset center) {
    const gold   = Color(0xFFFFD700);
    const red    = Color(0xFFEF4444);
    const white  = Color(0xFFFFFFFF);

    // Büyük kıvılcımlar — altın
    for (int i = 0; i < 40; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 200 + _rng.nextDouble() * 420;
      _particles.add(Particle(
        position: center,
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        radius:   3 + _rng.nextDouble() * 4,
        alpha:    1.0,
        color:    gold,
        type:     ParticleType.spark,
        life:     0.9 + _rng.nextDouble() * 0.6,
        rotSpeed: (_rng.nextDouble() - 0.5) * 10,
      ));
    }

    // Kırmızı kıvılcımlar — kaos efekti
    for (int i = 0; i < 20; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 150 + _rng.nextDouble() * 300;
      _particles.add(Particle(
        position: center,
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        radius:   2 + _rng.nextDouble() * 3,
        alpha:    1.0,
        color:    red,
        type:     ParticleType.spark,
        life:     0.6 + _rng.nextDouble() * 0.5,
        rotSpeed: (_rng.nextDouble() - 0.5) * 15,
      ));
    }

    // Büyük parçalar — shard
    for (int i = 0; i < 16; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 80 + _rng.nextDouble() * 200;
      _particles.add(Particle(
        position: center,
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        radius:   6 + _rng.nextDouble() * 10,
        alpha:    0.9,
        color:    gold.withAlpha(200),
        type:     ParticleType.shard,
        life:     0.5 + _rng.nextDouble() * 0.4,
        rotation: _rng.nextDouble() * 2 * pi,
        rotSpeed: (_rng.nextDouble() - 0.5) * 18,
      ));
    }

    // Beyaz flaş parçaları
    for (int i = 0; i < 8; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 60 + _rng.nextDouble() * 160;
      _particles.add(Particle(
        position: center,
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        radius:   4 + _rng.nextDouble() * 6,
        alpha:    1.0,
        color:    white.withAlpha(220),
        type:     ParticleType.shard,
        life:     0.3 + _rng.nextDouble() * 0.3,
        rotation: _rng.nextDouble() * 2 * pi,
        rotSpeed: (_rng.nextDouble() - 0.5) * 20,
      ));
    }

    // 3 genişleyen halka — iç içe
    for (int i = 0; i < 3; i++) {
      _particles.add(Particle(
        position: center,
        velocity: Offset.zero,
        radius:   8 + i * 4.0,
        alpha:    0.8 - i * 0.15,
        color:    i == 0 ? white : gold,
        type:     ParticleType.ring,
        life:     0.6 - i * 0.1,
      ));
    }
  }

  // ── Bonus Top Toplama ────────────────────────────────────────────────────

  void emitBonusCollect(Offset center) {
    for (int i = 0; i < 10; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 80 + _rng.nextDouble() * 140;
      _particles.add(Particle(
        position: center,
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        radius: 2 + _rng.nextDouble() * 2,
        alpha: 1.0,
        color: const Color(0xFF22C55E),
        type: ParticleType.spark,
        life: 0.5 + _rng.nextDouble() * 0.3,
      ));
    }
  }

  // ── Güncelleme ───────────────────────────────────────────────────────────

  void update(double dt) {
    _particles.removeWhere((p) => p.isDead);
    for (final p in _particles) {
      p.update(dt);
    }
  }

  void clear() => _particles.clear();
}
