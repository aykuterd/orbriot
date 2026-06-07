import 'package:flutter/material.dart';
import '../../../core/physics/particle_system.dart';

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter(this.particles);

  final Paint _paint = Paint()..style = PaintingStyle.fill;
  final Paint _ringPaint = Paint()..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final alpha = (p.alpha * 255).round().clamp(0, 255);
      if (alpha == 0) continue;

      _paint.color = p.color.withAlpha(alpha);

      switch (p.type) {
        case ParticleType.spark:
          // Glow efekti
          _paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
          canvas.drawCircle(p.position, p.radius * 1.6, _paint);
          _paint.maskFilter = null;
          canvas.drawCircle(p.position, p.radius, _paint);

        case ParticleType.shard:
          canvas.save();
          canvas.translate(p.position.dx, p.position.dy);
          canvas.rotate(p.rotation);
          // Küçük dönen dörtgen parça
          final r = p.radius;
          final rect = Rect.fromCenter(
            center: Offset.zero,
            width: r * 1.4,
            height: r * 0.7,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(2)),
            _paint,
          );
          canvas.restore();

        case ParticleType.ring:
          // Genişleyen halka — life azaldıkça büyür
          final expansionRadius = p.radius + (1 - p.life) * 28;
          _ringPaint.color = p.color.withAlpha(alpha);
          _ringPaint.strokeWidth = 1.5 + p.life * 2;
          _ringPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
          canvas.drawCircle(p.position, expansionRadius, _ringPaint);
          _ringPaint.maskFilter = null;
      }
    }
  }

  @override
  bool shouldRepaint(ParticlePainter old) => true;
}
