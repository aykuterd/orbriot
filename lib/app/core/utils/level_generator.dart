import 'dart:math';
import '../../models/brick.dart';
import '../../models/bonus_ball.dart';
import '../../models/power_up_cell.dart';
import 'constants.dart';

class LevelGenerator {
  static final Random _rng = Random();

  /// Her turda gelen yeni satırı oluşturur.
  ///
  /// [turnNumber]: Bu sahnede kaçıncı tur (1'den başlar).
  /// Yeni satırın **temel HP'si = turnNumber**, stage'e göre
  /// üst sınır ve yoğunluk ölçeklenir.
  ///
  /// Stage 1: max HP  5, az yoğun (3-4 tuğla)
  /// Stage 2: max HP  5, biraz daha yoğun
  /// Stage 5: max HP  6, yoğun (4-5 tuğla)
  /// Stage 6: max HP 10, çok yoğun (5-6 tuğla)
  /// Stage 10+: max HP 15+, tam yoğun (5-7 tuğla)
  static List<Brick> generateRow(int stage, int rowIndex, {int turnNumber = 1}) {
    final bricks = <Brick>[];

    // Tuğla türü şansları (stage 1-2'de özel tuğla yok)
    final s = max(0, stage - 2);
    final stoneChance      = (s * 0.025).clamp(0.0, 0.20);
    final bombChance       = (s * 0.012).clamp(0.0, 0.10);
    final triChance        = (stage * 0.030).clamp(0.0, 0.25);
    final chainChance      = (s * 0.015).clamp(0.0, 0.12);
    final shieldChance     = (s * 0.012).clamp(0.0, 0.10);
    final multiplierChance = (s * 0.010).clamp(0.0, 0.08);
    final laserHChance     = (s * 0.005).clamp(0.0, 0.04);
    final laserVChance     = (s * 0.005).clamp(0.0, 0.04);

    // Satır başına tuğla sayısı (stage arttıkça yoğunluk artar):
    //   Stage 1-3: 3-4 tuğla (%43-57 doluluk)
    //   Stage 4-6: 4-5 tuğla (%57-71 doluluk)
    //   Stage 7+ : 5-7 tuğla (%71-100 doluluk)
    final minCount = stage <= 3 ? 3 : stage <= 6 ? 4 : 5;
    final maxCount = stage <= 3 ? 4 : stage <= 6 ? 5 : 7;
    final count = (minCount + _rng.nextInt(maxCount - minCount + 1))
        .clamp(minCount, GameConstants.gridColumns);

    // Stage'e göre HP üst sınırı:
    //   Stage 1-4: max 5
    //   Stage 5  : max 6
    //   Stage 6  : max 10
    //   Stage 7+ : max 10 + (stage-6)×2,  max 30
    final stageMaxHp = stage <= 4
        ? 5
        : stage == 5
            ? 6
            : (10 + (stage - 6) * 2).clamp(10, 30);

    // Tur bazlı temel HP: tur arttıkça HP yükselir
    final baseHp = turnNumber.clamp(1, stageMaxHp);

    final cols = List.generate(GameConstants.gridColumns, (i) => i)..shuffle(_rng);
    final activeCols = cols.sublist(0, count);

    for (final col in activeCols) {
      final roll = _rng.nextDouble();
      BrickType type;
      int hp;
      TriangleOrientation? orientation;

      if (roll < bombChance) {
        type = BrickType.bomb;
        hp   = max(1, baseHp - 1);
      } else if (roll < bombChance + stoneChance) {
        type = BrickType.stone;
        hp   = (baseHp * 1.8).round().clamp(1, stageMaxHp);
      } else if (roll < bombChance + stoneChance + chainChance) {
        type = BrickType.chain;
        hp   = _turnHp(baseHp, stageMaxHp);
      } else if (roll < bombChance + stoneChance + chainChance + shieldChance) {
        type = BrickType.shield;
        hp   = _turnHp(baseHp, stageMaxHp);
      } else if (roll < bombChance + stoneChance + chainChance + shieldChance + multiplierChance) {
        type = BrickType.multiplier;
        hp   = _turnHp(baseHp, stageMaxHp);
      } else if (roll < bombChance + stoneChance + chainChance + shieldChance + multiplierChance + laserHChance) {
        type = BrickType.laserH;
        hp   = 1;
      } else if (roll < bombChance + stoneChance + chainChance + shieldChance + multiplierChance + laserHChance + laserVChance) {
        type = BrickType.laserV;
        hp   = 1;
      } else if (roll < bombChance + stoneChance + chainChance + shieldChance + multiplierChance + laserHChance + laserVChance + triChance) {
        type        = BrickType.triangle;
        orientation = _rng.nextBool()
            ? TriangleOrientation.slash
            : TriangleOrientation.backslash;
        hp = _turnHp(baseHp, stageMaxHp);
      } else {
        type = BrickType.normal;
        hp   = _turnHp(baseHp, stageMaxHp);
      }

      bricks.add(Brick(
        col: col,
        row: rowIndex,
        hp: hp,
        maxHp: hp,
        type: type,
        triangleOrientation: orientation,
      ));
    }

    return bricks;
  }

