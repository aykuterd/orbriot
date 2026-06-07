# GemShop UI — Tasarım Spesifikasyonu

**Tarih:** 2026-03-22
**Sprint:** Sprint 3 — Oyun Derinliği
**Kapsam:** Mevcut `upgrade_view.dart` ekranının 3 sekmeli `GemShopView`'e dönüştürülmesi

---

## 1. Amaç

Mevcut tek-sayfalı yükseltme ekranını organize, ölçeklenebilir ve kullanıcı dostu bir shop deneyimine dönüştürmek. Sprint 3'te eksik kalan Mega Pack ve gem kazanma özelliklerini tamamlamak, Sprint 4 skin sistemi için altyapı hazırlamak.

---

## 2. Navigasyon Değişikliği

```
HomeView
  └─ gem göstergesi (GestureDetector eklenir) ──→ GemShopView  /upgrade rotası
  └─ YÜKSELTMELER butonu ──────────────────────→ GemShopView  (değişmez)
```

- Route: `/upgrade` korunur (kırılganlık yok)
- `upgrade_view.dart` → `gem_shop_view.dart` olarak yeniden adlandırılır
- Class adı: `UpgradeView` → `GemShopView`
- `home_view.dart`'ta gem satırı `GestureDetector` ile sarılır → `Get.toNamed(AppRoutes.upgrade)`
  - Not: `home_view.dart`'ta gem bakiyesi `_ScoreCard` widget'ının içinde inline `Row` olarak bulunur; bu satır `GestureDetector` ile sarılacak, ayrı bir class çıkarılmayacak.

---

## 3. Ekran Yapısı

### 3.1 Üst Bar

```
╔══════════════════════════════════════╗
║  ◀  GEM SHOP              💎 142    ║
║  ─────────────────────────────────  ║
║  [ KAZAN ]  [ POWER-UP ]  [ UPGRADES]║
╚══════════════════════════════════════╝
```

- Başlık: `GEM SHOP` (Orbitron, 18px, weight 700)
- Gem chip: sağ üst, `Color(0xFF06B6D4)` cyan (sabit hex — bkz. Bölüm 8)
- TabBar: **manuel `TabController`** kullanılır (aşağıya bkz.)
  - Active indicator: `AppColors.primary` (`#7C3AED`), 2px underline
  - Inactive: `AppColors.muted`
  - Font: `AppTextStyles.hudLabel.copyWith(letterSpacing: 2.0)` — hudLabel'daki 1.5'i 2.0'a override eder

### 3.2 Tab Controller Mimarisi

`GemShopView` → `StatefulWidget` + **`TickerProviderStateMixin`** kullanır (`SingleTickerProviderStateMixin` değil). Bunun nedeni birden fazla `AnimationController`'a ihtiyaç duyulması:

```dart
class _GemShopViewState extends State<GemShopView>
    with TickerProviderStateMixin {
  late final TabController _tabCtrl;   // TabBar için
  late final AnimationController _bgCtrl; // NeonGridPainter için (6s)
  // MegaPackCard kendi TweenAnimationBuilder'ını yönetir — dışarıdan controller gerekmez
}
```

`MegaPackCard`'ın gradient animasyonu `TweenAnimationBuilder` ile controller'sız, `duration: Duration(seconds: 2), builder` ile yazılır. Sekme geçişlerinde animasyon sıfırlanması beklenen davranış olarak kabul edilir.

### 3.3 Arka Plan

Mevcut `NeonGridPainter` animasyonu korunur (`_bgCtrl`, 6s döngü).

---

## 4. Sekme İçerikleri

### 4.1 KAZAN Sekmesi

Gem kazanma yollarını listeler. Renk tonu: `AppColors.success` (`#22C55E`).

#### Günlük Bedava Şarj Kartı

- İkon: `Icons.card_giftcard_rounded`, yeşil
- Başlık: `GÜNLÜK BEDAVA ŞARJ`
- Açıklama: `Her gün 1 random power-up şarjı`
- Durum A (talep edilmedi): `[TALEP ET]` butonu — `success` glow
- Durum B (talep edildi): `Gelecek: HH:MM:SS` countdown + disabled buton

