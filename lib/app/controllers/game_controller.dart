import 'dart:async';
import 'dart:math';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/physics/ball_physics.dart';
import '../core/physics/particle_system.dart';
import '../core/utils/constants.dart';
import '../core/utils/level_generator.dart';
import '../core/utils/sound_service.dart';
import '../controllers/settings_controller.dart';
import '../controllers/upgrade_controller.dart';
import '../controllers/achievement_controller.dart';
import '../models/ball.dart';
import '../models/bonus_ball.dart';
import '../models/brick.dart';
import '../models/game_state.dart';
import '../models/laser_beam.dart';
import '../models/power_up_cell.dart';
import '../core/utils/analytics_service.dart';
import '../core/utils/game_save_service.dart';
import '../core/utils/auth_service.dart';
import '../core/utils/firestore_service.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import 'daily_mission_controller.dart';
import 'power_up_controller.dart';
import 'power_up_inventory_controller.dart';

class GameController extends GetxController with GetTickerProviderStateMixin {
  // ── Reaktif durum ────────────────────────────────────────────────────────
  final Rx<GameState?> gameState = Rx<GameState?>(null);
  final Rx<double?> aimAngle = Rx<double?>(null);
  // Parmak ne kadar uzağa çekildi → nişan çizgisi uzunluğunu belirler
  final Rx<double> aimDragMagnitude = 0.0.obs;

  // Parçacık sistemi (non-reactive — Painter doğrudan okur)
  final ParticleSystem particles = ParticleSystem();

  // Aktif lazer ışınları (non-reactive — her tick güncellenir)
  final List<LaserBeam> activeLasers = [];

  // Sahne geçiş yazısı — boş olmadığında overlay gösterilir
  final RxString stageTransitionText = ''.obs;

  // Cep envanteri açık/kapalı
  final RxBool inventoryOpen = false.obs;

  void toggleInventory() {
    final state = gameState.value;
    if (state == null || state.turnPhase != TurnPhase.aiming) return;
    inventoryOpen.value = !inventoryOpen.value;
  }

  void closeInventory() => inventoryOpen.value = false;

  // Combo göstergesi — tur sonunda 10+ tuğla kırılınca tetiklenir
  final RxString comboText = ''.obs;

  // Streak göstergesi — üst üste tuğla kıran turlarda tetiklenir
  final RxString streakText = ''.obs;

  // Sahne ilerleme çubuğu — 0.0 (boş) → 1.0 (tamamlandı)
  final RxDouble stageProgress = 0.0.obs;

  // Power-up aktivasyon bildirimi — kısa süreli banner
  final RxString powerUpText = ''.obs;

  // Oyun modu
  final Rx<GameMode> gameMode = GameMode.classic.obs;

  /// Klasik modda sahne tamamlanması için gereken tuğla sayısı.
  static int classicTarget(int stage) => 25 + stage * 10;

  /// Bu sahnede kırılan toplam tuğla sayısı (HUD için).
  int get stageBricksDestroyed => _stageBricksDestroyed;

  Offset? _dragStart;

  // ── Fizik ────────────────────────────────────────────────────────────────
  final BallPhysics _physics = BallPhysics();
  late BallPhysicsConfig _physicsConfig;

  // ── Ticker (game loop) ──────────────────────────────────────────────────
  Ticker? _ticker;
  Duration _lastTickTime = Duration.zero;

  // ── Fırlatma zamanlayıcısı ───────────────────────────────────────────────
  Timer? _launchTimer;

  // ── Ekran boyutu ─────────────────────────────────────────────────────────
  double _screenWidth = 390.0;
  double _screenHeight = 844.0;

  double get _launchY => _screenHeight;

  // ── Game over satırı (dinamik — canvas boyutuna göre hesaplanır) ──────────
  int _gameOverRow = GameConstants.gridRows;

  /// Tuğlaların geçemeyeceği Y koordinatı (danger çizgisi).
  /// _gameOverRow satırının altı — tuğlalar bu çizgiyi geçerse game over.
  double get dangerLineY =>
      _gameOverRow * (BrickConfig.size + BrickConfig.gap) + BrickConfig.size;

  // ── Tehlike yanıp-sönme animasyonu ───────────────────────────────────────
  final RxDouble dangerFlash = 0.0.obs;
  double _dangerPhase = 0.0;

  // ── Continue mekanizması ─────────────────────────────────────────────────
  int _continueCount = 0;
  bool get canContinue => _continueCount < GameConstants.maxContinues;

  /// Tuğla kayma animasyonu offseti (piksel). 0 = normal, >0 = kayma devam ediyor.
  final RxDouble brickShiftOffset = 0.0.obs;

  // Günlük görev sayaçları (tur başında sıfırlanır)
  int _bricksThisTurn  = 0;
  int _hpThisTurn      = 0; // bu turda kırılan tuğlaların toplam maxHp'si
  int _bombsThisTurn   = 0;
  int _shieldsThisTurn = 0;
  int _lasersThisTurn  = 0;
  int _scoreThisTurn   = 0;

  // Sahne ilerleme sayaçları (HP bazlı)
  int _stageTotalHp         = 1;  // sahnedeki toplam HP (başlangıç + eklenen satırlar)
  int _stageDamageDealt     = 0;  // kırılan tuğlaların toplam maxHp'si
  int _stageBricksDestroyed = 0;  // kırılan tuğla adedi (achievement/mission için)
  int _turnCount            = 0;  // Tur sayacı (satır ekleme sıklığı için)

