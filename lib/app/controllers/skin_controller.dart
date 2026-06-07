import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/analytics_service.dart';
import '../core/utils/firestore_service.dart';
import '../models/skin.dart';
import 'upgrade_controller.dart';

class SkinController extends GetxController {
  static const _kActiveSkin  = 'skin_active';
  static const _kUnlockedKey = 'skin_unlocked';

  final RxString activeSkinId = 'default'.obs;
  final RxSet<String> unlockedIds = <String>{'default'}.obs;

  // Sadece shop içinde önizleme için — null = normal durum
  final Rx<SkinDefinition?> previewSkin = Rx<SkinDefinition?>(null);

  SkinDefinition get activeSkin => SkinCatalog.findById(activeSkinId.value);

  bool isUnlocked(String id) => unlockedIds.contains(id);

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    activeSkinId.value = prefs.getString(_kActiveSkin) ?? 'default';
    final raw = prefs.getStringList(_kUnlockedKey) ?? ['default'];
    unlockedIds
      ..clear()
      ..addAll({...raw, 'default'});
  }

  /// Kilitsiz bir skini aktif yap.
  Future<void> selectSkin(String id) async {
    if (!isUnlocked(id)) return;
    activeSkinId.value = id;
    previewSkin.value = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kActiveSkin, id);
    if (Get.isRegistered<AnalyticsService>()) {
      Get.find<AnalyticsService>().logSkinSelect(skinId: id);
    }
  }

  /// Kilitli bir skini önizleme modunda göster (shop UI için).
  void previewLockedSkin(SkinDefinition skin) {
    if (isUnlocked(skin.id)) return;
    previewSkin.value = skin;
  }

  /// Önizlemeyi kapat.
  void clearPreview() {
    previewSkin.value = null;
  }

  /// Aktif önizlemedeki skini satın al.
  /// Başarılıysa true döner, gem yetersizse false.
  Future<bool> purchasePreviewedSkin() async {
    final skin = previewSkin.value;
    if (skin == null) return false;
    return purchaseSkin(skin.id);
  }

  /// Verilen id'li skini satın al.
  Future<bool> purchaseSkin(String id) async {
    final skin = SkinCatalog.findById(id);
    if (isUnlocked(id)) {
      await selectSkin(id);
      return true;
    }
    final upgrade = Get.find<UpgradeController>();
    final ok = await upgrade.spendGems(skin.cost);
    if (!ok) return false;

    unlockedIds.add(id);
    activeSkinId.value = id;
    previewSkin.value = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kUnlockedKey, unlockedIds.toList());
    await prefs.setString(_kActiveSkin, id);
    if (Get.isRegistered<AnalyticsService>()) {
      Get.find<AnalyticsService>().logSkinPurchase(skinId: id, cost: skin.cost);
    }
    // Otomatik cloud save
    if (Get.isRegistered<FirestoreService>()) {
      Get.find<FirestoreService>().autoSave();
    }
    return true;
  }
}
