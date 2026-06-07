# Daily Mission (Günlük Görev) Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Her gün sıfırlanan 3 görev sistemi — oyuncuyu günlük oynamaya teşvik eder, tamamlayınca gem ödülü verir.

**Architecture:** `DailyMissionController` (GetxController, permanent) SharedPreferences'a görev listesini ve tarihi kaydeder; gün değişince yeni görevler üretir. `GameController` tur/sahne/oyun bitişlerinde controller'a event raporlar. HomeView'da bir badge butonu panel açar.

**Tech Stack:** Flutter, GetX (reactive state + DI), SharedPreferences, dart:convert (JSON), dart:math (Random)

---

## File Map

| Dosya | İşlem | Sorumluluk |
|-------|-------|------------|
| `lib/app/models/daily_mission.dart` | Yeni | MissionType enum + DailyMission model + JSON seri |
| `lib/app/controllers/daily_mission_controller.dart` | Yeni | Görev yükleme/kaydetme, progress raporlama, ödül dağıtma |
| `lib/app/views/home/widgets/daily_mission_panel.dart` | Yeni | BottomSheet panel + mission kartları |
| `lib/app/bindings/home_binding.dart` | Değiştir | DailyMissionController'ı permanent olarak kaydet |
| `lib/app/controllers/game_controller.dart` | Değiştir | Per-turn sayaçlar + DailyMissionController'a event aktar |
| `lib/app/views/home/home_view.dart` | Değiştir | Badge butonu ekle → panel aç |

---

## Task 1: DailyMission Model

**Files:**
- Create: `lib/app/models/daily_mission.dart`

- [ ] **Step 1: Dosyayı oluştur**

```dart
import 'dart:math';

enum MissionType {
  breakBricks,    // X tuğla kır
  playGames,      // X oyun oyna
  completeStages, // X sahne geç
  popBombs,       // Bomb tuğla patlat
  earnScore,      // X puan kazan
  breakShields,   // Shield tuğla kır
}

class DailyMission {
  final String id;
  final MissionType type;
  final int target;
  final int reward; // gem
  int progress;
  bool rewardClaimed;

  DailyMission({
    required this.id,
    required this.type,
    required this.target,
    required this.reward,
    this.progress = 0,
    this.rewardClaimed = false,
  });

  bool get isCompleted => progress >= target;

  void addProgress(int amount) {
    if (!isCompleted) {
      progress = (progress + amount).clamp(0, target);
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'target': target,
    'reward': reward,
    'progress': progress,
    'rewardClaimed': rewardClaimed,
  };

  factory DailyMission.fromJson(Map<String, dynamic> j) => DailyMission(
    id: j['id'] as String,
    type: MissionType.values.firstWhere((e) => e.name == j['type']),
    target: j['target'] as int,
    reward: j['reward'] as int,
    progress: j['progress'] as int? ?? 0,
    rewardClaimed: j['rewardClaimed'] as bool? ?? false,
  );
}

/// Görev havuzu: her entry (type, target, reward)
const _missionPool = [
  (MissionType.breakBricks,    10,  5),
  (MissionType.breakBricks,    25, 10),
  (MissionType.breakBricks,    50, 20),
  (MissionType.playGames,       1,  5),
  (MissionType.playGames,       3, 10),
  (MissionType.playGames,       5, 20),
  (MissionType.completeStages,  3,  5),
  (MissionType.completeStages,  5, 10),
  (MissionType.completeStages, 10, 20),
  (MissionType.popBombs,        1,  5),
  (MissionType.popBombs,        3, 10),
  (MissionType.earnScore,     100,  5),
  (MissionType.earnScore,     500, 10),
  (MissionType.earnScore,    1000, 20),
  (MissionType.breakShields,    1,  5),
  (MissionType.breakShields,    2, 10),
];

/// Her gün 3 adet görev üret — farklı type'lardan seç
List<DailyMission> generateDailyMissions(String dateKey) {
  final rng = Random(dateKey.hashCode); // seed = tarih → aynı gün aynı görevler
  final pool = List.of(_missionPool)..shuffle(rng);

  final selected = <DailyMission>[];
  final usedTypes = <MissionType>{};

  for (final entry in pool) {
    if (selected.length == 3) break;
    if (usedTypes.contains(entry.$1)) continue;
    usedTypes.add(entry.$1);
    selected.add(DailyMission(
      id: '${dateKey}_${entry.$1.name}',
      type: entry.$1,
      target: entry.$2,
      reward: entry.$3,
    ));
  }

  return selected;
}

/// Görev tipi için UI etiketi
String missionLabel(DailyMission m) {
  switch (m.type) {
    case MissionType.breakBricks:
      return '${m.target} tuğla kır';
    case MissionType.playGames:
      return '${m.target} oyun oyna';
    case MissionType.completeStages:
      return '${m.target} sahne geç';
    case MissionType.popBombs:
      return '${m.target} bomb tuğla patlat';
    case MissionType.earnScore:
      return '${m.target} puan kazan';
    case MissionType.breakShields:
      return '${m.target} shield tuğla kır';
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/app/models/daily_mission.dart
git commit -m "feat: add DailyMission model with mission pool and JSON serialization"
```