  // Streak sayacı — üst üste tuğla kırılan tur sayısı
  int _streakCount = 0;

  // ── Yükseltme efektleri (initGame'de hesaplanır) ──────────────────────────
  double _effectiveBallRadius = GameConstants.ballRadius;
  double _effectiveBallSpeed  = GameConstants.ballSpeed;

  // ── Power-up referansı ────────────────────────────────────────────────────
  bool get _hasPowerUp => Get.isRegistered<PowerUpController>();
  PowerUpController get _powerUp => Get.find<PowerUpController>();

  // ── Başlatma ─────────────────────────────────────────────────────────────

  SoundService get _sound => Get.find<SoundService>();

  bool get _hapticEnabled =>
      Get.isRegistered<SettingsController>()
          ? Get.find<SettingsController>().hapticEnabled.value
          : true;

  void _haptic(Future<void> Function() fn) {
    if (_hapticEnabled) fn();
  }

  void initGame(double screenWidth, double screenHeight,
      [GameMode mode = GameMode.classic]) {
    gameMode.value = mode;
    _screenWidth = screenWidth;
    _screenHeight = screenHeight;
    particles.clear();

    // Ayarlar yüklenene kadar bekle, ayarları SoundService'e uygula, sonra BGM başlat
    if (Get.isRegistered<SettingsController>()) {
      Get.find<SettingsController>().ready.then((_) {
        Get.find<SettingsController>().applyToSound();
        _sound.startBgm();
      });
    } else {
      _sound.startBgm();
    }

    // iPad/tablet ölçekleme — sabit piksel değerlerini ekran genişliğine göre ayarla
    GameConstants.updateScale(screenWidth);

    // Analytics: oyun başladı
    if (Get.isRegistered<AnalyticsService>()) {
      Get.find<AnalyticsService>().logGameStart();
    }

    // Yükseltme efektlerini oku
    final upgrades = Get.find<UpgradeController>();
    _effectiveBallRadius = GameConstants.ballRadius * upgrades.sizeMultiplier;
    _effectiveBallSpeed  = GameConstants.ballSpeed  * upgrades.speedMultiplier;

    _configureBricks();
    _buildPhysicsConfig();

    final initial = LevelGenerator.generateStage(1);
    gameState.value = GameState.initial(screenWidth).copyWith(
      bricks: initial.bricks,
      bonusBalls: initial.bonusBalls,
      balls: _buildBalls(upgrades.startingBalls, screenWidth / 2),
      ballCount: upgrades.startingBalls,
    );

    _stageTotalHp         = LevelGenerator.estimateStageTotalHp(1);
    _stageDamageDealt     = 0;
    _stageBricksDestroyed = 0;
    _turnCount            = 0;
    _streakCount          = 0;
    _continueCount          = 0;
    brickShiftOffset.value  = 0.0;
    stageProgress.value     = 0.0;
    streakText.value        = '';
    if (_hasPowerUp) _powerUp.reset();

    // Günlük bedava şarj kontrolü (fire-and-forget)
    if (Get.isRegistered<PowerUpInventoryController>()) {
      unawaited(
        Get.find<PowerUpInventoryController>().tryClaimDailyCharge().then((claimed) {
          if (claimed) {
            final inv = Get.find<PowerUpInventoryController>();
            final type = inv.lastDailyType;
            if (type != null) {
              _showPowerUpBanner('label_powerup_daily'.trParams({'name': _powerUpLabel(type)}));
            }
          }
        }),
      );
    }

    _startTicker();
  }

  void _configureBricks() {
    final totalGap = GameConstants.brickGap * (GameConstants.gridColumns - 1) +
        GameConstants.brickPadding * 2;
    BrickConfig.size = (_screenWidth - totalGap) / GameConstants.gridColumns;
    BrickConfig.gap = GameConstants.brickGap;
    BrickConfig.padding = GameConstants.brickPadding;
    BrickConfig.topOffset = 0; // canvas HUD'ın altından başlıyor, iç offset yok
    BrickConfig.columns = GameConstants.gridColumns;

    // Game over satırı: tahtanın en alt çizgisine kadar iner.
    // 2 satır tampon bırakılır: top her zaman görünür bir mesafe uçabilsin.
    // Aksi hâlde tehlike satırındaki tuğlalar fırlatma noktasına çok yakın olur
    // ve top göz kırpması kadar kısa bir sürede geri döner (kullanıcı göremez).
    final rowH = BrickConfig.size + BrickConfig.gap;
    _gameOverRow = rowH > 0
        ? ((_screenHeight - GameConstants.ballRadius * 2) / rowH).floor() - 1
        : GameConstants.gridRows - 1;
  }

  void _buildPhysicsConfig() {
    _physicsConfig = BallPhysicsConfig(
      speed: _effectiveBallSpeed *
          (_hasPowerUp ? _powerUp.speedBoostFactor : 1.0),
      leftBound: 0,
      rightBound: _screenWidth,
      topBound: 0,
      bottomBound: _launchY,
      brickSize: BrickConfig.size,
      brickGap: BrickConfig.gap,
      brickPadding: BrickConfig.padding,
      brickTopOffset: BrickConfig.topOffset,
      damageMultiplier: _hasPowerUp ? _powerUp.damageMultiplier : 1,
    );
  }

  List<Ball> _buildBalls(int count, double launchX) {
    return List.generate(
      count,
      (_) => Ball(
        position: Offset(launchX, _launchY - _effectiveBallRadius),
        velocity: Offset.zero,
        radius: _effectiveBallRadius,
      ),
    );
  }

