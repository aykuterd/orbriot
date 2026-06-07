import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/bonus_ball.dart';
import '../../models/brick.dart';
import '../../models/game_state.dart';
import '../../models/power_up_cell.dart';

/// Oyun durumunu SharedPreferences'a kaydedip geri yükleyen servis.
/// Klasik ve Sonsuz mod için ayrı kayıt slotları kullanır.
class GameSaveService {
  static const _kClassicSave = 'saved_game_classic';
  static const _kEndlessSave = 'saved_game_endless';

  static String _key(GameMode mode) =>
      mode == GameMode.classic ? _kClassicSave : _kEndlessSave;

  // ── Kayıtlı oyun var mı? ─────────────────────────────────────────────────

  static Future<bool> hasSavedGame(GameMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_key(mode));
  }

  static Future<Map<GameMode, bool>> savedGames() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      GameMode.classic: prefs.containsKey(_kClassicSave),
      GameMode.endless: prefs.containsKey(_kEndlessSave),
    };
  }

  // ── Kaydet ────────────────────────────────────────────────────────────────

  static Future<void> save({
    required GameState state,
    required GameMode mode,
    required int stageBricksDestroyed,
    required int stageDamageDealt,
    required int stageTotalHp,
    required int turnCount,
    required int streakCount,
    required int continueCount,
    required double screenWidth,
    required double screenHeight,
  }) async {
    final data = {
      'mode': mode.index,
      'score': state.score,
      'level': state.level,
      'stage': state.stage,
      'ballCount': state.ballCount,
      'launchX': state.launchX,
      'screenWidth': screenWidth,
      'screenHeight': screenHeight,
      // Dahili sayaçlar
      'stageBricksDestroyed': stageBricksDestroyed,
      'stageDamageDealt': stageDamageDealt,
      'stageTotalHp': stageTotalHp,
      'turnCount': turnCount,
      'streakCount': streakCount,
      'continueCount': continueCount,
      // Tuğlalar
      'bricks': state.bricks
          .where((b) => b.isAlive)
          .map((b) => _brickToJson(b))
          .toList(),
      // Bonus toplar
      'bonusBalls': state.bonusBalls
          .where((b) => !b.isCollected)
          .map((b) => _bonusBallToJson(b))
          .toList(),
      // Power-up hücreleri
      'powerUpCells': state.powerUpCells
          .where((p) => !p.isCollected)
          .map((p) => _powerUpCellToJson(p))
          .toList(),
      // Kayıt zamanı
      'savedAt': DateTime.now().toIso8601String(),
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(mode), jsonEncode(data));
  }

  // ── Yükle ─────────────────────────────────────────────────────────────────

  static Future<SavedGameData?> load(GameMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key(mode));
    if (json == null) return null;

    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      return SavedGameData(
        mode: GameMode.values[data['mode'] as int],
        score: data['score'] as int,
        level: data['level'] as int,
        stage: data['stage'] as int,
        ballCount: data['ballCount'] as int,
        launchX: (data['launchX'] as num).toDouble(),
        screenWidth: (data['screenWidth'] as num).toDouble(),
        screenHeight: (data['screenHeight'] as num).toDouble(),
        stageBricksDestroyed: data['stageBricksDestroyed'] as int,
        stageDamageDealt: data['stageDamageDealt'] as int,
        stageTotalHp: data['stageTotalHp'] as int,
        turnCount: data['turnCount'] as int,
        streakCount: data['streakCount'] as int,
        continueCount: data['continueCount'] as int,
        bricks: (data['bricks'] as List).map((b) => _brickFromJson(b)).toList(),
        bonusBalls:
            (data['bonusBalls'] as List).map((b) => _bonusBallFromJson(b)).toList(),
        powerUpCells: (data['powerUpCells'] as List)
            .map((p) => _powerUpCellFromJson(p))
            .toList(),
      );
    } catch (_) {
      // Bozuk kayıt — sil
      await delete(mode);
      return null;
    }
  }

  // ── Sil ───────────────────────────────────────────────────────────────────

  static Future<void> delete(GameMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(mode));
  }

  // ── JSON dönüşümleri ─────────────────────────────────────────────────────

  static Map<String, dynamic> _brickToJson(Brick b) => {
        'col': b.col,
        'row': b.row,
        'hp': b.hp,
        'maxHp': b.maxHp,
        'type': b.type.index,
        'tri': b.triangleOrientation?.index,
        'shield': b.shieldActive,
      };

  static Brick _brickFromJson(dynamic j) {
    final m = j as Map<String, dynamic>;
    return Brick(
      col: m['col'] as int,
      row: m['row'] as int,
      hp: m['hp'] as int,
      maxHp: m['maxHp'] as int,
      type: BrickType.values[m['type'] as int],
      triangleOrientation: m['tri'] != null
          ? TriangleOrientation.values[m['tri'] as int]
          : null,
      shieldActive: m['shield'] as bool? ?? false,
    );
  }

  static Map<String, dynamic> _bonusBallToJson(BonusBall b) => {
        'col': b.col,
        'row': b.row,
        'type': b.type.index,
      };

  static BonusBall _bonusBallFromJson(dynamic j) {
    final m = j as Map<String, dynamic>;
    return BonusBall(
      col: m['col'] as int,
      row: m['row'] as int,
      type: BonusBallType.values[m['type'] as int],
    );
  }

  static Map<String, dynamic> _powerUpCellToJson(PowerUpCell p) => {
        'col': p.col,
        'row': p.row,
        'type': p.type.index,
      };

  static PowerUpCell _powerUpCellFromJson(dynamic j) {
    final m = j as Map<String, dynamic>;
    return PowerUpCell(
      col: m['col'] as int,
      row: m['row'] as int,
      type: PowerUpType.values[m['type'] as int],
    );
  }
}

/// Yüklenen kayıtlı oyun verisi.
class SavedGameData {
  final GameMode mode;
  final int score;
  final int level;
  final int stage;
  final int ballCount;
  final double launchX;
  final double screenWidth;
  final double screenHeight;
  final int stageBricksDestroyed;
  final int stageDamageDealt;
  final int stageTotalHp;
  final int turnCount;
  final int streakCount;
  final int continueCount;
  final List<Brick> bricks;
  final List<BonusBall> bonusBalls;
  final List<PowerUpCell> powerUpCells;

  const SavedGameData({
    required this.mode,
    required this.score,
    required this.level,
    required this.stage,
    required this.ballCount,
    required this.launchX,
    required this.screenWidth,
    required this.screenHeight,
    required this.stageBricksDestroyed,
    required this.stageDamageDealt,
    required this.stageTotalHp,
    required this.turnCount,
    required this.streakCount,
    required this.continueCount,
    required this.bricks,
    required this.bonusBalls,
    required this.powerUpCells,
  });
}
