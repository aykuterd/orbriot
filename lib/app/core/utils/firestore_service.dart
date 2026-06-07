import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/upgrade_controller.dart';
import '../../controllers/achievement_controller.dart';
import '../../controllers/skin_controller.dart';
import '../../controllers/power_up_inventory_controller.dart';
import '../../models/achievement.dart';
import '../../models/power_up_cell.dart';
import '../../models/upgrade_config.dart';
import 'auth_service.dart';

/// Cloud Firestore veri yönetim servisi.
/// Kullanıcı profili, leaderboard ve haftalık turnuva.
class FirestoreService extends GetxService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final AuthService _auth;

  // ── Koleksiyon referansları ──────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _db.collection('users');

  CollectionReference<Map<String, dynamic>> get _leaderboardCol =>
      _db.collection('leaderboard');

  CollectionReference<Map<String, dynamic>> get _weeklyCol =>
      _db.collection('weekly_tournament');

  Timer? _autoSaveTimer;

  Future<FirestoreService> init() async {
    _auth = Get.find<AuthService>();
    return this;
  }

  // ── Otomatik Cloud Save (debounced) ───────────────────────────────────

  /// Değişiklik olduğunda çağrılır. 5 saniye debounce ile toplu kaydeder.
  /// Böylece hızlı ardışık değişikliklerde Firestore'a spam atmaz.
  void autoSave() {
    // Sadece bağlı (linked) hesaplar için otomatik kaydet
    if (_auth.uid == null) return;
    if (!_auth.isLinked.value) return;

    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 5), () {
      _performAutoSave();
    });
  }

  Future<void> _performAutoSave() async {
    try {
      final uid = _auth.uid;
      if (uid == null) return;

      // Controller'lar hazır mı kontrol et
      if (!Get.isRegistered<UpgradeController>()) return;
      if (!Get.isRegistered<SkinController>()) return;
      if (!Get.isRegistered<AchievementController>()) return;
      if (!Get.isRegistered<PowerUpInventoryController>()) return;

      final upgrades = Get.find<UpgradeController>();
      final skins = Get.find<SkinController>();
      final achievements = Get.find<AchievementController>();
      final inventory = Get.find<PowerUpInventoryController>();
      final prefs = await SharedPreferences.getInstance();

      // Upgrade seviyeleri
      final upgradeLevels = <String, int>{};
      for (final def in UpgradeCatalog.all) {
        upgradeLevels[def.key] = upgrades.levelOf(def.key);
      }

      // Başarım sayaçları
      final achievementCounters = <String, int>{};
      for (final c in AchievementCounter.values) {
        achievementCounters[c.name] =
            prefs.getInt('ach_cnt_${c.name}') ?? 0;
      }

      // Açılmış ve ödül alınmış başarımlar
      final unlockedAchs = <String>[];
      final claimedAchs = <String>[];
      for (final a in achievements.achievements) {
        if (a.unlocked) unlockedAchs.add(a.id);
        if (a.claimed) claimedAchs.add(a.id);
      }

      // Power-up şarjları
      final puCharges = <String, int>{};
      for (final type in PowerUpType.values) {
        puCharges[type.name] = inventory.chargesOf(type);
      }

      // DisplayName — mevcut profildeki adı koru
      final existingProfile = await getUserProfile();
      final displayName = existingProfile?['displayName'] ?? 'Player';

      await saveFullProgress(
        displayName: displayName,
        highScore: prefs.getInt('high_score') ?? 0,
        bestStage: prefs.getInt('best_stage') ?? 0,
        totalGems: upgrades.gems.value,
        prestigeLevel: upgrades.prestigeLevel.value,
        upgradeLevels: upgradeLevels,
        achievementCounters: achievementCounters,
        unlockedAchievements: unlockedAchs,
        claimedAchievements: claimedAchs,
        unlockedSkins: skins.unlockedIds.toList(),
        activeSkinId: skins.activeSkinId.value,
        powerUpCharges: puCharges,
      );

      debugPrint('[FirestoreService] Otomatik kayıt tamamlandı');
    } catch (e) {
      debugPrint('[FirestoreService] Otomatik kayıt hatası: $e');
    }
  }

  @override
  void onClose() {
    _autoSaveTimer?.cancel();
    super.onClose();
  }

  // ── Kullanıcı Profili ───────────────────────────────────────────────────

  /// Kullanıcı profilini Firestore'a kaydet / güncelle.
  Future<void> saveUserProfile({
    required String displayName,
    required int highScore,
    required int totalGems,
    required int prestigeLevel,
    required int totalBricksDestroyed,
    required int totalGamesPlayed,
  }) async {
    final uid = _auth.uid;
    if (uid == null) return;

    await _usersCol.doc(uid).set({
      'displayName': displayName,
      'highScore': highScore,
      'totalGems': totalGems,
      'prestigeLevel': prestigeLevel,
      'totalBricksDestroyed': totalBricksDestroyed,
      'totalGamesPlayed': totalGamesPlayed,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Kullanıcı adını değiştir (sadece displayName).
  Future<void> updateDisplayName(String name) async {
    final uid = _auth.uid;
    if (uid == null) return;

    await _usersCol.doc(uid).update({
      'displayName': name,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  /// Kullanıcı profilini getir.
  Future<Map<String, dynamic>?> getUserProfile() async {
    final uid = _auth.uid;
    if (uid == null) return null;

    try {
      final doc = await _usersCol.doc(uid).get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      // İlk erişimde document yoksa veya izin hatası
      return null;
    }
  }

  // ── Tam İlerleme Kaydetme (Cloud Save) ──────────────────────────────────

  /// Tüm oyun ilerlemesini tek seferde Firestore'a kaydet.
  /// SharedPreferences'tan okunan tüm veriyi alır ve buluta yazar.
  Future<void> saveFullProgress({
    required String displayName,
    required int highScore,
    required int bestStage,
    required int totalGems,
    required int prestigeLevel,
    // Upgrade seviyeleri: {'extra_balls': 3, 'ball_speed': 1, ...}
    required Map<String, int> upgradeLevels,
    // Başarım sayaçları: {'shotsFired': 150, 'stagesCompleted': 20, ...}
    required Map<String, int> achievementCounters,
    // Açılmış başarımlar: ['first_shot', 'shots_100', ...]
    required List<String> unlockedAchievements,
    // Ödülü alınmış başarımlar
    required List<String> claimedAchievements,
    // Açılmış skinler: ['default', 'neon_blue', ...]
    required List<String> unlockedSkins,
    // Aktif skin ID
    required String activeSkinId,
    // Power-up şarjları: {'fireball': 5, 'nuke': 2, ...}
    required Map<String, int> powerUpCharges,
  }) async {
    final uid = _auth.uid;
    if (uid == null) return;

    await _usersCol.doc(uid).set({
      'displayName': displayName,
      'highScore': highScore,
      'bestStage': bestStage,
      'totalGems': totalGems,
      'prestigeLevel': prestigeLevel,
      'upgradeLevels': upgradeLevels,
      'achievementCounters': achievementCounters,
      'unlockedAchievements': unlockedAchievements,
      'claimedAchievements': claimedAchievements,
      'unlockedSkins': unlockedSkins,
      'activeSkinId': activeSkinId,
      'powerUpCharges': powerUpCharges,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Buluttan tüm ilerlemeyi yükle. Yoksa null döner.
  Future<Map<String, dynamic>?> loadFullProgress() async {
    final uid = _auth.uid;
    if (uid == null) return null;

    try {
      final doc = await _usersCol.doc(uid).get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  // ── Global Leaderboard ──────────────────────────────────────────────────

  /// Skoru leaderboard'a kaydet (sadece high score ise günceller).
  Future<void> submitScore({
    required int score,
    required String displayName,
    required int prestigeLevel,
  }) async {
    final uid = _auth.uid;
    if (uid == null) return;

    final docRef = _leaderboardCol.doc(uid);
    final existing = await docRef.get();

    // Sadece mevcut skordan yüksekse güncelle
    if (!existing.exists || (existing.data()?['score'] ?? 0) < score) {
      await docRef.set({
        'uid': uid,
        'displayName': displayName,
        'score': score,
        'prestigeLevel': prestigeLevel,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Global top 100 skor tablosu.
  Future<List<Map<String, dynamic>>> getGlobalLeaderboard({
    int limit = 100,
  }) async {
    final snapshot = await _leaderboardCol
        .orderBy('score', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => {
      ...doc.data(),
      'docId': doc.id,
    }).toList();
  }

  /// Kullanıcının global sıralamasını bul.
  Future<int?> getUserRank() async {
    final uid = _auth.uid;
    if (uid == null) return null;

    final userDoc = await _leaderboardCol.doc(uid).get();
    if (!userDoc.exists) return null;

    final userScore = userDoc.data()?['score'] ?? 0;
    final aboveCount = await _leaderboardCol
        .where('score', isGreaterThan: userScore)
        .count()
        .get();

    return (aboveCount.count ?? 0) + 1;
  }

  /// Kullanıcının global leaderboard bilgisini getir (rank + skor + isim).
  Future<Map<String, dynamic>?> getUserGlobalEntry() async {
    final uid = _auth.uid;
    if (uid == null) return null;

    final userDoc = await _leaderboardCol.doc(uid).get();
    if (!userDoc.exists) return null;

    final data = userDoc.data()!;
    final userScore = data['score'] ?? 0;
    final aboveCount = await _leaderboardCol
        .where('score', isGreaterThan: userScore)
        .count()
        .get();

    return {
      ...data,
      'docId': uid,
      'rank': (aboveCount.count ?? 0) + 1,
    };
  }

  /// Kullanıcının haftalık turnuva bilgisini getir (rank + skor + isim).
  Future<Map<String, dynamic>?> getUserWeeklyEntry() async {
    final uid = _auth.uid;
    if (uid == null) return null;

    final weekId = _currentWeekId;
    final userDoc = await _weeklyCol
        .doc(weekId)
        .collection('scores')
        .doc(uid)
        .get();
    if (!userDoc.exists) return null;

    final data = userDoc.data()!;
    final userScore = data['score'] ?? 0;
    final aboveCount = await _weeklyCol
        .doc(weekId)
        .collection('scores')
        .where('score', isGreaterThan: userScore)
        .count()
        .get();

    return {
      ...data,
      'docId': uid,
      'rank': (aboveCount.count ?? 0) + 1,
    };
  }

  // ── Haftalık Turnuva ────────────────────────────────────────────────────

  /// Mevcut haftanın ID'si (ISO hafta formatı: 2026-W13).
  String get _currentWeekId {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final weekNumber = ((dayOfYear - now.weekday + 10) / 7).floor();
    return '${now.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }

  /// Haftalık turnuvaya skor gönder.
  Future<void> submitWeeklyScore({
    required int score,
    required String displayName,
  }) async {
    final uid = _auth.uid;
    if (uid == null) return;

    final weekId = _currentWeekId;
    final docRef = _weeklyCol.doc(weekId).collection('scores').doc(uid);
    final existing = await docRef.get();

    if (!existing.exists || (existing.data()?['score'] ?? 0) < score) {
      await docRef.set({
        'uid': uid,
        'displayName': displayName,
        'score': score,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Haftalık turnuva sıralaması.
  Future<List<Map<String, dynamic>>> getWeeklyLeaderboard({
    int limit = 100,
  }) async {
    final weekId = _currentWeekId;
    final snapshot = await _weeklyCol
        .doc(weekId)
        .collection('scores')
        .orderBy('score', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => {
      ...doc.data(),
      'docId': doc.id,
    }).toList();
  }

  /// Haftalık turnuvada kullanıcının sırası.
  Future<int?> getUserWeeklyRank() async {
    final uid = _auth.uid;
    if (uid == null) return null;

    final weekId = _currentWeekId;
    final userDoc = await _weeklyCol
        .doc(weekId)
        .collection('scores')
        .doc(uid)
        .get();

    if (!userDoc.exists) return null;

    final userScore = userDoc.data()?['score'] ?? 0;
    final aboveCount = await _weeklyCol
        .doc(weekId)
        .collection('scores')
        .where('score', isGreaterThan: userScore)
        .count()
        .get();

    return (aboveCount.count ?? 0) + 1;
  }
}
