# ORBRIOT — Yol Haritası & Yapılacaklar

> Benzer oyunlar analiz edilerek (Ballz, Ball Blast, Brick Ball Blast, Archero)
> oluşturulmuş stratejik geliştirme planı.

---

## Mevcut Durum (Tamamlanan)

- [x] Temel brick blast oyun mekaniği (drag & aim, top fiziği)
- [x] Tuğla tipleri: normal, bomb, stone, triangle, chain, shield, multiplier, laserH, laserV
- [x] Bonus top sistemi (+ / -)
- [x] Sahne ve seviye sistemi
- [x] Yükseltme sistemi (extra ball, speed, size, gem bonus)
- [x] Gem ekonomisi temeli
- [x] Parçacık efektleri (particle system)
- [x] Ses sistemi (SFX + BGM pool)
- [x] Ayarlar ekranı (sfx, müzik, titreşim, ses seviyeleri, sıfırlama)
- [x] Splash screen (animasyonlu)
- [x] SharedPreferences persistence
- [x] Haptic feedback (ayarlarla kontrol edilebilir)
- [x] App ikonu (flutter_launcher_icons ile Android + iOS)
- [x] **KLASİK oyun modu** — X tuğla kır → sahne tamamlandı (Stage N hedef: 25+N×10)
- [x] **SONSUZ oyun modu** — Hayatta kal, skor topla, sahne bitişi yok
- [x] **Daily Login Bonus** — 7 günlük seri, her gün artan gem ödülü, takvim UI

---

## SPRINT 1 — Temel Gameplay Kalitesi
> Öncelik: KRİTİK — Oyun sıkıcı hissettiriyor, bunu düzelt

### Tuğla Doluluğu & Dağılım
- [x] **Level generator Gauss dağılımı**: 1. ve 2. sahnelerde sadece 1'ler değil,
      ağırlıklı 1-2, ender 3-4 gelsin. Yüksek sahnelerde ağırlık kayar.
- [x] **Doluluk oranı artırımı**: Her satırda minimum %60-70 tuğla dolduruluğu.
      Şu an çok boş, oyun sıkıcı.
- [x] 1. seviye: `[1,1,2,1,2,1]` benzeri yoğun açılış
- [x] 2. seviye: 2 ve 3'ler araya girmeye başlar
- [x] 3+ seviye: 3-4'ler belirgin, ender 5-6'lar

### Görsel Tatmin
- [x] **Top izi (trail) efekti**: Top hareket ederken renkli parçacık izi bırakır.
      `GamePainter`'a eklenebilir, top rengine uygun gradient.
- [x] **Nişan çizgisi yansıma**: Nişan alırken top duvardan yansıyacak yön gösterilsin
      (en az 1 yansıma, Ballz tarzı dashed line).
- [x] **"YENİ REKOR!" animasyonu**: Yeni high score kırılınca ekranda parlayan yazı.
- [x] **Combo göstergesi**: Tek turda 10+ tuğla kırılırsa "COMBO x2!" ekranda belirir.
- [x] **Sahne geçiş animasyonu**: Yeni sahne başlarken tuğlalar yukarıdan süzülür.

---

## SPRINT 2 — Retention Mekanikleri
> Oyuncuyu her gün geri getiren sistemler

### Daily Mission (Günlük Görev)
- [x] **DailyMissionController** oluştur (SharedPreferences ile)
- [x] Her gün sıfırlanan 3 görev (random havuzdan seçilir)
- [x] Görev havuzu örnekleri:
  - [x] "X tuğla kır" (10 / 25 / 50)
  - [x] "X oyun oyna" (1 / 3 / 5)
  - [x] "X sahne geç" (3 / 5 / 10)
  - [x] "Bomb tuğla patlat" (1 / 3)
  - [x] "X puan kazan" (100 / 500 / 1000)
  - [x] "Shield tuğla kır" (1 / 2)
