class GameConstants {
  GameConstants._();

  // ── iPad / Tablet ölçekleme ────────────────────────────────────
  // Referans genişlik: iPhone 14 (390pt). Daha geniş ekranlarda
  // tüm sabit piksel değerleri orantılı büyür.
  static const double _referenceWidth = 390.0;
  static double _scaleFactor = 1.0;

  /// Ekran genişliğine göre ölçek faktörünü günceller.
  /// GameController.initGame() içinden çağrılır.
  static void updateScale(double screenWidth) {
    _scaleFactor = (screenWidth / _referenceWidth).clamp(1.0, 2.0);
  }

  static double get scaleFactor => _scaleFactor;

  // ── Fizik (temel değerler) ─────────────────────────────────────
  static const double _baseBallSpeed = 600.0;
  static const double _baseBallRadius = 12.5;

  static double get ballSpeed  => _baseBallSpeed * _scaleFactor;
  static double get ballRadius => _baseBallRadius * _scaleFactor;

  // Top fırlatma gecikmesi (sıralı fırlatma)
  static const int launchDelayMs = 80;

  // ── Grid ───────────────────────────────────────────────────────
  static const int gridColumns = 7;
  static const int gridRows = 10; // görünür satır sayısı (game over sınırı)

  static const double _baseBrickGap = 4.0;
  static const double _baseBrickPadding = 8.0;

  static double get brickGap     => _baseBrickGap * _scaleFactor;
  static double get brickPadding => _baseBrickPadding * _scaleFactor;

  static const double hudHeight = 72.0;
  static const double ballAreaHeight = 72.0; // alttaki fırlatma bölgesi

  // Skor
  static const int scorePerBrick = 10;
  static const int scoreBonusPerLevel = 50;

  // Seviye başına yeni satır top sayısı eşikleri
  static const int bricksPerRow = 4; // satırda kaç tuğla çıkar (max 6)

  // ── Nişan çizgisi ──────────────────────────────────────────────
  static const int aimDotCount = 12;
  static const double _baseAimDotSpacing = 24.0;
  static double get aimDotSpacing => _baseAimDotSpacing * _scaleFactor;

  // ── Continue mekanizması ───────────────────────────────────────
  static const int maxContinues = 2;      // oyun başına maksimum devam hakkı
  static const int continueCostGems = 10; // gem ile devam maliyeti
  static const int continueShiftRows = 2; // devamda tuğlaların kayacağı satır sayısı
  static const double continueShiftMs = 400; // kayma animasyonu süresi (ms)
}
