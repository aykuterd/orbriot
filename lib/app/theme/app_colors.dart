import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Arkaplan
  static const Color background = Color(0xFF0F0F23);
  static const Color surface = Color(0xFF1E1C35);
  static const Color surfaceVariant = Color(0xFF27273B);

  // Ana renkler
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color accent = Color(0xFFF43F5E);
  static const Color success = Color(0xFF22C55E);
  static const Color neonBlue = Color(0xFF2563EB);

  // Metin
  static const Color foreground = Color(0xFFE2E8F0);
  static const Color muted = Color(0xFF94A3B8);

  // Kenarlık
  static const Color border = Color(0xFF4C1D95);
  static const Color borderLight = Color(0x1AFFFFFF);

  // Hata
  static const Color error = Color(0xFFEF4444);

  // Tuğla renkleri (HP'ye göre)
  static const List<Color> brickColors = [
    Color(0xFF7C3AED), // mor - yüksek HP
    Color(0xFF2563EB), // mavi
    Color(0xFF22C55E), // yeşil
    Color(0xFFF59E0B), // sarı
    Color(0xFFF43F5E), // kırmızı - düşük HP
  ];

  // Ek renkler
  static const Color cyan  = Color(0xFF06B6D4);
  static const Color amber = Color(0xFFF59E0B);

  // Neon glow renkleri (BoxShadow için)
  static const Color glowPrimary = Color(0x997C3AED);
  static const Color glowAccent = Color(0x99F43F5E);
  static const Color glowSuccess = Color(0x9922C55E);
  static const Color glowBlue = Color(0x992563EB);
  static const Color glowCyan = Color(0x9906B6D4);
}