- [x] Görev tamamlanınca 5-20 gem ödülü
- [x] **DailyMissionView** — ana ekranda badge, tıklayınca açılan panel

### Daily Login Bonus
- [x] Takvim UI: 7 günlük seri — her gün artan gem ödülü (3/5/5/8/10/10/25)
- [x] 7. gün ödülü: özel skin veya büyük gem paketi
- [x] Giriş serisi kaybolunca başa döner

### Achievement (Başarım) Sistemi
- [x] **AchievementController** — progress sayaçları SharedPreferences'ta
- [x] **Başarım listesi:**

  **Başlangıç Tier:**
  - [x] "İlk Atış" — İlk topu fırlat → 5 gem
  - [x] "Kırıcı" — İlk sahneyi tamamla → 5 gem
  - [x] "Zenginleşiyorum" — İlk gem kazan → 5 gem
  - [x] "Alışveriş" — İlk yükseltmeyi satın al → 10 gem

  **Orta Tier:**
  - [x] "Sürekli Oyuncu" — 50 sahne tamamla → 20 gem
  - [x] "Kırılmaz" — 500 tuğla kır → 15 gem
  - [x] "Bomba Uzmanı" — 20 bomb tuğla patlat → 20 gem
  - [x] "Lazer Çılgını" — 10 laser tuğla kır → 15 gem
  - [x] "Gem Koleksiyoncusu" — 100 gem biriktir → 25 gem

  **Uzman Tier:**
  - [x] "Efsane" — 500 sahne tamamla → 100 gem
  - [x] "Top Çılgını" — 50 topla aynı anda oyna → 50 gem
  - [x] "Mükemmel" — Tek turda 30+ tuğla kır → 30 gem
  - [x] "Yıkıcı" — Toplamda 5000 tuğla kır → 50 gem

- [x] **AchievementView** — liste ekranı, tamamlanan/tamamlanmayan kartlar
- [x] Ana ekranda başarım badge bildirimi ("!" ikonu)
- [x] Başarım açılınca popup animasyonu

### Streak Sistemi
- [x] Üst üste kırılan tuğlalar: x2, x3, x5 çarpan göstergesi ekranda
- [x] Combo puanı ayrıca hesaplanır

---

## SPRINT 3 — Oyun Derinliği
> Oyunun tekrar oynanabilirlik değerini artıracak mekanikler

### Boss Tuğla Sistemi
- [x] Her 5. sahnede (5, 10, 15...) boss tuğla eklenir
- [x] Boss özellikler: çok yüksek HP (stage×2, min 10, max 50), 2×2 grid boyutu, merkez sütun
- [x] Boss ölünce ekstra 10 gem ödülü + dev altın parçacık patlaması + banner
- [x] BrickType: `boss` eklenir
- [x] Boss görsel tasarımı: 3 HP fazı (altın/kızıl/son nefes), HUD bracket, boss runu, CRT scan lines
- [x] LevelGenerator'a boss logic eklendi (stage % 5 == 0, çakışan tuğlalar temizlenir)
- [x] CollisionDetector'a bossRect çarpışma desteği eklendi (2×2 fizik alanı)
- [x] ParticleSystem'e `emitBossExplosion()` eklendi (3× büyük, altın + kırmızı + beyaz halka)

### Power-Up Sistemi — Hibrit "Pocket Power-Ups" Modeli
> Strateji: Ücretsiz grid drop (organik öğrenme) + Cep envanteri (stratejik kullanım) + Gem Shop (monetizasyon)

#### Grid Drop (Sahne İçi — Anlık Aktivasyon)
- [x] Stage 3'ten itibaren rastgele grid hücrelerinde power-up kutucukları belirir
- [x] Top çarpınca anında aktif olur (Nuke) veya bir sonraki tura sıraya alınır
- [x] Yüksek sahnelerde çıkma olasılığı artar (Stage 3: %8 → max %30)
- [x] **Görsel:** Yuvarlak zemin (tuğla dikdörtgeninden ayrışık), pulsing glow, geometrik ikon

