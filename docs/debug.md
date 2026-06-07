# ORBRIOT — Pre-Launch Debug & Strategy Report
> Oluşturulma: 2026-06-02
> Bu dosyayı yeniden oluşturmak için aynı analizleri tekrar çalıştırmaya gerek yok.

---

## 1. KOD KALİTESİ — `flutter analyze` Sonuçları

Çalıştırılan komut: `flutter analyze lib`
Sonuç: **13 sorun — crash yok, tümü info/warning**

| Seviye | Dosya | Satır | Sorun |
|--------|-------|-------|-------|
| ⚠️ warning | `lib/app/views/home/widgets/daily_login_panel.dart` | 218 | `isFuture` değişkeni tanımlı ama hiç kullanılmıyor (`unused_local_variable`) |
| ⚠️ warning | `lib/app/views/achievements/achievement_view.dart` | 220 | `key` parametresi hiç verilmiyor (`unused_element_parameter`) |
| ℹ️ info | `lib/app/controllers/game_controller.dart` | 379 | `if` tek satırı küme parantezi yok (`curly_braces_in_flow_control_structures`) |
| ℹ️ info | `lib/app/controllers/game_controller.dart` | 768 | `null check` yerine `?.` kullan (`use_null_aware_elements`) |
| ℹ️ info | `lib/app/views/game/widgets/game_canvas.dart` | 232, 335, 562, 669 | Birden fazla alt çizgi (`unnecessary_underscores`) |
| ℹ️ info | `lib/app/views/achievements/achievement_view.dart` | 188, 333 | Birden fazla alt çizgi |
| ℹ️ info | `lib/app/views/settings/settings_view.dart` | 45 | Birden fazla alt çizgi |
| ℹ️ info | `lib/app/core/translations/en_US.dart` | 1 | Dosya adı snake_case değil |
| ℹ️ info | `lib/app/core/translations/tr_TR.dart` | 1 | Dosya adı snake_case değil |

**Değerlendirme:** Dart kodu derlenebilir, type-safe, null-safety uyumlu. Kritik bug yok.

---

## 2. PRE-LAUNCH KRİTİK SORUNLAR

### 🔴 BLOCKER — Store'a göndermeden önce mutlaka düzeltilmeli

#### 2.1 Test AdMob ID'leri kodda
- `lib/app/core/utils/ad_service.dart` → `_rewardedAdUnitId`, `_interstitialAdUnitId`
- `ios/Runner/Info.plist` → `GADApplicationIdentifier: ca-app-pub-3940256099942544~1458002511`
- `android/app/src/main/AndroidManifest.xml` → `ca-app-pub-3940256099942544~3347511713`
- **Aksiyon:** AdMob hesabı oluştur, gerçek uygulama ID + ad unit ID'lerini al ve değiştir.

#### 2.2 ATT Consent dialog yok (iOS 14.5+)
- `NSUserTrackingUsageDescription` Info.plist'te var ✓
- Ama `AppTrackingTransparency.requestTrackingAuthorization()` kodda **çağrılmıyor**
- Sonuç: iOS'ta limited targeting → eCPM %50–70 düşer → rewarded ad geliri massively etkilenir
- **Aksiyon:** `app_tracking_transparency` paketi ekle, `MobileAds.instance.initialize()` öncesinde çağır.
- **Sıra:** ATT dialog → UMP consent → MobileAds.initialize()

#### 2.3 SKAdNetworkItems eksik
- `ios/Runner/Info.plist`'te sadece 1 giriş: `cstr6suwn9.skadnetwork` (Google)
- AdMob v8 için Google'ın resmi tam listesi 100+ SKAdNetwork ID içerir
- **Aksiyon:** https://developers.google.com/admob/ios/quick-start adresinden güncel tam listeyi al ve Info.plist'e ekle.

#### 2.4 GDPR/UMP Consent yok
- AB kullanıcıları için Google UMP (User Messaging Platform) SDK zorunlu
- Spec'te "Sprint 5'e bırakıldı" yazıyor ama App Store review'da reject sebebi olabilir
- **Aksiyon:** `google_mobile_ads` zaten UMP içeriyor. `ConsentInformation.instance.requestConsentInfoUpdate()` flow ekle.