---

## Task 2: DailyMissionController

**Files:**
- Create: `lib/app/controllers/daily_mission_controller.dart`

- [ ] **Step 1: Dosyayı oluştur**

```dart
import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_mission.dart';
import 'upgrade_controller.dart';

class DailyMissionController extends GetxController {
  static const _kDate     = 'daily_missions_date';
  static const _kMissions = 'daily_missions_data';

  final RxList<DailyMission> missions = <DailyMission>[].obs;

  // Badge sayısı: tamamlanmış ama ödülü alınmamış görev sayısı
  int get unclaimedCount =>
      missions.where((m) => m.isCompleted && !m.rewardClaimed).length;

  @override
  void onInit() {
    super.onInit();
    _loadOrRefresh();
  }

  // ── Yükleme / Yenileme ───────────────────────────────────────────────────

  Future<void> _loadOrRefresh() async {
    final prefs   = await SharedPreferences.getInstance();
    final today   = _todayKey();
    final saved   = prefs.getString(_kDate);

    if (saved == today) {
      // Aynı gün → kayıtlı görevleri yükle
      final raw = prefs.getString(_kMissions);
      if (raw != null) {
        try {
          final list = (jsonDecode(raw) as List)
              .map((e) => DailyMission.fromJson(e as Map<String, dynamic>))
              .toList();
          missions.assignAll(list);
          return;
        } catch (_) { /* bozuksa yeniden üret */ }
      }
    }

    // Yeni gün veya ilk açılış → yeni görevler üret
    final newMissions = generateDailyMissions(today);
    missions.assignAll(newMissions);
    await _save(prefs, today);
  }

  Future<void> _save(SharedPreferences prefs, String dateKey) async {
    await prefs.setString(_kDate, dateKey);
    await prefs.setString(
      _kMissions,
      jsonEncode(missions.map((m) => m.toJson()).toList()),
    );
  }

  Future<void> _saveNow() async {
    final prefs = await SharedPreferences.getInstance();
    await _save(prefs, _todayKey());
  }

  // ── Progress Raporlama ───────────────────────────────────────────────────

  void reportBricksDestroyed(int count) =>
      _addProgress(MissionType.breakBricks, count);

  void reportGamePlayed() =>
      _addProgress(MissionType.playGames, 1);

  void reportStageCompleted() =>
      _addProgress(MissionType.completeStages, 1);

  void reportBombDestroyed(int count) =>
      _addProgress(MissionType.popBombs, count);

  void reportShieldDestroyed(int count) =>
      _addProgress(MissionType.breakShields, count);

  void reportScoreEarned(int score) =>
      _addProgress(MissionType.earnScore, score);

  void _addProgress(MissionType type, int amount) {
    bool changed = false;
    for (final m in missions) {
      if (m.type == type && !m.isCompleted) {
        m.addProgress(amount);
        changed = true;
      }
    }
    if (changed) {
      missions.refresh();
      _saveNow();
    }
  }

  // ── Ödül Alma ────────────────────────────────────────────────────────────

  Future<void> claimReward(DailyMission mission) async {
    if (!mission.isCompleted || mission.rewardClaimed) return;
    mission.rewardClaimed = true;
    missions.refresh();
    await Get.find<UpgradeController>().addGems(mission.reward);
    await _saveNow();
  }

  // ── Yardımcı ─────────────────────────────────────────────────────────────

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/app/controllers/daily_mission_controller.dart
git commit -m "feat: add DailyMissionController with daily reset, progress tracking, and reward claiming"
```

---

## Task 3: HomeBinding Kaydı

**Files:**
- Modify: `lib/app/bindings/home_binding.dart`

- [ ] **Step 1: Import ekle ve controller'ı kaydet**

`home_binding.dart` dosyasına import ve kayıt ekle:

```dart
// Eklenecek import (diğerlerin altına):
import '../controllers/daily_mission_controller.dart';
```

`dependencies()` metoduna ekle (diğer `if (!Get.isRegistered...)` bloklarından sonra):

