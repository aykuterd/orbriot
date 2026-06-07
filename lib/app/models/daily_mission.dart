import 'dart:math';
import 'package:get/get.dart';

enum MissionType {
  breakBricks,    // X tuğla kır
  playGames,      // X oyun oyna
  completeStages, // X sahne geç
  popBombs,       // Bomb tuğla patlat
  earnScore,      // X puan kazan
  breakShields,   // Shield tuğla kır
  usePowerUp,     // X power-up kullan
  defeatBoss,     // X boss öldür
  breakLasers,    // X laser tuğla kır
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

/// Görev havuzu: her entry (type, target, reward) — 40 entry, 9 tip
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

/// Her gün 3 adet görev üret — farklı type'lardan seç
/// C(9,3) = 84 farklı kombinasyon
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
  final key = switch (m.type) {
    MissionType.breakBricks    => 'mission_break_bricks',
    MissionType.playGames      => 'mission_play_games',
    MissionType.completeStages => 'mission_complete_stages',
    MissionType.popBombs       => 'mission_pop_bombs',
    MissionType.earnScore      => 'mission_earn_score',
    MissionType.breakShields   => 'mission_break_shields',
    MissionType.usePowerUp     => 'mission_use_power_up',
    MissionType.defeatBoss     => 'mission_defeat_boss',
    MissionType.breakLasers    => 'mission_break_lasers',
  };
  return key.trParams({'n': m.target.toString()});
}