  // ── Game Loop ────────────────────────────────────────────────────────────

  void _startTicker() {
    _ticker?.dispose();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final state = gameState.value;
    if (state == null) return;
    if (state.status != GameStatus.playing) return;

    final dt = _lastTickTime == Duration.zero
        ? 0.0
        : (elapsed - _lastTickTime).inMicroseconds / 1000000.0;
    _lastTickTime = elapsed;

    if (dt <= 0 || dt > 0.1) return;

    // Continue kayma animasyonu: brickShiftOffset → 0
    if (brickShiftOffset.value > 0) {
      final rowH    = BrickConfig.size + BrickConfig.gap;
      final total   = GameConstants.continueShiftRows * rowH;
      final step    = total * dt / (GameConstants.continueShiftMs / 1000.0);
      brickShiftOffset.value = (brickShiftOffset.value - step).clamp(0.0, total);
    }

    // Parçacıkları ve lazerleri her zaman güncelle
    particles.update(dt);
    activeLasers.removeWhere((l) => l.isExpired);
    for (final l in activeLasers) { l.lifetime -= dt; }

    // Çarpışma parlama zamanlayıcılarını azalt
    for (final brick in state.bricks) {
      if (brick.hitFlashTimer > 0) {
        brick.hitFlashTimer = (brick.hitFlashTimer - dt).clamp(0.0, 1.0);
      }
    }

    // Tehlike animasyonu — son satırdan 1 önce tuğla varsa kırmızı hale yanıp söner
    final dangerRow = _gameOverRow - 1;
    final inDanger  = state.bricks.any((b) => b.isAlive && b.row >= dangerRow);
    if (inDanger) {
      _dangerPhase += dt * 5.0; // ~5 Hz
      dangerFlash.value = (sin(_dangerPhase) * 0.5 + 0.5);
    } else {
      if (dangerFlash.value != 0.0) dangerFlash.value = 0.0;
      _dangerPhase = 0.0;
    }

    if (state.turnPhase != TurnPhase.shooting) return;

    final bricks      = state.bricks;
    final bonusBalls  = state.bonusBalls;
    final powerUpCells = state.powerUpCells;
    int bonusCollected    = 0;
    int bonusLost         = 0;
    int destroyedThisTick = 0;

    int extraBalls = 0;
    int totalWallBounces = 0;
    bool anyBrickHit = false;
    final destroyedBrickTypes = <BrickType>{};

    for (final ball in state.balls) {
      final result = _physics.tick(
          ball, dt, bricks, bonusBalls, _physicsConfig,
          powerUpCells: powerUpCells);

      // Comet trail: aktif topların pozisyon geçmişini tut
      if (ball.isActive) {
        ball.trail.add(ball.position);
        if (ball.trail.length > Ball.trailLength) ball.trail.removeAt(0);
      }

      totalWallBounces += result.wallBounces;

      // Tuğla patlama efektleri + ses tespiti
      for (final brick in result.hitBricks) {
        if (!brick.isAlive) {
          // Boss tuğla: özel dev patlama + gem ödülü
          if (brick.type == BrickType.boss) {
            particles.emitBossExplosion(brick.bossRect.center);
            _sound.playBombExplode();
            _sound.playLevelUp();
            _haptic(HapticFeedback.heavyImpact);
            unawaited(Get.find<UpgradeController>().addGems(5));
            _showPowerUpBanner('💀 BOSS YIKILDI! +5💎');
            if (Get.isRegistered<AchievementController>()) {
              Get.find<AchievementController>().reportBossDefeated();
            }
            if (Get.isRegistered<DailyMissionController>()) {
              Get.find<DailyMissionController>().reportBossDefeated();
            }
          } else {
            particles.emitBrickExplosion(
              brick.rect.center,
              _brickParticleColor(brick.type),
            );
          }
          destroyedThisTick++;
          _bricksThisTurn++;
          _hpThisTurn += brick.maxHp;
          if (brick.type == BrickType.bomb)   _bombsThisTurn++;
          if (brick.type == BrickType.shield) _shieldsThisTurn++;
          if (brick.type == BrickType.laserH ||
              brick.type == BrickType.laserV) { _lasersThisTurn++; }
          destroyedBrickTypes.add(brick.type);
        } else {
          anyBrickHit = true;
          if (brick.type == BrickType.shield) {
            _sound.playShieldHit();
          }
        }
      }

      // Bonus toplama efektleri
      for (final bonus in result.collected) {
        final center = bonus.centerFor(
          brickSize: BrickConfig.size,
          brickGap: BrickConfig.gap,
          padding: BrickConfig.padding,
          topOffset: BrickConfig.topOffset,
        );
        particles.emitBonusCollect(center);
        if (bonus.type == BonusBallType.minus) {
          bonusLost++;
          _sound.playMinusBall();
          _haptic(HapticFeedback.heavyImpact);
        } else {
          bonusCollected++;
        }
      }

      extraBalls += result.extraBalls;

      // Power-up toplama efektleri
      for (final cell in result.collectedPowerUps) {
        final center = cell.centerFor(
          brickSize: BrickConfig.size,
          brickGap:  BrickConfig.gap,
          padding:   BrickConfig.padding,
          topOffset: BrickConfig.topOffset,
        );
        particles.emitBonusCollect(center); // bonus efektini yeniden kullan
        _haptic(HapticFeedback.mediumImpact);

        if (_hasPowerUp) {
          if (cell.type == PowerUpType.nuke) {
            // Anında etki: tüm canlı tuğlaların HP -1
            for (final brick in bricks) {
              if (brick.isAlive) brick.hit(1);
            }
            _showPowerUpBanner('💥 NUKE!');
          } else {
            _powerUp.queueForNextTurn(cell.type);
            _showPowerUpBanner('${_powerUpLabel(cell.type)} HAZIR →');
          }
        }
      }

      // Lazer efektleri
      for (final laser in result.firedLasers) {
        activeLasers.add(LaserBeam(
          isHorizontal: laser.isHorizontal,
          position: laser.position,
        ));
        _sound.playLaserFire();
        _haptic(HapticFeedback.heavyImpact);
      }
    }

    // Ses efektleri — toplu işlem (throttle'dan faydalanmak için)
    if (totalWallBounces > 0) _sound.playWallBounce();
    if (anyBrickHit) _sound.playBrickBounce();

    for (final type in destroyedBrickTypes) {
      switch (type) {
        case BrickType.bomb:
          _sound.playBombExplode();
        case BrickType.chain:
          _sound.playChainTrigger();
        case BrickType.multiplier:
          _sound.playMultiplierCollect();
        default:
          _sound.playBrickBreak();
      }
    }

    // Haptic feedback — tuğla patladığında
    if (destroyedThisTick > 0) {
      _haptic(HapticFeedback.selectionClick);
    }

    final destroyedCount = bricks.where((b) => !b.isAlive).length;
    final newScore = state.score + destroyedCount * GameConstants.scorePerBrick;
    final newBallCount = max(1, state.ballCount + bonusCollected + extraBalls - bonusLost);

    gameState.value = state.copyWith(
      bricks: bricks.where((b) => b.isAlive).toList(),
      powerUpCells: powerUpCells.where((c) => !c.isCollected).toList(),
      score: newScore,
      ballCount: newBallCount,
    );

    if (state.balls.every((b) => b.hasReturned)) {
      _lastTickTime = Duration.zero;
      _endTurn();
    }
  }

