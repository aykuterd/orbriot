import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/achievement_controller.dart';
import '../../models/achievement.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

// ── Yardımcı veri modeli ──────────────────────────────────────────────────────

/// Bir serinin tüm achievement'larını gruplanmış halde tutar
class _SeriesGroup {
  final String name;
  final List<Achievement> achievements; // seriesOrder'a göre sıralı

  _SeriesGroup({required this.name, required this.achievements});

  /// Aktif (devam eden) tier indexi — tamamlanmamış ilk achievement
  int get activeIndex {
    for (int i = 0; i < achievements.length; i++) {
      if (!achievements[i].unlocked) return i;
    }
    return achievements.length; // hepsi tamamlandı
  }

  bool get isFullyCompleted => activeIndex == achievements.length;

  /// Claim bekleyen achievement var mı?
  bool get hasUnclaimed =>
      achievements.any((a) => a.unlocked && !a.claimed);

  /// Aktif tier rengi
  Color get activeColor {
    final idx = activeIndex.clamp(0, achievements.length - 1);
    return achievements[idx].def.tier.color;
  }
}

// ── Ana View ──────────────────────────────────────────────────────────────────

class AchievementView extends GetView<AchievementController> {
  const AchievementView({super.key});

  List<_SeriesGroup> _buildSeriesGroups(List<Achievement> achievements) {
    final map = <String, List<Achievement>>{};
    for (final a in achievements) {
      map.putIfAbsent(a.def.seriesName, () => []).add(a);
    }
    final groups = map.entries.map((e) {
      final sorted = List.of(e.value)
        ..sort((a, b) => a.def.seriesOrder.compareTo(b.def.seriesOrder));
      return _SeriesGroup(name: e.key, achievements: sorted);
    }).toList();

    // Sıralama: claim bekleyenler → devam edenler → tamamlanmışlar
    groups.sort((a, b) {
      if (a.isFullyCompleted != b.isFullyCompleted) {
        return a.isFullyCompleted ? 1 : -1;
      }
      if (a.hasUnclaimed != b.hasUnclaimed) {
        return a.hasUnclaimed ? -1 : 1;
      }
      return a.name.compareTo(b.name);
    });
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.muted, size: 20),
          onPressed: Get.back,
        ),
        centerTitle: true,
        title: Text(
          'title_achievements'.tr,
          style: GoogleFonts.orbitron(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryLight,
            letterSpacing: 2,
            shadows: [
              Shadow(color: AppColors.glowPrimary, blurRadius: 10),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
              ),
            ),
          ),
        ),
      ),
      body: Obx(() {
        final total    = controller.achievements.length;
        final unlocked = controller.achievements.where((a) => a.unlocked).length;
        final groups   = _buildSeriesGroups(controller.achievements);

        return CustomScrollView(
          slivers: [
            // Özet kart
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _SummaryCard(unlocked: unlocked, total: total),
              ),
            ),
            // Seri kartları
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SeriesCard(
                      group: groups[i],
                      controller: controller,
                    ),
                  ),
                  childCount: groups.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        );
      }),
    );
  }
}

