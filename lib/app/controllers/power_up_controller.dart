import 'package:get/get.dart';
import '../models/power_up_cell.dart';

/// Sahne içi power-up sistemi — aktif efekt yönetimi.
///
/// Akış:
///   1. Top grid'deki [PowerUpCell]'e çarpar → GameController bildirir
///   2. Nuke → anında etki (GameController uygular)
///   3. Diğerleri → [queueForNextTurn] ile bir sonraki tura sıraya alınır
///   4. [applyPendingToActive] → yeni tur başlangıcında (launchBalls) çağrılır
///   5. [consumeTurn] → tur sonunda (endTurn) çağrılır; sayaç düşer
class PowerUpController extends GetxController {
  // ── Aktif efekt ──────────────────────────────────────────────────────────

  /// Hâlihazırda uygulanmakta olan power-up türü.
  final Rx<PowerUpType?> activePowerUp = Rx<PowerUpType?>(null);

  /// Aktif efektin kalan tur sayısı.
  final RxInt activeTurnsLeft = 0.obs;

  /// Sıradaki tura taşınacak efekt (bu tur grid'den toplandı).
  final Rx<PowerUpType?> pendingPowerUp = Rx<PowerUpType?>(null);

  // ── Durum sorguları ───────────────────────────────────────────────────────

  bool get hasActive =>
      activePowerUp.value != null && activeTurnsLeft.value > 0;

  bool get hasPending => pendingPowerUp.value != null;

  // ── Efekt özellikleri — GameController & BallPhysics kullanır ────────────

  /// Fireball aktifse 3, değilse 1.
  int get damageMultiplier =>
      (hasActive && activePowerUp.value == PowerUpType.fireball) ? 3 : 1;

  /// SpeedBoost aktifse 2.0, değilse 1.0.
  double get speedBoostFactor =>
      (hasActive && activePowerUp.value == PowerUpType.speedBoost) ? 2.0 : 1.0;

  /// Bu turda top sayısı iki katına çıkar.
  bool get multiBallActive =>
      hasActive && activePowerUp.value == PowerUpType.multiBall;

  /// Bu turda tuğlalar aşağı inmiyor.
  bool get shieldRowActive =>
      hasActive && activePowerUp.value == PowerUpType.shieldRow;

  // ── Akış metodları ────────────────────────────────────────────────────────

  /// Grid'den toplanan, tur sonunda aktif olacak efekti sıraya alır.
  /// Zaten bir pending varsa üzerine yazar (tek slot).
  void queueForNextTurn(PowerUpType type) {
    pendingPowerUp.value = type;
  }

  /// [_launchBalls]'da çağrılır: pending efekti active'e alır.
  void applyPendingToActive() {
    final pending = pendingPowerUp.value;
    if (pending == null) return;
    activePowerUp.value = pending;
    activeTurnsLeft.value = 1;
    pendingPowerUp.value = null;
  }

  /// [_endTurn]'da çağrılır: kalan tur sayısını düşürür.
  void consumeTurn() {
    if (activeTurnsLeft.value > 0) {
      activeTurnsLeft.value--;
      if (activeTurnsLeft.value <= 0) {
        activePowerUp.value = null;
      }
    }
  }

  /// Oyun sıfırlandığında tüm durumu temizler.
  void reset() {
    activePowerUp.value = null;
    activeTurnsLeft.value = 0;
    pendingPowerUp.value = null;
  }

  // ── Görüntü yardımcıları ─────────────────────────────────────────────────

  /// Aktif veya bekleyen efektin gösterilecek adı.
  String get displayName {
    final type = activePowerUp.value ?? pendingPowerUp.value;
    return _nameOf(type);
  }

  /// Aktif veya bekleyen efektin rengi.
  int get displayColorValue {
    final type = activePowerUp.value ?? pendingPowerUp.value;
    return _colorOf(type);
  }

  static String _nameOf(PowerUpType? type) => switch (type) {
    PowerUpType.fireball   => 'FIREBALL',
    PowerUpType.nuke       => 'NUKE',
    PowerUpType.multiBall  => 'MULTI-BALL',
    PowerUpType.speedBoost => 'SPEED',
    PowerUpType.shieldRow  => 'SHIELD',
    null                   => '',
  };

  static int _colorOf(PowerUpType? type) => switch (type) {
    PowerUpType.fireball   => 0xFFEF4444,
    PowerUpType.nuke       => 0xFF8B5CF6,
    PowerUpType.multiBall  => 0xFF06B6D4,
    PowerUpType.speedBoost => 0xFFFBBF24,
    PowerUpType.shieldRow  => 0xFF3B82F6,
    null                   => 0xFFFFFFFF,
  };
}
