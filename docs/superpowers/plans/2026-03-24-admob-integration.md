# AdMob Reklam Entegrasyonu — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Orbriot'a Google AdMob entegrasyonu — Rewarded Ad (gem kazan + continue) ve Interstitial Ad (her 3 game over'da 1), ad-free flag altyapısı.

**Architecture:** Merkezi `AdService` (GetxService) tüm reklam yönetimini üstlenir. Mevcut placeholder'lar (`_onAdTap`, `claimAdReward`) `AdService`'i çağıracak şekilde güncellenir. Ad-free flag `AdService` içinde SharedPreferences ile yönetilir.

**Tech Stack:** Flutter, GetX, google_mobile_ads ^5.3.0, SharedPreferences

**Spec:** `docs/superpowers/specs/2026-03-24-admob-integration-design.md`

---

## Dosya Haritası

| Dosya | İşlem | Sorumluluk |
|-------|-------|-----------|
| `pubspec.yaml` | Modify | google_mobile_ads dependency |
| `android/app/src/main/AndroidManifest.xml` | Modify | AdMob Application ID meta-data |
| `ios/Runner/Info.plist` | Modify | GADApplicationIdentifier + SKAdNetwork |
| `lib/app/core/utils/ad_service.dart` | **Create** | Merkezi reklam yönetimi (rewarded, interstitial, ad-free) |
| `lib/main.dart` | Modify | MobileAds init + AdService register |
| `lib/app/views/upgrade/widgets/earn_tab.dart` | Modify | Placeholder → gerçek rewarded ad |
| `lib/app/views/game_over/game_over_view.dart` | Modify | Placeholder → gerçek rewarded + interstitial |

---

## Task 1: Platform Konfigürasyonu

**Files:**
- Modify: `pubspec.yaml:30-38`
- Modify: `android/app/src/main/AndroidManifest.xml:1-45`
- Modify: `ios/Runner/Info.plist:1-70`

- [ ] **Step 1: pubspec.yaml'a google_mobile_ads ekle**

`pubspec.yaml` dosyasında `audioplayers: ^6.1.0` satırından sonra ekle:

```yaml
  google_mobile_ads: ^5.3.0
```

- [ ] **Step 2: flutter pub get çalıştır**

Run: `cd /Users/aykut/StudioProjects/orbriot && flutter pub get`
Expected: `Got dependencies!` mesajı, hata yok.

- [ ] **Step 3: AndroidManifest.xml'e AdMob meta-data ekle**

`android/app/src/main/AndroidManifest.xml` dosyasında `</application>` kapanış tag'inden hemen önce (satır 33), `flutterEmbedding` meta-data'dan sonra ekle:

```xml
        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="ca-app-pub-3940256099942544~3347511713"/>
```

- [ ] **Step 4: Info.plist'e GADApplicationIdentifier ve SKAdNetwork ekle**

`ios/Runner/Info.plist` dosyasında `</dict>` kapanış tag'inden hemen önce (satır 69) ekle:

```xml
	<key>GADApplicationIdentifier</key>
	<string>ca-app-pub-3940256099942544~1458002511</string>
	<key>SKAdNetworkItems</key>
	<array>
		<dict>
			<key>SKAdNetworkIdentifier</key>
			<string>cstr6suwn9.skadnetwork</string>
		</dict>
	</array>
```

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock android/app/src/main/AndroidManifest.xml ios/Runner/Info.plist
git commit -m "feat: add google_mobile_ads dependency and platform config (test IDs)"
```

---

## Task 2: AdService Oluştur

**Files:**
- Create: `lib/app/core/utils/ad_service.dart`

- [ ] **Step 1: AdService dosyasını oluştur**

`lib/app/core/utils/ad_service.dart` dosyasını aşağıdaki içerikle oluştur:

```dart
import 'dart:async';
import 'dart:io' show Platform;
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Merkezi reklam yönetim servisi.
/// Global GetxService olarak app ömür boyu yaşar.
class AdService extends GetxService {
  // ── Ad-Free Flag ────────────────────────────────────────────────────────
  static const _kAdFreeKey = 'ad_free';
  final RxBool isAdFree = false.obs;

  // ── Interstitial Sayacı ─────────────────────────────────────────────────
  int _gameOverCount = 0;

  // ── Ad Instances ────────────────────────────────────────────────────────
  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  bool _isShowingAd = false;