// ── Özet Kart ─────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.unlocked, required this.total});
  final int unlocked;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : unlocked / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withAlpha(100)),
        boxShadow: const [
          BoxShadow(color: AppColors.glowPrimary, blurRadius: 20),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded,
              color: Color(0xFFF59E0B), size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'label_achievement_count'.trParams({'unlocked': '$unlocked', 'total': '$total'}),
                  style: GoogleFonts.orbitron(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: pct),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    builder: (_, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 6,
                      backgroundColor: AppColors.border.withAlpha(60),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${(pct * 100).round()}%',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFF59E0B),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Seri Kartı ────────────────────────────────────────────────────────────────

class _SeriesCard extends StatelessWidget {
  const _SeriesCard({
    required this.group,
    required this.controller,
  });

  final _SeriesGroup group;
  final AchievementController controller;

  @override
  Widget build(BuildContext context) {
    final g           = group;
    final activeIdx   = g.activeIndex;
    final isComplete  = g.isFullyCompleted;
    final accentColor = isComplete ? AppColors.amber : g.activeColor;

    // Aktif achievement (progress bar ve ikon için)
    final activeAch = activeIdx < g.achievements.length
        ? g.achievements[activeIdx]
        : g.achievements.last;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isComplete
              ? AppColors.amber.withAlpha(160)
              : accentColor.withAlpha(80),
          width: isComplete ? 1.5 : 1,
        ),
        boxShadow: g.hasUnclaimed
            ? [BoxShadow(color: accentColor.withAlpha(40), blurRadius: 12)]
            : null,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Başlık satırı ────────────────────────────────────────────
          Row(
            children: [
              Icon(activeAch.def.icon, color: accentColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'series_${g.name}'.tr.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.foreground,
                    letterSpacing: 1,
                  ),
                ),
              ),
              // Tier etiketi
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: accentColor.withAlpha(120)),
                ),
                child: Text(
                  isComplete ? 'label_done'.tr : activeAch.def.tier.label,
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // ── Tier badge satırı ────────────────────────────────────────
          Row(
            children: [
              for (int i = 0; i < g.achievements.length; i++) ...[
                _TierBadge(
                  label: _romanNumeral(i + 1),
                  achievement: g.achievements[i],
                  isActive: i == activeIdx,
                  onClaim: g.achievements[i].unlocked &&
                          !g.achievements[i].claimed
                      ? () => controller.claimReward(g.achievements[i])
                      : null,
                ),
                if (i < g.achievements.length - 1)
                  const SizedBox(width: 6),
              ],
            ],
          ),
          // ── Aktif tier progress ──────────────────────────────────────
          if (!isComplete) ...[
            const SizedBox(height: 10),
            Text(
              'Tier ${_romanNumeral(activeIdx + 1)} — ${activeAch.def.localizedDescription}',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 10,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: activeAch.progressFraction),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                builder: (_, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 5,
                  backgroundColor: AppColors.border.withAlpha(60),
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${activeAch.displayProgress} / ${activeAch.def.target}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                color: AppColors.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _romanNumeral(int n) {
    const map = {1: 'I', 2: 'II', 3: 'III', 4: 'IV', 5: 'V'};
    return map[n] ?? '$n';
  }
}

// ── Tier Badge ────────────────────────────────────────────────────────────────

class _TierBadge extends StatelessWidget {
  const _TierBadge({
    required this.label,
    required this.achievement,
    required this.isActive,
    this.onClaim,
  });

  final String       label;
  final Achievement  achievement;
  final bool         isActive;
  final VoidCallback? onClaim;

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.unlocked;
    final claimed  = achievement.claimed;
    final color    = achievement.def.tier.color;

    Color bgColor;
    Color borderColor;
    Widget icon;

    if (claimed) {
      bgColor     = AppColors.success.withAlpha(30);
      borderColor = AppColors.success.withAlpha(160);
      icon = const Icon(Icons.check_rounded, size: 10, color: AppColors.success);
    } else if (unlocked) {
      // Ödül bekliyor — altın vurgu
      bgColor     = AppColors.amber.withAlpha(30);
      borderColor = AppColors.amber;
      icon = const Icon(Icons.star_rounded, size: 10, color: AppColors.amber);
    } else if (isActive) {
      bgColor     = color.withAlpha(25);
      borderColor = color;
      icon = Text(
        label,
        style: TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      );
    } else {
      bgColor     = AppColors.surfaceVariant.withAlpha(60);
      borderColor = AppColors.border.withAlpha(60);
      icon = Text(
        label,
        style: const TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 9,
          color: AppColors.muted,
        ),
      );
    }

    return GestureDetector(
      onTap: (unlocked && !claimed) ? onClaim : null,
      child: Container(
        width: 32,
        height: 28,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: borderColor,
            width: isActive ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: icon,
      ),
    );
  }
}