  Color _brickParticleColor(BrickType type) {
    return switch (type) {
      BrickType.bomb       => AppColors.accent,
      BrickType.stone      => AppColors.muted,
      BrickType.triangle   => AppColors.neonBlue,
      BrickType.chain      => const Color(0xFF14B8A6), // teal
      BrickType.shield     => const Color(0xFFFBBF24), // altın
      BrickType.multiplier => const Color(0xFFEC4899), // pembe
      BrickType.laserH     => const Color(0xFFF97316), // turuncu
      BrickType.laserV     => const Color(0xFF06B6D4), // cyan
      BrickType.boss       => const Color(0xFFFFD700), // altın
      BrickType.normal     => AppColors.primary,
    };
  }

  // ── Dokunma Girdileri ────────────────────────────────────────────────────

  void onDragStart(Offset position) {
    final state = gameState.value;
    if (state == null || state.turnPhase != TurnPhase.aiming) return;
    _dragStart = position;
    _haptic(HapticFeedback.lightImpact);
  }

  void onDragUpdate(Offset position) {
    final state = gameState.value;
    if (state == null || state.turnPhase != TurnPhase.aiming) return;
    if (_dragStart == null) return;

    final delta = position - Offset(state.launchX, _launchY);
    if (delta.distance < 10) return;

    // Ekran Y'si aşağı artar. Parmak yukarıdaysa delta.dy < 0 → atan2 negatif açı verir.
    aimAngle.value = atan2(delta.dy, delta.dx);
    aimDragMagnitude.value = delta.distance;
  }

  void onDragEnd() {
    final state = gameState.value;
    if (state == null || state.turnPhase != TurnPhase.aiming) return;
    if (aimAngle.value == null) return;

    // Açı yukarı yönünde değilse (sin >= 0 → yatay veya aşağı bakıyor)
    // top fırlatılmaz; anında zemin çarpması → erken tur bitişini önler.
    if (sin(aimAngle.value!) >= 0) {
      aimAngle.value = null;
      aimDragMagnitude.value = 0;
      return;
    }

    _haptic(HapticFeedback.mediumImpact);
    _sound.playBallLaunch();
    _launchBalls(aimAngle.value!);
    aimAngle.value = null;
    aimDragMagnitude.value = 0;
    _dragStart = null;
  }

  // ── Fırlatma ─────────────────────────────────────────────────────────────

