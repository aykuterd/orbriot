import 'package:flutter/material.dart';

/// Bir skin'in veri tanımı.
class SkinDefinition {
  final String id;
  final String name;
  final Color primary; // top merkez rengi
  final Color light;   // sol üst parlama
  final Color dark;    // dış kenar / glow
  final int cost;      // 0 = ücretsiz

  const SkinDefinition({
    required this.id,
    required this.name,
    required this.primary,
    required this.light,
    required this.dark,
    required this.cost,
  });
}

/// Oyundaki tüm skinlerin kataloğu.
class SkinCatalog {
  SkinCatalog._();

  static const SkinDefinition defaultSkin = SkinDefinition(
    id: 'default',
    name: 'DEFAULT',
    primary: Color(0xFF7C3AED),
    light: Color(0xFFA78BFA),
    dark: Color(0xFF4C1D95),
    cost: 0,
  );

  static const SkinDefinition neon = SkinDefinition(
    id: 'neon',
    name: 'NEON',
    primary: Color(0xFF16A34A),
    light: Color(0xFF4ADE80),
    dark: Color(0xFF14532D),
    cost: 30,
  );

  static const SkinDefinition lava = SkinDefinition(
    id: 'lava',
    name: 'LAVA',
    primary: Color(0xFFEA580C),
    light: Color(0xFFFB923C),
    dark: Color(0xFF7C2D12),
    cost: 50,
  );

  static const SkinDefinition ice = SkinDefinition(
    id: 'ice',
    name: 'ICE',
    primary: Color(0xFF0891B2),
    light: Color(0xFF67E8F9),
    dark: Color(0xFF164E63),
    cost: 50,
  );

  static const SkinDefinition galaxy = SkinDefinition(
    id: 'galaxy',
    name: 'GALAXY',
    primary: Color(0xFF9333EA),
    light: Color(0xFFE879F9),
    dark: Color(0xFF581C87),
    cost: 80,
  );

  static const SkinDefinition gold = SkinDefinition(
    id: 'gold',
    name: 'GOLD',
    primary: Color(0xFFD97706),
    light: Color(0xFFFDE68A),
    dark: Color(0xFF78350F),
    cost: 150,
  );

  static const List<SkinDefinition> all = [
    defaultSkin,
    neon,
    lava,
    ice,
    galaxy,
    gold,
  ];

  static SkinDefinition findById(String id) {
    return all.firstWhere((s) => s.id == id, orElse: () => defaultSkin);
  }
}
