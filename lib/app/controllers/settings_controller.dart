import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/sound_service.dart';
import '../models/upgrade_config.dart';
import 'upgrade_controller.dart';

class SettingsController extends GetxController {
  // ── Reaktif durum ─────────────────────────────────────────────────────────
  final RxBool sfxEnabled    = true.obs;
  final RxBool bgmEnabled    = true.obs;
  final RxBool hapticEnabled = true.obs;
  final RxDouble sfxVolume   = 1.0.obs;
  final RxDouble bgmVolume   = 0.35.obs;

  /// Ayarların SharedPreferences'tan yüklendiğini garanti eder.
  late final Future<void> ready;

  // ── SharedPreferences anahtarları ─────────────────────────────────────────
  static const _kSfx      = 'sfx_enabled';
  static const _kBgm      = 'bgm_enabled';
  static const _kHaptic   = 'haptic_enabled';
  static const _kSfxVol   = 'sfx_volume';
  static const _kBgmVol   = 'bgm_volume';

  @override
  void onInit() {
    super.onInit();
    ready = _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    sfxEnabled.value    = prefs.getBool(_kSfx)      ?? true;
    bgmEnabled.value    = prefs.getBool(_kBgm)      ?? true;
    hapticEnabled.value = prefs.getBool(_kHaptic)   ?? true;
    sfxVolume.value     = prefs.getDouble(_kSfxVol) ?? 1.0;
    bgmVolume.value     = prefs.getDouble(_kBgmVol) ?? 0.35;
    // Not: SoundService'e uygulama burada yapılmaz.
    // SoundService putAsync ile register ediliyor ve burada hazır olmayabilir.
    // Ayarlar SoundService'e applyToSound() ile uygulanır (GameController çağırır).
  }

  /// Kayıtlı ayarları SoundService'e uygula.
  /// GameController, BGM başlatmadan önce bunu çağırmalıdır.
  void applyToSound() {
    if (!Get.isRegistered<SoundService>()) return;
    final sound = Get.find<SoundService>();
    sound.setSfxEnabled(sfxEnabled.value);
    sound.setBgmEnabled(bgmEnabled.value);
    sound.setSfxVolume(sfxVolume.value);
    sound.setBgmVolume(bgmVolume.value);
  }

  // ── Toggle metodları ──────────────────────────────────────────────────────

  Future<void> toggleSfx() async {
    sfxEnabled.value = !sfxEnabled.value;
    Get.find<SoundService>().setSfxEnabled(sfxEnabled.value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSfx, sfxEnabled.value);
  }

  Future<void> toggleBgm() async {
    bgmEnabled.value = !bgmEnabled.value;
    Get.find<SoundService>().setBgmEnabled(bgmEnabled.value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBgm, bgmEnabled.value);
  }

  Future<void> toggleHaptic() async {
    hapticEnabled.value = !hapticEnabled.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHaptic, hapticEnabled.value);
  }

  // ── Volume metodları ──────────────────────────────────────────────────────

  Future<void> updateSfxVolume(double v) async {
    sfxVolume.value = v;
    Get.find<SoundService>().setSfxVolume(v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kSfxVol, v);
  }

  Future<void> updateBgmVolume(double v) async {
    bgmVolume.value = v;
    await Get.find<SoundService>().setBgmVolume(v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kBgmVol, v);
  }

  // ── İlerleme sıfırlama ────────────────────────────────────────────────────

  Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('high_score');
    await prefs.remove('best_level');
    await prefs.remove('best_stage');
    await prefs.setInt('gems', 0);
    for (final def in UpgradeCatalog.all) {
      await prefs.remove('upg_${def.key}');
    }
    if (Get.isRegistered<UpgradeController>()) {
      await Get.find<UpgradeController>().reload();
    }
  }
}