  // ── Test Ad Unit IDs ────────────────────────────────────────────────────
  String get _rewardedAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/5224354917'
      : 'ca-app-pub-3940256099942544/1712485313';

  String get _interstitialAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';

  // ── Initialization ──────────────────────────────────────────────────────

  /// Servisi başlat: isAdFree flag'i yükle ve reklamları ön yükle.
  /// MobileAds.instance.initialize() main.dart'ta çağrılmalı.
  Future<AdService> init() async {
    final prefs = await SharedPreferences.getInstance();
    isAdFree.value = prefs.getBool(_kAdFreeKey) ?? false;
    _preloadRewarded();
    _preloadInterstitial();
    return this;
  }

  // ── Ad-Free Yönetimi ───────────────────────────────────────────────────

  Future<void> setAdFree(bool value) async {
    isAdFree.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAdFreeKey, value);
  }

  // ── Rewarded Ad ─────────────────────────────────────────────────────────

  /// Rewarded reklam gösterir.
  /// Kullanıcı ödülü kazandıysa `true`, aksi halde `false` döner.
  Future<bool> showRewardedAd() async {
    if (isAdFree.value) return false;
    if (_isShowingAd) return false;

    // Reklam yüklü değilse yüklemeyi dene, 10 sn timeout
    if (_rewardedAd == null) {
      _preloadRewarded();
      final loaded = await _waitForRewarded();
      if (!loaded) return false;
    }

    final ad = _rewardedAd;
    if (ad == null) return false;

    _isShowingAd = true;
    bool _earned = false;
    final completer = Completer<bool>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _isShowingAd = false;
        _preloadRewarded();
        if (!completer.isCompleted) completer.complete(_earned);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _isShowingAd = false;
        _preloadRewarded();
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    ad.show(onUserEarnedReward: (_, __) {
      _earned = true;
    });

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _isShowingAd = false;
        return false;
      },
    );
  }

  /// Rewarded reklam yüklenmesini 10 sn bekler.
  Future<bool> _waitForRewarded() async {
    for (int i = 0; i < 20; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (_rewardedAd != null) return true;
    }
    return false;
  }

  void _preloadRewarded() {
    if (_rewardedAd != null) return;
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (error) {
          // Sessizce log — sonraki kullanıcı aksiyonunda tekrar dener
          _rewardedAd = null;
        },
      ),
    );
  }

  // ── Interstitial Ad ─────────────────────────────────────────────────────

  /// Game over sayacını artırır.
  void incrementGameOver() => _gameOverCount++;

  /// Interstitial gösterilmeli mi? (Her 3 game over'da 1)
  bool get shouldShowInterstitial =>
      _gameOverCount % 3 == 0 && _gameOverCount > 0 && !isAdFree.value;

  /// Interstitial reklam gösterir.
  /// Reklam yüklü değilse beklemez, direkt true döner (navigasyon engellenmez).
  /// Reklam kapandıktan sonra `true` döner.
  Future<bool> showInterstitialAd() async {
    if (isAdFree.value) return true;
    if (_isShowingAd) return true;

    // Reklam yüklü değilse navigasyonu engelleme, preload et ve geç
    if (_interstitialAd == null) {
      _preloadInterstitial();
      return true;
    }

    final ad = _interstitialAd;
    if (ad == null) return true;

    _isShowingAd = true;
    final completer = Completer<bool>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _isShowingAd = false;
        _preloadInterstitial();
        if (!completer.isCompleted) completer.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _isShowingAd = false;
        _preloadInterstitial();
        if (!completer.isCompleted) completer.complete(true);
      },
    );

    ad.show();

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _isShowingAd = false;
        return true;
      },
    );
  }

  void _preloadInterstitial() {
    if (_interstitialAd != null) return;
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
        },
      ),
    );
  }

  // ── Cleanup ─────────────────────────────────────────────────────────────

  @override
  void onClose() {
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    super.onClose();
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/app/core/utils/ad_service.dart
git commit -m "feat: create AdService with rewarded/interstitial ad management"
```

---

## Task 3: main.dart'a AdService Kaydı

**Files:**
- Modify: `lib/main.dart:1-33`

- [ ] **Step 1: main.dart'ı güncelle**

`lib/main.dart` dosyasında şu değişiklikleri yap:

Import'lara ekle:
```dart
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'app/core/utils/ad_service.dart';
```

`main()` fonksiyonunu `async` yap ve `runApp` öncesinde MobileAds init + AdService register ekle:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  await MobileAds.instance.initialize();
  await Get.putAsync(() => AdService().init());
  runApp(const OrbriotApp());
}
```

- [ ] **Step 2: Build kontrolü**

Run: `cd /Users/aykut/StudioProjects/orbriot && flutter build apk --debug 2>&1 | tail -5`
Expected: `BUILD SUCCESSFUL` veya `✓ Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 3: Commit**

```bash
git add lib/main.dart
git commit -m "feat: initialize MobileAds and register AdService at app start"
```

---

## Task 4: Earn Tab — Rewarded Ad Entegrasyonu

**Files:**
- Modify: `lib/app/views/upgrade/widgets/earn_tab.dart:12-352`

- [ ] **Step 1: EarnTab'da const kaldır ve Obx ile ad-free kontrolü ekle**

`earn_tab.dart` dosyasında `EarnTab` widget'ının `build` metodunda `children: const [` ifadesini `children: [` olarak değiştir. `_AdRewardCard()` satırını `Obx` ile sar:

```dart
  @override
  Widget build(BuildContext context) {
    final adService = Get.find<AdService>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const _DailyChargeCard(),
        const SizedBox(height: 12),
        Obx(() => adService.isAdFree.value
            ? const SizedBox.shrink()
            : const _AdRewardCard()),
        const SizedBox(height: 16),
        const SectionHeader(title: 'PAKET'),
        const SizedBox(height: 12),
        const MegaPackCard(),
      ],
    );
  }
```

Import ekle (dosyanın üstüne):
```dart
import '../../../core/utils/ad_service.dart';
```

- [ ] **Step 2: _AdRewardCard'da reklam izleme butonuna AdService ekle**

`_AdRewardCard` widget'ının `GestureDetector.onTap` callback'inde (satır ~284-308), mevcut placeholder logic'i şu şekilde değiştir:

```dart
                  GestureDetector(
                    onTap: canClaim
                        ? () async {
                            HapticFeedback.lightImpact();
                            final adService = Get.find<AdService>();
                            final adShown = await adService.showRewardedAd();
                            if (!adShown) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Reklam yüklenemedi, tekrar dene',
                                      style: AppTextStyles.bodySmall
                                          .copyWith(color: Colors.white),
                                    ),
                                    backgroundColor: AppColors.accent.withAlpha(220),
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                );
                              }
                              return;
                            }
                            final ok = await ctrl.claimAdReward();
                            if (ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '+10 💎 kazandın!',
                                    style: AppTextStyles.bodySmall
                                        .copyWith(color: Colors.white),
                                  ),
                                  backgroundColor: color.withAlpha(220),
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                              );
                            }
                          }
                        : null,