**Countdown hesaplama:**
`PowerUpInventoryController` zaten `_kDailyDate` anahtarında tarih stringi saklıyor. Kalan süre hesabı:
```dart
Duration _timeUntilNextClaim() {
  final tomorrow = DateTime(
    DateTime.now().year, DateTime.now().month, DateTime.now().day + 1,
  );
  return tomorrow.difference(DateTime.now());
}
```
Countdown `Timer.periodic(Duration(seconds: 1), ...)` ile `setState` çağırır; `dispose()`'da iptal edilir.

- Kaynak: `PowerUpInventoryController.tryClaimDailyCharge()` (mevcut)

---

#### Reklam İzle Kartı

- İkon: `Icons.play_circle_outline_rounded`, `Color(0xFFF59E0B)` amber
- Başlık: `REKLAM İZLE`
- Açıklama: `+10 💎 kazan • Günde 5 kez`
- Kalan hak göstergesi: `x3 / 5`
- Buton: `[REKLAM İZLE]` — amber outlined, placeholder (Sprint 4'te AdMob)
- Kaynak: `UpgradeController.claimAdReward()` (yeni metod — bkz. Bölüm 6)

---

#### Mega Pack Kartı

Hem KAZAN hem POWER-UP sekmesinde gösterilir — aynı `MegaPackCard` widget'ı, tekrar kullanım.

- Büyük öne çıkan kart (`padding: 18`, `borderRadius: 14`)
- Animated gradient border: `TweenAnimationBuilder<double>` ile `#7C3AED → Color(0xFF06B6D4)` geçişi (2s döngü, `repeat: true`)
- Badge: `EN İYİ DEĞER` — sağ üst köşe, `AppColors.primary`
- İkon grubu: 5 power-up ikonu yan yana, küçük (22px)
- İçerik: `Her türden +3 şarj`
- Fiyat gösterimi: ~~`110💎`~~ (üstü çizili, `TextDecoration.lineThrough`) → `80💎`
- Buton: `[💎 80  SATIN AL]` — full-width, `AppColors.primary` glow
- Kaynak: `UpgradeController.purchaseMegaPack()` (yeni metod — bkz. Bölüm 6)

---

### 4.2 POWER-UP Sekmesi

```
┌─────────────────────────────────────┐
│ MegaPackCard (tekrar kullanım)      │
├─────────────────────────────────────┤
│ ── TEKLİ PAKETLER ──────────────── │
│ Mevcut 5 _PowerUpShopCard           │
└─────────────────────────────────────┘
```

- Section header: `TEKLİ PAKETLER`
- Mevcut `_PowerUpShopCard` widget'ları tasarım değişikliği olmadan taşınır

---

### 4.3 UPGRADES Sekmesi

Mevcut `_UpgradeCard` widget'ları büyük ölçüde korunur.

**Küçük iyileştirmeler:**
- Seviye noktaları: 8px → 10px
- MAX durumu: `boxShadow blurRadius` 16 → 24
- `effectLabel` font: `fontSize: 10` → `11`, alpha 200 → 230

---

## 5. Dosya Yapısı

```
lib/app/views/
  upgrade/
    gem_shop_view.dart          ← upgrade_view.dart yeniden adlandırılır
    widgets/
      mega_pack_card.dart       ← YENİ: Mega Pack featured kartı
      earn_tab.dart             ← YENİ: KAZAN sekmesi içeriği
      power_up_tab.dart         ← TAŞINDI: _PowerUpShopCard listesi
      upgrades_tab.dart         ← TAŞINDI: _UpgradeCard listesi
      shop_widgets.dart         ← TAŞINDI: _SectionHeader, _BuyButton, _MaxBadge, _GemChip (paylaşılan)
```

`shop_widgets.dart` private `_` prefix'leri kaldırılarak public class'lara dönüştürülür (dosyalar arası paylaşım için).

---

## 6. Controller Değişiklikleri

### UpgradeController — Eklemeler

```dart
// Günlük reklam sabitleri
static const int _kDailyAdLimit = 5;
static const String _kAdDateKey  = 'ad_date';
static const String _kAdCountKey = 'ad_count';

// State
final RxInt adCountToday = 0.obs;

// onInit içinde yükleme:
// _loadAdCount() — saklı tarihi bugünle karşılaştır:
//   eşleşiyorsa count yükle, eşleşmiyorsa count sıfırla + tarihi güncelle
void _loadAdCount() {
  final savedDate = _prefs.getString(_kAdDateKey) ?? '';
  final today = DateTime.now().toIso8601String().substring(0, 10);
  if (savedDate == today) {
    adCountToday.value = _prefs.getInt(_kAdCountKey) ?? 0;
  } else {
    adCountToday.value = 0;
    _prefs.setString(_kAdDateKey, today);
    _prefs.setInt(_kAdCountKey, 0);
  }
}

// Reklam ödülü talebi
Future<bool> claimAdReward() async {
  if (adCountToday.value >= _kDailyAdLimit) return false;
  addGems(10);
  adCountToday.value++;
  await _prefs.setInt(_kAdCountKey, adCountToday.value);
  return true;
}
```

### UpgradeController — Mega Pack

```dart
Future<bool> purchaseMegaPack() async {
  const int cost = 80;
  const int chargesPerType = 3;
  if (gems.value < cost) return false;

  // Atomic: önce gem'leri düş, hata olursa iade et
  final ok = await spendGems(cost);
  if (!ok) return false;

  try {
    final inventory = Get.find<PowerUpInventoryController>();
    for (final type in PowerUpType.values) {
      await inventory.addCharges(type, chargesPerType);
    }
    return true;
  } catch (e) {
    // Şarj ekleme başarısız: gem'leri iade et
    addGems(cost);
    return false;
  }
}
```

### PowerUpInventoryController — Değişiklik yok

`tryClaimDailyCharge()` ve `addCharges()` mevcut, kullanılıyor.

---

## 7. Home Ekranı Değişikliği

`home_view.dart` — `_ScoreCard` içindeki gem gösterge satırı `GestureDetector` ile sarılır:

```dart
GestureDetector(
  onTap: () => Get.toNamed(AppRoutes.upgrade),
  child: Row(
    // mevcut gem icon + sayı row'u (değişiklik yok)
  ),
)
```

---

## 8. Renk & Stil Referansı

> Not: `Color(0xFF06B6D4)` cyan rengi `AppColors`'ta tanımlı değil.
> `app_colors.dart`'a `static const Color cyan = Color(0xFF06B6D4);` eklenir.
> `AppColors.neonBlue` (`#2563EB`) farklı bir renk — karıştırılmamalı.

| Öğe | `AppColors` sabiti | Hex |
|-----|-------------------|-----|
| Tab indicator | `AppColors.primary` | `#7C3AED` |
| KAZAN tema | `AppColors.success` | `#22C55E` |
| Reklam butonu | (yeni) `AppColors.amber` veya hardcoded | `#F59E0B` |
| Mega Pack gradient start | `AppColors.primary` | `#7C3AED` |
| Mega Pack gradient end | (yeni) `AppColors.cyan` | `#06B6D4` |
| Gem chip | (yeni) `AppColors.cyan` | `#06B6D4` |
| Kart arka planı | `AppColors.surface` | `#1E1C35` |
| Arka plan | `AppColors.background` | `#0F0F23` |

**`app_colors.dart`'a eklenecek:**
```dart
static const Color cyan  = Color(0xFF06B6D4);
static const Color amber = Color(0xFFF59E0B);
```

---

## 9. Kapsam Dışı (Bu Sprintte Yapılmıyor)

- Skin sistemi UI (Sprint 4)
- Gerçek AdMob entegrasyonu (Sprint 4)
- IAP / gerçek para ile gem satın alma (Sprint 4+)
- Game Over "Son Şans" mekanizması (ayrı TODO item)
- Prestige sistemi (Sprint 4)
