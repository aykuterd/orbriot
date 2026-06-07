import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/utils/auth_service.dart';
import '../../core/utils/firestore_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../home/widgets/neon_grid_painter.dart';

class LeaderboardView extends StatefulWidget {
  const LeaderboardView({super.key});

  @override
  State<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<LeaderboardView>
    with TickerProviderStateMixin {
  late final AnimationController _bgCtrl;
  late final TabController _tabCtrl;

  List<Map<String, dynamic>> _globalScores = [];
  List<Map<String, dynamic>> _weeklyScores = [];
  Map<String, dynamic>? _userGlobalEntry;
  Map<String, dynamic>? _userWeeklyEntry;
  bool _loading = true;

  // Kullanıcı satırına otomatik scroll
  final ScrollController _globalScrollCtrl = ScrollController();
  final ScrollController _weeklyScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) setState(() {});
    });
    _loadData();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _tabCtrl.dispose();
    _globalScrollCtrl.dispose();
    _weeklyScrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final firestore = Get.find<FirestoreService>();
    final results = await Future.wait([
      firestore.getGlobalLeaderboard(),
      firestore.getWeeklyLeaderboard(),
      firestore.getUserGlobalEntry(),
      firestore.getUserWeeklyEntry(),
    ]);
    if (!mounted) return;
    setState(() {
      _globalScores = results[0] as List<Map<String, dynamic>>;
      _weeklyScores = results[1] as List<Map<String, dynamic>>;
      _userGlobalEntry = results[2] as Map<String, dynamic>?;
      _userWeeklyEntry = results[3] as Map<String, dynamic>?;
      _loading = false;
    });

    // Kullanıcının satırına scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToUser(_globalScores, _globalScrollCtrl);
    });
  }

  void _scrollToUser(
      List<Map<String, dynamic>> scores, ScrollController ctrl) {
    if (!ctrl.hasClients) return;
    final uid = Get.find<AuthService>().uid;
    final index = scores.indexWhere((e) => e['docId'] == uid);
    if (index < 0) return;

    // Her satır yaklaşık 52px yüksekliğinde (padding + margin)
    final offset = (index * 52.0 - 100).clamp(0.0, ctrl.position.maxScrollExtent);
    ctrl.animateTo(offset,
        duration: const Duration(milliseconds: 600), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
                // Üst bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: AppColors.foreground),
                        onPressed: () => Get.back(),
                      ),
                      const SizedBox(width: 8),
                      Text('title_leaderboard'.tr,
                          style: AppTextStyles.headlineMedium
                              .copyWith(fontSize: 16)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded,
                            color: AppColors.muted, size: 22),
                        onPressed: _loadData,
                      ),
                    ],
                  ),
                ),
                // Tab bar
                _buildTabBar(),
                const SizedBox(height: 8),
                // Kullanıcı kartı
                _buildUserRankCard(),
                const SizedBox(height: 8),
                // Liste
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary))
                      : TabBarView(
                          controller: _tabCtrl,
                          children: [
                            _buildScoreList(_globalScores, _globalScrollCtrl),
                            _buildScoreList(_weeklyScores, _weeklyScrollCtrl),
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

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withAlpha(60)),
      ),
      child: TabBar(
        controller: _tabCtrl,
        indicator: BoxDecoration(
          color: AppColors.primary.withAlpha(60),
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: AppTextStyles.hudLabel.copyWith(
            fontSize: 10, letterSpacing: 2, color: AppColors.foreground),
        unselectedLabelStyle: AppTextStyles.hudLabel.copyWith(
            fontSize: 10, letterSpacing: 2, color: AppColors.muted),
        labelColor: AppColors.foreground,
        unselectedLabelColor: AppColors.muted,
        onTap: (index) {
          // Tab değiştiğinde o listeye scroll
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final scores = index == 0 ? _globalScores : _weeklyScores;
            final ctrl = index == 0 ? _globalScrollCtrl : _weeklyScrollCtrl;
            _scrollToUser(scores, ctrl);
          });
        },
        tabs: [
          Tab(text: 'tab_global'.tr),
          Tab(text: 'tab_weekly'.tr),
        ],
      ),
    );
  }

  Widget _buildUserRankCard() {
    final entry = _tabCtrl.index == 0 ? _userGlobalEntry : _userWeeklyEntry;
    if (entry == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface.withAlpha(120),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withAlpha(40)),
        ),
        child: Row(
          children: [
            Icon(Icons.person_off_rounded,
                color: AppColors.muted.withAlpha(120), size: 20),
            const SizedBox(width: 10),
            Text('label_no_score_yet'.tr,
                style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
          ],
        ),
      );
    }

    final rank = entry['rank'] as int;
    final name = entry['displayName'] ?? 'label_default_player'.tr;
    final score = entry['score'] ?? 0;
    final prestige = entry['prestigeLevel'] ?? 0;

    // Sıralama rengi
    final rankColor = rank == 1
        ? const Color(0xFFFBBF24)
        : rank == 2
            ? const Color(0xFFC0C0C0)
            : rank == 3
                ? const Color(0xFFCD7F32)
                : AppColors.primaryLight;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withAlpha(30),
            AppColors.primary.withAlpha(10),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withAlpha(100)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(40),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Sıralama
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rankColor.withAlpha(20),
              shape: BoxShape.circle,
              border: Border.all(color: rankColor.withAlpha(120), width: 1.5),
            ),
            child: Center(
              child: rank <= 3
                  ? Icon(Icons.emoji_events_rounded,
                      color: rankColor, size: 20)
                  : Text(
                      '#$rank',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: rankColor,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // İsim + prestige
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (prestige > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.amber.withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                          border:
                              Border.all(color: AppColors.amber.withAlpha(80)),
                        ),
                        child: Text(
                          'P$prestige',
                          style: AppTextStyles.hudLabel.copyWith(
                            fontSize: 8,
                            color: AppColors.amber,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'label_you'.tr,
                  style: AppTextStyles.hudLabel.copyWith(
                    fontSize: 8,
                    color: AppColors.primaryLight.withAlpha(150),
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          // Skor
          Text(
            score.toString().padLeft(7, '0'),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryLight,
              letterSpacing: 1.5,
              shadows: [
                Shadow(
                  color: AppColors.glowPrimary,
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreList(
      List<Map<String, dynamic>> scores, ScrollController ctrl) {
    if (scores.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.leaderboard_rounded,
                color: AppColors.muted.withAlpha(80), size: 48),
            const SizedBox(height: 12),
            Text('label_no_scores'.tr,
                style: AppTextStyles.bodySmall.copyWith(fontSize: 13)),
            Text('label_be_first'.tr,
                style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
          ],
        ),
      );
    }

    final uid = Get.find<AuthService>().uid;

    return ListView.builder(
      controller: ctrl,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: scores.length,
      itemBuilder: (context, index) {
        final entry = scores[index];
        final rank = index + 1;
        final isMe = entry['docId'] == uid;
        final name = entry['displayName'] ?? 'label_default_player'.tr;
        final score = entry['score'] ?? 0;
        final prestige = entry['prestigeLevel'] ?? 0;

        return _ScoreRow(
          rank: rank,
          name: name,
          score: score,
          prestigeLevel: prestige,
          isMe: isMe,
        );
      },
    );
  }
}

// ── Skor Satırı ───────────────────────────────────────────────────────────

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.rank,
    required this.name,
    required this.score,
    required this.prestigeLevel,
    required this.isMe,
  });

  final int rank;
  final String name;
  final int score;
  final int prestigeLevel;
  final bool isMe;

  Color get _rankColor {
    switch (rank) {
      case 1:
        return const Color(0xFFFBBF24); // altın
      case 2:
        return const Color(0xFFC0C0C0); // gümüş
      case 3:
        return const Color(0xFFCD7F32); // bronz
      default:
        return AppColors.muted;
    }
  }

  IconData? get _rankIcon {
    if (rank <= 3) return Icons.emoji_events_rounded;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.primary.withAlpha(25)
            : AppColors.surface.withAlpha(180),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isMe
              ? AppColors.primary.withAlpha(100)
              : AppColors.border.withAlpha(40),
          width: isMe ? 1.5 : 1,
        ),
        boxShadow: isMe
            ? [
                BoxShadow(
                  color: AppColors.primary.withAlpha(30),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Sıra
          SizedBox(
            width: 32,
            child: _rankIcon != null
                ? Icon(_rankIcon, color: _rankColor, size: 18)
                : Text(
                    '$rank',
                    style: AppTextStyles.hudValue.copyWith(
                      fontSize: 13,
                      color: isMe ? AppColors.primaryLight : _rankColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
          const SizedBox(width: 10),
          // İsim + prestige
          Expanded(
            child: Row(
              children: [
                if (isMe) ...[
                  Icon(Icons.arrow_right_rounded,
                      color: AppColors.primaryLight, size: 16),
                  const SizedBox(width: 2),
                ],
                Flexible(
                  child: Text(
                    name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 12,
                      fontWeight: isMe ? FontWeight.w600 : FontWeight.w400,
                      color:
                          isMe ? AppColors.primaryLight : AppColors.foreground,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (prestigeLevel > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withAlpha(25),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.amber.withAlpha(80)),
                    ),
                    child: Text(
                      'P$prestigeLevel',
                      style: AppTextStyles.hudLabel.copyWith(
                        fontSize: 8,
                        color: AppColors.amber,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Skor
          Text(
            score.toString().padLeft(7, '0'),
            style: AppTextStyles.hudValue.copyWith(
              fontSize: 13,
              color: isMe
                  ? AppColors.primaryLight
                  : rank <= 3
                      ? _rankColor
                      : AppColors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}
