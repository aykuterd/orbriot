import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/analytics_service.dart';
import '../../core/utils/auth_service.dart';
import '../../core/utils/firestore_service.dart';
import '../../controllers/achievement_controller.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/power_up_inventory_controller.dart';
import '../../controllers/skin_controller.dart';
import '../../controllers/upgrade_controller.dart';
import '../../models/achievement.dart';
import '../../models/power_up_cell.dart';
import '../../models/upgrade_config.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../home/widgets/neon_grid_painter.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bgCtrl;
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _syncing = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  // Profil verisi
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _loadProfile();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final firestore = Get.find<FirestoreService>();
    final profile = await firestore.getUserProfile();
    if (mounted) {
      setState(() => _profile = profile);
      if (profile != null && profile['displayName'] != null) {
        _usernameCtrl.text = profile['displayName'];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthService>();

    return Scaffold(
      body: Stack(
        children: [
          // Arkaplan
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, child) => CustomPaint(
              painter: NeonGridPainter(_bgCtrl.value),
              size: Size.infinite,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Ust bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: AppColors.foreground),
                        onPressed: () => Get.back(),
                      ),
                      const SizedBox(width: 8),
                      Text('title_profile'.tr,
                          style: AppTextStyles.headlineMedium
                              .copyWith(fontSize: 16)),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        // Avatar
                        _buildAvatar(),
                        const SizedBox(height: 24),
                        // Istatistikler
                        _buildStatsCard(),
                        const SizedBox(height: 20),
                        // Hesap bolumu
                        Obx(() => auth.isLinked.value
                            ? _buildLinkedSection()
                            : _buildLinkSection()),
                        const SizedBox(height: 20),
                        // Giris yap (baska cihaz) — sadece anonim ise
                        Obx(() => auth.isLinked.value
                            ? const SizedBox.shrink()
                            : _buildSignInSection()),
                        // Hesaptan cik — sadece bagli ise
                        Obx(() => auth.isLinked.value
                            ? _buildSignOutSection()
                            : const SizedBox.shrink()),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final auth = Get.find<AuthService>();
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withAlpha(30),
            border: Border.all(color: AppColors.primary.withAlpha(120), width: 2),
            boxShadow: [
              BoxShadow(
                  color: AppColors.glowPrimary, blurRadius: 20),
            ],
          ),
          child: const Icon(Icons.person_rounded,
              color: AppColors.primaryLight, size: 40),
        ),
        const SizedBox(height: 12),
        Obx(() {
          final linked = auth.isLinked.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: linked
                  ? AppColors.success.withAlpha(20)
                  : AppColors.amber.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: linked
                    ? AppColors.success.withAlpha(80)
                    : AppColors.amber.withAlpha(80),
              ),
            ),
            child: Text(
              linked ? 'label_account_linked'.tr : 'label_anonymous'.tr,
              style: AppTextStyles.hudLabel.copyWith(
                fontSize: 9,
                color: linked ? AppColors.success : AppColors.amber,
                letterSpacing: 2,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStatsCard() {
    final home = Get.find<HomeController>();
    final upgrades = Get.find<UpgradeController>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withAlpha(80)),
      ),
      child: Obx(() => Column(
            children: [
              Text('section_stats'.tr,
                  style: AppTextStyles.hudLabel.copyWith(letterSpacing: 3)),
              const SizedBox(height: 16),
              _StatTile(
                icon: Icons.star_rounded,
                label: 'label_high_score'.tr,
                value: home.highScore.value.toString(),
                color: AppColors.success,
              ),
              const SizedBox(height: 10),
              _StatTile(
                icon: Icons.diamond_rounded,
                label: 'label_total_gems'.tr,
                value: upgrades.gems.value.toString(),
                color: AppColors.cyan,
              ),
              const SizedBox(height: 10),
              _StatTile(
                icon: Icons.auto_awesome_rounded,
                label: 'label_prestige_level_stat'.tr,
                value: upgrades.prestigeLevel.value.toString(),
                color: AppColors.amber,
              ),
            ],
          )),
    );
  }

  // -- Bagli Hesap Bolumu --

  Widget _buildLinkedSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withAlpha(60)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 28),
          const SizedBox(height: 8),
          Text('label_account_safe'.tr,
              style: AppTextStyles.headlineMedium.copyWith(fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            _profile?['displayName'] ?? '—',
            style: AppTextStyles.hudValue.copyWith(
              color: AppColors.cyan,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          _SmallButton(
            label: 'btn_change_name'.tr,
            icon: Icons.edit_rounded,
            color: AppColors.primaryLight,
            onTap: _showChangeNameDialog,
          ),
          const SizedBox(height: 8),
          _SmallButton(
            label: _syncing ? 'btn_saving'.tr : 'btn_cloud_save'.tr,
            icon: Icons.cloud_upload_rounded,
            color: AppColors.cyan,
            onTap: _syncing ? () {} : _syncToCloud,
          ),
          const SizedBox(height: 8),
          _SmallButton(
            label: 'btn_cloud_load'.tr,
            icon: Icons.cloud_download_rounded,
            color: AppColors.neonBlue,
            onTap: _loadFromCloud,
          ),
        ],
      ),
    );
  }

  // -- Anonim Hesap — Hesap Olustur Formu --

  Widget _buildLinkSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_rounded,
                  color: AppColors.amber, size: 20),
              const SizedBox(width: 8),
              Text('label_protect_account'.tr,
                  style: AppTextStyles.headlineMedium.copyWith(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'subtitle_protect_account'.tr,
            style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 16),
          _CyberTextField(
            controller: _usernameCtrl,
            hint: 'hint_username'.tr,
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 10),
          _CyberTextField(
            controller: _passwordCtrl,
            hint: 'hint_password'.tr,
            icon: Icons.lock_outline_rounded,
            obscure: _obscurePass,
            onToggle: () => setState(() => _obscurePass = !_obscurePass),
          ),
          const SizedBox(height: 10),
          _CyberTextField(
            controller: _confirmCtrl,
            hint: 'hint_confirm_password'.tr,
            icon: Icons.lock_outline_rounded,
            obscure: _obscureConfirm,
            onToggle: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: _NeonActionButton(
              label: _loading ? 'btn_connecting'.tr : 'btn_create_account'.tr,
              color: AppColors.success,
              loading: _loading,
              onTap: _loading ? null : _onLinkAccount,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInSection() {
    return Column(
      children: [
        const Divider(color: AppColors.border, height: 32),
        Text('label_already_have_account'.tr,
            style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SmallButton(
              label: 'btn_sign_in'.tr,
              icon: Icons.login_rounded,
              color: AppColors.primaryLight,
              onTap: _showSignInDialog,
            ),
            const SizedBox(width: 12),
            _SmallButton(
              label: 'btn_forgot_password'.tr,
              icon: Icons.help_outline_rounded,
              color: AppColors.amber,
              onTap: _showForgotPasswordDialog,
            ),
          ],
        ),
      ],
    );
  }

  // -- Hesaptan Cik Bolumu --

  Widget _buildSignOutSection() {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Divider(color: AppColors.border, height: 1),
        const SizedBox(height: 16),
        _SmallButton(
          label: 'btn_sign_out'.tr,
          icon: Icons.logout_rounded,
          color: AppColors.error,
          onTap: _showSignOutDialog,
        ),
      ],
    );
  }

  // -- Aksiyonlar --

  Future<void> _onLinkAccount() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    if (username.length < 3) {
      _showError('err_username_too_short'.tr);
      return;
    }
    if (password.length < 6) {
      _showError('err_password_too_short'.tr);
      return;
    }
    if (password != confirm) {
      _showError('err_passwords_mismatch'.tr);
      return;
    }

    setState(() => _loading = true);
    final auth = Get.find<AuthService>();
    final result = await auth.linkWithCredentials(
      username: username,
      password: password,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      // Firestore'a tam ilerlemeyi kaydet
      await _syncToCloud();
      if (Get.isRegistered<AnalyticsService>()) {
        Get.find<AnalyticsService>().logAccountLinked();
      }
      _showSuccess('success_account_created'.tr);
    } else {
      _showError(result.error ?? 'err_generic'.tr);
    }
  }

  /// Tum oyun verilerini Firestore'a kaydet
  Future<void> _syncToCloud() async {
    if (_syncing) return;
    setState(() => _syncing = true);

    try {
      final firestore = Get.find<FirestoreService>();
      final home = Get.find<HomeController>();
      final upgrades = Get.find<UpgradeController>();
      final skins = Get.find<SkinController>();
      final achievements = Get.find<AchievementController>();
      final inventory = Get.find<PowerUpInventoryController>();
      final prefs = await SharedPreferences.getInstance();

      // Upgrade seviyeleri
      final upgradeLevels = <String, int>{};
      for (final def in UpgradeCatalog.all) {
        upgradeLevels[def.key] = upgrades.levelOf(def.key);
      }

      // Basarim sayaclari
      final achievementCounters = <String, int>{};
      for (final c in AchievementCounter.values) {
        achievementCounters[c.name] =
            prefs.getInt('ach_cnt_${c.name}') ?? 0;
      }

      // Acilmis ve odul alinmis basarimlar
      final unlockedAchs = <String>[];
      final claimedAchs = <String>[];
      for (final a in achievements.achievements) {
        if (a.unlocked) unlockedAchs.add(a.id);
        if (a.claimed) claimedAchs.add(a.id);
      }

      // Power-up sarjlari
      final puCharges = <String, int>{};
      for (final type in PowerUpType.values) {
        puCharges[type.name] = inventory.chargesOf(type);
      }

      // DisplayName
      final displayName = _profile?['displayName'] ??
          (_usernameCtrl.text.trim().isNotEmpty
              ? _usernameCtrl.text.trim()
              : 'label_default_player'.tr);

      await firestore.saveFullProgress(
        displayName: displayName,
        highScore: home.highScore.value,
        bestStage: prefs.getInt('best_stage') ?? 0,
        totalGems: upgrades.gems.value,
        prestigeLevel: upgrades.prestigeLevel.value,
        upgradeLevels: upgradeLevels,
        achievementCounters: achievementCounters,
        unlockedAchievements: unlockedAchs,
        claimedAchievements: claimedAchs,
        unlockedSkins: skins.unlockedIds.toList(),
        activeSkinId: skins.activeSkinId.value,
        powerUpCharges: puCharges,
      );

      if (Get.isRegistered<AnalyticsService>()) {
        Get.find<AnalyticsService>().logCloudSave();
      }
      if (mounted) _showSuccess('success_cloud_saved'.tr);
      _loadProfile();
    } catch (e) {
      if (mounted) _showError('err_save'.trParams({'error': '$e'}));
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  /// Buluttan tum ilerlemeyi yukle ve yerel veriye yaz
  Future<void> _loadFromCloud() async {
    // Onay dialogu goster
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('dialog_cloud_load_title'.tr,
            style: AppTextStyles.headlineMedium.copyWith(fontSize: 14)),
        content: Text(
          'dialog_cloud_load_body'.tr,
          style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('btn_cancel'.tr,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('btn_load'.tr,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.neonBlue)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _syncing = true);

    try {
      final firestore = Get.find<FirestoreService>();
      final data = await firestore.loadFullProgress();
      if (data == null) {
        if (mounted) _showError('err_no_cloud_progress'.tr);
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final upgrades = Get.find<UpgradeController>();

      // High score + best stage
      if (data['highScore'] != null) {
        await prefs.setInt('high_score', data['highScore']);
      }
      if (data['bestStage'] != null) {
        await prefs.setInt('best_stage', data['bestStage']);
      }

      // Gems
      if (data['totalGems'] != null) {
        await prefs.setInt('gems', data['totalGems']);
      }

      // Prestige
      if (data['prestigeLevel'] != null) {
        await prefs.setInt('prestige_level', data['prestigeLevel']);
      }

      // Upgrade seviyeleri
      if (data['upgradeLevels'] is Map) {
        final levels = Map<String, dynamic>.from(data['upgradeLevels']);
        for (final entry in levels.entries) {
          await prefs.setInt('upg_${entry.key}', entry.value as int);
        }
      }

      // Basarim sayaclari
      if (data['achievementCounters'] is Map) {
        final counters =
            Map<String, dynamic>.from(data['achievementCounters']);
        for (final entry in counters.entries) {
          await prefs.setInt('ach_cnt_${entry.key}', entry.value as int);
        }
      }

      // Acilmis basarimlar
      if (data['unlockedAchievements'] is List) {
        for (final id in data['unlockedAchievements']) {
          await prefs.setBool('ach_unlocked_$id', true);
        }
      }
      if (data['claimedAchievements'] is List) {
        for (final id in data['claimedAchievements']) {
          await prefs.setBool('ach_claimed_$id', true);
        }
      }

      // Skinler
      if (data['unlockedSkins'] is List) {
        final skinList = List<String>.from(data['unlockedSkins']);
        await prefs.setStringList('skin_unlocked', skinList);
      }
      if (data['activeSkinId'] != null) {
        await prefs.setString('skin_active', data['activeSkinId']);
      }

      // Power-up sarjlari
      if (data['powerUpCharges'] is Map) {
        final charges =
            Map<String, dynamic>.from(data['powerUpCharges']);
        for (final entry in charges.entries) {
          await prefs.setInt('pu_charge_${entry.key}', entry.value as int);
        }
      }

      // Controller'lari yeniden yukle
      await upgrades.reload();
      // Skin + achievement + inventory controller'lari dispose/reinit yerine
      // home ekranina donup fresh state aliriz
      if (mounted) {
        _showSuccess('success_cloud_loaded'.tr);
        await Future.delayed(const Duration(seconds: 1));
        Get.offAllNamed(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) _showError('err_load'.trParams({'error': '$e'}));
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  // -- Sign Out --

  void _showSignOutDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('dialog_sign_out_title'.tr,
            style: AppTextStyles.headlineMedium.copyWith(fontSize: 14)),
        content: Text(
          'dialog_sign_out_body'.tr,
          style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('btn_cancel'.tr,
                style:
                    AppTextStyles.bodySmall.copyWith(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              final auth = Get.find<AuthService>();
              await auth.signOut();
              if (mounted) {
                _loadProfile();
                _showSuccess('success_sign_out'.tr);
              }
            },
            child: Text('btn_exit'.tr,
                style:
                    AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  // -- Sifremi Unuttum --

  void _showForgotPasswordDialog() {
    final userCtrl = TextEditingController();
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('dialog_forgot_password_title'.tr,
            style: AppTextStyles.headlineMedium.copyWith(fontSize: 14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'dialog_forgot_password_body'.tr,
              style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
            ),
            const SizedBox(height: 16),
            _CyberTextField(
              controller: userCtrl,
              hint: 'hint_username'.tr,
              icon: Icons.person_outline_rounded,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('btn_close'.tr,
                style:
                    AppTextStyles.bodySmall.copyWith(color: AppColors.muted)),
          ),
        ],
      ),
    );
  }

  void _showChangeNameDialog() {
    final nameCtrl =
        TextEditingController(text: _profile?['displayName'] ?? '');
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('dialog_change_name_title'.tr,
            style: AppTextStyles.headlineMedium.copyWith(fontSize: 14)),
        content: _CyberTextField(
          controller: nameCtrl,
          hint: 'hint_new_username'.tr,
          icon: Icons.person_outline_rounded,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('btn_cancel'.tr,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.length < 3) return;
              final firestore = Get.find<FirestoreService>();
              await firestore.updateDisplayName(name);
              Get.back();
              _loadProfile();
              _showSuccess('success_name_updated'.tr);
            },
            child: Text('btn_save'.tr,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.success)),
          ),
        ],
      ),
    );
  }

  void _showSignInDialog() {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('dialog_sign_in_title'.tr,
            style: AppTextStyles.headlineMedium.copyWith(fontSize: 14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CyberTextField(
              controller: userCtrl,
              hint: 'hint_username'.tr,
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 10),
            _CyberTextField(
              controller: passCtrl,
              hint: 'hint_password_simple'.tr,
              icon: Icons.lock_outline_rounded,
              obscure: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('btn_cancel'.tr,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () async {
              final auth = Get.find<AuthService>();
              final result = await auth.signInWithCredentials(
                username: userCtrl.text.trim(),
                password: passCtrl.text,
              );
              Get.back();
              if (result.success) {
                if (Get.isRegistered<AnalyticsService>()) {
                  Get.find<AnalyticsService>().logSignIn();
                }
                // Giris basarili — buluttan ilerlemeyi yukle
                _loadProfile();
                _showSuccess('success_sign_in'.tr);
              } else {
                _showError(result.error ?? 'err_sign_in_failed'.tr);
              }
            },
            child: Text('btn_go'.tr,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.success)),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    Get.snackbar('snack_error'.tr, msg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withAlpha(200),
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2));
  }

  void _showSuccess(String msg) {
    Get.snackbar('snack_success'.tr, msg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withAlpha(200),
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2));
  }
}

// -- Cyberpunk Text Field --

class _CyberTextField extends StatelessWidget {
  const _CyberTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.onToggle,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withAlpha(80)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.bodySmall.copyWith(fontSize: 12),
          prefixIcon: Icon(icon, color: AppColors.muted, size: 18),
          suffixIcon: onToggle != null
              ? IconButton(
                  icon: Icon(
                    obscure
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: AppColors.muted,
                    size: 18,
                  ),
                  onPressed: onToggle,
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }
}

// -- Stat Tile --

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(label, style: AppTextStyles.hudLabel.copyWith(fontSize: 10)),
        const Spacer(),
        Text(value,
            style: AppTextStyles.hudValue
                .copyWith(fontSize: 14, color: color)),
      ],
    );
  }
}

// -- Kucuk Buton --

class _SmallButton extends StatelessWidget {
  const _SmallButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(label,
                style: AppTextStyles.hudLabel.copyWith(
                  fontSize: 10,
                  color: color,
                  letterSpacing: 1.5,
                )),
          ],
        ),
      ),
    );
  }
}

// -- Neon Action Button --

class _NeonActionButton extends StatelessWidget {
  const _NeonActionButton({
    required this.label,
    required this.color,
    this.loading = false,
    this.onTap,
  });

  final String label;
  final Color color;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: onTap == null ? color.withAlpha(40) : color.withAlpha(200),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(120)),
          boxShadow: onTap == null
              ? null
              : [BoxShadow(color: color.withAlpha(60), blurRadius: 12)],
        ),
        child: Center(
          child: loading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.background))
              : Text(label,
                  style: AppTextStyles.button.copyWith(
                    fontSize: 12,
                    color: AppColors.background,
                  )),
        ),
      ),
    );
  }
}