  /// Tur bazlı HP hesaplama — baseHp etrafında hafif varyasyon.
  /// Bazı tuğlalar baseHp-1, bazıları baseHp+1 olabilir.
  static int _turnHp(int baseHp, int maxHp) {
    // ±1 varyasyon (baseHp küçükse sadece yukarı)
    final variance = _rng.nextInt(3) - 1; // -1, 0, +1
    return (baseHp + variance).clamp(1, maxHp);
  }

  static BonusBall? generateBonusBall(
      int level, int rowIndex, List<Brick> rowBricks) {
    // Stage 1-2: %40
    // Stage 3-5: %45
    // Stage 6+ : %50'den kademeli artış, max %70
    final chance = level <= 2
        ? 0.40
        : level <= 5
            ? 0.45
            : (0.50 + (level - 5) * 0.012).clamp(0.50, 0.70);
    if (_rng.nextDouble() > chance) return null;

    final occupied = rowBricks.map((b) => b.col).toSet();
    final freeCols = List.generate(GameConstants.gridColumns, (i) => i)
        .where((c) => !occupied.contains(c))
        .toList();
    if (freeCols.isEmpty) return null;

    final col = freeCols[_rng.nextInt(freeCols.length)];
    // Stage 5'ten itibaren %15 ihtimalle eksi top (erken seviyelerde eksi yok)
    final isMinus = level >= 5 && _rng.nextDouble() < 0.15;
    return BonusBall(
      col: col,
      row: rowIndex,
      type: isMinus ? BonusBallType.minus : BonusBallType.plus,
    );
  }

  /// Sahne başlangıcı — sadece ilk tur tuğlaları (HP 1).
  ///
  /// Sonraki turlar GameController tarafından `generateRow(stage, 0, turnNumber: N)`
  /// ile eklenir. Her turda HP artarak devam eder.
  ///
  /// Sahne başında başlangıç satır sayısı stage'e göre:
  ///   Stage 1-2: 2 satır (yumuşak başlangıç)
  ///   Stage 3-5: 3 satır
  ///   Stage 6+ : 4 satır
  static ({List<Brick> bricks, List<BonusBall> bonusBalls}) generateStage(int stage) {
    final bricks     = <Brick>[];
    final bonusBalls = <BonusBall>[];

    // Başlangıç satır sayısı
    final initialRows = stage <= 2 ? 2 : stage <= 5 ? 3 : 4;

    for (int row = 0; row < initialRows; row++) {
      // Sahne başı = tur 1, tüm başlangıç tuğlaları HP 1
      final rowBricks = generateRow(stage, row, turnNumber: 1);
      bricks.addAll(rowBricks);

      final bonus = generateBonusBall(stage, row, rowBricks);
      if (bonus != null) bonusBalls.add(bonus);
    }

    // ── Boss Tuğla (Her 5. Sahne) ─────────────────────────────────────────
    // Stage 5, 10, 15 … → merkeze yakın sütunda 2×2 boss tuğla eklenir.
    // Boss HP sahneyle ölçeklenir; onun kapladığı 4 hücredeki diğer tuğlalar
    // ve bonuslar listeden çıkarılır (görsel çakışmayı önlemek için).
    if (stage % 5 == 0) {
      final bossCol = (GameConstants.gridColumns ~/ 2 - 1).clamp(0, GameConstants.gridColumns - 2);
      const bossRow = 0;
      final bossHp  = (stage * 2).clamp(10, 50);

      bool inBossZone(int c, int r) =>
          (c == bossCol || c == bossCol + 1) && (r == bossRow || r == bossRow + 1);

      bricks.removeWhere((b) => inBossZone(b.col, b.row));
      bonusBalls.removeWhere((b) => inBossZone(b.col, b.row));

      bricks.insert(0, Brick(
        col:   bossCol,
        row:   bossRow,
        hp:    bossHp,
        maxHp: bossHp,
        type:  BrickType.boss,
      ));
    }

    return (bricks: bricks, bonusBalls: bonusBalls);
  }