  void _launchBalls(double angle) {
    final state = gameState.value;
    if (state == null) return;

    final velocity = BallPhysics.velocityFromAngle(angle, GameConstants.ballSpeed);
    final launchPos =
        Offset(state.launchX, _launchY - GameConstants.ballRadius);

    for (final ball in state.balls) {
      ball.resetToLaunchPosition(launchPos);
    }

    // Envanter drawer'ı kapat
    inventoryOpen.value = false;

    // Tur sayaçlarını sıfırla; skoru tur BAŞINDA yakala (delta hesabı için)
    _bricksThisTurn  = 0;
    _hpThisTurn      = 0;
    _bombsThisTurn   = 0;
    _shieldsThisTurn = 0;
    _lasersThisTurn  = 0;
    _scoreThisTurn   = state.score;

    // Power-up: bekleyen efekti aktif et + fizik config'i güncelle
    if (_hasPowerUp) {
      _powerUp.applyPendingToActive();
      if (_powerUp.hasActive) {
        _showPowerUpBanner('label_powerup_active'.trParams({'name': _powerUpLabel(_powerUp.activePowerUp.value!)}));
      }
      _buildPhysicsConfig(); // damageMultiplier ve speed yeniden hesaplanır

      // Multi-Ball: bu tur için top sayısını 2× yap
      if (_powerUp.multiBallActive) {
        final doubled = state.ballCount * 2;
        for (int i = state.balls.length; i < doubled; i++) {
          state.balls.add(Ball(
            position: Offset(state.launchX, _launchY - GameConstants.ballRadius),
            velocity: Offset.zero,
            radius: _effectiveBallRadius,
          ));
        }
      }
    }

    // Başarım: top sayısını raporla (Top Çılgını)
    if (Get.isRegistered<AchievementController>()) {
      Get.find<AchievementController>()
          .reportBallsInGame(state.ballCount);
    }
    // Başarım: ilk atış
    if (Get.isRegistered<AchievementController>()) {
      Get.find<AchievementController>().reportBallFired();
    }

    gameState.value = state.copyWith(turnPhase: TurnPhase.shooting);

    int launched = 0;
    _launchTimer?.cancel();
    _launchTimer = Timer.periodic(
      Duration(milliseconds: GameConstants.launchDelayMs),
      (timer) {
        if (launched >= state.balls.length) {
          timer.cancel();
          return;
        }
        state.balls[launched].velocity = velocity;
        state.balls[launched].isActive = true;
        launched++;
        gameState.refresh();
      },
    );
  }

  // ── Tur Sonu ─────────────────────────────────────────────────────────────

  void _endTurn() {
    final state = gameState.value;
    if (state == null) return;

    gameState.value = state.copyWith(turnPhase: TurnPhase.settling);

    // Günlük görev raporlama
    if (Get.isRegistered<DailyMissionController>()) {
      final dm = Get.find<DailyMissionController>();
      if (_bricksThisTurn  > 0) dm.reportBricksDestroyed(_bricksThisTurn);
      if (_bombsThisTurn   > 0) dm.reportBombDestroyed(_bombsThisTurn);
      if (_shieldsThisTurn > 0) dm.reportShieldDestroyed(_shieldsThisTurn);
      if (_lasersThisTurn  > 0) dm.reportLaserDestroyed(_lasersThisTurn);
      final scoreDelta = (gameState.value?.score ?? 0) - _scoreThisTurn;
      if (scoreDelta > 0) dm.reportScoreEarned(scoreDelta);
      // NOT: _scoreThisTurn bir sonraki _launchBalls() çağrısında sıfırlanır
    }

    // Başarım raporlama
    if (Get.isRegistered<AchievementController>()) {
      final ac = Get.find<AchievementController>();
      if (_bricksThisTurn  > 0) ac.reportBricksDestroyed(_bricksThisTurn);
      if (_bombsThisTurn   > 0) ac.reportBombDestroyed();
      if (_lasersThisTurn  > 0) ac.reportLaserDestroyed();
      if (_bricksThisTurn  > 0) ac.reportBricksInTurn(_bricksThisTurn);
    }

    // Combo göstergesi
    if (_bricksThisTurn >= 10) {
      final multiplier = _bricksThisTurn >= 30 ? 4
                       : _bricksThisTurn >= 20 ? 3
                       : 2;
      comboText.value = 'COMBO x$multiplier!';
      Future.delayed(const Duration(milliseconds: 1500), () {
        comboText.value = '';
      });
    }

    // Streak sistemi — üst üste tuğla kırılan turlarda çarpan göster
    if (_bricksThisTurn > 0) {
      _streakCount++;
      final streakMultiplier = _streakCount >= 7 ? 5
                             : _streakCount >= 4 ? 3
                             : _streakCount >= 2 ? 2 : 1;
      if (streakMultiplier > 1) {
        // Bonus puan: bu turda kırılan tuğlalar × scorePerBrick × (çarpan - 1)
        final bonus = _bricksThisTurn * GameConstants.scorePerBrick * (streakMultiplier - 1);
        final s = gameState.value;
        if (s != null) {
          gameState.value = s.copyWith(score: s.score + bonus);
        }
        streakText.value = 'STREAK x$streakMultiplier!';
        Future.delayed(const Duration(milliseconds: 1800), () {
          streakText.value = '';
        });
      }
    } else {
      _streakCount = 0;
      streakText.value = '';
    }

    // Sahne ilerleme: bu turda kırılan tuğlaların maxHp'sini biriktir
    _stageBricksDestroyed += _bricksThisTurn;
    _stageDamageDealt     += _hpThisTurn;

    _haptic(HapticFeedback.lightImpact);

    final firstReturned = state.balls.firstWhereOrNull((b) => b.hasReturned);
    final newLaunchX = firstReturned?.position.dx ?? state.launchX;

    // Power-up: tur bitişinde sayacı düşür
    final shieldActive = _hasPowerUp && _powerUp.shieldRowActive;
    if (_hasPowerUp) _powerUp.consumeTurn();

    // Lazer düğmeleri tur sonunda sahadan kalkar.
    // ShieldRow aktifse tuğlalar bu tur aşağı inmiyor.
    final aliveBricks = state.bricks
        .where((b) => b.isAlive &&
            b.type != BrickType.laserH &&
            b.type != BrickType.laserV)
        .map((b) => shieldActive ? b : b.movedDown())
        .toList();

    final activeBonuses = state.bonusBalls
        .where((b) => !b.isCollected)
        .map((b) => shieldActive ? b : b.movedDown())
        .toList();

    final activePowerUpCells = state.powerUpCells
        .where((c) => !c.isCollected)
        .map((c) => shieldActive ? c : c.movedDown())
        .toList();

    if (aliveBricks.any((b) => b.row >= _gameOverRow)) {
      _triggerGameOver(state.score, state.stage);
      return;
    }

    // Tüm tuğlalar temizlendi → sahne tamamlandı (her iki modda da geçerli)
    if (aliveBricks.isEmpty) {
      _triggerStageComplete(state, newLaunchX);
      return;
    }

    // Klasik mod: HP bazlı ilerleme — kırılan toplam HP / sahnedeki toplam HP
    if (gameMode.value == GameMode.classic) {
      stageProgress.value = (_stageDamageDealt / _stageTotalHp).clamp(0.0, 0.99);
      final target = classicTarget(state.stage);
      if (_stageBricksDestroyed >= target) {
        _triggerStageComplete(state, newLaunchX);
        return;
      }
    }

    // Normal tur: satır ekleme sıklığı stage'e göre değişir
    // Stage 1-4: her 2 turda bir  → oyuncu nefes alabilir
    // Stage 5+ : her tur → baskı artar
    _turnCount++;
    final rowInterval = state.stage <= 4 ? 2 : 1;
    final shouldAddRow = (_turnCount % rowInterval) == 0;

    final List<Brick> newRow = shouldAddRow
        ? LevelGenerator.generateRow(state.stage, 0, turnNumber: _turnCount)
        : [];
    final newBonus = shouldAddRow
        ? LevelGenerator.generateBonusBall(state.stage, 0, newRow)
        : null;

    // (Toplam HP sahne başında estimateStageTotalHp ile hesaplandı)
    // Sonsuz modda progress: HP bazlı
    if (gameMode.value == GameMode.endless) {
      stageProgress.value =
          (_stageDamageDealt / _stageTotalHp).clamp(0.0, 0.99);
    }

    final updatedBricks  = [...newRow, ...aliveBricks];
    final updatedBonuses = [...activeBonuses, ?newBonus];
    // Yeni satırla birlikte rastgele power-up hücresi oluşturulabilir
    final newPowerUpCell = shouldAddRow
        ? LevelGenerator.generatePowerUpCell(state.stage, 0, newRow)
        : null;

    final newBallCount = state.ballCount;
    final newBalls = _buildBalls(newBallCount, newLaunchX);
    final newScore = state.score + GameConstants.scoreBonusPerLevel;

    gameState.value = state.copyWith(
      bricks: updatedBricks,
      bonusBalls: updatedBonuses,
      powerUpCells: [...activePowerUpCells, ?newPowerUpCell],
      balls: newBalls,
      launchX: newLaunchX,
      level: state.level + 1,
      score: newScore,
      ballCount: newBallCount,
      turnPhase: TurnPhase.aiming,
    );
  }