#### 2.5 Ghost Skin implement edilmemiş
- TODO.md: "Ghost (yarı saydam) — 7 günlük login ödülü" → `[ ]` (yapılmadı)
- Eğer kullanıcı 7. günü claim ederse skinController ne yapıyor? Test edilmedi.
- **Aksiyon:** Ghost skin'i implement et VEYA Day 7 ödülünü geçici olarak 50 gem'e çevir.

### 🟡 ÖNEMLİ — Gelir kaybı

#### 2.6 Gerçek IAP yok
- Tüm monetizasyon: rewarded ad + in-game gem harcama
- **Gerçek parayla satın alma (IAP) hiç yok**
- Hybrid-casual modelde gelirin %30–40'ı IAP'tan gelmeli — bu şu an sıfır
- Ad-free flag (`SharedPreferences`) var ama bunu satın almanın yolu yok
- **Aksiyon:** Sprint 5'e `in_app_purchase` paketi + IAP paketleri ekle (bkz. Bölüm 5)

#### 2.7 Analytics çağrıları eksik
- `lib/app/core/utils/analytics_service.dart` içinde tüm eventler tanımlı ✓
- Ama `game_controller.dart`, `upgrade_controller.dart` vb. bu metodları **çağırmıyor**
- `main.dart`'ta sadece `analytics.observer` var (route tracking)
- **Sonuç:** Firebase konsolunda veri göremiyorsun, A/B test veya optimizasyon imkânsız
- **Aksiyon:** En azından `logGameStart`, `logGameOver`, `logUpgrade`, `logAdWatched` çağrılarını ekle

---

## 3. PİYASA ANALİZİ — Rakip Oyunlar (Araştırma: 2024–2025)

### Başlıca Oyunlar

| Oyun | İndirme | Model | ARPU (lifetime) |
|------|---------|-------|-----------------|
| Ballz (Ketchapp) | 100M+ | Sadece reklam | $0.03–0.10 |
| Ball Blast (Voodoo) | 100M+ | Reklam + ad-free IAP | $0.05–0.15 |
| Brick Breaker Star | 50M+ | Hybrid IAP + rewarded | $0.40–0.80 |
| Modern hybrid-casual | 10M+ | IAP + events + pass | $0.50–1.50 |

### ARPU & Dönüşüm Benchmarkları (2024)
- IAP dönüşüm: %2–5 (casual genre)
- Rewarded ad opt-in: %40–65 (continue/power-up teklifinde)
- ARPU (30 günlük aktif): $0.50–1.50 (iyi tasarlanmış hybrid)
- Rewarded video eCPM (US): $8–18
- Interstitial eCPM (US): $3–8

### Retention Sıralaması (Etkiye Göre)
1. Daily missions — en yüksek etki, günlük alışkanlık döngüsü ✅ Orbriot'ta var
2. Login streak bonus — D1-D7 seri ✅ Orbriot'ta var
3. Upgrade/prestige progression ✅ Orbriot'ta var
4. Limited-time events/seasons ❌ Yok
5. Leaderboards ✅ Kısmen var (Firebase)
6. Achievements ✅ Orbriot'ta var

