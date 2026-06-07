import 'dart:ui';

enum BrickType {
  normal,      // HP'si olan standart tuğla
  triangle,    // ikizkenar dik üçgen — hipotenüs açılı yansıma
  stone,       // çift HP'li sert taş
  bomb,        // patladığında çevresindeki tuğlaları da vurur
  chain,       // yok edilince rastgele bir başka tuğlaya da hasar verir
  shield,      // ilk vuruşta kalkan kırılır, hasar almaz; sonraki vuruşlar normal
  multiplier,  // yok edilince 2 ekstra top kazandırır
  laserH,      // tek seferlik yatay lazer — tüm satırı yok eder
  laserV,      // tek seferlik dikey lazer — tüm sütunu yok eder
  boss,        // 2×2 dev tuğla — Her 5. sahnede, yüksek HP, özel görsel
}

/// Üçgen tuğlanın hipotenüs yönü.
/// slash  = "/" şekli (TL-TR-BL köşeleri) — hipotenüs TR'den BL'ye
/// backslash = "\" şekli (TL-TR-BR köşeleri) — hipotenüs TL'den BR'ye
enum TriangleOrientation { slash, backslash }

class Brick {
  final int col;
  final int row;
  int hp;
  final int maxHp;
  final BrickType type;
  final TriangleOrientation? triangleOrientation; // sadece triangle türü için
  bool isAlive;
  bool shieldActive; // sadece shield türü için

  /// Çarpışma anında başlatılan parlama zamanlayıcısı (saniye).
  /// 0.25'ten başlar, 0'a inerken neon flash efekti zayıflar.
  double hitFlashTimer = 0.0;

  Rect get rect => Rect.fromLTWH(
        col * (BrickConfig.size + BrickConfig.gap) + BrickConfig.padding,
        row * (BrickConfig.size + BrickConfig.gap) + BrickConfig.topOffset,
        BrickConfig.size,
        BrickConfig.size,
      );

  /// Boss tuğla için 2×2 hücre kaplayan genişletilmiş dikdörtgen.
  Rect get bossRect => Rect.fromLTWH(
        col * (BrickConfig.size + BrickConfig.gap) + BrickConfig.padding,
        row * (BrickConfig.size + BrickConfig.gap) + BrickConfig.topOffset,
        BrickConfig.size * 2 + BrickConfig.gap,
        BrickConfig.size * 2 + BrickConfig.gap,
      );

  Brick({
    required this.col,
    required this.row,
    required this.hp,
    required this.maxHp,
    this.type = BrickType.normal,
    this.triangleOrientation,
    this.isAlive = true,
    bool? shieldActive,
  }) : shieldActive = shieldActive ?? (type == BrickType.shield);

  double get hpRatio => hp / maxHp;

  Brick movedDown() => Brick(
        col: col,
        row: row + 1,
        hp: hp,
        maxHp: maxHp,
        type: type,
        triangleOrientation: triangleOrientation,
        isAlive: isAlive,
        shieldActive: shieldActive,
      );

  void hit(int damage) {
    hitFlashTimer = 0.25; // çarpışma parlaması başlat
    if (shieldActive) {
      shieldActive = false; // kalkan kırılır, hasar uygulanmaz
      return;
    }
    hp -= damage;
    if (hp <= 0) {
      hp = 0;
      isAlive = false;
    }
  }
}

/// Tuğla boyut ve konum sabitleri.
/// Gerçek değerler GameController'da ekran genişliğine göre ayarlanır.
class BrickConfig {
  static double size    = 56.0;
  static double gap     = 4.0;
  static double padding = 8.0;
  static double topOffset = 0.0;
  static int    columns = 6;
}
