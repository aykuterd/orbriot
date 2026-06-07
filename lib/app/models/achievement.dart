import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ── Tier ─────────────────────────────────────────────────────────────────────

enum AchievementTier { starter, mid, expert }

extension AchievementTierLabel on AchievementTier {
  String get label {
    switch (this) {
      case AchievementTier.starter: return 'tier_starter'.tr;
      case AchievementTier.mid:     return 'tier_mid'.tr;
      case AchievementTier.expert:  return 'tier_expert'.tr;
    }
  }

  Color get color {
    switch (this) {
      case AchievementTier.starter: return const Color(0xFF22C55E);
      case AchievementTier.mid:     return const Color(0xFFF59E0B);
      case AchievementTier.expert:  return const Color(0xFFF43F5E);
    }
  }
}

// ── Counter Tipi ──────────────────────────────────────────────────────────────

enum AchievementCounter {
  shotsFired,       // her tur başında 1 artar
  stagesCompleted,  // sahne tamamlandığında artar
  gemsEarned,       // toplam kazanılan gem (kümülatif)
  upgradesBought,   // yükseltme satın alındığında artar
  totalBricks,      // toplamda kırılan tuğla
  totalBombs,       // toplamda patlatılan bomb
  totalLasers,      // toplamda kırılan laser tuğla
  maxBallsInGame,   // bir turda en fazla sahip olunan top (maximize)
  maxBricksInTurn,  // tek turda en fazla kırılan tuğla (maximize)
  bossesDefeated,   // boss brick öldürüldüğünde artar
  powerUpsUsed,     // power-up kullanıldığında artar
  daysPlayed,       // her günlük girişte 1 artar
}

// ── Tanım (değişmez, katalog) ─────────────────────────────────────────────────

class AchievementDef {
  const AchievementDef({
    required this.id,
    required this.tier,
    required this.icon,
    required this.title,
    required this.description,
    required this.counter,
    required this.target,
    required this.reward,
    required this.seriesName,
    required this.seriesOrder,
  });

  final String           id;
  final AchievementTier  tier;
  final IconData         icon;
  final String           title;
  final String           description;
  final AchievementCounter counter;
  final int              target;
  final int              reward;
  final String           seriesName;
  final int              seriesOrder;

  String get localizedTitle       => 'ach_${id}_title'.tr;
  String get localizedDescription => 'ach_${id}_desc'.tr;
  String get localizedSeriesName  => 'series_$seriesName'.tr;
}

// ── Katalog ───────────────────────────────────────────────────────────────────

class AchievementCatalog {
  AchievementCatalog._();

