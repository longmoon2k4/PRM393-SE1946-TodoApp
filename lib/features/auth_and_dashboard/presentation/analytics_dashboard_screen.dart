import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../../core/models/task_model.dart';
import '../../../core/providers/core_tasks_provider.dart';
import '../../../core/theme/adaptive_theme_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/statistics_provider.dart';

class AnalyticsDashboardScreen extends ConsumerStatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  ConsumerState<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState
    extends ConsumerState<AnalyticsDashboardScreen> {
  int _touchedPieIndex = -1;
  bool _isLoading = false;

  Future<void> _handleRefresh() async {
    setState(() => _isLoading = true);
    await ref.read(coreTasksProvider.notifier).syncFromBackend();
    if (mounted) setState(() => _isLoading = false);
  }

  void _showAdaptiveInfoDialog(
    BuildContext context,
    AdaptiveState adaptive,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        final modeColor = _getModeColor(adaptive.mode);
        final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
        final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
        final subtextColor =
            isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

        return AlertDialog(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: modeColor.withAlpha(isDark ? 50 : 25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getModeIcon(adaptive.mode),
                  color: modeColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Cơ chế Adaptive UI',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ứng dụng tự động điều chỉnh màu sắc giao diện theo tải công việc thời gian thực:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: subtextColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildAdaptiveRuleItem(
                    title: '🌿 Calm Mode (Dịu mát)',
                    desc: 'Khối lượng việc < 60% ngưỡng. Giữ tinh thần thoải mái, nhẹ nhàng.',
                    color: AppColors.calmPrimary,
                    isActive: adaptive.mode == AdaptiveMode.calm,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildAdaptiveRuleItem(
                    title: '⚡ Focus Mode (Tập trung)',
                    desc: 'Khối lượng việc 60% - 100% ngưỡng hoặc có việc quá hạn. Tông màu ấm tăng tập trung.',
                    color: AppColors.focusPrimary,
                    isActive: adaptive.mode == AdaptiveMode.focus,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildAdaptiveRuleItem(
                    title: '🚨 Overload Mode (Quá tải)',
                    desc: 'Vượt ngưỡng (${adaptive.backlogThreshold} việc). Kích hoạt màu đỏ khẩn cấp và cảnh báo thông báo.',
                    color: AppColors.overloadPrimary,
                    isActive: adaptive.mode == AdaptiveMode.overload,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Đã hiểu',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAdaptiveRuleItem({
    required String title,
    required String desc,
    required Color color,
    required bool isActive,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive
            ? color.withAlpha(isDark ? 40 : 20)
            : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: color,
                  ),
                ),
              ),
              if (isActive) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'ĐANG ÁP DỤNG',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  BoxDecoration _enterpriseCardDecoration({
    required Color cardBg,
    required bool isDark,
    double radius = 20,
    Color? customBorderColor,
    AdaptiveMode? mode,
  }) {
    final effectiveBorder = customBorderColor ??
        (mode == AdaptiveMode.overload
            ? (isDark ? const Color(0xFF9F1239) : const Color(0xFFFECDD3))
            : (mode == AdaptiveMode.focus
                ? (isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A))
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))));

    final shadowTint = mode == AdaptiveMode.overload
        ? const Color(0xFFE11D48)
        : (mode == AdaptiveMode.focus
            ? const Color(0xFFD97706)
            : const Color(0xFF0F172A));

    return BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: effectiveBorder,
        width: mode == AdaptiveMode.overload ? 1.5 : 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: shadowTint.withAlpha(isDark
              ? (mode == AdaptiveMode.overload ? 60 : 35)
              : (mode == AdaptiveMode.overload ? 25 : 12)),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: shadowTint.withAlpha(isDark ? 30 : 6),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(statisticsProvider);
    final adaptive = ref.watch(adaptiveStateProvider);
    final isDark = adaptive.isDark;
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final isOverload = adaptive.mode == AdaptiveMode.overload;
    final isFocus = adaptive.mode == AdaptiveMode.focus;

    final cardBg = Theme.of(context).cardColor;
    final borderColor = isDark
        ? (isOverload
            ? const Color(0xFF9F1239)
            : (isFocus ? const Color(0xFF78350F) : const Color(0xFF334155)))
        : (isOverload
            ? const Color(0xFFFECDD3)
            : (isFocus ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0)));
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(context, user, adaptive, isDark),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: Theme.of(context).primaryColor,
        child: _isLoading
            ? _buildSkeletonLoading(isDark)
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 10,
                  bottom: 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Offline banner if disconnected
                    if (auth.isOffline) _buildOfflineBanner(isDark),

                    // Emergency Overload HUD Banner
                    if (isOverload) ...[
                      _buildOverloadEmergencyBanner(
                        context: context,
                        adaptive: adaptive,
                        stats: stats,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 18),
                    ] else if (isFocus && stats.overdueCount > 0) ...[
                      _buildFocusAdvisoryBanner(
                        context: context,
                        overdueCount: stats.overdueCount,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 18),
                    ],

                    // 1. Productivity Health Hub (Hero Card)
                    _buildProductivityHub(
                      context,
                      stats,
                      adaptive,
                      cardBg,
                      borderColor,
                      textColor,
                      subtextColor,
                      isDark,
                    ),

                    const SizedBox(height: 18),

                    // 2. Adaptive Workload Engine Visualizer Card
                    _buildWorkloadAdaptiveCard(
                      context,
                      adaptive,
                      cardBg,
                      borderColor,
                      textColor,
                      subtextColor,
                      isDark,
                    ),

                    const SizedBox(height: 18),

                    // 3. 4-Metrics Interactive Grid
                    _buildMetricsGrid(
                      context,
                      stats,
                      adaptive,
                      cardBg,
                      borderColor,
                      textColor,
                      subtextColor,
                      isDark,
                    ),

                    const SizedBox(height: 18),

                    // 4. Actionable Urgent Tasks (Cần xử lý ngay)
                    if (stats.topActionableTasks.isNotEmpty) ...[
                      _buildActionableTasksSection(
                        context,
                        stats.topActionableTasks,
                        adaptive,
                        stats,
                        cardBg,
                        borderColor,
                        textColor,
                        subtextColor,
                        isDark,
                      ),
                      const SizedBox(height: 18),
                    ],

                    // 5. Task Distribution Donut Chart
                    _buildDistributionCard(
                      context,
                      stats,
                      adaptive,
                      cardBg,
                      borderColor,
                      textColor,
                      subtextColor,
                      isDark,
                    ),

                    const SizedBox(height: 18),

                    // 6. Weekly Productivity Velocity Bar Chart
                    _buildWeeklyVelocityCard(
                      context,
                      stats,
                      adaptive,
                      cardBg,
                      borderColor,
                      textColor,
                      subtextColor,
                      isDark,
                    ),

                    const SizedBox(height: 18),

                    // 7. Priority Distribution Breakdown
                    _buildPriorityBreakdownCard(
                      context,
                      stats,
                      adaptive,
                      cardBg,
                      borderColor,
                      textColor,
                      subtextColor,
                      isDark,
                    ),

                    const SizedBox(height: 28),

                    // Navigation CTA to Task Board
                    _buildTaskBoardShortcut(context, adaptive),
                  ],
                ),
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    dynamic user,
    AdaptiveState adaptive,
    bool isDark,
  ) {
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final modeColor = _getModeColor(adaptive.mode);

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 12,
      toolbarHeight: 68,
      title: Row(
        children: [
          // User Avatar with glowing status ring
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: modeColor,
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: modeColor.withAlpha(isDark ? 60 : 35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: user?.avatarUrl != null
                    ? Image.network(
                        user!.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        LucideIcons.user,
                        size: 18,
                        color: isDark ? Colors.white : const Color(0xFF334155),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getTimeGreeting(),
                  maxLines: 1,
                  softWrap: false,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: subtextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  user?.name ?? 'Long Moon',
                  maxLines: 1,
                  softWrap: false,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Mode indicator pill (Clickable to show rules dialog)
        GestureDetector(
          onTap: () => _showAdaptiveInfoDialog(context, adaptive, isDark),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: modeColor.withAlpha(isDark ? 40 : 20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: modeColor.withAlpha(isDark ? 90 : 70),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getModeIcon(adaptive.mode),
                  size: 12,
                  color: modeColor,
                ),
                const SizedBox(width: 4),
                Text(
                  adaptive.modeName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                    color: modeColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        // Dark/Light Mode Switcher
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              isDark ? LucideIcons.sun : LucideIcons.moon,
              size: 16,
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF475569),
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
            tooltip: isDark ? 'Giao diện Sáng' : 'Giao diện Tối',
          ),
        ),
        const SizedBox(width: 4),
        // Settings / Profile Button
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              LucideIcons.settings,
              size: 16,
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF475569),
            ),
            onPressed: () => context.push('/profile'),
            tooltip: 'Cài đặt hồ sơ & ngưỡng',
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildOfflineBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E3A8A).withAlpha(50)
            : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? const Color(0xFF3B82F6).withAlpha(70)
              : const Color(0xFFBFDBFE),
        ),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.wifiOff, size: 16, color: Color(0xFF3B82F6)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Chế độ ngoại tuyến: Dữ liệu đã lưu an toàn trên bộ nhớ thiết bị.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFF93C5FD)
                    : const Color(0xFF1E40AF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Emergency Overload HUD Banner
  Widget _buildOverloadEmergencyBanner({
    required BuildContext context,
    required AdaptiveState adaptive,
    required TaskStatistics stats,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF380E17), const Color(0xFF22080D)]
              : [const Color(0xFFFFF1F2), const Color(0xFFFFE4E6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE11D48),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE11D48).withAlpha(isDark ? 80 : 30),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE11D48),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.alertOctagon, size: 13, color: Colors.white),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'CẢNH BÁO QUÁ TẢI',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE11D48).withAlpha(isDark ? 50 : 25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFE11D48).withAlpha(120),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${(adaptive.loadPercentage * 100).round()}% tải',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFE11D48),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Khối lượng công việc đã vượt ngưỡng an toàn!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF9F1239),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bạn đang có ${adaptive.activeTaskCount} việc đang dở dang (ngưỡng an toàn: ${adaptive.backlogThreshold} việc). Hệ thống tự động thu gọn các việc ưu tiên thấp để bạn tập trung dứt điểm việc gấp trước.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              height: 1.45,
              color: isDark ? const Color(0xFFFECDD3) : const Color(0xFF881337),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/board'),
                  icon: const Icon(LucideIcons.flame, size: 14),
                  label: Text(
                    'Xử lý việc gấp (${stats.urgentCount + stats.overdueCount})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE11D48),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    textStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => context.push('/profile'),
                icon: const Icon(LucideIcons.slidersHorizontal, size: 13),
                label: const Text('Đổi ngưỡng'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE11D48),
                  side: const BorderSide(color: Color(0xFFE11D48)),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  textStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFocusAdvisoryBanner({
    required BuildContext context,
    required int overdueCount,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF281C0C)
            : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD97706),
          width: 1.4,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706).withAlpha(isDark ? 50 : 25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.zap,
              size: 15,
              color: Color(0xFFD97706),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chế độ Tập trung (Focus Mode)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFD97706),
                  ),
                ),
                Text(
                  'Có $overdueCount công việc quá hạn cần ưu tiên xử lý dứt điểm.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1. Productivity Health Hub (Hero Gauge Card)
  Widget _buildProductivityHub(
    BuildContext context,
    TaskStatistics stats,
    AdaptiveState adaptive,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
  ) {
    final score = stats.productivityScore;
    final isOverload = adaptive.mode == AdaptiveMode.overload;
    final isFocus = adaptive.mode == AdaptiveMode.focus;

    Color scoreColor;
    if (isOverload) {
      scoreColor = const Color(0xFFE11D48);
    } else if (score >= 80) {
      scoreColor = const Color(0xFF10B981); // Emerald
    } else if (score >= 60) {
      scoreColor = const Color(0xFFD97706); // Warm Amber
    } else {
      scoreColor = const Color(0xFFEF4444); // Red
    }

    final hubLabel = isOverload
        ? '🚨 Quá tải (${adaptive.activeTaskCount}/${adaptive.backlogThreshold} việc)'
        : (isFocus && stats.overdueCount > 0
            ? '⚡ Cần tập trung việc gấp'
            : stats.productivityLabel);

    final hubAdvice = isOverload
        ? 'Cảnh báo: Backlog công việc (${adaptive.activeTaskCount} việc) đã vượt ngưỡng cho phép (${adaptive.backlogThreshold} việc)! Hệ thống đã kích hoạt chế độ tinh gọn để bạn ưu tiên xử lý việc khẩn cấp.'
        : stats.productivityAdvice;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _enterpriseCardDecoration(
        cardBg: cardBg,
        isDark: isDark,
        radius: 20,
        mode: adaptive.mode,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular Gauge Indicator
              CircularPercentIndicator(
                radius: 46.0,
                lineWidth: 8.5,
                animation: true,
                animationDuration: 1000,
                percent: (score / 100).clamp(0.0, 1.0),
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$score',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: isOverload ? const Color(0xFFE11D48) : textColor,
                      ),
                    ),
                    Text(
                      'ĐIỂM',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: subtextColor,
                      ),
                    ),
                  ],
                ),
                circularStrokeCap: CircularStrokeCap.round,
                progressColor: scoreColor,
                backgroundColor: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFF1F5F9),
              ),

              const SizedBox(width: 18),

              // Title and details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: scoreColor.withAlpha(isDark ? 40 : 20),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: scoreColor.withAlpha(isDark ? 80 : 50),
                              ),
                            ),
                            child: Text(
                              hubLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: scoreColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hubAdvice,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        height: 1.4,
                        color: isOverload
                            ? (isDark ? const Color(0xFFFECDD3) : const Color(0xFF881337))
                            : subtextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 16),

          // Micro quick stat strip
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  label: 'Tỷ lệ hoàn thành',
                  value: '${(stats.completionRate * 100).round()}%',
                  icon: LucideIcons.checkCircle,
                  iconColor: const Color(0xFF10B981),
                  textColor: textColor,
                  subtextColor: subtextColor,
                ),
              ),
              Container(width: 1, height: 28, color: borderColor),
              Expanded(
                child: _buildMiniStat(
                  label: 'Cần giải quyết',
                  value: '${stats.todoCount + stats.inProgressCount} việc',
                  icon: LucideIcons.clock,
                  iconColor: isOverload ? const Color(0xFFE11D48) : const Color(0xFF3B82F6),
                  textColor: textColor,
                  subtextColor: subtextColor,
                ),
              ),
              Container(width: 1, height: 28, color: borderColor),
              Expanded(
                child: _buildMiniStat(
                  label: 'Hạn khẩn cấp',
                  value: '${stats.overdueCount + stats.dueSoonCount} việc',
                  icon: LucideIcons.flame,
                  iconColor: (isOverload || stats.overdueCount > 0)
                      ? const Color(0xFFE11D48)
                      : const Color(0xFFF59E0B),
                  textColor: (isOverload || stats.overdueCount > 0)
                      ? const Color(0xFFE11D48)
                      : textColor,
                  subtextColor: subtextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color textColor,
    required Color subtextColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 5),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: subtextColor,
          ),
        ),
      ],
    );
  }

  // 2. Adaptive Workload Engine Visualizer Card
  Widget _buildWorkloadAdaptiveCard(
    BuildContext context,
    AdaptiveState adaptive,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
  ) {
    final isOverload = adaptive.mode == AdaptiveMode.overload;
    final modeColor = _getModeColor(adaptive.mode);
    final percent = adaptive.loadPercentage.clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _enterpriseCardDecoration(
        cardBg: cardBg,
        isDark: isDark,
        radius: 20,
        mode: adaptive.mode,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: modeColor.withAlpha(isDark ? 40 : 20),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isOverload ? LucideIcons.flame : LucideIcons.gauge,
                        size: 16,
                        color: modeColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isOverload
                            ? 'Engine Thích ứng (🚨 Đang quá tải)'
                            : 'Engine Thích ứng (Adaptive)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: isOverload ? const Color(0xFFE11D48) : textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: modeColor.withAlpha(isDark ? 40 : 20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: modeColor.withAlpha(isDark ? 90 : 60),
                    width: 1.2,
                  ),
                ),
                child: Text(
                  '${adaptive.activeTaskCount}/${adaptive.backlogThreshold} việc',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: modeColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Multi-zone track progress bar
          Stack(
            children: [
              // Track background with 3 zones (Calm: 0-60%, Focus: 60-100%, Overload: >100%)
              Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155).withAlpha(60)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              // Current progress fill
              FractionallySizedBox(
                widthFactor: percent,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: modeColor,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: modeColor.withAlpha(isDark ? 80 : 50),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Zone markers legend - 3-Segment Capsule Grid
          Row(
            children: [
              Expanded(
                child: _buildZoneLegendPill(
                  icon: LucideIcons.leaf,
                  label: 'Calm',
                  range: '< 60%',
                  isActive: adaptive.mode == AdaptiveMode.calm,
                  color: AppColors.calmPrimary,
                  isDark: isDark,
                  subtextColor: subtextColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildZoneLegendPill(
                  icon: LucideIcons.zap,
                  label: 'Focus',
                  range: '60% - 100%',
                  isActive: adaptive.mode == AdaptiveMode.focus,
                  color: AppColors.focusPrimary,
                  isDark: isDark,
                  subtextColor: subtextColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildZoneLegendPill(
                  icon: LucideIcons.alertOctagon,
                  label: 'Overload',
                  range: '> 100%',
                  isActive: adaptive.mode == AdaptiveMode.overload,
                  color: AppColors.overloadPrimary,
                  isDark: isDark,
                  subtextColor: subtextColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Description & CTA
          Row(
            children: [
              Expanded(
                child: Text(
                  adaptive.modeDescription,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: subtextColor,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () => context.push('/profile'),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withAlpha(isDark ? 35 : 15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withAlpha(isDark ? 80 : 50),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Đổi ngưỡng',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 13,
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildZoneLegendPill({
    required IconData icon,
    required String label,
    required String range,
    required bool isActive,
    required Color color,
    required bool isDark,
    required Color subtextColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: isActive
            ? color.withAlpha(isDark ? 40 : 20)
            : (isDark ? const Color(0xFF0F172A).withAlpha(50) : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive
              ? color
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: isActive ? color : subtextColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                    color: isActive ? color : subtextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            range,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? color : subtextColor,
            ),
          ),
        ],
      ),
    );
  }

  // 3. 4-Metrics Interactive Grid
  Widget _buildMetricsGrid(
    BuildContext context,
    TaskStatistics stats,
    AdaptiveState adaptive,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Hoàn thành',
                value: '${stats.doneCount}',
                subtitle: '${(stats.completionRate * 100).round()}% tổng việc',
                icon: LucideIcons.checkCheck,
                color: AppColors.statusDone,
                cardBg: cardBg,
                borderColor: borderColor,
                textColor: textColor,
                subtextColor: subtextColor,
                isDark: isDark,
                mode: adaptive.mode,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: 'Đang làm',
                value: '${stats.inProgressCount}',
                subtitle: 'Đang xử lý dở',
                icon: LucideIcons.timer,
                color: AppColors.statusInProgress,
                cardBg: cardBg,
                borderColor: borderColor,
                textColor: textColor,
                subtextColor: subtextColor,
                isDark: isDark,
                mode: adaptive.mode,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Chờ xử lý',
                value: '${stats.todoCount}',
                subtitle: 'Trong hàng đợi',
                icon: LucideIcons.listTodo,
                color: const Color(0xFF64748B),
                cardBg: cardBg,
                borderColor: borderColor,
                textColor: textColor,
                subtextColor: subtextColor,
                isDark: isDark,
                mode: adaptive.mode,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: 'Quá hạn',
                value: '${stats.overdueCount}',
                subtitle: stats.overdueCount > 0 ? 'Cần xử lý gấp' : 'Không có việc trễ',
                icon: LucideIcons.alertTriangle,
                color: AppColors.priorityUrgent,
                cardBg: cardBg,
                borderColor: borderColor,
                textColor: textColor,
                subtextColor: subtextColor,
                isDark: isDark,
                mode: adaptive.mode,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subtextColor,
    required bool isDark,
    AdaptiveMode? mode,
  }) {
    final isOverloadHighlight = mode == AdaptiveMode.overload && title == 'Quá hạn';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: _enterpriseCardDecoration(
        cardBg: cardBg,
        isDark: isDark,
        radius: 18,
        mode: mode,
        customBorderColor: isOverloadHighlight ? const Color(0xFFE11D48) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: subtextColor,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withAlpha(isDark ? 40 : 25),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(icon, size: 14, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: subtextColor,
            ),
          ),
        ],
      ),
    );
  }

  // 4. Actionable Urgent Tasks Section
  Widget _buildActionableTasksSection(
    BuildContext context,
    List<TaskItem> tasks,
    AdaptiveState adaptive,
    TaskStatistics stats,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
  ) {
    final isOverload = adaptive.mode == AdaptiveMode.overload;
    final isFocus = adaptive.mode == AdaptiveMode.focus;

    // Trong Overload Mode: Tự động thu gọn các task mức ưu tiên thấp (Requirement 1.2)
    final displayedTasks = isOverload
        ? tasks.where((t) => t.isOverdue || t.priority == TaskPriority.urgent || t.priority == TaskPriority.high).toList()
        : tasks;

    final hiddenLowPriorityCount = tasks.length - displayedTasks.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _enterpriseCardDecoration(
        cardBg: cardBg,
        isDark: isDark,
        radius: 20,
        mode: adaptive.mode,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      isOverload
                          ? LucideIcons.flame
                          : (isFocus ? LucideIcons.zap : LucideIcons.checkSquare),
                      size: 16,
                      color: isOverload
                          ? AppColors.overloadPrimary
                          : (isFocus ? AppColors.focusPrimary : AppColors.calmPrimary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isOverload
                            ? 'Nhiệm vụ Cứu nguy (Chế độ Giảm tải)'
                            : (isFocus ? 'Cần xử lý ngay (Ưu tiên cao)' : 'Cần xử lý ngay'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isOverload
                              ? (isDark ? const Color(0xFFFDA4AF) : const Color(0xFFBE123C))
                              : textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isOverload
                          ? AppColors.overloadPrimary
                          : (isFocus ? AppColors.focusPrimary : AppColors.calmPrimary))
                      .withAlpha(isDark ? 40 : 20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isOverload ? 'LỌC KHẨN CẤP' : 'Tick để xong nhanh',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: isOverload ? AppColors.overloadPrimary : subtextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (displayedTasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'Không có việc khẩn cấp nào tồn đọng!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: subtextColor,
                  ),
                ),
              ),
            )
          else
            ...displayedTasks.map((task) => _buildActionableTaskTile(
                  task,
                  textColor,
                  subtextColor,
                  borderColor,
                  isDark,
                )),
          if (isOverload && hiddenLowPriorityCount > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.shieldCheck, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Đã tự động thu gọn $hiddenLowPriorityCount việc mức ưu tiên thấp để giảm tải áp lực.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: subtextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionableTaskTile(
    TaskItem task,
    Color textColor,
    Color subtextColor,
    Color borderColor,
    bool isDark,
  ) {
    final isUrgent = task.priority == TaskPriority.urgent;
    final isOverdue = task.isOverdue;

    Color badgeColor = const Color(0xFF3B82F6);
    String badgeText = 'Ưu tiên';
    if (isOverdue) {
      badgeColor = const Color(0xFFEF4444);
      badgeText = 'Quá hạn';
    } else if (isUrgent) {
      badgeColor = const Color(0xFFEF4444);
      badgeText = 'Khẩn cấp';
    } else if (task.priority == TaskPriority.high) {
      badgeColor = const Color(0xFFF59E0B);
      badgeText = 'Ưu tiên cao';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue
              ? const Color(0xFFEF4444).withAlpha(50)
              : borderColor,
        ),
      ),
      child: Row(
        children: [
          // Quick complete checkbox button
          InkWell(
            onTap: () {
              final updated = task.copyWith(status: TaskStatus.done);
              ref.read(coreTasksProvider.notifier).updateTask(updated);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã hoàn thành: ${task.title}'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isOverdue
                      ? const Color(0xFFEF4444)
                      : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                if (task.deadline != null)
                  Text(
                    'Hạn chót: ${DateFormat('dd/MM/yyyy HH:mm').format(task.deadline!)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: isOverdue ? const Color(0xFFEF4444) : subtextColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withAlpha(isDark ? 40 : 20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badgeText,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: badgeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5. Task Distribution Donut Chart
  Widget _buildDistributionCard(
    BuildContext context,
    TaskStatistics stats,
    AdaptiveState adaptive,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
  ) {
    if (stats.totalTasks == 0) {
      return _buildEmptyTaskCard(cardBg, borderColor, textColor, subtextColor, isDark);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _enterpriseCardDecoration(
        cardBg: cardBg,
        isDark: isDark,
        radius: 20,
        mode: adaptive.mode,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Phân bổ trạng thái',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Tổng: ${stats.totalTasks} việc',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: subtextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 145,
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  _touchedPieIndex = -1;
                                  return;
                                }
                                _touchedPieIndex = pieTouchResponse
                                    .touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 3,
                          centerSpaceRadius: 36,
                          sections: _getPieSections(stats),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(stats.completionRate * 100).round()}%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                          Text(
                            'Đã xong',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: subtextColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem(
                        'Hoàn thành',
                        stats.doneCount,
                        stats.totalTasks,
                        AppColors.statusDone,
                        textColor,
                        subtextColor,
                      ),
                      const SizedBox(height: 8),
                      _buildLegendItem(
                        'Đang làm',
                        stats.inProgressCount,
                        stats.totalTasks,
                        AppColors.statusInProgress,
                        textColor,
                        subtextColor,
                      ),
                      const SizedBox(height: 8),
                      _buildLegendItem(
                        'Chờ xử lý',
                        stats.todoCount,
                        stats.totalTasks,
                        const Color(0xFF64748B),
                        textColor,
                        subtextColor,
                      ),
                      const SizedBox(height: 8),
                      _buildLegendItem(
                        'Quá hạn',
                        stats.overdueCount,
                        stats.totalTasks,
                        AppColors.priorityUrgent,
                        textColor,
                        subtextColor,
                      ),
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

  List<PieChartSectionData> _getPieSections(TaskStatistics stats) {
    final isDoneTouched = _touchedPieIndex == 0;
    final isInProgressTouched = _touchedPieIndex == 1;
    final isTodoTouched = _touchedPieIndex == 2;
    final isOverdueTouched = _touchedPieIndex == 3;

    final doneVal = stats.doneCount.toDouble();
    final inProgressVal = stats.inProgressCount.toDouble();
    final todoVal = stats.todoCount.toDouble();
    final overdueVal = stats.overdueCount.toDouble();

    return [
      PieChartSectionData(
        color: AppColors.statusDone,
        value: doneVal == 0 ? 0.001 : doneVal,
        title: '',
        radius: isDoneTouched ? 28 : 22,
      ),
      PieChartSectionData(
        color: AppColors.statusInProgress,
        value: inProgressVal == 0 ? 0.001 : inProgressVal,
        title: '',
        radius: isInProgressTouched ? 28 : 22,
      ),
      PieChartSectionData(
        color: const Color(0xFF64748B),
        value: todoVal == 0 ? 0.001 : todoVal,
        title: '',
        radius: isTodoTouched ? 28 : 22,
      ),
      PieChartSectionData(
        color: AppColors.priorityUrgent,
        value: overdueVal == 0 ? 0.001 : overdueVal,
        title: '',
        radius: isOverdueTouched ? 28 : 22,
      ),
    ];
  }

  Widget _buildLegendItem(
    String label,
    int count,
    int total,
    Color color,
    Color textColor,
    Color subtextColor,
  ) {
    final pct = total == 0 ? 0 : (count * 100 / total).round();

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: subtextColor,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$count ($pct%)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ],
    );
  }

  // 6. Weekly Productivity Velocity Bar Chart
  Widget _buildWeeklyVelocityCard(
    BuildContext context,
    TaskStatistics stats,
    AdaptiveState adaptive,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
  ) {
    final days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final currentWeekdayIndex = (DateTime.now().weekday - 1) % 7;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _enterpriseCardDecoration(
        cardBg: cardBg,
        isDark: isDark,
        radius: 20,
        mode: adaptive.mode,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Hiệu suất hoàn thành theo tuần',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withAlpha(isDark ? 40 : 20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Tuần này',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 145,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 8,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) =>
                        isDark ? const Color(0xFF334155) : const Color(0xFF0F172A),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final val = stats.weeklyCompletedCounts[group.x.toInt()];
                      return BarTooltipItem(
                        '$val việc',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (val, meta) => Text(
                        '${val.toInt()}',
                        style: TextStyle(fontSize: 10, color: subtextColor),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final index = val.toInt();
                        if (index >= 0 && index < days.length) {
                          final isToday = index == currentWeekdayIndex;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              days[index],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    isToday ? FontWeight.w800 : FontWeight.w600,
                                color: isToday
                                    ? Theme.of(context).primaryColor
                                    : subtextColor,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark
                        ? const Color(0xFF334155).withAlpha(60)
                        : const Color(0xFFF1F5F9),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) {
                  final val = stats.weeklyCompletedCounts[i].toDouble();
                  final isToday = i == currentWeekdayIndex;

                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: val == 0 ? 0.2 : val,
                        color: val > 0
                            ? (isToday
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).primaryColor.withAlpha(isDark ? 200 : 160))
                            : (isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0)),
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 7. Priority Distribution Breakdown
  Widget _buildPriorityBreakdownCard(
    BuildContext context,
    TaskStatistics stats,
    AdaptiveState adaptive,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _enterpriseCardDecoration(
        cardBg: cardBg,
        isDark: isDark,
        radius: 20,
        mode: adaptive.mode,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phân rã mức độ ưu tiên',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildPriorityRow('Khẩn cấp (Urgent)', stats.urgentCount, stats.totalTasks,
              AppColors.priorityUrgent, textColor, subtextColor, isDark),
          const SizedBox(height: 12),
          _buildPriorityRow('Ưu tiên cao (High)', stats.highCount, stats.totalTasks,
              AppColors.priorityHigh, textColor, subtextColor, isDark),
          const SizedBox(height: 12),
          _buildPriorityRow('Trung bình (Medium)', stats.mediumCount, stats.totalTasks,
              AppColors.priorityMedium, textColor, subtextColor, isDark),
          const SizedBox(height: 12),
          _buildPriorityRow('Thấp (Low)', stats.lowCount, stats.totalTasks,
              AppColors.priorityLow, textColor, subtextColor, isDark),
        ],
      ),
    );
  }

  Widget _buildPriorityRow(
    String label,
    int count,
    int total,
    Color color,
    Color textColor,
    Color subtextColor,
    bool isDark,
  ) {
    final percent = total == 0 ? 0.0 : (count / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$count (${(percent * 100).round()}%)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearPercentIndicator(
          lineHeight: 7.0,
          percent: percent,
          progressColor: color,
          backgroundColor: isDark
              ? const Color(0xFF334155)
              : const Color(0xFFF1F5F9),
          barRadius: const Radius.circular(4),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildEmptyTaskCard(
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subtextColor,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: _enterpriseCardDecoration(cardBg: cardBg, isDark: isDark, radius: 20),
      child: Column(
        children: [
          Image.asset(
            'assets/images/empty_tasks.png',
            height: 100,
            fit: BoxFit.contain,
            errorBuilder: (ctx, err, stack) => Icon(
              LucideIcons.inbox,
              size: 48,
              color: subtextColor,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Không có công việc nào',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hiện tại không có dữ liệu công việc để thống kê.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: subtextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskBoardShortcut(BuildContext context, AdaptiveState adaptive) {
    Color btnColor;
    IconData btnIcon;
    String btnLabel;

    switch (adaptive.mode) {
      case AdaptiveMode.overload:
        btnColor = AppColors.overloadPrimary;
        btnIcon = LucideIcons.flame;
        btnLabel = 'Xử lý ngay các việc khẩn cấp (Giảm tải) →';
        break;
      case AdaptiveMode.focus:
        btnColor = AppColors.focusPrimary;
        btnIcon = LucideIcons.zap;
        btnLabel = 'Vào bảng công việc tập trung →';
        break;
      case AdaptiveMode.calm:
        btnColor = AppColors.calmPrimary;
        btnIcon = LucideIcons.kanban;
        btnLabel = 'Xem Bảng Công Việc (Task Board) →';
        break;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => context.push('/board'),
        icon: Icon(btnIcon, size: 18),
        label: Text(btnLabel),
        style: ElevatedButton.styleFrom(
          backgroundColor: btnColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading(bool isDark) {
    final shimmerColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: shimmerColor,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getModeColor(AdaptiveMode mode) {
    switch (mode) {
      case AdaptiveMode.calm:
        return AppColors.calmPrimary;
      case AdaptiveMode.focus:
        return AppColors.focusPrimary;
      case AdaptiveMode.overload:
        return AppColors.overloadPrimary;
    }
  }

  IconData _getModeIcon(AdaptiveMode mode) {
    switch (mode) {
      case AdaptiveMode.calm:
        return LucideIcons.leaf;
      case AdaptiveMode.focus:
        return LucideIcons.zap;
      case AdaptiveMode.overload:
        return LucideIcons.alertOctagon;
    }
  }
}
