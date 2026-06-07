import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// Arkaplan dekoratif neon grid çizgisi
class NeonGridPainter extends CustomPainter {
  final double animValue; // 0.0 – 1.0

  NeonGridPainter(this.animValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = AppColors.primary.withAlpha(28);

    const spacing = 36.0;

    // Dikey çizgiler
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Yatay çizgiler (animasyonla yavaşça kayar)
    final offset = animValue * spacing;
    for (double y = -spacing + offset; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Parlayan köşe noktaları
    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.primary.withAlpha(40);

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = -spacing + offset; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(NeonGridPainter old) => old.animValue != animValue;
}