```

- [ ] **Step 3: Commit**

```bash
git add lib/app/views/upgrade/widgets/earn_tab.dart
git commit -m "feat: integrate rewarded ad into earn tab gem reward flow"
```

---

## Task 5: Game Over — Rewarded Ad Continue

**Files:**
- Modify: `lib/app/views/game_over/game_over_view.dart:1-637`

- [ ] **Step 1: Import ekle**

`game_over_view.dart` dosyasının üstüne import ekle:

```dart
import '../../core/utils/ad_service.dart';
```

- [ ] **Step 2: _ContinueButtonsState._onAdTap() metodunu güncelle**

Mevcut `_onAdTap()` metodunu (satır 430-438) şu şekilde değiştir:

```dart
  Future<void> _onAdTap() async {
    if (_adLoading) return;
    setState(() => _adLoading = true);
    final adService = Get.find<AdService>();
    final success = await adService.showRewardedAd();
    if (!mounted) return;
    setState(() => _adLoading = false);
    if (success) {
      _doResume();
    } else {
      Get.snackbar(
        'Reklam Yüklenemedi',
        'Lütfen tekrar dene',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF1A1A2E),
        colorText: const Color(0xFFE2E8F0),
        margin: const EdgeInsets.all(12),
      );
    }
  }
```

- [ ] **Step 3: Ad-free olunca "Reklam İzle" butonunu gizle**

`_ContinueButtonsState.build()` metodunda (satır 448-481), "Reklam ile devam" bölümünü `Obx` ile sar:

```dart
        // ▶ Reklam ile devam (ad-free ise SizedBox dahil gizlenir)
        Obx(() {
          final adService = Get.find<AdService>();
          if (adService.isAdFree.value) return const SizedBox.shrink();
          return Column(
            children: [
              const SizedBox(height: 10),
              _ContinueButton(
                label: _adLoading ? 'YÜKLÜYOR...' : 'REKLAM İZLE',
                badge: 'ÜCRETSİZ',
                color: AppColors.amber,
                glowColor: AppColors.amber.withAlpha(100),
                outlined: true,
                loading: _adLoading,
                onTap: _adLoading ? null : _onAdTap,
              ),
            ],
          );
        }),