  // ── Sahne Tamamlandı ─────────────────────────────────────────────────────

  Future<void> _triggerStageComplete(GameState state, double newLaunchX) async {
    final completedStage = state.stage;
    if (Get.isRegistered<DailyMissionController>()) {
      Get.find<DailyMissionController>().reportStageCompleted();
    }
    if (Get.isRegistered<AchievementController>()) {
      Get.find<AchievementController>().reportStageCompleted();
    }
    final newStage = completedStage + 1;

    // En yüksek sahneyi kaydet
    final prefs = await SharedPreferences.getInstance();
    final bestStage = prefs.getInt('best_stage') ?? 0;
    if (completedStage > bestStage) await prefs.setInt('best_stage', completedStage);

    // Her sahne tamamlandığında 1 gem
    // Her 10 sahnelik milestone'da ek 4 gem (toplam 5 gem o sahnede)
    final upgrades = Get.find<UpgradeController>();
    const stageGems = 1;
    await upgrades.addGems(stageGems);
    _sound.playGemCollect();
    _haptic(HapticFeedback.lightImpact);

    if (completedStage % 10 == 0) {
      const milestoneGems = 4; // +4 ekstra → o sahnede toplam 5 gem
      await upgrades.addGems(milestoneGems);
      _haptic(HapticFeedback.heavyImpact);
    }

    _sound.playLevelUp();
    _haptic(HapticFeedback.mediumImpact);

    // Yeni sahne bricklerini yükle
    final newStageData = LevelGenerator.generateStage(newStage);

    // Top sayısını sıfırla: bonus toplar kaybolur, sadece kalıcı (satın alınan) toplar kalır
    final newBallCount = upgrades.startingBalls;
    final newBalls = _buildBalls(newBallCount, newLaunchX);
    final newScore = state.score + GameConstants.scoreBonusPerLevel * 5;

    gameState.value = state.copyWith(
      bricks: newStageData.bricks,
      bonusBalls: newStageData.bonusBalls,
      balls: newBalls,
      launchX: newLaunchX,
      stage: newStage,
      level: state.level + 1,
      score: newScore,
      ballCount: newBallCount,
      turnPhase: TurnPhase.aiming,
    );

    // Sahne ilerleme çubuğunu tamamlandı göster, kısa gecikme sonrası sıfırla
    stageProgress.value = 1.0;
    _stageTotalHp         = LevelGenerator.estimateStageTotalHp(newStage);
    _stageDamageDealt     = 0;
    _stageBricksDestroyed = 0;
    _turnCount            = 0;
    _streakCount          = 0;
    streakText.value        = '';
    Future.delayed(const Duration(milliseconds: 500), () {
      stageProgress.value = 0.0;
    });

    // Geçiş yazısını göster, 2.8 saniye sonra kaldır
    final isMilestone = completedStage % 10 == 0;
    final gemLabel = isMilestone ? '+5💎' : '+1💎';
    stageTransitionText.value = 'label_stage_transition'.trParams({'stage': '$newStage', 'gems': gemLabel});
    Future.delayed(const Duration(milliseconds: 2800), () {
      stageTransitionText.value = '';
    });
  }