  /// Sahne başında toplam HP'yi önceden tahmin eder (progress bar için).
  ///
  /// classicTarget kadar tuğla kırılana dek kaç satır geleceğini,
  /// her satırın HP'sini ve ortalama tuğla sayısını hesaplar.
  static int estimateStageTotalHp(int stage) {
    final target = 25 + stage * 10; // classicTarget
    final initialRows = stage <= 2 ? 2 : stage <= 5 ? 3 : 4;
    final avgPerRow = stage <= 3 ? 3.5 : stage <= 6 ? 4.5 : 6.0;
    final stageMaxHp = stage <= 4
        ? 5
        : stage == 5
            ? 6
            : (10 + (stage - 6) * 2).clamp(10, 30);
    final rowInterval = stage <= 4 ? 2 : 1;

    // Başlangıç satırları: hepsi HP 1
    double totalHp = initialRows * avgPerRow * 1.0;
    int bricksEstimate = (initialRows * avgPerRow).round();

    // Sonraki turlar
    int turn = 0;
    while (bricksEstimate < target) {
      turn++;
      if (turn % rowInterval == 0) {
        final hp = turn.clamp(1, stageMaxHp);
        totalHp += avgPerRow * hp;
        bricksEstimate += avgPerRow.round();
      }
    }

    return max(1, totalHp.round());
  }

  /// Yeni satırla birlikte rastgele bir power-up hücresi oluşturur.
  ///
  /// Stage 3'ten itibaren aktif olur; stage arttıkça şans yükselir.
  /// Bonus top ve tuğlaların olmadığı boş sütunlardan birine yerleştirilir.
  static PowerUpCell? generatePowerUpCell(
      int stage, int rowIndex, List<Brick> rowBricks) {
    if (stage < 3) return null;

    // Stage 3: %8, Stage 5: ~%12, Stage 10: ~%20, max %30
    final chance = (0.06 + stage * 0.014).clamp(0.0, 0.30);
    if (_rng.nextDouble() > chance) return null;

    // Tuğla sütunlarını dışla (power-up tuğlayla çakışmasın)
    final occupied = rowBricks.map((b) => b.col).toSet();
    final freeCols = List.generate(GameConstants.gridColumns, (i) => i)
        .where((c) => !occupied.contains(c))
        .toList();
    if (freeCols.isEmpty) return null;

    final col = freeCols[_rng.nextInt(freeCols.length)];

    // Ağırlıklı tip seçimi — nuke nadir, diğerleri eşit
    final types = [
      PowerUpType.fireball,   // 25%
      PowerUpType.fireball,   // 25%
      PowerUpType.multiBall,  // 25%
      PowerUpType.speedBoost, // 12.5%
      PowerUpType.shieldRow,  // 6.25%
      PowerUpType.nuke,       // 6.25%
    ];
    final type = types[_rng.nextInt(types.length)];

    return PowerUpCell(col: col, row: rowIndex, type: type);
  }

}