```dart
if (!Get.isRegistered<DailyMissionController>()) {
  Get.put<DailyMissionController>(DailyMissionController(), permanent: true);
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/app/bindings/home_binding.dart
git commit -m "feat: register DailyMissionController as permanent in HomeBinding"
```

---

## Task 4: GameController Event Hooks

**Files:**
- Modify: `lib/app/controllers/game_controller.dart`

GameController'a 3 per-turn sayaç ekle ve 4 noktada DailyMissionController'ı bilgilendir.

- [ ] **Step 1: Per-turn sayaç alanlarını ekle**

Sınıf alanlarına ekle (diğer field'ların yanına, örn. `_dangerPhase` civarı):

```dart
// Günlük görev sayaçları (tur başında sıfırlanır)
int _bricksThisTurn  = 0;
int _bombsThisTurn   = 0;
int _shieldsThisTurn = 0;
int _scoreThisTurn   = 0;
```

- [ ] **Step 2: Import ekle**

Dosyanın üstüne (diğer importların altına):

```dart
import 'daily_mission_controller.dart';
```

- [ ] **Step 3: Sayaçları tur başında sıfırla ve skoru yakala**

`_launchBalls()` metodunda `gameState.value = state.copyWith(turnPhase: TurnPhase.shooting);` satırından ÖNCE ekle:

```dart
// Tur sayaçlarını sıfırla; skoru tur BAŞINDA yakala (delta hesabı için)
_bricksThisTurn  = 0;
_bombsThisTurn   = 0;
_shieldsThisTurn = 0;
_scoreThisTurn   = state.score; // state burada zaten mevcut
```

- [ ] **Step 4: Fizik tick'inde sayaçları artır**

`for (final brick in result.hitBricks)` döngüsünde, `!brick.isAlive` bloğuna ekle (mevcut `destroyedThisTick++` satırından sonra):

```dart
_bricksThisTurn++;
if (brick.type == BrickType.bomb)   _bombsThisTurn++;
if (brick.type == BrickType.shield) _shieldsThisTurn++;
```

- [ ] **Step 5: Tur sonunda raporla**

`_endTurn()` metodunda, `gameState.value = state.copyWith(turnPhase: TurnPhase.settling);` satırından SONRA ekle:

```dart
// Günlük görev raporlama
if (Get.isRegistered<DailyMissionController>()) {
  final dm = Get.find<DailyMissionController>();
  if (_bricksThisTurn  > 0) dm.reportBricksDestroyed(_bricksThisTurn);
  if (_bombsThisTurn   > 0) dm.reportBombDestroyed(_bombsThisTurn);
  if (_shieldsThisTurn > 0) dm.reportShieldDestroyed(_shieldsThisTurn);
  final scoreDelta = (gameState.value?.score ?? 0) - _scoreThisTurn;
  if (scoreDelta > 0) dm.reportScoreEarned(scoreDelta);
  // NOT: _scoreThisTurn bir sonraki _launchBalls() çağrısında sıfırlanır
}
```

- [ ] **Step 6: Oyun bitişinde raporla**

`_triggerGameOver()` metoduna, `final prefs = await SharedPreferences.getInstance();` satırından ÖNCE ekle:

```dart
if (Get.isRegistered<DailyMissionController>()) {
  Get.find<DailyMissionController>().reportGamePlayed();
}
```

- [ ] **Step 7: Sahne bitişinde raporla**

`_triggerStageComplete()` metoduna, `final completedStage = state.stage;` satırından SONRA ekle:

```dart
if (Get.isRegistered<DailyMissionController>()) {
  Get.find<DailyMissionController>().reportStageCompleted();
}
```

- [ ] **Step 8: Commit**

```bash
git add lib/app/controllers/game_controller.dart
git commit -m "feat: add per-turn brick counters and DailyMission event reporting to GameController"
```

---

## Task 5: DailyMissionPanel Widget

**Files:**
- Create: `lib/app/views/home/widgets/daily_mission_panel.dart`

- [ ] **Step 1: Widget'ı oluştur**

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/daily_mission_controller.dart';
import '../../../models/daily_mission.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// Ana ekranda badge'e tıklanınca açılan bottom sheet
void showDailyMissionPanel(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _DailyMissionSheet(),
  );
}

class _DailyMissionSheet extends GetView<DailyMissionController> {
  const _DailyMissionSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tutaç
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text('GÜNLÜK GÖREVLER', style: AppTextStyles.hudLabel),
          const SizedBox(height: 4),
          Obx(() {
            final tomorrow = _tomorrowMidnight();
            return Text(
              'Yenileniyor: $tomorrow',
              style: AppTextStyles.bodySmall,
            );
          }),
          const SizedBox(height: 20),
          Obx(() => Column(
            children: controller.missions
                .map((m) => _MissionCard(mission: m))
                .toList(),
          )),
        ],
      ),
    );
  }

  String _tomorrowMidnight() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return '${tomorrow.day}.${tomorrow.month.toString().padLeft(2, '0')}.${tomorrow.year}';
  }
}