### Reklam Yerleşimi Best Practice
- ✅ Rewarded: continue + gem kazan → her zaman güvenli (player-initiated)
- ✅ Interstitial: her 3–4 game over'da 1 → doğru kadans (Orbriot bunu doğru yapıyor)
- ❌ Interstitial uygulama açılışında → D1 retention %15–20 düşer (Orbriot'ta yok, iyi)
- ❌ Interstitial continue teklifinden önce → (Orbriot'ta yok, iyi)

---

## 4. MEVCUT PLAN DEĞERLENDİRMESİ

### Doğru Kararlar ✅
- Rewarded + Interstitial, banner yok → best practice
- Her 3 game over'da 1 interstitial → doğru kadans
- Continue'dan önce interstitial göstermeme → doğru sıra
- Ad-free flag altyapısı hazır (ödeme mekanizması eksik)
- Tek soft currency (gem) → kafa karıştırmıyor
- Prestige + daily mission + achievement + login streak → güçlü retention altyapısı

### Eksik / Yanlış ❌
- IAP yok (en büyük gelir boşluğu)
- ATT consent yok (iOS gelirini massively etkiliyor)
- First-purchase offer yok (en yüksek ROI özellik)
- Battle pass / season yok (2024 trendi, D30 retention +%10-15)
- Analytics çağrıları eksik (veri görünürlüğü sıfır)
- GDPR/UMP yok (legal risk)

---

## 5. STRATEJİK ÖNERİLER & AKSİYON PLANI

### A) Acil — Store Öncesi (1–2 hafta)

| # | Görev | Öncelik |
|---|-------|---------|
| A1 | ATT consent dialog (`app_tracking_transparency` paketi) | 🔴 Kritik |
| A2 | GDPR/UMP consent flow | 🔴 Kritik |
| A3 | Google'ın tam SKAdNetwork listesi Info.plist'e | 🔴 Kritik |
| A4 | Ghost skin implement et veya Day 7 → 50 gem yap | 🟡 Önemli |
| A5 | Analytics çağrıları: `logGameStart`, `logGameOver`, `logUpgrade`, `logAdWatched` | 🟡 Önemli |
| A6 | Gerçek AdMob ID'leri al ve yerleştir | 🔴 Kritik |
| A7 | "Son Şans: 10💎 → 1 Nuke" Game Over'da implement et (TODO'da `[ ]`) | 🟡 Önemli |
| A8 | Lint warning fix: `isFuture`, `key` parametresi | 🟢 Minor |

### B) Kısa Vade — Gelir İçin Kritik (1 ay)

| # | Görev | Beklenen Etki |
|---|-------|---------------|
| B1 | `in_app_purchase` paketi + 3 gem paketi ($0.99 / $4.99 / $9.99) | %30-40 gelir artışı |
| B2 | Ad-free permanent purchase ($2.99) — flag zaten hazır | Engaged payer segment |
| B3 | First-purchase offer: session 3–5'te game over anında tetikle, %50 indirim, 24h sayaç | 3–6× dönüşüm artışı |

#### IAP Paket Önerisi
```
Starter Pack:  $0.99  → 100 gem
Value Pack:    $4.99  → 600 gem (en iyi değer)
Mega Pack:     $9.99  → 1500 gem + exclusive skin
Ad-Free:       $2.99  → Kalıcı interstitial kaldır (rewarded opsiyonel kalsın)
```

### C) Orta Vade — LTV Artırma (2–3 ay)

| # | Görev | Beklenen Etki |
|---|-------|---------------|
| C1 | Season/Battle Pass ($4.99/ay): 7 günlük görev + özel skin + gem bonus | D30 retention +%10-15 |
| C2 | Haftalık turnuva (Firebase altyapısı hazır, weekly reset ekle) | Rekabetçi engagement |
| C3 | Sezonsal event: tema değişikliği + event-exclusive skin (FOMO → satın alma) | IAP spike |
| C4 | "Top X% oyuncu!" bildirimi (fake social proof değil, gerçek percentile) | Engagement |

---

## 6. TEKNIK BORÇ ÖNCELİK LİSTESİ

Store sonrası, sırayla:
1. `LevelGenerator` birim testleri (kritis game loop)
2. `CollisionDetector` birim testleri
3. `CustomPainter.shouldRepaint` optimizasyonu (gereksiz repaint)
4. `GameController` profiling — frame drop kontrolü
5. Memory leak kontrolü (AudioPlayer pool)
6. iPad responsive layout

---

## 7. MEVCUT DURUM ÖZETİ (2026-06-02)

- Sprint 1–4: Tamamlandı ✅
- Sprint 5: Kısmen başlandı
  - Firebase entegrasyonu ✅
  - Leaderboard ✅
  - Analytics service tanımlı ama çağrılmıyor ⚠️
  - Haftalık turnuva ❌
  - IAP ❌
  - ATT/GDPR ❌
  - App Store metadata ❌
- `google_mobile_ads` v8.0.0 (SPM) güncellendi ✅ (2026-06-02)
- CocoaPods kaldırıldı, SPM'e geçildi ✅ (2026-06-02)

---

*Sonraki adım için önerilen sıra: A1 (ATT) → A2 (GDPR) → A3 (SKAdNetwork) → A6 (gerçek AdMob ID) → B1 (IAP)*
