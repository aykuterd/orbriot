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

  void reportBossDefeated()             => _addProgress(MissionType.defeatBoss, 1);
  void reportPowerUpUsed()              => _addProgress(MissionType.usePowerUp, 1);
  void reportLaserDestroyed(int count)  => _addProgress(MissionType.breakLasers, count);

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
