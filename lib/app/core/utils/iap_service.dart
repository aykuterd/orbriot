import 'dart:async';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'ad_service.dart';
import 'analytics_service.dart';
import '../../../app/controllers/upgrade_controller.dart';

// ── Ürün ID'leri ─────────────────────────────────────────────────────────────
// TODO: App Store Connect ve Google Play Console'da bu ID'leri oluşturun.
// iOS  → App Store Connect > My Apps > Orbriot > Subscriptions > In-App Purchases
// Android → Play Console > Orbriot > Monetize > In-App Products
class IAPProductIds {
  static const String starterPack = 'com.orbriot.gems.starter'; // $0.99 → 100 gem
  static const String valuePack   = 'com.orbriot.gems.value';   // $4.99 → 600 gem
  static const String megaPack    = 'com.orbriot.gems.mega';    // $9.99 → 1500 gem
  static const String adFree      = 'com.orbriot.adfree';       // $2.99 → reklamsız

  static const Set<String> all = {starterPack, valuePack, megaPack, adFree};
}

// ── Paket tanımı ─────────────────────────────────────────────────────────────

enum GemPack { starter, value, mega, adFree }

extension GemPackDetails on GemPack {
  String get productId {
    switch (this) {
      case GemPack.starter: return IAPProductIds.starterPack;
      case GemPack.value:   return IAPProductIds.valuePack;
      case GemPack.mega:    return IAPProductIds.megaPack;
      case GemPack.adFree:  return IAPProductIds.adFree;
    }
  }

  int get gemReward {
    switch (this) {
      case GemPack.starter: return 100;
      case GemPack.value:   return 600;
      case GemPack.mega:    return 1500;
      case GemPack.adFree:  return 0;
    }
  }

  String get displayPrice {
    switch (this) {
      case GemPack.starter: return '\$0.99';
      case GemPack.value:   return '\$4.99';
      case GemPack.mega:    return '\$9.99';
      case GemPack.adFree:  return '\$2.99';
    }
  }

  String get displayPriceHalf {
    switch (this) {
      case GemPack.starter: return '\$0.49';
      case GemPack.value:   return '\$2.49';
      case GemPack.mega:    return '\$4.99';
      case GemPack.adFree:  return '\$1.49';
    }
  }
}

// ── IAP Servisi ──────────────────────────────────────────────────────────────

class IAPService extends GetxService {
  final _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  final RxBool isAvailable       = false.obs;
  final RxBool isPurchasing      = false.obs;
  final RxMap<String, ProductDetails> products = <String, ProductDetails>{}.obs;

  Future<IAPService> init() async {
    isAvailable.value = await _iap.isAvailable();
    if (!isAvailable.value) return this;

    _sub = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (_) {},
    );

    await _loadProducts();
    await _restorePurchases();
    return this;
  }

  Future<void> _loadProducts() async {
    final response = await _iap.queryProductDetails(IAPProductIds.all);
    for (final p in response.productDetails) {
      products[p.id] = p;
    }
  }

  Future<void> _restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (_) {}
  }

  // ── Satın alma ────────────────────────────────────────────────────────────

  Future<bool> buyPack(GemPack pack) async {
    if (!isAvailable.value) return false;
    if (isPurchasing.value) return false;

    final product = products[pack.productId];
    if (product == null) return false;

    isPurchasing.value = true;
    final param = PurchaseParam(productDetails: product);
    try {
      await _iap.buyConsumable(purchaseParam: param);
      return true;
    } catch (_) {
      isPurchasing.value = false;
      return false;
    }
  }

  Future<bool> buyAdFree() async {
    if (!isAvailable.value) return false;
    if (isPurchasing.value) return false;

    final product = products[IAPProductIds.adFree];
    if (product == null) return false;

    isPurchasing.value = true;
    final param = PurchaseParam(productDetails: product);
    try {
      await _iap.buyNonConsumable(purchaseParam: param);
      return true;
    } catch (_) {
      isPurchasing.value = false;
      return false;
    }
  }

  // ── Satın alma sonucu ─────────────────────────────────────────────────────

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) continue;

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _grantPurchase(purchase);
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
    isPurchasing.value = false;
  }

  Future<void> _grantPurchase(PurchaseDetails purchase) async {
    final id = purchase.productID;

    if (id == IAPProductIds.adFree) {
      if (Get.isRegistered<AdService>()) {
        await Get.find<AdService>().setAdFree(true);
      }
      _logPurchase(id, 0);
      return;
    }

    final pack = _packFromId(id);
    if (pack == null) return;

    if (Get.isRegistered<UpgradeController>()) {
      await Get.find<UpgradeController>().addGems(pack.gemReward);
    }
    _logPurchase(id, pack.gemReward);
  }

  GemPack? _packFromId(String id) {
    for (final p in GemPack.values) {
      if (p.productId == id) return p;
    }
    return null;
  }

  void _logPurchase(String productId, int gems) {
    if (!Get.isRegistered<AnalyticsService>()) return;
    Get.find<AnalyticsService>().logGemSpend(
      amount: -gems,
      item: 'iap_$productId',
    );
  }

  // ── Fiyat gösterimi ───────────────────────────────────────────────────────

  /// Store'dan gelen gerçek fiyat (yüklendiyse), yoksa fallback.
  String priceOf(GemPack pack, {bool half = false}) {
    final product = products[pack.productId];
    if (product != null && !half) return product.price;
    return half ? pack.displayPriceHalf : pack.displayPrice;
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
