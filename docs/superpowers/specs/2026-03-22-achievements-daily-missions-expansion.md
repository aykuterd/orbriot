# Achievements & Daily Missions Genişletme — Tasarım Spesifikasyonu

**Tarih:** 2026-03-22
**Sprint:** Sprint 2/3 — Retention İyileştirme
**Kapsam:** 13 → 50 başarım (tier-based seri sistemi), daily mission pool 16 → 40 entry

---

## 1. Amaç

- Başarım sistemini 13'ten 50'ye çıkarmak (Clash of Clans tarzı I/II/III tier'lı seriler)
- Daily mission havuzunu genişletmek (6 tip × az entry → 9 tip × 40 entry)
- Mevcut oyuncu verisi korunmalı (SharedPreferences migration gerekmez)

---

## 2. Model Değişiklikleri

### 2.1 AchievementDef — 2 Yeni Alan

```dart
class AchievementDef {
  // ... mevcut alanlar ...
  final String seriesName;  // "Tuğla Yıkıcı", "Nişancı" vb.
  final int    seriesOrder; // serideki sıra: 1, 2, 3, 4, 5
}
```

Tüm mevcut `AchievementDef` entry'lerine bu iki alan eklenir.
Mevcut ID'ler değişmez — mevcut oyuncu ilerlemesi korunur.

### 2.2 AchievementCounter — 3 Yeni Değer

```dart
enum AchievementCounter {
  // ... mevcut 9 değer ...
  bossesDefeated,  // boss tuğla öldürüldüğünde artar
  powerUpsUsed,    // power-up aktive edildiğinde artar
  daysPlayed,      // her günlük girişte 1 artar
}
```

### 2.3 MissionType — 3 Yeni Değer

```dart
enum MissionType {
  // ... mevcut 6 değer ...
  usePowerUp,   // X power-up kullan
  defeatBoss,   // X boss öldür
  breakLasers,  // X laser tuğla kır
}
```

---

## 3. Achievement Kataloğu (50 Başarım — 12 Seri)

### Tier Renk/Sınıf Kararı

**Tier her entry için tabloda AÇIKÇA belirtilir** — `seriesOrder`'dan otomatik hesaplanmaz.
Bu sayede mevcut oyuncu verisiyle görsel tutarsızlık yaşanmaz (backward-compat).

Genel kılavuz (mevcut ID'ler için mevcut tier korunur):
- seriesOrder 1-2 → genellikle `starter` (yeşil)
- seriesOrder 3-4 → genellikle `mid` (sarı)
- seriesOrder 5+  → genellikle `expert` (kırmızı/pembe)
- Kısa seriler (3-4 elem) için tier seri uzunluğuna göre esnetilir

### Seri 1 — Nişancı (`shotsFired`)
| ID | seriesOrder | target | reward | tier |
|----|-------------|--------|--------|------|
| `first_shot` *(mevcut)* | 1 | 1 | 5 | starter |
| `shots_100` | 2 | 100 | 10 | starter |
| `shots_1000` | 3 | 1000 | 25 | mid |
| `shots_5000` | 4 | 5000 | 40 | mid |
| `shots_20000` | 5 | 20000 | 80 | expert |

### Seri 2 — Sahne Fatihi (`stagesCompleted`)
| ID | seriesOrder | target | reward | tier |
|----|-------------|--------|--------|------|
| `first_stage` *(mevcut)* | 1 | 1 | 5 | starter |
| `stages_10` | 2 | 10 | 10 | starter |
| `stages_50` *(mevcut)* | 3 | 50 | 20 | mid |
| `stages_200` | 4 | 200 | 50 | mid |
| `stages_500` *(mevcut)* | 5 | 500 | 100 | expert |

### Seri 3 — Gem Avcısı (`gemsEarned`)
| ID | seriesOrder | target | reward | tier |
|----|-------------|--------|--------|------|
| `first_gem` *(mevcut)* | 1 | 1 | 5 | starter |
| `gems_100` *(mevcut — tier korundu: mid)* | 2 | 100 | 25 | **mid** |
| `gems_1000` | 3 | 1000 | 50 | mid |
| `gems_10000` | 4 | 10000 | 100 | mid |
| `gems_50000` | 5 | 50000 | 200 | expert |

### Seri 4 — Mağaza Ustası (`upgradesBought`)
| ID | seriesOrder | target | reward | tier |
|----|-------------|--------|--------|------|
| `first_upgrade` *(mevcut)* | 1 | 1 | 10 | starter |
| `upgrades_5` | 2 | 5 | 20 | starter |
| `upgrades_20` | 3 | 20 | 50 | mid |
| `upgrades_50` | 4 | 50 | 100 | mid |

### Seri 5 — Tuğla Yıkıcı (`totalBricks`)
| ID | seriesOrder | target | reward | tier |
|----|-------------|--------|--------|------|
| `bricks_100` | 1 | 100 | 10 | starter |
| `bricks_500` *(mevcut — tier korundu: mid)* | 2 | 500 | 20 | **mid** |
| `bricks_2500` | 3 | 2500 | 35 | mid |
| `bricks_5000` *(mevcut — tier korundu: expert)* | 4 | 5000 | 65 | **expert** |
| `bricks_50000` | 5 | 50000 | 120 | expert |

### Seri 6 — Bomba Ustası (`totalBombs`)
| ID | seriesOrder | target | reward | tier |
|----|-------------|--------|--------|------|
| `bombs_5` | 1 | 5 | 10 | starter |
| `bombs_20` *(mevcut — tier korundu: mid)* | 2 | 20 | 20 | **mid** |
| `bombs_100` | 3 | 100 | 50 | expert |

### Seri 7 — Lazer Ustası (`totalLasers`)
| ID | seriesOrder | target | reward | tier |
|----|-------------|--------|--------|------|
| `lasers_5` | 1 | 5 | 10 | starter |
| `lasers_10` *(mevcut — tier korundu: mid)* | 2 | 10 | 20 | **mid** |
| `lasers_100` | 3 | 100 | 50 | expert |

### Seri 8 — Top Hakimi (`maxBallsInGame`)
| ID | seriesOrder | target | reward | tier |
|----|-------------|--------|--------|------|
| `balls_10` | 1 | 10 | 15 | starter |
| `balls_30` | 2 | 30 | 30 | mid |
| `max_balls_50` *(mevcut)* | 3 | 50 | 50 | expert |
| `balls_100` | 4 | 100 | 100 | expert |

### Seri 9 — Combo Ustası (`maxBricksInTurn`)
| ID | seriesOrder | target | reward | tier |
|----|-------------|--------|--------|------|
| `combo_10` | 1 | 10 | 10 | starter |
| `combo_20` | 2 | 20 | 20 | mid |
| `bricks_turn_30` *(mevcut)* | 3 | 30 | 30 | expert |
| `combo_50` | 4 | 50 | 60 | expert |

### Seri 10 — Boss Avcısı (`bossesDefeated` — YENİ)
| ID | seriesOrder | target | reward | tier |
|----|-------------|--------|--------|------|
| `boss_1` | 1 | 1 | 10 | starter |
| `boss_10` | 2 | 10 | 30 | mid |
| `boss_50` | 3 | 50 | 75 | expert |
| `boss_100` | 4 | 100 | 150 | expert |

### Seri 11 — Power-Up Ustası (`powerUpsUsed` — YENİ)
| ID | seriesOrder | target | reward | tier |
|----|-------------|--------|--------|------|
| `pu_1` | 1 | 1 | 5 | starter |
| `pu_10` | 2 | 10 | 20 | mid |
| `pu_50` | 3 | 50 | 40 | mid |
| `pu_200` | 4 | 200 | 80 | expert |

### Seri 12 — Sadık Oyuncu (`daysPlayed` — YENİ)
| ID | seriesOrder | target | reward | tier |
|----|-------------|--------|--------|------|
| `days_3` | 1 | 3 | 15 | starter |
| `days_7` | 2 | 7 | 30 | mid |
| `days_30` | 3 | 30 | 100 | expert |
| `days_100` | 4 | 100 | 200 | expert |

**Toplam: 50 başarım (13 mevcut korundu, 37 yeni)**

---

## 4. AchievementController Değişiklikleri

### Yeni Report Metodları

```dart
void reportBossDefeated()   => _increment(AchievementCounter.bossesDefeated, 1);
void reportPowerUpUsed()    => _increment(AchievementCounter.powerUpsUsed, 1);
void reportDayPlayed()      => _increment(AchievementCounter.daysPlayed, 1);
```

### Hook Noktaları
| Metod | Nerede çağrılır |
|-------|----------------|
| `reportBossDefeated()` | `GameController._tick()` — boss brick `!isAlive` bloğu (satır ~306) |
| `reportPowerUpUsed()` | `PowerUpInventoryController.useCharge()` — başarılı şarj kullanımında |
| `reportDayPlayed()` | `DailyLoginController.claimToday()` — günlük bonus alınınca |

**Boss hook detayı:** `GameController._tick()` içindeki mevcut `if (brick.type == BrickType.boss)` bloğuna ekle:
```dart
Get.find<AchievementController>().reportBossDefeated();
Get.find<DailyMissionController>().reportBossDefeated();
```
`_bossesThisTurn` sayacı gerekmez çünkü her sahne yalnızca bir boss içerir; doğrudan call yeterli.

> **ÖNEMLİ NOT — Laser Signature:** Mevcut `AchievementController.reportLaserDestroyed()` metodu parametre almaz ve değiştirilmez. `GameController._endTurn()` bu metodu halihazırda parametre olmadan çağırıyor (satır ~577). Yeni `DailyMissionController.reportLaserDestroyed(int count)` farklı bir controller'da farklı bir imzadır — aralarında çakışma yoktur.

---

## 5. AchievementView UI Yeniden Tasarımı

### Seri Kartı Düzeni

```
╔══════════════════════════════════════════╗
║  🧱  TUĞLA YIKICI              [MID]     ║
║  ──────────────────────────────────────  ║
║  [I ✓] [II ✓] [III →] [IV ·] [V ·]      ║
║                                          ║
║  Tier III — 2500 tuğla kır               ║
║  ████████████░░░░  1847 / 2500           ║
║                              [+35💎 AL]  ║
╚══════════════════════════════════════════╝
```

### Tier Badge Durumları
- **Tamamlanmış + ödül alındı** → `✓` yeşil dolu badge, tıklanamaz
- **Tamamlanmış + ödül bekliyor** → `✓` altın badge, yanıp söner, tıklanınca ödül alınır
- **Aktif (devam ediyor)** → `→` tier rengiyle vurgulanmış, progress bar altında
- **Kilitli** → `·` gri, soluk

### Kart Sıralama
1. Devam eden seriler (aktif tier tamamlanmamış) — üstte, `unclaimedCount > 0` olanlar en üst
2. Tamamen tamamlanmış seriler — altta, altın border

### Tier Renk Mantığı
Kartın border/accent rengi aktif tier'a göre belirlenir:
- seriesOrder 1-2 → `AppColors.success` (#22C55E)
- seriesOrder 3-4 → `AppColors.amber` (#F59E0B)
- seriesOrder 5+ → `AppColors.accent` (#F43F5E)

---

## 6. Daily Mission Pool Genişletme

### Yeni DailyMissionController Metodları
```dart
void reportBossDefeated()            => _addProgress(MissionType.defeatBoss, 1);
void reportPowerUpUsed()             => _addProgress(MissionType.usePowerUp, 1);
void reportLaserDestroyed(int count) => _addProgress(MissionType.breakLasers, count);
```

### Yeni MissionType Hook Noktaları
| Tip | Nerede raporlanır |
|-----|------------------|
| `usePowerUp` | `lib/app/views/game/widgets/power_up_bar.dart` — `if (!used) return;` guard'ından sonra |
| `defeatBoss` | `GameController._tick()` — boss `!isAlive` bloğu → `DailyMissionController.reportBossDefeated()` |
| `breakLasers` | `GameController._endTurn()` — mevcut `_lasersThisTurn` sayacı kullanılarak → `if (_lasersThisTurn > 0) dm.reportLaserDestroyed(_lasersThisTurn);` |

**usePowerUp hook kodu (power_up_bar.dart):**
```dart
final used = await widget.inventory.useCharge(widget.type);
if (!used) return;
// --- EKLENECEK ---
Get.find<AchievementController>().reportPowerUpUsed();
Get.find<DailyMissionController>().reportPowerUpUsed();
// -----------------
```
Bu yaklaşım mevcut mimari pattern'e uygundur; `PowerUpInventoryController` diğer controller'lara bağımlı olmaz.

### Yeni `missionLabel` Entry'leri
```dart
case MissionType.usePowerUp:   return '${m.target} power-up kullan';
case MissionType.defeatBoss:   return '${m.target} boss öldür';
case MissionType.breakLasers:  return '${m.target} laser tuğla kır';
```

### Genişletilmiş Pool (40 entry)

```dart
const _missionPool = [
  // breakBricks (5)
  (MissionType.breakBricks,    25,  10),
  (MissionType.breakBricks,    50,  15),
  (MissionType.breakBricks,   100,  25),
  (MissionType.breakBricks,   200,  40),
  (MissionType.breakBricks,   500,  60),
  // playGames (5)
  (MissionType.playGames,       1,   5),
  (MissionType.playGames,       3,  10),
  (MissionType.playGames,       5,  20),
  (MissionType.playGames,      10,  35),
  (MissionType.playGames,      25,  60),
  // completeStages (5)
  (MissionType.completeStages,  3,   5),
  (MissionType.completeStages,  7,  12),
  (MissionType.completeStages, 15,  25),
  (MissionType.completeStages, 30,  40),
  (MissionType.completeStages, 50,  60),
  // popBombs (5)
  (MissionType.popBombs,        1,   5),
  (MissionType.popBombs,        3,  10),
  (MissionType.popBombs,        8,  20),
  (MissionType.popBombs,       20,  35),
  (MissionType.popBombs,       50,  60),
  // earnScore (5)
  (MissionType.earnScore,     200,   5),
  (MissionType.earnScore,     500,  12),
  (MissionType.earnScore,    1500,  25),
  (MissionType.earnScore,    5000,  40),
  (MissionType.earnScore,   10000,  60),
  // breakShields (3)
  (MissionType.breakShields,    1,   5),
  (MissionType.breakShields,    3,  10),
  (MissionType.breakShields,    8,  20),
  // usePowerUp (4)
  (MissionType.usePowerUp,      1,   5),
  (MissionType.usePowerUp,      3,  10),
  (MissionType.usePowerUp,      8,  20),
  (MissionType.usePowerUp,     15,  30),
  // defeatBoss (3)
  (MissionType.defeatBoss,      1,  10),
  (MissionType.defeatBoss,      3,  20),
  (MissionType.defeatBoss,      5,  35),
  // breakLasers (5)
  (MissionType.breakLasers,     3,   8),
  (MissionType.breakLasers,     8,  15),
  (MissionType.breakLasers,    20,  25),
  (MissionType.breakLasers,    40,  40),
  (MissionType.breakLasers,    80,  60),
];
```

**Kombinasyon artışı: C(6,3) = 20 → C(9,3) = 84 farklı günlük görev seti**

---

## 7. Kapsam Dışı

- AchievementView'ın tier geçişinde animasyon efekti (ileride eklenebilir)
- Mission tiplerine göre ikon farklılaştırması (mevcut ikon sistemi yeterli)
- Başarım paylaşma (Sprint 5 online özellikler)
