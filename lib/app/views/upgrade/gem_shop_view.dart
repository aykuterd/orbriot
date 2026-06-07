import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/upgrade_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../home/widgets/neon_grid_painter.dart';
import 'widgets/earn_tab.dart';
import 'widgets/gem_packages_tab.dart';
import 'widgets/power_up_tab.dart';
import 'widgets/shop_widgets.dart';
import 'widgets/skin_tab.dart';
import 'widgets/upgrades_tab.dart';

class GemShopView extends StatefulWidget {
  const GemShopView({super.key});

  @override
  State<GemShopView> createState() => _GemShopViewState();
}

class _GemShopViewState extends State<GemShopView>
    with TickerProviderStateMixin {
  late final TabController _tabCtrl;
  late final AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<UpgradeController>();

    return Scaffold(
      body: Stack(
        children: [
          // Neon grid arka plan
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (context, _) => CustomPaint(
              painter: NeonGridPainter(_bgCtrl.value),
              size: Size.infinite,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // ── Üst Bar ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_rounded,
                            color: AppColors.foreground, size: 20),
                        onPressed: Get.back,
                      ),
                      Expanded(
                        child: Text(
                          'title_gem_shop'.tr,
                          style: AppTextStyles.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Obx(() => GemChip(gems: ctrl.gems.value)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // ── Tab Bar ─────────────────────────────────────────────
                TabBar(
                  controller: _tabCtrl,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 2,
                  dividerColor: AppColors.border.withAlpha(80),
                  labelStyle: AppTextStyles.hudLabel.copyWith(
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w700,
                  ),
                  labelColor: AppColors.foreground,
                  unselectedLabelColor: AppColors.muted,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [
                    Tab(text: 'tab_earn'.tr),
                    Tab(text: 'tab_power_up'.tr),
                    Tab(text: 'tab_upgrades_shop'.tr),
                    Tab(text: 'tab_skins'.tr),
                    Tab(text: 'tab_packages'.tr),
                  ],
                ),
                // ── Tab View ────────────────────────────────────────────
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: const [
                      EarnTab(),
                      PowerUpTab(),
                      UpgradesTab(),
                      SkinTab(),
                      GemPackagesTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
