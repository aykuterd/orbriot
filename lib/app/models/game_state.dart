import 'ball.dart';
import 'bonus_ball.dart';
import 'brick.dart';
import 'power_up_cell.dart';

enum GameMode {
  classic, // Seviye bazlı: X tuğla kır → sonraki seviye
  endless, // Sonsuz: hayatta kal, puan topla
}

enum TurnPhase {
  aiming,    // Oyuncu nişan alıyor
  shooting,  // Toplar uçuyor
  settling,  // Toplar dönüyor, tur bitiyor
}

enum GameStatus {
  playing,
  paused,
  gameOver,
}

class GameState {
  final List<Ball> balls;
  final List<Brick> bricks;
  final List<BonusBall> bonusBalls;
  final List<PowerUpCell> powerUpCells;

  final int score;
  final int level;  // tur sayacı (dahili kullanım)
  final int stage;  // gerçek oyun seviyesi (HUD'da gösterilen)
  final int ballCount; // sahip olunan top sayısı

  final TurnPhase turnPhase;
  final GameStatus status;

  // Nişan çizgisi açısı (radyan) — null: henüz nişan alınmadı
  final double? aimAngle;

  // İlk topu geri dönen yeri: tur sonunda tüm toplar buraya gelir
  final double launchX;

  const GameState({
    required this.balls,
    required this.bricks,
    required this.bonusBalls,
    required this.powerUpCells,
    required this.score,
    required this.level,
    required this.stage,
    required this.ballCount,
    required this.turnPhase,
    required this.status,
    required this.launchX,
    this.aimAngle,
  });

  // Oyun başlangıcı için sıfır durumu
  factory GameState.initial(double screenWidth) {
    return GameState(
      balls: [],
      bricks: [],
      bonusBalls: [],
      powerUpCells: [],
      score: 0,
      level: 1,
      stage: 1,
      ballCount: 1,
      turnPhase: TurnPhase.aiming,
      status: GameStatus.playing,
      launchX: screenWidth / 2,
    );
  }

  // Kaç top henüz aktif uçuyor
  int get activeBallCount => balls.where((b) => b.isActive).length;

  // Tüm aktif toplar geri dönüp dönmedi
  bool get allBallsReturned =>
      balls.isNotEmpty && balls.every((b) => b.hasReturned);

  // Herhangi bir tuğla son satıra ulaştı mı (game over koşulu)
  bool isGameOver(int maxRows) =>
      bricks.any((b) => b.isAlive && b.row >= maxRows);

  GameState copyWith({
    List<Ball>? balls,
    List<Brick>? bricks,
    List<BonusBall>? bonusBalls,
    List<PowerUpCell>? powerUpCells,
    int? score,
    int? level,
    int? stage,
    int? ballCount,
    TurnPhase? turnPhase,
    GameStatus? status,
    double? launchX,
    double? aimAngle,
    bool clearAimAngle = false,
  }) {
    return GameState(
      balls: balls ?? this.balls,
      bricks: bricks ?? this.bricks,
      bonusBalls: bonusBalls ?? this.bonusBalls,
      powerUpCells: powerUpCells ?? this.powerUpCells,
      score: score ?? this.score,
      level: level ?? this.level,
      stage: stage ?? this.stage,
      ballCount: ballCount ?? this.ballCount,
      turnPhase: turnPhase ?? this.turnPhase,
      status: status ?? this.status,
      launchX: launchX ?? this.launchX,
      aimAngle: clearAimAngle ? null : (aimAngle ?? this.aimAngle),
    );
  }
}
