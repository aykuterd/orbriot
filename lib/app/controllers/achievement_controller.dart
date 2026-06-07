import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/firestore_service.dart';
import '../models/achievement.dart';
import 'upgrade_controller.dart';

class AchievementController extends GetxController {
  // ── Durum ─────────────────────────────────────────────────────────────────

  final RxList<Achievement> achievements = <Achievement>[].obs;

  /// Açık ama ödülü alınmamış başarım sayısı (badge için)
  int get unclaimedCount =>
      achievements.where((a) => a.unlocked && !a.claimed).length;

  /// Banner gösterme kuyruğu
  final RxList<Achievement> pendingBanners = <Achievement>[].obs;

  // ── Sayaçlar ──────────────────────────────────────────────────────────────

  final Map<AchievementCounter, int> _counters = {
    for (final c in AchievementCounter.values) c: 0,
  };

  SharedPreferences? _prefs;

  static const _kPfx = 'ach_';

  // ── Başlangıç ─────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();

    // Sayaçları yükle
    for (final c in AchievementCounter.values) {
      _counters[c] = _prefs!.getInt('${_kPfx}cnt_${c.name}') ?? 0;
    }

    // Başarım listesini oluştur + durum yükle
    final list = AchievementCatalog.all.map((def) {
      final progress = _counters[def.counter]!.clamp(0, def.target * 10);
      final unlocked = _prefs!.getBool('${_kPfx}unlocked_${def.id}') ?? false;
      final claimed  = _prefs!.getBool('${_kPfx}claimed_${def.id}')  ?? false;
      return Achievement(
        def: def,
        progress: progress.clamp(0, def.target),
        unlocked: unlocked,
        claimed: claimed,
      );
    }).toList();

    achievements.assignAll(list);
  }

  // ── Raporlama (oyundan çağrılır) ──────────────────────────────────────────

  void reportBallFired()           => _increment(AchievementCounter.shotsFired, 1);
  void reportStageCompleted()      => _increment(AchievementCounter.stagesCompleted, 1);
  void reportGemsEarned(int amt)   => _increment(AchievementCounter.gemsEarned, amt);
  void reportUpgradeBought()       => _increment(AchievementCounter.upgradesBought, 1);
  void reportBricksDestroyed(int n)=> _increment(AchievementCounter.totalBricks, n);
  void reportBombDestroyed()       => _increment(AchievementCounter.totalBombs, 1);
  void reportLaserDestroyed()      => _increment(AchievementCounter.totalLasers, 1);
  void reportBricksInTurn(int n)   => _maximize(AchievementCounter.maxBricksInTurn, n);
  void reportBallsInGame(int n)    => _maximize(AchievementCounter.maxBallsInGame, n);
  void reportBossDefeated()        => _increment(AchievementCounter.bossesDefeated, 1);
  void reportPowerUpUsed()         => _increment(AchievementCounter.powerUpsUsed, 1);
  void reportDayPlayed()           => _increment(AchievementCounter.daysPlayed, 1);

  // ── Ödül alma ─────────────────────────────────────────────────────────────

  Future<void> claimReward(Achievement a) async {
    if (!a.unlocked || a.claimed) return;
    await Get.find<UpgradeController>().addGems(a.reward);
    a.claimed = true;
    _prefs?.setBool('${_kPfx}claimed_${a.id}', true);
    achievements.refresh();
    // Otomatik cloud save
    if (Get.isRegistered<FirestoreService>()) {
      Get.find<FirestoreService>().autoSave();
    }
  }

  // ── İç mantık ─────────────────────────────────────────────────────────────

  void _increment(AchievementCounter counter, int amount) {
    final newVal = (_counters[counter] ?? 0) + amount;
    _counters[counter] = newVal;
    _prefs?.setInt('${_kPfx}cnt_${counter.name}', newVal);
    _checkCounter(counter, newVal);
  }

  void _maximize(AchievementCounter counter, int value) {
    final current = _counters[counter] ?? 0;
    if (value <= current) return;
    _counters[counter] = value;
    _prefs?.setInt('${_kPfx}cnt_${counter.name}', value);
    _checkCounter(counter, value);
  }

  void _checkCounter(AchievementCounter counter, int value) {
    bool listChanged = false;

    for (int i = 0; i < achievements.length; i++) {
      final a = achievements[i];
      if (a.def.counter != counter) continue;
      if (a.unlocked) continue; // zaten açık

      // İlerlemeyi güncelle
      final newProgress = value.clamp(0, a.def.target);
      if (newProgress != a.progress) {
        a.progress = newProgress;
        listChanged = true;
      }

      // Kilidi aç
      if (value >= a.def.target) {
        a.unlocked = true;
        _prefs?.setBool('${_kPfx}unlocked_${a.id}', true);
        listChanged = true;
        _showBanner(a);
      }
    }

    if (listChanged) achievements.refresh();
  }

  void _showBanner(Achievement a) {
    // Frame bittikten sonra göster — gesture callback'inden güvenli çıkış
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = Get.overlayContext ?? Get.context;
      if (ctx == null) return;

      OverlayState? overlay;
      try {
        overlay = Overlay.of(ctx, rootOverlay: true);
      } catch (_) {
        return;
      }

      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (_) => _AchievementBannerWidget(
          achievement: a,
          onRemove: () {
            if (entry.mounted) entry.remove();
          },
        ),
      );

      overlay.insert(entry);
      Future.delayed(const Duration(milliseconds: 3500), () {
        if (entry.mounted) entry.remove();
      });
    });
  }
}

// ── Banner Overlay Widget ─────────────────────────────────────────────────────

class _AchievementBannerWidget extends StatefulWidget {
  const _AchievementBannerWidget({
    required this.achievement,
    required this.onRemove,
  });

  final Achievement achievement;
  final VoidCallback onRemove;

  @override
  State<_AchievementBannerWidget> createState() =>
      _AchievementBannerWidgetState();
}

class _AchievementBannerWidgetState extends State<_AchievementBannerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset>   _slide;
  late final Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5)),
    );

    _ctrl.forward();

    // Çıkış: 2.8 saniye sonra başlar
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) _ctrl.reverse().then((_) => widget.onRemove());
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a    = widget.achievement;
    final tier = a.def.tier;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1C35),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: tier.color.withAlpha(180), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: tier.color.withAlpha(100),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // İkon kutusu
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: tier.color.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: tier.color.withAlpha(120)),
                    ),
                    child: Icon(a.def.icon, color: tier.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'label_achievement_unlocked'.tr,
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: tier.color,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          a.def.localizedTitle,
                          style: const TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Ödül
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFF7C3AED).withAlpha(160)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.diamond_rounded,
                            size: 12, color: Color(0xFFA78BFA)),
                        const SizedBox(width: 4),
                        Text(
                          '+${a.def.reward}',
                          style: const TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFA78BFA),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
