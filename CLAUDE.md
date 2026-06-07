# ORBRIOT — Proje Memory

## Proje Özeti
Flutter ile yazılmış retro-futuristik cyberpunk temalı brick blast oyunu.
Dart SDK ^3.11.1, Flutter stable.

## Tech Stack
- **State management:** GetX (`get: ^4.6.6`) — Obx, GetxController, Get.find
- **Persistence:** SharedPreferences (`^2.2.2`)
- **Ses:** audioplayers (`^6.1.0`) — SoundService pool sistemi
- **Font:** Google Fonts (`^6.2.1`) — Orbitron (UI başlıklar), JetBrains Mono (sayılar)
- **Platform:** Android + iOS

## Tema & Görsel Dil
- **Arkaplan:** `#0F0F23` (koyu lacivert)
- **Ana renk (mor):** `#7C3AED`
- **Prestige / altın:** `#FBBF24`
- **Gem / cyan:** `#06B6D4`
- **Başarı (yeşil):** `#22C55E`
- **Tehlike (kırmızı):** `#EF4444`
- **Stil:** Retro-futuristik cyberpunk, neon glow, CRT efektleri
- **Font kuralı:** Başlık/buton → Orbitron, sayısal HUD → JetBrains Mono

## Mimari
```
lib/app/
├── bindings/         # GetX binding (home_binding, game_binding)
├── controllers/      # GetX controller'lar
├── core/utils/       # SoundService, vb.
├── models/           # Veri modelleri
├── theme/            # AppColors, AppTextStyles, AppTheme
└── views/            # Ekranlar ve widget'lar
    ├── achievements/
    ├── game/
    ├── game_over/
    ├── home/
    ├── settings/
    ├── splash/
    └── upgrade/
```

## Controller'lar
| Controller | Sorumluluk |
|---|---|
| `GameController` | Oyun döngüsü, top fiziği, skor |
| `UpgradeController` | Gem bakiyesi, upgrade seviyeleri, prestige level/multiplier |
| `PrestigeController` | canPrestige getter, executePrestige() |
| `SkinController` | Aktif top skin |
| `PowerUpController` | Oyun içi power-up aktivasyonu |
| `PowerUpInventoryController` | Şarj sayaçları, günlük bedava şarj |
| `AchievementController` | Başarım progress takibi |
| `DailyMissionController` | Günlük görevler |
| `DailyLoginController` | 7 günlük giriş serisi |
| `SettingsController` | SFX/BGM/haptic ayarları |
| `HomeController` | Ana ekran state |

**Binding'ler:**
- `HomeBinding` — home, upgrade, skin, prestige, achievement, daily mission/login, power-up inventory controller'larını register eder
- `GameBinding` — game, power-up, power-up inventory controller'larını register eder

## Sprint Durumu

### Tamamlanan
- Sprint 1: Gameplay kalitesi (Gauss dağılım, trail, nişan yansıma, combo, sahne animasyonu)
- Sprint 2: Retention (daily mission, achievement, login bonus, streak)
- Sprint 3: Derinlik (boss tuğla, power-up sistemi, gem shop, continue mekanizması)
- Sprint 4 — kısmen tamamlandı:
  - [x] Skin sistemi (6 skin, SkinShopView)
  - [x] **Prestige sistemi** (PrestigeController, PrestigeBadge, PrestigeButton, PrestigeModal + kutlama animasyonu)

### Devam Eden / Sıradaki
- Sprint 4: Reklam entegrasyonu (Google AdMob)
  - `google_mobile_ads` paketi
  - Rewarded Ad (gem kazan, continue)
  - Interstitial Ad (her 3 game over'da 1)
  - Banner Ad (home alt)
  - Ad-free flag altyapısı
- Sprint 5: Online özellikler, analitik, push notification, store hazırlığı

## Önemli Teknik Kararlar
- **Prestige crash-safety:** `incrementPrestigeLevel()` → `resetForPrestige()` sırası (önce level artır, sonra sıfırla)
- **Dialog sonrası overlay:** Dialog kapandıktan sonra yeni dialog açmak için `Get.overlayContext!` kullan
- **Gem çarpanı:** `totalGemMultiplier = gemMultiplier * prestigeGemMultiplier` (upgrade × prestige stacks)
- **Prestige max:** 5 seviye, her biri +%10 kalıcı gem çarpanı
- **GetxController cache:** `Get.find<X>()` çağrısını `initState`'te bir değişkene ata, Obx içinde tekrar çağırma

## Kodlama Kuralları
- Türkçe yorum ve kullanıcıya dönük metin
- `withAlpha()` kullan, `withOpacity()` kullanma (lint uyarısı)
- Widget'ları küçük, tek sorumluluklu tut
- Ses çağrıları: `Get.isRegistered<SoundService>()` kontrolü yap, sonra `Get.find`
- SharedPreferences key'leri controller içinde `static const` olarak tanımla

## Aktif Görev — AdMob Reklam Entegrasyonu
- **Durum:** Plan hazır, uygulamaya geçilmedi
- **Spec:** `docs/superpowers/specs/2026-03-24-admob-integration-design.md`
- **Plan:** `docs/superpowers/plans/2026-03-24-admob-integration.md`
- **Kapsam:** Rewarded Ad (earn tab + continue), Interstitial Ad (her 3 game over'da 1), ad-free flag altyapısı. Banner yok.
- **Sonraki adım:** Plan'daki 8 task'ı sırayla uygula (superpowers:subagent-driven-development veya superpowers:executing-plans ile)