#### Cep Envanteri (Pre-Turn — Stratejik Kullanım)
- [x] Oyuncu tura başlamadan önce 1 power-up aktif edebilir (nişan almadan önce)
- [x] Her türden max 99 şarj saklanabilir (SharedPreferences)
- [x] **Şarj kaynakları:** Günlük 1 bedava (random tip, günde 1 kez), gem shop
- [x] **PowerUpInventoryController** — şarj sayaçları, `useCharge`, `addCharges`, `tryClaimDailyCharge`
- [x] **PowerUpBarWidget** — game ekranının altında 5 slotlu Cyberpunk HUD bar (56px slot, neon glow, şarj badge)
- [x] GameBinding'e `PowerUpInventoryController` kaydı eklendi
- [x] Günlük bedava şarj: oyun başlarken otomatik kontrol → banner bildirimi
- [x] UpgradeView'a Power-Up şarj paketi bölümü eklendi (her tip için 5'li paket satın alma)

#### Power-Up Tipleri & Görsel Dil (Retro-Futurism × OLED Dark)
- [x] 🔥 **Fireball** — 1 tur, toplar 3× hasar | Renk: `#EF4444` → `#FF6B6B` (ateş) | İkon: üçgen alev + merkez orb
- [x] 💥 **Nuke** — Anında, tüm tuğlaların HP'sini -1 | Renk: `#8B5CF6` → `#A78BFA` (plazma) | İkon: dışa yayılan halkalar
- [x] ✨ **Multi-Ball** — 1 tur, top sayısı 2× | Renk: `#06B6D4` → `#67E8F9` (siyan) | İkon: 3 nokta üçgen
- [x] ⚡ **Speed Boost** — 1 tur, top hızı 2× | Renk: `#FBBF24` → `#FDE68A` (şimşek) | İkon: çift V-şekli ok
- [x] 🛡️ **Shield Row** — 1 tur, tuğlalar aşağı inmiyor | Renk: `#3B82F6` → `#93C5FD` (buz mavisi) | İkon: kalkan + yatay çizgi

#### Gem Shop Entegrasyonu
- [x] Her power-up için 5'li şarj paketi: Fireball 25💎, Nuke 30💎, Multi-Ball 20💎, Speed 15💎, Shield 20💎
- [x] "Mega Pack" — Her türden 3'er şarj: 80💎
- [x] Game Over ekranında "Son Şans: 10💎 → 1 Nuke kullan" seçeneği

#### Teknik
- [x] `PowerUpType` enum + `PowerUpCell` model (`lib/app/models/power_up_cell.dart`)
- [x] `PowerUpController` (GetX) — aktivasyon, tur yönetimi, HUD state (`lib/app/controllers/power_up_controller.dart`)
- [x] `GameState`'e `powerUpCells` alanı eklendi
- [x] `BallPhysics`'e power-up çarpışma tespiti + `damageMultiplier` eklendi
- [x] `GameController`'a toplama, nuke, queue, apply, consume akışı eklendi
- [x] `LevelGenerator.generatePowerUpCell()` — rastgele spawn, ağırlıklı tip seçimi
- [x] `GameBinding`'e `PowerUpController` kaydı eklendi
- [x] `game_painter.dart`'a power-up hücre çizimi (`_drawPowerUpCell`) — 5 tip ikonlu
- [x] **HUD widget:** `_ActivePowerUpHud` pill — sol üst köşe, aktif efekt + kalan tur sayısı
- [x] **Banner widget:** `_PowerUpBanner` — aktivasyon anında ekran ortasında animasyonlu bildirim
- [x] Günlük bedava şarj sistemi — `PowerUpInventoryController.tryClaimDailyCharge()` ile uygulandı