  // ── Duraklatma ───────────────────────────────────────────────────────────

  void pauseGame() {
    final state = gameState.value;
    if (state == null || state.status != GameStatus.playing) return;
    _ticker?.stop();
    _sound.pauseBgm();
    gameState.value = state.copyWith(status: GameStatus.paused);
  }

  void resumeGame() {
    final state = gameState.value;
    if (state == null || state.status != GameStatus.paused) return;
    _lastTickTime = Duration.zero;
    _ticker?.start();
    _sound.resumeBgm();
    gameState.value = state.copyWith(status: GameStatus.playing);
  }

  void restartGame() {
    _ticker?.stop();
    _launchTimer?.cancel();
    _lastTickTime = Duration.zero;
    // Yeniden başlatıldığında kayıtlı oyunu sil
    GameSaveService.delete(gameMode.value);
    initGame(_screenWidth, _screenHeight, gameMode.value);
  }

  /// Oyun durumunu kaydedip ana menüye dön.
  Future<void> saveAndGoHome() async {
    final state = gameState.value;
    if (state == null) {
      Get.offAllNamed('/home');
      return;
    }

    _ticker?.stop();
    _sound.stopBgm();

    await GameSaveService.save(
      state: state,
      mode: gameMode.value,
      stageBricksDestroyed: _stageBricksDestroyed,
      stageDamageDealt: _stageDamageDealt,
      stageTotalHp: _stageTotalHp,
      turnCount: _turnCount,
      streakCount: _streakCount,
      continueCount: _continueCount,
      screenWidth: _screenWidth,
      screenHeight: _screenHeight,
    );

    Get.offAllNamed('/home');
  }

  /// Kayıtlı oyunu geri yükle.
  Future<bool> restoreGame(double screenWidth, double screenHeight,
      GameMode mode) async {
    final saved = await GameSaveService.load(mode);
    if (saved == null) return false;

    gameMode.value = mode;
    _screenWidth = screenWidth;
    _screenHeight = screenHeight;
    particles.clear();

    // Ayarlar yüklenene kadar bekle, ayarları SoundService'e uygula, sonra BGM başlat
    if (Get.isRegistered<SettingsController>()) {
      Get.find<SettingsController>().ready.then((_) {
        Get.find<SettingsController>().applyToSound();
        _sound.startBgm();
      });
    } else {
      _sound.startBgm();
    }

    GameConstants.updateScale(screenWidth);

    final upgrades = Get.find<UpgradeController>();
    _effectiveBallRadius = GameConstants.ballRadius * upgrades.sizeMultiplier;
    _effectiveBallSpeed = GameConstants.ballSpeed * upgrades.speedMultiplier;

    _configureBricks();
    _buildPhysicsConfig();

    // Dahili sayaçları geri yükle
    _stageBricksDestroyed = saved.stageBricksDestroyed;
    _stageDamageDealt = saved.stageDamageDealt;
    _stageTotalHp = saved.stageTotalHp;
    _turnCount = saved.turnCount;
    _streakCount = saved.streakCount;
    _continueCount = saved.continueCount;

    // GameState'i oluştur — toplar aiming pozisyonunda
    final launchX = saved.launchX.clamp(0.0, screenWidth);
    final balls = List.generate(
      saved.ballCount,
      (_) => Ball(
        position: Offset(launchX, _launchY),
        velocity: Offset.zero,
        radius: _effectiveBallRadius,
      ),
    );

    gameState.value = GameState(
      balls: balls,
      bricks: saved.bricks,
      bonusBalls: saved.bonusBalls,
      powerUpCells: saved.powerUpCells,
      score: saved.score,
      level: saved.level,
      stage: saved.stage,
      ballCount: saved.ballCount,
      turnPhase: TurnPhase.aiming,
      status: GameStatus.playing,
      launchX: launchX,
    );

    // Progress bar güncelle
    stageProgress.value =
        (_stageDamageDealt / _stageTotalHp).clamp(0.0, 0.99);

    // Kayıtlı oyunu sil (yüklendi, artık gerek yok)
    await GameSaveService.delete(mode);

    _lastTickTime = Duration.zero;
    _startTicker();

    return true;
  }

  // ── Game Over ────────────────────────────────────────────────────────────