```

Not: Orijinal `const SizedBox(height: 10)` satırı (460) kaldırılır, Obx bloğunun içindeki Column'a taşınır. Böylece ad-free olunca gap da kaybolur.

- [ ] **Step 4: Commit**

```bash
git add lib/app/views/game_over/game_over_view.dart
git commit -m "feat: integrate rewarded ad into game over continue flow"
```

---

## Task 6: Game Over — Interstitial Ad

**Files:**
- Modify: `lib/app/views/game_over/game_over_view.dart:107-119`

- [ ] **Step 1: Navigasyon butonlarına interstitial logic ekle**

`_GameOverViewState.build()` içinde "YENİDEN OYNA" ve "ANA MENÜ" butonlarındaki `onTap` callback'lerini (satır 108-119) helper metod kullanacak şekilde güncelle.

`_GameOverViewState` sınıfına yeni metod ekle:

```dart
  void _navigateWithInterstitial(String route) {
    final adService = Get.find<AdService>();
    adService.incrementGameOver();
    if (adService.shouldShowInterstitial) {
      adService.showInterstitialAd().then((_) {
        Get.offAllNamed(route);
      });
    } else {
      Get.offAllNamed(route);
    }
  }
```

Not: `NeonButton.onTap` tipi `VoidCallback` (senkron) olduğu için metod `void` döner. Interstitial reklam varsa `.then()` ile navigasyonu callback'e alır, yoksa direkt navigasyon.

Butonları güncelle:

```dart
                      NeonButton(
                        label: 'YENİDEN OYNA',
                        onTap: () => _navigateWithInterstitial(AppRoutes.game),
                        icon: Icons.replay_rounded,
                      ),
                      const SizedBox(height: 12),
                      NeonButton(
                        label: 'ANA MENÜ',
                        onTap: () => _navigateWithInterstitial(AppRoutes.home),
                        outlined: true,
                        icon: Icons.home_outlined,
                      ),
```

- [ ] **Step 2: Commit**

```bash
git add lib/app/views/game_over/game_over_view.dart
git commit -m "feat: add interstitial ad on game over navigation (every 3rd)"
```

---

## Task 7: Build & Smoke Test

- [ ] **Step 1: Flutter analyze çalıştır**

Run: `cd /Users/aykut/StudioProjects/orbriot && flutter analyze`
Expected: Hata yok (warning kabul edilebilir).

- [ ] **Step 2: Debug build çalıştır**

Run: `cd /Users/aykut/StudioProjects/orbriot && flutter build apk --debug 2>&1 | tail -10`
Expected: `BUILD SUCCESSFUL`

- [ ] **Step 3: Varsa hataları düzelt ve commit**

Eğer analyze veya build hataları varsa düzelt.

```bash
git add -A
git commit -m "fix: resolve build/lint issues from admob integration"
```

---

## Task 8: TODO.md Güncelle

**Files:**
- Modify: `TODO.md:199-204`

- [ ] **Step 1: Tamamlanan maddeleri işaretle**

`TODO.md` dosyasındaki "Reklam Entegrasyonu" bölümünü (satır 199-204) güncelle:

```markdown
### Reklam Entegrasyonu (Google AdMob)
- [x] `google_mobile_ads` paketi entegrasyonu
- [x] **Rewarded Ad:** "10 gem kazan", "Continue" için
- [x] **Interstitial Ad:** Her 3 game over'dan sonra 1 kez
- [x] ~~**Banner Ad:** Home ekranı alt kısmı (küçük)~~ — kapsam dışı bırakıldı
- [x] Ad-free seçenek altyapısı (SharedPreferences flag)
```

- [ ] **Step 2: Commit**

```bash
git add TODO.md
git commit -m "docs: mark admob integration tasks as complete in TODO.md"
```
