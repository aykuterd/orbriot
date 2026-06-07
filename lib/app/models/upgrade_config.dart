import 'package:flutter/material.dart';

/// Tek bir yükseltme tanımı — sabit, değişmez veri.
class UpgradeDef {
  final String key;
  final String name;
  final String desc;
  final String effectLabel;
  final int maxLevel;
  final List<int> costs; // costs[i] = i. seviyeye geçiş maliyeti
  final IconData icon;
  final Color color;

  const UpgradeDef({
    required this.key,
    required this.name,
    required this.desc,
    required this.effectLabel,
    required this.maxLevel,
    required this.costs,
    required this.icon,
    required this.color,
  });

  /// Şu an currentLevel ise bir sonraki seviyenin maliyeti.
  /// Maksimum seviyedeyse 0 döner.
  int nextCost(int currentLevel) =>
      currentLevel < maxLevel ? costs[currentLevel] : 0;
}

abstract class UpgradeCatalog {
  // ── Top Kolu ─────────────────────────────────────────────────────────────

  static const extraBalls = UpgradeDef(
    key: 'extra_balls',
    name: 'EKSTRA TOP',
    desc: 'upg_extra_balls_desc',
    effectLabel: 'upg_extra_balls_effect',
    maxLevel: 5,
    costs: [30, 60, 120, 220, 380],
    icon: Icons.sports_baseball_rounded,
    color: Color(0xFF7C3AED),
  );

  static const ballSpeed = UpgradeDef(
    key: 'ball_speed',
    name: 'TOP HIZI',
    desc: 'upg_ball_speed_desc',
    effectLabel: 'upg_ball_speed_effect',
    maxLevel: 3,
    costs: [50, 110, 230],
    icon: Icons.bolt_rounded,
    color: Color(0xFFF59E0B),
  );

  static const ballSize = UpgradeDef(
    key: 'ball_size',
    name: 'TOP BOYUTU',
    desc: 'upg_ball_size_desc',
    effectLabel: 'upg_ball_size_effect',
    maxLevel: 3,
    costs: [40, 90, 200],
    icon: Icons.circle_rounded,
    color: Color(0xFF22C55E),
  );

  // ── Ekonomi Kolu ─────────────────────────────────────────────────────────

  static const gemBonus = UpgradeDef(
    key: 'gem_bonus',
    name: 'GEM BONUSU',
    desc: 'upg_gem_bonus_desc',
    effectLabel: 'upg_gem_bonus_effect',
    maxLevel: 3,
    costs: [80, 160, 320],
    icon: Icons.diamond_rounded,
    color: Color(0xFF06B6D4),
  );

  static const List<UpgradeDef> all = [
    extraBalls,
    ballSpeed,
    ballSize,
    gemBonus,
  ];
}