  Future<void> _triggerGameOver(int score, int stage) async {
    _ticker?.stop();
    _launchTimer?.cancel();
    await _sound.stopBgm();
    _sound.playGameOver();
    _haptic(HapticFeedback.heavyImpact);

    // Oyun bitti — kayıtlı oyunu sil
    GameSaveService.delete(gameMode.value);

    if (Get.isRegistered<DailyMissionController>()) {
      Get.find<DailyMissionController>().reportGamePlayed();
    }

    final prefs = await SharedPreferences.getInstance();
    final highScore  = prefs.getInt('high_score') ?? 0;
    final bestStage  = prefs.getInt('best_stage') ?? 0;

    if (score > highScore) await prefs.setInt('high_score', score);
    if (stage > bestStage) await prefs.setInt('best_stage', stage);

    // Gem kazanımı: (stage ÷ 2) + 1, gem bonusu çarpanı uygulanır
    final upgrades = Get.find<UpgradeController>();
    final rawGems    = (stage ~/ 2) + 1;
    final earnedGems = (rawGems * upgrades.totalGemMultiplier).round();
    await upgrades.addGems(earnedGems);
    _sound.playGemCollect();

    final state = gameState.value;
    if (state != null) {
      gameState.value = state.copyWith(status: GameStatus.gameOver);
    }

    await Future.delayed(const Duration(milliseconds: 600));

    // Analytics: oyun bitti
    if (Get.isRegistered<AnalyticsService>()) {
      Get.find<AnalyticsService>().logGameOver(
        score: score,
        stage: stage,
        earnedGems: earnedGems,
      );
    }

    // Skoru Firestore'a kaydet (leaderboard + haftalık turnuva)
    _submitScoreToFirestore(score, max(score, highScore));

    Get.toNamed(AppRoutes.gameOver, arguments: {
      'score': score,
      'stage': stage,
      'high_score': max(score, highScore),
      'earned_gems': earnedGems,
      'continues_left': GameConstants.maxContinues - _continueCount,
    });
  }

  // ── Continue Mekanizması ─────────────────────────────────────────────────

  /// Oyuncunun game over ekranından devam etmesi.
  /// Çağrılmadan önce gem/reklam ödemesi yapılmış olmalı.
  void continueGame() {
    if (!canContinue) return;
    final state = gameState.value;
    if (state == null) return;

    final rowH = BrickConfig.size + BrickConfig.gap;
    final shiftRows = GameConstants.continueShiftRows;

    // Tuğlaları yukarı kaydır; üste taşanları sil
    final newBricks = state.bricks
        .map((b) => Brick(
              col: b.col,
              row: b.row - shiftRows,
              hp: b.hp,
              maxHp: b.maxHp,
              type: b.type,
              triangleOrientation: b.triangleOrientation,
              isAlive: b.isAlive,
              shieldActive: b.shieldActive,
            ))
        .where((b) => b.row >= 0)
        .toList();

    // Görsel kayma başlangıç offseti: tuğlalar şimdilik 2 satır aşağıda görünür,
    // _onTick içinde 0'a animasyonlu şekilde düşer.
    brickShiftOffset.value = shiftRows * rowH;

    // State'i sıfırla: oynama moduna dön, aiming aşamasına geç
    gameState.value = state.copyWith(
      bricks: newBricks,
      status: GameStatus.playing,
      turnPhase: TurnPhase.aiming,
    );

    _continueCount++;
    _lastTickTime = Duration.zero;
    _sound.startBgm();
    _startTicker();
  }

  // ── Power-Up Yardımcıları ─────────────────────────────────────────────────

  /// Envanterdeki bir power-up slotuna dokunulunca çağrılır.
  /// Şarj zaten `PowerUpInventoryController` tarafından tüketildi;
  /// burada sadece sıraya alındığını bildiririz.
  void showInventoryPowerUpBanner(PowerUpType type) {
    _showPowerUpBanner('${_powerUpLabel(type)} HAZIR →');
  }

  /// Kısa süreli power-up banner gösterir (2 saniye).
  void _showPowerUpBanner(String text) {
    powerUpText.value = text;
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (powerUpText.value == text) powerUpText.value = '';
    });
  }

  /// PowerUpType için kısa HUD etiketi.
  String _powerUpLabel(PowerUpType type) => switch (type) {
    PowerUpType.fireball   => '🔥 FIREBALL',
    PowerUpType.nuke       => '💥 NUKE',
    PowerUpType.multiBall  => '⚡ MULTI-BALL',
    PowerUpType.speedBoost => '⚡ SPEED',
    PowerUpType.shieldRow  => '🛡 SHIELD',
  };

  // ── Firestore Skor Gönderimi ──────────────────────────────────────────────

  /// Oyun sonu skorunu Firestore'a gönderir (global + haftalık).
  void _submitScoreToFirestore(int score, int bestScore) {
    try {
      if (!Get.isRegistered<FirestoreService>()) return;
      if (!Get.isRegistered<AuthService>()) return;

      final firestore = Get.find<FirestoreService>();
      final auth = Get.find<AuthService>();
      if (auth.uid == null) return;

      // Profildeki displayName'i al, yoksa 'Oyuncu' kullan
      final displayName = auth.currentUser.value?.email != null
          ? auth.currentUser.value!.email!
              .replaceAll('@orbriot.game', '')
          : 'label_default_player'.tr;

      final upgrades = Get.find<UpgradeController>();
      final prestige = upgrades.prestigeLevel.value;

      // Global leaderboard
      firestore.submitScore(
        score: score,
        displayName: displayName,
        prestigeLevel: prestige,
      );

      // Haftalık turnuva
      firestore.submitWeeklyScore(
        score: score,
        displayName: displayName,
      );

      // Otomatik tam cloud save (debounced)
      firestore.autoSave();
    } catch (_) {
      // Firestore hatası oyunu etkilememeli
    }
  }

  // ── Temizlik ─────────────────────────────────────────────────────────────

  @override
  void onClose() {
    _ticker?.dispose();
    _launchTimer?.cancel();
    super.onClose();
  }
}