### Gem Shop UI
- [x] **GemShopView** — 3 sekmeli shop ekranı (KAZAN / POWER-UP / UPGRADES)
- [x] "Reklam izle → 10 gem kazan" butonu (rewarded ad placeholder, günde 5 kez)
- [x] Mevcut gem bakiyesi göstergesi (üst bar GemChip)
- [x] Ana ekranda gem göstergesine tıklayınca açılır
- [x] Günlük bedava şarj kartı (talep et / countdown)
- [x] **Mega Pack** (80💎 → her türe +3 şarj, animated gradient border)

### Continue Mekanizması
- [X] Game Over ekranında "DEVAM ET" butonu
- [X] Maliyet: 10 gem VEYA reklam izle
- [X] Devam edilince tuğlalar 2 satır yukarı çıkar, oyun devam eder
- [X] Tek oyun başına maksimum 2 continue

### ~~Roguelite Yetenek Seçimi~~ — ATLANACAK
> Karar: Power-up sistemi aynı ihtiyacı karşılıyor. Geçici buffs oyun akışını bölüyor,
> brick blast tarzına uymadığına karar verildi. Sprint 4'e geçildi.

---

## SPRINT 4 — Kozmetik & Monetizasyon

### Skin Sistemi (Top Görünümleri)
- [x] **SkinController** — aktif skin SharedPreferences'ta
- [x] **Skin tipleri:**
  - [x] Default (beyaz-mor) — ücretsiz
  - [x] Neon Green — 30 gem
  - [x] Lava (turuncu ateş efekti) — 50 gem
  - [x] Ice Blue (mavi buz) — 50 gem
  - [x] Galaxy (mor-pembe) — 80 gem
  - [x] Gold (altın) — 150 gem
  - [ ] Ghost (yarı saydam) — 7 günlük login ödülü
- [x] **SkinShopView** — GemShop 4. sekme (SKİNLER), kilitli/açık gösterimi
- [x] Top görünümü GamePainter'da skin'e göre değişir (gradient + glow rengi)
- [x] Trail efekti de skin rengine uyarla (comet gradient trail)

### Reklam Entegrasyonu (Google AdMob)
- [x] `google_mobile_ads` paketi entegrasyonu
- [x] **Rewarded Ad:** "10 gem kazan", "Continue" için
- [x] **Interstitial Ad:** Her 3 game over'dan sonra 1 kez
- [x] ~~**Banner Ad:** Home ekranı alt kısmı (küçük)~~ — kapsam dışı bırakıldı
- [x] Ad-free seçenek altyapısı (SharedPreferences flag)

### Prestige Sistemi
- [x] Tüm yükseltmeler max olunca "Prestige" butonu görünür
- [x] Prestige: tüm yükseltmeler sıfırlanır, gem sıfırlanır
- [x] Karşılığı: kalıcı "Prestige Çarpanı" (+%10 gem kazanımı, stacks)
- [x] Prestige rozeti (ekranda küçük yıldız göstergesi, home + game HUD)
- [x] Maksimum 5 prestige

---

## SPRINT 5 — Polishing & Yayın Hazırlığı

### Online Özellikler
- [X] **Firebase entegrasyonu** (Authentication, Firestore, Analytics)
- [x] **Online leaderboard** — global top 100 skor tablosu
- [ ] **Haftalık turnuva** — Her hafta sıfırlanan skor yarışması
- [x] Kullanıcı profili (opsiyonel kullanıcı adı)
- [ ] Arkadaş skoru karşılaştırma

### Analitik & A/B Test
- [x] Firebase Analytics event tracking:
  - [x] Game start / game over (`game_controller.dart`)
  - [ ] Level completed
  - [x] Upgrade purchased (`upgrade_controller.dart`)
  - [x] Ad watched (`ad_service.dart` — rewarded + interstitial)
  - [ ] Session duration
- [ ] Crash reporting (Firebase Crashlytics)
- [ ] A/B test altyapısı (tuğla doluluk oranları, gem fiyatları)