class _MissionCard extends GetView<DailyMissionController> {
  const _MissionCard({required this.mission});
  final DailyMission mission;

  @override
  Widget build(BuildContext context) {
    final progress = (mission.progress / mission.target).clamp(0.0, 1.0);
    final done = mission.isCompleted;
    final claimed = mission.rewardClaimed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: done ? AppColors.primary.withAlpha(160) : AppColors.border,
          width: done ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  missionLabel(mission),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: claimed
                        ? AppColors.foreground.withAlpha(100)
                        : AppColors.foreground,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Ödül claim butonu veya gem göstergesi
              if (done && !claimed)
                GestureDetector(
                  onTap: () => controller.claimReward(mission),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.diamond_outlined, size: 13, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          '+${mission.reward}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.diamond_outlined,
                      size: 13,
                      color: AppColors.foreground.withAlpha(claimed ? 80 : 160),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${mission.reward}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.foreground.withAlpha(claimed ? 80 : 160),
                      ),
                    ),
                    if (claimed) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.check_circle, size: 15, color: AppColors.primary.withAlpha(180)),
                    ],
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          // İlerleme çubuğu
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.border.withAlpha(80),
              valueColor: AlwaysStoppedAnimation<Color>(
                claimed ? AppColors.primary.withAlpha(80) : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${mission.progress} / ${mission.target}',
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 11,
              color: AppColors.foreground.withAlpha(120),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/app/views/home/widgets/daily_mission_panel.dart
git commit -m "feat: add DailyMissionPanel bottom sheet with mission cards and claim UI"
```

---

## Task 6: HomeView Badge Entegrasyonu

**Files:**
- Modify: `lib/app/views/home/home_view.dart`

- [ ] **Step 1: Import ekle**

`home_view.dart` dosyasının importlarına ekle:

```dart
import '../../controllers/daily_mission_controller.dart';
import 'widgets/daily_mission_panel.dart';
```

- [ ] **Step 2: Badge butonunu ekle**

`HomeView`'da, ayarlar butonunun bulunduğu `Align` widget'ının içindeki `Padding`'i `Row` ile sararak görev butonunu soluna ekle. Mevcut:
```dart
Align(
  alignment: Alignment.centerRight,
  child: Padding(
    padding: const EdgeInsets.only(top: 8, right: 0),
    child: IconButton(
      icon: const Icon(Icons.settings_rounded,
          color: AppColors.muted, size: 22),
      onPressed: () => Get.toNamed(AppRoutes.settings),
      tooltip: 'Ayarlar',
    ),
  ),
),
```

Bunu şununla değiştir:
```dart
Align(
  alignment: Alignment.centerRight,
  child: Padding(
    padding: const EdgeInsets.only(top: 8, right: 0),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Günlük görev badge
        Obx(() {
          final dm = Get.find<DailyMissionController>();
          final count = dm.unclaimedCount;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.task_alt_rounded,
                    color: AppColors.muted, size: 22),
                onPressed: () => showDailyMissionPanel(context),
                tooltip: 'Günlük Görevler',
              ),
              if (count > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF97316),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          );
        }),
        IconButton(
          icon: const Icon(Icons.settings_rounded,
              color: AppColors.muted, size: 22),
          onPressed: () => Get.toNamed(AppRoutes.settings),
          tooltip: 'Ayarlar',
        ),
      ],
    ),
  ),
),
```

- [ ] **Step 3: Commit**

```bash
git add lib/app/views/home/home_view.dart
git commit -m "feat: add daily mission badge button to HomeView"
```

---

## Doğrulama

- [ ] Uygulama açılıyor ve Home ekranında görev ikonu görünüyor
- [ ] İkona tıklayınca panel açılıyor, 3 görev listeli
- [ ] Oyun oynandığında "X oyun oyna" görevi ilerliyor (game over'dan sonra kontrol et)
- [ ] Tuğla kırınca "tuğla kır" görevi ilerliyor
- [ ] Sahne geçince "sahne geç" görevi ilerliyor
- [ ] Görev tamamlanınca ödül butonu çıkıyor, tıklayınca gem ekleniyor
- [ ] Uygulama kapatılıp açılınca progress korunuyor
- [ ] Tarih değişince (veya tarihi değiştirerek simüle edince) görevler sıfırlanıyor

---

*Plan tarihi: 2026-03-20*
