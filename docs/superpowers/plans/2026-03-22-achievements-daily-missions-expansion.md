# Achievements & Daily Missions Genişletme — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 13 başarımı 50'ye çıkar (12 tier-based seri), daily mission pool'unu 40 entry'ye genişlet (9 tip), yeni counter hook'larını bağla ve AchievementView'ı seri kartlarına yeniden tasarla.

**Architecture:** Model katmanı önce genişletilir (achievement.dart, daily_mission.dart), ardından controller metodları eklenir, sonra hook noktaları bağlanır ve son olarak UI yenilenir. Her adım öncekinin üzerine inşa eder.

**Tech Stack:** Flutter/Dart, GetX, SharedPreferences, Google Fonts (Orbitron + JetBrains Mono)

---

## Dosya Haritası

| Dosya | Durum | Yapılacak |
|-------|-------|-----------|
| `lib/app/models/achievement.dart` | Değiştirilecek | `seriesName`/`seriesOrder` ekle, 3 yeni counter, 50 başarım kataloğu |
| `lib/app/models/daily_mission.dart` | Değiştirilecek | 3 yeni MissionType, pool 40 entry, 3 yeni missionLabel case |
| `lib/app/controllers/achievement_controller.dart` | Değiştirilecek | `reportBossDefeated()`, `reportPowerUpUsed()`, `reportDayPlayed()` ekle |
| `lib/app/controllers/daily_mission_controller.dart` | Değiştirilecek | `reportBossDefeated()`, `reportPowerUpUsed()`, `reportLaserDestroyed(int)` ekle |
| `lib/app/controllers/game_controller.dart` | Değiştirilecek | Boss death hook + `_endTurn()` laser hook |
| `lib/app/views/game/widgets/power_up_bar.dart` | Değiştirilecek | `_onTap()` içine powerUp report hook'u ekle |
| `lib/app/controllers/daily_login_controller.dart` | Değiştirilecek | `claimToday()` içine `reportDayPlayed()` hook'u ekle |
| `lib/app/views/achievements/achievement_view.dart` | Yeniden yazılacak | Seri kartı düzeni (tier badge'ler, progress bar, claim) |

---

## Task 1: AchievementDef Model + AchievementCounter + Katalog (50 Başarım)

**Files:**
- Modify: `lib/app/models/achievement.dart`

### Genel Bakış
- `AchievementDef`'e `seriesName` (String) ve `seriesOrder` (int) ekle
- `AchievementCounter` enum'a `bossesDefeated`, `powerUpsUsed`, `daysPlayed` ekle
- `AchievementCatalog.all`'ı 13 → 50 entry'ye çıkar (mevcut ID'ler değişmez)

- [ ] **Step 1: AchievementCounter'a 3 yeni değer ekle**

`achievement.dart` içindeki `enum AchievementCounter` bloğuna şunları ekle:

```dart
enum AchievementCounter {
  shotsFired,
  stagesCompleted,
  gemsEarned,
  upgradesBought,
  totalBricks,
  totalBombs,
  totalLasers,
  maxBallsInGame,
  maxBricksInTurn,
  bossesDefeated, // YENİ — boss brick öldürüldüğünde artar
  powerUpsUsed,   // YENİ — power-up kullanıldığında artar
  daysPlayed,     // YENİ — her günlük girişte 1 artar
}
```

- [ ] **Step 2: AchievementDef'e seriesName ve seriesOrder ekle**

```dart
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
    required this.seriesName,  // YENİ
    required this.seriesOrder, // YENİ
  });

  final String           id;
  final AchievementTier  tier;
  final IconData         icon;
  final String           title;
  final String           description;
  final AchievementCounter counter;
  final int              target;
  final int              reward;
  final String           seriesName;  // YENİ
  final int              seriesOrder; // YENİ
}
```

- [ ] **Step 3: AchievementCatalog.all'ı 50 başarımla güncelle**

`AchievementCatalog.all` listesini aşağıdaki tam içerikle değiştir. Mevcut 13 başarımın `id` değerleri değişmez — sadece `seriesName` ve `seriesOrder` eklenir:

```dart
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
    title: 'Gem Krali', description: 'Toplamda 50000 gem kazan',
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
  // ── Seri 10: Boss Avcısı (bossesDefeated) — YENİ ─────────────────────
  AchievementDef(
    id: 'boss_1', seriesName: 'Boss Avcısı', seriesOrder: 1,
    tier: AchievementTier.starter,
    icon: Icons.skull, // eğer hata verirse: Icons.dangerous_rounded
    title: 'Boss Avcısı I', description: 'İlk boss\'u öldür',
    counter: AchievementCounter.bossesDefeated, target: 1, reward: 10,
  ),
  AchievementDef(
    id: 'boss_10', seriesName: 'Boss Avcısı', seriesOrder: 2,
    tier: AchievementTier.mid,
    icon: Icons.skull, // eğer hata verirse: Icons.dangerous_rounded
    title: 'Boss Avcısı II', description: '10 boss öldür',
    counter: AchievementCounter.bossesDefeated, target: 10, reward: 30,
  ),
  AchievementDef(
    id: 'boss_50', seriesName: 'Boss Avcısı', seriesOrder: 3,
    tier: AchievementTier.expert,
    icon: Icons.skull, // eğer hata verirse: Icons.dangerous_rounded
    title: 'Boss Avcısı III', description: '50 boss öldür',
    counter: AchievementCounter.bossesDefeated, target: 50, reward: 75,
  ),
  AchievementDef(
    id: 'boss_100', seriesName: 'Boss Avcısı', seriesOrder: 4,
    tier: AchievementTier.expert,
    icon: Icons.skull, // eğer hata verirse: Icons.dangerous_rounded
    title: 'Boss Katili', description: '100 boss öldür',
    counter: AchievementCounter.bossesDefeated, target: 100, reward: 150,
  ),
  // ── Seri 11: Power-Up Ustası (powerUpsUsed) — YENİ ───────────────────
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
  // ── Seri 12: Sadık Oyuncu (daysPlayed) — YENİ ────────────────────────
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
```

> **NOT:** `Icons.skull` Flutter material icons'ta mevcut değilse `Icons.dangerous_rounded` veya `Icons.pest_control_rounded` kullan.

- [ ] **Step 4: flutter analyze çalıştır**

```bash
cd /Users/aykut/StudioProjects/orbriot && flutter analyze lib/app/models/achievement.dart
```

Beklenen: 0 hata. Hata varsa önce düzelt, sonra devam et.

- [ ] **Step 5: Commit**

```bash
cd /Users/aykut/StudioProjects/orbriot
git add lib/app/models/achievement.dart
git commit -m "feat: expand AchievementCatalog to 50 achievements (12 series, tier-based)"
```

---

## Task 2: MissionType + Pool Genişletme (40 Entry)

**Files:**
- Modify: `lib/app/models/daily_mission.dart`

- [ ] **Step 1: 3 yeni MissionType ekle**

```dart
enum MissionType {
  breakBricks,
  playGames,
  completeStages,
  popBombs,
  earnScore,
  breakShields,
  usePowerUp,   // YENİ
  defeatBoss,   // YENİ
  breakLasers,  // YENİ
}
```

- [ ] **Step 2: _missionPool'u 40 entry ile değiştir**

`daily_mission.dart` içindeki `const _missionPool = [...]` bloğunu şununla değiştir:

```dart
const _missionPool = [
  // breakBricks (5)
  (MissionType.breakBricks,   25,  10),
  (MissionType.breakBricks,   50,  15),
  (MissionType.breakBricks,  100,  25),
  (MissionType.breakBricks,  200,  40),
  (MissionType.breakBricks,  500,  60),
  // playGames (5)
  (MissionType.playGames,      1,   5),
  (MissionType.playGames,      3,  10),
  (MissionType.playGames,      5,  20),
  (MissionType.playGames,     10,  35),
  (MissionType.playGames,     25,  60),
  // completeStages (5)
  (MissionType.completeStages,  3,   5),
  (MissionType.completeStages,  7,  12),
  (MissionType.completeStages, 15,  25),
  (MissionType.completeStages, 30,  40),
  (MissionType.completeStages, 50,  60),
  // popBombs (5)
  (MissionType.popBombs,  1,   5),
  (MissionType.popBombs,  3,  10),
  (MissionType.popBombs,  8,  20),
  (MissionType.popBombs, 20,  35),
  (MissionType.popBombs, 50,  60),
  // earnScore (5)
  (MissionType.earnScore,   200,   5),
  (MissionType.earnScore,   500,  12),
  (MissionType.earnScore,  1500,  25),
  (MissionType.earnScore,  5000,  40),
  (MissionType.earnScore, 10000,  60),
  // breakShields (3)
  (MissionType.breakShields, 1,   5),
  (MissionType.breakShields, 3,  10),
  (MissionType.breakShields, 8,  20),
  // usePowerUp (4)
  (MissionType.usePowerUp,  1,   5),
  (MissionType.usePowerUp,  3,  10),
  (MissionType.usePowerUp,  8,  20),
  (MissionType.usePowerUp, 15,  30),
  // defeatBoss (3)
  (MissionType.defeatBoss, 1,  10),
  (MissionType.defeatBoss, 3,  20),
  (MissionType.defeatBoss, 5,  35),
  // breakLasers (5)
  (MissionType.breakLasers,  3,   8),
  (MissionType.breakLasers,  8,  15),
  (MissionType.breakLasers, 20,  25),
  (MissionType.breakLasers, 40,  40),
  (MissionType.breakLasers, 80,  60),
];
```

- [ ] **Step 3: missionLabel switch'e 3 yeni case ekle**

`missionLabel()` fonksiyonundaki switch bloğuna ekle (mevcut case'lerin sonuna):

```dart
case MissionType.usePowerUp:
  return '${m.target} power-up kullan';
case MissionType.defeatBoss:
  return '${m.target} boss öldür';
case MissionType.breakLasers:
  return '${m.target} laser tuğla kır';
```

- [ ] **Step 4: flutter analyze çalıştır**

```bash
cd /Users/aykut/StudioProjects/orbriot && flutter analyze lib/app/models/daily_mission.dart
```

Beklenen: 0 hata.

- [ ] **Step 5: Commit**

```bash
cd /Users/aykut/StudioProjects/orbriot
git add lib/app/models/daily_mission.dart
git commit -m "feat: expand daily mission pool to 40 entries with 3 new types"
```

---

## Task 3: Controller Report Metodları

**Files:**
- Modify: `lib/app/controllers/achievement_controller.dart`
- Modify: `lib/app/controllers/daily_mission_controller.dart`

### AchievementController

- [ ] **Step 1: 3 yeni report metodu ekle**

`achievement_controller.dart` içindeki "Raporlama" bölümüne (mevcut `reportBallsInGame` satırından sonra) ekle:

```dart
void reportBossDefeated()  => _increment(AchievementCounter.bossesDefeated, 1);
void reportPowerUpUsed()   => _increment(AchievementCounter.powerUpsUsed, 1);
void reportDayPlayed()     => _increment(AchievementCounter.daysPlayed, 1);
```

### DailyMissionController

- [ ] **Step 2: 3 yeni report metodu ekle**

`daily_mission_controller.dart` içindeki "Progress Raporlama" bölümüne (mevcut `reportScoreEarned` satırından sonra) ekle:

```dart
void reportBossDefeated()             => _addProgress(MissionType.defeatBoss, 1);
void reportPowerUpUsed()              => _addProgress(MissionType.usePowerUp, 1);
void reportLaserDestroyed(int count)  => _addProgress(MissionType.breakLasers, count);
```

- [ ] **Step 3: flutter analyze çalıştır**

```bash
cd /Users/aykut/StudioProjects/orbriot && flutter analyze lib/app/controllers/
```

Beklenen: 0 hata.

- [ ] **Step 4: Commit**

```bash
cd /Users/aykut/StudioProjects/orbriot
git add lib/app/controllers/achievement_controller.dart lib/app/controllers/daily_mission_controller.dart
git commit -m "feat: add boss/powerUp/day/laser report methods to controllers"
```

---

## Task 4: Hook Noktalarını Bağla

**Files:**
- Modify: `lib/app/controllers/game_controller.dart`
- Modify: `lib/app/views/game/widgets/power_up_bar.dart`
- Modify: `lib/app/controllers/daily_login_controller.dart`

### 4a. GameController — Boss Death Hook

- [ ] **Step 1: Boss death bloğuna report çağrıları ekle**

`game_controller.dart` içinde (satır ~306–312), mevcut `if (brick.type == BrickType.boss)` bloğunda `unawaited(Get.find<UpgradeController>().addGems(5));` satırının hemen altına ekle:

```dart
if (Get.isRegistered<AchievementController>()) {
  Get.find<AchievementController>().reportBossDefeated();
}
if (Get.isRegistered<DailyMissionController>()) {
  Get.find<DailyMissionController>().reportBossDefeated();
}
```

### 4b. GameController — _endTurn() Laser Hook

- [ ] **Step 2: _endTurn() içine laser DM hook'u ekle**

`game_controller.dart`, `_endTurn()` metodunda (satır ~562–569), mevcut DailyMissionController bloğunun içine `_shieldsThisTurn` satırından sonra ekle:

```dart
if (_lasersThisTurn > 0) dm.reportLaserDestroyed(_lasersThisTurn);
```

Tamamlanmış blok şöyle görünmeli:
```dart
if (Get.isRegistered<DailyMissionController>()) {
  final dm = Get.find<DailyMissionController>();
  if (_bricksThisTurn  > 0) dm.reportBricksDestroyed(_bricksThisTurn);
  if (_bombsThisTurn   > 0) dm.reportBombDestroyed(_bombsThisTurn);
  if (_shieldsThisTurn > 0) dm.reportShieldDestroyed(_shieldsThisTurn);
  if (_lasersThisTurn  > 0) dm.reportLaserDestroyed(_lasersThisTurn); // YENİ
  final scoreDelta = (gameState.value?.score ?? 0) - _scoreThisTurn;
  if (scoreDelta > 0) dm.reportScoreEarned(scoreDelta);
}
```

### 4c. power_up_bar.dart — PowerUp Hook

- [ ] **Step 3: _onTap() içine powerUp report hook'u ekle**

`power_up_bar.dart` içindeki `_onTap()` metodunda (satır ~193), `if (!used) return;` satırından hemen sonra ekle:

```dart
// Başarım ve günlük görev raporla
if (Get.isRegistered<AchievementController>()) {
  Get.find<AchievementController>().reportPowerUpUsed();
}
if (Get.isRegistered<DailyMissionController>()) {
  Get.find<DailyMissionController>().reportPowerUpUsed();
}
```

`power_up_bar.dart` dosyasına gerekli import'ları ekle (eğer yoksa):
```dart
import '../../../controllers/achievement_controller.dart';
import '../../../controllers/daily_mission_controller.dart';
```

### 4d. DailyLoginController — DayPlayed Hook

- [ ] **Step 4: claimToday() içine reportDayPlayed ekle**

`daily_login_controller.dart` içindeki `claimToday()` metodunda, `await Get.find<UpgradeController>().addGems(reward);` satırından hemen sonra ekle:

```dart
if (Get.isRegistered<AchievementController>()) {
  Get.find<AchievementController>().reportDayPlayed();
}
```

`daily_login_controller.dart` dosyasına import ekle (eğer yoksa):
```dart
import 'achievement_controller.dart';
```

- [ ] **Step 5: flutter analyze çalıştır**

```bash
cd /Users/aykut/StudioProjects/orbriot && flutter analyze lib/
```

Beklenen: 0 hata.

- [ ] **Step 6: Commit**

```bash
cd /Users/aykut/StudioProjects/orbriot
git add lib/app/controllers/game_controller.dart \
        lib/app/views/game/widgets/power_up_bar.dart \
        lib/app/controllers/daily_login_controller.dart
git commit -m "feat: wire boss/laser/powerUp/day hooks to achievement and mission controllers"
```

---

## Task 5: AchievementView Yeniden Tasarımı (Seri Kartları)

**Files:**
- Modify: `lib/app/views/achievements/achievement_view.dart`

### Genel Bakış
Mevcut tier-based gruplama (`_TierSection`) yerine series-based gruplama (`_SeriesCard`) yapılır.

Her seri kartı şunları gösterir:
- Seri adı + tier renk göstergesi
- Tier badge satırı: `[I ✓] [II →] [III ·]`
- Aktif tier progress bar + `X / Y` etiketi
- Claim butonu (ödül bekleniyorsa)

**Kart sıralama:**
1. Tüm tier'ları tamamlanmamış seriler — üstte (önce claim bekleyenler)
2. Tamamen tamamlanmış seriler — altta (altın border)

- [ ] **Step 1: Yardımcı veri modeli oluştur**

`achievement_view.dart` dosyasının üstüne (import'lardan sonra) şu yardımcı sınıfı ekle:

```dart
/// Bir serinin tüm achievement'larını gruplanmış halde tutar
class _SeriesGroup {
  final String name;
  final List<Achievement> achievements; // seriesOrder'a göre sıralı

  _SeriesGroup({required this.name, required this.achievements});

  /// Aktif (devam eden) tier indexi — tamamlanmamış ilk achievement
  int get activeIndex {
    for (int i = 0; i < achievements.length; i++) {
      if (!achievements[i].unlocked) return i;
    }
    return achievements.length; // hepsi tamamlandı
  }

  bool get isFullyCompleted => activeIndex == achievements.length;

  /// Claim bekleyen achievement var mı?
  bool get hasUnclaimed =>
      achievements.any((a) => a.unlocked && !a.claimed);

  /// Aktif tier rengi (aktif index'teki achievement'ın tier rengini döner)
  Color get activeColor {
    final idx = activeIndex.clamp(0, achievements.length - 1);
    return achievements[idx].def.tier.color;
  }
}
```

- [ ] **Step 2: Seri gruplama helper'ı ekle**

`AchievementView`'ın `build()` metodu içinde (ya da ayrı bir metod olarak) seriler şöyle gruplandırılır:

```dart
List<_SeriesGroup> _buildSeriesGroups(List<Achievement> achievements) {
  final map = <String, List<Achievement>>{};
  for (final a in achievements) {
    map.putIfAbsent(a.def.seriesName, () => []).add(a);
  }
  final groups = map.entries.map((e) {
    final sorted = List.of(e.value)
      ..sort((a, b) => a.def.seriesOrder.compareTo(b.def.seriesOrder));
    return _SeriesGroup(name: e.key, achievements: sorted);
  }).toList();

  // Sıralama: claim bekleyenler → devam edenler → tamamlanmışlar
  groups.sort((a, b) {
    if (a.isFullyCompleted != b.isFullyCompleted) {
      return a.isFullyCompleted ? 1 : -1;
    }
    if (a.hasUnclaimed != b.hasUnclaimed) {
      return a.hasUnclaimed ? -1 : 1;
    }
    return a.name.compareTo(b.name);
  });
  return groups;
}
```

- [ ] **Step 3: AchievementView.build() güncelle**

Mevcut `Obx` içindeki sliver listesini şu yapıyla değiştir:

```dart
body: Obx(() {
  final total    = controller.achievements.length;
  final unlocked = controller.achievements.where((a) => a.unlocked).length;
  final groups   = _buildSeriesGroups(controller.achievements);

  return CustomScrollView(
    slivers: [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: _SummaryCard(unlocked: unlocked, total: total),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SeriesCard(group: groups[i], controller: controller),
            ),
            childCount: groups.length,
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 32)),
    ],
  );
}),
```

> **Önemli:** `AchievementView` şu an `GetView<AchievementController>` extends ediyor (StatelessWidget alt sınıfı). `_buildSeriesGroups`, `AchievementView` sınıfına normal bir instance metod olarak eklenebilir — `StatefulWidget`'a dönüştürme GEREKMİYOR.

- [ ] **Step 4: _SeriesCard widget'ı oluştur**

Eski `_TierSection` ve `_AchievementCard` sınıflarının yerine (ya da yanına) şu widget'ı ekle:

```dart
class _SeriesCard extends StatelessWidget {
  const _SeriesCard({super.key, required this.group, required this.controller});
  final _SeriesGroup group;
  final AchievementController controller;

  @override
  Widget build(BuildContext context) {
    final g          = group;
    final activeIdx  = g.activeIndex;
    final isComplete = g.isFullyCompleted;
    final accentColor = isComplete ? AppColors.amber : g.activeColor;

    // Aktif achievement (progress bar için)
    final activeAch = activeIdx < g.achievements.length
        ? g.achievements[activeIdx]
        : g.achievements.last;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isComplete
              ? AppColors.amber.withAlpha(160)
              : accentColor.withAlpha(80),
          width: isComplete ? 1.5 : 1,
        ),
        boxShadow: g.hasUnclaimed
            ? [BoxShadow(color: accentColor.withAlpha(40), blurRadius: 12)]
            : null,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Başlık satırı ────────────────────────────────────────────
          Row(
            children: [
              Icon(activeAch.def.icon, color: accentColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  g.name.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.foreground,
                    letterSpacing: 1,
                  ),
                ),
              ),
              // Tier badge etiketi
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: accentColor.withAlpha(120)),
                ),
                child: Text(
                  isComplete ? 'TAMAM' : activeAch.def.tier.label,
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // ── Tier badge satırı ────────────────────────────────────────
          Row(
            children: [
              for (int i = 0; i < g.achievements.length; i++) ...[
                _TierBadge(
                  label: _romanNumeral(i + 1),
                  achievement: g.achievements[i],
                  isActive: i == activeIdx,
                  onClaim: g.achievements[i].unlocked && !g.achievements[i].claimed
                      ? () => controller.claimReward(g.achievements[i])
                      : null,
                ),
                if (i < g.achievements.length - 1) const SizedBox(width: 6),
              ],
            ],
          ),
          // ── Aktif tier progress ──────────────────────────────────────
          if (!isComplete) ...[
            const SizedBox(height: 10),
            Text(
              'Tier ${_romanNumeral(activeIdx + 1)} — ${activeAch.def.description}',
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 10,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: activeAch.progressFraction),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v,
                  minHeight: 5,
                  backgroundColor: AppColors.border.withAlpha(60),
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${activeAch.displayProgress} / ${activeAch.def.target}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                color: AppColors.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _romanNumeral(int n) {
    const map = {1: 'I', 2: 'II', 3: 'III', 4: 'IV', 5: 'V'};
    return map[n] ?? '$n';
  }
}
```

- [ ] **Step 5: _TierBadge widget'ı oluştur**

```dart
class _TierBadge extends StatelessWidget {
  const _TierBadge({
    required this.label,
    required this.achievement,
    required this.isActive,
    this.onClaim,
  });

  final String      label;
  final Achievement achievement;
  final bool        isActive;
  final VoidCallback? onClaim;

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.unlocked;
    final claimed  = achievement.claimed;
    final color    = achievement.def.tier.color;

    Color bgColor;
    Color borderColor;
    Widget icon;

    if (claimed) {
      bgColor     = AppColors.success.withAlpha(30);
      borderColor = AppColors.success.withAlpha(160);
      icon = Icon(Icons.check_rounded, size: 10, color: AppColors.success);
    } else if (unlocked && !claimed) {
      bgColor     = AppColors.amber.withAlpha(30);
      borderColor = AppColors.amber;
      icon = Icon(Icons.star_rounded, size: 10, color: AppColors.amber);
    } else if (isActive) {
      bgColor     = color.withAlpha(25);
      borderColor = color;
      icon = Text(
        label,
        style: TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      );
    } else {
      bgColor     = AppColors.surfaceVariant.withAlpha(60);
      borderColor = AppColors.border.withAlpha(60);
      icon = Text(
        label,
        style: const TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 9,
          color: AppColors.muted,
        ),
      );
    }

    return GestureDetector(
      onTap: (unlocked && !claimed) ? onClaim : null,
      child: Container(
        width: 32,
        height: 28,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor, width: isActive ? 1.5 : 1),
        ),
        alignment: Alignment.center,
        child: icon,
      ),
    );
  }
}
```

- [ ] **Step 6: Eski widget'ları kaldır, _SummaryCard'ı koru**

`achievement_view.dart` içinden şu sınıfları sil (artık kullanılmıyor):
- `_TierSection`
- `_AchievementCard`
- `_AchievementIcon`
- `_GemBadge`

**`_SummaryCard` KORUNUR** — özet kart (açık / toplam sayısı, progress bar) değişmez.

- [ ] **Step 7: flutter analyze çalıştır**

```bash
cd /Users/aykut/StudioProjects/orbriot && flutter analyze lib/app/views/achievements/
```

Beklenen: 0 hata.

- [ ] **Step 8: Commit**

```bash
cd /Users/aykut/StudioProjects/orbriot
git add lib/app/views/achievements/achievement_view.dart
git commit -m "feat: redesign AchievementView with series-grouped tier badge cards"
```

---

## Task 6: Doğrulama & Son Kontrol

- [ ] **Step 1: Tam proje analyze**

```bash
cd /Users/aykut/StudioProjects/orbriot && flutter analyze
```

Beklenen: 0 hata, 0 warning.

- [ ] **Step 2: Uygulamayı çalıştır ve manuel test et**

```bash
cd /Users/aykut/StudioProjects/orbriot && flutter run
```

Test kontrol listesi:
- [ ] Başarımlar ekranı açılıyor (crash yok)
- [ ] 12 seri kartı görünüyor (Nişancı, Sahne Fatihi, vb.)
- [ ] Tier badge'ler doğru renkte (starter=yeşil, mid=sarı, expert=kırmızı)
- [ ] Mevcut kazanılmış başarımların tier'ları değişmedi (`bricks_500` mid, `bricks_5000` expert)
- [ ] Oyun içinde boss öldürünce banner çıkıyor
- [ ] Günlük görev ekranında 3 görev geliyor (yeni tipler dahil gelebilir)
- [ ] Power-up kullanınca AchievementController'da sayaç artıyor (debug log ile doğrula)

- [ ] **Step 3: Final commit**

```bash
cd /Users/aykut/StudioProjects/orbriot
git add -A
git commit -m "feat: achievements & daily missions expansion — 50 achievements, 40 mission pool"
```

---

## Notlar

- `Icons.skull` mevcut değilse `Icons.dangerous_rounded` kullan
- `AchievementView` `GetView<AchievementController>` extends ediyor (StatelessWidget alt sınıfı). `_buildSeriesGroups` instance metod olarak sınıfa ekle — `StatefulWidget` dönüşümü gerekmez.
- Mevcut oyuncu verisi korunur: `SharedPreferences` key'leri değişmedi (`ach_unlocked_<id>`, `ach_claimed_<id>`, `ach_cnt_<counter_name>`). Yeni counter'lar (bossesDefeated vb.) yeni key'ler olarak otomatik eklenir.
- `_lasersThisTurn` sayacı `AchievementController.reportLaserDestroyed()` tarafından zaten (parametre olmadan) `_endTurn()`'de çağrılıyor. Yeni `dm.reportLaserDestroyed(_lasersThisTurn)` onun yanına eklenir — mevcut AC call değişmez.