### Monetizasyon (IAP)
- [x] `in_app_purchase: ^3.1.12` paketi eklendi
- [x] `IAPService` — tam satın alma akışı, product ID'ler (`lib/app/core/utils/iap_service.dart`)
- [x] `SessionService` — session sayacı, first-purchase offer flag
- [x] `FirstPurchaseModal` — session 3-5'te game over'da %50 indirimli VALUE PACK teklifi
- [x] GemShop'a "PAKETLER" 5. sekmesi eklendi (starter/value/mega + ad-free)
- [ ] **⚠️ App Store Connect'te ürün ID'leri oluştur:**
  - `com.orbriot.gems.starter` ($0.99 Consumable → 100 gem)
  - `com.orbriot.gems.value` ($4.99 Consumable → 600 gem)
  - `com.orbriot.gems.mega` ($9.99 Consumable → 1500 gem)
  - `com.orbriot.adfree` ($2.99 Non-Consumable)
- [ ] **⚠️ Google Play Console'da aynı ID'leri oluştur**
- [ ] **⚠️ Gerçek AdMob ID'leri** — `ad_service.dart` + `Info.plist` + `AndroidManifest.xml`

### App Store Hazırlığı
- [ ] App Store metadata (açıklama, anahtar kelimeler)
- [ ] Play Store listing
- [ ] Screenshot seti (6.5" iPhone + tablet)
- [ ] Preview video (15 saniyelik gameplay)
- [ ] Privacy policy URL
- [x] GDPR/CCPA uyum — UMP consent flow eklendi (`main.dart`)
- [x] iOS ATT consent dialog (`app_tracking_transparency` paketi)
- [x] SKAdNetwork tam liste (1 → 90+ giriş, `Info.plist`)

### Son Polishing
- [ ] Tüm ses efektleri tamamlandı mı? Kontrol et
- [ ] Tüm tuğla tipleri için ses efekti var mı?
- [ ] Düşük performanslı cihazlarda particle system'i azalt
- [ ] iPad uyumluluğu (responsive layout)
- [ ] Accessibility (font boyutu, kontrast)

---

## Teknik Borç & Code Quality

- [ ] `LevelGenerator` birim testleri
- [ ] `CollisionDetector` birim testleri
- [ ] `BallPhysics` birim testleri
- [ ] Widget testleri (HomeView, UpgradeView)
- [ ] `SoundService` hata yakalama geliştirilmesi (dosya yokken)
- [ ] `CustomPainter.shouldRepaint` optimizasyonu (gereksiz repaint azaltımı)
- [ ] `GameController` profiling — frame drop var mı?
- [ ] Memory leak kontrolü (AudioPlayer pool)
- [ ] Null safety tam uyum kontrolü

---

## Fikir Havuzu (Değerlendirilecek)

> Kesin yapmak zorunda değiliz ama ilginç olabilir

- [ ] **Çevrimdışı mod** — İnternet yoksa her şey çalışmaya devam etsin
- [x] **Farklı oyun modları**: KLASİK (seviye hedefli) + SONSUZ (endless) ✅ — "Time Attack" henüz yapılmadı
- [ ] **Mini boss: Guardian** — Tuğlaların önünde gezinen bir koruyucu top
- [ ] **Dinamik arka planlar** — Her 20 sahnede tema değişir (uzay, okyanus, orman)
- [ ] **Kooperatif mod** — 2 oyuncu aynı cihazda (bölünmüş ekran)
- [ ] **Haftalık özel sahne** — Tüm oyuncular için aynı seed, kim daha iyi?
- [ ] **Tuğla editörü** — Kullanıcı kendi sahnelerini oluşturabilir (çok karmaşık)
- [ ] **Watchfaces** — Apple Watch / WearOS entegrasyonu (skor gösterimi)
- [ ] **Widget** — iOS/Android ana ekran widget'ı (günlük skor gösterimi)

---

## Öncelik Özeti

| Sprint | Odak | Tahmini Süre |
|--------|------|--------------|
| Sprint 1 | Gameplay kalitesi (doluluk, trail, nişan) | 1-2 hafta |
| Sprint 2 | Retention (daily mission, achievement, login) | 2-3 hafta |
| Sprint 3 | Derinlik (boss, power-up, gem shop, continue) | 3-4 hafta |
| Sprint 4 | Kozmetik & monetizasyon (skin, reklam, prestige) | 4-6 hafta |
| Sprint 5 | Online & yayın hazırlığı | 6-8 hafta |

---

*Son güncelleme: 2026-03-24*
*Analiz: Sequential Thinking + Ballz / Ball Blast / Brick Ball Blast / Archero incelemesi*

---

## App Store / Google Play Screenshot Stratejisi

> Araştırma: ASO best practices (SplitMetrics, StoreMaven, Sensor Tower) — 2025

### Boyutlar

| Platform | Boyut |
|---|---|
| iOS 6.7" (iPhone 14/15 Pro Max) — zorunlu | 1290 × 2796 px |
| iOS 5.5" (iPhone 8 Plus) — zorunlu | 1242 × 2208 px |
| Android telefon | 1080 × 1920 px |
| Android Feature Graphic (ayrı, zorunlu) | 1024 × 500 px |

Format: PNG, alpha kanal yok. Her platform için 8 screenshot kullan (max slot).

### 8 Screenshot Sırası

| # | İçerik | Neden |
|---|---|---|
| 1 | En yoğun oyun anı — toplar uçuyor, neon trail, `#0F0F23` arka plan | Thumbnail'da bile durdurucu; rakipler açık renkli, ORBRIOT koyu = farklı |
| 2 | Boss tuğla patlarken (stage 5/10) | Derinlik var, sadece "top sek" değil |
| 3 | Power-up aktivasyonu (Fireball veya Multi-Ball) | Çeşitlilik |
| 4 | Upgrade ekranı + Prestige badge | Uzun dönem loop — rakiplerde yok |
| 5 | Büyük combo sayısı (x12, x15) | Beton sayı = güvenilirlik |
| 6 | Gem kazanma / ödül animasyonu | Dopamin tetikleyici |
| 7 | Skin seçim ekranı | Production value |
| 8 | Logo + tagline, koyu arka plan, neon glow | Marka kapanışı |

### Metin Overlay Kuralları

- Maksimum 1 callout per screenshot
- Üst %20 veya alt %20'ye koy, orta %60 gameplay
- Orbitron font + neon glow (`#7C3AED` veya `#06B6D4`)
- Kısa ve somut: `"5 PRESTİJ SEVİYESİ"`, `"SONSUZ YÜKSELTME"`, `"x15 COMBO"`
- Genel laflar yok: "Eğlenceli", "Bağımlılık yapan"

### ORBRIOT'un ASO Avantajı

Rakipler (Ballz, Brick Breaker Star) açık renkli / candy-look.
`#0F0F23` + mor + cyan paleti store listesinde tamamen farklı durur.
İlk screenshot'ta bu farkı öne çıkar — yumuşatma.

### Video Preview

- 15-30 saniye, sessiz izlenebilir (iOS autoplay sessiz başlar)
- İlk 3 saniyede toplar hareket etmeli, tuğlalar patlıyor olmalı
- Ortalama %25-35 daha fazla indirme sağlar

### Yapılacaklar

- [ ] iOS 6.7" (1290×2796) ve 5.5" (1242×2208) screenshot seti — 8 adet
- [ ] Android 1080×1920 screenshot seti — 8 adet
- [ ] Android Feature Graphic 1024×500 (logo + en iyi oyun anı)
- [ ] Callout metinleri Orbitron font + neon glow ile ekle (Canva veya Figma)
- [ ] 15-30 sn gameplay video preview hazırla
- [ ] App Store Product Page Optimization (A/B test) — yayından sonra

*Son güncelleme: 2026-06-06*
