# AdMob Reklam Entegrasyonu — Tasarım Dokümanı

> Sprint 4 — Monetizasyon

## Özet

Orbriot'a Google AdMob entegrasyonu. Rewarded ve Interstitial reklam tipleri. Banner yok. Merkezi `AdService` (GetxService) ile yönetim. Test ID'leriyle geliştirme, gerçek ID'ler store yayını sonrası.

## Kapsam

### Dahil
- `google_mobile_ads` paketi entegrasyonu
- Merkezi `AdService` (GetxService)
- Rewarded Ad: Earn tab (gem kazan) + Game Over continue
- Interstitial Ad: Her 3 game over'da 1, navigasyon sırasında
- Ad-free flag altyapısı (SharedPreferences, gerçek IAP sonra)
- Android ve iOS platform konfigürasyonu (test ID'ler)

### Hariç
- Banner reklam — orijinal planda (TODO.md) vardı ancak kullanıcı deneyimini bozması ve düşük gelir/değer oranı nedeniyle kapsam dışı bırakıldı
- Gerçek AdMob Application ID'leri (store sonrası)
- In-App Purchase (Sprint 5)
- GDPR/ATT consent dialog (Sprint 5) — Bu olmadan iOS'ta reklamlar sınırlı hedeflemeyle çalışır, bu bilinen ve kabul edilen bir durumdur

## Mimari

### AdService (GetxService)

Dosya: `lib/app/core/utils/ad_service.dart`

```
AdService extends GetxService
├── _rewardedAd: RewardedAd?
├── _interstitialAd: InterstitialAd?
├── _gameOverCount: int
├── isAdFree: RxBool (SharedPreferences'tan)
│
├── init() → Future<AdService>
│   └── SharedPreferences'tan isAdFree yükle + preload both ads (MobileAds.initialize main.dart'ta yapılır)
├── showRewardedAd() → Future<bool>
│   └── ad-free check → show → preload next → return success
├── showInterstitialAd() → Future<bool>
│   └── ad-free check → show → preload next → return success
├── incrementGameOver() → void
│   └── _gameOverCount++
├── shouldShowInterstitial() → bool
│   └── _gameOverCount % 3 == 0 && !isAdFree
├── setAdFree(bool) → Future<void>
│   └── SharedPreferences + isAdFree.value güncelle
├── _preloadRewarded() → void
├── _preloadInterstitial() → void
└── onClose() → dispose ads
```

### isAdFree Sahipliği

`AdService` kendi `isAdFree` RxBool'unu doğrudan SharedPreferences'tan yükler ve yönetir. `SettingsController`'a bağımlılık yoktur — `AdService` global service olarak binding'lerden bağımsız çalışır. `SettingsController` yalnızca UI'dan `AdService.setAdFree()` çağırır.

### Kayıt

`main.dart`'ta, mevcut service'lerden önce:
```dart
WidgetsFlutterBinding.ensureInitialized();
await MobileAds.instance.initialize();  // Tek initialization noktası
await Get.putAsync(() => AdService().init());  // init() sadece preload + isAdFree yükler
```

`main()` fonksiyonu `async` yapılır. Global GetxService olarak register edilir. Binding'lerden bağımsız, app ömür boyu yaşar.

## Entegrasyon Noktaları

### 1. Rewarded Ad — Earn Tab

**Dosya:** `lib/app/views/upgrade/widgets/earn_tab.dart`

Mevcut `_AdRewardCard` widget'ında placeholder logic var. Değişiklik:
- `AdService.showRewardedAd()` çağrılır
- Başarılıysa `UpgradeController.claimAdReward()` ile +10 gem
- Başarısızsa kullanıcıya snackbar: "Reklam yüklenemedi"
- Günlük 5 limit mevcut `UpgradeController` logic'inde zaten var
- `isAdFree` true ise kart gizlenir

### 2. Rewarded Ad — Game Over Continue

**Dosya:** `lib/app/views/game_over/game_over_view.dart`

Mevcut `_onAdTap()` metodu 3 sn delay ile simüle ediyor. Değişiklik:
- `AdService.showRewardedAd()` çağrılır
- Başarılıysa `_doResume()` tetiklenir
- Başarısızsa snackbar + buton tekrar aktif olur
- `isAdFree` true ise "Reklam İzle" butonu gizlenir

### 3. Interstitial Ad — Game Over Navigasyon

**Dosya:** `lib/app/views/game_over/game_over_view.dart`

"Ana Menü" ve "Tekrar Oyna" butonlarında:
1. `AdService.incrementGameOver()` çağrılır
2. `AdService.shouldShowInterstitial()` true ise:
   - `await AdService.showInterstitialAd()`
   - Reklam kapandıktan sonra navigasyon
3. False ise (veya ad-free) direkt navigasyon

### 4. Ad-Free Flag

`isAdFree` RxBool'u `AdService` tarafından sahiplenilir. SharedPreferences key: `'ad_free'`.

Kontrol noktaları:
- `AdService.showRewardedAd()` — return false
- `AdService.shouldShowInterstitial()` — return false
- Earn tab `_AdRewardCard` — `Obx` ile sarılır, `isAdFree` true ise widget gizlenir (`const` annotation kaldırılır)
- Game Over "Reklam İzle" butonu — gizlenir

Gerçek IAP toggle'ı Sprint 5'te eklenecek. Şimdilik sadece `AdService.setAdFree(bool)` API'si hazır.

## Platform Konfigürasyonu

### Android

**`pubspec.yaml`:**
```yaml
google_mobile_ads: ^5.3.0
```

**`android/app/src/main/AndroidManifest.xml`:**
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-3940256099942544~3347511713"/>
```

### iOS

**`ios/Runner/Info.plist`:**
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

### Test Ad Unit ID'leri

| Tip | Android | iOS |
|-----|---------|-----|
| Rewarded | `ca-app-pub-3940256099942544/5224354917` | `ca-app-pub-3940256099942544/1712485313` |
| Interstitial | `ca-app-pub-3940256099942544/1033173712` | `ca-app-pub-3940256099942544/4411468910` |

ID'ler `AdService` içinde platform-aware constant olarak tanımlanır (`Platform.isAndroid` kontrolü).

## Davranış Detayları

### Rewarded Ad Akışı
1. Kullanıcı butona basar → `_adLoading` guard aktif (çift tıklama önlenir)
2. `AdService.showRewardedAd()` çağrılır
3. `_rewardedAd` null ise → preload dener, 10 sn timeout ile bekler. Timeout aşılırsa `false` döner
4. `_rewardedAd` var ise → `show()` çağrılır, `onUserEarnedReward` callback'inde Completer tamamlanır
5. Reklam kapandıktan sonra → preload sonraki reklam, `true` dön
6. Earn tab: `true` ise `claimAdReward()` çağrılır (gem ekleme mevcut logic'te)
7. Game Over: `true` ise `_doResume()` çağrılır

### Interstitial Ad Akışı
1. Kullanıcı "Ana Menü" veya "Tekrar Oyna"ya basar
2. `incrementGameOver()` → `_gameOverCount++`
3. `shouldShowInterstitial()` true ise → `showInterstitialAd()` çağrılır
4. `showInterstitialAd()` bir Completer döner, `onAdDismissedFullScreenContent` callback'inde tamamlanır
5. Future tamamlandıktan sonra navigasyon (`Get.offAllNamed`) çağrılır — widget dispose sorunu olmaz çünkü navigasyon reklam kapandıktan sonra gerçekleşir
6. `_interstitialAd` null ise → direkt `true` dön, navigasyona devam

### Game Over Sayacı
- `_gameOverCount` session-based (app restart'ta sıfırlanır, persist etmez)
- Continue kullanılıp tekrar game over olunursa aynı oyun oturumu sayılır, `incrementGameOver()` sadece "Ana Menü" / "Tekrar Oyna" butonlarında çağrılır (oyun oturumu başına 1 kez)

### Çift Tıklama Koruması
- `showRewardedAd()` ve `showInterstitialAd()` içinde `_isShowingAd` boolean guard bulunur
- Zaten gösteriliyorsa `false` döner

## Hata Yönetimi

- Reklam yüklenemezse: sessizce log, kullanıcıya etki yok, bir sonraki tetiklemede tekrar dener
- Reklam gösterilemezse (loaded ama show fail): snackbar "Reklam yüklenemedi, tekrar dene", preload tekrar tetiklenir
- İnternet yoksa: reklam yüklenmez, tüm ad-dependent butonlar normal çalışır ama reklam gösterilmez (graceful degradation)
- `onAdFailedToLoad` callback'inde retry yok (spam önleme), sonraki kullanıcı aksiyonunda tekrar preload
- Timeout: `showRewardedAd()` ve `showInterstitialAd()` içinde 10 sn timeout, aşılırsa `false` döner

## Dosya Değişiklik Özeti

| Dosya | Değişiklik |
|-------|-----------|
| `pubspec.yaml` | `google_mobile_ads` eklenir |
| `android/app/src/main/AndroidManifest.xml` | AdMob meta-data |
| `ios/Runner/Info.plist` | GADApplicationIdentifier + SKAdNetwork |
| `lib/main.dart` | MobileAds init + AdService register |
| `lib/app/core/utils/ad_service.dart` | **Yeni dosya** |
| `lib/app/views/upgrade/widgets/earn_tab.dart` | Placeholder → gerçek rewarded ad |
| `lib/app/views/game_over/game_over_view.dart` | Placeholder → gerçek rewarded + interstitial |
| `lib/app/controllers/settings_controller.dart` | isAdFree flag artık AdService'te, bu dosyada değişiklik yok |