  static const List<AchievementDef> all = [
    // ── Seri 1: Nişancı (shotsFired) ──────────────────────────────────────
    AchievementDef(
      id: 'first_shot', seriesName: 'Nişancı', seriesOrder: 1,
      tier: AchievementTier.starter,
      icon: Icons.sports_basketball_rounded,
      title: 'İlk Atış', description: 'İlk topu fırlat',
      counter: AchievementCounter.shotsFired, target: 1, reward: 5,
    ),
    AchievementDef(
      id: 'shots_100', seriesName: 'Nişancı', seriesOrder: 2,
      tier: AchievementTier.starter,
      icon: Icons.sports_basketball_rounded,
      title: 'Nişancı II', description: '100 top fırlat',
      counter: AchievementCounter.shotsFired, target: 100, reward: 10,
    ),
    AchievementDef(
      id: 'shots_1000', seriesName: 'Nişancı', seriesOrder: 3,
      tier: AchievementTier.mid,
      icon: Icons.sports_basketball_rounded,
      title: 'Nişancı III', description: '1000 top fırlat',
      counter: AchievementCounter.shotsFired, target: 1000, reward: 25,
    ),
    AchievementDef(
      id: 'shots_5000', seriesName: 'Nişancı', seriesOrder: 4,
      tier: AchievementTier.mid,
      icon: Icons.sports_basketball_rounded,
      title: 'Nişancı IV', description: '5000 top fırlat',
      counter: AchievementCounter.shotsFired, target: 5000, reward: 40,
    ),
    AchievementDef(
      id: 'shots_20000', seriesName: 'Nişancı', seriesOrder: 5,
      tier: AchievementTier.expert,
      icon: Icons.sports_basketball_rounded,
      title: 'Efsane Nişancı', description: '20000 top fırlat',
      counter: AchievementCounter.shotsFired, target: 20000, reward: 80,
    ),
    // ── Seri 2: Sahne Fatihi (stagesCompleted) ────────────────────────────
    AchievementDef(
      id: 'first_stage', seriesName: 'Sahne Fatihi', seriesOrder: 1,
      tier: AchievementTier.starter,
      icon: Icons.military_tech_rounded,
      title: 'Kırıcı', description: 'İlk sahneyi tamamla',
      counter: AchievementCounter.stagesCompleted, target: 1, reward: 5,
    ),
    AchievementDef(
      id: 'stages_10', seriesName: 'Sahne Fatihi', seriesOrder: 2,
      tier: AchievementTier.starter,
      icon: Icons.military_tech_rounded,
      title: 'Sahne Fatihi II', description: '10 sahne tamamla',
      counter: AchievementCounter.stagesCompleted, target: 10, reward: 10,
    ),
    AchievementDef(
      id: 'stages_50', seriesName: 'Sahne Fatihi', seriesOrder: 3,
      tier: AchievementTier.mid,
      icon: Icons.sports_esports_rounded,
      title: 'Sürekli Oyuncu', description: '50 sahne tamamla',
      counter: AchievementCounter.stagesCompleted, target: 50, reward: 20,
    ),
    AchievementDef(
      id: 'stages_200', seriesName: 'Sahne Fatihi', seriesOrder: 4,
      tier: AchievementTier.mid,
      icon: Icons.sports_esports_rounded,
      title: 'Sahne Fatihi IV', description: '200 sahne tamamla',
      counter: AchievementCounter.stagesCompleted, target: 200, reward: 50,
    ),
    AchievementDef(
      id: 'stages_500', seriesName: 'Sahne Fatihi', seriesOrder: 5,
      tier: AchievementTier.expert,
      icon: Icons.emoji_events_rounded,
      title: 'Efsane', description: '500 sahne tamamla',
      counter: AchievementCounter.stagesCompleted, target: 500, reward: 100,
    ),
    // ── Seri 3: Gem Avcısı (gemsEarned) ──────────────────────────────────
    AchievementDef(
      id: 'first_gem', seriesName: 'Gem Avcısı', seriesOrder: 1,
      tier: AchievementTier.starter,
      icon: Icons.diamond_rounded,
      title: 'Zenginleşiyorum', description: 'İlk gem\'ini kazan',
      counter: AchievementCounter.gemsEarned, target: 1, reward: 5,
    ),
    AchievementDef(
      id: 'gems_100', seriesName: 'Gem Avcısı', seriesOrder: 2,
      tier: AchievementTier.mid, // backward-compat: mid korundu
      icon: Icons.collections_bookmark_rounded,
      title: 'Gem Koleksiyoncusu', description: 'Toplamda 100 gem kazan',
      counter: AchievementCounter.gemsEarned, target: 100, reward: 25,
    ),
    AchievementDef(
      id: 'gems_1000', seriesName: 'Gem Avcısı', seriesOrder: 3,
      tier: AchievementTier.mid,
      icon: Icons.diamond_rounded,
      title: 'Gem Avcısı III', description: 'Toplamda 1000 gem kazan',
      counter: AchievementCounter.gemsEarned, target: 1000, reward: 50,
    ),
    AchievementDef(
      id: 'gems_10000', seriesName: 'Gem Avcısı', seriesOrder: 4,
      tier: AchievementTier.mid,
      icon: Icons.diamond_rounded,
      title: 'Gem Avcısı IV', description: 'Toplamda 10000 gem kazan',
      counter: AchievementCounter.gemsEarned, target: 10000, reward: 100,
    ),
    AchievementDef(
      id: 'gems_50000', seriesName: 'Gem Avcısı', seriesOrder: 5,
      tier: AchievementTier.expert,
      icon: Icons.diamond_rounded,
      title: 'Gem Kralı', description: 'Toplamda 50000 gem kazan',
      counter: AchievementCounter.gemsEarned, target: 50000, reward: 200,
    ),
    // ── Seri 4: Mağaza Ustası (upgradesBought) ────────────────────────────
    AchievementDef(
      id: 'first_upgrade', seriesName: 'Mağaza Ustası', seriesOrder: 1,
      tier: AchievementTier.starter,
      icon: Icons.shopping_bag_rounded,
      title: 'Alışveriş', description: 'İlk yükseltmeni satın al',
      counter: AchievementCounter.upgradesBought, target: 1, reward: 10,
    ),
    AchievementDef(
      id: 'upgrades_5', seriesName: 'Mağaza Ustası', seriesOrder: 2,
      tier: AchievementTier.starter,
      icon: Icons.shopping_bag_rounded,
      title: 'Mağaza Ustası II', description: '5 yükseltme satın al',
      counter: AchievementCounter.upgradesBought, target: 5, reward: 20,
    ),
    AchievementDef(
      id: 'upgrades_20', seriesName: 'Mağaza Ustası', seriesOrder: 3,
      tier: AchievementTier.mid,
      icon: Icons.shopping_bag_rounded,
      title: 'Mağaza Ustası III', description: '20 yükseltme satın al',
      counter: AchievementCounter.upgradesBought, target: 20, reward: 50,
    ),
    AchievementDef(
      id: 'upgrades_50', seriesName: 'Mağaza Ustası', seriesOrder: 4,
      tier: AchievementTier.mid,
      icon: Icons.shopping_bag_rounded,
      title: 'Alışveriş Delisi', description: '50 yükseltme satın al',
      counter: AchievementCounter.upgradesBought, target: 50, reward: 100,
    ),
    // ── Seri 5: Tuğla Yıkıcı (totalBricks) ───────────────────────────────
    AchievementDef(
      id: 'bricks_100', seriesName: 'Tuğla Yıkıcı', seriesOrder: 1,
      tier: AchievementTier.starter,
      icon: Icons.grid_view_rounded,
      title: 'Tuğla Yıkıcı I', description: '100 tuğla kır',
      counter: AchievementCounter.totalBricks, target: 100, reward: 10,
    ),
    AchievementDef(
      id: 'bricks_500', seriesName: 'Tuğla Yıkıcı', seriesOrder: 2,
      tier: AchievementTier.mid, // backward-compat: mid korundu
      icon: Icons.shield_rounded,
      title: 'Kırılmaz', description: '500 tuğla kır',
      counter: AchievementCounter.totalBricks, target: 500, reward: 20,
    ),
    AchievementDef(
      id: 'bricks_2500', seriesName: 'Tuğla Yıkıcı', seriesOrder: 3,
      tier: AchievementTier.mid,
      icon: Icons.grid_view_rounded,
      title: 'Tuğla Yıkıcı III', description: '2500 tuğla kır',
      counter: AchievementCounter.totalBricks, target: 2500, reward: 35,
    ),
    AchievementDef(
      id: 'bricks_5000', seriesName: 'Tuğla Yıkıcı', seriesOrder: 4,
      tier: AchievementTier.expert, // backward-compat: expert korundu
      icon: Icons.whatshot_rounded,
      title: 'Yıkıcı', description: 'Toplamda 5000 tuğla kır',
      counter: AchievementCounter.totalBricks, target: 5000, reward: 65,
    ),
    AchievementDef(
      id: 'bricks_50000', seriesName: 'Tuğla Yıkıcı', seriesOrder: 5,
      tier: AchievementTier.expert,
      icon: Icons.whatshot_rounded,
      title: 'Tuğla Tanrısı', description: '50000 tuğla kır',
      counter: AchievementCounter.totalBricks, target: 50000, reward: 120,
    ),
    // ── Seri 6: Bomba Ustası (totalBombs) ─────────────────────────────────
    AchievementDef(
      id: 'bombs_5', seriesName: 'Bomba Ustası', seriesOrder: 1,
      tier: AchievementTier.starter,
      icon: Icons.local_fire_department_rounded,
      title: 'Bomba Ustası I', description: '5 bomb tuğla patlat',
      counter: AchievementCounter.totalBombs, target: 5, reward: 10,
    ),
    AchievementDef(
      id: 'bombs_20', seriesName: 'Bomba Ustası', seriesOrder: 2,
      tier: AchievementTier.mid, // backward-compat: mid korundu
      icon: Icons.local_fire_department_rounded,
      title: 'Bomba Uzmanı', description: '20 bomb tuğla patlat',
      counter: AchievementCounter.totalBombs, target: 20, reward: 20,
    ),
    AchievementDef(
      id: 'bombs_100', seriesName: 'Bomba Ustası', seriesOrder: 3,
      tier: AchievementTier.expert,
      icon: Icons.local_fire_department_rounded,
      title: 'Bomba Dehası', description: '100 bomb tuğla patlat',
      counter: AchievementCounter.totalBombs, target: 100, reward: 50,
    ),
    // ── Seri 7: Lazer Ustası (totalLasers) ────────────────────────────────
    AchievementDef(
      id: 'lasers_5', seriesName: 'Lazer Ustası', seriesOrder: 1,
      tier: AchievementTier.starter,
      icon: Icons.bolt_rounded,
      title: 'Lazer Ustası I', description: '5 laser tuğla kır',
      counter: AchievementCounter.totalLasers, target: 5, reward: 10,
    ),
    AchievementDef(
      id: 'lasers_10', seriesName: 'Lazer Ustası', seriesOrder: 2,
      tier: AchievementTier.mid, // backward-compat: mid korundu
      icon: Icons.bolt_rounded,
      title: 'Lazer Çılgını', description: '10 laser tuğla kır',
      counter: AchievementCounter.totalLasers, target: 10, reward: 20,
    ),
    AchievementDef(
      id: 'lasers_100', seriesName: 'Lazer Ustası', seriesOrder: 3,
      tier: AchievementTier.expert,
      icon: Icons.bolt_rounded,
      title: 'Lazer Tanrısı', description: '100 laser tuğla kır',
      counter: AchievementCounter.totalLasers, target: 100, reward: 50,
    ),
    // ── Seri 8: Top Hakimi (maxBallsInGame) ───────────────────────────────
    AchievementDef(
      id: 'balls_10', seriesName: 'Top Hakimi', seriesOrder: 1,
      tier: AchievementTier.starter,
      icon: Icons.bubble_chart_rounded,
      title: 'Top Hakimi I', description: 'Aynı anda 10 top kullan',
      counter: AchievementCounter.maxBallsInGame, target: 10, reward: 15,
    ),
    AchievementDef(
      id: 'balls_30', seriesName: 'Top Hakimi', seriesOrder: 2,
      tier: AchievementTier.mid,
      icon: Icons.bubble_chart_rounded,
      title: 'Top Hakimi II', description: 'Aynı anda 30 top kullan',
      counter: AchievementCounter.maxBallsInGame, target: 30, reward: 30,
    ),
    AchievementDef(
      id: 'max_balls_50', seriesName: 'Top Hakimi', seriesOrder: 3,
      tier: AchievementTier.expert, // backward-compat: expert korundu
      icon: Icons.bubble_chart_rounded,
      title: 'Top Çılgını', description: 'Aynı anda 50 top kullan',
      counter: AchievementCounter.maxBallsInGame, target: 50, reward: 50,
    ),
    AchievementDef(
      id: 'balls_100', seriesName: 'Top Hakimi', seriesOrder: 4,
      tier: AchievementTier.expert,
      icon: Icons.bubble_chart_rounded,
      title: 'Top Efsanesi', description: 'Aynı anda 100 top kullan',
      counter: AchievementCounter.maxBallsInGame, target: 100, reward: 100,
    ),
    // ── Seri 9: Combo Ustası (maxBricksInTurn) ────────────────────────────
    AchievementDef(
      id: 'combo_10', seriesName: 'Combo Ustası', seriesOrder: 1,
      tier: AchievementTier.starter,
      icon: Icons.star_rounded,
      title: 'Combo Ustası I', description: 'Tek turda 10 tuğla kır',
      counter: AchievementCounter.maxBricksInTurn, target: 10, reward: 10,
    ),
    AchievementDef(
      id: 'combo_20', seriesName: 'Combo Ustası', seriesOrder: 2,
      tier: AchievementTier.mid,
      icon: Icons.star_rounded,
      title: 'Combo Ustası II', description: 'Tek turda 20 tuğla kır',
      counter: AchievementCounter.maxBricksInTurn, target: 20, reward: 20,
    ),
    AchievementDef(
      id: 'bricks_turn_30', seriesName: 'Combo Ustası', seriesOrder: 3,
      tier: AchievementTier.expert, // backward-compat: expert korundu
      icon: Icons.star_rounded,
      title: 'Mükemmel', description: 'Tek turda 30+ tuğla kır',
      counter: AchievementCounter.maxBricksInTurn, target: 30, reward: 30,
    ),
    AchievementDef(
      id: 'combo_50', seriesName: 'Combo Ustası', seriesOrder: 4,
      tier: AchievementTier.expert,
      icon: Icons.star_rounded,
      title: 'Combo Tanrısı', description: 'Tek turda 50 tuğla kır',
      counter: AchievementCounter.maxBricksInTurn, target: 50, reward: 60,
    ),
    // ── Seri 10: Boss Avcısı (bossesDefeated) ────────────────────────────
    AchievementDef(
      id: 'boss_1', seriesName: 'Boss Avcısı', seriesOrder: 1,
      tier: AchievementTier.starter,
      icon: Icons.dangerous_rounded,
      title: 'Boss Avcısı I', description: 'İlk boss\'u öldür',
      counter: AchievementCounter.bossesDefeated, target: 1, reward: 10,
    ),
    AchievementDef(
      id: 'boss_10', seriesName: 'Boss Avcısı', seriesOrder: 2,
      tier: AchievementTier.mid,
      icon: Icons.dangerous_rounded,
      title: 'Boss Avcısı II', description: '10 boss öldür',
      counter: AchievementCounter.bossesDefeated, target: 10, reward: 30,
    ),
    AchievementDef(
      id: 'boss_50', seriesName: 'Boss Avcısı', seriesOrder: 3,
      tier: AchievementTier.expert,
      icon: Icons.dangerous_rounded,
      title: 'Boss Avcısı III', description: '50 boss öldür',
      counter: AchievementCounter.bossesDefeated, target: 50, reward: 75,
    ),
    AchievementDef(
      id: 'boss_100', seriesName: 'Boss Avcısı', seriesOrder: 4,
      tier: AchievementTier.expert,
      icon: Icons.dangerous_rounded,
      title: 'Boss Katili', description: '100 boss öldür',
      counter: AchievementCounter.bossesDefeated, target: 100, reward: 150,
    ),
    // ── Seri 11: Power-Up Ustası (powerUpsUsed) ───────────────────────────
    AchievementDef(
      id: 'pu_1', seriesName: 'Power-Up Ustası', seriesOrder: 1,
      tier: AchievementTier.starter,
      icon: Icons.flash_on_rounded,
      title: 'Power-Up Ustası I', description: 'İlk power-up\'ı kullan',
      counter: AchievementCounter.powerUpsUsed, target: 1, reward: 5,
    ),
    AchievementDef(
      id: 'pu_10', seriesName: 'Power-Up Ustası', seriesOrder: 2,
      tier: AchievementTier.mid,
      icon: Icons.flash_on_rounded,
      title: 'Power-Up Ustası II', description: '10 power-up kullan',
      counter: AchievementCounter.powerUpsUsed, target: 10, reward: 20,
    ),
    AchievementDef(
      id: 'pu_50', seriesName: 'Power-Up Ustası', seriesOrder: 3,
      tier: AchievementTier.mid,
      icon: Icons.flash_on_rounded,
      title: 'Power-Up Ustası III', description: '50 power-up kullan',
      counter: AchievementCounter.powerUpsUsed, target: 50, reward: 40,
    ),
    AchievementDef(
      id: 'pu_200', seriesName: 'Power-Up Ustası', seriesOrder: 4,
      tier: AchievementTier.expert,
      icon: Icons.flash_on_rounded,
      title: 'Güç Bağımlısı', description: '200 power-up kullan',
      counter: AchievementCounter.powerUpsUsed, target: 200, reward: 80,
    ),
    // ── Seri 12: Sadık Oyuncu (daysPlayed) ───────────────────────────────
    AchievementDef(
      id: 'days_3', seriesName: 'Sadık Oyuncu', seriesOrder: 1,
      tier: AchievementTier.starter,
      icon: Icons.calendar_today_rounded,
      title: 'Sadık Oyuncu I', description: '3 gün oyna',
      counter: AchievementCounter.daysPlayed, target: 3, reward: 15,
    ),
    AchievementDef(
      id: 'days_7', seriesName: 'Sadık Oyuncu', seriesOrder: 2,
      tier: AchievementTier.mid,
      icon: Icons.calendar_today_rounded,
      title: 'Haftalık Oyuncu', description: '7 gün oyna',
      counter: AchievementCounter.daysPlayed, target: 7, reward: 30,
    ),
    AchievementDef(
      id: 'days_30', seriesName: 'Sadık Oyuncu', seriesOrder: 3,
      tier: AchievementTier.expert,
      icon: Icons.calendar_today_rounded,
      title: 'Aylık Oyuncu', description: '30 gün oyna',
      counter: AchievementCounter.daysPlayed, target: 30, reward: 100,
    ),
    AchievementDef(
      id: 'days_100', seriesName: 'Sadık Oyuncu', seriesOrder: 4,
      tier: AchievementTier.expert,
      icon: Icons.calendar_today_rounded,
      title: 'Efsane Oyuncu', description: '100 gün oyna',
      counter: AchievementCounter.daysPlayed, target: 100, reward: 200,
    ),
  ];
}

// ── Çalışma Zamanı Durumu ─────────────────────────────────────────────────────

class Achievement {
  Achievement({
    required this.def,
    this.progress = 0,
    this.unlocked = false,
    this.claimed = false,
  });

  final AchievementDef def;
  int  progress;
  bool unlocked;
  bool claimed;

  double get progressFraction => (progress / def.target).clamp(0.0, 1.0);
  int    get displayProgress  => progress.clamp(0, def.target);

  String get id          => def.id;
  String get title       => def.title;
  String get description => def.description;
  int    get target      => def.target;
  int    get reward      => def.reward;
}
