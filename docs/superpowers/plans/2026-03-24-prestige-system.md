# Prestige Sistemi Implementation Planı

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ORBRIOT oyununa tüm yükseltmeler max'a gelince tetiklenen, gem+yükseltme sıfırlayan ve kalıcı +%10 gem çarpanı kazandıran Prestige sistemi ekle.

**Architecture:** `UpgradeController`'a prestige level/multiplier field'ları eklenir; yeni `PrestigeController` sadece prestige akışını (canPrestige kontrolü, sıfırlama, kalıcı kayıt) yönetir. UI katmanı üç bileşenden oluşur: `PrestigeBadgeWidget` (home + HUD), `PrestigeButton` (Upgrade Shop'ta), `PrestigeModal` (dramatik onay ekranı).

**Tech Stack:** Flutter, GetX (reactive state), SharedPreferences (persistence), Google Fonts (Orbitron), AnimationController (shimmer + modal animasyonları)

---

## Dosya Haritası

| Durum | Dosya | Sorumluluk |
|-------|-------|------------|
| Güncelle | `lib/app/controllers/upgrade_controller.dart` | `prestigeLevel`, `prestigeGemMultiplier`, `totalGemMultiplier`, `resetForPrestige()` |
| Yeni | `lib/app/controllers/prestige_controller.dart` | `canPrestige`, `executePrestige()`, prestige akışı |
| Güncelle | `lib/app/bindings/home_binding.dart` | `PrestigeController` kaydı |
| Yeni | `lib/app/views/home/widgets/prestige_badge_widget.dart` | 👑 Glowing Crown badge (home + HUD paylaşımlı) |
| Yeni | `lib/app/views/upgrade/widgets/prestige_button.dart` | Upgrade Shop'taki tetikleyici buton |
| Yeni | `lib/app/views/upgrade/widgets/prestige_modal.dart` | Dramatik tam ekran onay modalı |
| Güncelle | `lib/app/views/upgrade/widgets/upgrades_tab.dart` | Prestige butonunu listenin altına ekle |
| Güncelle | `lib/app/views/home/home_view.dart` | Top-right row'a badge ekle |
| Güncelle | `lib/app/views/game/game_view.dart` | `_NeonHudBar`'a badge ekle |

---

## Task 1: UpgradeController — Prestige Field'ları

**Files:**
- Modify: `lib/app/controllers/upgrade_controller.dart`

### Yapılacaklar

- [ ] `upgrade_controller.dart` dosyasını aç, mevcut kodu oku

- [ ] `gems` field'ının hemen altına prestige level ekle:

```dart
final RxInt prestigeLevel = 0.obs;
static const _kPrestigeLevel = 'prestige_level';
static const int maxPrestigeLevel = 5;
```

- [ ] `_load()` metoduna prestige yüklemeyi ekle (mevcut gem yüklemenin hemen altına):

```dart
prestigeLevel.value = prefs.getInt(_kPrestigeLevel) ?? 0;
```

- [ ] Hesaplanan çarpanları ekle (`gemMultiplier` getter'ının hemen altına):

```dart
/// Prestige başına +%10 gem çarpanı (stacks, max x5 = +%50)
double get prestigeGemMultiplier =>
    1.0 + 0.10 * prestigeLevel.value;

/// Toplam gem çarpanı (upgrade çarpanı × prestige çarpanı)
double get totalGemMultiplier => gemMultiplier * prestigeGemMultiplier;
```

- [ ] `// ── İşlemler` bölümüne `resetForPrestige()` metodunu ekle:

```dart
/// Prestige için yükseltme seviyelerini ve gem'i sıfırlar.
/// Prestige level ve diğer sistemler (skinler, başarımlar) korunur.
Future<void> resetForPrestige() async {
  // Tüm upgrade seviyelerini sıfırla
  for (final def in UpgradeCatalog.all) {
    _levels[def.key] = 0;
  }
  // Gem'i sıfırla
  gems.value = 0;

  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_kGems, 0);
  for (final def in UpgradeCatalog.all) {
    await prefs.setInt('upg_${def.key}', 0);
  }
}

/// Prestige level'ı artırır ve kaydeder.
Future<void> incrementPrestigeLevel() async {
  if (prestigeLevel.value >= maxPrestigeLevel) return;
  prestigeLevel.value++;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_kPrestigeLevel, prestigeLevel.value);
}
```

- [ ] `GameController` ve diğer gem çarpanı kullanan yerlerde `gemMultiplier` yerine `totalGemMultiplier` kullanıldığını doğrula (grep ile):

```bash
grep -r "gemMultiplier" /Users/aykut/StudioProjects/orbriot/lib --include="*.dart"
```

- [ ] `game_controller.dart:876` satırında `upgrades.gemMultiplier` → `upgrades.totalGemMultiplier` olarak değiştir (tek kullanım yeri burasıdır, diğer referanslar getter tanımının kendisidir):

```dart
// game_controller.dart:876 — öncesi:
final earnedGems = (rawGems * upgrades.gemMultiplier).round();
// sonrası:
final earnedGems = (rawGems * upgrades.totalGemMultiplier).round();
```

- [ ] Hot reload ile derleme hatası olmadığını kontrol et:

```bash
cd /Users/aykut/StudioProjects/orbriot && flutter analyze lib/app/controllers/upgrade_controller.dart
```

---

## Task 2: PrestigeController Oluştur

**Files:**
- Create: `lib/app/controllers/prestige_controller.dart`

### Yapılacaklar

- [ ] Dosyayı oluştur:

```dart
import 'package:get/get.dart';
import 'upgrade_controller.dart';
import '../models/upgrade_config.dart';

class PrestigeController extends GetxController {
  UpgradeController get _upgrade => Get.find<UpgradeController>();

  /// Tüm yükseltmeler max seviyede VE prestige limiti dolmamışsa true.
  bool get canPrestige {
    if (_upgrade.prestigeLevel.value >= UpgradeController.maxPrestigeLevel) {
      return false;
    }
    return UpgradeCatalog.all
        .every((def) => _upgrade.levelOf(def.key) >= def.maxLevel);
  }

  /// Mevcut prestige level (0-5).
  int get currentLevel => _upgrade.prestigeLevel.value;

  /// Prestige yapıldıktan sonraki gem çarpanı.
  double get nextMultiplier =>
      1.0 + 0.10 * (currentLevel + 1);

  /// Prestige uygula: upgrade + gem sıfırla, level artır.
  Future<void> executePrestige() async {
    if (!canPrestige) return;
    await _upgrade.incrementPrestigeLevel();
    await _upgrade.resetForPrestige();
  }
}
```

- [ ] Analiz et:

```bash
cd /Users/aykut/StudioProjects/orbriot && flutter analyze lib/app/controllers/prestige_controller.dart
```

---

## Task 3: HomeBinding'e PrestigeController Ekle

**Files:**
- Modify: `lib/app/bindings/home_binding.dart`

### Yapılacaklar

- [ ] Import ekle (dosyanın üstüne, diğer controller importlarının yanına):

```dart
import '../controllers/prestige_controller.dart';
```

- [ ] `dependencies()` metoduna kayıt ekle (SkinController kaydının hemen altına):

```dart
// PrestigeController uygulama boyunca yaşar (permanent: true)
if (!Get.isRegistered<PrestigeController>()) {
  Get.put<PrestigeController>(PrestigeController(), permanent: true);
}
```

- [ ] Analiz et:

```bash
cd /Users/aykut/StudioProjects/orbriot && flutter analyze lib/app/bindings/home_binding.dart
```

---

## Task 4: PrestigeBadgeWidget Oluştur

**Files:**
- Create: `lib/app/views/home/widgets/prestige_badge_widget.dart`

Bu widget hem `HomeView` hem `GameView` HUD'ında kullanılacak.

### Yapılacaklar

- [ ] Dosyayı oluştur:

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/upgrade_controller.dart';

/// 👑 Glowing Crown prestige badge.
/// Prestige level 0'da görünmez.
/// Hem HomeView hem GameView HUD'ında kullanılır.
class PrestigeBadgeWidget extends StatefulWidget {
  /// Küçük versiyon (HUD için). Varsayılan: false (home için normal boy).
  final bool compact;

  const PrestigeBadgeWidget({super.key, this.compact = false});

  @override
  State<PrestigeBadgeWidget> createState() => _PrestigeBadgeWidgetState();
}

class _PrestigeBadgeWidgetState extends State<PrestigeBadgeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmer;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _shimmerAnim = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmer, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  String _romanNumeral(int level) {
    const numerals = ['I', 'II', 'III', 'IV', 'V'];
    if (level < 1 || level > 5) return '';
    return numerals[level - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ctrl = Get.find<UpgradeController>();
      final level = ctrl.prestigeLevel.value;
      if (level == 0) return const SizedBox.shrink();

      final double badgeH = widget.compact ? 28 : 36;
      final double crownSize = widget.compact ? 14 : 18;
      final double titleSize = widget.compact ? 7 : 8;
      final double levelSize = widget.compact ? 11 : 13;
      final double hPad = widget.compact ? 8 : 12;
      final double vPad = widget.compact ? 4 : 6;

      return AnimatedBuilder(
        animation: _shimmerAnim,
        builder: (context, child) {
          return Container(
            height: badgeH,
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: const [
                  Color(0xFF1c1000),
                  Color(0xFF2a1a00),
                  Color(0xFF1c1000),
                ],
              ),
              borderRadius: BorderRadius.circular(widget.compact ? 10 : 14),
              border: Border.all(
                color: const Color(0xFFFBBF24).withAlpha(128),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFBBF24).withAlpha(51),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Shimmer overlay
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(widget.compact ? 10 : 14),
                    child: Transform.translate(
                      offset: Offset(
                          _shimmerAnim.value * 80, 0),
                      child: Container(
                        width: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              const Color(0xFFFBBF24).withAlpha(20),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // İçerik
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '👑',
                      style: TextStyle(fontSize: crownSize),
                    ),
                    const SizedBox(width: 5),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PRESTIGE',
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: titleSize,
                            letterSpacing: 1.5,
                            color: const Color(0xFFFBBF24).withAlpha(153),
                            height: 1.0,
                          ),
                        ),
                        Text(
                          'LV. ${_romanNumeral(level)}',
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: levelSize,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: const Color(0xFFFBBF24),
                            height: 1.0,
                            shadows: [
                              Shadow(
                                color: const Color(0xFFFBBF24).withAlpha(153),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    });
  }
}
```

- [ ] Analiz et:

```bash
cd /Users/aykut/StudioProjects/orbriot && flutter analyze lib/app/views/home/widgets/prestige_badge_widget.dart
```

---

## Task 5: PrestigeButton Oluştur

**Files:**
- Create: `lib/app/views/upgrade/widgets/prestige_button.dart`

### Yapılacaklar

- [ ] Dosyayı oluştur:

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/prestige_controller.dart';
import '../../../controllers/upgrade_controller.dart';
import 'prestige_modal.dart';

/// Upgrade Shop'ta tüm yükseltmeler max'a gelince görünen Prestige butonu.
class PrestigeButton extends StatelessWidget {
  const PrestigeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final prestige = Get.find<PrestigeController>();
      final upgrade = Get.find<UpgradeController>();

      final canPrestige = prestige.canPrestige;
      final level = upgrade.prestigeLevel.value;
      final isMaxed = level >= UpgradeController.maxPrestigeLevel;

      // Prestige yapılamıyor ve max prestige'e ulaşıldıysa tamamen gizle
      if (isMaxed) {
        return _MaxPrestigeBanner(level: level);
      }

      return Column(
        children: [
          const SizedBox(height: 8),
          // Ayırıcı çizgi
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  canPrestige
                      ? const Color(0xFFFBBF24).withAlpha(128)
                      : Colors.white.withAlpha(20),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Durum bilgisi
          if (!canPrestige)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Tüm yükseltmeleri max\'a getir',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 10,
                  letterSpacing: 1,
                  color: Colors.white.withAlpha(51),
                ),
              ),
            ),
          // Ana buton
          GestureDetector(
            onTap: canPrestige
                ? () => showPrestigeModal(context)
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: canPrestige
                    ? const LinearGradient(
                        colors: [Color(0xFF2a1a00), Color(0xFF3d2500)],
                      )
                    : null,
                color: canPrestige ? null : const Color(0xFF1a1a2e),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: canPrestige
                      ? const Color(0xFFFBBF24).withAlpha(179)
                      : Colors.white.withAlpha(20),
                  width: 1.5,
                ),
                boxShadow: canPrestige
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFBBF24).withAlpha(77),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Text(
                    '👑',
                    style: TextStyle(
                      fontSize: canPrestige ? 28 : 20,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'PRESTIGE',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      color: canPrestige
                          ? const Color(0xFFFBBF24)
                          : Colors.white.withAlpha(51),
                      shadows: canPrestige
                          ? [
                              Shadow(
                                color: const Color(0xFFFBBF24).withAlpha(179),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    level == 0
                        ? '+%10 kalıcı gem çarpanı'
                        : 'LV.${_roman(level)} → LV.${_roman(level + 1)} · +%${(level + 1) * 10} toplam',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 9,
                      letterSpacing: 1,
                      color: canPrestige
                          ? const Color(0xFFFBBF24).withAlpha(179)
                          : Colors.white.withAlpha(38),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      );
    });
  }

  String _roman(int n) {
    const r = ['I', 'II', 'III', 'IV', 'V'];
    if (n < 1 || n > 5) return '';
    return r[n - 1];
  }
}

class _MaxPrestigeBanner extends StatelessWidget {
  final int level;
  const _MaxPrestigeBanner({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2a1a00), Color(0xFF1c1000)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFBBF24).withAlpha(102),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👑', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PRESTIGE LV. V',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFFBBF24),
                ),
              ),
              Text(
                'Maksimum prestige seviyesine ulaştın!',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 9,
                  color: const Color(0xFFFBBF24).withAlpha(128),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] Analiz et:

```bash
cd /Users/aykut/StudioProjects/orbriot && flutter analyze lib/app/views/upgrade/widgets/prestige_button.dart
```

---

## Task 6: PrestigeModal Oluştur

**Files:**
- Create: `lib/app/views/upgrade/widgets/prestige_modal.dart`

### Yapılacaklar

- [ ] Dosyayı oluştur:

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/prestige_controller.dart';
import '../../../controllers/upgrade_controller.dart';
import '../../../models/upgrade_config.dart';

/// Prestige onay modal'ını gösterir.
void showPrestigeModal(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Prestige',
    barrierColor: Colors.black.withAlpha(204),
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (_, __, ___) => const _PrestigeModalContent(),
    transitionBuilder: (context, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(curved),
        child: FadeTransition(opacity: anim, child: child),
      );
    },
  );
}

class _PrestigeModalContent extends StatelessWidget {
  const _PrestigeModalContent();

  String _roman(int n) {
    const r = ['I', 'II', 'III', 'IV', 'V'];
    if (n < 1 || n > 5) return '';
    return r[n - 1];
  }

  @override
  Widget build(BuildContext context) {
    final prestige = Get.find<PrestigeController>();
    final upgrade = Get.find<UpgradeController>();
    final currentLevel = prestige.currentLevel;
    final nextLevel = currentLevel + 1;
    final nextMultiplierPct = (nextLevel * 10);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F23),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFBBF24).withAlpha(102),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFBBF24).withAlpha(38),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Başlık
              const Text('👑', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text(
                'PRESTIGE',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  color: const Color(0xFFFBBF24),
                  shadows: [
                    Shadow(
                      color: const Color(0xFFFBBF24).withAlpha(179),
                      blurRadius: 16,
                    ),
                  ],
                ),
              ),
              Text(
                'LV. ${_roman(currentLevel)} → LV. ${_roman(nextLevel)}',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 11,
                  letterSpacing: 2,
                  color: const Color(0xFFFBBF24).withAlpha(153),
                ),
              ),
              const SizedBox(height: 24),

              // Kaybedilecekler
              _SectionCard(
                icon: '⚠️',
                title: 'KAYBEDECEKSIN',
                titleColor: const Color(0xFFEF4444),
                borderColor: const Color(0xFFEF4444).withAlpha(77),
                items: [
                  '${upgrade.gems.value} 💎 gem',
                  ...UpgradeCatalog.all.map((d) =>
                      '${d.name}: LV.${upgrade.levelOf(d.key)} → LV.0'),
                ],
                itemColor: const Color(0xFFFCA5A5),
              ),
              const SizedBox(height: 12),

              // Kazanılacaklar
              _SectionCard(
                icon: '✨',
                title: 'KAZANACAKSIN',
                titleColor: const Color(0xFF22C55E),
                borderColor: const Color(0xFF22C55E).withAlpha(77),
                items: [
                  'Kalıcı +%$nextMultiplierPct gem çarpanı',
                  '👑 Prestige LV. ${_roman(nextLevel)} rozeti',
                ],
                itemColor: const Color(0xFF86EFAC),
              ),
              const SizedBox(height: 24),

              // Butonlar
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: Colors.white.withAlpha(51),
                          ),
                        ),
                      ),
                      child: Text(
                        'İPTAL',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 12,
                          letterSpacing: 2,
                          color: Colors.white.withAlpha(128),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await prestige.executePrestige();
                        // Başarı bildirimi
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '👑 Prestige LV. ${_roman(nextLevel)} tamamlandı! +%$nextMultiplierPct gem çarpanı aktif.',
                                style: const TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 11,
                                  color: Colors.black,
                                ),
                              ),
                              backgroundColor: const Color(0xFFFBBF24),
                              duration: const Duration(seconds: 3),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFBBF24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        '✦ ONAYLA',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String icon;
  final String title;
  final Color titleColor;
  final Color borderColor;
  final List<String> items;
  final Color itemColor;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.titleColor,
    required this.borderColor,
    required this.items,
    required this.itemColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: titleColor.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: titleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                '• $item',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 10,
                  color: itemColor,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] Analiz et:

```bash
cd /Users/aykut/StudioProjects/orbriot && flutter analyze lib/app/views/upgrade/widgets/prestige_modal.dart
```

---

## Task 7: UpgradesTab'a PrestigeButton Ekle

**Files:**
- Modify: `lib/app/views/upgrade/widgets/upgrades_tab.dart`

### Yapılacaklar

- [ ] Dosyanın başına import ekle:

```dart
import 'prestige_button.dart';
```

- [ ] `UpgradesTab.build()` metodundaki `return ListView(...)` bloğunu şöyle güncelle. Mevcut `Obx` ve `_UpgradeCard` koduna **dokunma**, sadece `children:` parametresini spread + `PrestigeButton` ekleyecek şekilde düzenle:

```dart
return ListView(
  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
  children: [
    ...UpgradeCatalog.all
        .map((def) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Obx(() {
                final level = ctrl.levelOf(def.key);
                final isMax = level >= def.maxLevel;
                final cost = def.nextCost(level);
                final canAfford = ctrl.gems.value >= cost;
                return _UpgradeCard(
                  def: def,
                  level: level,
                  isMax: isMax,
                  cost: cost,
                  canAfford: canAfford,
                  onBuy: () async {
                    final ok = await ctrl.purchase(def);
                    if (ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '\${def.name} yükseltildi!',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: Colors.white),
                          ),
                          backgroundColor: def.color.withAlpha(220),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      );
                    }
                  },
                );
              }),
            ))
        .toList(),
    // Prestige butonu — en altta, mevcut upgrade kartlarından sonra
    const PrestigeButton(),
  ],
);
```

- [ ] Analiz et:

```bash
cd /Users/aykut/StudioProjects/orbriot && flutter analyze lib/app/views/upgrade/widgets/upgrades_tab.dart
```

---

## Task 8: HomeView'a Badge Ekle

**Files:**
- Modify: `lib/app/views/home/home_view.dart`

### Yapılacaklar

- [ ] Import ekle (mevcut widget importlarının yanına):

```dart
import 'widgets/prestige_badge_widget.dart';
```

- [ ] Top-right icon buton `Row`'una, ayarlar ikonunun en soluna (mevcut başarım ikonundan önce) badge ekle:

```dart
// Mevcut Row yapısı — en başa ekle:
const PrestigeBadgeWidget(),
const SizedBox(width: 4),
// ... mevcut başarım ikonu devam eder
```

- [ ] Analiz et:

```bash
cd /Users/aykut/StudioProjects/orbriot && flutter analyze lib/app/views/home/home_view.dart
```

---

## Task 9: GameView HUD'a Badge Ekle

**Files:**
- Modify: `lib/app/views/game/game_view.dart`

### Yapılacaklar

- [ ] Import ekle:

```dart
import '../home/widgets/prestige_badge_widget.dart';
```

- [ ] `_NeonHudBar`'ın `build` metodundaki içerik `Row`'unda, `_ScoreBlock`'un hemen sağına (mevcut `const Spacer()`'dan önce) compact badge ekle:

```dart
_ScoreBlock(score: score),
const SizedBox(width: 8),
const PrestigeBadgeWidget(compact: true),  // ← yeni
const Spacer(),
// ... devam eder
```

- [ ] Analiz et:

```bash
cd /Users/aykut/StudioProjects/orbriot && flutter analyze lib/app/views/game/game_view.dart
```

---

## Task 10: Tam Analiz ve Derleme Kontrolü

**Files:**
- Tüm değiştirilen dosyalar

### Yapılacaklar

- [ ] Tüm projeyi analiz et:

```bash
cd /Users/aykut/StudioProjects/orbriot && flutter analyze
```

- [ ] Hata varsa düzelt, tekrar analiz et

- [ ] Uygulamayı debug modda çalıştır ve şu senaryoları test et:

1. **Prestige butonu gizli:** Shop'ta bazı yükseltmeler max değilken buton kilitli görünüyor mu?
2. **Prestige butonu aktif:** Tüm yükseltmeleri max yap (debug'da hızlıca gem ekle), buton altın rengi alıyor mu?
3. **Modal açılıyor:** Butona basınca dramatik modal geliyor mu?
4. **Sıfırlama çalışıyor:** ONAYLA'ya basınca gemler + yükseltmeler sıfırlanıyor mu?
5. **Badge görünüyor:** Prestige sonrası home ekranında ve HUD'da 👑 LV. I badge görünüyor mu?
6. **Çarpan çalışıyor:** Oyun sonunda gem kazanımı %10 artmış mı?
7. **Persistence:** Uygulama kapatıp açınca prestige level korunuyor mu?
8. **Max prestige:** 5 kez prestige sonrası buton yerine banner gösteriliyor mu?

---

## Referans: Roma Rakamları

| Level | Gösterim |
|-------|---------|
| 1 | LV. I |
| 2 | LV. II |
| 3 | LV. III |
| 4 | LV. IV |
| 5 | LV. V |

## Referans: Renkler

| Amaç | Renk |
|------|------|
| Prestige altın | `#FBBF24` |
| Prestige arka plan | `#1c1000` → `#2a1a00` |
| Kayıp (kırmızı) | `#EF4444` |
| Kazanım (yeşil) | `#22C55E` |
| Ana tema | `#7C3AED` |
